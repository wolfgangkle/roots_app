import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { recalculateGuildAndAlliancePoints } from '../helpers/recalculateGuildAndAlliancePoints.js';

const db = admin.firestore();

export async function kickGuildFromAlliance(request: any) {
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
    throw new HttpsError('permission-denied', 'Only guild leaders can kick other guilds from the alliance.');
  }

  const leaderGuildRef = db.doc(`guilds/${profile.guildId}`);
  const targetGuildRef = db.doc(`guilds/${targetGuildId}`);

  const [leaderGuildSnap, targetGuildSnap] = await Promise.all([
    leaderGuildRef.get(),
    targetGuildRef.get(),
  ]);

  const leaderGuild = leaderGuildSnap.data();
  const targetGuild = targetGuildSnap.data();

  const allianceId = leaderGuild?.allianceId;

  if (!allianceId || leaderGuild?.allianceRole !== 'leader') {
    throw new HttpsError('permission-denied', 'Only alliance leaders can kick guilds.');
  }

  if (!targetGuildSnap.exists || targetGuild?.allianceId !== allianceId) {
    throw new HttpsError('failed-precondition', 'Target guild is not part of the same alliance.');
  }

  if (targetGuild?.allianceRole === 'leader') {
    throw new HttpsError('failed-precondition', 'You cannot kick the alliance leader.');
  }

  const allianceRef = db.doc(`alliances/${allianceId}`);
  const allianceLogRef = allianceRef.collection('log');

  const systemMessage = `⚔️ Guild ${targetGuild?.tag ?? targetGuildId} was removed from the alliance.`;

  await db.runTransaction(async (tx) => {
    tx.update(targetGuildRef, {
      allianceId: admin.firestore.FieldValue.delete(),
      allianceRole: admin.firestore.FieldValue.delete(),
    });

    tx.update(allianceRef, {
      guildIds: admin.firestore.FieldValue.arrayRemove(targetGuildId),
    });

    tx.set(allianceLogRef.doc(), {
      type: 'system',
      content: systemMessage,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  // 🧠 Trigger a fresh point tally for leaderboard goodness
  await recalculateGuildAndAlliancePoints();


  console.log(`👢 Guild ${targetGuildId} was kicked from alliance ${allianceId} by ${profile.guildId}`);

  return {
    status: 'kicked',
    message: 'The guild has been removed from the alliance.',
  };
}
