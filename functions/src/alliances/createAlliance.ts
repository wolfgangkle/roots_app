import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { recalculateGuildAndAlliancePoints } from '../helpers/recalculateGuildAndAlliancePoints.js';

const db = admin.firestore();

export async function createAlliance(request: any) {
  const userId = request.auth?.uid;
  const { name, tag, description } = request.data;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (typeof name !== 'string' || name.trim().length < 3) {
    throw new HttpsError('invalid-argument', 'Alliance name must be at least 3 characters.');
  }
  if (typeof tag !== 'string' || tag.length < 2 || tag.length > 4 || !/^[a-zA-Z]+$/.test(tag)) {
    throw new HttpsError('invalid-argument', 'Tag must be 2–4 letters (uppercase or lowercase).');
  }

  const trimmedName = name.trim();
  const trimmedTag = tag.trim()
  const trimmedDesc = typeof description === 'string' ? description.trim() : '';

  const alliancesRef = db.collection('alliances');
  const userProfileRef = db.doc(`users/${userId}/profile/main`);
  const userProfileSnap = await userProfileRef.get();
  const profileData = userProfileSnap.data();

  if (!profileData?.guildId) {
    throw new HttpsError('failed-precondition', 'You must be in a guild to create an alliance.');
  }
  if (profileData.guildRole !== 'leader') {
    throw new HttpsError('permission-denied', 'Only guild leaders can create alliances.');
  }

  const guildRef = db.doc(`guilds/${profileData.guildId}`);
  const guildSnap = await guildRef.get();
  const guildData = guildSnap.data();

  if (guildData?.allianceId) {
    throw new HttpsError('failed-precondition', 'This guild is already in an alliance.');
  }

  const existingName = await alliancesRef.where('name', '==', trimmedName).get();
  if (!existingName.empty) {
    throw new HttpsError('already-exists', 'An alliance with this name already exists.');
  }

  const existingTag = await alliancesRef.where('tag', '==', trimmedTag).get();
  if (!existingTag.empty) {
    throw new HttpsError('already-exists', 'This tag is already taken.');
  }

  const allianceRef = alliancesRef.doc();
  const now = admin.firestore.FieldValue.serverTimestamp();

  const allianceData = {
    name: trimmedName,
    tag: trimmedTag,
    description: trimmedDesc,
    createdAt: now,
    createdByGuildId: guildRef.id,
    guildIds: [guildRef.id],
  };

  await db.runTransaction(async (tx) => {
    tx.set(allianceRef, allianceData);
    tx.update(guildRef, {
      allianceId: allianceRef.id,
      allianceRole: 'leader',
    });
  });

  // 🧠 Trigger a fresh point tally for leaderboard goodness
  await recalculateGuildAndAlliancePoints();
  console.log(`🤝 Created alliance "${trimmedName}" [${trimmedTag}] by guild ${guildRef.id}`);


  return {
    allianceId: allianceRef.id,
    name: trimmedName,
    tag: trimmedTag,
  };
}
