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

  // 👁️ SPY: Recalculate total spy points from all buildings
  let totalSpy = 0;
  for (const [type, def] of buildingDefinitions.entries()) {
    const level = buildings[type]?.level || 0;
    const spyPoints = def.provides?.spy || 0;
    totalSpy += spyPoints * level;
  }
  updates['spy'] = totalSpy;
  console.log(`👁️ Spy stat → ${totalSpy}`);

  // 🌿 CAMOUFLAGE: Recalculate total camouflage value from all buildings
  let totalCamouflage = 0;
  for (const [type, def] of buildingDefinitions.entries()) {
    const level = buildings[type]?.level || 0;
    const camouflageValue = def.provides?.camouflage || 0;
    totalCamouflage += camouflageValue * level;
  }
  updates['camouflage'] = totalCamouflage;
  console.log(`🌿 Camouflage stat → ${totalCamouflage}`);

  // 📦 STORAGE: Dynamically apply all storageCapacity.* values (e.g. wood, food, stone, iron)
  const providesStorage = updatedBuildingDef.provides?.storageCapacity;
  if (providesStorage) {
    for (const [resourceType, baseValue] of Object.entries(providesStorage)) {
      const total = (baseValue as number) * newLevel;
      updates[`storageCapacity.${resourceType}`] = total;
      console.log(`📦 Storage → ${resourceType}: ${total}`);
    }
  }

  // 🛡️ BUNKERS: Dynamically apply all securedResources.* from provides.maxSecuredResources
  const providesSecured = updatedBuildingDef.provides?.maxSecuredResources;
  if (providesSecured) {
    for (const [resourceType, baseValue] of Object.entries(providesSecured)) {
      const total = (baseValue as number) * newLevel;
      updates[`securedResources.${resourceType}`] = total;
      console.log(`🛡️ Secured → ${resourceType}: ${total}`);
    }
  }

  // 🏹 DEFENSE STRUCTURE: If this building provides combatStats, write them under defenseStructures.{buildingType}
  const combatStats = updatedBuildingDef.provides?.combatStats;
  if (combatStats) {
    const scaledStats: Record<string, number> = {};
    for (const [stat, value] of Object.entries(combatStats)) {
      scaledStats[stat] = (value as number) * newLevel;
    }

    updates[`defenseStructures.${buildingType}`] = {
      level: newLevel,
      combatStats: scaledStats,
    };

    console.log(`🏹 Defense → ${buildingType}:`, scaledStats);
  }

  if (Object.keys(updates).length > 0) {
    await villageRef.update(updates);
  }
}
