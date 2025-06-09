import * as admin from 'firebase-admin';

export async function applyDamageAndUpdateHeroes({
  heroes,
  damageMap,
}: {
  heroes: Array<{ id: string; data: any; ref: FirebaseFirestore.DocumentReference }>;
  damageMap: Record<string, number>;
}): Promise<Array<{ id: string; data: any }>> {
  const updatedHeroes: Array<{ id: string; data: any }> = [];
  const batch = admin.firestore().batch();

  for (const hero of heroes) {
    const baseHp = hero.data.hp ?? 0;
    const dmg = damageMap[hero.id] ?? 0;
    const newHp = Math.max(0, baseHp - dmg);
    const isDead = newHp <= 0;

    hero.data.hp = newHp;
    hero.data.state = isDead ? 'dead' : 'in_combat';

    const update: Record<string, any> = {
      hp: newHp,
      state: hero.data.state,
    };

    if (isDead) {
      update.movementQueue = [];
      update.destinationX = admin.firestore.FieldValue.delete();
      update.destinationY = admin.firestore.FieldValue.delete();
      update.arrivesAt = admin.firestore.FieldValue.delete();
      update.nextTileKey = admin.firestore.FieldValue.delete();
      update.reservedDestination = admin.firestore.FieldValue.delete();
    }

    batch.update(hero.ref, update);
    updatedHeroes.push({ id: hero.id, data: hero.data });

    console.log(`${isDead ? '☠️' : '❤️'} Hero ${hero.id} is now ${hero.data.state} (HP: ${newHp})`);
  }

  await batch.commit();
  return updatedHeroes;
}
