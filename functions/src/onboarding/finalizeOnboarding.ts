import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Finalizes the onboarding process by creating the initial village and
 * locking in the player's chosen hero name and race.
 *
 * Input data should include:
 *   - heroName: string  (the account/hero name)
 *   - race: string      (e.g., "Human")
 *   - villageName: string
 *   - startZone: string (e.g., "north", "south", etc.)
 */
export async function finalizeOnboardingLogic(request: any) {
  // 1. Ensure the user is authenticated.
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  // 2. Validate input parameters.
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

  // 3. Define zone coordinate bounds.
  const zoneBounds: Record<string, { minX: number; maxX: number; minY: number; maxY: number }> = {
    north: { minX: 0, maxX: 100, minY: 300, maxY: 400 },
    south: { minX: 0, maxX: 100, minY: 0,   maxY: 100 },
    east:  { minX: 300, maxX: 400, minY: 150, maxY: 250 },
    west:  { minX: 0, maxX: 100, minY: 150, maxY: 250 },
    center:{ minX: 100, maxX: 200, minY: 150, maxY: 250 },
  };

  const zone = zoneBounds[startZone];
  if (!zone) {
    throw new HttpsError('invalid-argument', `Invalid startZone: ${startZone}`);
  }

  // 4. Helper: find an available tile within the specified zone.
  async function findAvailableTile(
    bounds: { minX: number; maxX: number; minY: number; maxY: number },
    minDistance = 5
  ): Promise<{ x: number; y: number } | null> {
    const maxTries = 50;
    for (let i = 0; i < maxTries; i++) {
      const x = Math.floor(Math.random() * (bounds.maxX - bounds.minX)) + bounds.minX;
      const y = Math.floor(Math.random() * (bounds.maxY - bounds.minY)) + bounds.minY;
      const tileId = `tile_${x}_${y}`;
      const tileRef = db.collection('tiles').doc(tileId);
      const tileDoc = await tileRef.get();

      // If tile exists and its terrain is disallowed, skip.
      if (tileDoc.exists) {
        const tileData = tileDoc.data();
        if (tileData && ['water', 'mountain', 'ice', 'forest'].includes(tileData.terrain)) {
          continue;
        }
        // Skip if tile is already occupied.
        if (tileData && tileData.occupiedBy) {
          continue;
        }
      }
      return { x, y };
    }
    return null;
  }

  const tile = await findAvailableTile(zone);
  if (!tile) {
    throw new HttpsError('failed-precondition', 'Could not find a free tile in the selected zone.');
  }

  // 5. Perform all writes in a transaction.
  try {
    const result = await db.runTransaction(async (transaction) => {
      // Create a new village document under the user's villages collection.
      const villagesRef = db.collection('users').doc(uid).collection('villages');
      const newVillageRef = villagesRef.doc();
      const now = admin.firestore.FieldValue.serverTimestamp();
      const villageData = {
        name: villageName.trim(),
        tileX: tile.x,
        tileY: tile.y,
        ownerId: uid,
        resources: {
          wood: 100,
          stone: 100,
          food: 100,
          iron: 50,
          gold: 10,
        },
        buildings: {
          townHall: { level: 1 }
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

      // Mark the tile as occupied.
      const tileRef = db.collection('tiles').doc(`tile_${tile.x}_${tile.y}`);
      transaction.set(tileRef, { occupiedBy: newVillageRef.id }, { merge: true });

      // Create (or update) the user profile in the user's profile subcollection.
      const profileRef = db.collection('users').doc(uid).collection('profile').doc('main');
      const profileData = {
        heroName: heroName.trim(), // Now matching your Firestore field.
        race: race.trim(),
        villageId: newVillageRef.id,
        zone: startZone, // Optionally store the chosen zone.
        createdAt: now,
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
