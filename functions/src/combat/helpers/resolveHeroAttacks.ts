

export async function resolveHeroAttacks({
  heroes,
  enemies,
}: {
  heroes: Array<{ id: string; data: any; ref: FirebaseFirestore.DocumentReference }>;
  enemies: any[];
}): Promise<{
  updatedEnemies: any[];
  heroLogs: Array<{ attackerId: string; targetIndex: number; damage: number }>;
  heroUpdates: Record<string, number>; // { heroId: newNextAttackAt }
}> {
  const now = Date.now();
  const updatedEnemies = [...enemies];
  const heroLogs: Array<{ attackerId: string; targetIndex: number; damage: number }> = [];
  const heroUpdates: Record<string, number> = {};

  for (const hero of heroes) {
    if (!hero.data || hero.data.hp <= 0) continue;

    const nextAttackAt = hero.data.combat?.nextAttackAt ?? 0;
    if (now < nextAttackAt) continue;

    const minDmg = hero.data.combat?.attackMin ?? 5;
    const maxDmg = hero.data.combat?.attackMax ?? 10;
    const speedMs = hero.data.combat?.attackSpeedMs ?? 15000;
    const damage = Math.floor(minDmg + Math.random() * (maxDmg - minDmg + 1));

    const aliveEnemies = updatedEnemies
      .map((e, i) => ({ ...e, index: i }))
      .filter(e => e.hp > 0);

    if (aliveEnemies.length === 0) continue;

    const target = aliveEnemies[Math.floor(Math.random() * aliveEnemies.length)];

    updatedEnemies[target.index].hp = Math.max(0, updatedEnemies[target.index].hp - damage);
    heroLogs.push({
      attackerId: hero.id,
      targetIndex: target.index,
      damage,
    });

    const newNextAttackAt = now + speedMs;
    heroUpdates[hero.id] = newNextAttackAt;

    // Update Firestore (batched later)
    await hero.ref.update({
      'combat.nextAttackAt': newNextAttackAt,
    });

    console.log(`🗡️ Hero ${hero.id} hit enemy[${target.index}] for ${damage}`);
  }

  return {
    updatedEnemies,
    heroLogs,
    heroUpdates,
  };
}
