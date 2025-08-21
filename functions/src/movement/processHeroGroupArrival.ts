import * as admin from 'firebase-admin';
import { applyMovementStep } from './applyMovementStep.js';
import { maybeContinueGroupMovement } from './maybeContinueGroupMovement.js';
import { maybeTriggerPveEvent } from './maybeTriggerPveEvent.js';
import { createPveEvent } from './createPveEvent.js';
import { handleTriggeredPveEvent } from './handleTriggeredPveEvent.js';
import { HeroGroupData } from '../types/heroGroupData.js';
import { simulateRegenForHero } from './simulateRegenForHero.js';

const db = admin.firestore();

/**
 * Persist out-of-combat regen for all heroes in the group.
 * ✅ Tick model: hpRegen / manaRegen = seconds PER +1 point.
 * Uses separate clocks lastHpRegenAt / lastManaRegenAt (number ms or Firestore Timestamp).
 * Writes numeric ms epoch back for both timestamps.
 */
async function persistOutOfCombatRegenForGroup(groupId: string, group: HeroGroupData) {
  const nowMs = Date.now();
  const heroIds: string[] = Array.isArray(group?.members) ? group.members : [];
  if (!heroIds.length) return;

  // Load heroes
  const heroRefs = heroIds.map((id) => db.collection('heroes').doc(id));
  const heroSnaps = await db.getAll(...heroRefs);

  const batch = db.batch();
  let updates = 0;

  // Normalize potential Firestore Timestamps to ms numbers
  const toMs = (v: any) => (typeof v === 'number' ? v : v?.toMillis?.() ?? undefined);

  for (const snap of heroSnaps) {
    if (!snap.exists) continue;
    const h = snap.data() || {};

    const sim = simulateRegenForHero(
      {
        hp: h.hp ?? 0,
        hpMax: h.hpMax ?? 0,
        mana: h.mana,
        manaMax: h.manaMax,

        // ⏱️ Seconds PER +1 point (tick model)
        hpRegen: h.hpRegen,       // e.g., 270  => +1 HP every 270s
        manaRegen: h.manaRegen,   // e.g., 270  => +1 Mana every 270s

        // Separate clocks with legacy fallback
        lastHpRegenAt: toMs(h.lastHpRegenAt) ?? toMs(h.lastRegenAt),
        lastManaRegenAt: toMs(h.lastManaRegenAt) ?? toMs(h.lastRegenAt),
        lastRegenAt: toMs(h.lastRegenAt),
      },
      nowMs
    );

    const update: Record<string, any> = {
      hp: sim.hp,
      lastHpRegenAt: sim.lastHpRegenAt,     // numeric ms (advanced by applied ticks only)
      lastManaRegenAt: sim.lastManaRegenAt, // numeric ms (advanced by applied ticks only)
    };
    if (h.manaMax != null) update.mana = sim.mana;

    batch.update(snap.ref, update);
    updates++;
  }

  if (updates > 0) {
    await batch.commit();
    console.log(`💾 Regen persisted for ${updates} hero(es) in group ${groupId}.`);
  } else {
    console.log(`ℹ️ No hero updates necessary for regen in group ${groupId}.`);
  }
}

export async function processHeroGroupArrival(groupId: string) {
  console.log(`📦 processHeroGroupArrival(${groupId}) started`);

  const groupRef = db.collection('heroGroups').doc(groupId);
  const groupSnap = await groupRef.get();

  if (!groupSnap.exists) {
    console.warn(`❌ Group ${groupId} not found.`);
    return;
  }

  const group = groupSnap.data()!;
  console.log(
    `📄 Group data loaded. State: ${group.state}, Returning: ${group.returning}, Waypoints: ${group.waypoints?.length ?? 0}`
  );

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
    console.log(
      `⏩ Group ${groupId} is not in 'moving' or 'arrived' state (${group.state}). Skipping.`
    );
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
  const updatedGroup = updatedSnap.data() as HeroGroupData;
  console.log(
    `🧠 Group ${groupId} is now at ${updatedGroup.tileX}_${updatedGroup.tileY} and ready for regen + PvE roll.`
  );

  // ✅ PERSIST OUT-OF-COMBAT REGEN BEFORE ANY EVENT ROLL
  try {
    await persistOutOfCombatRegenForGroup(groupId, updatedGroup);
  } catch (err: any) {
    console.error(`💥 Failed to persist regen before PvE roll: ${err.message}`);
    // Proceed anyway; worst case heroes fight with slightly stale HP.
  }

  // 🎲 Try triggering a PvE event
  const triggerInfo = await maybeTriggerPveEvent(updatedGroup);
  const tileKey = updatedGroup.tileKey ?? `${updatedGroup.tileX}_${updatedGroup.tileY}`;
  const tileSnap = await db.collection('mapTiles').doc(tileKey).get();
  const terrain = tileSnap.get('terrain') ?? 'any';

  if (triggerInfo.shouldTrigger) {
    try {
      console.log(`⚠️ Triggering PvE event: ${triggerInfo.type}, Level ${triggerInfo.level}`);
      const eventResult = await createPveEvent(
        groupId,
        {
          tileX: updatedGroup.tileX,
          tileY: updatedGroup.tileY,
          tileKey,
          members: updatedGroup.members ?? [],
        },
        triggerInfo.type!,
        triggerInfo.level!,
        terrain // 🌲🌋🏔️⛰️
      );

      console.log(`📜 PvE event created: ${eventResult.combatId ?? eventResult.peacefulReportId}`);
      await handleTriggeredPveEvent(eventResult, { ...updatedGroup, groupId }); // ✅ inject groupId!
      console.log(`🏁 PvE event handled successfully.`);
      return;
    } catch (err: any) {
      console.error(`❌ Failed to create/handle PvE event: ${err.message}`);
      await maybeContinueGroupMovement(groupId); // ✅ don't skip movement!
      return;
    }
  }

  // 🏃 No PvE triggered → continue
  await maybeContinueGroupMovement(groupId);
}
