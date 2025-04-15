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
    // This branch applies if combat.pvp === true or if there is more than one hero and no NPC event.
    if ((combat.pvp === true) || (combat.heroIds && combat.heroIds.length > 1 && !combat.eventId)) {
      // Get all hero IDs from the combat document.
      const heroIds: string[] = combat.heroIds || [];
      if (heroIds.length === 0) {
        throw new HttpsError('invalid-argument', 'No heroes found in combat document.');
      }

      // Fetch hero documents.
      const heroDocs = await Promise.all(
        heroIds.map(id => db.collection('heroes').doc(id).get())
      );
      const heroes = heroDocs
        .map(doc => doc.data() ? { id: doc.id, data: doc.data()!, ref: doc.ref } : null)
        .filter((h): h is { id: string; data: any; ref: FirebaseFirestore.DocumentReference } => h !== null);
      if (heroes.length === 0) {
        throw new HttpsError('not-found', 'No valid heroes found in combat.');
      }

      // Filter alive heroes based on their hp.
      let aliveHeroes = heroes.filter(h => h.data.hp !== undefined && h.data.hp > 0);

      // Copy the enemies array from the combat document.
      let enemies = [...combat.enemies];

      // Initialize an array to collect detailed hero attack logs.
      const heroAttackLogs: Array<{ attackerId: string; targetType: 'enemy' | 'hero'; target: string | number; damage: number }> = [];

      // ── HERO ATTACK PHASE (Individual Attack Timers) ──
      // Instead of a single global timer, loop through each hero and check their own nextAttackAt timestamp.
      for (const hero of aliveHeroes) {
        const heroNextAttackAt = hero.data.combat?.nextAttackAt ?? 0;
        if (now >= heroNextAttackAt) {
          const heroMin = hero.data.combat?.attackMin ?? 5;
          const heroMax = hero.data.combat?.attackMax ?? 9;
          const damage = Math.floor(heroMin + Math.random() * (heroMax - heroMin + 1));

          // Build potential targets (NPC enemies and other heroes, excluding self).
          const potentialTargets: Array<{ type: 'enemy' | 'hero'; index?: number; heroId?: string }> = [];
          for (let i = 0; i < enemies.length; i++) {
            if (enemies[i].hp > 0) {
              potentialTargets.push({ type: 'enemy', index: i });
            }
          }
          for (const otherHero of aliveHeroes) {
            if (otherHero.id !== hero.id) {
              potentialTargets.push({ type: 'hero', heroId: otherHero.id });
            }
          }
          if (potentialTargets.length > 0) {
            const choice = potentialTargets[Math.floor(Math.random() * potentialTargets.length)];
            if (choice.type === 'enemy' && choice.index !== undefined) {
              enemies[choice.index].hp = Math.max(0, enemies[choice.index].hp - damage);
              heroAttackLogs.push({ attackerId: hero.id, targetType: 'enemy', target: choice.index, damage });
              console.log(`🌀 PvP/HCV: Hero ${hero.id} attacked enemy[${choice.index}] for ${damage}`);
            } else if (choice.type === 'hero' && choice.heroId) {
              const targetHero = aliveHeroes.find(h => h.id === choice.heroId);
              if (targetHero) {
                targetHero.data.hp = Math.max(0, targetHero.data.hp - damage);
                heroAttackLogs.push({ attackerId: hero.id, targetType: 'hero', target: targetHero.id, damage });
                console.log(`🌀 PvP/HCV: Hero ${hero.id} attacked hero ${targetHero.id} for ${damage}`);
              }
            }
          }
          // Update the hero's next attack time individually.
          const attackSpeed = hero.data.combat?.attackSpeedMs ?? 150000;
          const newNextAttackAt = now + attackSpeed;
          hero.data.combat = { ...hero.data.combat, nextAttackAt: newNextAttackAt };
          await hero.ref.update({ "combat.nextAttackAt": newNextAttackAt });
        }
      }

      // ── ENEMY ATTACK PHASE (Simultaneous Targeting) ──
      // Instead of updating hp after each enemy attack, we capture a snapshot of targets at the beginning
      // and accumulate damage per hero. This simulates simultaneous attacks.
      const enemyAttacksLog: Array<{ enemyIndex: number; heroId: string; damage: number }> = [];
      // Snapshot of alive heroes before enemy attacks.
      const targetHeroesSnapshot = heroes.filter(h => h.data.hp !== undefined && h.data.hp > 0);
      const heroDamageMap: { [heroId: string]: number } = {}; // Accumulator for each hero's damage.
      for (let i = 0; i < enemies.length; i++) {
        const enemy = enemies[i];
        if (enemy.hp <= 0) continue;
        const attackReady = now >= (enemy.nextAttackAt ?? 0);
        if (!attackReady) continue;
        const minDamage = enemy.minDamage ?? 1;
        const maxDamage = enemy.maxDamage ?? 3;
        const attackSpeed = enemy.attackSpeedMs ?? 90000;
        const attackDamage = Math.floor(minDamage + Math.random() * (maxDamage - minDamage + 1));
        if (targetHeroesSnapshot.length > 0) {
          // Choose a target from the snapshot (same snapshot used for all enemy attacks this tick)
          const targetHero = targetHeroesSnapshot[Math.floor(Math.random() * targetHeroesSnapshot.length)];
          // Accumulate damage for that hero.
          heroDamageMap[targetHero.id] = (heroDamageMap[targetHero.id] || 0) + attackDamage;
          enemy.nextAttackAt = now + attackSpeed;
          enemyAttacksLog.push({ enemyIndex: i, heroId: targetHero.id, damage: attackDamage });
          console.log(`🌀 PvP/HCV: Enemy[${i}] attacked hero ${targetHero.id} for ${attackDamage}`);
        }
      }
      // After processing all enemy attacks, update each targeted hero's hp with the accumulated damage.
      for (const hero of heroes) {
        if (heroDamageMap[hero.id]) {
          hero.data.hp = Math.max(0, hero.data.hp - heroDamageMap[hero.id]);
        }
      }

      // ── Tick & Win Conditions ──
      const tick = (combat.tick ?? 0) + 1;
      // Refresh list of living heroes.
      aliveHeroes = heroes.filter(h => h.data.hp !== undefined && h.data.hp > 0);
      let newState = 'ongoing';
      const npcAliveCount = combat.eventId ? enemies.filter(e => e.hp > 0).length : 0;
      if (tick >= MAX_TICKS) {
        newState = 'ended';
      } else if (combat.eventId) {
        if (npcAliveCount > 0) {
          if (aliveHeroes.length === 0) newState = 'ended';
        } else {
          if (aliveHeroes.length < 2) newState = 'ended';
        }
      } else {
        if (aliveHeroes.length < 2) newState = 'ended';
      }

      const allEnemiesDead = combat.eventId
        ? (enemies.length > 0 ? enemies.every(e => e.hp <= 0) : false)
        : false;

      // ── Award XP for Defeated NPC Enemies if Combat Ended ──
      if (!combat.pvp && combat.eventId && newState === 'ended' && allEnemiesDead && combat.enemyXpTotal) {
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
          message: `Defeated ${combat.enemyCount} ${combat.enemyName}(s) for ${combat.enemyXpTotal} XP.`
        });
      }

      // ── Log Tick Data with Detailed Attack Info ──
      const logRef = combatRef.collection('combatLog').doc(`tick_${tick}`);
      await logRef.set({
        tick,
        heroAttacks: heroAttackLogs,
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
            nextTileKey: admin.firestore.FieldValue.delete(),
            reservedDestination: admin.firestore.FieldValue.delete(),
          });
          console.log(`☠️ Hero ${h.id} died in combat ${combatId}`);
        } else if (newState === 'ended') {
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

      await combatRef.update({
        tick,
        state: newState,
        enemies,
        // For the PvP/HCV branch, we no longer use a global nextHeroAttackAt.
        ...(newState === 'ended' && { endedAt: admin.firestore.FieldValue.serverTimestamp() }),
      });

      // ── Resume Movement for Surviving Heroes if Combat Ended ──
      if (newState === 'ended') {
        for (const heroId of heroIds) {
          const heroSnap = await db.collection('heroes').doc(heroId).get();
          const heroData = heroSnap.data();
          if (heroData && heroData.hp > 0 && (heroData.state === 'moving' || heroData.state === 'in_combat')) {
            let nextStep: { x: number; y: number } | null = null;
            let remainingQueue = Array.isArray(heroData.movementQueue) ? heroData.movementQueue : [];
            if (heroData.reservedDestination) {
              nextStep = heroData.reservedDestination;
            } else if (remainingQueue.length > 0) {
              nextStep = remainingQueue[0];
              remainingQueue = remainingQueue.slice(1);
            }
            if (nextStep) {
              const moveSpeed = typeof heroData.movementSpeed === 'number'
                ? heroData.movementSpeed * 1000
                : 20 * 60 * 1000;
              const nextArrivesAt = new Date(Date.now() + moveSpeed);
              await db.collection('heroes').doc(heroId).update({
                state: 'moving',
                destinationX: nextStep.x,
                destinationY: nextStep.y,
                nextTileKey: `${nextStep.x}_${nextStep.y}`,
                arrivesAt: admin.firestore.Timestamp.fromDate(nextArrivesAt),
                movementQueue: remainingQueue,
                reservedDestination: admin.firestore.FieldValue.delete(),
              });
              const { scheduleHeroArrivalTask } = await import('../heroes/scheduleHeroArrivalTask.js');
              await scheduleHeroArrivalTask({ heroId, delaySeconds: Math.floor(moveSpeed / 1000) });
              console.log(`🔁 Hero ${heroId} resumed movement to (${nextStep.x}, ${nextStep.y})`);
            }
          }
        }
      }

      if (newState === 'ongoing') {
        const { scheduleCombatTick } = await import('./scheduleCombatTick.js');
        await scheduleCombatTick({ combatId, delaySeconds: TICK_INTERVAL_SECONDS });
        console.log(`⏭️ Scheduled next tick for combat ${combatId}`);
      } else {
        console.log(`🏁 Combat ${combatId} ended.`);
      }

      res.status(200).send('Tick complete (PvP/HCV mode).');
      return;
    } // End PvP/HCV branch

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

    // Hero attacks (global timer for single-hero branch is acceptable)
    if (now >= (combat.nextHeroAttackAt ?? 0)) {
      heroAttack = Math.floor(heroMin + Math.random() * (heroMax - heroMin + 1));
      targetIndex = aliveIndexes[Math.floor(Math.random() * aliveIndexes.length)];
      enemies[targetIndex].hp = Math.max(0, enemies[targetIndex].hp - heroAttack);
      combat.nextHeroAttackAt = now + (singleHero.combat?.attackSpeedMs ?? 150000);
    }

    // Enemies attack for single-hero branch.
    let totalEnemyAttack = 0;
    const enemyAttacks: Array<{ index: number; damage: number }> = [];
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
      finalHeroState = ((singleHero.movementQueue && singleHero.movementQueue.length > 0) || singleHero.reservedDestination) ? 'moving' : 'idle';
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
        xp: combat.enemyXpTotal,
        reward: ['gold'],
        message: `Defeated ${combat.enemyCount} ${combat.enemyName}(s) for ${gainedXp} XP.`
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
      const freshHeroSnap = await db.collection('heroes').doc(singleHeroId).get();
      const freshHero = freshHeroSnap.data();
      if (freshHero && finalHeroState === 'moving') {
        let nextStep: { x: number; y: number } | null = null;
        let remainingQueue = Array.isArray(freshHero.movementQueue) ? freshHero.movementQueue : [];
        if (freshHero.reservedDestination) {
          nextStep = freshHero.reservedDestination;
        } else if (remainingQueue.length > 0) {
          nextStep = remainingQueue[0];
          remainingQueue = remainingQueue.slice(1);
        }
        if (nextStep) {
          const moveSpeed = typeof freshHero.movementSpeed === 'number'
            ? freshHero.movementSpeed * 1000
            : 20 * 60 * 1000;
          const nextArrivesAt = new Date(Date.now() + moveSpeed);
          await singleHeroRef.update({
            destinationX: nextStep.x,
            destinationY: nextStep.y,
            nextTileKey: `${nextStep.x}_${nextStep.y}`,
            arrivesAt: admin.firestore.Timestamp.fromDate(nextArrivesAt),
            movementQueue: remainingQueue,
            reservedDestination: admin.firestore.FieldValue.delete(),
          });
          const { scheduleHeroArrivalTask } = await import('../heroes/scheduleHeroArrivalTask.js');
          await scheduleHeroArrivalTask({ heroId: singleHeroId, delaySeconds: Math.floor(moveSpeed / 1000) });
          console.log(`🔁 Hero ${singleHeroId} resumed movement to (${nextStep.x}, ${nextStep.y})`);
        }
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
