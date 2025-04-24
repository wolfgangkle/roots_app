import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import {
  calculateHeroWeight,
  calculateAdjustedMovementSpeed,
} from '../helpers/heroWeight';
import { updateGroupMovementSpeed } from '../helpers/groupUtils';
import { calculateHeroCombatStats } from '../helpers/calculateHeroCombatStats';

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

  const dropToRef = villageId
    ? db.collection('users').doc(userId).collection('villages').doc(villageId).collection('items').doc()
    : tileKey
      ? db.collection('mapTiles').doc(tileKey).collection('items').doc()
      : null;

  if (!dropToRef) {
    throw new HttpsError('invalid-argument', 'Either villageId or tileKey must be provided.');
  }

  // Remove the item from the equipment slot
  equipped[slot] = null;

  // ✅ Recalculate combat stats
  const {
    attackMin,
    attackMax,
    attackSpeedMs,
    defense,
    at,
    def,
  } = calculateHeroCombatStats(hero.stats, equipped);

  const hpMax = hero.hpMax ?? 100;
  const manaMax = hero.manaMax ?? 50;
  const combatLevel = Math.floor((at + def) / 2 + hpMax / 10 + manaMax / 20);

  // ✅ Recalculate weight and movement speed
  const backpack = hero.backpack ?? [];
  const currentWeight = calculateHeroWeight(equipped, backpack);
  const baseSpeed = hero.baseMovementSpeed ?? hero.movementSpeed ?? 1200;
  const carryCapacity = hero.carryCapacity ?? 100;
  const movementSpeed = calculateAdjustedMovementSpeed(baseSpeed, currentWeight, carryCapacity);

  const batch = db.batch();

  // Drop the item into the world or village
  batch.set(dropToRef, {
    itemId,
    craftedStats,
    quantity: 1,
    droppedByHero: heroId,
    droppedAt: admin.firestore.FieldValue.serverTimestamp(),
    droppedFromSlot: slot,
  });

  // Update hero with recalculated stats
  batch.update(heroRef, {
    equipped,
    combat: {
      ...hero.combat,
      attackMin,
      attackMax,
      attackSpeedMs,
      defense,
      at,
      def,
      combatLevel,
    },
    currentWeight,
    movementSpeed,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();

  // ✅ Update group data
  if (hero.groupId) {
    const groupRef = db.collection('heroGroups').doc(hero.groupId);
    await groupRef.update({
      combatLevel,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await updateGroupMovementSpeed(hero.groupId);
  }

  console.log(`📦 Dropped ${itemId} from slot ${slot} to ${villageId ?? tileKey} (hero: ${heroId})`);

  return {
    success: true,
    droppedSlot: slot,
    itemId,
    updatedStats: {
      attackMin,
      attackMax,
      attackSpeedMs,
      defense,
      at,
      def,
      combatLevel,
      currentWeight,
      movementSpeed,
    },
  };
}
