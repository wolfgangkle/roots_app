import { onCall, CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { applyBuildingEffects } from '../helpers/applyBuildingEffects.js';

const db = admin.firestore();

export async function finishBuildingUpgradeLogic(request: CallableRequest<any>) {
  const { villageId, forceFinish } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!villageId) throw new HttpsError('invalid-argument', 'villageId is required.');

  const villageRef = db.collection('users').doc(userId).collection('villages').doc(villageId);
  const doc = await villageRef.get();
  if (!doc.exists) throw new HttpsError('not-found', 'Village not found.');

  const dataObj = doc.data()!;
  const buildJob = dataObj.currentBuildJob;
  const buildings: Record<string, any> = dataObj.buildings || {};
  const lastCheck = (dataObj.lastUpgradeCheck instanceof admin.firestore.Timestamp)
    ? dataObj.lastUpgradeCheck.toDate()
    : new Date(0);
  const now = new Date();

  const secondsSinceLastCheck = (now.getTime() - lastCheck.getTime()) / 1000;
  if (!forceFinish && secondsSinceLastCheck < 10) {
    console.log(`⏱️ Throttled: ${villageId} checked ${secondsSinceLastCheck.toFixed(2)}s ago`);
    return { throttled: true, secondsSinceLastCheck };
  }

  if (!buildJob) {
    console.log(`👻 No active build job for ${villageId}, probably already finished.`);
    await villageRef.update({
      lastUpgradeCheck: admin.firestore.Timestamp.fromDate(now),
    });
    return { message: 'No build job in progress (possibly already completed).' };
  }

  const startedAt = (buildJob.startedAt instanceof admin.firestore.Timestamp)
    ? buildJob.startedAt.toDate()
    : new Date(0);
  const duration = buildJob.durationSeconds || 0;
  const finishTime = new Date(startedAt.getTime() + duration * 1000);

  if (now < finishTime) {
    if (!forceFinish) {
      return { message: 'Upgrade is not complete yet.' };
    } else {
      console.log(`🚀 Force finishing early: ${villageId} (scheduled until ${finishTime.toISOString()})`);
    }
  }


  const type = buildJob.buildingType;
  const targetLevel = buildJob.targetLevel;

  // 🛠️ Preserve assignedWorkers if it exists
  const existing = buildings[type] || {};
  const assignedWorkers = existing.assignedWorkers;
  const upgradedBuilding: Record<string, any> = { level: targetLevel };
  if (typeof assignedWorkers === 'number') {
    upgradedBuilding.assignedWorkers = assignedWorkers;
    console.log(`👷 Preserved ${assignedWorkers} assigned workers for ${type}`);
  }

  const newBuildings = {
    ...buildings,
    [type]: upgradedBuilding,
  };

  await villageRef.update({
    buildings: newBuildings,
  });

  // 🧩 Apply effects, safely reusing assignedWorkers
  await applyBuildingEffects({
    userId,
    villageRef,
    buildingType: type,
    newLevel: targetLevel,
    assignedWorkers, // ✅ passed forward
  });

  // 🗑️ Delete scheduled Cloud Task (if exists)
  const taskName = dataObj.currentBuildTaskName;
  if (taskName) {
    try {
      const { getCloudTasksClient } = await import('../utils/cloudTasksClient.js');
      const client = await getCloudTasksClient();
      await client.deleteTask({ name: taskName });
      console.log(`🗑️ Deleted Cloud Task: ${taskName}`);
    } catch (err: any) {
      console.warn(`⚠️ Could not delete task ${taskName}:`, err.message);
    }
  }

  // 🧹 Cleanup build job metadata
  await villageRef.update({
    currentBuildJob: admin.firestore.FieldValue.delete(),
    lastUpgradeCheck: admin.firestore.Timestamp.fromDate(now),
    lastUpgradeMethod: request.auth?.uid ? 'onCall' : 'scheduled',
    currentBuildTaskName: admin.firestore.FieldValue.delete(),
  });

  // 📬 Create event report
  const reportRef = villageRef.collection('finishedJobs').doc();
  await reportRef.set({
    type: 'upgrade',
    title: `🏗️ ${type} upgraded to level ${targetLevel}`,
    buildingType: type,
    newLevel: targetLevel,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    hiddenForUserIds: [],
    read: false,
    userId,
  });

  console.log(`📬 Upgrade report created for village ${villageId}`);
  console.log(`✅ Finished upgrade for ${villageId}: ${type} → Level ${targetLevel}`);

  return {
    finished: true,
    forced: !!forceFinish,
    newLevel: targetLevel,
    buildingType: type,
  };
}

export const finishBuildingUpgrade = onCall(finishBuildingUpgradeLogic);
