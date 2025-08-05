import * as admin from 'firebase-admin';

export async function logCombatTick({
  combatId,
  tick,
  heroLogs,
  enemyLogs,
  updatedHeroes,
  updatedEnemies,
}: {
  combatId: string;
  tick: number;
  heroLogs: Array<{ attackerId: string; targetIndex: number; damage: number }>;
  enemyLogs: Array<{ enemyIndex: number; heroId: string; damage: number }>;
  updatedHeroes: Array<{ id: string; hp: number } & Record<string, any>>;
  updatedEnemies: Array<{ hp: number } & Record<string, any>>;
}): Promise<void> {
  const db = admin.firestore();

  const heroesHpAfter: Record<string, number> = {};
  for (const h of updatedHeroes) {
    heroesHpAfter[h.id] = h.hp ?? 0;
  }

  const enemiesHpAfter = updatedEnemies.map(e => e.hp ?? 0);

  const heroSnapshots = updatedHeroes.map(h => ({
    id: h.id,
    hp: h.hp ?? 0,
    attackMin: h.attackMin ?? 0,
    attackMax: h.attackMax ?? 0,
    attackSpeedMs: h.attackSpeedMs ?? 0,
    nextAttackAt: h.nextAttackAt ?? 0,
    mana: h.mana ?? 0,
  }));

  const enemySnapshots = updatedEnemies.map(e => ({
    hp: e.hp ?? 0,
    attackMin: e.attackMin ?? 0,
    attackMax: e.attackMax ?? 0,
    attackSpeedMs: e.attackSpeedMs ?? 0,
    nextAttackAt: e.nextAttackAt ?? 0,
    instanceId: e.instanceId,
  }));

  const logRef = db
    .collection('combats')
    .doc(combatId)
    .collection('combatLog')
    .doc(`tick_${tick}`);

  await logRef.set({
    tick,
    heroAttacks: heroLogs,
    enemyAttacks: enemyLogs,
    heroesHpAfter,
    enemiesHpAfter,
    heroes: heroSnapshots,
    enemies: enemySnapshots,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`📝 Logged combat tick ${tick} for combat ${combatId}`);
}
