import * as admin from 'firebase-admin';
import { resolveHeroAttacks } from '../helpers/resolveHeroAttacks.js';
import { resolveEnemyAttacks } from '../helpers/resolveEnemyAttacks.js';
import { applyDamageAndUpdateHeroes } from '../helpers/applyDamageAndUpdateHeroes.js';
import { checkCombatOutcomeAndUpdate } from '../helpers/checkCombatOutcomeAndUpdate.js';
import { logCombatTick } from '../helpers/logCombatTick.js';
import { scheduleNextCombatTick } from '../helpers/scheduleNextCombatTick.js';
import { applyRegenAndCooldowns } from '../helpers/applyRegenAndCooldowns.js';

const db = admin.firestore();

type HeroData = {
  name: string;
  hp: number;
  hpMax: number;
  mana?: number;
  manaMax?: number;
  hpRegen?: number;
  manaRegen?: number;
  lastHpRegenAt?: number;
  lastManaRegenAt?: number;
};

export async function runGroupPveCombatTick(combatId: string, combat: any) {
  console.log(`⚔️ Processing PvE tick for ${combatId}`);

  const groupId = combat.groupId;
  if (!groupId) {
    console.warn(`❌ Combat ${combatId} missing groupId`);
    return;
  }

  const groupSnap = await db.collection('heroGroups').doc(groupId).get();
  if (!groupSnap.exists) {
    console.warn(`❌ Hero group ${groupId} not found for combat ${combatId}`);
    return;
  }

  const group = groupSnap.data()!;
  const heroIds: string[] = group.members ?? [];
  if (heroIds.length === 0) {
    console.warn(`⚠️ No heroes found in group ${groupId}`);
    return;
  }

  // 🔄 Load hero data
  const heroSnaps = await db.getAll(...heroIds.map(id => db.doc(`heroes/${id}`)));

  const heroes = heroSnaps
    .map(snap => ({
      id: snap.id,
      ref: snap.ref,
      data: snap.data(),
    }))
    .filter(h => h.data) as {
      id: string;
      ref: FirebaseFirestore.DocumentReference;
      data: HeroData;
    }[];

  if (heroes.length === 0) {
    console.warn(`⚠️ No valid hero docs for group ${groupId}`);
    return;
  }

  // 🧪 Step 0: Apply regeneration and cooldown updates
  const lastTickAt = typeof combat.lastTickAt === 'number' ? combat.lastTickAt : Date.now();
  const { updatedHeroes: heroesWithRegen, newLastTickAt } = applyRegenAndCooldowns(
    heroes,
    lastTickAt
  );

  // 🗡️ Step 1: Heroes attack enemies
  const { updatedEnemies: enemiesAfterHeroHits, heroLogs } = await resolveHeroAttacks({
    heroes: heroesWithRegen,
    enemies: combat.enemies ?? [],
  });

  // 💀 Step 2: Enemies attack heroes
  const { updatedEnemies, damageMap, enemyLogs } = resolveEnemyAttacks({
    enemies: enemiesAfterHeroHits,
    heroes: heroesWithRegen,
  });

  // 💥 Step 3: Apply enemy damage to heroes + update state
  const updatedHeroes = await applyDamageAndUpdateHeroes({
    heroes: heroesWithRegen.map((h, i) => ({
      ...h,
      ref: heroes[i].ref,
    })),
    damageMap,
  });

  // 🧾 Step 4: Check for end of combat + award XP if needed
  const newState = await checkCombatOutcomeAndUpdate({
    combatId,
    combat,
    updatedHeroes,
    updatedEnemies,
  });

  // 📝 Step 5: Log the tick
  const tick = (combat.tick ?? 0) + 1;
  await logCombatTick({
    combatId,
    tick,
    heroLogs,
    enemyLogs,
    updatedHeroes,
    updatedEnemies,
  });

  // ⏱️ Step 6: Schedule next tick
  await scheduleNextCombatTick({
    combatId,
    newState,
  });

  // 🕒 Optional: Persist new regen baseline
  await db.collection('combats').doc(combatId).update({
    lastTickAt: newLastTickAt,
    tick,
  });

  console.log(`✅ PvE tick complete for ${combatId}`);
}
