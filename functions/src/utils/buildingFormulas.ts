// functions/src/utils/buildingFormulas.ts

type ResourceCost = Record<string, number>;

const baseCosts: Record<string, ResourceCost> = {
  woodcutter: { wood: 50, stone: 20 },
  quarry: { wood: 60, stone: 30 },
  farm: { wood: 40, stone: 40 },
  mine: { wood: 80, stone: 60 },
  goldmine: { wood: 100, stone: 80 },
  wood_storage: { wood: 150, stone: 100 },
};

/**
 * 🧮 Calculates upgrade cost based on building type and target level.
 */
export function getUpgradeCost(buildingType: string, level: number): ResourceCost {
  const base = baseCosts[buildingType] || {};
  const multiplier = level;
  const cost: ResourceCost = {};

  for (const key in base) {
    cost[key] = (base[key] || 0) * multiplier; // No TS error now
  }

  return cost;
}

/**
 * ⏱️ Returns duration in milliseconds
 */
export function getUpgradeDuration(buildingType: string, level: number): number {
  return 30 * Math.sqrt(level * level) * 1000; // e.g. L2 = ~1272s
}
