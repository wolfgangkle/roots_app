import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { updateHeroStats } from '../helpers/updateHeroStats';

const db = admin.firestore();

export async function equipHeroItem(request: any) {
  const { heroId, villageId, tileKey, itemDocId, slot } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!heroId || typeof heroId !== 'string') throw new HttpsError('invalid-argument', 'Missing heroId.');
  if (!itemDocId || typeof itemDocId !== 'string') throw new HttpsError('invalid-argument', 'Missing itemDocId.');
  if (!slot || typeof slot !== 'string') throw new HttpsError('invalid-argument', 'Missing or invalid slot.');

  const validSlots = ['mainHand', 'offHand', 'helmet', 'chest', 'legs', 'arms', 'belt', 'feet'];
  if (!validSlots.includes(slot)) {
    throw new HttpsError('invalid-argument', `Invalid slot: ${slot}`);
  }

  const heroRef = db.collection('heroes').doc(heroId);
  const sourceItemRef = villageId
    ? db.collection('users').doc(userId).collection('villages').doc(villageId).collection('items').doc(itemDocId)
    : tileKey
      ? db.collection('mapTiles').doc(tileKey).collection('items').doc(itemDocId)
      : null;

  if (!sourceItemRef) {
    throw new HttpsError('invalid-argument', 'Either villageId or tileKey must be provided.');
  }

  const [heroSnap, itemSnap] = await Promise.all([
    heroRef.get(),
    sourceItemRef.get(),
  ]);

  if (!heroSnap.exists) throw new HttpsError('not-found', 'Hero not found.');
  if (!itemSnap.exists) throw new HttpsError('not-found', 'Item not found at source.');

  const heroData = heroSnap.data()!;
  const itemData = itemSnap.data()!;
  const itemId = itemData.itemId;
  const craftedStats = itemData.craftedStats || {};
  const equipSlot = itemData.equipSlot?.toString().toLowerCase() ?? 'main_hand';

  const equipped = { ...(heroData.equipped || {}) };
  const oldItem = equipped[slot] || null;

  // Prevent equipping offHand with two-hander in mainHand
  const mainHandItemId = equipped['mainHand']?.itemId;
  const mainHandEquipSlot = equipped['mainHand']?.equipSlot ?? null;
  if (slot === 'offHand' && mainHandItemId && mainHandEquipSlot === 'two_hand') {
    throw new HttpsError('failed-precondition', 'Cannot equip offhand item while using a two-handed weapon.');
  }

  const batch = db.batch();

  // 1. If equipping a two-hander, unequip offHand and return it
  if (slot === 'mainHand' && equipSlot === 'two_hand' && equipped['offHand']?.itemId && villageId) {
    const unequippedItem = equipped['offHand'];
    const backToVillage = db
      .collection('users')
      .doc(userId)
      .collection('villages')
      .doc(villageId)
      .collection('items')
      .doc();

    batch.set(backToVillage, {
      itemId: unequippedItem.itemId,
      craftedStats: unequippedItem.craftedStats || {},
      quantity: 1,
      movedFromHeroId: heroId,
      movedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    equipped['offHand'] = null;
  }

  // 2. Return previously equipped item
  if (oldItem?.itemId) {
    const returnToRef = villageId
      ? db.collection('users').doc(userId).collection('villages').doc(villageId).collection('items').doc()
      : tileKey
        ? db.collection('mapTiles').doc(tileKey).collection('items').doc()
        : null;

    if (returnToRef) {
      batch.set(returnToRef, {
        itemId: oldItem.itemId,
        craftedStats: oldItem.craftedStats || {},
        quantity: 1,
        movedFromHeroId: heroId,
        movedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  // 3. Remove item from source
  batch.delete(sourceItemRef);

  // 4. Equip the new item
  equipped[slot] = {
    itemId,
    craftedStats,
    equipSlot,
  };

  // 5. Write equipped changes first
  batch.update(heroRef, {
    equipped,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();

  // 6. Recalculate stats and sync group
  await updateHeroStats(heroId);

  console.log(`🛡 Hero ${heroId} equipped ${itemId} from ${villageId ? 'village' : tileKey} to slot ${slot}.`);

  return {
    success: true,
    equippedSlot: slot,
  };
}
