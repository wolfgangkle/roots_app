import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function acceptGuildInvite(request: any) {
  const userId = request.auth?.uid;
  const { guildId } = request.data;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!guildId || typeof guildId !== 'string') {
    throw new HttpsError('invalid-argument', 'guildId must be provided.');
  }

  const inviteRef = db.doc(`guildInvites/${userId}_${guildId}`);
  const profileRef = db.doc(`users/${userId}/profile/main`);
  const guildRef = db.doc(`guilds/${guildId}`);

  const [inviteSnap, profileSnap, guildSnap] = await Promise.all([
    inviteRef.get(),
    profileRef.get(),
    guildRef.get(),
  ]);

  if (!inviteSnap.exists) {
    throw new HttpsError('not-found', 'No invite found.');
  }

  const invite = inviteSnap.data();
  if (!invite || invite.status !== 'pending') {
    throw new HttpsError('failed-precondition', 'Invite has already been accepted or declined.');
  }


  const profile = profileSnap.data();
  if (profile?.guildId) {
    throw new HttpsError('already-exists', 'You are already in a guild.');
  }

  if (!guildSnap.exists) {
    throw new HttpsError('not-found', 'Target guild does not exist.');
  }

  await db.runTransaction(async (tx) => {
    tx.update(profileRef, {
      guildId,
      guildRole: 'member',
    });

    tx.update(inviteRef, {
      status: 'accepted',
      acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  console.log(`✅ ${userId} accepted invite to guild ${guildId}`);

  return {
    guildId,
    message: 'You have successfully joined the guild.',
  };
}
