import { scheduleCombatTick } from '../scheduleCombatTick.js';

export async function scheduleNextCombatTick({
  combatId,
  newState,
  delaySeconds = 15,
}: {
  combatId: string;
  newState: 'ongoing' | 'ended';
  delaySeconds?: number;
}): Promise<void> {
  if (newState !== 'ongoing') {
    console.log(`🏁 Combat ${combatId} ended. No further ticks scheduled.`);
    return;
  }

  await scheduleCombatTick({ combatId, delaySeconds });
  console.log(`⏭️ Scheduled next combat tick for ${combatId} in ${delaySeconds}s`);
}
