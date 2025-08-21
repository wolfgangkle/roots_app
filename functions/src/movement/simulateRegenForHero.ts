// movement/simulateRegenForHero.ts
// Out-of-combat regen with separate clocks (HP/Mana).
// ✅ Semantics: hpRegen / manaRegen = SECONDS PER +1 POINT (tick model).

type NumberLike = number | { toMillis?: () => number };

function toMillis(v: NumberLike | undefined, fallback: number) {
  if (typeof v === 'number') return v;
  if (v && typeof (v as any).toMillis === 'function') {
    try { return (v as any).toMillis() ?? fallback; } catch { return fallback; }
  }
  return fallback;
}

export function simulateRegenForHero(hero: {
  hp: number;
  hpMax: number;
  mana?: number;
  manaMax?: number;

  // Seconds per +1 point (tick model)
  hpRegen?: number | null;    // e.g., 270  => +1 HP every 270s
  manaRegen?: number | null;  // e.g., 270  => +1 Mana every 270s

  // Separate clocks (preferred)
  lastHpRegenAt?: NumberLike;
  lastManaRegenAt?: NumberLike;

  // Legacy single clock (fallback)
  lastRegenAt?: NumberLike;
}, nowMs: number = Date.now()) {
  const lastHpMs   = toMillis(hero.lastHpRegenAt ?? hero.lastRegenAt, nowMs);
  const lastManaMs = toMillis(hero.lastManaRegenAt ?? hero.lastRegenAt, nowMs);

  const hpMax = Number.isFinite(hero.hpMax) ? hero.hpMax : 0;
  const manaMax = Number.isFinite(hero.manaMax ?? NaN) ? (hero.manaMax as number) : undefined;

  let hp = Number.isFinite(hero.hp) ? hero.hp : 0;
  let mana = Number.isFinite(hero.mana ?? NaN) ? (hero.mana as number) : 0;

  let newLastHpAt = lastHpMs;
  let newLastManaAt = lastManaMs;

  // ---- HP: +1 per hpRegen seconds ----
  if (hpMax > 0 && hp < hpMax && hero.hpRegen && hero.hpRegen > 0) {
    const intervalMs = hero.hpRegen * 1000;
    const elapsedMs = Math.max(0, nowMs - lastHpMs);
    const ticks = Math.floor(elapsedMs / intervalMs);

    if (ticks > 0) {
      const missing = Math.max(0, Math.ceil(hpMax - hp)); // how many whole points needed
      const applied = Math.min(ticks, missing);
      hp = Math.min(hpMax, hp + applied);
      newLastHpAt = lastHpMs + applied * intervalMs; // carry over leftover fraction
    }
  }

  // ---- Mana: +1 per manaRegen seconds ----
  if (manaMax != null && mana < manaMax && hero.manaRegen && hero.manaRegen > 0) {
    const intervalMs = hero.manaRegen * 1000;
    const elapsedMs = Math.max(0, nowMs - lastManaMs);
    const ticks = Math.floor(elapsedMs / intervalMs);

    if (ticks > 0) {
      const missing = Math.max(0, Math.ceil(manaMax - mana));
      const applied = Math.min(ticks, missing);
      mana = Math.min(manaMax, mana + applied);
      newLastManaAt = lastManaMs + applied * intervalMs;
    }
  }

  // Clamp safety
  if (hpMax > 0) hp = Math.max(0, Math.min(hpMax, hp));
  if (manaMax != null) mana = Math.max(0, Math.min(manaMax, mana));

  return {
    ...hero,
    hp,
    mana: manaMax != null ? mana : hero.mana,
    // ✅ advance clocks only by applied ticks (preserve fractional remainder)
    lastHpRegenAt: newLastHpAt,
    lastManaRegenAt: newLastManaAt,
  };
}
