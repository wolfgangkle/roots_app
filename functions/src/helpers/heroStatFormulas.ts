export function heroStatFormulas(
  stats: { strength: number; dexterity: number; intelligence: number; constitution: number },
  equipped: Record<string, any>
) {
  const { strength: STR, dexterity: DEX, constitution: CON, intelligence: INT } = stats;

  const baseAttackMin = 5 + Math.floor(STR * 0.4);
  const baseAttackMax = 9 + Math.floor(STR * 0.6);
  const baseAttackSpeedMs = 240_000 - DEX * 3_000;

  let bonusMin = 0;
  let bonusMax = 0;
  let bonusDefense = 0;
  let bonusAttackSpeedReduction = 0;
  let bonusBalance = 0;

  for (const item of Object.values(equipped)) {
    const itemStats = item?.craftedStats;
    if (!itemStats) continue;

    bonusMin += itemStats.minDamage ?? 0;
    bonusMax += itemStats.maxDamage ?? 0;
    bonusDefense += itemStats.armor ?? 0;
    bonusAttackSpeedReduction += itemStats.attackSpeed ?? 0;
    bonusBalance += itemStats.balance ?? 0;
  }

  const finalMin = baseAttackMin + bonusMin;
  const finalMax = baseAttackMax + bonusMax;
  const attackSpeedMs = Math.max(30_000, baseAttackSpeedMs - bonusAttackSpeedReduction);

  const at = Math.floor(
    STR * 1.5 + DEX * 1.0 + (finalMin + finalMax) / 2 + bonusBalance
  );

  const def = Math.floor(
    CON * 1.5 + DEX * 0.8 + bonusDefense
  );

  const hpMax = 100 + CON * 10;
  const manaMax = 50 + INT * 2;

  const combatLevel = Math.floor((at + def) / 2 + hpMax / 10 + manaMax / 20);

  return {
    hpMax,
    manaMax,
    hpRegen: Math.max(60, 300 - CON * 3),
    manaRegen: Math.max(20, 300 - INT * 3),
    maxWaypoints: 10 + Math.floor(INT * 0.5),
    carryCapacity: 50 + STR * 2 + CON * 5,
    baseMovementSpeed: Math.max(600, 1500 - CON * 15),
    combatLevel,
    combat: {
      attackMin: finalMin,
      attackMax: finalMax,
      attackSpeedMs,
      defense: bonusDefense,
      at,
      def,
      regenPerTick: 1,
    },
  };
}
