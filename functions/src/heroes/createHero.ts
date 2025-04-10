// functions/src/heroes/createHero.ts
import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

export async function createHeroLogic(request: any) {
  const db = admin.firestore();
  const { race, tileX, tileY } = request.data;
  const userId = request.auth?.uid;

  // Ensure the user is authenticated.
  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  // 🔥 Load hero name from user profile
  const profileSnap = await db.doc(`users/${userId}/profile/main`).get();
  const profileData = profileSnap.data();

  if (!profileData || typeof profileData.heroName !== 'string' || profileData.heroName.trim().length < 3) {
    throw new HttpsError('invalid-argument', 'Main hero name not set or invalid in user profile.');
  }

  const heroName = profileData.heroName.trim();

  // Validate other parameters
  if (!race || typeof race !== 'string' || race.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'race is required.');
  }
  if (typeof tileX !== 'number' || typeof tileY !== 'number') {
    throw new HttpsError('invalid-argument', 'tileX and tileY must be numbers.');
  }

  const heroesRef = db.collection('heroes');

  // Check that a main hero (mage) does not already exist for this user.
  const existingSnapshot = await heroesRef
    .where('ownerId', '==', userId)
    .where('type', '==', 'mage')
    .get();

  if (!existingSnapshot.empty) {
    throw new HttpsError('already-exists', 'Main hero already exists for this user.');
  }

  // Define the new hero data.
  const heroData = {
    ownerId: userId,
    heroName,
    type: 'mage',
    race: race.trim(),
    level: 1,
    experience: 0,
    stats: {
      strength: 10,
      dexterity: 10,
      intelligence: 10,
      constitution: 10,
      magicResistance: 0,
    },
    hp: 100,
    hpMax: 100,
    mana: 50,
    manaMax: 50,
    tileX,
    tileY,
    state: 'idle',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),

    // ✅ Add these
    hpRegen: 300,        // e.g. 5 minutes
    manaRegen: 60,       // 1 mana every 60 seconds
    foodDuration: 3600,  // 1 hour before hunger drains
  };


  // Create the new hero document.
  const newHeroRef = heroesRef.doc();
  await newHeroRef.set(heroData);

  console.log(`🚀 Created main hero "${heroName}" with id ${newHeroRef.id} for user ${userId}`);
  return {
    heroId: newHeroRef.id,
    message: 'Hero created successfully.',
  };
}
