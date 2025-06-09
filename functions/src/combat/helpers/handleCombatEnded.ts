import * as admin from 'firebase-admin';
import { maybeContinueGroupMovement } from '../../movement/maybeContinueGroupMovement.js';

const db = admin.firestore();

/**
 * Handles movement and cleanup after a PvE or PvP combat ends.
 */
export async function handleCombatEnded(combat: any): Promise<void> {
  const groupId = combat.groupId;
  if (!groupId) {
    console.warn(`⚠️ Combat ${combat.id} has no groupId. Skipping cleanup.`);
    return;
  }

  const groupRef = db.collection('heroGroups').doc(groupId);
  const groupSnap = await groupRef.get();
  if (!groupSnap.exists) {
    console.warn(`❌ Group ${groupId} not found for post-combat cleanup.`);
    return;
  }

  const group = groupSnap.data()!;
  const movementQueue: any[] = group.movementQueue ?? [];

  const groupUpdates: Record<string, any> = {
    state: 'arrived',
    activeCombatId: admin.firestore.FieldValue.delete(),
  };

  await groupRef.update(groupUpdates);

  console.log(`🧹 Cleared combat state for group ${groupId}.`);

  if (movementQueue.length > 0) {
    console.log(`🏃 Resuming movement for group ${groupId}...`);
    await maybeContinueGroupMovement(groupId);
  } else {
    console.log(`💤 Group ${groupId} has no more steps. Setting group and heroes to idle.`);

    await groupRef.update({
      state: 'idle',
      currentStep: admin.firestore.FieldValue.delete(),
      arrivesAt: admin.firestore.FieldValue.delete(),
      currentMovementTaskName: admin.firestore.FieldValue.delete(),
    });

    const heroIds: string[] = group.members ?? [];
    const heroSnaps = await db.getAll(...heroIds.map(id => db.doc(`heroes/${id}`)));
    const batch = db.batch();

    for (const snap of heroSnaps) {
      if (snap.exists) {
        batch.update(snap.ref, { state: 'idle' });
      }
    }

    await batch.commit();
  }
}
