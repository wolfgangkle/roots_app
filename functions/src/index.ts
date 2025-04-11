import * as admin from 'firebase-admin';
import { onCall } from 'firebase-functions/v2/https';
import * as functions from 'firebase-functions';

import { createHeroLogic } from './heroes/createHero.js';
import { startHeroMovements } from './heroes/startHeroMovements.js'; // ✅ Newly added function

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
export const createHero = onCall(createHeroLogic);

/**
 * 🚶 startHeroMovements (NEW)
 */
export const startHeroMovementsFunction = onCall(startHeroMovements);

/**
 * 🏕️ foundVillage
 */
export const foundVillage = onCall(async (request) => {
  const { foundVillageLogic } = await import('./village/foundVillage.js');
  return foundVillageLogic(request);
});

/**
 * ⏰ finishBuildingUpgradeScheduled (Cloud Task HTTP endpoint)
 */
export const finishBuildingUpgradeScheduled = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const { userId, villageId } = req.body;
    if (!userId || !villageId) {
      res.status(400).send('Missing userId or villageId in request body.');
      return;
    }

    const { finishBuildingUpgradeLogic } = await import('./village/finishBuildingUpgrade.js');
    const fakeRequest = {
      data: { villageId },
      auth: { uid: userId },
    };

    const result = await finishBuildingUpgradeLogic(fakeRequest as any);

    console.log(`✅ Scheduled upgrade executed for village ${villageId}`);
    res.status(200).json({ success: true, result });
  } catch (error: any) {
    console.error('❌ Scheduled upgrade error:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * 🧙 processHeroArrival (Cloud Task HTTP endpoint)
 */
export const processHeroArrival = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const { heroId } = req.body;
    if (!heroId) {
      res.status(400).send('Missing heroId in request body.');
      return;
    }

    const { processHeroArrival } = await import('./heroes/processHeroArrival.js');
    return processHeroArrival(req, res);
  } catch (error: any) {
    console.error('❌ Scheduled hero arrival error:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});
