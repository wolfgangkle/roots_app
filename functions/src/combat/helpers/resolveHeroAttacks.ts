export async function resolveHeroAttacks({
  heroes,
  enemies,
}: {
  heroes: Array<{
    id: string;
    hp: number;
    attackMin: number;
    attackMax: number;
    attackSpeedMs: number;
    nextAttackAt?: number;
    [key: string]: any;
  }>;
  enemies: any[];
}): Promise<{
  updatedEnemies: any[];
  heroLogs: Array<{ attackerId: string; targetIndex: number; damage: number }>;
  heroUpdates: Record<string, number>;
}> {
  const now = Date.now();

  // Use a fresh copy of enemy objects (not just the array) to avoid shared refs.
  const updatedEnemies = enemies.map(e => ({ ...e }));

  const heroLogs: Array<{ attackerId: string; targetIndex: number; damage: number }> = [];
  const heroUpdates: Record<string, number> = {};

  for (const hero of heroes) {
    const heroHp = Number(hero.hp) || 0;
    if (heroHp <= 0) continue;

    const nextAttackAt = Number(hero.nextAttackAt ?? 0);
    if (now < nextAttackAt) continue;

    const minDmgRaw = Number(hero.attackMin);
    const maxDmgRaw = Number(hero.attackMax);
    const minDmg = Number.isFinite(minDmgRaw) ? Math.max(0, minDmgRaw) : 0;
    const maxDmg = Number.isFinite(maxDmgRaw) ? Math.max(minDmg, maxDmgRaw) : minDmg;
    const speedMsRaw = Number(hero.attackSpeedMs);
    const speedMs = Number.isFinite(speedMsRaw) ? Math.max(300, speedMsRaw) : 15000;

    // If hero can't deal any damage, still advance the timer to avoid spamming checks.
    if (maxDmg <= 0) {
      heroUpdates[hero.id] = now + speedMs;
      continue;
    }

    // Pick only living enemies from the *updated* list
    const livingEnemyIndexes: number[] = [];
    for (let i = 0; i < updatedEnemies.length; i++) {
      const ehp = Number(updatedEnemies[i]?.hp) || 0;
      if (ehp > 0) livingEnemyIndexes.push(i);
    }
    if (livingEnemyIndexes.length === 0) continue;

    const targetIndex = livingEnemyIndexes[Math.floor(Math.random() * livingEnemyIndexes.length)];
    const target = updatedEnemies[targetIndex];
    if (!target) continue;

    // Re-check target alive (belt & suspenders)
    const targetHpBefore = Math.max(0, Number(target.hp) || 0);
    if (targetHpBefore <= 0) continue;

    // Roll damage
    const damage = Math.floor(minDmg + Math.random() * (maxDmg - minDmg + 1));

    // Apply damage
    const newHp = Math.max(0, targetHpBefore - damage);
    target.hp = newHp;

    // ✅ Disarm immediately if killed in hero phase
    if (newHp <= 0) {
      target.nextAttackAt = null;      // <- critical fix against "zombie" attacks
      if (target.state !== 'dead') target.state = 'dead'; // optional but helpful
      if (!target.deadAt) target.deadAt = now;            // optional: logging/UX
    }

    // Log
    heroLogs.push({
      attackerId: hero.id,
      targetIndex,
      damage,
    });

    // Advance hero timer
    heroUpdates[hero.id] = now + speedMs;

    console.log(`🗡️ Hero ${hero.id} hit enemy[${targetIndex}] for ${damage} (hp ${targetHpBefore} → ${newHp})`);
  }

  return {
    updatedEnemies,
    heroLogs,
    heroUpdates,
  };
}
