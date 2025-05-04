import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function leaveGuild(request: any) {
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

  if (!profile?.guildId || !profile?.guildRole) {
    throw new HttpsError('failed-precondition', 'You are not in a guild.');
  }

  if (profile.guildRole === 'leader') {
    throw new HttpsError('failed-precondition', 'Guild leaders cannot leave the guild.');
  }

  const guildId = profile.guildId;
  const heroName = profile.heroName ?? 'Someone';
  const guildChatRef = db.collection('guilds').doc(guildId).collection('chat');

  await db.runTransaction(async (tx) => {
    tx.update(profileRef, {
      guildId: admin.firestore.FieldValue.delete(),
      guildRole: admin.firestore.FieldValue.delete(),
    });

    const invitesQuery = await db.collection('guildInvites')
      .where('fromUserId', '==', userId)
      .get();

    for (const doc of invitesQuery.docs) {
      tx.delete(doc.ref);
    }

    tx.set(guildChatRef.doc(), {
      sender: 'System',
      content: `🚪 ${heroName} has left the guild.`,
      type: 'system',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  console.log(`🚪 ${userId} (${heroName}) has left guild ${guildId}`);

  return {
    status: 'left',
    message: 'You have left the guild.',
  };
}
