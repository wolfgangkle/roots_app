import * as admin from 'firebase-admin';

const db = admin.firestore();

type BuildingMap = Record<string, { level: number }>;
type ResourceType = 'wood' | 'stone' | 'food' | 'iron' | 'gold';
type ProductionMap = Record<ResourceType, number>;

export async function recalculateProduction(buildings: BuildingMap): Promise<ProductionMap> {
  const result: ProductionMap = {
    wood: 0,
    stone: 0,
    food: 0,
    iron: 0,
    gold: 0,
  };

  const buildingTypes = Object.keys(buildings);
  const snapshots = await Promise.all(
    buildingTypes.map(type => db.doc(`buildingDefinitions/${type}`).get())
  );

  for (const snap of snapshots) {
    if (!snap.exists) continue;

    const def = snap.data()!;
    const type = def.type;
    const base = def.baseProductionPerHour ?? 0;
    const level = buildings[type]?.level ?? 0;

    const resource = (def.produces ?? inferProducedResource(type)) as ResourceType | null;

    if (resource && Object.prototype.hasOwnProperty.call(result, resource)) {
      result[resource] += base * level;
    }
  }

  return result;
}

function inferProducedResource(type: string): ResourceType | null {
  if (type.includes('wood')) return 'wood';
  if (type.includes('stone') || type.includes('quarry')) return 'stone';
  if (type.includes('farm') || type.includes('food')) return 'food';
  if (type.includes('mine') || type.includes('iron')) return 'iron';
  if (type.includes('gold')) return 'gold';
  return null;
}
