import * as admin from 'firebase-admin';
import { onCall } from 'firebase-functions/v2/https';
import * as functions from 'firebase-functions';

import { createHeroLogic } from './heroes/createHero.js';
import { startHeroMovements } from './heroes/startHeroMovements.js';
import { processHeroArrivalCallableLogic } from './heroes/processHeroArrival.js';
import { processCombatTick } from './combat/processCombatTick.js'; // ⚔️ New combat tick logic
import { transferHeroResources } from './heroes/transferHeroResources.js';


admin.initializeApp();


/**
 * 🏰 createVillage (New callable for founding a village from hero position)
 */
export const createVillage = onCall(async (request) => {
  const { createVillageLogic } = await import('./village/createVillage.js');
  return createVillageLogic(request);
});



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
 * 👥 createCompanion
 */
export const createCompanion = onCall(async (request) => {
  const { createCompanionLogic } = await import('./heroes/createCompanion.js');
  return createCompanionLogic(request);
});




/**
 * 🧩 connectHeroToGroup
 */
export const connectHeroToGroup = onCall(async (request) => {
  const { connectHeroToGroupLogic } = await import('./heroes/connectHeroToGroup.js');
  return connectHeroToGroupLogic(request);
});



/**
 * 🧹 disconnectHeroFromGroup
 */
export const disconnectHeroFromGroup = onCall(async (request) => {
  const { disconnectHeroFromGroupLogic } = await import('./heroes/disconnectHeroFromGroup.js');
  return disconnectHeroFromGroupLogic(request);
});



/**
 * 🥾 kickHeroFromGroup
 */
export const kickHeroFromGroup = onCall(async (request) => {
  const { kickHeroFromGroupLogic } = await import('./heroes/kickHeroFromGroup.js');
  return kickHeroFromGroupLogic(request);
});




/**
 * 🚶 startHeroMovements (NEW)
 */
export const startHeroMovementsFunction = onCall(startHeroMovements);


/**
 * 📦 transferHeroResources
 */
export const transferHeroResourcesFunction = onCall(transferHeroResources);



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
 * 🧙 processHeroArrival (Dart fallback)
 */
export const processHeroArrivalCallable = onCall(processHeroArrivalCallableLogic);

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

/**
 * ⚔️ processCombatTick (Cloud Task HTTP endpoint)
 */
export const processCombatTickScheduled = functions.https.onRequest(processCombatTick);
