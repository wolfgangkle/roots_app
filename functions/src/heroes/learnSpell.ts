import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function learnSpellLogic(request: CallableRequest<any>) {
  const uid = request.auth?.uid;
  const { heroId, spellId, userId } = request.data;

  if (!uid) {
    throw new HttpsError('unauthenticated', 'You must be logged in.');
  }

  if (!heroId || !spellId || !userId) {
    throw new HttpsError('invalid-argument', 'heroId, spellId, and userId are required.');
  }

  if (uid !== userId) {
    throw new HttpsError('permission-denied', 'You are not allowed to modify this hero.');
  }

  const heroRef = db.collection('heroes').doc(heroId);
  const heroSnap = await heroRef.get();

  if (!heroSnap.exists) {
    throw new HttpsError('not-found', 'Hero not found.');
  }

  const heroData = heroSnap.data()!;
  if (heroData.ownerId !== uid) {
    throw new HttpsError('permission-denied', 'You do not own this hero.');
  }

  const learnedSpells: string[] = heroData.learnedSpells || [];
  if (learnedSpells.includes(spellId)) {
    throw new HttpsError('already-exists', 'This spell is already learned.');
  }

  await heroRef.update({
    learnedSpells: admin.firestore.FieldValue.arrayUnion(spellId),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, spellId };
}
