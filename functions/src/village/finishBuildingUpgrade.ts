import { onCall, CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { applyBuildingEffects } from '../helpers/applyBuildingEffects.js';

const db = admin.firestore();

export async function finishBuildingUpgradeLogic(request: CallableRequest<any>) {
  const { villageId } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!villageId) throw new HttpsError('invalid-argument', 'villageId is required.');

  const villageRef = db.collection('users').doc(userId).collection('villages').doc(villageId);
  const doc = await villageRef.get();
  if (!doc.exists) throw new HttpsError('not-found', 'Village not found.');

  const dataObj = doc.data()!;
  const buildJob = dataObj.currentBuildJob;
  const buildings: Record<string, { level: number }> = dataObj.buildings || {};
  const lastCheck = (dataObj.lastUpgradeCheck instanceof admin.firestore.Timestamp)
    ? dataObj.lastUpgradeCheck.toDate()
    : new Date(0);
  const now = new Date();

  // ⏱️ Throttle repeated finish attempts
  const secondsSinceLastCheck = (now.getTime() - lastCheck.getTime()) / 1000;
  if (secondsSinceLastCheck < 10) {
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
    return { message: 'Upgrade is not complete yet.' };
  }

  const type = buildJob.buildingType;
  const targetLevel = buildJob.targetLevel;

  const newBuildings = { ...buildings, [type]: { level: targetLevel } };

  // 🧩 Apply additional building-specific effects
  await applyBuildingEffects({
    userId,
    villageRef,
    buildingType: type,
    newLevel: targetLevel,
  });

  // 🏗️ Final update
  await villageRef.update({
    buildings: newBuildings,
    currentBuildJob: admin.firestore.FieldValue.delete(),
    lastUpgradeCheck: admin.firestore.Timestamp.fromDate(now),
    lastUpgradeMethod: request.auth?.uid ? 'onCall' : 'scheduled',
  });



  console.log(`✅ Finished upgrade for ${villageId}: ${type} → Level ${targetLevel}`);

  return {
    finished: true,
    newLevel: targetLevel,
    buildingType: type,
  };
}

export const finishBuildingUpgrade = onCall(finishBuildingUpgradeLogic);
