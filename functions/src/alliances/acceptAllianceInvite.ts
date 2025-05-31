import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { recalculateGuildAndAlliancePoints } from '../helpers/recalculateGuildAndAlliancePoints.js';

const db = admin.firestore();

export async function acceptAllianceInvite(request: any) {
  const userId = request.auth?.uid;
  const { allianceId } = request.data;

  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  if (!allianceId || typeof allianceId !== 'string') {
    throw new HttpsError('invalid-argument', 'allianceId must be provided.');
  }

  const profileRef = db.doc(`users/${userId}/profile/main`);
  const profileSnap = await profileRef.get();
  const profile = profileSnap.data();

  if (!profile?.guildId || profile.guildRole !== 'leader') {
    throw new HttpsError('permission-denied', 'Only guild leaders can accept alliance invites.');
  }

  const guildId = profile.guildId;
  const guildRef = db.doc(`guilds/${guildId}`);
  const inviteRef = db.doc(`guilds/${guildId}/allianceInvites/${allianceId}`);
  const allianceRef = db.doc(`alliances/${allianceId}`);

  const [inviteSnap, guildSnap, allianceSnap] = await Promise.all([
    inviteRef.get(),
    guildRef.get(),
    allianceRef.get(),
  ]);

  if (!inviteSnap.exists) {
    throw new HttpsError('not-found', 'No alliance invite found.');
  }

  const guild = guildSnap.data();
  if (guild?.allianceId) {
    throw new HttpsError('already-exists', 'This guild is already in an alliance.');
  }

  if (!allianceSnap.exists) {
    throw new HttpsError('not-found', 'Alliance does not exist.');
  }

  const allianceData = allianceSnap.data();
  const allianceTag = allianceData?.tag ?? '';
  const systemMessage = `📜 Guild ${guild?.tag ?? guildId} has joined the alliance [${allianceTag}]`;

  const allianceLogRef = db.collection('alliances').doc(allianceId).collection('log');

  await db.runTransaction(async (tx) => {
    tx.update(guildRef, {
      allianceId,
      allianceRole: 'member',
    });

    tx.update(allianceRef, {
      guildIds: admin.firestore.FieldValue.arrayUnion(guildId),
    });

    tx.update(profileRef, {
      allianceId,
      allianceTag,
    });

    tx.delete(inviteRef);

    tx.set(allianceLogRef.doc(), {
      type: 'system',
      content: systemMessage,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  // 🧮 Trigger a fresh point tally for leaderboard goodness
  await recalculateGuildAndAlliancePoints();

  console.log(`✅ Guild ${guildId} accepted alliance invite to ${allianceId}`);

  return {
    allianceId,
    message: 'Your guild has successfully joined the alliance.',
  };
}
