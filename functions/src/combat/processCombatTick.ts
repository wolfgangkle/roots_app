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

    const now = Date.now();

    // ──────────────── PvP/HCV Mode Branch ────────────────
    // Either if the combat document was flagged as PvP
    // or if there is more than one hero and no NPC event (eventId is null)
    if ((combat.pvp === true) || (combat.heroIds && combat.heroIds.length > 1 && !combat.eventId)) {
      // Get all hero IDs participating in this combat.
      const heroIds: string[] = combat.heroIds || [];
      if (heroIds.length === 0) {
        throw new HttpsError('invalid-argument', 'No heroes found in combat document.');
      }

      // Fetch all hero documents.
      const heroDocs = await Promise.all(
        heroIds.map(id => db.collection('heroes').doc(id).get())
      );
      const heroes = heroDocs
        .map(doc => doc.data() ? { id: doc.id, data: doc.data()!, ref: doc.ref } : null)
        .filter((h): h is { id: string; data: any; ref: FirebaseFirestore.DocumentReference } => h !== null);

      if (heroes.length === 0) {
        throw new HttpsError('not-found', 'No valid heroes found in combat.');
      }

      // Filter alive heroes.
      let aliveHeroes = heroes.filter(h => h.data.hp !== undefined && h.data.hp > 0);

      // ── HERO ATTACK PHASE ──
      if (now >= (combat.nextHeroAttackAt ?? 0) && aliveHeroes.length > 0) {
        // Choose a random attacker.
        const attackerIndex = Math.floor(Math.random() * aliveHeroes.length);
        const attacker = aliveHeroes[attackerIndex];
        const attackerData = attacker.data;
        const heroMin = attackerData.combat?.attackMin ?? 5;
        const heroMax = attackerData.combat?.attackMax ?? 9;
        const heroAttack = Math.floor(heroMin + Math.random() * (heroMax - heroMin + 1));

        // Build potential targets from both enemies and other heroes.
        const potentialTargets: { type: 'enemy' | 'hero'; index?: number; heroId?: string }[] = [];
        const enemies = [...combat.enemies]; // make a copy
        for (let i = 0; i < enemies.length; i++) {
          if (enemies[i].hp > 0) {
            potentialTargets.push({ type: 'enemy', index: i });
          }
        }
        // Add other heroes as possible targets, skipping the attacker.
        for (const h of aliveHeroes) {
          if (h.id !== attacker.id) {
            potentialTargets.push({ type: 'hero', heroId: h.id });
          }
        }
        if (potentialTargets.length > 0) {
          const choice = potentialTargets[Math.floor(Math.random() * potentialTargets.length)];
          if (choice.type === 'enemy' && choice.index !== undefined) {
            enemies[choice.index].hp = Math.max(0, enemies[choice.index].hp - heroAttack);
            console.log(`🌀 PvP/HCV: Hero ${attacker.id} attacked enemy[${choice.index}] for ${heroAttack}`);
          } else if (choice.type === 'hero' && choice.heroId) {
            const targetHero = aliveHeroes.find(h => h.id === choice.heroId);
            if (targetHero) {
              targetHero.data.hp = Math.max(0, targetHero.data.hp - heroAttack);
              console.log(`🌀 PvP/HCV: Hero ${attacker.id} attacked hero ${targetHero.id} for ${heroAttack}`);
            }
          }
          combat.nextHeroAttackAt = now + (attackerData.combat?.attackSpeedMs ?? 150000);
        }
      }

      // ── ENEMY ATTACK PHASE ──
      const enemyAttacksLog: { enemyIndex: number; heroId: string; damage: number }[] = [];
      const enemies = [...combat.enemies];
      for (let i = 0; i < enemies.length; i++) {
        const enemy = enemies[i];
        if (enemy.hp <= 0) continue;
        const attackReady = now >= (enemy.nextAttackAt ?? 0);
        if (!attackReady) continue;
        const minDamage = enemy.minDamage ?? 1;
        const maxDamage = enemy.maxDamage ?? 3;
        const attackSpeed = enemy.attackSpeedMs ?? 90000;
        const attack = Math.floor(minDamage + Math.random() * (maxDamage - minDamage + 1));
        // Refresh alive heroes list in case HP changed.
        aliveHeroes = heroes.filter(h => h.data.hp !== undefined && h.data.hp > 0);
        if (aliveHeroes.length > 0) {
          const targetHero = aliveHeroes[Math.floor(Math.random() * aliveHeroes.length)];
          targetHero.data.hp = Math.max(0, targetHero.data.hp - attack);
          enemy.nextAttackAt = now + attackSpeed;
          enemyAttacksLog.push({ enemyIndex: i, heroId: targetHero.id, damage: attack });
          console.log(`🌀 PvP/HCV: Enemy[${i}] attacked hero ${targetHero.id} for ${attack}`);
        }
      }

      // ── Tick & Win Conditions ──
      const tick = (combat.tick ?? 0) + 1;
      const allEnemiesDead = enemies.every(e => e.hp <= 0);
      aliveHeroes = heroes.filter(h => h.data.hp !== undefined && h.data.hp > 0);
      const allHeroesDead = (aliveHeroes.length === 0);
      let newState = 'ongoing';
      if (allEnemiesDead || allHeroesDead || tick >= MAX_TICKS) {
        newState = 'ended';
      }
      // Log tick data.
      const logRef = combatRef.collection('combatLog').doc(`tick_${tick}`);
      await logRef.set({
        tick,
        heroAttack: 'various',
        enemyAttacks: enemyAttacksLog,
        heroesHpAfter: heroes.reduce((acc: Record<string, number>, h) => {
          acc[h.id] = h.data.hp;
          return acc;
        }, {}),
        enemiesHpAfter: enemies.map(e => e.hp),
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`🌀 Tick ${tick} processed in PvP/HCV mode.`);

      // ── Update Each Hero's Document in Combat ──
      for (const h of heroes) {
        let finalHeroState: 'dead' | 'moving' | 'idle' | 'in_combat';
        if (h.data.hp <= 0) {
          finalHeroState = 'dead';
          await h.ref.update({
            hp: h.data.hp,
            state: finalHeroState,
            movementQueue: [],
            destinationX: admin.firestore.FieldValue.delete(),
            destinationY: admin.firestore.FieldValue.delete(),
            arrivesAt: admin.firestore.FieldValue.delete(),
            nextMoveAt: admin.firestore.FieldValue.delete(),
          });
          console.log(`☠️ Hero ${h.id} died in combat ${combatId}`);
        } else if (newState === 'ended') {
          // Change condition to allow heroes in combat to resume movement if they have a queued waypoint.
          finalHeroState = (h.data.movementQueue && h.data.movementQueue.length > 0) ? 'moving' : 'idle';
          await h.ref.update({ hp: h.data.hp, state: finalHeroState });
        } else {
          finalHeroState = 'in_combat';
          await h.ref.update({
            hp: h.data.hp,
            state: finalHeroState,
            destinationX: admin.firestore.FieldValue.delete(),
            destinationY: admin.firestore.FieldValue.delete(),
            arrivesAt: admin.firestore.FieldValue.delete(),
          });
        }
      }

      // ── Award XP for Defeated NPC Enemies if Combat Ended ──
      if (newState === 'ended' && allEnemiesDead && combat.enemyXpTotal) {
        const survivors = heroes.filter(h => h.data.hp > 0);
        const xpPerHero = Math.floor(combat.enemyXpTotal / (survivors.length || 1));
        for (const h of survivors) {
          await h.ref.update({
            experience: admin.firestore.FieldValue.increment(xpPerHero)
          });
          console.log(`🎉 Hero ${h.id} gained ${xpPerHero} XP`);
        }
        await combatRef.update({
          xp: combat.enemyXpTotal,
          reward: ['gold'],
          message: `Defeated ${combat.enemyCount} ${combat.enemyName}(s) for ${combat.enemyXpTotal} XP.`,
        });
      }

      await combatRef.update({
        tick,
        state: newState,
        enemies,
        nextHeroAttackAt: combat.nextHeroAttackAt,
        ...(newState === 'ended' && { endedAt: admin.firestore.FieldValue.serverTimestamp() }),
      });

      // ── Resume Movement for Surviving Heroes if Combat Ended ──
      // Updated condition: check for heroes that have a non-empty movementQueue regardless if state is 'moving' or 'in_combat'
      if (newState === 'ended') {
        for (const h of heroes) {
          if (
            h.data.hp > 0 &&
            (h.data.state === 'moving' || h.data.state === 'in_combat') &&
            Array.isArray(h.data.movementQueue) &&
            h.data.movementQueue.length > 0
          ) {
            const nextStep = h.data.movementQueue[0];
            const remainingQueue = h.data.movementQueue.slice(1);
            // Use the hero's movementSpeed if available (assuming it's stored in seconds, convert if needed)
            const moveSpeed = typeof h.data.movementSpeed === 'number'
              ? h.data.movementSpeed * 1000 // converting seconds to ms
              : 20 * 60 * 1000;
            const nextArrivesAt = new Date(Date.now() + moveSpeed);
            await h.ref.update({
              state: 'moving', // set state to moving for resumption
              destinationX: nextStep.x,
              destinationY: nextStep.y,
              arrivesAt: admin.firestore.Timestamp.fromDate(nextArrivesAt),
              movementQueue: remainingQueue,
            });
            const { scheduleHeroArrivalTask } = await import('../heroes/scheduleHeroArrivalTask.js');
            await scheduleHeroArrivalTask({ heroId: h.id, delaySeconds: Math.floor(moveSpeed / 1000) });
            console.log(`🔁 Hero ${h.id} resumed movement to (${nextStep.x}, ${nextStep.y})`);
          }
        }
      }

      // ── Schedule Next Tick if Combat Still Ongoing ──
      if (newState === 'ongoing') {
        const { scheduleCombatTick } = await import('./scheduleCombatTick.js');
        await scheduleCombatTick({ combatId, delaySeconds: TICK_INTERVAL_SECONDS });
        console.log(`⏭️ Scheduled next tick for combat ${combatId}`);
      } else {
        console.log(`🏁 Combat ${combatId} ended.`);
      }

      res.status(200).send('Tick complete (PvP/HCV mode).');
      return;
    } // End PvP branch

    // ──────────────── Non-PvP (Original Single-Hero) Branch ────────────────
    const singleHeroId = combat.heroIds?.[0];
    if (!singleHeroId) {
      throw new HttpsError('invalid-argument', 'No heroId found in combat document.');
    }
    const singleHeroRef = db.collection('heroes').doc(singleHeroId);
    const singleHeroSnap = await singleHeroRef.get();
    const singleHero = singleHeroSnap.data();
    if (!singleHero) {
      throw new HttpsError('not-found', 'Hero not found.');
    }
    const heroMin = singleHero.combat?.attackMin ?? 5;
    const heroMax = singleHero.combat?.attackMax ?? 9;
    let heroAttack = 0;
    let targetIndex: number | null = null;
    const enemies = [...combat.enemies];
    const aliveIndexes = enemies.map((e, i) => (e.hp > 0 ? i : -1)).filter(i => i !== -1);
    if (aliveIndexes.length === 0) {
      console.log('⚠️ All enemies already dead.');
      await combatRef.update({ state: 'ended' });
      await singleHeroRef.update({ state: 'idle' });
      res.status(200).send('Combat already over.');
      return;
    }

    // Hero attacks
    if (now >= (combat.nextHeroAttackAt ?? 0)) {
      heroAttack = Math.floor(heroMin + Math.random() * (heroMax - heroMin + 1));
      targetIndex = aliveIndexes[Math.floor(Math.random() * aliveIndexes.length)];
      enemies[targetIndex].hp = Math.max(0, enemies[targetIndex].hp - heroAttack);
      combat.nextHeroAttackAt = now + (singleHero.combat?.attackSpeedMs ?? 150000);
    }

    // Enemies attack
    let totalEnemyAttack = 0;
    const enemyAttacks: { index: number; damage: number }[] = [];
    enemies.forEach((enemy, index) => {
      if (enemy.hp <= 0) return;
      const attackReady = now >= (enemy.nextAttackAt ?? 0);
      const minDamage = enemy.minDamage ?? 1;
      const maxDamage = enemy.maxDamage ?? 3;
      const attackSpeed = enemy.attackSpeedMs ?? 90000;
      if (attackReady) {
        const attack = Math.floor(minDamage + Math.random() * (maxDamage - minDamage + 1));
        totalEnemyAttack += attack;
        enemy.nextAttackAt = now + attackSpeed;
        enemyAttacks.push({ index, damage: attack });
      }
    });

    const newHeroHp = Math.max(0, singleHero.hp - totalEnemyAttack);
    const tick = (combat.tick ?? 0) + 1;
    const allEnemiesDead = enemies.every(e => e.hp <= 0);
    const heroWon = allEnemiesDead && newHeroHp > 0;
    let newState = 'ongoing';
    if (newHeroHp <= 0 || tick >= MAX_TICKS || allEnemiesDead) {
      newState = 'ended';
    }

    // Log tick details.
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

    // Update hero state accordingly.
    let finalHeroState: 'dead' | 'moving' | 'idle' | 'in_combat';
    if (newHeroHp <= 0) {
      finalHeroState = 'dead';
      await singleHeroRef.update({
        movementQueue: [],
        state: finalHeroState,
        destinationX: admin.firestore.FieldValue.delete(),
        destinationY: admin.firestore.FieldValue.delete(),
        nextMoveAt: admin.firestore.FieldValue.delete(),
      });
      console.log(`☠️ Hero ${singleHeroId} died during combat ${combatId}`);
    } else if (newState === 'ended') {
      finalHeroState = (singleHero.movementQueue && singleHero.movementQueue.length > 0) ? 'moving' : 'idle';
      await singleHeroRef.update({ hp: newHeroHp, state: finalHeroState });
    } else {
      finalHeroState = 'in_combat';
      await singleHeroRef.update({
        hp: newHeroHp,
        state: finalHeroState,
        destinationX: admin.firestore.FieldValue.delete(),
        destinationY: admin.firestore.FieldValue.delete(),
        arrivesAt: admin.firestore.FieldValue.delete(),
      });
    }

    if (newState === 'ended' && heroWon && combat.enemyXpTotal) {
      const gainedXp = combat.enemyXpTotal;
      await singleHeroRef.update({
        experience: admin.firestore.FieldValue.increment(gainedXp)
      });
      await combatRef.update({
        xp: gainedXp,
        reward: ['gold'],
        message: `Defeated ${combat.enemyCount} ${combat.enemyName}(s) for ${gainedXp} XP.`,
      });
      console.log(`🎉 Hero ${singleHeroId} won and gained ${gainedXp} XP`);
    }

    await combatRef.update({
      tick,
      state: newState,
      enemies,
      nextHeroAttackAt: combat.nextHeroAttackAt,
      ...(newState === 'ended' && { endedAt: admin.firestore.FieldValue.serverTimestamp() }),
    });

    if (newState === 'ended') {
      const reportSnap = await db.collection('heroes')
        .doc(singleHeroId)
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
      if (finalHeroState === 'moving' && Array.isArray(singleHero.movementQueue) && singleHero.movementQueue.length > 0) {
        const nextStep = singleHero.movementQueue[0];
        const remainingQueue = singleHero.movementQueue.slice(1);
        // Convert movementSpeed from seconds to milliseconds when resuming.
        const moveSpeed = typeof singleHero.movementSpeed === 'number'
          ? singleHero.movementSpeed * 1000
          : 20 * 60 * 1000;
        const nextArrivesAt = new Date(Date.now() + moveSpeed);
        await singleHeroRef.update({
          destinationX: nextStep.x,
          destinationY: nextStep.y,
          arrivesAt: admin.firestore.Timestamp.fromDate(nextArrivesAt),
          movementQueue: remainingQueue,
        });
        const { scheduleHeroArrivalTask } = await import('../heroes/scheduleHeroArrivalTask.js');
        await scheduleHeroArrivalTask({ heroId: singleHeroId, delaySeconds: Math.floor(moveSpeed / 1000) });
        console.log(`🔁 Hero ${singleHeroId} resumed movement to (${nextStep.x}, ${nextStep.y})`);
      }
    }

    if (newState === 'ongoing') {
      const { scheduleCombatTick } = await import('./scheduleCombatTick.js');
      await scheduleCombatTick({ combatId, delaySeconds: TICK_INTERVAL_SECONDS });
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
