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

  // ✅ FLATTEN HEROES FIRST
  const flatHeroes = heroesRaw.map((h: any) => ({
    id: h.id,
    hp: h.hp ?? 1,
    mana: h.mana ?? 0,
    attackMin: h.attackMin ?? 5,
    attackMax: h.attackMax ?? 10,
    attackSpeedMs: h.attackSpeedMs ?? 15000,
    nextAttackAt: h.nextAttackAt ?? 0,
    lastHpRegenAt: h.lastHpRegenAt,
    lastManaRegenAt: h.lastManaRegenAt,
  }));


  // 🧪 Step 0: Regen + cooldowns
  const {
    updatedHeroes: heroesWithRegen,
    newLastTickAt,
  } = applyRegenAndCooldowns(flatHeroes, lastTickAt);

  // 🗡️ Step 1: Hero attacks
  const {
    updatedEnemies: enemiesAfterHeroHits,
    heroLogs,
    heroUpdates,
  } = await resolveHeroAttacks({
    heroes: heroesWithRegen,
    enemies,
  });

  // ✨ Step 1.5: Patch nextAttackAt
  const heroesWithNextAttackAt = heroesWithRegen.map(h => ({
    id: h.id,
    hp: h.hp,
    mana: h.mana,
    attackMin: h.attackMin,
    attackMax: h.attackMax,
    attackSpeedMs: h.attackSpeedMs,
    lastHpRegenAt: h.lastHpRegenAt,
    lastManaRegenAt: h.lastManaRegenAt,
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
    heroes: heroesWithNextAttackAt.map(h => ({
      id: h.id,
      hp: h.hp,
      mana: h.mana,
    })),
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
  });

  // 💾 Step 6: Persist tick
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
