import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { heroStatFormulas } from '../helpers/heroStatFormulas';

const db = admin.firestore();

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
  const companionName =
    typeof name === 'string' && name.trim().length > 0 ? name.trim() : 'Unnamed Companion';

  const movementModifiers: Record<string, number> = { human: 0, dwarf: 400 };
  const raceMovementOffset = movementModifiers[normalizedRace] ?? 0;

  const usedVillages = profileData.currentSlotUsage.villages ?? 0;
  const usedCompanions = profileData.currentSlotUsage.companions ?? 0;

  const maxCompanions = profileData.slotLimits.maxCompanions ?? 8;
  const maxSlotsRaceCap = profileData.slotLimits.maxSlots ?? 8;
  const usedSlots = usedVillages + usedCompanions;

  const mageSnap = await db
    .collection('heroes')
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
    throw new HttpsError(
      'failed-precondition',
      `You have used all available slots (${usedSlots}/${currentMaxSlots}).`
    );
  }

  if (usedCompanions >= maxCompanions) {
    throw new HttpsError(
      'failed-precondition',
      `You have reached your companion limit (${usedCompanions}/${maxCompanions}).`
    );
  }

  const newHeroRef = db.collection('heroes').doc();
  const heroId = newHeroRef.id;
  const tileKey = `${tileX}_${tileY}`;
  const nowTs = admin.firestore.FieldValue.serverTimestamp();
  const nowMs = Date.now(); // ✅ numeric ms for regen clocks

  const baseStats = {
    strength: 10,
    dexterity: 10,
    intelligence: 3, // Dumb bois unite
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

  const baseMovementSpeed = Math.max(600, baseSpeedBeforeRace + raceMovementOffset);

  // ✅ Defensive normalization for tick intervals (seconds PER +1 point)
  const hpRegenTick = Math.max(1, Math.round(hpRegen ?? 0));      // e.g., 270 => +1 HP every 270s
  const manaRegenTick = Math.max(1, Math.round(manaRegen ?? 0));  // e.g., 270 => +1 Mana every 270s

  await db.runTransaction(async (tx) => {
    const heroData = {
      ownerId: userId,
      heroName: companionName,
      type: 'companion',
      race: normalizedRace,
      level: 1,
      xp: 0,
      groupId: heroId,
      groupLeaderId: null,
      stats: baseStats,

      // Attribute points to spend
      unspentAttributePoints: 0,

      // Core vitals
      hp: hpMax,
      hpMax,
      mana: manaMax,
      manaMax,

      // ✅ Regen config (TICK model: seconds PER +1 point)
      hpRegen: hpRegenTick,
      manaRegen: manaRegenTick,

      // ✅ Initialize separate regen clocks (numbers, ms epoch)
      lastHpRegenAt: nowMs,
      lastManaRegenAt: nowMs,

      // (Optional legacy single clock for any old readers)
      lastRegenAt: nowMs,

      combatLevel,
      combat, // ✅ cleaned, no duplicate combatLevel
      foodDuration: 3600,
      baseMovementSpeed,
      movementSpeed: baseMovementSpeed,
      maxWaypoints,
      carryCapacity,
      currentWeight: 0,
      state: 'idle',
      createdAt: nowTs,
    };

    const groupRef = db.collection('heroGroups').doc(heroId);
    const groupData = {
      leaderHeroId: heroId,
      members: [heroId],
      connections: {},
      tileX,
      tileY,
      tileKey,
      baseMovementSpeed,
      movementSpeed: baseMovementSpeed,
      insideVillage: true,
      createdAt: nowTs,
      updatedAt: nowTs,
      combatLevel,
    };

    tx.set(newHeroRef, heroData);
    tx.set(groupRef, groupData);

    tx.update(profileRef, {
      'currentSlotUsage.companions': admin.firestore.FieldValue.increment(1),
      currentMaxSlots,
    });
  });

  console.log(
    `👥 Companion "${companionName}" created for ${userId} (${usedSlots + 1}/${currentMaxSlots} slots), baseMove=${baseMovementSpeed}s`
  );

  return {
    heroId,
    message: `Companion created successfully. (${usedSlots + 1}/${currentMaxSlots} slots used)`,
  };
}
