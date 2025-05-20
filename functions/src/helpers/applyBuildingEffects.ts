import * as admin from 'firebase-admin';

export async function applyBuildingEffects({
  villageRef,
  buildingType,
  newLevel,
}: {
  villageRef: FirebaseFirestore.DocumentReference;
  buildingType: string;
  newLevel: number;
}) {
  const updates: FirebaseFirestore.UpdateData = {};

  const [villageSnap, defSnap] = await Promise.all([
    villageRef.get(),
    admin.firestore().collection('buildingDefinitions').get(),
  ]);

  const villageData = villageSnap.data();
  if (!villageData) {
    console.warn(`⚠️ Village not found at ${villageRef.path}`);
    return;
  }

  const buildings: Record<string, any> = villageData.buildings || {};
  const buildingDefinitions = new Map<string, any>();
  defSnap.docs.forEach(doc => buildingDefinitions.set(doc.id, doc.data()));

  const updatedBuildingDef = buildingDefinitions.get(buildingType);
  if (!updatedBuildingDef) {
    console.warn(`⚠️ No definition found for ${buildingType}`);
    return;
  }

  // 👷 WORKERS: Recalculate free workers based on huts + houses minus assigned
  let totalWorkers = 0;
  for (const [type, def] of buildingDefinitions.entries()) {
    const level = buildings[type]?.level || 0;
    const workersProvided = def.provides?.workers || 0;
    totalWorkers += workersProvided * level;
  }

  const resourceBuildingKeys = ['woodcutter', 'quarry', 'farm', 'mine'];
  let assignedWorkers = 0;
  for (const key of resourceBuildingKeys) {
    const b = buildings[key];
    if (b?.assignedWorkers) assignedWorkers += b.assignedWorkers;
  }

  const freeWorkers = Math.max(0, totalWorkers - assignedWorkers);
  updates['freeWorkers'] = freeWorkers;
  console.log(`👷 Workers → total: ${totalWorkers}, assigned: ${assignedWorkers}, free: ${freeWorkers}`);

  // 📦 STORAGE: Dynamically apply all storageCapacity.* values (e.g. wood, food, stone, iron)
  const providesStorage = updatedBuildingDef.provides?.storageCapacity;
  if (providesStorage) {
    for (const [resourceType, baseValue] of Object.entries(providesStorage)) {
      const total = (baseValue as number) * newLevel;
      updates[`storageCapacity.${resourceType}`] = total;
      console.log(`📦 Storage → ${resourceType}: ${total}`);
    }
  }

  // 🧩 FUTURE: Add more dynamic effects here (bunkers, crafting unlocks, spell access, research...)

  if (Object.keys(updates).length > 0) {
    await villageRef.update(updates);
  }
}
