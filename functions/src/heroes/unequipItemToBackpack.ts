import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

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

  // Remove from equipped
  equipped[slot] = null;

  // Add to backpack
  backpack.push({
    itemId: item.itemId,
    craftedStats: item.craftedStats || {},
    quantity: 1,
    unequippedFromSlot: slot,
    unequippedAt: admin.firestore.Timestamp.now(),
  });

  // Recalculate combat stats
  let attackMin = 5;
  let attackMax = 10;
  let defense = 0;
  let weight = 0;

  for (const s of validSlots) {
    const equippedItem = equipped[s];
    if (equippedItem?.craftedStats) {
      attackMin += equippedItem.craftedStats.attackMin ?? 0;
      attackMax += equippedItem.craftedStats.attackMax ?? 0;
      defense += equippedItem.craftedStats.defense ?? 0;
      weight += equippedItem.craftedStats.weight ?? 0;
    }
  }

  const batch = db.batch();

  batch.update(heroRef, {
    equipped,
    backpack,
    combat: {
      ...hero.combat,
      attackMin,
      attackMax,
      defense,
    },
    totalWeight: weight,
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
      defense,
      weight,
    },
  };
}
