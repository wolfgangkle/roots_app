import { onCall, CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { finishBuildingUpgradeLogic } from './finishBuildingUpgrade.js'; // <- Important import

const db = admin.firestore();

export async function devFinishNowLogic(request: CallableRequest<any>) {
  const { villageId } = request.data;
  const userId = request.auth?.uid;

  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  if (!villageId) {
    throw new HttpsError('invalid-argument', 'villageId is required.');
  }

  const villageRef = db.collection('users').doc(userId).collection('villages').doc(villageId);
  const villageSnap = await villageRef.get();

  if (!villageSnap.exists) {
    throw new HttpsError('not-found', 'Village not found.');
  }

  const villageData = villageSnap.data()!;
  const taskName = villageData.currentBuildTaskName;

  if (taskName) {
    try {
      const { getCloudTasksClient } = await import('../utils/cloudTasksClient.js');
      const client = await getCloudTasksClient();
      await client.deleteTask({ name: taskName });
      console.log(`🗑️ Deleted Cloud Task: ${taskName}`);
    } catch (err: any) {
      console.warn(`⚠️ Failed to delete task: ${taskName}`, err.message);
    }
  } else {
    console.log('ℹ️ No scheduled task to delete.');
  }

  // ✅ Call logic directly instead of HTTP
  try {
    console.log('⚡ Running finishBuildingUpgradeLogic with forceFinish: true...');
    const result = await finishBuildingUpgradeLogic({
      data: { villageId, forceFinish: true },
      auth: { uid: userId },
    } as CallableRequest<any>);

    console.log('✅ Logic executed directly:', result);

    return {
      success: true,
      result,
    };
  } catch (error: any) {
    console.error('❌ Direct logic execution failed:', error.message);
    return {
      success: false,
      error: error.message,
    };
  }
}

export const devFinishNow = onCall(devFinishNowLogic);
