import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function updateAllianceDescription(request: any) {
  const userId = request.auth?.uid;
  const { allianceId, description } = request.data;

  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  if (!allianceId || typeof allianceId !== 'string') {
    throw new HttpsError('invalid-argument', 'Missing or invalid allianceId.');
  }

  if (typeof description !== 'string' || description.length > 500) {
    throw new HttpsError('invalid-argument', 'Description must be a string with max 500 characters.');
  }

  const profileRef = db.doc(`users/${userId}/profile/main`);
  const profileSnap = await profileRef.get();
  const profile = profileSnap.data();

  if (!profile?.guildId || profile.guildRole !== 'leader') {
    throw new HttpsError('permission-denied', 'Only guild leaders can update alliance descriptions.');
  }

  const guildRef = db.doc(`guilds/${profile.guildId}`);
  const guildSnap = await guildRef.get();
  const guild = guildSnap.data();

  if (!guild?.allianceId || guild.allianceId !== allianceId || guild.allianceRole !== 'leader') {
    throw new HttpsError('permission-denied', 'Only the alliance leader can update the description.');
  }

  const allianceRef = db.doc(`alliances/${allianceId}`);

  await allianceRef.update({
    description: description.trim(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`📝 Alliance ${allianceId} description updated by guild ${profile.guildId}`);

  return {
    allianceId,
    status: 'updated',
    message: 'Alliance description updated.',
  };
}
