import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Applies the current movement step: updates position, pops step, prepares next.
 * Returns movement info or null if group has no valid movement step.
 */
export async function applyMovementStep(groupId: string): Promise<{
  groupId: string;
  tileX: number;
  tileY: number;
  tileKey: string;
  newQueue: any[];
  nextStep: any | null;
  travelTime: number;
} | null> {
  const groupRef = db.collection('heroGroups').doc(groupId);
  const snap = await groupRef.get();

  if (!snap.exists) {
    console.warn(`⚠️ applyMovementStep: group ${groupId} not found.`);
    return null;
  }

  const group = snap.data()!;
  const queue: any[] = group.movementQueue ?? [];
  const currentStep = queue[0];

  if (!currentStep || currentStep.action !== 'walk') {
    console.warn(`⚠️ No valid movement step for group ${groupId}.`);
    return null;
  }

  const { x, y } = currentStep;
  const tileKey = `${x}_${y}`;
  const movementSpeed = group.movementSpeed;
  const dx = Math.abs(x - group.tileX);
  const dy = Math.abs(y - group.tileY);
  const distance = Math.sqrt(dx * dx + dy * dy);
  const travelTime = movementSpeed * distance;

  const newQueue = queue.slice(1);
  const nextStep = newQueue[0] ?? null;

  const update: Record<string, any> = {
    tileX: x,
    tileY: y,
    tileKey,
    movementQueue: newQueue,
    currentStep: nextStep,
    arrivesAt: null, // always cleared after arrival
    state: 'arrived',
  };

  if (!nextStep) {
    update.currentMovementTaskName = admin.firestore.FieldValue.delete();
    update.returning = admin.firestore.FieldValue.delete();
  }

  await groupRef.update(update);

  console.log(`📦 applyMovementStep: Group ${groupId} arrived at (${x},${y}), next step: ${!!nextStep}`);
  return {
    groupId,
    tileX: x,
    tileY: y,
    tileKey,
    newQueue,
    nextStep,
    travelTime,
  };
}
