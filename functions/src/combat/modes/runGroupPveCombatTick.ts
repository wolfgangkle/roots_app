// combat/modes/runGroupPveCombatTick.ts
import * as admin from 'firebase-admin';
import { resolveHeroAttacks } from '../helpers/resolveHeroAttacks.js';
import { resolveEnemyAttacks } from '../helpers/resolveEnemyAttacks.js';
import { applyDamageAndUpdateHeroes } from '../helpers/applyDamageAndUpdateHeroes.js';
import { checkCombatOutcomeAndUpdate } from '../helpers/checkCombatOutcomeAndUpdate.js';
import { logCombatTick } from '../helpers/logCombatTick.js';
import { scheduleNextCombatTick } from '../helpers/scheduleNextCombatTick.js';
import { applyRegenAndCooldowns } from '../helpers/applyRegenAndCooldowns.js';
import { handleCombatEnded } from '../helpers/handleCombatEnded.js';

const db = admin.firestore();

export async function runGroupPveCombatTick(combatId: string, combat: any) {
  console.log(`⚔️ Processing PvE tick for ${combatId}`);

  const tick = (combat.tick ?? 0) + 1;
  const lastTickAt = typeof combat.lastTickAt === 'number' ? combat.lastTickAt : Date.now();
  const groupId = combat.groupId;
  if (!groupId) {
    console.warn(`❌ Combat ${combatId} missing groupId`);
    return;
  }

  const heroesRaw = combat.heroes ?? [];
  const enemies = combat.enemies ?? [];
  if (heroesRaw.length === 0 || enemies.length === 0) {
    console.warn(`❌ Combat ${combatId} has no valid heroes or enemies`);
    return;
  }

  const hpBeforeTick = heroesRaw.map((h: any) => ({ id: h.id, hp: h.hp }));

  const { updatedHeroes: heroesAfterCooldowns, newLastTickAt } =
    applyRegenAndCooldowns(heroesRaw, lastTickAt);

  const {
    updatedEnemies: enemiesAfterHeroHits,
    heroLogs,
    heroUpdates,
  } = await resolveHeroAttacks({ heroes: heroesAfterCooldowns, enemies });

  const heroesWithNextAttackAt = heroesAfterCooldowns.map((h: any) => ({
    ...h,
    nextAttackAt: heroUpdates[h.id] ?? h.nextAttackAt,
  }));

  // 🔒 Belt-and-suspenders: sanitize enemies before enemy phase
  const enemiesForEnemyPhase = enemiesAfterHeroHits.map((e: any) => {
    const hp = Number(e?.hp) || 0;
    if (hp > 0) return e;
    // forcefully disarm any dead enemy
    return { ...e, hp: 0, nextAttackAt: null, state: e?.state ?? 'dead' };
  });

  // Optional diagnostic: detect "dead but armed" just in case
  const zombies = enemiesAfterHeroHits.filter(
    (e: any) => (Number(e?.hp) || 0) <= 0 && e?.nextAttackAt
  );
  if (zombies.length) {
    console.warn(
      `🧟 Found ${zombies.length} dead enemies with timers before enemy phase:`,
      zombies.map((z: any) => ({ id: z.instanceId, hp: z.hp, nextAttackAt: z.nextAttackAt }))
    );
  }

  const {
    updatedEnemies,
    damageMap,
    enemyLogs: rawEnemyLogs,
  } = resolveEnemyAttacks({
    enemies: enemiesForEnemyPhase, // ← use sanitized list
    heroes: heroesWithNextAttackAt.map(({ id, hp }) => ({ id, hp })),
  });

  const enemyLogs = rawEnemyLogs.map((log, index) => ({
    attackerId: log.attackerId,       // ✅ stable per enemy
    heroId: log.targetHeroId,
    damage: log.damage,
    enemyIndex: index,                // (optional) keep for debugging
  }));

  const updatedHeroes = await applyDamageAndUpdateHeroes({
    heroes: heroesWithNextAttackAt,
    damageMap,
  });

  // Compute outcome + XP metadata (no writes here)
  const { newState, totalXp, xpPerHero, livingHeroIds } = await checkCombatOutcomeAndUpdate({
    combatId,
    combat,
    updatedHeroes,
    updatedEnemies,
  });

  // Log the tick
  await logCombatTick({
    combatId,
    tick,
    heroLogs,
    enemyLogs,
    updatedHeroes,
    updatedEnemies,
    hpBeforeTick,
  });

  // Persist current tick state
  const combatRef = db.collection('combats').doc(combatId);
  await combatRef.update({
    tick,
    lastTickAt: newLastTickAt,
    heroes: updatedHeroes,
    enemies: updatedEnemies,
    state: newState,
    ...(newState === 'ended' && {
      endedAt: admin.firestore.FieldValue.serverTimestamp(),
      xp: totalXp,
      xpPerHero,
      xpRecipients: livingHeroIds,
    }),
  });

  // If ended, pay XP and run post-combat pipeline
  if (newState === 'ended') {
    // XP payout with a batch
    if (xpPerHero > 0 && livingHeroIds.length > 0) {
      const batch = db.batch();
      for (const heroId of livingHeroIds) {
        batch.update(db.collection('heroes').doc(heroId), {
          experience: admin.firestore.FieldValue.increment(xpPerHero),
        });
        console.log(`[XP] hero ${heroId} +${xpPerHero}`);
      }
      await batch.commit();
      console.log(
        `[XP] committed payout: totalXp=${totalXp}, perHero=${xpPerHero}, recipients=${livingHeroIds.length}`
      );
    } else {
      console.log(`[XP] no payout (totalXp=${totalXp}, recipients=${livingHeroIds.length})`);
    }

    // Call post-combat cleanup with final arrays
    const combatAfter = {
      ...combat,
      id: combatId,
      state: 'ended',
      heroes: updatedHeroes,
      enemies: updatedEnemies,
    };

    console.log(`🪦 PvE combat ${combatId} ended → calling handleCombatEnded()`);
    await handleCombatEnded(combatAfter);
    console.log(`✅ Post-combat pipeline finished for ${combatId}`);
    return;
  }

  // Otherwise schedule next tick
  await scheduleNextCombatTick({ combatId, newState });
  console.log(`✅ PvE tick ${tick} completed for ${combatId}`);
}
