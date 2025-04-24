export function calculateHeroCombatStats(
  stats: { strength: number; dexterity: number; intelligence: number; constitution: number },
  equipped: Record<string, any>
) {
  const { strength: STR, dexterity: DEX, constitution: CON } = stats;

  const baseAttackMin = 5 + Math.floor(STR * 0.4);
  const baseAttackMax = 9 + Math.floor(STR * 0.6);
  const baseAttackSpeedMs = 240_000 - DEX * 3_000;

  let bonusMin = 0;
  let bonusMax = 0;
  let bonusDefense = 0;
  let bonusAttackSpeedReduction = 0;
  let bonusBalance = 0;

  for (const item of Object.values(equipped)) {
    const stats = item?.craftedStats;
    if (!stats) continue;

    bonusMin += stats.minDamage ?? 0;
    bonusMax += stats.maxDamage ?? 0;
    bonusDefense += stats.armor ?? 0;
    bonusAttackSpeedReduction += stats.attackSpeed ?? 0;
    bonusBalance += stats.balance ?? 0;
  }

  const finalMin = baseAttackMin + bonusMin;
  const finalMax = baseAttackMax + bonusMax;
  const attackSpeedMs = Math.max(30_000, baseAttackSpeedMs - bonusAttackSpeedReduction);

  const at = Math.floor(
    STR * 1.5 +
    DEX * 1.0 +
    (finalMin + finalMax) / 2 +
    bonusBalance
  );

  const def = Math.floor(
    CON * 1.5 +
    DEX * 0.8 +
    bonusDefense
  );

  return {
    attackMin: finalMin,
    attackMax: finalMax,
    attackSpeedMs,
    defense: bonusDefense,
    at,
    def,
    // Optional: return combatLevel too here
  };
}

export function calculateNonCombatDerivedStats(
  stats: { strength: number; intelligence: number; constitution: number }
) {
  const { strength: STR, intelligence: INT, constitution: CON } = stats;


  const hpMax = 100 + CON * 10;
  const manaMax = 50 + INT * 2;

  const at = 0; // placeholder if you want to calculate combatLevel here
  const def = 0;

  const combatLevel = Math.floor((at + def) / 2 + hpMax / 10 + manaMax / 20); // for future split calc

  return {
    hpMax,
    hpRegen: Math.max(60, 300 - CON * 3),
    manaMax,
    manaRegen: Math.max(20, 60 - INT * 1),
    maxWaypoints: 10 + Math.floor(INT * 0.5),
    carryCapacity: 50 + STR * 2 + CON * 5,
    baseMovementSpeed: Math.max(600, 1500 - CON * 15),
    combatLevel // optional here or in combat calc
  };
}
