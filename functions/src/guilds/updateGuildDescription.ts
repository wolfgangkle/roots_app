import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function updateGuildDescription(request: any) {
  const userId = request.auth?.uid;
  const { guildId, description } = request.data;

  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  if (!guildId || typeof guildId !== 'string') {
    throw new HttpsError('invalid-argument', 'Missing or invalid guildId.');
  }

  if (typeof description !== 'string' || description.length > 500) {
    throw new HttpsError('invalid-argument', 'Description must be a string with max 500 characters.');
  }

  const profileRef = db.doc(`users/${userId}/profile/main`);
  const guildRef = db.doc(`guilds/${guildId}`);

  const [profileSnap, guildSnap] = await Promise.all([
    profileRef.get(),
    guildRef.get(),
  ]);

  if (!profileSnap.exists || !guildSnap.exists) {
    throw new HttpsError('not-found', 'Profile or guild not found.');
  }

  const profile = profileSnap.data();

  if (profile?.guildId !== guildId || profile?.guildRole !== 'leader') {
    throw new HttpsError('permission-denied', 'Only the guild leader can update the description.');
  }

  await guildRef.update({
    description: description.trim(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`📝 Guild ${guildId} description updated by ${userId}`);

  return {
    guildId,
    status: 'updated',
    message: 'Description updated.',
  };
}
