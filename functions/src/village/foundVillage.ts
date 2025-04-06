// functions/src/village/foundVillage.ts
import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function foundVillageLogic(request: any) {
  // Ensure the request is authenticated.
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated.');
  }

  // Validate input parameters.
  const { heroId, tileX, tileY } = request.data;
  if (typeof heroId !== 'string' || typeof tileX !== 'number' || typeof tileY !== 'number') {
    throw new HttpsError('invalid-argument', 'Invalid arguments provided.');
  }

  const uid = request.auth.uid;

  try {
    const result = await db.runTransaction(async (transaction) => {
      // 1. Retrieve the hero document.
      const heroRef = db.collection('heroes').doc(heroId);
      const heroDoc = await transaction.get(heroRef);
      if (!heroDoc.exists) {
        throw new HttpsError('not-found', 'Hero not found.');
      }
      const heroData = heroDoc.data()!;
      // Ensure the hero belongs to the requesting user.
      if (heroData.ownerId !== uid) {
        throw new HttpsError('permission-denied', 'Hero does not belong to the user.');
      }
      // Check that the hero is a mage.
      if (heroData.type !== 'mage') {
        throw new HttpsError('failed-precondition', 'Only mages can found new villages.');
      }
      // Verify that the hero is on the target tile.
      if (heroData.tileX !== tileX || heroData.tileY !== tileY) {
        throw new HttpsError('failed-precondition', 'Mage is not on the selected tile.');
      }

      // 2. Compute the maximum allowed villages based on hero level.
      const heroLevel = heroData.level || 1;
      const maxVillages = Math.min(1 + Math.floor((heroLevel - 1) / 2), 5);

      // 3. Count current villages under the user.
      const villagesRef = db.collection('users').doc(uid).collection('villages');
      const villagesSnapshot = await transaction.get(villagesRef);
      const currentVillageCount = villagesSnapshot.size;

      if (currentVillageCount >= maxVillages) {
        throw new HttpsError('failed-precondition', 'Village cap reached for your level.');
      }

      // 4. Check that the selected tile is not already occupied.
      const tileId = `tile_${tileX}_${tileY}`;
      const tileRef = db.collection('tiles').doc(tileId);
      const tileDoc = await transaction.get(tileRef);
      if (tileDoc.exists && tileDoc.data()?.occupiedBy) {
        throw new HttpsError('failed-precondition', 'Tile is already occupied.');
      }

      // 5. Create a new village document.
      const newVillageRef = villagesRef.doc(); // Auto-generate document ID.
      const now = admin.firestore.FieldValue.serverTimestamp();
      const villageData = {
        name: 'New Village', // You may want to let the player set a name later.
        tileX,
        tileY,
        ownerId: uid,
        createdAt: now,
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
      };

      transaction.set(newVillageRef, villageData);

      // 6. Mark the tile as occupied by this village.
      transaction.set(tileRef, { occupiedBy: newVillageRef.id }, { merge: true });

      return {
        villageId: newVillageRef.id,
        newTotalVillages: currentVillageCount + 1,
        maxVillages,
      };
    });

    return { success: true, data: result };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    console.error('Error in foundVillageLogic:', error);
    throw new HttpsError('unknown', 'An unknown error occurred while founding the village.');
  }
}
