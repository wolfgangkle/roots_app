import * as admin from 'firebase-admin';

const db = admin.firestore();

const BASE_COMBAT_CHANCE = 0.8;
const BASE_PEACEFUL_CHANCE = 0.2;
const COMBAT_COOLDOWN_50 = 180; // minutes
const COMBAT_COOLDOWN_20 = 360; // minutes

export async function maybeTriggerPveEvent(group: any): Promise<{
  shouldTrigger: boolean;
  type?: 'combat' | 'peaceful';
  level?: number;
}> {
  const { tileKey, groupId, combatLevel = 1 } = group;
  if (!tileKey) {
    console.warn(`⚠️ Group ${groupId} has no tileKey.`);
    return { shouldTrigger: false };
  }

  const tileSnap = await db.collection('mapTiles').doc(tileKey).get();
  const tileData = tileSnap.exists ? tileSnap.data() ?? {} : {};

  if (tileData.villageId) {
    console.log(`🛡️ No event triggered on village tile ${tileKey}`);
    return { shouldTrigger: false };
  }

  // ⏳ Cooldown-based chance reduction
  let combatChance = BASE_COMBAT_CHANCE;
  let peacefulChance = BASE_PEACEFUL_CHANCE;
  const now = Date.now();

  if (tileData.lastEventAt?.toMillis) {
    const lastEventAt = tileData.lastEventAt.toMillis();
    const minutesSince = (now - lastEventAt) / 60000;

    if (minutesSince < COMBAT_COOLDOWN_50) {
      combatChance *= 0.5;
      peacefulChance *= 0.5;
      console.log(`🧯 Reduced event chances by 50% on ${tileKey} (${minutesSince.toFixed(1)} min)`);
    } else if (minutesSince < COMBAT_COOLDOWN_20) {
      combatChance *= 0.2;
      peacefulChance *= 0.2;
      console.log(`🧊 Reduced event chances by 80% on ${tileKey} (${minutesSince.toFixed(1)} min)`);
    }
  }

  // ⚙️ Placeholder for user preference modifier (e.g., avoidCombat)
  // In the future, fetch this from the user profile or group config
  const avoidCombatModifier = 1.0; // e.g. 0.5 to reduce chance
  combatChance *= avoidCombatModifier;

  const roll = Math.random();
  console.log(`🎲 Event roll for group ${groupId} at ${tileKey}: ${roll.toFixed(2)} vs combat=${combatChance}, peaceful=${peacefulChance}`);

  if (roll < combatChance) {
    return { shouldTrigger: true, type: 'combat', level: combatLevel };
  } else if (roll < combatChance + peacefulChance) {
    return { shouldTrigger: true, type: 'peaceful', level: combatLevel };
  }

  return { shouldTrigger: false };
}
