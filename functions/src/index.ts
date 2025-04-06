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

/**
 * 🌱 finalizeOnboarding
 */
export const finalizeOnboarding = onCall(async (request) => {
  const { finalizeOnboardingLogic } = await import('./onboarding/finalizeOnboarding.js');
  return finalizeOnboardingLogic(request);
});


/**
 * 🌱 createHero
 */

export const createHero = onCall(async (request) => {
  const { createHeroLogic } = await import(`${__dirname}/hero/createHero.js`);
  return createHeroLogic(request);
});



/**
 * 🏕️ foundVillage
 */
export const foundVillage = onCall(async (request) => {
  const { foundVillageLogic } = await import('./village/foundVillage.js');
  return foundVillageLogic(request);
});
