import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { recalculateGuildAndAlliancePoints } from '../helpers/recalculateGuildAndAlliancePoints.js';

const db = admin.firestore();

export async function acceptGuildInvite(request: any) {
  const userId = request.auth?.uid;
  const { guildId } = request.data;

  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

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

  const guildData = guildSnap.data();
  const heroName = profile?.heroName ?? 'Someone';
  const guildTag = guildData?.tag ?? '';

  const guildChatRef = db.collection('guilds').doc(guildId).collection('chat');

  await db.runTransaction(async (tx) => {
    tx.update(profileRef, {
      guildId,
      guildTag,
      guildRole: 'member',
      allianceId: admin.firestore.FieldValue.delete(),
      allianceTag: admin.firestore.FieldValue.delete(),
    });

    tx.update(inviteRef, {
      status: 'accepted',
      acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(guildChatRef.doc(), {
      sender: 'System',
      content: `🎉 ${heroName} has joined the guild!`,
      type: 'system',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  console.log(`✅ ${userId} (${heroName}) accepted invite to guild ${guildId}`);

  // 🧮 Trigger recalculation of guild and alliance points
  await recalculateGuildAndAlliancePoints();

  return {
    guildId,
    message: 'You have successfully joined the guild.',
  };
}
