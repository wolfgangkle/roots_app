import * as admin from 'firebase-admin';
import { scheduleHeroGroupArrivalTask } from './scheduleHeroGroupArrivalTask.js';

const db = admin.firestore();

export async function resolveMovementStep(groupId: string): Promise<boolean> {
  const groupRef = db.collection('heroGroups').doc(groupId);
  const snap = await groupRef.get();

  if (!snap.exists) {
    console.warn(`⚠️ resolveMovementStep: group ${groupId} not found.`);
    return false;
  }

  const group = snap.data()!;
  const queue = group.movementQueue ?? [];
  const currentStep = queue[0];

  if (!currentStep) {
    console.log(`✅ Group ${groupId} has no movement step.`);
    return false;
  }

  if (currentStep.action !== 'walk') {
    console.warn(`⚠️ Unexpected step type in resolveMovementStep: ${currentStep.action}`);
    return false;
  }

  const { x, y } = currentStep;
  const tileKey = `${x}_${y}`;
  const movementSpeed = group.movementSpeed;
  const now = Date.now();

  // ✅ Diagonal-aware movement timing
  const dx = Math.abs(x - group.tileX);
  const dy = Math.abs(y - group.tileY);
  const distance = Math.sqrt(dx * dx + dy * dy);
  const travelTime = movementSpeed * distance;
  const arrivesAt = admin.firestore.Timestamp.fromMillis(now + travelTime * 1000);

  // 🧹 Prepare movement update
  const newQueue = queue.slice(1);
  const nextStep = newQueue[0] ?? null;

  const update: Record<string, any> = {
    tileX: x,
    tileY: y,
    tileKey,
    movementQueue: newQueue,
    currentStep: nextStep,
    arrivesAt: nextStep ? arrivesAt : null,
  };

  if (!nextStep) {
    update.state = 'idle';
    update.currentMovementTaskName = admin.firestore.FieldValue.delete();
    update.returning = admin.firestore.FieldValue.delete();
  }

  await groupRef.update(update);

  if (nextStep?.action === 'walk') {
    await scheduleHeroGroupArrivalTask({ groupId, delaySeconds: travelTime });
    console.log(`⏭️ Scheduled next step for group ${groupId} with travelTime ${travelTime.toFixed(2)}s`);
  } else {
    console.log(`🛑 No more walk steps, group ${groupId} will be idle soon.`);

    // 💤 Set all group heroes to 'idle'
    const memberIds: string[] = group.members ?? [];
    const heroSnaps = await db.getAll(...memberIds.map(id => db.doc(`heroes/${id}`)));
    const batch = db.batch();
    for (const snap of heroSnaps) {
      if (snap.exists) {
        batch.update(snap.ref, { state: 'idle' });
      }
    }
    await batch.commit();

    console.log(`😌 Group ${groupId} and its heroes are now idle.`);
  }

  return true;
}
