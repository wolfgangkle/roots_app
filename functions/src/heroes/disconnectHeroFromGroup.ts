import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function disconnectHeroFromGroupLogic(request: any) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const { heroId } = request.data;
  if (typeof heroId !== 'string') {
    throw new HttpsError('invalid-argument', 'Invalid or missing heroId.');
  }

  const uid = request.auth.uid;

  try {
    const result = await db.runTransaction(async (tx) => {
      const heroRef = db.collection('heroes').doc(heroId);
      const heroSnap = await tx.get(heroRef);

      if (!heroSnap.exists) {
        throw new HttpsError('not-found', 'Hero not found.');
      }

      const heroData = heroSnap.data()!;
      if (heroData.ownerId !== uid) {
        throw new HttpsError('permission-denied', 'Hero does not belong to the user.');
      }

      if (!heroData.groupId || !heroData.groupLeaderId) {
        throw new HttpsError('failed-precondition', 'Hero is not part of a group.');
      }

      if (heroData.state !== 'idle') {
        throw new HttpsError('failed-precondition', 'Hero must be idle to leave a group.');
      }

      const isRootLeader = heroId === heroData.groupId;
      if (isRootLeader) {
        throw new HttpsError('failed-precondition', 'The group leader cannot leave the group. Use kick instead.');
      }

      const groupRef = db.collection('heroGroups').doc(heroData.groupId);
      const soloGroupRef = db.collection('heroGroups').doc(heroId);

      // ✅ PRE-READ all group data BEFORE any writes
      const groupSnap = await tx.get(groupRef);

      // ✅ Prepare updated group data
      let updatedMembers: string[] = [];
      let updatedConnections: Record<string, any> = {};
      let groupData: any = null;

      if (groupSnap.exists) {
        groupData = groupSnap.data()!;
        updatedMembers = (groupData.members || []).filter((id: string) => id !== heroId);
        updatedConnections = { ...(groupData.connections || {}) };
        delete updatedConnections[heroId];
      }

      // ✅ Write group updates or delete group
      if (updatedMembers.length === 0) {
        tx.delete(groupRef); // Empty group cleanup
      } else {
        tx.update(groupRef, {
          members: updatedMembers,
          connections: updatedConnections,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // ✅ Create solo group with tile + insideVillage + movementSpeed
      tx.set(soloGroupRef, {
        leaderHeroId: heroId,
        members: [heroId],
        connections: {},
        tileX: groupData.tileX,
        tileY: groupData.tileY,
        tileKey: groupData.tileKey,
        movementSpeed: heroData.movementSpeed ?? 1200,
        insideVillage: groupData.insideVillage ?? true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ✅ Update hero
      tx.update(heroRef, {
        groupId: heroId,
        groupLeaderId: null,
      });

      return {
        heroId,
        leftGroupId: heroData.groupId,
        wasRootLeader: false,
        newGroupId: heroId,
      };
    });

    return { success: true, data: result };
  } catch (error) {
    if (error instanceof HttpsError) throw error;

    console.error('❌ Error in disconnectHeroFromGroupLogic:', error);
    throw new HttpsError('unknown', 'An unknown error occurred while disconnecting the hero.');
  }
}
