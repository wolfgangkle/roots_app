import { onCall, CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { scheduleCraftingTask } from '../utils/scheduleCraftingTask.js';

const db = admin.firestore();

export async function startCraftingJobLogic(request: CallableRequest<any>) {
  const { villageId, itemId, quantity = 1 } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!villageId || !itemId) {
    throw new HttpsError('invalid-argument', 'villageId and itemId are required.');
  }

  const villageRef = db.collection('users').doc(userId).collection('villages').doc(villageId);
  const [villageSnap, itemSnap] = await Promise.all([
    villageRef.get(),
    db.collection('items').doc(itemId).get()
  ]);

  if (!villageSnap.exists) throw new HttpsError('not-found', 'Village not found.');
  if (!itemSnap.exists) throw new HttpsError('not-found', 'Item not found.');

  const villageData = villageSnap.data()!;
  const itemData = itemSnap.data()!;
  const research = villageData.research?.[itemId] || { damage: 0, balance: 0, weight: 0 };
  const existingJob = villageData.currentCraftingJob;

  if (existingJob) {
    throw new HttpsError('failed-precondition', 'Another crafting job is already active.');
  }

  const craftedStats = {
    damage: research.damage || 0,
    balance: research.balance || 0,
    weight: research.weight || 0,
  };

  // 🔧 Calculate total cost
  const resourceCost = itemData.craftingCost || {};
  const totalCost: Record<string, number> = {};
  for (const key in resourceCost) {
    totalCost[key] = resourceCost[key] * quantity;
  }

  const resources = villageData.resources || {};

  // ✅ Check resources
  for (const key in totalCost) {
    if ((resources[key] || 0) < totalCost[key]) {
      throw new HttpsError('failed-precondition', `Not enough ${key}`);
    }
  }

  // 💸 Deduct resources
  const newResources = { ...resources };
  for (const key in totalCost) {
    newResources[key] -= totalCost[key];
  }

  // 🕒 Set up crafting job
  const durationSeconds: number = itemData.buildTime || 60; // fallback to 60s if not defined
  const now = new Date();
  const startedAt = admin.firestore.Timestamp.fromDate(now);

  const craftingJob = {
    itemId,
    quantity,
    craftedStats,
    startedAt,
    durationSeconds
  };

  await villageRef.update({
    resources: newResources,
    currentCraftingJob: craftingJob,
    lastCraftingCheck: startedAt
  });

  // ⏰ Schedule crafting completion
  await scheduleCraftingTask({
    userId,
    villageId,
    delaySeconds: durationSeconds
  });

  console.log(`⏳ Started crafting ${quantity}x ${itemId} for ${villageId} (${durationSeconds}s)`);

  return {
    started: true,
    itemId,
    quantity,
    craftedStats,
    durationSeconds,
    newResources
  };
}

export const startCraftingJob = onCall(startCraftingJobLogic);
