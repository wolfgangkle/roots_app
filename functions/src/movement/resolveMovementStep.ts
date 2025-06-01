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
  const arrivesAt = admin.firestore.Timestamp.fromMillis(now + movementSpeed * 1000);

  // Remove the current step from queue
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

  await groupRef.update(update);

  // Schedule next arrival if needed
  if (nextStep?.action === 'walk') {
    await scheduleHeroGroupArrivalTask({ groupId, delaySeconds: movementSpeed });
    console.log(`⏭️ Scheduled next step for group ${groupId}`);
  } else {
    console.log(`🛑 No more walk steps, group ${groupId} will be idle soon.`);
  }

  return true;
}
