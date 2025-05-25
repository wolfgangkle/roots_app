import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { recalculateProduction } from '../utils/recalculateProduction.js';

const db = admin.firestore();

// ✅ Only these buildings are allowed to have workers
const workerBuildings = new Set([
  'woodcutter',
  'quarry',
  'farm',
  'wheat_fields',
  'wheat_fields_large',
  'iron_mine',
]);

export async function assignWorkerToBuilding(request: CallableRequest<any>) {
  const { villageId, buildingType, assignedWorkers, mode } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!villageId) throw new HttpsError('invalid-argument', 'Missing villageId.');

  const villageRef = db.collection('users').doc(userId).collection('villages').doc(villageId);
  const villageSnap = await villageRef.get();
  if (!villageSnap.exists) throw new HttpsError('not-found', 'Village not found.');

  const data = villageSnap.data()!;
  const buildings = data.buildings || {};
  let freeWorkers = data.freeWorkers ?? 0;
  const maxProductionPerHour = data.maxProductionPerHour || {};

  // === FILL ALL MODE ===
  if (mode === 'fill_all') {
    const buildingDefSnap = await admin.firestore().collection('buildingDefinitions').get();
    const defs = new Map<string, Record<string, any>>();
    buildingDefSnap.forEach(doc => defs.set(doc.id, doc.data() as Record<string, any>));

    let anyChanges = false;

    for (const [type, config] of Object.entries(buildings)) {
      const level = (config as any).level ?? 0;
      if (level === 0 || !workerBuildings.has(type)) continue;

      const def = defs.get(type);
      if (!def) continue;

      const workerPerLevel = def.workerPerLevel ?? 2;
      const maxAllowed = level * workerPerLevel;
      const current = (config as any).assignedWorkers ?? 0;
      const remaining = maxAllowed - current;

      if (remaining > 0 && freeWorkers > 0) {
        const assign = Math.min(remaining, freeWorkers);
        (buildings[type] as any).assignedWorkers = current + assign;
        freeWorkers -= assign;
        anyChanges = true;
      }
    }

    if (!anyChanges) {
      return {
        success: true,
        message: 'No buildings could be filled. All are already at capacity or no free workers.',
        freeWorkers,
      };
    }

    const currentProduction = recalculateProduction(buildings, maxProductionPerHour);

    await villageRef.update({
      buildings,
      freeWorkers,
      currentProductionPerHour: currentProduction,
    });

    console.log(`✨ Auto-filled all buildings in ${villageId}. Workers left: ${freeWorkers}`);

    return {
      success: true,
      mode: 'fill_all',
      freeWorkers,
      currentProductionPerHour: currentProduction,
    };
  }

  // === SINGLE BUILDING MODE ===
  if (!buildingType) {
    throw new HttpsError('invalid-argument', 'Missing buildingType for non-fill_all mode.');
  }

  if (!workerBuildings.has(buildingType)) {
    throw new HttpsError('failed-precondition', `${buildingType} cannot have workers assigned.`);
  }

  const buildingDefRef = db.collection('buildingDefinitions').doc(buildingType);
  const defSnap = await buildingDefRef.get();
  if (!defSnap.exists) throw new HttpsError('not-found', 'Building definition not found.');
  const def = defSnap.data()!;
  const building = buildings[buildingType];
  if (!building || typeof building.level !== 'number') {
    throw new HttpsError('failed-precondition', 'Building is not constructed.');
  }

  const workerPerLevel = def.workerPerLevel ?? 2;
  const maxAllowed = building.level * workerPerLevel;
  const currentAssigned = building.assignedWorkers ?? 0;

  let targetAssigned = 0;

  if (mode === 'fill') {
    const remaining = maxAllowed - currentAssigned;
    const canAssign = Math.min(remaining, freeWorkers);
    if (canAssign <= 0) {
      return {
        success: true,
        buildingType,
        assignedWorkers: currentAssigned,
        message: 'No available workers to assign.',
      };
    }
    targetAssigned = currentAssigned + canAssign;
  } else {
    if (typeof assignedWorkers !== 'number') {
      throw new HttpsError('invalid-argument', 'assignedWorkers is required in manual mode.');
    }
    if (assignedWorkers < 0) {
      throw new HttpsError('invalid-argument', 'Assigned workers cannot be negative.');
    }
    if (assignedWorkers > maxAllowed) {
      throw new HttpsError(
        'failed-precondition',
        `Cannot assign more than ${maxAllowed} workers to ${buildingType}.`
      );
    }

    const change = assignedWorkers - currentAssigned;
    if (change > freeWorkers) {
      throw new HttpsError(
        'failed-precondition',
        `Not enough free workers (${freeWorkers}) to assign ${change}.`
      );
    }

    targetAssigned = assignedWorkers;
  }

  // ✅ Apply assignment for single building
  const change = targetAssigned - currentAssigned;
  buildings[buildingType].assignedWorkers = targetAssigned;
  const updatedFreeWorkers = freeWorkers - change;
  const currentProduction = recalculateProduction(buildings, maxProductionPerHour);

  await villageRef.update({
    buildings,
    freeWorkers: updatedFreeWorkers,
    currentProductionPerHour: currentProduction,
  });

  console.log(`👷 Assigned ${targetAssigned} to ${buildingType} in ${villageId} (Δ ${change})`);

  return {
    success: true,
    mode: mode || 'manual',
    buildingType,
    assignedWorkers: targetAssigned,
    freeWorkers: updatedFreeWorkers,
    currentProductionPerHour: currentProduction,
  };
}
