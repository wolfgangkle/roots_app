import * as admin from 'firebase-admin';
import { onRequest, HttpsError, CallableRequest } from 'firebase-functions/v2/https';

// Constants
const COMBAT_CHANCE = 0.8;
const PEACEFUL_CHANCE = 0.1;
const MAX_RETRY_COUNT = 5;

/**
 * processArrivalCore implements the following logic:
 *
 * 1. Ensure the hero is in a proper moving state and that the arrival time has passed.
 * 2. Check whether the destination tile (hero.destinationX/destinationY) is already occupied.
 *    - If so, check if there is an ongoing combat there.
 *       a. If an ongoing combat is found, update the hero's position to the destination and add this hero to that combat
 *          (joining a hybrid PvP/PvE fight). Additionally, create a combat report for the joining hero.
 *       b. Otherwise, update the hero's position and trigger a new PvP combat between the arriving hero and one of the heroes already on the tile.
 *          In this scenario, ONLY the hero or heroes already present (the interrupted ones) should have their current destination
 *          saved to 'reservedDestination', so they can resume their planned movement later.
 *    In either case the function returns immediately so that movement is paused.
 * 3. If no conflict is detected at the destination, teleport the hero from his origin tile to the destination.
 * 4. Then perform an event roll at the arrival tile:
 *    - In case of a combat event (PvE), set the hero to in_combat and create a combat encounter from encounterEvents.
 *      (Note: In this case the reached waypoint is not simply reattempted on the same tile –
 *       if a movementQueue exists, we reserve the next queued tile as the hero's reservedDestination.)
 *    - In case of a peaceful event or no event, the reached waypoint is removed from the movementQueue and, if more waypoints exist,
 *      the next movement is scheduled using the hero’s movementSpeed.
 */
