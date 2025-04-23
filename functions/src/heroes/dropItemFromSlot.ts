import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import {
  calculateHeroWeight,
  calculateAdjustedMovementSpeed,
} from '../helpers/heroWeight';
import { updateGroupMovementSpeed } from '../helpers/groupUtils'; // ✅ New import

export async function dropItemFromSlot(request: any) {
  const db = admin.firestore();
  const { heroId, slot, villageId, tileKey } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!heroId || typeof heroId !== 'string') throw new HttpsError('invalid-argument', 'Missing heroId.');
  if (!slot || typeof slot !== 'string') throw new HttpsError('invalid-argument', 'Missing equipment slot.');

  const validSlots = ['mainHand', 'offHand', 'helmet', 'chest', 'legs', 'arms', 'belt', 'feet'];
  if (!validSlots.includes(slot)) {
    throw new HttpsError('invalid-argument', `Invalid equipment slot: ${slot}`);
  }

  const heroRef = db.collection('heroes').doc(heroId);
  const heroSnap = await heroRef.get();
  if (!heroSnap.exists) throw new HttpsError('not-found', 'Hero not found.');

  const hero = heroSnap.data()!;
  const equipped = hero.equipped || {};
  const item = equipped[slot];

  if (!item || !item.itemId) {
    throw new HttpsError('not-found', `No item equipped in slot: ${slot}`);
  }

  const itemId = item.itemId;
  const craftedStats = item.craftedStats || {};

  // Determine where to drop the item
  const dropToRef = villageId
    ? db.collection('users').doc(userId).collection('villages').doc(villageId).collection('items').doc()
    : tileKey
      ? db.collection('mapTiles').doc(tileKey).collection('items').doc()
      : null;

  if (!dropToRef) {
    throw new HttpsError('invalid-argument', 'Either villageId or tileKey must be provided.');
  }

  // Remove the item from equipment slot
  equipped[slot] = null;

  // Recalculate stats (attack/defense only)
  let attackMin = 5;
  let attackMax = 10;
  let defense = 0;

  for (const s of validSlots) {
    const eq = equipped[s];
    if (eq?.craftedStats) {
      attackMin += eq.craftedStats.attackMin ?? 0;
      attackMax += eq.craftedStats.attackMax ?? 0;
      defense += eq.craftedStats.defense ?? 0;
    }
  }

  // Recalculate current weight and movement speed
  const backpack = hero.backpack ?? [];
  const currentWeight = calculateHeroWeight(equipped, backpack);
  const baseSpeed = hero.baseMovementSpeed ?? hero.movementSpeed ?? 1200;
  const carryCapacity = hero.carryCapacity ?? 100;
  const movementSpeed = calculateAdjustedMovementSpeed(baseSpeed, currentWeight, carryCapacity);

  const batch = db.batch();

  // Drop the item to external location
  batch.set(dropToRef, {
    itemId,
    craftedStats,
    quantity: 1,
    droppedByHero: heroId,
    droppedAt: admin.firestore.FieldValue.serverTimestamp(),
    droppedFromSlot: slot,
  });

  // Update hero
  batch.update(heroRef, {
    equipped,
    combat: {
      ...hero.combat,
      attackMin,
      attackMax,
      defense,
    },
    currentWeight,
    movementSpeed,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();

  // ✅ Update group movement speed if needed
  if (hero.groupId) {
    await updateGroupMovementSpeed(hero.groupId);
  }

  console.log(`📦 Dropped ${itemId} from slot ${slot} to ${villageId ?? tileKey} (hero: ${heroId})`);

  return {
    success: true,
    droppedSlot: slot,
    itemId,
    updatedStats: {
      currentWeight,
      movementSpeed,
    },
  };
}
