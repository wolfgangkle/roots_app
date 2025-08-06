import * as admin from 'firebase-admin';
import { handleCombatEnded } from './handleCombatEnded.js';

const db = admin.firestore();

export async function checkCombatOutcomeAndUpdate({
  combatId,
  combat,
  updatedHeroes,
  updatedEnemies,
}: {
  combatId: string;
  combat: any;
  updatedHeroes: Array<{ id: string; hp: number } & Record<string, any>>;
  updatedEnemies: any[];
}): Promise<'ongoing' | 'ended'> {
  const combatRef = db.collection('combats').doc(combatId);
  const tick = (combat.tick ?? 0) + 1;

  let newState: 'ongoing' | 'ended' = 'ongoing';

  const livingHeroes = updatedHeroes.filter(h => h.hp > 0);
  const livingEnemies = updatedEnemies.filter(e => e.hp > 0);

  if (tick >= 500 || livingHeroes.length === 0 || livingEnemies.length === 0) {
    newState = 'ended';
  }

  const updates: Record<string, any> = {
    tick,
    state: newState,
    enemies: updatedEnemies,
  };

  if (newState === 'ended') {
    updates.endedAt = admin.firestore.FieldValue.serverTimestamp();

    // 🎓 XP payout from dead enemies
    const totalXp = updatedEnemies
      .filter(e => (e.hp ?? 1) <= 0)
      .reduce((sum, e) => sum + (e.xp ?? 0), 0);

    const xpPerHero = Math.floor(totalXp / (livingHeroes.length || 1));

    for (const hero of livingHeroes) {
      await db.collection('heroes').doc(hero.id).update({
        experience: admin.firestore.FieldValue.increment(xpPerHero),
      });
      console.log(`🎉 Hero ${hero.id} gains ${xpPerHero} XP`);
    }

    updates.xp = totalXp;
    updates.message = `Defeated ${combat.enemyCount ?? '?'} ${combat.enemyName ?? 'enemies'} for ${totalXp} XP.`;
    updates.reward = ['gold']; // 💰 Placeholder for loot system
  }

  await combatRef.update(updates);
  console.log(`🧾 Combat ${combatId} state: ${newState}`);

  if (newState === 'ended') {
    await handleCombatEnded(combat); // 🧹 Cleanup & resume movement
  }

  return newState;
}
