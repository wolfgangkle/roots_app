import * as admin from 'firebase-admin';
import { scheduleCombatTick } from '../combat/scheduleCombatTick.js';
import { maybeContinueGroupMovement } from './maybeContinueGroupMovement.js';

const db = admin.firestore();

export async function handleTriggeredPveEvent(
  result: {
    type: 'combat' | 'peaceful';
    eventId: string;
    combatId?: string;
    peacefulReportId?: string;
  },
  group: any
): Promise<void> {
  const groupRef = db.collection('heroGroups').doc(group.groupId);
  const updates: Record<string, any> = {};

  // 🛑 Pause movement
  updates.state = result.type === 'combat' ? 'in_combat' : 'arrived';
  updates.arrivesAt = admin.firestore.FieldValue.delete();
  updates.currentMovementTaskName = admin.firestore.FieldValue.delete();

  if (result.type === 'combat') {
    updates.activeCombatId = result.combatId;

    console.log(`⚔️ Group ${group.groupId} entered combat: ${result.combatId}`);

    // 💥 Update individual heroes to in_combat
    const heroIds: string[] = group.members ?? [];
    const heroSnaps = await db.getAll(...heroIds.map(id => db.doc(`heroes/${id}`)));
    const batch = db.batch();

    for (const snap of heroSnaps) {
      if (snap.exists) {
        batch.update(snap.ref, {
          state: 'in_combat',
          activeCombatId: result.combatId,
        });
      }
    }

    await batch.commit();

    // 🕒 Schedule first combat tick
    await scheduleCombatTick({
      combatId: result.combatId!,
      delaySeconds: 3, // ⏱️ adjust for production (e.g. 10)
    });
  }

  if (result.type === 'peaceful') {
    console.log(`📜 Group ${group.groupId} completed a peaceful event: ${result.eventId}`);
  }

  // 📝 Save group state
  await groupRef.update(updates);

  if (result.type === 'peaceful') {
    await maybeContinueGroupMovement(group.groupId);
  }

  console.log(`✅ PvE event '${result.eventId}' handled for group ${group.groupId}`);
}
