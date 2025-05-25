import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';

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

  const profileRef = db.doc(`users/${uid}/profile/main`);
  const profileSnap = await profileRef.get();
  const profile = profileSnap.data();

  if (!profile || !profile.slotLimits || !profile.currentSlotUsage) {
    throw new HttpsError('failed-precondition', 'Profile is missing slot limits.');
  }

  const usedVillages = profile.currentSlotUsage.villages ?? 0;
  const usedCompanions = profile.currentSlotUsage.companions ?? 0;
  const maxVillages = profile.slotLimits.maxVillages ?? 8;
  const maxSlots = profile.slotLimits.maxSlots ?? 8;
  const totalUsedSlots = usedVillages + usedCompanions;

  const mageSnap = await db.collection('heroes')
    .where('ownerId', '==', uid)
    .where('type', '==', 'mage')
    .limit(1)
    .get();

  if (mageSnap.empty) {
    throw new HttpsError('failed-precondition', 'Main hero (mage) not found.');
  }

  const mageLevel = mageSnap.docs[0].data().level ?? 1;

  const currentMaxSlots = Math.min(
    2 + Math.floor((mageLevel - 1) / 2),
    maxSlots
  );

  const newVillageRef = db.collection('users').doc(uid).collection('villages').doc();

  await db.runTransaction(async (tx) => {
    const now = admin.firestore.FieldValue.serverTimestamp();

    const isCompanion = hero.type === 'companion';
    const hasFreeSlot = totalUsedSlots < currentMaxSlots;
    const underVillageCap = usedVillages < maxVillages;

    if (!hasFreeSlot && (!isCompanion || !underVillageCap)) {
      throw new HttpsError(
        'failed-precondition',
        'You have no available slot and cannot sacrifice this hero to found a village.'
      );
    }

    tx.set(newVillageRef, {
      name: villageName.trim(),
      tileX,
      tileY,
      tileKey,
      ownerId: uid,
      resources: {
        wood: 0,
        stone: 0,
        food: 0,
        iron: 0,
        gold: 0,
      },
      storageCapacity: {
        wood: 5000,
        stone: 5000,
        iron: 5000,
        food: 1000,
        gold: Infinity,
      },
      buildings: {},
      freeWorkers: 0,
      maxProductionPerHour: {},
      currentProductionPerHour: {},
      lastUpdated: now,
      createdAt: now,
    });

    tx.update(mapTileRef, {
      villageId: newVillageRef.id,
    });

    const profileUpdate: FirebaseFirestore.UpdateData<admin.firestore.DocumentData> = {
      'currentSlotUsage.villages': admin.firestore.FieldValue.increment(1),
      currentMaxSlots,
    };

    if (!hasFreeSlot && isCompanion) {
      profileUpdate['currentSlotUsage.companions'] = admin.firestore.FieldValue.increment(-1);
    }

    tx.update(profileRef, profileUpdate);

    if (!hasFreeSlot && isCompanion) {
      tx.delete(heroRef);
      console.log(`☠️ Companion ${heroId} sacrificed to found a village.`);
    }
  });

  console.log(`✅ Village '${villageName}' created at ${tileKey} by hero ${heroId}`);

  return {
    success: true,
    villageId: newVillageRef.id,
    tileX,
    tileY,
    tileKey,
    message: `Village successfully founded.`,
  };
}
