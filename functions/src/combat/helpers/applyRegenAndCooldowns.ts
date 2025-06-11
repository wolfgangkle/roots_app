type FlatHero = {
  id: string;
  hp: number;
  mana: number;
  attackMin: number;
  attackMax: number;
  attackSpeedMs: number;
  nextAttackAt: number;
  lastHpRegenAt?: number;
  lastManaRegenAt?: number;
};

export function applyRegenAndCooldowns(
  heroes: FlatHero[],
  lastTickAt: number
): {
  updatedHeroes: FlatHero[];
  newLastTickAt: number;
} {
  const now = Date.now();

  const updatedHeroes = heroes.map(hero => {
    let hp = hero.hp;
    let mana = hero.mana;
    let lastHpRegenAt = hero.lastHpRegenAt ?? now;
    let lastManaRegenAt = hero.lastManaRegenAt ?? now;

    // ♻️ HP Regen
    if (hp < 9999 && hero.lastHpRegenAt != null) {
      const intervalMs = 10000; // Fixed regen every 10s? Adjust per system.
      const elapsedMs = now - lastHpRegenAt;
      const ticks = Math.floor(elapsedMs / intervalMs);
      if (ticks > 0) {
        hp = hp + ticks; // No max cap applied here unless needed
        lastHpRegenAt += ticks * intervalMs;
      }
    }

    // 💧 Mana Regen
    if (mana < 9999 && hero.lastManaRegenAt != null) {
      const intervalMs = 10000;
      const elapsedMs = now - lastManaRegenAt;
      const ticks = Math.floor(elapsedMs / intervalMs);
      if (ticks > 0) {
        mana = mana + ticks;
        lastManaRegenAt += ticks * intervalMs;
      }
    }

    return {
      ...hero,
      hp,
      mana,
      lastHpRegenAt,
      lastManaRegenAt,
    };
  });

  return {
    updatedHeroes,
    newLastTickAt: now,
  };
}
