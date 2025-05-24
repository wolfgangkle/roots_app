import * as admin from 'firebase-admin';

export async function applyBuildingEffects({
  userId,
  villageRef,
  buildingType,
  newLevel,
}: {
  userId: string;
  villageRef: FirebaseFirestore.DocumentReference;
  buildingType: string;
  newLevel: number;
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

  // 👷 WORKERS
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

  // 👁️ SPY
  let totalSpy = 0;
  for (const [type, def] of buildingDefinitions.entries()) {
    const level = buildings[type]?.level || 0;
    const spyPoints = def.provides?.spy || 0;
    totalSpy += spyPoints * level;
  }
  updates['spy'] = totalSpy;
  console.log(`👁️ Spy stat → ${totalSpy}`);

  // 🌿 CAMOUFLAGE
  let totalCamouflage = 0;
  for (const [type, def] of buildingDefinitions.entries()) {
    const level = buildings[type]?.level || 0;
    const camouflageValue = def.provides?.camouflage || 0;
    totalCamouflage += camouflageValue * level;
  }
  updates['camouflage'] = totalCamouflage;
  console.log(`🌿 Camouflage stat → ${totalCamouflage}`);

  // 📦 STORAGE
  const providesStorage = updatedBuildingDef.provides?.storageCapacity;
  if (providesStorage) {
    for (const [resourceType, baseValue] of Object.entries(providesStorage)) {
      const total = (baseValue as number) * newLevel;
      updates[`storageCapacity.${resourceType}`] = total;
      console.log(`📦 Storage → ${resourceType}: ${total}`);
    }
  }

  // 🛡️ BUNKERS
  const providesSecured = updatedBuildingDef.provides?.maxSecuredResources;
  if (providesSecured) {
    for (const [resourceType, baseValue] of Object.entries(providesSecured)) {
      const total = (baseValue as number) * newLevel;
      updates[`securedResources.${resourceType}`] = total;
      console.log(`🛡️ Secured → ${resourceType}: ${total}`);
    }
  }

  // 🏹 DEFENSE STRUCTURES
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

  // 🏭 PRODUCTION
  const providesProduction = updatedBuildingDef.provides?.maxProductionPerHour;
  if (providesProduction) {
    for (const [resourceType, baseValue] of Object.entries(providesProduction)) {
      const total = (baseValue as number) * newLevel;
      updates[`maxProductionPerHour.${resourceType}`] = total;
      console.log(`🏭 Max Production → ${resourceType}: ${total}`);
    }
  }

  // 🧱 WALL HP
  let totalWallHp = 0;
  for (const [type, def] of buildingDefinitions.entries()) {
    const level = buildings[type]?.level || 0;
    const wallHp = def.provides?.combatStats?.wallHp || 0;
    totalWallHp += wallHp * level;
  }
  updates['wallHp'] = totalWallHp;
  console.log(`🧱 Wall HP stat → ${totalWallHp}`);

  // 🚚 TRADE
  const tradeAmount = updatedBuildingDef.provides?.maxDailyTradeAmount;
  if (typeof tradeAmount === 'number') {
    const total = tradeAmount * newLevel;
    updates['maxDailyTradeAmount'] = total;
    console.log(`🚚 Max Daily Trade Amount → ${total}`);
  }

  // 🧮 BUILDING QUEUE
  const queueSlots = updatedBuildingDef.provides?.buildingQueueSlots;
  if (typeof queueSlots === 'number') {
    const total = queueSlots * newLevel;
    updates['buildingQueueSlots'] = total;
    console.log(`🧮 Building Queue Slots → ${total}`);
  }

  // 🏆 BUILDING POINTS
  const buildingPoints = updatedBuildingDef.points || 0;
  if (buildingPoints > 0) {
    const profileRef = admin.firestore().doc(`users/${userId}/profile/main`);
    await profileRef.set(
      { totalBuildingPoints: admin.firestore.FieldValue.increment(buildingPoints) },
      { merge: true }
    );
    console.log(`🏆 Added ${buildingPoints} points to user profile.`);
  }

  // 🔄 COMMIT
  if (Object.keys(updates).length > 0) {
    await villageRef.update(updates);
  }
}
