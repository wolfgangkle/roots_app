import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function applyDamageAndUpdateHeroes({
  heroes,
  damageMap,
}: {
  heroes: Array<{ id: string; hp: number; mana?: number; [key: string]: any }>;
  damageMap: Record<string, number>;
}): Promise<Array<{ id: string; hp: number } & Record<string, any>>> {
  const updatedHeroes = heroes.map(hero => {
    const dmg = damageMap[hero.id] ?? 0;
    const newHp = Math.max(0, hero.hp - dmg);
    const isDead = newHp <= 0;

    return {
      ...hero,
      hp: newHp,
      state: isDead ? 'dead' : 'in_combat',
    };
  });

  const batch = db.batch();

  for (const hero of updatedHeroes) {
    const ref = db.doc(`heroes/${hero.id}`);
    batch.update(ref, {
      hp: hero.hp,
      mana: hero.mana ?? 0,
      state: hero.state,
    });
  }

  await batch.commit();

  return updatedHeroes;
}
