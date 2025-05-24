import { onCall, CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { recalculateProduction } from '../utils/recalculateProduction.js';

const db = admin.firestore();

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

  const buildings = dataObj.buildings || {};
  const maxProduction = dataObj.maxProductionPerHour || {};
  const resources: Record<string, number> = dataObj.resources || {};

  const currentProduction = recalculateProduction(buildings, maxProduction);

  const gain = {
    wood: Math.floor((currentProduction.wood || 0) * (elapsedMinutes / 60)),
    stone: Math.floor((currentProduction.stone || 0) * (elapsedMinutes / 60)),
    food: Math.floor((currentProduction.food || 0) * (elapsedMinutes / 60)),
    iron: Math.floor((currentProduction.iron || 0) * (elapsedMinutes / 60)),
    gold: Math.floor((currentProduction.gold || 0) * (elapsedMinutes / 60)),
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
    currentProductionPerHour: currentProduction, // ✅ saved now
    lastUpdated: admin.firestore.Timestamp.fromDate(now),
  });

  return {
    updated: true,
    newResources: updatedResources,
    currentProductionPerHour: currentProduction,
    elapsedMinutes: elapsedMinutes.toFixed(2),
  };
}

export const updateVillageResources = onCall(updateVillageResourcesLogic);
