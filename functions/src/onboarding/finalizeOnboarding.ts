import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function finalizeOnboardingLogic(request: any) {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  const { heroName, race, villageName, startZone } = request.data;
  if (typeof heroName !== 'string' || heroName.trim().length < 3) {
    throw new HttpsError('invalid-argument', 'heroName must be at least 3 characters long.');
  }
  if (typeof race !== 'string' || race.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'race is required.');
  }
  if (typeof villageName !== 'string' || villageName.trim().length < 3) {
    throw new HttpsError('invalid-argument', 'villageName must be at least 3 characters long.');
  }
  if (typeof startZone !== 'string' || startZone.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'startZone is required.');
  }

  const zoneBounds: Record<string, { minX: number; maxX: number; minY: number; maxY: number }> = {
    north: { minX: 20, maxX: 80, minY: 0, maxY: 20 },
    south: { minX: 20, maxX: 80, minY: 80, maxY: 99 },
    east: { minX: 80, maxX: 99, minY: 20, maxY: 80 },
    west: { minX: 0, maxX: 20, minY: 20, maxY: 80 },
    center: { minX: 40, maxX: 60, minY: 40, maxY: 60 },
  };

  const zone = zoneBounds[startZone];
  if (!zone) {
    throw new HttpsError('invalid-argument', `Invalid startZone: ${startZone}`);
  }

  async function findAvailableTile(
    bounds: { minX: number; maxX: number; minY: number; maxY: number },
    maxTries = 50
  ): Promise<{ x: number; y: number } | null> {
    for (let i = 0; i < maxTries; i++) {
      const x = Math.floor(Math.random() * (bounds.maxX - bounds.minX)) + bounds.minX;
      const y = Math.floor(Math.random() * (bounds.maxY - bounds.minY)) + bounds.minY;
      const tileId = `${x}_${y}`;
      const tileRef = db.collection('mapTiles').doc(tileId);
      const tileDoc = await tileRef.get();
      const tileData = tileDoc.data();

      if (tileData && tileData.terrain === 'plains' && !tileData.villageId) {
        return { x, y };
      }
    }
    return null;
  }

  const tile = await findAvailableTile(zone);
  if (!tile) {
    throw new HttpsError('failed-precondition', 'Could not find a free tile in the selected zone.');
  }

  try {
    const result = await db.runTransaction(async (transaction) => {
      const villagesRef = db.collection('users').doc(uid).collection('villages');
      const newVillageRef = villagesRef.doc();
      const profileRef = db.collection('users').doc(uid).collection('profile').doc('main');
      const now = admin.firestore.FieldValue.serverTimestamp();

      const villageData = {
        name: villageName.trim(),
        tileX: tile.x,
        tileY: tile.y,
        tileKey: `${tile.x}_${tile.y}`,
        ownerId: uid,
        resources: {
          wood: 500,
          stone: 250,
          food: 50,
          iron: 250,
          gold: 0,
        },
        productionPerHour: {
          wood: 50,
          stone: 40,
          food: 0,
          iron: 0,
          gold: 0,
        },
        lastUpdated: now,
        createdAt: now,
      };

      transaction.set(newVillageRef, villageData);
      transaction.update(db.collection('mapTiles').doc(`${tile.x}_${tile.y}`), {
        villageId: newVillageRef.id,
      });

      const trimmedRace = race.trim().toLowerCase();

      const defaultSlotLimitsByRace: Record<string, { maxSlots: number; maxVillages: number; maxCompanions: number }> = {
        human: { maxSlots: 8, maxVillages: 8, maxCompanions: 8 },
        dwarf: { maxSlots: 8, maxVillages: 8, maxCompanions: 8 },
        orc: { maxSlots: 8, maxVillages: 2, maxCompanions: 8 },
        ethereal: { maxSlots: 8, maxVillages: 8, maxCompanions: 0 },
      };

      const slotLimits = defaultSlotLimitsByRace[trimmedRace] ?? {
        maxSlots: 8,
        maxVillages: 8,
        maxCompanions: 8,
      };

      // 🧠 Level-based slot formula
      function calculateMaxSlots(level: number): number {
        return Math.min(2 + Math.floor((level - 1) / 2), slotLimits.maxSlots);
      }

      const mageLevel = 1; // Starting mage level
      const currentMaxSlots = calculateMaxSlots(mageLevel);

      const profileData = {
        heroName: heroName.trim(),
        race: trimmedRace,
        villageId: newVillageRef.id,
        zone: startZone,
        createdAt: now,
        slotLimits,
        currentSlotUsage: {
          villages: 1,
          companions: 0,
        },
        currentMaxSlots, // ✅ Store it!
      };

      transaction.set(profileRef, profileData);

      return {
        villageId: newVillageRef.id,
        tile,
      };
    });

    return {
      success: true,
      data: result,
      message: 'Onboarding finalized: village created and race locked in.',
    };
  } catch (error) {
    console.error('Error finalizing onboarding:', error);
    throw new HttpsError('unknown', 'Error finalizing onboarding.');
  }
}
