import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { updateHeroStats } from '../helpers/updateHeroStats';

const db = admin.firestore();

export async function unequipItemToBackpack(request: any) {
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
  const equipped = { ...(hero.equipped || {}) };
  const backpack = Array.isArray(hero.backpack) ? [...hero.backpack] : [];

  const item = equipped[slot];
  if (!item || !item.itemId) {
    throw new HttpsError('not-found', `No item equipped in slot: ${slot}`);
  }

  // Remove item from equipped
  equipped[slot] = null;

  // Add to backpack
  backpack.push({
    itemId: item.itemId,
    craftedStats: item.craftedStats || {},
    equipSlot: item.equipSlot ?? null, // ✅ Preserve equipSlot
    quantity: 1,
    unequippedFromSlot: slot,
    unequippedAt: admin.firestore.Timestamp.now(),
  });

  // Write equipped + backpack update first
  await heroRef.update({
    equipped,
    backpack,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Centralized stat update for hero and group
  await updateHeroStats(heroId);

  console.log(`🎒 Unequipped ${item.itemId} from ${slot} → backpack for hero ${heroId}`);

  return {
    success: true,
    unequippedSlot: slot,
  };
}
