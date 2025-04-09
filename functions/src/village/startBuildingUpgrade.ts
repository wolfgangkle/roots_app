import { onCall, CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { getUpgradeCost, getUpgradeDuration } from '../utils/buildingFormulas.js';
import { scheduleUpgradeTask } from '../utils/scheduleUpgradeTask.js'; // 🔁 NEW import

const db = admin.firestore();

/**
 * 🧠 Pure logic for starting a building upgrade.
 * Used directly from index.ts or wrapped as a Firebase function.
 */
export async function startBuildingUpgradeLogic(request: CallableRequest<any>) {
  const { villageId, buildingType } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!villageId || !buildingType)
    throw new HttpsError('invalid-argument', 'villageId and buildingType are required.');

  const villageRef = db.collection('users').doc(userId).collection('villages').doc(villageId);
  const doc = await villageRef.get();
  if (!doc.exists) throw new HttpsError('not-found', 'Village not found.');

  const dataObj = doc.data()!;
  const buildings: Record<string, { level: number }> = dataObj.buildings || {};
  const resources: Record<string, number> = dataObj.resources || {};
  const buildJob = dataObj.currentBuildJob;

  if (buildJob) {
    throw new HttpsError('failed-precondition', 'Another building is already upgrading.');
  }

  const currentLevel = buildings[buildingType]?.level || 0;
  const targetLevel = currentLevel + 1;

  const cost = getUpgradeCost(buildingType, targetLevel);
  const duration = getUpgradeDuration(buildingType, targetLevel);
  const durationSeconds = Math.floor(duration / 1000);
  const now = new Date();

  // ✅ Check if enough resources
  for (const key in cost) {
    if ((resources[key] || 0) < cost[key]) {
      throw new HttpsError('failed-precondition', `Not enough ${key}`);
    }
  }

  // 💸 Deduct cost
  const newResources: Record<string, number> = { ...resources };
  for (const key in cost) {
    newResources[key] = (resources[key] || 0) - cost[key];
  }

  const buildJobData = {
    buildingType,
    targetLevel,
    startedAt: admin.firestore.Timestamp.fromDate(now),
    durationSeconds: durationSeconds,
  };

  // 🔄 Update village with new job and resources
  await villageRef.update({
    resources: newResources,
    currentBuildJob: buildJobData,
    lastUpgradeCheck: admin.firestore.Timestamp.fromDate(now),
  });

  console.log(`🚧 Started upgrade for ${buildingType} → L${targetLevel} (duration ${durationSeconds}s)`);

  // ⏰ Schedule backend upgrade
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

/**
 * 🛠️ Firebase-wrapped function export
 */
export const startBuildingUpgrade = onCall(startBuildingUpgradeLogic);
