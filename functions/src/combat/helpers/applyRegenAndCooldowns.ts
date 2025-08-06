export function applyRegenAndCooldowns(
  heroes: any[], // Accept full hero objects
  lastTickAt: number
): {
  updatedHeroes: any[];
  newLastTickAt: number;
} {
  const now = Date.now();

  const updatedHeroes = heroes.map(hero => {
    const hpRegenSec = hero.hpRegen ?? 0;
    const manaRegenSec = hero.manaRegen ?? 0;

    let hp = hero.hp ?? 0;
    let mana = hero.mana ?? 0;
    const hpMax = hero.hpMax ?? 9999;
    const manaMax = hero.manaMax ?? 9999;

    let lastHpRegenAt = hero.lastHpRegenAt ?? now;
    let lastManaRegenAt = hero.lastManaRegenAt ?? now;

    // ♻️ HP Regen
    if (hp < hpMax && hpRegenSec > 0) {
      const intervalMs = hpRegenSec * 1000;
      const elapsedMs = now - lastHpRegenAt;
      const ticks = Math.floor(elapsedMs / intervalMs);
      if (ticks > 0) {
        hp = Math.min(hpMax, hp + ticks);
        lastHpRegenAt += ticks * intervalMs;
      }
    }

    // 💧 Mana Regen
    if (mana < manaMax && manaRegenSec > 0) {
      const intervalMs = manaRegenSec * 1000;
      const elapsedMs = now - lastManaRegenAt;
      const ticks = Math.floor(elapsedMs / intervalMs);
      if (ticks > 0) {
        mana = Math.min(manaMax, mana + ticks);
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
