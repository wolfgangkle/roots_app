export function simulateRegenForHero(hero: {
  hp: number;
  hpMax: number;
  mana?: number;
  manaMax?: number;
  hpRegen?: number;        // seconds between +1 HP
  manaRegen?: number;      // seconds between +1 Mana
  lastRegenAt?: number;    // timestamp in ms
}) {
  const now = Date.now();
  const last = hero.lastRegenAt ?? now;
  const elapsed = now - last;

  let newHp = hero.hp;
  let newMana = hero.mana ?? 0;

  if (hero.hpRegen && hero.hp < hero.hpMax) {
    const hpTicks = Math.floor(elapsed / (hero.hpRegen * 1000));
    newHp = Math.min(hero.hpMax, newHp + hpTicks);
  }

  if (hero.manaRegen && hero.mana != null && hero.mana < (hero.manaMax ?? Infinity)) {
    const manaTicks = Math.floor(elapsed / (hero.manaRegen * 1000));
    newMana = Math.min(hero.manaMax ?? newMana, newMana + manaTicks);
  }

  return {
    ...hero,
    hp: newHp,
    mana: newMana,
    lastRegenAt: now,
  };
}
