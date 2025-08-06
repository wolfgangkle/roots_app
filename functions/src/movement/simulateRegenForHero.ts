export function simulateRegenForHero(hero: {
  hp: number;
  hpMax: number;
  mana?: number;
  manaMax?: number;
  hpRegen?: number;
  manaRegen?: number;
  lastRegenAt?: number;
}) {
  const now = Date.now();
  const last = hero.lastRegenAt ?? now;
  const elapsed = now - last;

  console.log('🧪 simulateRegenForHero input:', JSON.stringify(hero, null, 2));
  console.log(`⏳ elapsed since last regen: ${elapsed}ms`);

  let newHp = hero.hp;
  let newMana = hero.mana ?? 0;

  if (hero.hpRegen && hero.hp < hero.hpMax) {
    const hpTicks = Math.floor(elapsed / (hero.hpRegen * 1000));
    console.log(`💉 HP regen eligible: ticks=${hpTicks}, hp before=${newHp}, hpMax=${hero.hpMax}`);
    newHp = Math.min(hero.hpMax, newHp + hpTicks);
  } else {
    console.log(`🛑 Skipping HP regen → hp=${hero.hp}, hpMax=${hero.hpMax}, hpRegen=${hero.hpRegen}`);
  }

  if (hero.manaRegen && hero.mana != null && hero.mana < (hero.manaMax ?? Infinity)) {
    const manaTicks = Math.floor(elapsed / (hero.manaRegen * 1000));
    console.log(`🔮 Mana regen eligible: ticks=${manaTicks}, mana before=${newMana}`);
    newMana = Math.min(hero.manaMax ?? newMana, newMana + manaTicks);
  } else {
    console.log(`🛑 Skipping Mana regen → mana=${hero.mana}, manaMax=${hero.manaMax}, manaRegen=${hero.manaRegen}`);
  }

  console.log(`✅ Regen result: hp=${newHp}, mana=${newMana}`);

  return {
    ...hero,
    hp: newHp,
    mana: newMana,
    lastRegenAt: now,
  };
}
