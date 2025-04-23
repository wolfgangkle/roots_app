import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

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

  // Add to backpack
  backpack.push({
    itemId,
    craftedStats,
    quantity,
    movedFrom: villageId ? 'village' : tileKey,
    movedAt: admin.firestore.Timestamp.now(),
  });

  const batch = db.batch();

  // Remove the item from the tile or village
  batch.delete(sourceRef);

  // Update the backpack
  batch.update(heroRef, {
    backpack,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();

  console.log(`🎒 Hero ${heroId} picked up ${quantity}x ${itemId} into backpack from ${villageId ?? tileKey}`);

  return {
    success: true,
    itemId,
    quantity,
    source: villageId ?? tileKey,
  };
}
