import { onCall, CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { scheduleUpgradeTask } from '../utils/scheduleUpgradeTask.js';

const db = admin.firestore();

export async function startBuildingUpgradeLogic(request: CallableRequest<any>) {
  const { villageId, buildingType } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!villageId || !buildingType)
    throw new HttpsError('invalid-argument', 'villageId and buildingType are required.');

  const villageRef = db.collection('users').doc(userId).collection('villages').doc(villageId);
  const buildingDefRef = db.collection('buildingDefinitions').doc(buildingType);

  const [villageSnap, defSnap] = await Promise.all([
    villageRef.get(),
    buildingDefRef.get(),
  ]);

  if (!villageSnap.exists) throw new HttpsError('not-found', 'Village not found.');
  if (!defSnap.exists) throw new HttpsError('not-found', 'Building definition not found.');

  const villageData = villageSnap.data()!;
  const def = defSnap.data()!;
  const buildings: Record<string, { level: number }> = villageData.buildings || {};
  const resources: Record<string, number> = villageData.resources || {};
  const buildJob = villageData.currentBuildJob;

  if (buildJob) {
    throw new HttpsError('failed-precondition', 'Another building is already upgrading.');
  }

  const currentLevel = buildings[buildingType]?.level || 0;
  const targetLevel = currentLevel + 1;

  const baseCost = def.baseCost || {};
  const costFactor = def.costMultiplier?.factor ?? 1;
  const costLinear = def.costMultiplier?.linear ?? 0;

  const cost: Record<string, number> = {};
  for (const key in baseCost) {
    const base = baseCost[key];
    const linearPart = key === 'gold' ? 0 : targetLevel * costLinear;
    cost[key] = Math.round(base * Math.pow(targetLevel, costFactor) + linearPart);
  }

  const baseTimeSec = def.baseBuildTimeSeconds ?? 30;
  const buildTimeScaling = def.buildTimeScaling ?? {};
  const timeFactor = buildTimeScaling.factor ?? 1;
  const timeLinear = buildTimeScaling.linear ?? 0;

  const durationSeconds = Math.round(
    baseTimeSec * Math.pow(targetLevel, timeFactor) + targetLevel * timeLinear
  );

  // ✅ Check resource availability
  for (const key in cost) {
    if ((resources[key] || 0) < cost[key]) {
      throw new HttpsError('failed-precondition', `Not enough ${key}`);
    }
  }

  // 💸 Deduct resources
  const newResources: Record<string, number> = { ...resources };
  for (const key in cost) {
    newResources[key] -= cost[key];
  }

  const now = new Date();
  const buildJobData = {
    buildingType,
    targetLevel,
    startedAt: admin.firestore.Timestamp.fromDate(now),
    durationSeconds,
  };

  await villageRef.update({
    resources: newResources,
    currentBuildJob: buildJobData,
    lastUpgradeCheck: admin.firestore.Timestamp.fromDate(now),
  });

  console.log(`🚧 Upgrade started: ${buildingType} → L${targetLevel} (${durationSeconds}s)`);

  await scheduleUpgradeTask({
    villageId,
    userId,
    delaySeconds: durationSeconds,
  });

  return {
    started: true,
    buildingType,
    targetLevel,
    durationSeconds,
    newResources,
  };
}

export const startBuildingUpgrade = onCall(startBuildingUpgradeLogic);
