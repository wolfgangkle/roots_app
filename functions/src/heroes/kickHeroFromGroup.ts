import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function kickHeroFromGroupLogic(request: any) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const { heroId, targetHeroId } = request.data;

  if (typeof heroId !== 'string' || typeof targetHeroId !== 'string') {
    throw new HttpsError('invalid-argument', 'Both heroId and targetHeroId must be strings.');
  }

  const uid = request.auth.uid;

  try {
    const result = await db.runTransaction(async (tx) => {
      const heroRef = db.collection('heroes').doc(heroId);
      const targetRef = db.collection('heroes').doc(targetHeroId);
      const groupRef = db.collection('heroGroups').doc(heroId);
      const soloGroupRef = db.collection('heroGroups').doc(targetHeroId);

      // ✅ Read everything first
      const [heroSnap, targetSnap, groupSnap] = await Promise.all([
        tx.get(heroRef),
        tx.get(targetRef),
        tx.get(groupRef),
      ]);

      if (!heroSnap.exists || !targetSnap.exists) {
        throw new HttpsError('not-found', 'One or both heroes not found.');
      }

      const heroData = heroSnap.data()!;
      const targetData = targetSnap.data()!;

      if (heroData.ownerId !== uid) {
        throw new HttpsError('permission-denied', 'You do not own the hero issuing the kick.');
      }

      const isRootLeader = heroData.groupId === heroId;
      if (!isRootLeader) {
        throw new HttpsError('permission-denied', 'Only the group leader can kick heroes.');
      }

      if (targetData.groupId !== heroData.groupId) {
        throw new HttpsError('failed-precondition', 'Target hero is not in the same group.');
      }

      if (targetData.state !== 'idle') {
        throw new HttpsError('failed-precondition', 'Target hero must be idle to be kicked.');
      }

      if (!groupSnap.exists) {
        throw new HttpsError('not-found', 'Group metadata not found.');
      }

      const groupData = groupSnap.data()!;
      const updatedMembers = (groupData.members || []).filter((id: string) => id !== targetHeroId);
      const updatedConnections = { ...(groupData.connections || {}) };
      delete updatedConnections[targetHeroId];

      // ✅ Write all updates AFTER reads
      if (updatedMembers.length === 0) {
        tx.delete(groupRef);
      } else {
        // Fetch movementSpeed of remaining members
        const remainingRefs = updatedMembers.map((id: string) => db.collection('heroes').doc(id));
        const remainingSnaps = await Promise.all(
          remainingRefs.map((ref: FirebaseFirestore.DocumentReference) => tx.get(ref))
        );


        const slowestSpeed = Math.max(
          ...remainingSnaps.map(snap => snap.data()?.movementSpeed ?? 999999)
        );

        tx.update(groupRef, {
          members: updatedMembers,
          connections: updatedConnections,
          movementSpeed: slowestSpeed, // ✅ Recalculate new slowest
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }


      // ✅ Create solo group with inherited position + insideVillage + own movementSpeed
      tx.set(soloGroupRef, {
        leaderHeroId: targetHeroId,
        members: [targetHeroId],
        connections: {},
        tileX: groupData.tileX,
        tileY: groupData.tileY,
        tileKey: groupData.tileKey,
        insideVillage: groupData.insideVillage ?? true,
        movementSpeed: targetData.movementSpeed ?? 1200,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.update(targetRef, {
        groupId: targetHeroId,
        groupLeaderId: null,
      });

      return {
        kickedHeroId: targetHeroId,
        fromGroupId: heroData.groupId,
        newGroupId: targetHeroId,
      };
    });

    return { success: true, data: result };
  } catch (error) {
    if (error instanceof HttpsError) throw error;

    console.error('❌ Error in kickHeroFromGroupLogic:', error);
    throw new HttpsError('unknown', 'An unknown error occurred while kicking the hero.');
  }
}
