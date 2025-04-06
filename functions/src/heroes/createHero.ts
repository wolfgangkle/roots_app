// functions/src/hero/createHero.ts
import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Pure logic for creating a main hero (mage) during onboarding.
 * Validates the input, ensures the user is authenticated,
 * and checks that a main hero doesn't already exist before creating one.
 */
export async function createHeroLogic(request: any) {
  const { heroName, race, tileX, tileY } = request.data;
  const userId = request.auth?.uid;

  // Ensure the user is authenticated.
  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  // Validate input parameters.
  if (!heroName || typeof heroName !== 'string' || heroName.trim().length < 3) {
    throw new HttpsError('invalid-argument', 'heroName must be at least 3 characters long.');
  }
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
    heroName: heroName.trim(),
    type: 'mage',  // Main hero is always a mage.
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
    state: 'idle', // Other states: 'moving', 'exploring', 'fighting', etc.
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  // Create the new hero document.
  const newHeroRef = heroesRef.doc();
  await newHeroRef.set(heroData);

  console.log(`🚀 Created main hero (mage) with id ${newHeroRef.id} for user ${userId}`);
  return {
    heroId: newHeroRef.id,
    message: 'Hero created successfully.',
  };
}
