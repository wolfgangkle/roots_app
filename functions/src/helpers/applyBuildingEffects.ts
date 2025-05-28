import * as admin from 'firebase-admin';

export async function applyBuildingEffects({
  userId,
  villageRef,
  buildingType,
  newLevel,
  assignedWorkers, // ✅ optional param
}: {
  userId: string;
  villageRef: FirebaseFirestore.DocumentReference;
  buildingType: string;
  newLevel: number;
  assignedWorkers?: number;
}) {
  const updates: FirebaseFirestore.UpdateData<Record<string, any>> = {};

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

  const resourceBuildingKeys = ['woodcutter', 'quarry', 'farm', 'mine'];

  // 👷 WORKERS
  let totalWorkers = 0;
  for (const [type, def] of buildingDefinitions.entries()) {
    const level = buildings[type]?.level || 0;
    const workersProvided = def.provides?.workers || 0;
    totalWorkers += workersProvided * level;
  }

  let assigned = 0;
  for (const key of resourceBuildingKeys) {
    const b = buildings[key];
    if (b?.assignedWorkers) assigned += b.assignedWorkers;
  }

  const freeWorkers = Math.max(0, totalWorkers - assigned);
  updates['freeWorkers'] = freeWorkers;
  console.log(`👷 Workers → total: ${totalWorkers}, assigned: ${assigned}, free: ${freeWorkers}`);

  // 👁️ Spy
  let spy = 0;
  for (const [type, def] of buildingDefinitions.entries()) {
    const level = buildings[type]?.level || 0;
    const spyPoints = def.provides?.spy || 0;
    spy += spyPoints * level;
  }
  updates['spy'] = spy;

  // 🌿 Camouflage
  let camouflage = 0;
  for (const [type, def] of buildingDefinitions.entries()) {
    const level = buildings[type]?.level || 0;
    const camo = def.provides?.camouflage || 0;
    camouflage += camo * level;
  }
  updates['camouflage'] = camouflage;

  // 📦 Storage
  const providesStorage = updatedBuildingDef.provides?.storageCapacity;
  if (providesStorage) {
    for (const [resourceType, baseValue] of Object.entries(providesStorage)) {
      const previous = villageData.storageCapacity?.[resourceType] ?? 0;
      const addition = (baseValue as number) * newLevel;
      const total = previous + addition;
      updates[`storageCapacity.${resourceType}`] = total;
    }
  }

  // 🛡️ Secured resources
  const providesSecured = updatedBuildingDef.provides?.maxSecuredResources;
  if (providesSecured) {
    for (const [resourceType, baseValue] of Object.entries(providesSecured)) {
      const total = (baseValue as number) * newLevel;
      updates[`securedResources.${resourceType}`] = total;
    }
  }

  // 🏹 Defense
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
  }

  // 🏭 Production
  const providesProduction = updatedBuildingDef.provides?.maxProductionPerHour;
  if (providesProduction) {
    for (const [resourceType, baseValue] of Object.entries(providesProduction)) {
      const total = (baseValue as number) * newLevel;
      updates[`maxProductionPerHour.${resourceType}`] = total;
    }
  }

  // 🧱 Wall HP
  let wallHp = 0;
  for (const [type, def] of buildingDefinitions.entries()) {
    const level = buildings[type]?.level || 0;
    const wall = def.provides?.combatStats?.wallHp || 0;
    wallHp += wall * level;
  }
  updates['wallHp'] = wallHp;

  // 🚚 Trade
  if (updatedBuildingDef.provides?.maxDailyResourceTradeAmount) {
    updates['maxDailyResourceTradeAmount'] =
      updatedBuildingDef.provides.maxDailyResourceTradeAmount * newLevel;
  }
  if (updatedBuildingDef.provides?.maxDailyGoldTradeAmount) {
    updates['maxDailyGoldTradeAmount'] =
      updatedBuildingDef.provides.maxDailyGoldTradeAmount * newLevel;
  }

  // 🧮 Queue
  if (updatedBuildingDef.provides?.buildingQueueSlots) {
    updates['buildingQueueSlots'] =
      updatedBuildingDef.provides.buildingQueueSlots * newLevel;
  }

  // 🏆 Points
  if (updatedBuildingDef.points) {
    const profileRef = admin.firestore().doc(`users/${userId}/profile/main`);
    await profileRef.set(
      { totalBuildingPoints: admin.firestore.FieldValue.increment(updatedBuildingDef.points) },
      { merge: true }
    );
  }

  // ✅ Restore assignedWorkers
  if (resourceBuildingKeys.includes(buildingType)) {
    const safeAssigned = typeof assignedWorkers === 'number' ? assignedWorkers : 0;
    updates[`buildings.${buildingType}.assignedWorkers`] = safeAssigned;
    console.log(`🔁 Restored assignedWorkers for ${buildingType}: ${safeAssigned}`);
  }

  // 🔄 Commit
  if (Object.keys(updates).length > 0) {
    await villageRef.update(updates);
  }
}
