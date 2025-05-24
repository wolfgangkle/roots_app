import * as admin from 'firebase-admin';

const db = admin.firestore();

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
    const max = maxProductionPerHour[resource] ?? 0;

    result[resource] = Math.floor(max * Math.min(assigned / 5, 1));
  }

  return result;
}

