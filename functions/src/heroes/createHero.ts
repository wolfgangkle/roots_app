import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { heroStatFormulas } from '../helpers/heroStatFormulas';

const db = admin.firestore();

export async function createHeroLogic(request: any) {
  const { tileX, tileY } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (typeof tileX !== 'number' || typeof tileY !== 'number') {
    throw new HttpsError('invalid-argument', 'tileX and tileY must be numbers.');
  }

  const profileSnap = await db.doc(`users/${userId}/profile/main`).get();
  const profileData = profileSnap.data();

  if (
    !profileData ||
    typeof profileData.heroName !== 'string' ||
    profileData.heroName.trim().length < 3
  ) {
    throw new HttpsError('invalid-argument', 'Main hero name not set or invalid in user profile.');
  }

  if (!profileData.race || typeof profileData.race !== 'string') {
    throw new HttpsError('invalid-argument', 'Race is required in your profile.');
  }

  const heroName = profileData.heroName.trim();
  const normalizedRace = profileData.race.trim().toLowerCase();
  const tileKey = `${tileX}_${tileY}`;

  const existingSnapshot = await db
    .collection('heroes')
    .where('ownerId', '==', userId)
    .where('type', '==', 'mage')
    .get();

  if (!existingSnapshot.empty) {
    throw new HttpsError('already-exists', 'Main hero already exists for this user.');
  }

  const baseStats = {
    strength: 10,
    dexterity: 10,
    intelligence: 10,
    constitution: 10,
    magicResistance: 0,
  };

  const {
    hpMax,
    manaMax,
    hpRegen,
    manaRegen,
    maxWaypoints,
    carryCapacity,
    baseMovementSpeed: baseSpeedBeforeRace,
    combatLevel,
    combat,
  } = heroStatFormulas(baseStats, {});

  const raceMovementModifiers: Record<string, number> = {
    human: 0,
    dwarf: 400,
  };

  const raceOffset = raceMovementModifiers[normalizedRace] ?? 0;
  const baseMovementSpeed = Math.max(600, baseSpeedBeforeRace + raceOffset);

  const newHeroRef = db.collection('heroes').doc();
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
    stats: baseStats,
    hp: hpMax,
    hpMax,
    mana: manaMax,
    manaMax,
    combatLevel, // ✅ Only here
    combat,      // ✅ Cleaned version (no combatLevel inside)
    state: 'idle',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    hpRegen,
    manaRegen,
    foodDuration: 3600,
    baseMovementSpeed,
    movementSpeed: baseMovementSpeed,
    maxWaypoints,
    carryCapacity,
    currentWeight: 0,
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
    baseMovementSpeed,
    movementSpeed: baseMovementSpeed,
    insideVillage: true,
    createdAt: now,
    updatedAt: now,
    combatLevel, // ✅ Group-level reference
  };

  await Promise.all([newHeroRef.set(heroData), heroGroupRef.set(heroGroupData)]);

  console.log(
    `🚀 Created main hero "${heroName}" with id ${heroId} for user ${userId}, race=${normalizedRace}, baseMove=${baseMovementSpeed}s`
  );

  return {
    heroId,
    message: 'Hero created successfully.',
  };
}
