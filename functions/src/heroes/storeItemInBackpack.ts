import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import {
  calculateHeroWeight,
  calculateAdjustedMovementSpeed,
} from '../helpers/heroWeight';
import { updateGroupMovementSpeed } from '../helpers/updateGroupMovementSpeed';

export async function storeItemInBackpack(request: any) {
  const db = admin.firestore();
  const { heroId, itemDocId, villageId, tileKey } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!heroId || typeof heroId !== 'string') throw new HttpsError('invalid-argument', 'Missing heroId.');
  if (!itemDocId || typeof itemDocId !== 'string') throw new HttpsError('invalid-argument', 'Missing itemDocId.');

  const heroRef = db.collection('heroes').doc(heroId);
  const heroSnap = await heroRef.get();
  if (!heroSnap.exists) throw new HttpsError('not-found', 'Hero not found.');

  const hero = heroSnap.data()!;
  const backpack = Array.isArray(hero.backpack) ? [...hero.backpack] : [];

  const sourceRef = villageId
    ? db.collection('users').doc(userId).collection('villages').doc(villageId).collection('items').doc(itemDocId)
    : tileKey
      ? db.collection('mapTiles').doc(tileKey).collection('items').doc(itemDocId)
      : null;

  if (!sourceRef) throw new HttpsError('invalid-argument', 'Either villageId or tileKey must be provided.');

  const itemSnap = await sourceRef.get();
  if (!itemSnap.exists) throw new HttpsError('not-found', 'Item not found at source.');

  const item = itemSnap.data()!;
  const itemId = item.itemId;
  const craftedStats = item.craftedStats || {};
  const quantity = item.quantity ?? 1;
  const equipSlot = item.equipSlot?.toString().toLowerCase() ?? null; // ✅ Add equipSlot

  // Add to backpack
  backpack.push({
    itemId,
    craftedStats,
    equipSlot, // ✅ Preserve it
    quantity,
    movedFrom: villageId ? 'village' : tileKey,
    movedAt: admin.firestore.Timestamp.now(),
  });

  // ✅ Recalculate weight and movement speed
  const equipped = hero.equipped || {};
  const currentWeight = calculateHeroWeight(equipped, backpack);
  const baseSpeed = hero.baseMovementSpeed ?? hero.movementSpeed ?? 1200;
  const carryCapacity = hero.carryCapacity ?? 100;
  const movementSpeed = calculateAdjustedMovementSpeed(baseSpeed, currentWeight, carryCapacity);

  const batch = db.batch();

  // Remove the item from the tile or village
  batch.delete(sourceRef);

  // Update the backpack and new stats
  batch.update(heroRef, {
    backpack,
    currentWeight,
    movementSpeed,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();

  // ✅ Sync group speed if needed
  if (hero.groupId) {
    await updateGroupMovementSpeed(hero.groupId);
  }

  console.log(`🎒 Hero ${heroId} picked up ${quantity}x ${itemId} into backpack from ${villageId ?? tileKey}`);

  return {
    success: true,
    itemId,
    quantity,
    source: villageId ?? tileKey,
    updatedStats: {
      currentWeight,
      movementSpeed,
    },
  };
}
