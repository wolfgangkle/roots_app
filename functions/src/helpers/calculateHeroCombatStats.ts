export function calculateHeroCombatStats(
  stats: { strength: number; dexterity: number; intelligence: number; constitution: number },
  equipped: Record<string, any>
) {
  const { strength: STR, dexterity: DEX } = stats;

  const baseAttackMin = 5 + Math.floor(STR * 0.4);
  const baseAttackMax = 9 + Math.floor(STR * 0.6);
  const baseAttackSpeedMs = Math.max(400, 1000 - DEX * 20);

  let bonusMin = 0;
  let bonusMax = 0;
  let bonusDefense = 0;
  let bonusAttackSpeedReduction = 0;

  for (const item of Object.values(equipped)) {
    const stats = item?.craftedStats;
    if (!stats) continue;

    bonusMin += stats.minDamage ?? 0;
    bonusMax += stats.maxDamage ?? 0;
    bonusDefense += stats.armor ?? 0;
    bonusAttackSpeedReduction += stats.attackSpeed ?? 0;
  }

  return {
    attackMin: baseAttackMin + bonusMin,
    attackMax: baseAttackMax + bonusMax,
    attackSpeedMs: Math.max(200, baseAttackSpeedMs - bonusAttackSpeedReduction),
    defense: bonusDefense,
  };
}
