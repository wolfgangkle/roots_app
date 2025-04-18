import { onCall, CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * 🧠 Pure logic for finishing a crafting job.
 * Safe to call via HTTP (Cloud Task) or manually (client).
 */
export async function finishCraftingJobLogic(request: CallableRequest<any>) {
  const { villageId } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!villageId) throw new HttpsError('invalid-argument', 'villageId is required.');

  const villageRef = db.collection('users').doc(userId).collection('villages').doc(villageId);
  const doc = await villageRef.get();
  if (!doc.exists) throw new HttpsError('not-found', 'Village not found.');

  const data = doc.data()!;
  const craftingJob = data.currentCraftingJob;
  const lastCheck = (data.lastCraftingCheck instanceof admin.firestore.Timestamp)
    ? data.lastCraftingCheck.toDate()
    : new Date(0);
  const now = new Date();

  // ⏱️ Throttle repeat finishes
  const secondsSinceLastCheck = (now.getTime() - lastCheck.getTime()) / 1000;
  if (secondsSinceLastCheck < 10) {
    console.log(`⏱️ Throttled: ${villageId} checked ${secondsSinceLastCheck.toFixed(2)}s ago`);
    return { throttled: true, secondsSinceLastCheck };
  }

  if (!craftingJob) {
    console.log(`👻 No crafting job found for ${villageId}, probably already finished.`);
    await villageRef.update({
      lastCraftingCheck: admin.firestore.Timestamp.fromDate(now),
    });
    return { message: 'No crafting job in progress (possibly already completed).' };
  }

  const startedAt = (craftingJob.startedAt instanceof admin.firestore.Timestamp)
    ? craftingJob.startedAt.toDate()
    : new Date(0);
  const duration = craftingJob.durationSeconds || 0;
  const finishTime = new Date(startedAt.getTime() + duration * 1000);

  if (now < finishTime) {
    return { message: 'Crafting job is not complete yet.' };
  }

  // 🎯 Apply result to village inventory
  const { itemId, quantity, craftedStats } = craftingJob;
  const itemsRef = villageRef.collection('items');

  const existingQuery = await itemsRef
    .where('itemId', '==', itemId)
    .where('craftedStats.damage', '==', craftedStats.damage)
    .where('craftedStats.balance', '==', craftedStats.balance)
    .where('craftedStats.weight', '==', craftedStats.weight)
    .limit(1)
    .get();

  if (!existingQuery.empty) {
    // 🔁 Merge stack
    await existingQuery.docs[0].ref.update({
      quantity: admin.firestore.FieldValue.increment(quantity)
    });
  } else {
    // ➕ New stack
    await itemsRef.add({
      itemId,
      quantity,
      craftedStats,
      craftedAt: admin.firestore.Timestamp.now(),
      craftedByVillageId: villageId
    });
  }

  // 🧹 Clean up crafting job
  await villageRef.update({
    currentCraftingJob: admin.firestore.FieldValue.delete(),
    lastCraftingCheck: admin.firestore.Timestamp.fromDate(now),
    lastCraftingMethod: request.auth?.uid ? 'onCall' : 'scheduled'
  });

  console.log(`✅ Finished crafting ${quantity}x ${itemId} for village ${villageId}`);

  return {
    finished: true,
    itemId,
    quantity,
    craftedStats
  };
}

export const finishCraftingJob = onCall(finishCraftingJobLogic);
