import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Reusable stat scaling logic
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

export async function createCompanionLogic(request: any) {
  const { tileX, tileY, name } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (typeof tileX !== 'number' || typeof tileY !== 'number') {
    throw new HttpsError('invalid-argument', 'tileX and tileY must be numbers.');
  }

  const profileRef = db.doc(`users/${userId}/profile/main`);
  const profileSnap = await profileRef.get();
  const profileData = profileSnap.data();

  if (!profileData || !profileData.slotLimits || !profileData.currentSlotUsage) {
    throw new HttpsError('failed-precondition', 'Profile not initialized with slot limits.');
  }

  const normalizedRace = profileData.race?.trim().toLowerCase() || 'unknown';
  const companionName = typeof name === 'string' && name.trim().length > 0
    ? name.trim()
    : 'Unnamed Companion';

  const movementSpeeds: Record<string, number> = {
    human: 300,
    dwarf: 600,
  };
  const movementSpeed = movementSpeeds[normalizedRace] ?? 1200;

  const usedVillages = profileData.currentSlotUsage.villages ?? 0;
  const usedCompanions = profileData.currentSlotUsage.companions ?? 0;

  const maxCompanions = profileData.slotLimits.maxCompanions ?? 8;
  const maxSlotsRaceCap = profileData.slotLimits.maxSlots ?? 8;
  const usedSlots = usedVillages + usedCompanions;

  const mageSnap = await db.collection('heroes')
    .where('ownerId', '==', userId)
    .where('type', '==', 'mage')
    .limit(1)
    .get();

  if (mageSnap.empty) {
    throw new HttpsError('failed-precondition', 'Main hero (mage) not found.');
  }

  const mageLevel = mageSnap.docs[0].data().level ?? 1;

  function calculateMaxSlots(level: number): number {
    return Math.min(2 + Math.floor((level - 1) / 2), maxSlotsRaceCap);
  }

  const currentMaxSlots = calculateMaxSlots(mageLevel);

  if (usedSlots >= currentMaxSlots) {
    throw new HttpsError('failed-precondition', `You have used all available slots (${usedSlots}/${currentMaxSlots}).`);
  }

  if (usedCompanions >= maxCompanions) {
    throw new HttpsError('failed-precondition', `You have reached your companion limit (${usedCompanions}/${maxCompanions}).`);
  }

  const newHeroRef = db.collection('heroes').doc();
  const heroId = newHeroRef.id;
  const tileKey = `${tileX}_${tileY}`;
  const now = admin.firestore.FieldValue.serverTimestamp();

  const baseStats = {
    strength: 10,
    dexterity: 10,
    intelligence: 3, // 🧠 Dumber than a mage
    constitution: 10,
    magicResistance: 0,
  };

  const derived = calculateDerivedStats(baseStats);

  await db.runTransaction(async (tx) => {
    const heroData = {
      ownerId: userId,
      heroName: companionName,
      type: 'companion',
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
        defense: 1,
        regenPerTick: 1,
        attackSpeedMs: derived.attackSpeedMs,
      },
      hpRegen: derived.hpRegen,
      manaRegen: derived.manaRegen,
      foodDuration: 3600,
      movementSpeed,
      maxWaypoints: derived.maxWaypoints,
      carryCapacity: derived.carryCapacity,
      state: 'idle',
      createdAt: now,
    };

    const groupRef = db.collection('heroGroups').doc(heroId);
    const groupData = {
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

    tx.set(newHeroRef, heroData);
    tx.set(groupRef, groupData);

    tx.update(profileRef, {
      'currentSlotUsage.companions': admin.firestore.FieldValue.increment(1),
      currentMaxSlots: currentMaxSlots,
    });
  });

  console.log(`👥 Companion "${companionName}" created for ${userId} (${usedSlots + 1}/${currentMaxSlots} slots)`);

  return {
    heroId,
    message: `Companion created successfully. (${usedSlots + 1}/${currentMaxSlots} slots used)`,
  };
}
