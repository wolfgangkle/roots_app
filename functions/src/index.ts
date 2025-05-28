import * as admin from 'firebase-admin';
import { onCall, onRequest, Request } from 'firebase-functions/v2/https';
import type { Response } from 'express';

import { startHeroMovements } from './heroes/startHeroMovements.js';
import { processHeroArrivalCallableLogic } from './heroes/processHeroArrival.js';
import { processCombatTick } from './combat/processCombatTick.js';

admin.initializeApp();

// === Village Management ===
export const createVillage = onCall(async (request) => {
  const { createVillageLogic } = await import('./village/createVillage.js');
  return createVillageLogic(request);
});

export const updateVillageResources = onCall(async (request) => {
  const { updateVillageResourcesLogic } = await import('./village/updateResources.js');
  return updateVillageResourcesLogic(request);
});

export const finishBuildingUpgrade = onCall(async (request) => {
  const { finishBuildingUpgradeLogic } = await import('./village/finishBuildingUpgrade.js');
  return finishBuildingUpgradeLogic(request);
});

export const startBuildingUpgrade = onCall(async (request) => {
  const { startBuildingUpgradeLogic } = await import('./village/startBuildingUpgrade.js');
  return startBuildingUpgradeLogic(request);
});

export const assignWorkerToBuilding = onCall(async (request) => {
  const { assignWorkerToBuilding: logic } = await import('./village/assignWorkerToBuilding.js');
  return logic(request);
});

export const devFinishNow = onCall(async (request) => {
  const { devFinishNowLogic } = await import('./village/devFinishNow.js');
  return devFinishNowLogic(request);
});

export const executeTrade = onCall(async (request) => {
  const { executeTrade } = await import('./village/executeTrade.js');
  return executeTrade(request);
});



// === Onboarding ===
export const finalizeOnboarding = onCall(async (request) => {
  const { finalizeOnboardingLogic } = await import('./onboarding/finalizeOnboarding.js');
  return finalizeOnboardingLogic(request);
});

// === Heroes ===
export const createHero = onCall(async (request) => {
  const { createHeroLogic } = await import('./heroes/createHero.js');
  return createHeroLogic(request);
});

export const createCompanion = onCall(async (request) => {
  const { createCompanionLogic } = await import('./heroes/createCompanion.js');
  return createCompanionLogic(request);
});

export const connectHeroToGroup = onCall(async (request) => {
  const { connectHeroToGroupLogic } = await import('./heroes/connectHeroToGroup.js');
  return connectHeroToGroupLogic(request);
});

export const disconnectHeroFromGroup = onCall(async (request) => {
  const { disconnectHeroFromGroupLogic } = await import('./heroes/disconnectHeroFromGroup.js');
  return disconnectHeroFromGroupLogic(request);
});

export const kickHeroFromGroup = onCall(async (request) => {
  const { kickHeroFromGroupLogic } = await import('./heroes/kickHeroFromGroup.js');
  return kickHeroFromGroupLogic(request);
});

export const equipHeroItem = onCall(async (request) => {
  const { equipHeroItem } = await import('./heroes/equipHeroItem.js');
  return equipHeroItem(request);
});

export const dropHeroItem = onCall(async (request) => {
  const { dropHeroItem } = await import('./heroes/dropHeroItem.js');
  return dropHeroItem(request);
});

export const equipItemFromBackpack = onCall(async (request) => {
  const { equipItemFromBackpack } = await import('./heroes/equipItemFromBackpack.js');
  return equipItemFromBackpack(request);
});

export const storeItemInBackpack = onCall(async (request) => {
  const { storeItemInBackpack } = await import('./heroes/storeItemInBackpack.js');
  return storeItemInBackpack(request);
});

export const unequipItemToBackpack = onCall(async (request) => {
  const { unequipItemToBackpack } = await import('./heroes/unequipItemToBackpack.js');
  return unequipItemToBackpack(request);
});

