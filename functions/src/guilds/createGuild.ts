import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function createGuild(request: any) {
  const userId = request.auth?.uid;
  const { name, tag, description } = request.data;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (typeof name !== 'string' || name.trim().length < 3) {
    throw new HttpsError('invalid-argument', 'Guild name must be at least 3 characters.');
  }
  if (typeof tag !== 'string' || tag.length < 2 || tag.length > 4 || !/^[A-Z]+$/.test(tag)) {
    throw new HttpsError('invalid-argument', 'Tag must be 2–4 uppercase letters.');
  }

  const trimmedName = name.trim();
  const trimmedTag = tag.trim().toUpperCase();
  const trimmedDesc = typeof description === 'string' ? description.trim() : '';

  const guildsRef = db.collection('guilds');

  const existing = await guildsRef.where('name', '==', trimmedName).get();
  if (!existing.empty) {
    throw new HttpsError('already-exists', 'A guild with this name already exists.');
  }

  const tagTaken = await guildsRef.where('tag', '==', trimmedTag).get();
  if (!tagTaken.empty) {
    throw new HttpsError('already-exists', 'This tag is already taken.');
  }

  const guildRef = guildsRef.doc();
  const profileRef = db.doc(`users/${userId}/profile/main`);
  const now = admin.firestore.FieldValue.serverTimestamp();

  const guildData = {
    name: trimmedName,
    tag: trimmedTag,
    description: trimmedDesc,
    createdAt: now,
    createdBy: userId,
    joinPolicy: 'invite_only',
    memberUserIds: [userId],
  };

  await db.runTransaction(async (tx) => {
    tx.set(guildRef, guildData);
    tx.update(profileRef, {
      guildId: guildRef.id,
      guildRole: 'leader',
    });
  });

  console.log(`🏰 Created guild "${trimmedName}" [${trimmedTag}] by user ${userId}`);

  return {
    guildId: guildRef.id,
    name: trimmedName,
    tag: trimmedTag,
  };
}
