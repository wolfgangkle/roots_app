import * as admin from 'firebase-admin';
import { onRequest } from 'firebase-functions/v2/https';
import { HttpsError } from 'firebase-functions/v2/https';

const db = admin.firestore();

// Random event roll thresholds
const COMBAT_CHANCE = 0.2;
const PEACEFUL_CHANCE = 0.3;

export const processHeroArrival = onRequest(async (req, res) => {
  try {
    const { heroId } = req.body;
    if (!heroId || typeof heroId !== 'string') {
      throw new HttpsError('invalid-argument', 'Missing heroId.');
    }

    const heroRef = db.collection('heroes').doc(heroId);
    const heroSnap = await heroRef.get();
    const hero = heroSnap.data();

    if (!hero) {
      throw new HttpsError('not-found', 'Hero not found.');
    }

    if (hero.state !== 'moving' || !hero.destinationX || !hero.destinationY || !hero.arrivesAt) {
      throw new HttpsError('failed-precondition', 'Hero is not currently moving.');
    }

    const now = Date.now();
    const arrivalTimestamp = hero.arrivesAt.toMillis();
    if (now < arrivalTimestamp) {
      console.warn(`⏱️ Task executed early for hero ${heroId}. Aborting.`);
      res.status(200).send('Too early, skipping.');
      return;
    }

    // ✅ Move the hero
    const newTileX = hero.destinationX;
    const newTileY = hero.destinationY;

    const updates: any = {
      tileX: newTileX,
      tileY: newTileY,
      destinationX: admin.firestore.FieldValue.delete(),
      destinationY: admin.firestore.FieldValue.delete(),
      arrivesAt: admin.firestore.FieldValue.delete(),
    };

    // 🎲 Roll for event
    const roll = Math.random();
    console.log(`🎲 Hero ${heroId} rolled ${roll.toFixed(2)}`);

    if (roll < COMBAT_CHANCE) {
      // ⚔️ Trigger combat
      updates.state = 'in_combat';

      // Optional: create a combat document
      const combatRef = await db.collection('combats').add({
        heroId,
        tileX: newTileX,
        tileY: newTileY,
        enemyType: 'bandits', // TODO: randomize or tile-based
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        state: 'ongoing',
        tick: 0,
      });

      console.log(`⚔️ Combat started for hero ${heroId} at combat ${combatRef.id}`);
    } else if (roll < COMBAT_CHANCE + PEACEFUL_CHANCE) {
      // 🌼 Peaceful event
      updates.state = 'idle';

      const reportRef = db
        .collection('heroes')
        .doc(heroId)
        .collection('eventReports')
        .doc();

      await reportRef.set({
        type: 'peaceful',
        message: 'You found an ancient mossy shrine. It hums quietly.',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`📜 Peaceful event logged for hero ${heroId}`);
    } else {
      // 🚶 No event
      updates.state = 'idle';
      console.log(`🧍 Hero ${heroId} arrived at (${newTileX}, ${newTileY}) without incident.`);
    }

    // ✅ Apply updates
    await heroRef.update(updates);

    // 🔁 Continue movement if waypoints exist
    if (hero.movementQueue && Array.isArray(hero.movementQueue) && hero.movementQueue.length > 0) {
      const nextStep = hero.movementQueue[0];
      const remainingQueue = hero.movementQueue.slice(1);

      const movementSpeed = 20 * 60 * 1000; // 20 min per tile
      const nextArrivesAt = new Date(Date.now() + movementSpeed);

      await heroRef.update({
        state: 'moving',
        destinationX: nextStep.x,
        destinationY: nextStep.y,
        arrivesAt: admin.firestore.Timestamp.fromDate(nextArrivesAt),
        movementQueue: remainingQueue,
      });

      // Schedule next task
      const { scheduleHeroArrivalTask } = await import('./scheduleHeroArrivalTask.js');
      await scheduleHeroArrivalTask({
        heroId,
        delaySeconds: Math.floor(movementSpeed / 1000),
      });

      console.log(`🔁 Continued movement to (${nextStep.x}, ${nextStep.y})`);
    }

    res.status(200).send('Hero arrival processed.');
  } catch (error: any) {
    console.error('❌ Error in processHeroArrival:', error);
    res.status(500).send(error.message || 'Internal error');
  }
});
