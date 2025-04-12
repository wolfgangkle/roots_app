import * as admin from 'firebase-admin';
import { onRequest, HttpsError, CallableRequest } from 'firebase-functions/v2/https';

const COMBAT_CHANCE = 0.5;
const PEACEFUL_CHANCE = 0.3;
const MAX_RETRY_COUNT = 5;

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

  if (hero.state !== 'moving' || !hero.destinationX || !hero.destinationY || !hero.arrivesAt) {
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

    await scheduleHeroArrivalTask({
      heroId,
      delaySeconds: retryDelay,
    });

    return 'Task too early — rescheduled.';
  }

  const newTileX = hero.destinationX;
  const newTileY = hero.destinationY;

  const updates: any = {
    tileX: newTileX,
    tileY: newTileY,
    destinationX: admin.firestore.FieldValue.delete(),
    destinationY: admin.firestore.FieldValue.delete(),
    arrivesAt: admin.firestore.FieldValue.delete(),
    retryCount: admin.firestore.FieldValue.delete(),
  };

  const roll = Math.random();
  console.log(`🎲 Hero ${heroId} rolled ${roll.toFixed(2)}`);
  const combatLevel = hero.combat?.combatLevel ?? 1;

  // 🔥 COMBAT ENCOUNTER HANDLING
  if (roll < COMBAT_CHANCE) {
    updates.state = 'in_combat';

    const eventSnap = await db.collection('encounterEvents')
      .where('type', '==', 'combat')
      .where('minCombatLevel', '<=', combatLevel)
      .where('maxCombatLevel', '>=', combatLevel)
      .get();

    if (eventSnap.empty) {
      console.warn(`⚠️ No combat events found for level ${combatLevel}. Defaulting to idle.`);
      updates.state = 'idle';
    } else {
      const picked = eventSnap.docs[Math.floor(Math.random() * eventSnap.docs.length)];
      const event = picked.data();
      const eventId = picked.id;

      const allowedTypes: string[] = event.enemyTypes ?? [];
      if (allowedTypes.length === 0) {
        console.warn(`⚠️ Combat event ${eventId} has no enemyTypes.`);
        updates.state = 'idle';
      } else {
        const chosenEnemyType = allowedTypes[Math.floor(Math.random() * allowedTypes.length)];
        const enemySnap = await db.collection('enemyTypes').doc(chosenEnemyType).get();
        const enemy = enemySnap.data();

        if (!enemy || !enemy.combatLevel) {
          console.warn(`⚠️ EnemyType ${chosenEnemyType} not found or missing combatLevel.`);
          updates.state = 'idle';
        } else {
          const heroLevel = hero.combat?.combatLevel ?? 1;
          const enemyLevel = enemy.combatLevel ?? 1;
          const enemyCount = Math.max(1, Math.floor(heroLevel / enemyLevel));

          const enemies = Array.from({ length: enemyCount }, () => ({
            hp: enemy.hp,
            nextAttackAt: now + (enemy.attackSpeedMs ?? 30000),
          }));

          const nextHeroAttackAt = now + (hero.combat?.attackSpeedMs ?? 150000);

          const combatDoc = {
            groupId: null,
            heroIds: [heroId],
            tileX: newTileX,
            tileY: newTileY,
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
          await scheduleCombatTick({
            combatId: combatRef.id,
            delaySeconds: 3,
          });

          // ✅ Create combat report
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

  } else if (roll < COMBAT_CHANCE + PEACEFUL_CHANCE) {
    updates.state = 'idle';

    const peacefulSnap = await db.collection('encounterEvents')
      .where('type', '==', 'peaceful')
      .where('minCombatLevel', '<=', combatLevel)
      .where('maxCombatLevel', '>=', combatLevel)
      .get();

    if (peacefulSnap.empty) {
      console.warn(`⚠️ No peaceful events found for level ${combatLevel}. Logging no event.`);
    } else {
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

      console.log(`📜 Peaceful event "${picked.id}" triggered for hero ${heroId}`);
    }

  } else {
    updates.state = 'idle';
    console.log(`🧍 Hero ${heroId} arrived at (${newTileX}, ${newTileY}) without incident.`);
  }

  await heroRef.update(updates);

  if (hero.movementQueue && Array.isArray(hero.movementQueue) && hero.movementQueue.length > 0) {
    const nextStep = hero.movementQueue[0];
    const remainingQueue = hero.movementQueue.slice(1);

    const movementSpeed = 20 * 60 * 1000;
    const nextArrivesAt = new Date(Date.now() + movementSpeed);

    await heroRef.update({
      state: 'moving',
      destinationX: nextStep.x,
      destinationY: nextStep.y,
      arrivesAt: admin.firestore.Timestamp.fromDate(nextArrivesAt),
      movementQueue: remainingQueue,
    });

    const { scheduleHeroArrivalTask } = await import('./scheduleHeroArrivalTask.js');
    await scheduleHeroArrivalTask({
      heroId,
      delaySeconds: Math.floor(movementSpeed / 1000),
    });

    console.log(`🔁 Continued movement to (${nextStep.x}, ${nextStep.y})`);
  }

  return 'Hero arrival processed.';
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
