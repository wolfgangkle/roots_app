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

  if (!hero) {
    console.error(`❌ Hero not found for ID: ${heroId}`);
    throw new HttpsError('not-found', 'Hero not found.');
  }

  // Validate hero state and required fields.
  if (
    hero.state !== 'moving' ||
    hero.destinationX === undefined ||
    hero.destinationY === undefined ||
    !hero.arrivesAt
  ) {
    console.warn(`⚠️ Hero ${heroId} is not in a valid 'moving' state`);
    throw new HttpsError('failed-precondition', 'Hero is not currently moving.');
  }

  const now = Date.now();
  const arrivalTimestamp = hero.arrivesAt.toMillis();

  if (now < arrivalTimestamp) {
    const retryCount = hero.retryCount ?? 0;
    if (retryCount >= MAX_RETRY_COUNT) {
      console.error(`🚫 Retry limit reached for hero ${heroId}. Not rescheduling.`);
      return 'Too early, but retry limit reached. Skipping reschedule.';
    }
    const retryDelay = 30;
    console.warn(`⏱️ Task executed early for hero ${heroId}. Rescheduling in ${retryDelay}s (retry #${retryCount + 1}).`);
    const { scheduleHeroArrivalTask } = await import('./scheduleHeroArrivalTask.js');
    await heroRef.update({ retryCount: retryCount + 1 });
    await scheduleHeroArrivalTask({ heroId, delaySeconds: retryDelay });
    return 'Task too early — rescheduled.';
  }

  // Determine movement speed (using hero's movementSpeed if available).
  const movementSpeed = (hero.movementSpeed && typeof hero.movementSpeed === 'number')
    ? hero.movementSpeed
    : 20 * 60 * 1000;

  // Save the origin tile (starting position) before teleportation.
  const originX = hero.tileX;
  const originY = hero.tileY;

  // The intended destination tile.
  const destinationX = hero.destinationX;
  const destinationY = hero.destinationY;

  // **************************************
  // Check destination tile for conflict
  // **************************************
  const destConflictSnap = await db.collection('heroes')
    .where('tileX', '==', destinationX)
    .where('tileY', '==', destinationY)
    .get();
  // Filter out our own hero.
  const conflictingHeroes = destConflictSnap.docs.filter(doc => doc.id !== heroId);

  if (conflictingHeroes.length > 0) {
    // For all heroes already on this destination tile (i.e. the ones getting interrupted),
    // update their record to store their current destination tile into 'reservedDestination'.
    for (const conflictDoc of conflictingHeroes) {
      const conflictHero = conflictDoc.data();
      // Only update those whose state is "moving", implying they were planning further movement.
      if (conflictHero.state === 'moving') {
        const reserved = (conflictHero.destinationX !== undefined && conflictHero.destinationY !== undefined)
          ? { x: conflictHero.destinationX, y: conflictHero.destinationY }
          : null;
        await conflictDoc.ref.update({
          reservedDestination: reserved ? reserved : admin.firestore.FieldValue.delete()
        });
      }
    }

    // There is at least one other hero on the destination tile.
    // First, see if there is an ongoing combat on this tile.
    const combatSnap = await db.collection('combats')
      .where('tileX', '==', destinationX)
      .where('tileY', '==', destinationY)
      .where('state', '==', 'ongoing')
      .limit(1)
      .get();
    if (!combatSnap.empty) {
      // An ongoing combat exists.
      // Update the arriving hero's position to the destination before joining.
      await heroRef.update({
        tileX: destinationX,
        tileY: destinationY,
        tileKey: `${destinationX}_${destinationY}`,
      });

      // Join that fight (creating a hybrid PvP/PvE combat).
      const combatDoc = combatSnap.docs[0];
      await combatDoc.ref.update({
        heroIds: admin.firestore.FieldValue.arrayUnion(heroId)
      });
      await heroRef.update({ state: 'in_combat' });
      console.log(`🌀 Hero ${heroId} joined existing combat on tile (${destinationX}, ${destinationY}).`);
      // Create a combat report for the joining hero.
      const reportRef = db.collection('heroes').doc(heroId).collection('eventReports').doc();
      await reportRef.set({
        type: 'combat',
        title: 'Hero vs Hero Battle',
        state: 'ongoing',
        combatId: combatDoc.id,
        heroId: heroId,
        // If the combat is hybrid (has an eventId), add that as well.
        ...(combatDoc.data()?.eventId ? { eventId: combatDoc.data()?.eventId } : {}),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return 'Joined existing combat; movement paused at destination.';
    } else {
      // No ongoing combat exists; trigger a new PvP combat.
      await heroRef.update({
        tileX: destinationX,
        tileY: destinationY,
        tileKey: `${destinationX}_${destinationY}`,
      });

      await heroRef.update({ state: 'in_combat' });
      console.log(`🌀 PvP condition triggered for hero ${heroId} upon arriving at destination (${destinationX}, ${destinationY}).`);

      const existingHeroId = conflictingHeroes[0].id;
      const newCombatDoc = {
        groupId: null,
        heroIds: [existingHeroId, heroId],
        tileX: destinationX,
        tileY: destinationY,
        eventId: null, // Pure PvP (no NPC event)
        enemyType: null,
        enemyCount: 0,
        enemies: [],
        nextHeroAttackAt: now + (hero.combat?.attackSpeedMs ?? 150000),
        tick: 0,
        state: 'ongoing',
        pvp: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      const combatSnapshot = await db.collection('combats').add(newCombatDoc);
      console.log(`⚔️ New PvP combat created between hero ${existingHeroId} and hero ${heroId} at tile (${destinationX}, ${destinationY}).`);

      // Create combat reports for both heroes.
      for (const reportHeroId of [existingHeroId, heroId]) {
        const reportRef = db.collection('heroes').doc(reportHeroId).collection('eventReports').doc();
        await reportRef.set({
          type: 'combat',
          title: 'Hero vs Hero Battle',
          state: 'ongoing',
          combatId: combatSnapshot.id,
          heroId: reportHeroId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Schedule the first tick for the newly created PvP combat.
      const { scheduleCombatTick } = await import('../combat/scheduleCombatTick.js');
      await scheduleCombatTick({ combatId: combatSnapshot.id, delaySeconds: 3 });
      return 'PvP combat triggered; movement paused at destination.';
    }
  }
  // End of destination conflict check.
  // **************************************

  // Teleport the hero by updating the tile coordinates.
  await heroRef.update({
    tileX: destinationX,
    tileY: destinationY,
    tileKey: `${destinationX}_${destinationY}`,
    nextTileKey: admin.firestore.FieldValue.delete(),
    retryCount: admin.firestore.FieldValue.delete(),
  });
  console.log(`🚀 Teleported hero ${heroId} from (${originX}, ${originY}) to (${destinationX}, ${destinationY}).`);

  // Now perform an event roll at the arrival tile.
  const roll = Math.random();
  console.log(`🎲 Event roll for hero ${heroId} at (${destinationX}, ${destinationY}): ${roll.toFixed(2)}`);

  // Retrieve a copy of the movementQueue.
  const movementQueue: Array<{ x: number; y: number }> = Array.isArray(hero.movementQueue)
    ? [...hero.movementQueue]
    : [];

  if (roll < COMBAT_CHANCE) {
    // ► PvE Combat event triggered.
    let reserved: { x: number; y: number } | undefined;
    let updatedQueue = movementQueue;
    if (movementQueue.length > 0) {
      reserved = movementQueue[0];
      updatedQueue = movementQueue.slice(1);
    }
    await heroRef.update({
      state: 'in_combat',
      reservedDestination: reserved ? reserved : admin.firestore.FieldValue.delete(),
      movementQueue: updatedQueue
    });
    console.log(`⚔️ Combat event triggered at tile (${destinationX}, ${destinationY}) for hero ${heroId}.`);
    const combatLevel = hero.combat?.combatLevel ?? 1;
    const eventSnap = await db.collection('encounterEvents')
      .where('type', '==', 'combat')
      .where('minCombatLevel', '<=', combatLevel)
      .where('maxCombatLevel', '>=', combatLevel)
      .get();
    if (eventSnap.empty) {
      console.warn(`⚠️ No combat events found for level ${combatLevel}. Defaulting hero state to idle.`);
      await heroRef.update({ state: 'idle' });
    } else {
      const picked = eventSnap.docs[Math.floor(Math.random() * eventSnap.docs.length)];
      const event = picked.data();
      const eventId = picked.id;
      const allowedTypes: string[] = event.enemyTypes ?? [];
      if (allowedTypes.length === 0) {
        console.warn(`⚠️ Combat event ${eventId} has no enemyTypes.`);
        await heroRef.update({ state: 'idle' });
      } else {
        const chosenEnemyType = allowedTypes[Math.floor(Math.random() * allowedTypes.length)];
        const enemySnap = await db.collection('enemyTypes').doc(chosenEnemyType).get();
        const enemy = enemySnap.data();
        if (!enemy || !enemy.combatLevel) {
          console.warn(`⚠️ EnemyType ${chosenEnemyType} not found or missing combatLevel.`);
          await heroRef.update({ state: 'idle' });
        } else {
          const heroLevel = hero.combat?.combatLevel ?? 1;
          const enemyLevel = enemy.combatLevel ?? 1;
          const enemyCount = Math.max(1, Math.floor(heroLevel / enemyLevel));
          const enemies = Array.from({ length: enemyCount }, () => ({
            hp: enemy.hp ?? 10,
            minDamage: enemy.minDamage ?? 1,
            maxDamage: enemy.maxDamage ?? 3,
            attackSpeedMs: enemy.attackSpeedMs ?? 30000,
            nextAttackAt: now + (enemy.attackSpeedMs ?? 30000),
            combatLevel: enemy.combatLevel,
          }));
          const nextHeroAttackAt = now + (hero.combat?.attackSpeedMs ?? 150000);
          const combatDoc = {
            groupId: null,
            heroIds: [heroId],
            tileX: destinationX,
            tileY: destinationY,
            eventId,
            enemyType: chosenEnemyType,
            enemyCount,
            enemies,
            nextHeroAttackAt,
            enemyName: enemy.name ?? chosenEnemyType,
            enemyXpTotal: enemy.xp ? enemy.xp * enemyCount : 0,
            tick: 0,
            state: 'ongoing',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          };
          const combatRef = await db.collection('combats').add(combatDoc);
          console.log(`⚔️ Combat triggered with ${enemyCount} x ${chosenEnemyType} (${enemy.hp} HP each) from event ${eventId}`);
          const { scheduleCombatTick } = await import('../combat/scheduleCombatTick.js');
          await scheduleCombatTick({ combatId: combatRef.id, delaySeconds: 3 });
          const reportRef = db.collection('heroes').doc(heroId).collection('eventReports').doc();
          await reportRef.set({
            type: 'combat',
            title: event.title ?? `Combat vs ${chosenEnemyType}`,
            state: 'ongoing',
            combatId: combatRef.id,
            eventId,
            heroId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }
    }
    // For PvE events, do not consume the reached waypoint (we have already consumed one if available)
    return 'Combat event triggered; movement paused at arrival.';
  } else if (roll < COMBAT_CHANCE + PEACEFUL_CHANCE) {
    // ► Peaceful event triggered.
    await heroRef.update({
      destinationX: admin.firestore.FieldValue.delete(),
      destinationY: admin.firestore.FieldValue.delete(),
      arrivesAt: admin.firestore.FieldValue.delete()
    });
    await heroRef.update({ state: 'idle' });
    console.log(`📜 Peaceful event triggered at tile (${destinationX}, ${destinationY}) for hero ${heroId}.`);
    const combatLevel = hero.combat?.combatLevel ?? 1;
    const peacefulSnap = await db.collection('encounterEvents')
      .where('type', '==', 'peaceful')
      .where('minCombatLevel', '<=', combatLevel)
      .where('maxCombatLevel', '>=', combatLevel)
      .get();
    if (!peacefulSnap.empty) {
      const picked = peacefulSnap.docs[Math.floor(Math.random() * peacefulSnap.docs.length)];
      const data = picked.data();
      const reportRef = db.collection('heroes').doc(heroId).collection('eventReports').doc();
      await reportRef.set({
        type: 'peaceful',
        title: data.title ?? 'Untitled Event',
        message: data.description ?? 'You experienced a strange feeling...',
        xp: data.reward?.xp ?? 0,
        eventId: picked.id,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`📜 Peaceful event report created for hero ${heroId}.`);
    }
    movementQueue.shift();
    await heroRef.update({ movementQueue, state: movementQueue.length > 0 ? 'moving' : 'idle' });
    if (movementQueue.length > 0) {
      const nextStep = movementQueue[0];
      const nextArrivesAt = new Date(Date.now() + movementSpeed);
      await heroRef.update({
        destinationX: nextStep.x,
        destinationY: nextStep.y,
        arrivesAt: admin.firestore.Timestamp.fromDate(nextArrivesAt),
      });
      const { scheduleHeroArrivalTask } = await import('./scheduleHeroArrivalTask.js');
      await scheduleHeroArrivalTask({ heroId, delaySeconds: Math.floor(movementSpeed / 1000) });
      console.log(`🔁 Scheduled next movement to (${nextStep.x}, ${nextStep.y}) for hero ${heroId}.`);
    }
    return 'Peaceful event processed; movement updated.';
  } else {
    // ► No event triggered.
    await heroRef.update({ state: 'idle' });
    console.log(`✅ No event triggered at tile (${destinationX}, ${destinationY}) for hero ${heroId}.`);
    await heroRef.update({
      destinationX: admin.firestore.FieldValue.delete(),
      destinationY: admin.firestore.FieldValue.delete(),
      arrivesAt: admin.firestore.FieldValue.delete()
    });
    movementQueue.shift();
    await heroRef.update({ movementQueue, state: movementQueue.length > 0 ? 'moving' : 'idle' });
    if (movementQueue.length > 0) {
      const nextStep = movementQueue[0];
      const nextArrivesAt = new Date(Date.now() + movementSpeed);
      await heroRef.update({
        destinationX: nextStep.x,
        destinationY: nextStep.y,
        arrivesAt: admin.firestore.Timestamp.fromDate(nextArrivesAt),
      });
      const { scheduleHeroArrivalTask } = await import('./scheduleHeroArrivalTask.js');
      await scheduleHeroArrivalTask({ heroId, delaySeconds: Math.floor(movementSpeed / 1000) });
      console.log(`🔁 Scheduled next movement to (${nextStep.x}, ${nextStep.y}) for hero ${heroId}.`);
    }
    return 'Arrival processed without event; movement updated.';
  }
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
