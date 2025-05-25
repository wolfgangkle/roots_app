type BuildingMap = Record<string, { level: number; assignedWorkers?: number }>;
type ResourceType = 'wood' | 'stone' | 'food' | 'iron' | 'gold';
type ProductionMap = Record<ResourceType, number>;

export function recalculateProduction(
  buildings: BuildingMap,
  maxProductionPerHour: Record<ResourceType, number>
): ProductionMap {
  const result: ProductionMap = {
    wood: 0,
    stone: 0,
    food: 0,
    iron: 0,
    gold: 0,
  };

  const buildingToResource: Record<string, ResourceType> = {
    woodcutter: 'wood',
    quarry: 'stone',
    farm: 'food',
    mine: 'iron',
  };

  for (const [buildingType, config] of Object.entries(buildings)) {
    const resource = buildingToResource[buildingType];
    if (!resource) continue;

    const assigned = config.assignedWorkers ?? 0;
    const level = config.level ?? 0;
    const max = maxProductionPerHour[resource] ?? 0;

    const maxWorkers = level * 2;
    const ratio = maxWorkers > 0 ? assigned / maxWorkers : 0;

    result[resource] = Math.floor(max * Math.min(Math.max(ratio, 0), 1));
  }

  return result;
}
