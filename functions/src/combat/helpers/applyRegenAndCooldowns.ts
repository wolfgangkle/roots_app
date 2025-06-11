import { DocumentReference } from 'firebase-admin/firestore';

/**
 * Applies HP/mana regeneration and keeps combat values bounded.
 * Also useful before checking if nextAttackAt is ready.
 */
export function applyRegenAndCooldowns(heroes: {
  id: string;
  ref: DocumentReference;
  data: {
    name: string;
    hp: number;
    hpMax: number;
    mana?: number;
    manaMax?: number;
    hpRegen?: number;
    manaRegen?: number;
    lastHpRegenAt?: number;
    lastManaRegenAt?: number;
  };
}[], lastTickAt: number): {
  updatedHeroes: {
    id: string;
    ref: DocumentReference;
    data: typeof heroes[number]['data'];
  }[];
  newLastTickAt: number;
} {
  const now = Date.now();

  const updatedHeroes = heroes.map(hero => {
    const d = hero.data;
    let hp = d.hp;
    let mana = d.mana;
    let lastHpRegenAt = d.lastHpRegenAt ?? now;
    let lastManaRegenAt = d.lastManaRegenAt ?? now;

    // ♻️ HP Regen
    if (d.hpRegen && d.hp < d.hpMax) {
      const intervalMs = d.hpRegen * 1000;
      const elapsedMs = now - lastHpRegenAt;
      const ticks = Math.floor(elapsedMs / intervalMs);
      if (ticks > 0) {
        hp = Math.min(d.hpMax, hp + ticks);
        lastHpRegenAt += ticks * intervalMs;
      }
    }

    // 💧 Mana Regen
    if (d.manaRegen && d.mana != null && d.manaMax != null && d.mana < d.manaMax) {
      const intervalMs = d.manaRegen * 1000;
      const elapsedMs = now - lastManaRegenAt;
      const ticks = Math.floor(elapsedMs / intervalMs);
      if (ticks > 0) {
        mana = Math.min(d.manaMax, (mana ?? 0) + ticks);
        lastManaRegenAt += ticks * intervalMs;
      }
    }

    return {
      id: hero.id,
      ref: hero.ref,
      data: {
        ...d,
        hp,
        mana,
        lastHpRegenAt,
        lastManaRegenAt,
      },
    };
  });

  return {
    updatedHeroes,
    newLastTickAt: now,
  };
}
