import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { scheduleHeroGroupArrivalTask } from './scheduleHeroGroupArrivalTask.js';

const db = admin.firestore();

export async function editHeroGroupMovement(request: any) {
  const { groupId, movementQueue } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!groupId || !Array.isArray(movementQueue)) {
    throw new HttpsError('invalid-argument', 'Group ID and new movementQueue are required.');
  }

  const groupRef = db.collection('heroGroups').doc(groupId);
  const groupSnap = await groupRef.get();
  if (!groupSnap.exists) throw new HttpsError('not-found', 'Hero group not found.');

  const group = groupSnap.data()!;
  const members: string[] = group.members ?? [];

  // Confirm user controls at least one hero in the group
  const ownedHeroesSnap = await db.getAll(...members.map(id => db.doc(`heroes/${id}`)));
  const ownsAny = ownedHeroesSnap.some(doc => doc.exists && doc.data()?.ownerId === userId);
  if (!ownsAny) throw new HttpsError('permission-denied', 'You do not control any heroes in this group.');

  if (!group.arrivesAt || !group.currentStep) {
    throw new HttpsError('failed-precondition', 'Group is not currently moving. Only active groups can be edited.');
  }

  // Optional validation
  for (const step of movementQueue) {
    if (!step || typeof step.action !== 'string') {
      throw new HttpsError('invalid-argument', 'All steps must be valid action objects.');
    }
  }

  // 🧹 Delete existing movement task if present
  const previousTaskName = group.currentMovementTaskName;
  if (previousTaskName) {
    try {
      const { getCloudTasksClient } = await import('../utils/cloudTasksClient.js');
      const client = await getCloudTasksClient();
      await client.deleteTask({ name: previousTaskName });
      console.log(`🗑️ Deleted previous movement task: ${previousTaskName}`);
    } catch (err: any) {
      console.warn(`⚠️ Could not delete previous movement task: ${err.message}`);
    }
  }

  await groupRef.update({
    movementQueue,
    activeCombatId: admin.firestore.FieldValue.delete(),
    returning: admin.firestore.FieldValue.delete(),
    currentMovementTaskName: admin.firestore.FieldValue.delete(),
    lastMovementStartedAt: admin.firestore.Timestamp.now(),
  });


  // 🗓️ Reschedule the task based on time remaining
  const now = Date.now();
  const arrivesAtMillis = group.arrivesAt.toMillis();
  const delaySeconds = Math.max(1, Math.floor((arrivesAtMillis - now) / 1000));

  await scheduleHeroGroupArrivalTask({ groupId, delaySeconds });

  console.log(`✏️ Movement queue edited + rescheduled for group ${groupId}. Steps remaining: ${movementQueue.length}`);

  return {
    success: true,
    updatedQueueLength: movementQueue.length,
  };
}
