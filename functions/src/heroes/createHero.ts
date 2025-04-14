import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

export async function createHeroLogic(request: any) {
  const db = admin.firestore();
  // Remove race from request.data—we'll fetch it from the user profile.
  const { tileX, tileY } = request.data;
  const userId = request.auth?.uid;

  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  // Load hero data from the user profile
  const profileSnap = await db.doc(`users/${userId}/profile/main`).get();
  const profileData = profileSnap.data();

  // Ensure heroName is valid.
  if (!profileData || typeof profileData.heroName !== 'string' || profileData.heroName.trim().length < 3) {
    throw new HttpsError('invalid-argument', 'Main hero name not set or invalid in user profile.');
  }
  const heroName = profileData.heroName.trim();

  // Now, get the race from the profile data.
  if (!profileData.race || typeof profileData.race !== 'string' || profileData.race.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'Race is required in your profile.');
  }
  const normalizedRace = profileData.race.trim().toLowerCase();

  // Check that tileX and tileY are numbers.
  if (typeof tileX !== 'number' || typeof tileY !== 'number') {
    throw new HttpsError('invalid-argument', 'tileX and tileY must be numbers.');
  }

  const heroesRef = db.collection('heroes');

  // Ensure the user does not already have a main hero (mage).
  const existingSnapshot = await heroesRef
    .where('ownerId', '==', userId)
    .where('type', '==', 'mage')
    .get();
  if (!existingSnapshot.empty) {
    throw new HttpsError('already-exists', 'Main hero already exists for this user.');
  }

  // 🐎 Define default movement speed per race (in seconds per tile)
  const defaultMovementSpeeds: Record<string, number> = {
    human: 300, // 20 minutes in seconds; right now reduced to 300 for testing
    drawf: 600, // 10 minutes in seconds; right now reduced to 600 for testing
    // elf: 900,  // maybe faster in the future
    // dwarf: 1500, // slower
    // etc.
  };

  const movementSpeed = defaultMovementSpeeds[normalizedRace] ?? 1200; // fallback to 20 minutes if unknown

  const heroData = {
    ownerId: userId,
    heroName,
    type: 'mage',
    race: normalizedRace,
    level: 1,
    experience: 0,
    groupId: null,
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
    combat: {
      combatLevel: 1,
      attackMin: 5,
      attackMax: 9,
      defense: 1,
      regenPerTick: 1,
      attackSpeedMs: 100000,
    },
    tileX,
    tileY,
    state: 'idle',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),

    // Regen and hunger settings
    hpRegen: 300,
    manaRegen: 60,
    foodDuration: 3600,

    // 🆕 movement speed in seconds per tile
    movementSpeed,
  };

  const newHeroRef = heroesRef.doc();
  await newHeroRef.set(heroData);

  console.log(`🚀 Created main hero "${heroName}" with id ${newHeroRef.id} for user ${userId}, race=${normalizedRace}, movementSpeed=${movementSpeed}s`);
  return {
    heroId: newHeroRef.id,
    message: 'Hero created successfully.',
  };
}
