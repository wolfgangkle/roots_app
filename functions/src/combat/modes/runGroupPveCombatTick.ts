import * as admin from 'firebase-admin';
import { resolveHeroAttacks } from '../helpers/resolveHeroAttacks.js';
import { resolveEnemyAttacks } from '../helpers/resolveEnemyAttacks.js';
import { applyDamageAndUpdateHeroes } from '../helpers/applyDamageAndUpdateHeroes.js';
import { checkCombatOutcomeAndUpdate } from '../helpers/checkCombatOutcomeAndUpdate.js';
import { logCombatTick } from '../helpers/logCombatTick.js';
import { scheduleNextCombatTick } from '../helpers/scheduleNextCombatTick.js';
import { applyRegenAndCooldowns } from '../helpers/applyRegenAndCooldowns.js';

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

  // ✅ Save hp before tick
  const hpBeforeTick = heroesRaw.map((h: any) => ({
    id: h.id,
    hp: h.hp,
  }));

  // 🧪 Step 0: Regen + cooldowns (keeps full hero object, patches only changing fields)
  const {
    updatedHeroes: regenAppliedHeroes,
    newLastTickAt,
  } = applyRegenAndCooldowns(heroesRaw, lastTickAt);

  // 🗡️ Step 1: Hero attacks
  const {
    updatedEnemies: enemiesAfterHeroHits,
    heroLogs,
    heroUpdates,
  } = await resolveHeroAttacks({
    heroes: regenAppliedHeroes,
    enemies,
  });

  // ✨ Step 1.5: Patch nextAttackAt but preserve all other fields
  const heroesWithNextAttackAt = regenAppliedHeroes.map((h: any) => ({
    ...h,
    nextAttackAt: heroUpdates[h.id] ?? h.nextAttackAt,
  }));

  // 💀 Step 2: Enemies attack heroes
  const {
    updatedEnemies,
    damageMap,
    enemyLogs: rawEnemyLogs,
  } = resolveEnemyAttacks({
    enemies: enemiesAfterHeroHits,
    heroes: heroesWithNextAttackAt.map(({ id, hp }) => ({ id, hp })),
  });

  const enemyLogs = rawEnemyLogs.map((log, index) => ({
    enemyIndex: index,
    heroId: log.targetHeroId,
    damage: log.damage,
  }));

  // 💥 Step 3: Apply damage to heroes
  const updatedHeroes = await applyDamageAndUpdateHeroes({
    heroes: heroesWithNextAttackAt,
    damageMap,
  });

  // 🧾 Step 4: Check win/loss
  const newState = await checkCombatOutcomeAndUpdate({
    combatId,
    combat,
    updatedHeroes,
    updatedEnemies,
  });

  // 📝 Step 5: Log
  await logCombatTick({
    combatId,
    tick,
    heroLogs,
    enemyLogs,
    updatedHeroes,
    updatedEnemies,
    hpBeforeTick,
  });

  // 💾 Step 6: Persist tick — full hero object stays intact!
  await db.collection('combats').doc(combatId).update({
    tick,
    lastTickAt: newLastTickAt,
    heroes: updatedHeroes,
    enemies: updatedEnemies,
  });

  // ⏱️ Step 7: Next tick?
  await scheduleNextCombatTick({
    combatId,
    newState,
  });

  console.log(`✅ PvE tick ${tick} completed for ${combatId}`);
}
