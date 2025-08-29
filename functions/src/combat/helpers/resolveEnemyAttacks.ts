export function resolveEnemyAttacks({
  enemies,
  heroes,
}: {
  enemies: Array<{
    instanceId: string;
    hp: number;
    attackMin: number;
    attackMax: number;
    attackSpeedMs?: number;
    nextAttackAt?: number | null; // allow null
    // optional but useful for logs/UI:
    spawnIndex?: number;
    name?: string;
    enemyType?: string;
    type?: string;
    [key: string]: any;
  }>;
  heroes: Array<{
    id: string;
    hp: number;
    [key: string]: any;
  }>;
}): {
  updatedEnemies: typeof enemies;
  damageMap: Record<string, number>;
  enemyLogs: Array<{
    attackerId: string;
    targetHeroId: string;
    damage: number;
    attackerSpawnIndex?: number | null;
    attackerBaseName?: string | null;
  }>;
} {
  const now = Date.now();
  const updatedEnemies = [...enemies];
  const damageMap: Record<string, number> = {};
  const enemyLogs: Array<{
    attackerId: string;
    targetHeroId: string;
    damage: number;
    attackerSpawnIndex?: number | null;
    attackerBaseName?: string | null;
  }> = [];

  for (const enemy of updatedEnemies) {
    const enemyHp = typeof enemy.hp === 'number' ? enemy.hp : 0;

    // 💀 Skip dead enemies and prevent future logic from using them
    if (enemyHp <= 0) {
      enemy.hp = 0;
      enemy.nextAttackAt = null;
      console.log(`☠️ Enemy ${enemy.instanceId} is dead and cannot attack.`);
      continue;
    }

    const nextAttackAt = enemy.nextAttackAt ?? 0;
    const speedMs = enemy.attackSpeedMs ?? 15000;

    if (now < nextAttackAt) {
      console.log(`⏳ Enemy ${enemy.instanceId} is cooling down (nextAttackAt: ${nextAttackAt})`);
      continue;
    }

    const aliveHeroes = heroes.filter(h => (h.hp ?? 0) > 0);
    if (aliveHeroes.length === 0) {
      console.log(`⚠️ No alive heroes to attack.`);
      break;
    }

    const target = aliveHeroes[Math.floor(Math.random() * aliveHeroes.length)];

    const minDmg = enemy.attackMin ?? 5;
    const maxDmg = enemy.attackMax ?? 10;
    const damage = Math.floor(minDmg + Math.random() * (maxDmg - minDmg + 1));

    damageMap[target.id] = (damageMap[target.id] ?? 0) + damage;

    enemy.nextAttackAt = now + speedMs;
    // (optional) lastAttackAt can help debugging/cooldowns
    enemy.lastAttackAt = now;

    enemyLogs.push({
      attackerId: enemy.instanceId,
      targetHeroId: target.id,
      damage,
      attackerSpawnIndex: typeof enemy.spawnIndex === 'number' ? enemy.spawnIndex : null,
      attackerBaseName:
        (enemy.name ?? enemy.enemyType ?? enemy.type ?? null) as string | null,
    });

    console.log(`👹 Enemy ${enemy.instanceId} hit Hero ${target.id} for ${damage}`);
  }

  return {
    updatedEnemies,
    damageMap,
    enemyLogs,
  };
}
