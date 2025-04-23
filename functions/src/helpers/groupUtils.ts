import * as admin from 'firebase-admin';

/**
 * Recalculates the group movementSpeed as the slowest of its members.
 */
export async function updateGroupMovementSpeed(groupId: string): Promise<void> {
  const db = admin.firestore(); // ✅ safely initialized inside the function

  const groupRef = db.collection('heroGroups').doc(groupId);
  const groupSnap = await groupRef.get();
  if (!groupSnap.exists) return;

  const groupData = groupSnap.data();
  const memberIds: string[] = groupData?.members || [];

  if (!memberIds.length) return;

  const memberRefs = memberIds.map(id => db.collection('heroes').doc(id));
  const memberSnaps = await db.getAll(...memberRefs);

  const speeds = memberSnaps
    .filter(snap => snap.exists)
    .map(snap => snap.data()?.movementSpeed ?? 999999);

  const slowest = Math.max(...speeds); // slowest hero defines group speed

  await groupRef.update({
    movementSpeed: slowest,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
