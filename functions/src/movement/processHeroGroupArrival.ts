import * as admin from 'firebase-admin';
import { applyMovementStep } from './applyMovementStep.js';
import { maybeContinueGroupMovement } from './maybeContinueGroupMovement.js';
import { maybeTriggerPveEvent } from './maybeTriggerPveEvent.js';
import { createPveEvent } from './createPveEvent.js';
import { handleTriggeredPveEvent } from './handleTriggeredPveEvent.js';
import { HeroGroupData } from '../types/heroGroupData.js'; // 👈 make sure this path is correct

const db = admin.firestore();

export async function processHeroGroupArrival(groupId: string) {
  console.log(`📦 processHeroGroupArrival(${groupId}) started`);

  const groupRef = db.collection('heroGroups').doc(groupId);
  const groupSnap = await groupRef.get();

  if (!groupSnap.exists) {
    console.warn(`❌ Group ${groupId} not found.`);
    return;
  }

  const group = groupSnap.data()!;
  console.log(`📄 Group data loaded. State: ${group.state}, Returning: ${group.returning}, Waypoints: ${group.waypoints?.length ?? 0}`);

  // 🏠 Handle returning logic
  if (group.returning) {
    console.log(`🏠 Group ${groupId} is returning. Skipping PvE.`);
    await groupRef.update({ returning: admin.firestore.FieldValue.delete() });

    try {
      const result = await applyMovementStep(groupId);
      if (!result) {
        console.warn(`⚠️ Movement failed for returning group ${groupId}`);
        return;
      }
      console.log(`😌 Group ${groupId} returned to (${result.tileX}, ${result.tileY})`);
    } catch (err: any) {
      console.error(`🔥 Error during return movement: ${err.message}`);
      return;
    }

    await maybeContinueGroupMovement(groupId);
    return;
  }

  // ⚠️ Only allow execution if in 'moving' or 'arrived' state
  if (group.state !== 'arrived' && group.state !== 'moving') {
    console.log(`⏩ Group ${groupId} is not in 'moving' or 'arrived' state (${group.state}). Skipping.`);
    return;
  }

  // 🧭 Apply movement and transition to new tile
  let movementResult;
  try {
    movementResult = await applyMovementStep(groupId);
    if (!movementResult) {
      console.warn(`❌ Movement failed for group ${groupId}`);
      return;
    }
  } catch (err: any) {
    console.error(`🔥 Error during applyMovementStep: ${err.message}`);
    return;
  }

  // 🔍 Reload updated group
  const updatedSnap = await groupRef.get();
  const updatedGroup = updatedSnap.data() as HeroGroupData; // ✅ Cast here
  console.log(`🧠 Group ${groupId} is now at ${updatedGroup.tileX}_${updatedGroup.tileY} and ready for PvE roll.`);

  // 🎲 Try triggering a PvE event
  const triggerInfo = await maybeTriggerPveEvent(updatedGroup);
  if (triggerInfo.shouldTrigger) {
    try {
      console.log(`⚠️ Triggering PvE event: ${triggerInfo.type}, Level ${triggerInfo.level}`);
      const eventResult = await createPveEvent(groupId, updatedGroup, triggerInfo.type!, triggerInfo.level!);
      console.log(`📜 PvE event created: ${eventResult.combatId ?? eventResult.peacefulReportId}`);
      await handleTriggeredPveEvent(eventResult, updatedGroup);
      console.log(`🏁 PvE event handled successfully.`);
      return; // ✅ Stop after event
    } catch (err: any) {
      console.error(`❌ Failed to create/handle PvE event: ${err.message}`);
      // Optionally: continue movement anyway
    }
  }

  // 🏃 No PvE triggered → continue
  await maybeContinueGroupMovement(groupId);
}
