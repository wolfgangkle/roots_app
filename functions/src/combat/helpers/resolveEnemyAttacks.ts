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
    nextAttackAt?: number | null; // ← add `null` here
    [key: string]: any;
  }>;
  heroes: Array<{
    id: string;
    hp: number;
    [key: string]: any;
  }>;
}): {
  updatedEnemies: any[];
  damageMap: Record<string, number>;
  enemyLogs: Array<{ attackerId: string; targetHeroId: string; damage: number }>;
} {
  const now = Date.now();
  const updatedEnemies = [...enemies];
  const damageMap: Record<string, number> = {};
  const enemyLogs: Array<{ attackerId: string; targetHeroId: string; damage: number }> = [];

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

    const aliveHeroes = heroes.filter(h => h.hp > 0);
    if (aliveHeroes.length === 0) {
      console.log(`⚠️ No alive heroes to attack.`);
      break;
    }

    const target = aliveHeroes[Math.floor(Math.random() * aliveHeroes.length)];

    const minDmg = enemy.attackMin ?? 5;
    const maxDmg = enemy.attackMax ?? 10;
    const damage = Math.floor(minDmg + Math.random() * (maxDmg - minDmg + 1));

    damageMap[target.id] = (damageMap[target.id] ?? 0) + damage;

    const newNextAttackAt = now + speedMs;
    enemy.nextAttackAt = newNextAttackAt;

    enemyLogs.push({
      attackerId: enemy.instanceId,
      targetHeroId: target.id,
      damage,
    });

    console.log(`👹 Enemy ${enemy.instanceId} hit Hero ${target.id} for ${damage}`);
  }

  return {
    updatedEnemies,
    damageMap,
    enemyLogs,
  };
}
