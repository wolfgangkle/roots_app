

export function resolveEnemyAttacks({
  enemies,
  heroes,
}: {
  enemies: any[];
  heroes: Array<{ id: string; data: any }>;
}): {
  updatedEnemies: any[];
  damageMap: Record<string, number>; // { heroId: accumulatedDamage }
  enemyLogs: Array<{ enemyIndex: number; heroId: string; damage: number }>;
} {
  const now = Date.now();
  const updatedEnemies = [...enemies];
  const aliveHeroes = heroes.filter(h => h.data.hp > 0);

  const damageMap: Record<string, number> = {};
  const enemyLogs: Array<{ enemyIndex: number; heroId: string; damage: number }> = [];

  for (let i = 0; i < updatedEnemies.length; i++) {
    const enemy = updatedEnemies[i];
    if (enemy.hp <= 0) continue;

    const nextAttackAt = enemy.nextAttackAt ?? 0;
    if (now < nextAttackAt) continue;

    if (aliveHeroes.length === 0) break;

    const target = aliveHeroes[Math.floor(Math.random() * aliveHeroes.length)];
    const min = enemy.minDamage ?? 1;
    const max = enemy.maxDamage ?? 3;
    const speed = enemy.attackSpeedMs ?? 90000;

    const dmg = Math.floor(min + Math.random() * (max - min + 1));
    updatedEnemies[i].nextAttackAt = now + speed;

    damageMap[target.id] = (damageMap[target.id] || 0) + dmg;
    enemyLogs.push({
      enemyIndex: i,
      heroId: target.id,
      damage: dmg,
    });

    console.log(`💀 Enemy[${i}] hit hero ${target.id} for ${dmg}`);
  }

  return {
    updatedEnemies,
    damageMap,
    enemyLogs,
  };
}
