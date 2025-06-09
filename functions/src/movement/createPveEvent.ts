import * as admin from 'firebase-admin';

const db = admin.firestore();

interface HeroGroupData {
  tileX: number;
  tileY: number;
  tileKey: string;
}

export async function createPveEvent(
  groupId: string,
  group: HeroGroupData,
  type: 'combat' | 'peaceful',
  level: number
): Promise<{
  type: 'combat' | 'peaceful';
  eventId: string;
  combatId?: string;
  peacefulReportId?: string;
}> {
  const { tileX, tileY, tileKey } = group;

  if (!tileKey) {
    throw new Error(`❌ Missing tileKey for group ${groupId}`);
  }

  const eventsSnap = await db.collection('encounterEvents')
    .where('type', '==', type)
    .where('minCombatLevel', '<=', level)
    .where('maxCombatLevel', '>=', level)
    .get();

  if (eventsSnap.empty) {
    throw new Error(`❌ No suitable ${type} events found for level ${level}`);
  }

  const selected = eventsSnap.docs[Math.floor(Math.random() * eventsSnap.docs.length)];
  const eventData = selected.data();
  const eventId = selected.id;

  const scale = eventData.scale ?? { base: 1, scalePerLevel: 0.1, max: 5 };
  const scaledCount = Math.min(
    scale.max ?? 5,
    Math.floor(scale.base + scale.scalePerLevel * level)
  );

  const now = admin.firestore.Timestamp.now();

  await db.collection('mapTiles').doc(tileKey).update({ lastEventAt: now });

  if (type === 'combat') {
    const combatRef = db.collection('combats').doc();
    await combatRef.set({
      groupId,
      eventId,
      tileX,
      tileY,
      tileKey,
      state: 'pending',
      tick: 0,
      createdAt: now,
      type: 'pve',
      enemies: Array(scaledCount).fill({
        ...eventData.enemy,
        currentHp: eventData.enemy.hp,
      }),
      heroActions: [],
      enemyActions: [],
      combatLog: [],
    });

    return {
      type: 'combat',
      eventId,
      combatId: combatRef.id,
    };
  } else {
    const peacefulRef = db.collection('peacefulReports').doc();
    await peacefulRef.set({
      groupId,
      eventId,
      tileX,
      tileY,
      tileKey,
      createdAt: now,
      reward: eventData.reward ?? {},
      description: eventData.description ?? 'You experienced a peaceful moment.',
      source: 'pve',
    });

    return {
      type: 'peaceful',
      eventId,
      peacefulReportId: peacefulRef.id,
    };
  }
}
