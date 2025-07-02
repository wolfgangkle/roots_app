import * as admin from 'firebase-admin';
import { maybeContinueGroupMovement } from '../../movement/maybeContinueGroupMovement.js';

const db = admin.firestore();

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
  const heroIds: string[] = group.members ?? [];

  const combatHeroes: any[] = combat.heroes ?? [];

  const heroSnaps = await db.getAll(...heroIds.map(id => db.doc(`heroes/${id}`)));
  const batch = db.batch();

  let aliveHeroIds: string[] = [];

  for (const snap of heroSnaps) {
    if (!snap.exists) continue;
    const heroId = snap.id;

    const heroRef = snap.ref;
    const combatHero = combatHeroes.find(h => h.id === heroId);
    const isDead = combatHero?.hp <= 0;

    if (isDead) {
      batch.update(heroRef, {
        state: 'dead',
        groupId: admin.firestore.FieldValue.delete(),
      });

      console.log(`☠️ Hero ${heroId} has died and will be removed from group ${groupId}`);
    } else {
      // Hero survived
      batch.update(heroRef, {
        state: 'idle',
      });
      aliveHeroIds.push(heroId);
    }
  }

  // Update the group with remaining members
  const groupUpdate: Record<string, any> = {
    activeCombatId: admin.firestore.FieldValue.delete(),
    members: aliveHeroIds,
    arrivesAt: admin.firestore.FieldValue.delete(),
    currentMovementTaskName: admin.firestore.FieldValue.delete(),
  };

  // Determine new group state
  if (aliveHeroIds.length === 0) {
    groupUpdate.state = 'dead';
    groupUpdate.currentStep = admin.firestore.FieldValue.delete();
    groupUpdate.movementQueue = [];
  } else if (movementQueue.length === 0) {
    groupUpdate.state = 'idle';
    groupUpdate.currentStep = admin.firestore.FieldValue.delete();
  } else {
    // There are remaining waypoints, resume after cleanup
    groupUpdate.state = 'arrived';
  }

  batch.update(groupRef, groupUpdate);

  await batch.commit();
  console.log(`✅ Post-combat cleanup completed for group ${groupId}`);

  // Resume movement if waypoints remain and heroes survived
  if (aliveHeroIds.length > 0 && movementQueue.length > 0) {
    await maybeContinueGroupMovement(groupId);
  }
}
