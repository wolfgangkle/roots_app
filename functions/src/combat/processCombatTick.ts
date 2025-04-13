import * as admin from 'firebase-admin';
import { onRequest, HttpsError } from 'firebase-functions/v2/https';

const TICK_INTERVAL_SECONDS = 15;
const MAX_TICKS = 500;

export const processCombatTick = onRequest(async (req, res) => {
  try {
    const { combatId } = req.body;
    if (!combatId || typeof combatId !== 'string') {
      throw new HttpsError('invalid-argument', 'Missing combatId.');
    }

    const db = admin.firestore();
    const combatRef = db.collection('combats').doc(combatId);
    const combatSnap = await combatRef.get();
    const combat = combatSnap.data();

    if (!combat || combat.state !== 'ongoing') {
      console.log(`⚠️ Combat ${combatId} missing or already ended. Skipping tick.`);
      res.status(200).send('Combat missing or ended.');
      return;
    }

    const heroId = combat.heroIds?.[0];
    if (!heroId) {
      throw new HttpsError('invalid-argument', 'No heroId found in combat document.');
    }

    const heroRef = db.collection('heroes').doc(heroId);
    const heroSnap = await heroRef.get();
    const hero = heroSnap.data();

    if (!hero) {
      throw new HttpsError('not-found', 'Hero not found.');
    }

    let minEnemyDamage = 3;
    let maxEnemyDamage = 7;

    if (combat.eventId) {
      const eventSnap = await db.collection('encounterEvents').doc(combat.eventId).get();
      const event = eventSnap.data();
      if (event?.enemy?.minDamage && event?.enemy?.maxDamage) {
        minEnemyDamage = event.enemy.minDamage;
        maxEnemyDamage = event.enemy.maxDamage;
      }
    }

    const now = Date.now();
    const heroMin = hero.combat?.attackMin ?? 5;
    const heroMax = hero.combat?.attackMax ?? 9;
    let heroAttack = 0;
    let targetIndex: number | null = null;

    const enemies = [...combat.enemies];
    const aliveIndexes = enemies.map((e, i) => e.hp > 0 ? i : -1).filter(i => i !== -1);

    if (aliveIndexes.length === 0) {
      console.log('⚠️ All enemies already dead.');
      await combatRef.update({ state: 'ended' });
      await heroRef.update({ state: 'idle' });
      res.status(200).send('Combat already over.');
      return;
    }

    if (now >= (combat.nextHeroAttackAt ?? 0)) {
      heroAttack = Math.floor(heroMin + Math.random() * (heroMax - heroMin + 1));
      targetIndex = aliveIndexes[Math.floor(Math.random() * aliveIndexes.length)];
      enemies[targetIndex].hp = Math.max(0, enemies[targetIndex].hp - heroAttack);
      combat.nextHeroAttackAt = now + (hero.combat?.attackSpeedMs ?? 150000);
    }

    let totalEnemyAttack = 0;
    const enemyAttacks: { index: number, damage: number }[] = [];

    enemies.forEach((enemy, index) => {
      if (enemy.hp <= 0) return;
      if (now >= (enemy.nextAttackAt ?? 0)) {
        const attack = Math.floor(minEnemyDamage + Math.random() * (maxEnemyDamage - minEnemyDamage + 1));
        totalEnemyAttack += attack;
        enemy.nextAttackAt = now + (enemy.attackSpeedMs ?? 30000);
        enemyAttacks.push({ index, damage: attack });
      }
    });

    const newHeroHp = Math.max(0, hero.hp - totalEnemyAttack);
    const tick = (combat.tick ?? 0) + 1;

    const allEnemiesDead = enemies.every(e => e.hp <= 0);
    const heroWon = allEnemiesDead && newHeroHp > 0;

    let newState = 'ongoing';
    if (newHeroHp <= 0 || tick >= MAX_TICKS || allEnemiesDead) {
      newState = 'ended';
    }

    const logRef = combatRef.collection('combatLog').doc(`tick_${tick}`);
    await logRef.set({
      tick,
      heroAttack,
      targetEnemyIndex: targetIndex,
      enemyAttack: totalEnemyAttack,
      enemyAttacks,
      heroHpAfter: newHeroHp,
      enemiesHpAfter: enemies.map(e => e.hp),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`🌀 Tick ${tick} | Hero → Enemy[${targetIndex}] for ${heroAttack} | Enemies → Hero for ${totalEnemyAttack}`);

    const finalHeroState = newHeroHp <= 0 ? 'dead' : (newState === 'ended' ? 'idle' : 'in_combat');

    await heroRef.update({
      hp: newHeroHp,
      state: finalHeroState,
    });

    if (finalHeroState === 'dead') {
      console.log(`☠️ Hero ${heroId} died during combat ${combatId}`);

      // Clear movement queue
      await heroRef.update({
        movementQueue: [],
        destinationX: admin.firestore.FieldValue.delete(),
        destinationY: admin.firestore.FieldValue.delete(),
        nextMoveAt: admin.firestore.FieldValue.delete(),
      });

      console.log(`🚫 Cleared movement queue for dead hero ${heroId}`);
    }

    await combatRef.update({
      tick,
      state: newState,
      enemies,
      nextHeroAttackAt: combat.nextHeroAttackAt,
      ...(newState === 'ended' && { endedAt: admin.firestore.FieldValue.serverTimestamp() }),
    });

    if (newState === 'ended' && heroWon && combat.enemyXpTotal) {
      const gainedXp = combat.enemyXpTotal;

      await heroRef.update({
        experience: admin.firestore.FieldValue.increment(gainedXp),
      });

      await combatRef.update({
        xp: gainedXp,
        reward: ['gold'], // or whatever reward was defined in encounterEvents
        message: `You defeated ${combat.enemyCount} ${combat.enemyName}(s) and gained ${gainedXp} XP.`,
      });

      console.log(`🎉 Hero ${heroId} won and gained ${gainedXp} XP`);
    }

    if (newState === 'ended') {
      const reportSnap = await db.collection('heroes')
        .doc(heroId)
        .collection('eventReports')
        .where('combatId', '==', combatId)
        .limit(1)
        .get();

      if (!reportSnap.empty) {
        const reportRef = reportSnap.docs[0].ref;

        await reportRef.update({
          state: 'completed',
          hiddenForUserIds: admin.firestore.FieldValue.arrayUnion(),
        });

        console.log(`📘 Marked report as completed for combat ${combatId}`);
      }

      // 🧭 Resume movement if hero survived and has waypoints
      if (
        finalHeroState === 'idle' &&
        Array.isArray(hero.movementQueue) &&
        hero.movementQueue.length > 0
      ) {
        const nextStep = hero.movementQueue[0];
        const remainingQueue = hero.movementQueue.slice(1);

        const movementSpeed = 20 * 60 * 1000; // 20 minutes
        const nextArrivesAt = new Date(Date.now() + movementSpeed);

        await heroRef.update({
          state: 'moving',
          destinationX: nextStep.x,
          destinationY: nextStep.y,
          arrivesAt: admin.firestore.Timestamp.fromDate(nextArrivesAt),
          movementQueue: remainingQueue,
        });

        const { scheduleHeroArrivalTask } = await import('../heroes/scheduleHeroArrivalTask.js');
        await scheduleHeroArrivalTask({
          heroId,
          delaySeconds: Math.floor(movementSpeed / 1000),
        });

        console.log(`🔁 Hero ${heroId} survived combat and continues to (${nextStep.x}, ${nextStep.y})`);
      }
    }

    if (newState === 'ongoing') {
      const { scheduleCombatTick } = await import('./scheduleCombatTick.js');
      await scheduleCombatTick({
        combatId,
        delaySeconds: TICK_INTERVAL_SECONDS,
      });
      console.log(`⏭️ Scheduled next tick for combat ${combatId}`);
    } else {
      console.log(`🏁 Combat ${combatId} ended.`);
    }

    res.status(200).send('Tick complete.');
  } catch (error: any) {
    console.error('❌ Error in processCombatTick:', error);
    res.status(500).send(error.message || 'Internal error');
  }
});
