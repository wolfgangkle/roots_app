import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function sendGuildInvite(request: any) {
  const fromUserId = request.auth?.uid;
  const { toUserId } = request.data;

  if (!fromUserId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  if (!toUserId || typeof toUserId !== 'string') {
    throw new HttpsError('invalid-argument', 'Missing or invalid toUserId.');
  }

  if (fromUserId === toUserId) {
    throw new HttpsError('invalid-argument', 'You cannot invite yourself.');
  }

  const fromProfileRef = db.doc(`users/${fromUserId}/profile/main`);
  const toProfileRef = db.doc(`users/${toUserId}/profile/main`);

  const [fromSnap, toSnap] = await Promise.all([
    fromProfileRef.get(),
    toProfileRef.get(),
  ]);

  if (!fromSnap.exists || !toSnap.exists) {
    throw new HttpsError('not-found', 'User profile(s) not found.');
  }

  const from = fromSnap.data();
  const to = toSnap.data();

  if (!from?.guildId || !from?.guildRole) {
    throw new HttpsError('failed-precondition', 'You must be in a guild to invite someone.');
  }

  if (from.guildRole !== 'leader' && from.guildRole !== 'officer') {
    throw new HttpsError('permission-denied', 'Only leaders or officers can send invites.');
  }

  if (to?.guildId) {
    throw new HttpsError('failed-precondition', 'Target user is already in a guild.');
  }

  const inviteId = `${toUserId}_${from.guildId}`;
  const inviteRef = db.doc(`guildInvites/${inviteId}`);
  const existingInvite = await inviteRef.get();

  if (existingInvite.exists && existingInvite.data()?.status === 'pending') {
    throw new HttpsError('already-exists', 'This user already has a pending invite to your guild.');
  }

  await inviteRef.set({
    fromUserId,
    toUserId,
    guildId: from.guildId,
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`📨 ${fromUserId} invited ${toUserId} to guild ${from.guildId}`);

  return {
    toUserId,
    guildId: from.guildId,
    status: 'pending',
  };
}
