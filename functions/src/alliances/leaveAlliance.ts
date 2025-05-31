import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { recalculateGuildAndAlliancePoints } from '../helpers/recalculateGuildAndAlliancePoints.js';

const db = admin.firestore();

export async function leaveAlliance(request: any) {
  const userId = request.auth?.uid;

  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  const profileRef = db.doc(`users/${userId}/profile/main`);
  const profileSnap = await profileRef.get();
  const profile = profileSnap.data();

  if (!profile?.guildId || profile.guildRole !== 'leader') {
    throw new HttpsError('permission-denied', 'Only guild leaders can leave an alliance.');
  }

  const guildRef = db.doc(`guilds/${profile.guildId}`);
  const guildSnap = await guildRef.get();
  const guild = guildSnap.data();

  if (!guild?.allianceId) {
    throw new HttpsError('failed-precondition', 'This guild is not part of an alliance.');
  }

  if (guild.allianceRole === 'leader') {
    throw new HttpsError('failed-precondition', 'Alliance leaders must disband the alliance instead.');
  }

  const allianceRef = db.doc(`alliances/${guild.allianceId}`);
  const allianceLogRef = allianceRef.collection('log');

  const systemMessage = `👋 Guild ${guild.tag ?? guildRef.id} has left the alliance.`;

  const affectedProfiles = await db
    .collectionGroup('profile')
    .where('guildId', '==', guildRef.id)
    .get();

  await db.runTransaction(async (tx) => {
    // Remove alliance from guild doc
    tx.update(guildRef, {
      allianceId: admin.firestore.FieldValue.delete(),
      allianceRole: admin.firestore.FieldValue.delete(),
    });

    // Remove guild from alliance array
    tx.update(allianceRef, {
      guildIds: admin.firestore.FieldValue.arrayRemove(guildRef.id),
    });

    // Add alliance log
    tx.set(allianceLogRef.doc(), {
      type: 'system',
      content: systemMessage,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Remove alliance info from all members
    for (const doc of affectedProfiles.docs) {
      tx.update(doc.ref, {
        allianceId: admin.firestore.FieldValue.delete(),
        allianceTag: admin.firestore.FieldValue.delete(),
      });
    }
  });

  // 🧠 Leaderboard update
  await recalculateGuildAndAlliancePoints();

  console.log(`🏳️ Guild ${guildRef.id} has left alliance ${guild.allianceId}`);

  return {
    status: 'left',
    message: 'Your guild has left the alliance.',
  };
}
