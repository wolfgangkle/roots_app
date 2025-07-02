import * as admin from 'firebase-admin';
import { scheduleHeroGroupArrivalTask } from './scheduleHeroGroupArrivalTask.js';

const db = admin.firestore();

/**
 * Checks if the group has more steps. If yes, sets state to 'moving' and schedules next task.
 * If not, sets group and heroes to 'idle'.
 */
export async function maybeContinueGroupMovement(groupId: string): Promise<void> {
  const groupRef = db.collection('heroGroups').doc(groupId);
  const snap = await groupRef.get();
  if (!snap.exists) {
    console.warn(`❌ Group ${groupId} not found in maybeContinueGroupMovement.`);
    return;
  }

  const group = snap.data()!;
  const currentStep = group.currentStep;
  const queue: any[] = group.movementQueue ?? [];

  // 🧠 Check both currentStep and the movementQueue
  if (!currentStep || queue.length === 0) {
    console.log(`💤 Group ${groupId} has no more steps or stale step. Forcing idle state.`);

    await groupRef.update({
      state: 'idle',
      currentStep: admin.firestore.FieldValue.delete(),
      arrivesAt: admin.firestore.FieldValue.delete(),
      currentMovementTaskName: admin.firestore.FieldValue.delete(),
    });

    // 🧍‍♂️ Set all heroes in group to idle
    const heroIds: string[] = group.members ?? [];
    const heroSnaps = await db.getAll(...heroIds.map(id => db.doc(`heroes/${id}`)));
    const batch = db.batch();

    for (const snap of heroSnaps) {
      if (snap.exists) {
        batch.update(snap.ref, { state: 'idle' });
      }
    }

    await batch.commit();
    return;
  }

  const { x, y } = currentStep;
  const dx = Math.abs(x - group.tileX);
  const dy = Math.abs(y - group.tileY);
  const distance = Math.sqrt(dx * dx + dy * dy);
  const movementSpeed = group.movementSpeed;

  if (typeof movementSpeed !== 'number') {
    console.warn(`🚨 Group ${groupId} has no movementSpeed defined!`);
    return;
  }

  const travelTime = movementSpeed * distance;
  const bufferSeconds = 1;
  const totalDelay = travelTime + bufferSeconds;

  const arrivesAt = admin.firestore.Timestamp.fromMillis(Date.now() + totalDelay * 1000);

  await groupRef.update({
    arrivesAt,
    state: 'moving',
    currentMovementTaskName: admin.firestore.FieldValue.delete(),
    lastMovementStartedAt: admin.firestore.Timestamp.now(),
  });

  // Update all surviving heroes to moving state
  const heroIds: string[] = group.members ?? [];
  if (heroIds.length > 0) {
    const heroSnaps = await db.getAll(...heroIds.map(id => db.doc(`heroes/${id}`)));
    const heroBatch = db.batch();
    for (const snap of heroSnaps) {
      if (snap.exists) {
        heroBatch.update(snap.ref, { state: 'moving' });
      }
    }
    await heroBatch.commit();
  }

  await scheduleHeroGroupArrivalTask({
    groupId,
    delaySeconds: totalDelay,
  });

  console.log(`🏃 Group ${groupId} continues to (${x},${y}) in ${totalDelay.toFixed(2)}s`);
}
