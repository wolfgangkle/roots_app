// helpers/checkCombatOutcomeAndUpdate.ts
export async function checkCombatOutcomeAndUpdate({
  combatId,
  combat,
  updatedHeroes,
  updatedEnemies,
}: {
  combatId: string;
  combat: any;
  updatedHeroes: Array<{ id: string; hp: number } & Record<string, any>>;
  updatedEnemies: Array<{ hp: number; xp?: number } & Record<string, any>>;
}): Promise<{
  newState: 'ongoing' | 'ended';
  totalXp: number;
  xpPerHero: number;
  livingHeroIds: string[];
}> {
  const tick = (combat.tick ?? 0) + 1;

  const livingHeroes = updatedHeroes.filter((h) => (h.hp ?? 0) > 0);
  const livingHeroIds = livingHeroes.map(h => h.id);
  const livingEnemies = updatedEnemies.filter((e) => (e.hp ?? 0) > 0);

  const ended = tick >= 500 || livingHeroes.length === 0 || livingEnemies.length === 0;
  const newState: 'ongoing' | 'ended' = ended ? 'ended' : 'ongoing';

  // Sum XP from enemies that are dead at end of combat
  const totalXp = ended
    ? updatedEnemies
        .filter((e) => (e.hp ?? 1) <= 0)
        .reduce((sum, e) => sum + (Number(e.xp) || 0), 0)
    : 0;

  const xpPerHero = ended ? Math.floor(totalXp / Math.max(livingHeroes.length, 1)) : 0;

  console.log(`[XP] eval combat ${combatId}: state=${newState}, totalXp=${totalXp}, recipients=${livingHeroIds.length}, xpPerHero=${xpPerHero}`);

  return { newState, totalXp, xpPerHero, livingHeroIds };
}
