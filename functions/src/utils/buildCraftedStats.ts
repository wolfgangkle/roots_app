export function buildCraftedStats(
  baseStats: Record<string, any>,
  research: Record<string, any> = {},
  type: string = 'misc'
): Record<string, number> {
  const stats: Record<string, number> = {};

  if (type === 'weapon') {
    stats.minDamage = baseStats.minDamage ?? 0;
    stats.maxDamage = baseStats.maxDamage ?? 0;
    stats.attackSpeed = baseStats.attackSpeed ?? 1000;
    stats.balance = research.balance !== undefined ? research.balance : baseStats.balance ?? 0;
  }

  if (type === 'armor') {
    stats.armor = baseStats.armor ?? 0;
    stats.camouflage = baseStats.camouflage ?? 0;
  }

  // Always include weight
  stats.weight = research.weight !== undefined ? research.weight : baseStats.weight ?? 0;

  return stats;
}
