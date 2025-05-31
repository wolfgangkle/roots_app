import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function disbandGuild(request: any) {
  const userId = request.auth?.uid;

  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  const profileRef = db.doc(`users/${userId}/profile/main`);
  const profileSnap = await profileRef.get();

  if (!profileSnap.exists) {
    throw new HttpsError('not-found', 'User profile not found.');
  }

  const profile = profileSnap.data();

  const guildId = profile?.guildId;
  const guildRole = profile?.guildRole;

  if (!guildId || guildRole !== 'leader') {
    throw new HttpsError('permission-denied', 'Only the guild leader can disband the guild.');
  }

  const guildRef = db.doc(`guilds/${guildId}`);

  const memberQuery = await db
    .collectionGroup('profile')
    .where('guildId', '==', guildId)
    .get();

  const inviteQuery = await db
    .collection('guildInvites')
    .where('guildId', '==', guildId)
    .get();

  await db.runTransaction(async (tx) => {
    // Remove guild and alliance data from all member profiles
    for (const memberDoc of memberQuery.docs) {
      tx.update(memberDoc.ref, {
        guildId: admin.firestore.FieldValue.delete(),
        guildTag: admin.firestore.FieldValue.delete(),
        guildRole: admin.firestore.FieldValue.delete(),
        allianceId: admin.firestore.FieldValue.delete(),
        allianceTag: admin.firestore.FieldValue.delete(),
      });
    }

    // Delete all invites
    for (const inviteDoc of inviteQuery.docs) {
      tx.delete(inviteDoc.ref);
    }

    // Delete the guild document itself
    tx.delete(guildRef);
  });

  console.log(`💥 Guild ${guildId} was disbanded by ${userId}`);

  return {
    status: 'disbanded',
    guildId,
    message: 'The guild has been disbanded.',
  };
}
