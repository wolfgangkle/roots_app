// functions/src/index.ts
import * as admin from 'firebase-admin';
import { onCall } from 'firebase-functions/v2/https';

admin.initializeApp();

/**
 * 📦 updateVillageResources
 */
export const updateVillageResources = onCall(async (request) => {
  const { updateVillageResourcesLogic } = await import('./village/updateResources.js');
  return updateVillageResourcesLogic(request);
});

/**
 * 🏗️ finishBuildingUpgrade
 */
export const finishBuildingUpgrade = onCall(async (request) => {
  const { finishBuildingUpgradeLogic } = await import('./village/finishBuildingUpgrade.js');
  return finishBuildingUpgradeLogic(request);
});

/**
 * 🛠️ startBuildingUpgrade
 */
export const startBuildingUpgrade = onCall(async (request) => {
  const { startBuildingUpgradeLogic } = await import('./village/startBuildingUpgrade.js');
  return startBuildingUpgradeLogic(request);
});
