import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { updateHeroStats } from '../helpers/updateHeroStats';

const db = admin.firestore();

export async function equipItemFromBackpack(request: any) {
  const { heroId, backpackIndex, slot } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!heroId || typeof heroId !== 'string') throw new HttpsError('invalid-argument', 'Missing heroId.');
  if (typeof backpackIndex !== 'number') throw new HttpsError('invalid-argument', 'Missing backpackIndex.');
  if (!slot || typeof slot !== 'string') throw new HttpsError('invalid-argument', 'Missing slot.');

  const validSlots = ['mainHand', 'offHand', 'helmet', 'chest', 'legs', 'arms', 'belt', 'feet'];
  if (!validSlots.includes(slot)) {
    throw new HttpsError('invalid-argument', `Invalid slot: ${slot}`);
  }

  const heroRef = db.collection('heroes').doc(heroId);
  const heroSnap = await heroRef.get();
  if (!heroSnap.exists) throw new HttpsError('not-found', 'Hero not found.');

  const hero = heroSnap.data()!;
  const backpack = Array.isArray(hero.backpack) ? [...hero.backpack] : [];
  const equipped = { ...(hero.equipped || {}) };

  const item = backpack[backpackIndex];
  if (!item || !item.itemId) {
    throw new HttpsError('not-found', 'Item not found in backpack.');
  }

  const itemId = item.itemId;
  const craftedStats = item.craftedStats || {};
  const equipSlot = item.equipSlot?.toString().toLowerCase() ?? 'main_hand';

  if (equipSlot !== slot.toLowerCase()) {
    console.warn(`⚠️ Slot mismatch: trying to equip ${itemId} with slot ${equipSlot} into ${slot}`);
  }

  const oldEquippedItem = equipped[slot];

  // Remove item from backpack
  backpack.splice(backpackIndex, 1);

  // Equip new item
  equipped[slot] = {
    itemId,
    craftedStats,
    equipSlot,
  };

  // Return previously equipped item (if any) back to backpack
  if (oldEquippedItem?.itemId) {
    backpack.push({
      itemId: oldEquippedItem.itemId,
      craftedStats: oldEquippedItem.craftedStats || {},
      quantity: 1,
      returnedFromSlot: slot,
    });
  }

  // Update hero inventory and equipped state first
  await heroRef.update({
    equipped,
    backpack,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Use centralized helper to recalculate stats and group state
  await updateHeroStats(heroId);

  console.log(`🛡 Hero ${heroId} equipped ${itemId} to slot ${slot} from backpack`);

  return {
    success: true,
    equippedSlot: slot,
  };
}
