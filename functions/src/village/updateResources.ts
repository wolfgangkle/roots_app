// functions/src/village/updateResources.ts
import { onCall, CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * 🧠 Core logic for updating village resources based on elapsed time
 */
export async function updateVillageResourcesLogic(request: CallableRequest<any>) {
  const { villageId } = request.data;
  const userId = request.auth?.uid;

  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');
  if (!villageId) throw new HttpsError('invalid-argument', 'villageId is required.');

  const villageRef = db
    .collection('users')
    .doc(userId)
    .collection('villages')
    .doc(villageId);

  const doc = await villageRef.get();
  if (!doc.exists) throw new HttpsError('not-found', 'Village not found.');

  const dataObj = doc.data()!;
  const lastUpdated = dataObj.lastUpdated?.toDate?.() ?? new Date(0);
  const now = new Date();

  const elapsedMinutes = (now.getTime() - lastUpdated.getTime()) / 60000;
  if (elapsedMinutes < 0.17) {
    console.log(`⏳ Skipped update for ${villageId}, only ${elapsedMinutes.toFixed(2)} min elapsed`);
    return { message: 'Not enough time elapsed.' };
  }

  const production: Record<string, number> = dataObj.productionPerHour || {};
  const resources: Record<string, number> = dataObj.resources || {};

  if (Object.keys(production).length === 0) {
    console.warn(`⚠️ No production defined for ${villageId}`);
    return { message: 'No production data available.' };
  }

  const gain = {
    wood: Math.floor((production.wood || 0) * (elapsedMinutes / 60)),
    stone: Math.floor((production.stone || 0) * (elapsedMinutes / 60)),
    food: Math.floor((production.food || 0) * (elapsedMinutes / 60)),
    iron: Math.floor((production.iron || 0) * (elapsedMinutes / 60)),
    gold: Math.floor((production.gold || 0) * (elapsedMinutes / 60)),
  };

  const updatedResources = {
    wood: (resources.wood || 0) + gain.wood,
    stone: (resources.stone || 0) + gain.stone,
    food: (resources.food || 0) + gain.food,
    iron: (resources.iron || 0) + gain.iron,
    gold: (resources.gold || 0) + gain.gold,
  };

  console.log(`🌾 Updated village ${villageId} after ${elapsedMinutes.toFixed(1)} min:`, gain);

  await villageRef.update({
    resources: updatedResources,
    lastUpdated: admin.firestore.Timestamp.fromDate(now),
  });

  return {
    updated: true,
    newResources: updatedResources,
    elapsedMinutes: elapsedMinutes.toFixed(2),
  };
}

/**
 * 📦 Firebase callable function export
 */
export const updateVillageResources = onCall(updateVillageResourcesLogic);
