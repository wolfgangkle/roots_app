import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { scheduleHeroGroupArrivalTask } from './scheduleHeroGroupArrivalTask.js';

const db = admin.firestore();

export async function startHeroGroupMovement(request: any) {
  const { groupId, movementQueue } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!groupId || !Array.isArray(movementQueue) || movementQueue.length === 0) {
    throw new HttpsError('invalid-argument', 'Group ID and non-empty movementQueue are required.');
  }

  const groupRef = db.collection('heroGroups').doc(groupId);
  const groupSnap = await groupRef.get();
  if (!groupSnap.exists) throw new HttpsError('not-found', 'Hero group not found.');

  const group = groupSnap.data()!;
  const members: string[] = group.members ?? [];

  // Verify that the user controls at least one hero in the group
  const ownedHeroesSnap = await db.getAll(...members.map(id => db.doc(`heroes/${id}`)));
  const ownsAny = ownedHeroesSnap.some(doc => doc.exists && doc.data()?.ownerId === userId);
  if (!ownsAny) throw new HttpsError('permission-denied', 'You do not control any heroes in this group.');

  if (group.arrivesAt) {
    throw new HttpsError('failed-precondition', 'Hero group is already moving.');
  }

  const tileX = group.tileX;
  const tileY = group.tileY;

  const firstStep = movementQueue[0];
  if (!firstStep || firstStep.action !== 'walk' || typeof firstStep.x !== 'number' || typeof firstStep.y !== 'number') {
    throw new HttpsError('invalid-argument', 'First movement step must be a walk step with valid x/y.');
  }

  const dx = Math.abs(firstStep.x - tileX);
  const dy = Math.abs(firstStep.y - tileY);
  if (dx > 1 || dy > 1) {
    throw new HttpsError('invalid-argument', 'First step must be to an adjacent tile.');
  }

  const movementSpeed = group.movementSpeed;
  if (typeof movementSpeed !== 'number') {
    console.error(`🚨 Missing movementSpeed in group ${groupId}`);
    throw new HttpsError('failed-precondition', 'Hero group has no defined movement speed.');
  }

  const now = Date.now();
  const arrivesAt = admin.firestore.Timestamp.fromMillis(now + movementSpeed * 1000);

  await groupRef.update({
    movementQueue,
    currentStep: firstStep,
    arrivesAt,
  });

  // Set state = 'moving' on all group heroes
  const batch = db.batch();
  for (const heroSnap of ownedHeroesSnap) {
    if (heroSnap.exists) {
      batch.update(heroSnap.ref, { state: 'moving' });
    }
  }
  await batch.commit();

  await scheduleHeroGroupArrivalTask({ groupId, delaySeconds: movementSpeed });

  console.log(`🚶 HeroGroup ${groupId} started moving to (${firstStep.x}, ${firstStep.y})`);

  return {
    success: true,
    arrivesAt: arrivesAt.toDate().toISOString(),
    queuedSteps: movementQueue.length,
  };
}