export const dropItemFromSlot = onCall(async (request) => {
  const { dropItemFromSlot } = await import('./heroes/dropItemFromSlot.js');
  return dropItemFromSlot(request);
});

export const transferHeroResources = onCall(async (request) => {
  const { transferHeroResources } = await import('./heroes/transferHeroResources.js');
  return transferHeroResources(request);
});

export const startHeroMovementsFunction = onCall(startHeroMovements);

export const processHeroArrivalCallable = onCall(processHeroArrivalCallableLogic);

// === Crafting ===
export const startCraftingJob = onCall(async (request) => {
  const { startCraftingJobLogic } = await import('./crafting/startCraftingJob.js');
  return startCraftingJobLogic(request);
});

export const finishCraftingJob = onCall(async (request) => {
  const { finishCraftingJobLogic } = await import('./crafting/finishCraftingJob.js');
  return finishCraftingJobLogic(request);
});

export { finishCraftingJobScheduled } from './crafting/finishCraftingJobScheduled.js';



// === Guilds ===
export const createGuild = onCall(async (request) => {
  const { createGuild } = await import('./guilds/createGuild.js');
  return createGuild(request);
});

export const sendGuildInvite = onCall(async (request) => {
  const { sendGuildInvite } = await import('./guilds/sendGuildInvite.js');
  return sendGuildInvite(request);
});

export const leaveGuild = onCall(async (request) => {
  const { leaveGuild } = await import('./guilds/leaveGuild.js');
  return leaveGuild(request);
});

export const disbandGuild = onCall(async (request) => {
  const { disbandGuild } = await import('./guilds/disbandGuild.js');
  return disbandGuild(request);
});

export const updateGuildDescription = onCall(async (request) => {
  const { updateGuildDescription } = await import('./guilds/updateGuildDescription.js');
  return updateGuildDescription(request);
});

export const acceptGuildInvite = onCall(async (request) => {
  const { acceptGuildInvite } = await import('./guilds/acceptGuildInvite.js');
  return acceptGuildInvite(request);
});

export const updateGuildRole = onCall(async (request) => {
  const { updateGuildRole } = await import('./guilds/updateGuildRole.js');
  return updateGuildRole(request);
});

// === Alliances ===
export const createAlliance = onCall(async (request) => {
  const { createAlliance } = await import('./alliances/createAlliance.js');
  return createAlliance(request);
});

export const sendAllianceInvite = onCall(async (request) => {
  const { sendAllianceInvite } = await import('./alliances/sendAllianceInvite.js');
  return sendAllianceInvite(request);
});

export const acceptAllianceInvite = onCall(async (request) => {
  const { acceptAllianceInvite } = await import('./alliances/acceptAllianceInvite.js');
  return acceptAllianceInvite(request);
});

export const leaveAlliance = onCall(async (request) => {
  const { leaveAlliance } = await import('./alliances/leaveAlliance.js');
  return leaveAlliance(request);
});

export const disbandAlliance = onCall(async (request) => {
  const { disbandAlliance } = await import('./alliances/disbandAlliance.js');
  return disbandAlliance(request);
});

export const kickGuildFromAlliance = onCall(async (request) => {
  const { kickGuildFromAlliance } = await import('./alliances/kickGuildFromAlliance.js');
  return kickGuildFromAlliance(request);
});

export const updateAllianceDescription = onCall(async (request) => {
  const { updateAllianceDescription } = await import('./alliances/updateAllianceDescription.js');
  return updateAllianceDescription(request);
});


// === AI Event Generators ===
export { generatePeacefulEventFromAI } from './events/generatePeacefulEventFromAI.js';
export { generateCombatEventFromAI } from './events/generateCombatEventFromAI.js';

// === HTTP Scheduled Tasks ===
export const processHeroArrival = onRequest(async (req: Request, res: Response) => {
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

export const finishBuildingUpgradeScheduled = onRequest(async (req: Request, res: Response) => {
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

export const processCombatTickScheduled = onRequest(processCombatTick);
