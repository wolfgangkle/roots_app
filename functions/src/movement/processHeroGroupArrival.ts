import * as admin from 'firebase-admin';
import { resolveMovementStep } from './resolveMovementStep.js';

const db = admin.firestore();

export async function processHeroGroupArrival(groupId: string) {
  console.log(`📦 processHeroGroupArrival(${groupId}) started`);

  const groupRef = db.collection('heroGroups').doc(groupId);
  const groupSnap = await groupRef.get();
  if (!groupSnap.exists) {
    console.warn(`⚠️ Group ${groupId} not found.`);
    return;
  }

  const group = groupSnap.data()!;
  if (group.returning) {
    console.log(`🏠 Group ${groupId} is returning. Skipping event checks.`);
    await groupRef.update({
      returning: admin.firestore.FieldValue.delete(),
    });

    const moved = await resolveMovementStep(groupId);
    if (!moved) {
      console.warn(`⚠️ Movement failed while returning for group ${groupId}`);
    } else {
      console.log(`😌 Group ${groupId} returned without triggering events.`);
    }
    return;
  }

  const moved = await resolveMovementStep(groupId);
  if (!moved) {
    console.warn(`⚠️ Movement failed or no step to resolve for group ${groupId}`);
    return;
  }

  // 🔜 Future logic goes here:
  // - PvP collision
  // - Tile event roll
  // - Shrine / loot / peaceful
  // - Merging with other groups, etc.

  console.log(`✅ Movement step resolved for group ${groupId}`);
}
