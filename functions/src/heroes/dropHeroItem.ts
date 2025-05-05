import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import {
  calculateHeroWeight,
  calculateAdjustedMovementSpeed,
} from '../helpers/heroWeight';
import { updateGroupMovementSpeed } from '../helpers/updateGroupMovementSpeed';

export async function dropHeroItem(request: any) {
  const db = admin.firestore();
  const { heroId, backpackIndex, quantity, villageId, tileKey } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!heroId || typeof heroId !== 'string') throw new HttpsError('invalid-argument', 'Missing heroId.');
  if (typeof backpackIndex !== 'number') throw new HttpsError('invalid-argument', 'Invalid backpackIndex.');
  if (!quantity || quantity <= 0) throw new HttpsError('invalid-argument', 'Quantity must be > 0.');

  const heroRef = db.collection('heroes').doc(heroId);
  const heroSnap = await heroRef.get();
  if (!heroSnap.exists) throw new HttpsError('not-found', 'Hero not found.');

  const hero = heroSnap.data()!;
  const backpack = Array.isArray(hero.backpack) ? [...hero.backpack] : [];
  const item = backpack[backpackIndex];

  if (!item || !item.itemId) {
    throw new HttpsError('not-found', 'Item not found in backpack at index.');
  }

  const itemId = item.itemId;
  const craftedStats = item.craftedStats || {};
  const itemQuantity = item.quantity || 1;
  const equipSlot = item.equipSlot?.toString().toLowerCase() ?? null; // ✅ FIXED: extract before .set()

  if (quantity > itemQuantity) {
    throw new HttpsError('invalid-argument', 'Trying to drop more than you have.');
  }

  // Choose where to drop the item
  const dropToRef = villageId
    ? db.collection('users').doc(userId).collection('villages').doc(villageId).collection('items').doc()
    : tileKey
      ? db.collection('mapTiles').doc(tileKey).collection('items').doc()
      : null;

  if (!dropToRef) {
    throw new HttpsError('invalid-argument', 'Either villageId or tileKey must be provided.');
  }

  const batch = db.batch();

  // 1. Add to tile or village
  batch.set(dropToRef, {
    itemId,
    craftedStats,
    equipSlot, // ✅ Store correctly
    quantity,
    droppedByHero: heroId,
    droppedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 2. Update backpack
  if (quantity === itemQuantity) {
    backpack.splice(backpackIndex, 1); // drop all = remove item
  } else {
    backpack[backpackIndex].quantity -= quantity;
  }

  // 3. Recalculate weight & speed
  const equipped = hero.equipped || {};
  const currentWeight = calculateHeroWeight(equipped, backpack);
  const baseSpeed = hero.baseMovementSpeed ?? hero.movementSpeed ?? 1200;
  const carryCapacity = hero.carryCapacity ?? 100;
  const movementSpeed = calculateAdjustedMovementSpeed(baseSpeed, currentWeight, carryCapacity);

  // 4. Update hero doc
  batch.update(heroRef, {
    backpack,
    currentWeight,
    movementSpeed,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();

  // ✅ 5. Sync group movement if needed
  if (hero.groupId) {
    await updateGroupMovementSpeed(hero.groupId);
  }

  console.log(`📦 Hero ${heroId} dropped ${quantity}x ${itemId} to ${villageId ?? tileKey}`);

  return {
    success: true,
    itemId,
    quantity,
    updatedStats: {
      currentWeight,
      movementSpeed,
    },
  };
}
