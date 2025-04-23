export function calculateHeroCombatStats(
  stats: { strength: number; dexterity: number; intelligence: number; constitution: number },
  equipped: Record<string, any>
) {
  const { strength: STR, dexterity: DEX } = stats;

  const baseAttackMin = 5 + Math.floor(STR * 0.4);
  const baseAttackMax = 9 + Math.floor(STR * 0.6);

  // 🐢 Base attack speed (starts at 4 minutes, reduced by DEX)
  const baseAttackSpeedMs = 240_000 - DEX * 3_000;

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
    bonusAttackSpeedReduction += stats.attackSpeed ?? 0; // milliseconds
  }

  return {
    attackMin: baseAttackMin + bonusMin,
    attackMax: baseAttackMax + bonusMax,
    attackSpeedMs: Math.max(30_000, baseAttackSpeedMs - bonusAttackSpeedReduction),
    defense: bonusDefense,
  };
}

// ✅ New: Calculate non-combat derived stats including movementSpeed (in seconds)
export function calculateNonCombatDerivedStats(
  stats: { strength: number; intelligence: number; constitution: number }
) {
  const { strength: STR, intelligence: INT, constitution: CON } = stats;

  return {
    hpMax: 100 + CON * 10,
    hpRegen: Math.max(60, 300 - CON * 3),
    manaMax: 50 + INT * 2,
    manaRegen: Math.max(20, 60 - INT * 1),
    maxWaypoints: 10 + Math.floor(INT * 0.5),
    carryCapacity: 50 + STR * 2 + CON * 5,
    baseMovementSpeed: Math.max(600, 1500 - CON * 15), // ⏱ seconds per tile (min: 10 min)
  };
}
