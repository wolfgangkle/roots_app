// combat/helpers/applyRegenAndCooldowns.ts

/**
 * Applies (optional) in-combat regen and returns updated heroes.
 * By default, combat regen is DISABLED to avoid same-tick "saved by 1 HP" cases.
 * If you ever want it back, pass { enableCombatRegen: true } and we’ll use the
 * time-to-full model: hpRegen/manaRegen = seconds to go from 0 -> max.
 *
 * NOTE: We do NOT modify lastHpRegenAt / lastManaRegenAt here.
 * Those clocks are for OUT-OF-COMBAT regen only (updated on tile arrival).
 */
export function applyRegenAndCooldowns(
  heroes: any[],
  lastTickAt: number,
  options?: { enableCombatRegen?: boolean }
): {
  updatedHeroes: any[];
  newLastTickAt: number;
} {
  const now = Date.now();
  const enableCombatRegen = options?.enableCombatRegen === true;

  if (!enableCombatRegen) {
    // ✅ No in-combat regen. Leave heroes as-is.
    // (Cooldown handling, if any, should live elsewhere.)
    return {
      updatedHeroes: heroes,
      newLastTickAt: now,
    };
  }

  // 🔄 Optional path: enable continuous in-combat regen using time-to-full model
  // hpRegen/manaRegen represent SECONDS-TO-FULL.
  const elapsedSec = Math.max(0, Math.floor((now - (lastTickAt ?? now)) / 1000));

  const updatedHeroes = heroes.map((hero) => {
    let hp = hero.hp ?? 0;
    let mana = hero.mana ?? 0;
    const hpMax = hero.hpMax ?? 0;
    const manaMax = hero.manaMax ?? 0;

    const hpRegenTimeSec = hero.hpRegen ?? 0;     // seconds to full
    const manaRegenTimeSec = hero.manaRegen ?? 0; // seconds to full

    if (elapsedSec > 0 && hpMax > 0 && hp < hpMax && hpRegenTimeSec > 0) {
      const hpPerSec = hpMax / hpRegenTimeSec;
      hp = Math.min(hpMax, hp + elapsedSec * hpPerSec);
    }

    if (elapsedSec > 0 && manaMax > 0 && mana < manaMax && manaRegenTimeSec > 0) {
      const manaPerSec = manaMax / manaRegenTimeSec;
      mana = Math.min(manaMax, mana + elapsedSec * manaPerSec);
    }

    // IMPORTANT: Do NOT touch lastHpRegenAt / lastManaRegenAt in combat
    return {
      ...hero,
      hp,
      mana,
    };
  });

  return {
    updatedHeroes,
    newLastTickAt: now,
  };
}
