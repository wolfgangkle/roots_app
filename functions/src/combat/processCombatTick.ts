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

    // ──────────────── PvP Mode Branch ────────────────
    if (combat.pvp) {
      // Get all hero IDs participating in this combat.
      const heroIds: string[] = combat.heroIds || [];
      if (heroIds.length === 0) {
        throw new HttpsError('invalid-argument', 'No heroes found in combat document.');
      }

      // Fetch all hero documents and filter out any that have no data.
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
      if (now >= (combat.nextHeroAttackAt ?? 0)) {
        if (aliveHeroes.length > 0) {
          // Choose a random attacker from the alive heroes.
          const attackerIndex = Math.floor(Math.random() * aliveHeroes.length);
          const attacker = aliveHeroes[attackerIndex];
          const attackerData = attacker.data!; // non-null asserted

          // Use attack stats from the attacker (with fallbacks).
          const heroMin = attackerData.combat?.attackMin ?? 5;
          const heroMax = attackerData.combat?.attackMax ?? 9;
          const heroAttack = Math.floor(heroMin + Math.random() * (heroMax - heroMin + 1));

          // Build a list of potential targets: alive NPC enemies and all other heroes.
          const potentialTargets: { type: 'enemy' | 'hero'; index?: number; heroId?: string }[] = [];
          const enemies = [...combat.enemies]; // work on a copy
          for (let i = 0; i < enemies.length; i++) {
            if (enemies[i].hp > 0) {
              potentialTargets.push({ type: 'enemy', index: i });
            }
          }
          // Add other heroes (skip the attacker).
          for (const hero of aliveHeroes) {
            if (hero.id !== attacker.id) {
              potentialTargets.push({ type: 'hero', heroId: hero.id });
            }
          }
          if (potentialTargets.length > 0) {
            const choice = potentialTargets[Math.floor(Math.random() * potentialTargets.length)];
            if (choice.type === 'enemy' && choice.index !== undefined) {
              // Hero attacks an enemy.
              enemies[choice.index].hp = Math.max(0, enemies[choice.index].hp - heroAttack);
              console.log(`🌀 PvP: Hero ${attacker.id} attacked enemy[${choice.index}] for ${heroAttack}`);
            } else if (choice.type === 'hero' && choice.heroId) {
              // Hero attacks another hero.
              const targetHero = aliveHeroes.find(h => h.id === choice.heroId);
              if (targetHero) {
                targetHero.data.hp = Math.max(0, targetHero.data.hp - heroAttack);
                console.log(`🌀 PvP: Hero ${attacker.id} attacked hero ${targetHero.id} for ${heroAttack}`);
              }
            }
          }
          // Set next hero attack time based on the attacker's attack speed.
          combat.nextHeroAttackAt = now + (attackerData.combat?.attackSpeedMs ?? 150000);
        }
      }

      // ── ENEMY ATTACK PHASE ──
      const enemyAttacksLog: { enemyIndex: number; heroId: string; damage: number }[] = [];
      const enemies = [...combat.enemies]; // Copy the enemies array.
      for (let i = 0; i < enemies.length; i++) {
        const enemy = enemies[i];
        if (enemy.hp <= 0) continue;
        const attackReady = now >= (enemy.nextAttackAt ?? 0);
        if (!attackReady) continue;
        const minDamage = enemy.minDamage ?? 1;
        const maxDamage = enemy.maxDamage ?? 3;
        const attackSpeed = enemy.attackSpeedMs ?? 90000;
        const attack = Math.floor(minDamage + Math.random() * (maxDamage - minDamage + 1));

        // Recompute alive heroes in case their HP was updated.
        aliveHeroes = heroes.filter(h => h.data.hp !== undefined && h.data.hp > 0);
        if (aliveHeroes.length > 0) {
          const targetHero = aliveHeroes[Math.floor(Math.random() * aliveHeroes.length)];
          targetHero.data.hp = Math.max(0, targetHero.data.hp - attack);
          enemy.nextAttackAt = now + attackSpeed;
          enemyAttacksLog.push({ enemyIndex: i, heroId: targetHero.id, damage: attack });
          console.log(`🌀 PvP: Enemy[${i}] attacked hero ${targetHero.id} for ${attack}`);
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

      // Log the tick details.
      const logRef = combatRef.collection('combatLog').doc(`tick_${tick}`);
      await logRef.set({
        tick,
        heroAttack: 'various', // multiple heroes may have attacked
        enemyAttacks: enemyAttacksLog,
        heroesHpAfter: heroes.reduce((acc: Record<string, number>, h) => {
          acc[h.id] = h.data.hp;
          return acc;
        }, {}),
        enemiesHpAfter: enemies.map(e => e.hp),
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ── Update Each Hero's Document ──
      for (const hero of heroes) {
        let finalHeroState: 'dead' | 'moving' | 'idle' | 'in_combat';
        if (hero.data.hp <= 0) {
          finalHeroState = 'dead';
          await hero.ref.update({
            hp: hero.data.hp,
            state: finalHeroState,
            movementQueue: [],
            destinationX: admin.firestore.FieldValue.delete(),
            destinationY: admin.firestore.FieldValue.delete(),
            nextMoveAt: admin.firestore.FieldValue.delete(),
          });
          console.log(`☠️ Hero ${hero.id} died in PvP combat ${combatId}`);
        } else if (newState === 'ended') {
          finalHeroState = (hero.data.movementQueue && hero.data.movementQueue.length > 0) ? 'moving' : 'idle';
          await hero.ref.update({
            hp: hero.data.hp,
            state: finalHeroState,
          });
        } else {
          finalHeroState = 'in_combat';
          await hero.ref.update({
            hp: hero.data.hp,
            state: finalHeroState,
          });
        }
      }

      // ── Award XP for Defeating NPC Enemies (if any) ──
      if (newState === 'ended' && allEnemiesDead && combat.enemyXpTotal) {
        const survivors = heroes.filter(h => h.data.hp > 0);
        const xpPerHero = Math.floor(combat.enemyXpTotal / (survivors.length || 1));
        for (const hero of survivors) {
          await hero.ref.update({
            experience: admin.firestore.FieldValue.increment(xpPerHero)
          });
          console.log(`🎉 Hero ${hero.id} gained ${xpPerHero} XP`);
        }
      }

      // ── Update Combat Document ──
      await combatRef.update({
        tick,
        state: newState,
        enemies,
        nextHeroAttackAt: combat.nextHeroAttackAt,
        ...(newState === 'ended' && { endedAt: admin.firestore.FieldValue.serverTimestamp() }),
      });

      // ── Resume Movement for Surviving Heroes if Combat Ended ──
      if (newState === 'ended') {
        for (const hero of heroes) {
          if (
            hero.data.hp > 0 &&
            hero.data.state === 'moving' &&
            Array.isArray(hero.data.movementQueue) &&
            hero.data.movementQueue.length > 0
          ) {
            const nextStep = hero.data.movementQueue[0];
            const remainingQueue = hero.data.movementQueue.slice(1);
            const movementSpeed = 20 * 60 * 1000;
            const nextArrivesAt = new Date(Date.now() + movementSpeed);
            await hero.ref.update({
              destinationX: nextStep.x,
              destinationY: nextStep.y,
              arrivesAt: admin.firestore.Timestamp.fromDate(nextArrivesAt),
              movementQueue: remainingQueue,
            });
            const { scheduleHeroArrivalTask } = await import('../heroes/scheduleHeroArrivalTask.js');
            await scheduleHeroArrivalTask({
              heroId: hero.id,
              delaySeconds: Math.floor(movementSpeed / 1000),
            });
            console.log(`🔁 Hero ${hero.id} resumed movement to (${nextStep.x}, ${nextStep.y})`);
          }
        }
      }

      // ── Schedule Next Tick if Combat Still Ongoing ──
      if (newState === 'ongoing') {
        const { scheduleCombatTick } = await import('./scheduleCombatTick.js');
        await scheduleCombatTick({
          combatId,
          delaySeconds: TICK_INTERVAL_SECONDS,
        });
        console.log(`⏭️ Scheduled next tick for combat ${combatId}`);
      } else {
        console.log(`🏁 PvP Combat ${combatId} ended.`);
      }

      res.status(200).send('Tick complete (PvP mode).');
      return;
    } // End PvP branch

    // ──────────────── Non-PvP (Original Single-Hero) Branch ────────────────
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

    const heroMin = hero.combat?.attackMin ?? 5;
    const heroMax = hero.combat?.attackMax ?? 9;
    let heroAttack = 0;
    let targetIndex: number | null = null;

    const enemies = [...combat.enemies];
    const aliveIndexes = enemies
      .map((e, i) => (e.hp > 0 ? i : -1))
      .filter(i => i !== -1);

    if (aliveIndexes.length === 0) {
      console.log('⚠️ All enemies already dead.');
      await combatRef.update({ state: 'ended' });
      await heroRef.update({ state: 'idle' });
      res.status(200).send('Combat already over.');
      return;
    }

    // 👊 Hero attacks
    if (now >= (combat.nextHeroAttackAt ?? 0)) {
      heroAttack = Math.floor(heroMin + Math.random() * (heroMax - heroMin + 1));
      targetIndex = aliveIndexes[Math.floor(Math.random() * aliveIndexes.length)];
      enemies[targetIndex].hp = Math.max(0, enemies[targetIndex].hp - heroAttack);
      combat.nextHeroAttackAt = now + (hero.combat?.attackSpeedMs ?? 150000);
    }

    // 💢 Enemies attack
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

    const newHeroHp = Math.max(0, hero.hp - totalEnemyAttack);
    const tick = (combat.tick ?? 0) + 1;
    const allEnemiesDead = enemies.every(e => e.hp <= 0);
    const heroWon = allEnemiesDead && newHeroHp > 0;
    let newState = 'ongoing';
    if (newHeroHp <= 0 || tick >= MAX_TICKS || allEnemiesDead) {
      newState = 'ended';
    }

    // ── Determine final hero state based on movement queue ──
    let finalHeroState: 'dead' | 'moving' | 'idle' | 'in_combat';
    if (newHeroHp <= 0) {
      finalHeroState = 'dead';
    } else if (newState === 'ended') {
      finalHeroState = (hero.movementQueue && hero.movementQueue.length > 0) ? 'moving' : 'idle';
    } else {
      finalHeroState = 'in_combat';
    }

    // Log combat tick.
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

    await heroRef.update({
      hp: newHeroHp,
      state: finalHeroState,
    });

    if (finalHeroState === 'dead') {
      console.log(`☠️ Hero ${heroId} died during combat ${combatId}`);
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
        reward: ['gold'],
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
      // Resume movement if hero is set to 'moving'
      if (
        finalHeroState === 'moving' &&
        Array.isArray(hero.movementQueue) &&
        hero.movementQueue.length > 0
      ) {
        const nextStep = hero.movementQueue[0];
        const remainingQueue = hero.movementQueue.slice(1);
        const movementSpeed = 20 * 60 * 1000;
        const nextArrivesAt = new Date(Date.now() + movementSpeed);
        await heroRef.update({
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
