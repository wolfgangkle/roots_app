import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function removeAssignedSpellFromHero(request: CallableRequest<any>) {
  const userId = request.auth?.uid;
  const { heroId, spellId } = request.data;

  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  if (!heroId || typeof heroId !== 'string') {
    throw new HttpsError('invalid-argument', 'heroId is required.');
  }

  if (!spellId || typeof spellId !== 'string') {
    throw new HttpsError('invalid-argument', 'spellId is required.');
  }

  const heroRef = db.collection('heroes').doc(heroId);
  const spellRef = heroRef.collection('assignedSpells').doc(spellId);

  const heroSnap = await heroRef.get();
  if (!heroSnap.exists) {
    throw new HttpsError('not-found', 'Hero not found.');
  }

  const heroData = heroSnap.data();
  if (heroData?.ownerId !== userId) {
    throw new HttpsError('permission-denied', 'You do not own this hero.');
  }

  await spellRef.delete();

  console.log(`🧹 Removed spell "${spellId}" from hero ${heroId}`);

  return {
    success: true,
    message: `Spell "${spellId}" removed from hero.`,
  };
}
