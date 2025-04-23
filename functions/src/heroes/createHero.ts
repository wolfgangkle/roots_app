import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Calculates all derived stats for a hero based on base attributes.
 */
function calculateDerivedStats(stats: {
  strength: number;
  dexterity: number;
  intelligence: number;
  constitution: number;
}) {
  const { strength: STR, dexterity: DEX, intelligence: INT, constitution: CON } = stats;

  return {
    hpMax: 100 + CON * 10,
    hpRegen: Math.max(60, 300 - CON * 3),
    manaMax: 50 + INT * 2,
    manaRegen: Math.max(20, 60 - INT * 1),
    attackMin: 5 + Math.floor(STR * 0.4),
    attackMax: 9 + Math.floor(STR * 0.6),
    attackSpeedMs: Math.max(400, 1000 - DEX * 20),
    maxWaypoints: 10 + Math.floor(INT * 0.5),
    carryCapacity: 50 + STR * 2 + CON * 5
  };
}

export async function createHeroLogic(request: any) {
  const { tileX, tileY } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (typeof tileX !== 'number' || typeof tileY !== 'number') {
    throw new HttpsError('invalid-argument', 'tileX and tileY must be numbers.');
  }

  const profileSnap = await db.doc(`users/${userId}/profile/main`).get();
  const profileData = profileSnap.data();

  if (!profileData || typeof profileData.heroName !== 'string' || profileData.heroName.trim().length < 3) {
    throw new HttpsError('invalid-argument', 'Main hero name not set or invalid in user profile.');
  }

  if (!profileData.race || typeof profileData.race !== 'string') {
    throw new HttpsError('invalid-argument', 'Race is required in your profile.');
  }

  const heroName = profileData.heroName.trim();
  const normalizedRace = profileData.race.trim().toLowerCase();
  const tileKey = `${tileX}_${tileY}`;

  const existingSnapshot = await db.collection('heroes')
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

  const newHeroRef = db.collection('heroes').doc();
  const heroId = newHeroRef.id;

  const baseStats = {
    strength: 10,
    dexterity: 10,
    intelligence: 10,
    constitution: 10,
    magicResistance: 0,
  };

  const derived = calculateDerivedStats(baseStats);

  const heroData = {
    ownerId: userId,
    heroName,
    type: 'mage',
    race: normalizedRace,
    level: 1,
    experience: 0,
    groupId: heroId,
    groupLeaderId: null,
    stats: baseStats,
    hp: derived.hpMax,
    hpMax: derived.hpMax,
    mana: derived.manaMax,
    manaMax: derived.manaMax,
    combat: {
      combatLevel: 1,
      attackMin: derived.attackMin,
      attackMax: derived.attackMax,
      attackSpeedMs: derived.attackSpeedMs,
      defense: 1,
      regenPerTick: 1,
    },
    state: 'idle',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    hpRegen: derived.hpRegen,
    manaRegen: derived.manaRegen,
    foodDuration: 3600,
    baseMovementSpeed: movementSpeed, // ✅ added
    movementSpeed,
    maxWaypoints: derived.maxWaypoints,
    carryCapacity: derived.carryCapacity,
    currentWeight: 0, // ✅ added
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
    baseMovementSpeed: movementSpeed, // ✅ added
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
