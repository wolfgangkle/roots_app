import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function connectHeroToGroupLogic(request: any) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const { heroId, targetHeroId } = request.data;
  if (typeof heroId !== 'string' || typeof targetHeroId !== 'string') {
    throw new HttpsError('invalid-argument', 'Both heroId and targetHeroId must be strings.');
  }

  const uid = request.auth.uid;

  try {
    const result = await db.runTransaction(async (transaction) => {
      const heroRef = db.collection('heroes').doc(heroId);
      const targetRef = db.collection('heroes').doc(targetHeroId);
      const oldGroupRef = db.collection('heroGroups').doc(heroId);
      const groupRef = db.collection('heroGroups').doc(targetHeroId);

      // ✅ Read all required docs
      const [heroSnap, targetSnap, oldGroupSnap, groupSnap] = await Promise.all([
        transaction.get(heroRef),
        transaction.get(targetRef),
        transaction.get(oldGroupRef),
        transaction.get(groupRef),
      ]);

      if (!heroSnap.exists || !targetSnap.exists) {
        throw new HttpsError('not-found', 'One or both heroes were not found.');
      }

      const heroData = heroSnap.data()!;
      const targetData = targetSnap.data()!;

      if (heroData.ownerId !== uid) {
        throw new HttpsError('permission-denied', 'You do not own this hero.');
      }

      if (heroData.state !== 'idle' || targetData.state !== 'idle') {
        throw new HttpsError('failed-precondition', 'Both heroes must be idle.');
      }

      if (heroData.tileX !== targetData.tileX || heroData.tileY !== targetData.tileY) {
        throw new HttpsError('failed-precondition', 'Heroes must be on the same tile.');
      }

      // ✅ Group leader check
      if (targetData.groupLeaderId && targetData.groupLeaderId !== targetHeroId) {
        throw new HttpsError('failed-precondition', 'Target hero is not a group leader.');
      }

      // ✅ Loop protection
      let ancestorId = targetData.groupLeaderId;
      const visited = new Set<string>();
      while (ancestorId) {
        if (ancestorId === heroId) {
          throw new HttpsError(
            'failed-precondition',
            'Loop connection detected. Cannot connect to a hero within your own group.'
          );
        }

        if (visited.has(ancestorId)) break;
        visited.add(ancestorId);

        const ancestorSnap = await transaction.get(db.collection('heroes').doc(ancestorId));
        if (!ancestorSnap.exists) break;

        ancestorId = ancestorSnap.data()?.groupLeaderId;
      }

      // ✅ Update connecting hero
      transaction.update(heroRef, {
        groupLeaderId: targetHeroId,
        groupId: targetHeroId,
      });

      // ✅ Merge group metadata
      const existingGroupData = groupSnap.exists ? groupSnap.data() : null;
      const newConnections = existingGroupData?.connections || {};
      newConnections[heroId] = targetHeroId;

      const newMembers = admin.firestore.FieldValue.arrayUnion(heroId, targetHeroId);

      // ✅ Calculate slowest movementSpeed
      const heroSpeed = heroData.movementSpeed ?? 1200;
      const groupSpeed = existingGroupData?.movementSpeed ?? 1200;
      const updatedSpeed = Math.min(heroSpeed, groupSpeed);

      const insideVillage = existingGroupData?.insideVillage ?? false;

      transaction.set(groupRef, {
        members: newMembers,
        connections: newConnections,
        leaderHeroId: targetHeroId,
        movementSpeed: updatedSpeed,
        insideVillage,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      // ✅ Delete old solo group if it's empty
      if (oldGroupSnap.exists) {
        const oldData = oldGroupSnap.data();
        const oldMembers = oldData?.members || [];
        if (oldMembers.length <= 1) {
          transaction.delete(oldGroupRef);
        }
      }

      return {
        heroId,
        connectedTo: targetHeroId,
      };
    });

    return { success: true, data: result };
  } catch (error) {
    if (error instanceof HttpsError) throw error;

    console.error('Error in connectHeroToGroupLogic:', error);
    throw new HttpsError('unknown', 'An unknown error occurred while connecting heroes.');
  }
}
