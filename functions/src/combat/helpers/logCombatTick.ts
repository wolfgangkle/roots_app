import * as admin from 'firebase-admin';

export async function logCombatTick({
  combatId,
  tick,
  heroLogs,
  enemyLogs,
  updatedHeroes,
  updatedEnemies,
  hpBeforeTick,
}: {
  combatId: string;
  tick: number;
  heroLogs: Array<{ attackerId: string; targetIndex: number; damage: number; targetEnemyId?: string | null }>;
  // Accept both new (attackerId) and legacy (enemyIndex) shapes
  enemyLogs: Array<{ attackerId?: string; heroId: string; damage: number; enemyIndex?: number }>;
  updatedHeroes: Array<{ id: string; hp: number } & Record<string, any>>;
  // Make instanceId optional in typing (we’ll handle missing defensively)
  updatedEnemies: Array<{ instanceId?: string; hp: number } & Record<string, any>>;
  hpBeforeTick?: Array<{ id: string; hp: number }>;
}): Promise<void> {
  const db = admin.firestore();

  // ---- After-HP maps/arrays (keep legacy + add stable map) ----
  const heroesHpAfter: Record<string, number> = {};
  for (const h of updatedHeroes) {
    heroesHpAfter[h.id] = h.hp ?? 0;
  }

  // Legacy array (order-based). Keep for backward-compat.
  const enemiesHpAfter = updatedEnemies.map(e => e.hp ?? 0);

  // Stable map keyed by instanceId (recommended for new UI)
  const enemiesHpAfterMap: Record<string, number> = {};
  for (const e of updatedEnemies) {
    const id = (e.instanceId ?? '').toString();
    if (id) enemiesHpAfterMap[id] = e.hp ?? 0;
  }

  // Snapshots (what the tick looked like right after resolution)
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
    instanceId: e.instanceId ?? null,
    hp: e.hp ?? 0,
    attackMin: e.attackMin ?? 0,
    attackMax: e.attackMax ?? 0,
    attackSpeedMs: e.attackSpeedMs ?? 0,
    nextAttackAt: e.nextAttackAt ?? 0,
    spawnIndex: e.spawnIndex ?? null,   // if you set this at spawn time
    name: e.name ?? e.enemyType ?? e.type ?? null,
  }));

  // ---- Normalize enemy logs: ensure attackerId is present ----
  const normalizedEnemyLogs = enemyLogs.map((log) => {
    let attackerId = (log.attackerId ?? '').toString();

    if (!attackerId && typeof log.enemyIndex === 'number') {
      const idx = log.enemyIndex;
      const fromArray = updatedEnemies[idx];
      const fallbackId = fromArray?.instanceId ? String(fromArray.instanceId) : '';
      if (fallbackId) attackerId = fallbackId;
    }

    return {
      attackerId: attackerId || 'unknown',  // always present for UI
      heroId: log.heroId,
      damage: log.damage,
      enemyIndex: log.enemyIndex ?? null,   // keep for debugging/back-compat
    };
  });

  const logRef = db
    .collection('combats')
    .doc(combatId)
    .collection('combatLog')
    .doc(`tick_${tick}`);

  await logRef.set({
    tick,
    heroAttacks: heroLogs,
    enemyAttacks: normalizedEnemyLogs,   // ✅ now keyed by attackerId
    hpBeforeTick: hpBeforeTick ?? [],
    heroesHpAfter,
    enemiesHpAfter,                      // legacy array (kept)
    enemiesHpAfterMap,                   // ✅ stable map (new)
    heroes: heroSnapshots,
    enemies: enemySnapshots,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`📝 Logged combat tick ${tick} for combat ${combatId}`);
}
