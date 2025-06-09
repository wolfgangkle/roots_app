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
  updatedHeroes: Array<{ id: string; data: any }>;
  updatedEnemies: any[];
}): Promise<void> {
  const db = admin.firestore();

  const heroesHpAfter: Record<string, number> = {};
  for (const h of updatedHeroes) {
    heroesHpAfter[h.id] = h.data.hp ?? 0;
  }

  const enemiesHpAfter = updatedEnemies.map(e => e.hp ?? 0);

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
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`📝 Logged combat tick ${tick} for combat ${combatId}`);
}
