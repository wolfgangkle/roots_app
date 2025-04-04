// functions/src/utils/recalculateProduction.ts

/**
 * 🧱 Defines the expected structure for each building entry.
 */
type BuildingMap = Record<string, { level: number }>;

/**
 * 🎯 Result format: production values per resource
 */
type ProductionMap = Record<'wood' | 'stone' | 'food' | 'iron' | 'gold', number>;

/**
 * 🧮 Calculates production per hour based on building levels.
 * Should be run after any building upgrade.
 */
export function recalculateProduction(buildings: BuildingMap): ProductionMap {
  const getLevel = (type: string) => buildings[type]?.level ?? 0;

  return {
    wood: getLevel('woodcutter') * 100,
    stone: getLevel('quarry') * 80,
    food: getLevel('farm') * 120,
    iron: getLevel('mine') * 60,
    gold: getLevel('goldmine') * 40,
  };
}
