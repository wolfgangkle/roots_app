import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https'; // ✅ Removed unused onCall

const db = admin.firestore();

export async function createVillageLogic(request: any) {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'You must be logged in to create a village.');
  }

  const { heroId, villageName } = request.data;

  if (!heroId || typeof heroId !== 'string') {
    throw new HttpsError('invalid-argument', 'Missing or invalid heroId.');
  }

  if (!villageName || typeof villageName !== 'string' || villageName.trim().length < 3) {
    throw new HttpsError('invalid-argument', 'Village name must be at least 3 characters.');
  }

  const heroRef = db.collection('heroes').doc(heroId);
  const heroSnap = await heroRef.get();
  const hero = heroSnap.data();

  if (!hero) {
    throw new HttpsError('not-found', 'Hero not found.');
  }

  if (hero.ownerId !== uid) {
    throw new HttpsError('permission-denied', 'You do not own this hero.');
  }

  if (hero.state !== 'idle') {
    throw new HttpsError('failed-precondition', 'Hero must be idle to found a village.');
  }

  const tileX = hero.tileX;
  const tileY = hero.tileY;
  const tileKey = `${tileX}_${tileY}`;
  const mapTileRef = db.collection('mapTiles').doc(tileKey);
  const mapTileSnap = await mapTileRef.get();
  const mapTile = mapTileSnap.data();

  if (!mapTile) {
    throw new HttpsError('not-found', `Map tile ${tileKey} does not exist.`);
  }

  if (mapTile.terrain !== 'plains') {
    throw new HttpsError('failed-precondition', `You can only found a village on plains. This tile is: ${mapTile.terrain}`);
  }

  if (mapTile.villageId) {
    throw new HttpsError('already-exists', 'This tile already has a village.');
  }

  const newVillageRef = db.collection('users').doc(uid).collection('villages').doc();

  await db.runTransaction(async (tx) => {
    const now = admin.firestore.FieldValue.serverTimestamp();

    tx.set(newVillageRef, {
      name: villageName.trim(),
      tileX,
      tileY,
      tileKey,
      ownerId: uid,
      resources: {
        wood: 100,
        stone: 100,
        food: 100,
        iron: 50,
        gold: 10,
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
    });

    tx.update(mapTileRef, {
      villageId: newVillageRef.id,
    });
  });

  console.log(`✅ Village '${villageName}' created at ${tileKey} by hero ${heroId}`);

  return {
    success: true,
    villageId: newVillageRef.id,
    tileX,
    tileY,
    tileKey,
    message: 'Village successfully founded.',
  };
}