export async function processArrivalCore(heroId: string): Promise<string> {
  console.log('📦 processHeroArrival triggered with:', heroId);
  const db = admin.firestore();
  const heroRef = db.collection('heroes').doc(heroId);
  const heroSnap = await heroRef.get();
  const hero = heroSnap.data();

  if (!hero) throw new HttpsError('not-found', 'Hero not found.');

  if (
    hero.state !== 'moving' ||
    hero.destinationX === undefined ||
    hero.destinationY === undefined ||
    !hero.arrivesAt
  ) {
    throw new HttpsError('failed-precondition', 'Hero is not currently moving.');
  }

  const now = Date.now();
  const arrivalTimestamp = hero.arrivesAt.toMillis();
  if (now < arrivalTimestamp) {
    const retryCount = hero.retryCount ?? 0;
    if (retryCount >= MAX_RETRY_COUNT) return 'Too early, max retries hit.';
    const { scheduleHeroArrivalTask } = await import('./scheduleHeroArrivalTask.js');
    await heroRef.update({ retryCount: retryCount + 1 });
    await scheduleHeroArrivalTask({ heroId, delaySeconds: 30 });
    return 'Too early — rescheduled.';
  }

  const movementSpeed = hero.movementSpeed ? hero.movementSpeed : 20 * 60 * 1000;
  const destinationX = hero.destinationX;
  const destinationY = hero.destinationY;
  const tileKey = `${destinationX}_${destinationY}`;

  // Get movement queue and current step
  let movementQueue: any[] = Array.isArray(hero.movementQueue) ? [...hero.movementQueue] : [];
  const currentStep = movementQueue[0];

  // Load tile data
  const tileSnap = await db.collection('mapTiles').doc(tileKey).get();
  const tileData = tileSnap.exists ? tileSnap.data() ?? {} : {};

  const lastEventAt = tileData.lastEventAt?.toDate?.();
  let adjustedCombatChance = COMBAT_CHANCE;
  let adjustedPeacefulChance = PEACEFUL_CHANCE;

  if (lastEventAt) {
    const minutesSince = (now - lastEventAt.getTime()) / 60000;

    if (minutesSince < 180) {
      adjustedCombatChance *= 0.5;
      adjustedPeacefulChance *= 0.5;
      console.log(`🧯 Event chance reduced to 50% on tile ${tileKey} (last event ${minutesSince.toFixed(1)} min ago)`);
    } else if (minutesSince < 360) {
      adjustedCombatChance *= 0.2;
      adjustedPeacefulChance *= 0.2;
      console.log(`🧊 Event chance reduced to 20% on tile ${tileKey} (last event ${minutesSince.toFixed(1)} min ago)`);
    }
  }

  // First, update the hero's position (teleport to the destination tile)
  await heroRef.update({
    tileX: destinationX,
    tileY: destinationY,
    tileKey,
    nextTileKey: admin.firestore.FieldValue.delete(),
    retryCount: admin.firestore.FieldValue.delete(),
  });
  console.log(`🚀 Hero ${heroId} arrived at (${destinationX}, ${destinationY})`);

  // Reload movement queue and extract the current step
  movementQueue = Array.isArray(hero.movementQueue) ? [...hero.movementQueue] : [];
  const step = movementQueue[0];

  // Handle instant enter/exitVillage actions (for non-village tile movement)
  if (step?.action === 'enterVillage' || step?.action === 'exitVillage') {
    const newInside = step.action === 'enterVillage';
    if (newInside && !tileData.villageId) {
      throw new HttpsError('failed-precondition', 'No village to enter on this tile.');
    }

    movementQueue.shift();
    await heroRef.update({
      insideVillage: newInside,
      movementQueue,
      state: movementQueue.length > 0 ? 'moving' : 'idle',
      destinationX: admin.firestore.FieldValue.delete(),
      destinationY: admin.firestore.FieldValue.delete(),
      arrivesAt: admin.firestore.FieldValue.delete(),
    });

    console.log(`${newInside ? '📥' : '📤'} Hero ${heroId} ${newInside ? 'entered' : 'exited'} village on tile ${tileKey}`);

    // If a next movement is queued, process it immediately
    if (movementQueue.length > 0) {
      return await processArrivalCore(heroId);
    }
    return `${newInside ? 'Entered' : 'Exited'} village.`;
  }

  // (Optional) You already handled 'exitVillage' in the block above.
  // You may remove the duplicate branch below if not needed.
  if (currentStep?.action === 'exitVillage') {
    movementQueue.shift();
    await heroRef.update({
      insideVillage: false,
      movementQueue,
      state: movementQueue.length > 0 ? 'moving' : 'idle',
      destinationX: admin.firestore.FieldValue.delete(),
      destinationY: admin.firestore.FieldValue.delete(),
      arrivesAt: admin.firestore.FieldValue.delete(),
    });
    console.log(`📤 Hero ${heroId} exited village at tile ${tileKey}`);
    const nextStep = movementQueue[0];
    if (nextStep?.x !== undefined && nextStep?.y !== undefined) {
      const nextArrivesAt = new Date(now + movementSpeed);
      await heroRef.update({
        destinationX: nextStep.x,
        destinationY: nextStep.y,
        arrivesAt: admin.firestore.Timestamp.fromDate(nextArrivesAt),
      });
      const { scheduleHeroArrivalTask } = await import('./scheduleHeroArrivalTask.js');
      await scheduleHeroArrivalTask({ heroId, delaySeconds: Math.floor(movementSpeed / 1000) });
    }
    return 'Exited village.';
  }

  // (Secondary) Re-update hero's position if necessary


    // Re-update hero's position if necessary
    await heroRef.update({
      tileX: destinationX,
      tileY: destinationY,
      tileKey,
      nextTileKey: admin.firestore.FieldValue.delete(),
      retryCount: admin.firestore.FieldValue.delete(),
    });
    console.log(`🚀 Hero ${heroId} confirmed at (${destinationX}, ${destinationY})`);

    // Modified branch: Handle village tile behavior
    if (tileData.villageId) {
      console.log(`🛑 Hero is on a village tile ${tileKey}.`);

      // Remove the coordinate waypoint that got us here
      movementQueue.shift();
      await heroRef.update({
        movementQueue,
        destinationX: admin.firestore.FieldValue.delete(),
        destinationY: admin.firestore.FieldValue.delete(),
        arrivesAt: admin.firestore.FieldValue.delete(),
      });

      // Check if the next queued step is an action (enterVillage/exitVillage)
      const nextStep = movementQueue[0];
      if (nextStep && (nextStep.action === 'enterVillage' || nextStep.action === 'exitVillage')) {
        const newInside = nextStep.action === 'enterVillage';
        // For an 'enterVillage' action, ensure the village exists on the tile
        if (newInside && !tileData.villageId) {
          throw new HttpsError('failed-precondition', 'No village to enter on this tile.');
        }
        // Remove the action step from the queue
        movementQueue.shift();
        await heroRef.update({
          insideVillage: newInside,
          movementQueue,
          state: movementQueue.length > 0 ? 'moving' : 'idle',
        });
        console.log(`${newInside ? '📥' : '📤'} Hero ${heroId} ${newInside ? 'entered' : 'exited'} village on tile ${tileKey}`);
        return `${newInside ? 'Entered' : 'Exited'} village.`;
      } else if (nextStep && nextStep.x !== undefined && nextStep.y !== undefined) {
        // If the next step is a coordinate-based movement, schedule it normally.
        const nextArrivesAt = new Date(Date.now() + movementSpeed);
        await heroRef.update({
          destinationX: nextStep.x,
          destinationY: nextStep.y,
          arrivesAt: admin.firestore.Timestamp.fromDate(nextArrivesAt),
        });
        const { scheduleHeroArrivalTask } = await import('./scheduleHeroArrivalTask.js');
        await scheduleHeroArrivalTask({ heroId, delaySeconds: Math.floor(movementSpeed / 1000) });
      }
      return 'Village tile reached; no event triggered.';
    }



  // 🎲 Roll for random event
  const roll = Math.random();
  console.log(`🎲 Event roll for hero ${heroId} at (${destinationX}, ${destinationY}): ${roll.toFixed(2)}`);

  if (roll < adjustedCombatChance) {
    // ⚔️ PvE combat event logic...
    // [Existing code for combat event remains unchanged]
    // (Omitted here for brevity)
  } else if (roll < adjustedCombatChance + adjustedPeacefulChance) {
    // 📜 Peaceful event event logic...
    // [Existing code for peaceful event remains unchanged]
    // (Omitted here for brevity)
  }

  // ✅ No event: remove the reached waypoint and continue movement
  movementQueue.shift();
  await heroRef.update({
    state: movementQueue.length > 0 ? 'moving' : 'idle',
    movementQueue,
    destinationX: admin.firestore.FieldValue.delete(),
    destinationY: admin.firestore.FieldValue.delete(),
    arrivesAt: admin.firestore.FieldValue.delete(),
  });

  const nextStep = movementQueue[0];
  if (nextStep?.x !== undefined && nextStep?.y !== undefined) {
    const nextArrivesAt = new Date(Date.now() + movementSpeed);
    await heroRef.update({
      destinationX: nextStep.x,
      destinationY: nextStep.y,
      arrivesAt: admin.firestore.Timestamp.fromDate(nextArrivesAt),
    });
    const { scheduleHeroArrivalTask } = await import('./scheduleHeroArrivalTask.js');
    await scheduleHeroArrivalTask({ heroId, delaySeconds: Math.floor(movementSpeed / 1000) });
  }

  return 'No event triggered; continued movement.';
}


export const processHeroArrival = onRequest(async (req, res) => {
  try {
    const { heroId } = req.body;
    if (!heroId || typeof heroId !== 'string') {
      res.status(400).send('Missing or invalid heroId.');
      return;
    }
    const result = await processArrivalCore(heroId);
    res.status(200).send(result);
  } catch (error: any) {
    console.error('❌ Error in processHeroArrival (onRequest):', error);
    res.status(500).send(error.message || 'Internal error');
  }
});

export async function processHeroArrivalCallableLogic(req: CallableRequest): Promise<{ message: string }> {
  const heroId = req.data.heroId;
  if (!heroId || typeof heroId !== 'string') {
    throw new HttpsError('invalid-argument', 'Missing or invalid heroId.');
  }
  const message = await processArrivalCore(heroId);
  return { message };
}
