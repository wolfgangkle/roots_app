import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { calculateHeroCombatStats } from '../helpers/calculateHeroCombatStats';
import {
  calculateHeroWeight,
  calculateAdjustedMovementSpeed,
} from '../helpers/heroWeight';

export async function unequipItemToBackpack(request: any) {
  const db = admin.firestore();
  const { heroId, slot } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!heroId || typeof heroId !== 'string') throw new HttpsError('invalid-argument', 'Missing heroId.');
  if (!slot || typeof slot !== 'string') throw new HttpsError('invalid-argument', 'Missing or invalid slot.');

  const validSlots = ['mainHand', 'offHand', 'helmet', 'chest', 'legs', 'arms', 'belt', 'feet'];
  if (!validSlots.includes(slot)) {
    throw new HttpsError('invalid-argument', `Invalid equipment slot: ${slot}`);
  }

  const heroRef = db.collection('heroes').doc(heroId);
  const heroSnap = await heroRef.get();
  if (!heroSnap.exists) throw new HttpsError('not-found', 'Hero not found.');

  const hero = heroSnap.data()!;
  const equipped = hero.equipped || {};
  const backpack = Array.isArray(hero.backpack) ? [...hero.backpack] : [];

  const item = equipped[slot];
  if (!item || !item.itemId) {
    throw new HttpsError('not-found', `No item equipped in slot: ${slot}`);
  }

  // 1. Remove from equipped
  equipped[slot] = null;

  // 2. Add to backpack
  backpack.push({
    itemId: item.itemId,
    craftedStats: item.craftedStats || {},
    quantity: 1,
    unequippedFromSlot: slot,
    unequippedAt: admin.firestore.Timestamp.now(),
  });

  // ✅ 3. Recalculate full combat stats
  const { attackMin, attackMax, attackSpeedMs, defense } = calculateHeroCombatStats(hero.stats, equipped);

  // ✅ 4. Recalculate weight + speed
  const currentWeight = calculateHeroWeight(equipped, backpack);
  const baseSpeed = hero.baseMovementSpeed ?? hero.movementSpeed ?? 1200;
  const carryCapacity = hero.carryCapacity ?? 100;
  const movementSpeed = calculateAdjustedMovementSpeed(baseSpeed, currentWeight, carryCapacity);

  const batch = db.batch();

  batch.update(heroRef, {
    equipped,
    backpack,
    combat: {
      ...hero.combat,
      attackMin,
      attackMax,
      attackSpeedMs,
      defense,
    },
    currentWeight,
    movementSpeed,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();

  console.log(`🎒 Unequipped ${item.itemId} from ${slot} → backpack for hero ${heroId}`);

  return {
    success: true,
    unequippedSlot: slot,
    updatedStats: {
      attackMin,
      attackMax,
      attackSpeedMs,
      defense,
      currentWeight,
      movementSpeed,
    },
  };
}
