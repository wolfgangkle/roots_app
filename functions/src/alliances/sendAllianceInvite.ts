import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function sendAllianceInvite(request: any) {
  const userId = request.auth?.uid;
  const { targetGuildId } = request.data;

  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  if (!targetGuildId || typeof targetGuildId !== 'string') {
    throw new HttpsError('invalid-argument', 'targetGuildId must be provided.');
  }

  const profileRef = db.doc(`users/${userId}/profile/main`);
  const profileSnap = await profileRef.get();
  const profile = profileSnap.data();

  if (!profile?.guildId || profile.guildRole !== 'leader') {
    throw new HttpsError('permission-denied', 'Only guild leaders can send alliance invites.');
  }

  const senderGuildRef = db.doc(`guilds/${profile.guildId}`);
  const senderGuildSnap = await senderGuildRef.get();
  const senderGuild = senderGuildSnap.data();

  const allianceId = senderGuild?.allianceId;
  if (!allianceId || senderGuild?.allianceRole !== 'leader') {
    throw new HttpsError('permission-denied', 'Only alliance leaders can invite other guilds.');
  }

  const targetGuildRef = db.doc(`guilds/${targetGuildId}`);
  const targetGuildSnap = await targetGuildRef.get();

  if (!targetGuildSnap.exists) {
    throw new HttpsError('not-found', 'Target guild does not exist.');
  }

  const targetGuild = targetGuildSnap.data();
  if (targetGuild?.allianceId) {
    throw new HttpsError('failed-precondition', 'Target guild is already in an alliance.');
  }

  const inviteRef = db.doc(`guilds/${targetGuildId}/allianceInvites/${allianceId}`);
  const existingInviteSnap = await inviteRef.get();
  if (existingInviteSnap.exists) {
    throw new HttpsError('already-exists', 'An invite from this alliance already exists.');
  }

  await inviteRef.set({
    allianceId,
    invitedByGuildId: senderGuildRef.id,
    invitedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`📨 Sent alliance invite from ${senderGuildRef.id} to ${targetGuildId}`);

  return { success: true };
}
