import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function disbandAlliance(request: any) {
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
    throw new HttpsError('permission-denied', 'Only guild leaders can disband an alliance.');
  }

  const guildRef = db.doc(`guilds/${guildId}`);
  const guildSnap = await guildRef.get();
  const guild = guildSnap.data();

  const allianceId = guild?.allianceId;
  const allianceRole = guild?.allianceRole;

  if (!allianceId || allianceRole !== 'leader') {
    throw new HttpsError('failed-precondition', 'Only the alliance leader can disband the alliance.');
  }

  const allianceRef = db.doc(`alliances/${allianceId}`);

  const allGuildsQuery = await db
    .collection('guilds')
    .where('allianceId', '==', allianceId)
    .get();

  const allProfilesQuery = await db
    .collectionGroup('profile')
    .where('allianceId', '==', allianceId)
    .get();

  await db.runTransaction(async (tx) => {
    for (const guildDoc of allGuildsQuery.docs) {
      tx.update(guildDoc.ref, {
        allianceId: admin.firestore.FieldValue.delete(),
        allianceRole: admin.firestore.FieldValue.delete(),
      });
    }

    for (const profileDoc of allProfilesQuery.docs) {
      tx.update(profileDoc.ref, {
        allianceId: admin.firestore.FieldValue.delete(),
        allianceTag: admin.firestore.FieldValue.delete(),
      });
    }

    tx.delete(allianceRef);
  });

  // Delete logs outside transaction (not supported inside)
  const logDocs = await db.collection(`alliances/${allianceId}/log`).listDocuments();
  for (const doc of logDocs) {
    await doc.delete();
  }

  console.log(`💥 Alliance ${allianceId} disbanded by guild ${guildId} — log cleared.`);

  return {
    status: 'disbanded',
    allianceId,
    message: 'The alliance and its logs have been deleted.',
  };
}
