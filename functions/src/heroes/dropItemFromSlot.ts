import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { updateHeroStats } from '../helpers/updateHeroStats';

const db = admin.firestore();

export async function dropItemFromSlot(request: any) {
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
  const equipped = { ...(hero.equipped || {}) };
  const item = equipped[slot];

  if (!item || !item.itemId) {
    throw new HttpsError('not-found', `No item equipped in slot: ${slot}`);
  }

  const itemId = item.itemId;
  const craftedStats = item.craftedStats || {};
  const equipSlot = item.equipSlot?.toString().toLowerCase() ?? null; // ✅ Ensure equipSlot is preserved

  const dropToRef = villageId
    ? db.collection('users').doc(userId).collection('villages').doc(villageId).collection('items').doc()
    : tileKey
      ? db.collection('mapTiles').doc(tileKey).collection('items').doc()
      : null;

  if (!dropToRef) {
    throw new HttpsError('invalid-argument', 'Either villageId or tileKey must be provided.');
  }

  // 1. Remove item from equipment
  equipped[slot] = null;

  // 2. Drop the item into world or village
  const batch = db.batch();
  batch.set(dropToRef, {
    itemId,
    craftedStats,
    equipSlot, // ✅ Add it here
    quantity: 1,
    droppedByHero: heroId,
    droppedAt: admin.firestore.FieldValue.serverTimestamp(),
    droppedFromSlot: slot,
  });

  // 3. Save equipped state before stat recalculation
  batch.update(heroRef, {
    equipped,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();

  // 4. Update all hero and group stats centrally
  await updateHeroStats(heroId);

  console.log(`📦 Dropped ${itemId} from slot ${slot} to ${villageId ?? tileKey} (hero: ${heroId})`);

  return {
    success: true,
    droppedSlot: slot,
    itemId,
  };
}
