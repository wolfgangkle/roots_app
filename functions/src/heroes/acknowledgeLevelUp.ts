// functions/src/heroes/acknowledgeLevelUp.ts
import { onCall } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const acknowledgeLevelUp = onCall(async (req) => {
  const uid = req.auth?.uid;
  const { heroId } = req.data || {};
  if (!uid || !heroId) throw new Error('unauthenticated / invalid-argument');

  const heroRef = db.doc(`heroes/${heroId}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(heroRef);
    if (!snap.exists) throw new Error('Hero not found');
    const data = snap.data()!;
    if (data.ownerId !== uid) throw new Error('permission-denied');

    if (data.pendingLevelUp) {
      tx.update(heroRef, { pendingLevelUp: admin.firestore.FieldValue.delete() });
    }
  });

  return { ok: true };
});
