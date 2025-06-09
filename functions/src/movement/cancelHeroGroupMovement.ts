import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { scheduleHeroGroupArrivalTask } from './scheduleHeroGroupArrivalTask.js';

const db = admin.firestore();

export async function cancelHeroGroupMovement(request: any) {
  const { groupId } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!groupId) throw new HttpsError('invalid-argument', 'Group ID is required.');

  const groupRef = db.collection('heroGroups').doc(groupId);
  const groupSnap = await groupRef.get();
  if (!groupSnap.exists) throw new HttpsError('not-found', 'Hero group not found.');

  const group = groupSnap.data()!;
  const members: string[] = group.members ?? [];

  const ownedHeroesSnap = await db.getAll(...members.map(id => db.doc(`heroes/${id}`)));
  const ownsAny = ownedHeroesSnap.some(doc => doc.exists && doc.data()?.ownerId === userId);
  if (!ownsAny) throw new HttpsError('permission-denied', 'You do not control any heroes in this group.');

  const now = Date.now();
  const arrivesAt = group.arrivesAt?.toMillis();
  const originalStart = arrivesAt && typeof group.movementSpeed === 'number'
    ? arrivesAt - group.movementSpeed * 1000
    : null;

  if (!arrivesAt || !originalStart || arrivesAt <= now) {
    throw new HttpsError('failed-precondition', 'Group is not currently moving.');
  }

  const elapsed = now - originalStart;
  const returnTrip = Math.max(elapsed, 1000); // At least 1s to avoid instant return

  const newArrivesAt = admin.firestore.Timestamp.fromMillis(now + returnTrip);

  // 🧹 Delete the old scheduled task if it exists
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

  // 🧭 Update group with return-to-origin movement
  await groupRef.update({
    movementQueue: [
      {
        action: 'walk',
        x: group.tileX,
        y: group.tileY,
      },
    ],
    currentStep: {
      action: 'walk',
      x: group.tileX,
      y: group.tileY,
    },
    arrivesAt: newArrivesAt,
    returning: true,
    state: 'moving',
    tileKey: `${group.tileX}_${group.tileY}`,
    activeCombatId: admin.firestore.FieldValue.delete(),
    currentMovementTaskName: admin.firestore.FieldValue.delete(),
    lastMovementStartedAt: admin.firestore.Timestamp.now(),
  });



  await scheduleHeroGroupArrivalTask({ groupId, delaySeconds: returnTrip / 1000 });

  console.log(`🔙 HeroGroup ${groupId} is returning to origin. ETA: ${returnTrip / 1000}s`);

  return {
    success: true,
    arrivesBackAt: newArrivesAt.toDate().toISOString(),
  };
}
