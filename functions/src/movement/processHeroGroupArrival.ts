import { resolveMovementStep } from './resolveMovementStep.js';

export async function processHeroGroupArrival(groupId: string) {
  console.log(`📦 processHeroGroupArrival(${groupId}) started`);

  const moved = await resolveMovementStep(groupId);
  if (!moved) {
    console.warn(`⚠️ Movement failed or no step to resolve for group ${groupId}`);
    return;
  }

  // 🔜 Here we’ll eventually check for:
  // - PvP
  // - Events
  // - Loot
  // - Merges

  console.log(`✅ Movement step resolved for group ${groupId}`);
}
