import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

export async function createHeroLogic(request: any) {
  const db = admin.firestore();
  const { tileX, tileY } = request.data;
  const userId = request.auth?.uid;

  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  const profileSnap = await db.doc(`users/${userId}/profile/main`).get();
  const profileData = profileSnap.data();

  if (!profileData || typeof profileData.heroName !== 'string' || profileData.heroName.trim().length < 3) {
    throw new HttpsError('invalid-argument', 'Main hero name not set or invalid in user profile.');
  }
  const heroName = profileData.heroName.trim();

  if (!profileData.race || typeof profileData.race !== 'string' || profileData.race.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'Race is required in your profile.');
  }
  const normalizedRace = profileData.race.trim().toLowerCase();

  if (typeof tileX !== 'number' || typeof tileY !== 'number') {
    throw new HttpsError('invalid-argument', 'tileX and tileY must be numbers.');
  }

  const tileKey = `${tileX}_${tileY}`;
  const heroesRef = db.collection('heroes');

  const existingSnapshot = await heroesRef
    .where('ownerId', '==', userId)
    .where('type', '==', 'mage')
    .get();
  if (!existingSnapshot.empty) {
    throw new HttpsError('already-exists', 'Main hero already exists for this user.');
  }

  const defaultMovementSpeeds: Record<string, number> = {
    human: 300,
    dwarf: 600,
  };

  const movementSpeed = defaultMovementSpeeds[normalizedRace] ?? 1200;

  const newHeroRef = heroesRef.doc();
  const heroId = newHeroRef.id;

  const heroData = {
    ownerId: userId,
    heroName,
    type: 'mage',
    race: normalizedRace,
    level: 1,
    experience: 0,
    groupId: heroId,
    groupLeaderId: null,
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
    state: 'idle',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),

    // Regen and hunger
    hpRegen: 300,
    manaRegen: 60,
    foodDuration: 3600,

    movementSpeed,
  };

  const heroGroupRef = db.collection('heroGroups').doc(heroId);
  const now = admin.firestore.FieldValue.serverTimestamp();

  const heroGroupData = {
    leaderHeroId: heroId,
    members: [heroId],
    connections: {},
    tileX,
    tileY,
    tileKey,
    movementSpeed,
    insideVillage: true,
    createdAt: now,
    updatedAt: now,
  };

  await Promise.all([
    newHeroRef.set(heroData),
    heroGroupRef.set(heroGroupData),
  ]);

  console.log(`🚀 Created main hero "${heroName}" with id ${heroId} for user ${userId}, race=${normalizedRace}, movementSpeed=${movementSpeed}s`);

  return {
    heroId,
    message: 'Hero created successfully.',
  };
}
