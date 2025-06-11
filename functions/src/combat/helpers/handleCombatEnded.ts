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
    currentStep: admin.firestore.FieldValue.delete(),
    arrivesAt: admin.firestore.FieldValue.delete(),
    currentMovementTaskName: admin.firestore.FieldValue.delete(),
  };

  // Set correct group state
  if (movementQueue.length > 0) {
    groupUpdate.state = 'arrived'; // cleanup done, but movement may resume
    await maybeContinueGroupMovement(groupId);
  } else {
    groupUpdate.state = aliveHeroIds.length === 0 ? 'dead' : 'idle';
  }

  batch.update(groupRef, groupUpdate);

  await batch.commit();
  console.log(`✅ Post-combat cleanup completed for group ${groupId}`);
}
