import * as admin from 'firebase-admin';

export async function checkCombatOutcomeAndUpdate({
  combatId,
  combat,
  updatedHeroes,
  updatedEnemies,
}: {
  combatId: string;
  combat: any;
  updatedHeroes: Array<{ id: string; data: any }>;
  updatedEnemies: any[];
}): Promise<'ongoing' | 'ended'> {
  const db = admin.firestore();
  const combatRef = db.collection('combats').doc(combatId);

  const tick = (combat.tick ?? 0) + 1;
  let newState: 'ongoing' | 'ended' = 'ongoing';

  const livingHeroes = updatedHeroes.filter(h => h.data.hp > 0);
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
  }

  // 🎓 XP reward logic (only for PvE)
  if (
    newState === 'ended' &&
    combat.eventId &&
    !combat.pvp &&
    combat.enemyXpTotal &&
    livingEnemies.length === 0
  ) {
    const survivors = livingHeroes;
    const xpPerHero = Math.floor(combat.enemyXpTotal / (survivors.length || 1));
    for (const hero of survivors) {
      await admin.firestore().collection('heroes').doc(hero.id).update({
        experience: admin.firestore.FieldValue.increment(xpPerHero),
      });
      console.log(`🎉 Hero ${hero.id} gains ${xpPerHero} XP`);
    }

    updates.xp = combat.enemyXpTotal;
    updates.message = `Defeated ${combat.enemyCount ?? '?'} ${combat.enemyName ?? 'enemies'} for ${combat.enemyXpTotal} XP.`;
    updates.reward = ['gold']; // TODO: Expand loot system
  }

  await combatRef.update(updates);
  console.log(`🧾 Combat ${combatId} state: ${newState}`);

  return newState;
}
