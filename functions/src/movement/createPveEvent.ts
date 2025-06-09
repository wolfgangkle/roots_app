import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function createPveEvent(group: any, type: 'combat' | 'peaceful', level: number): Promise<{
  type: 'combat' | 'peaceful';
  eventId: string;
  combatId?: string;
  peacefulReportId?: string;
}> {
  const { tileX, tileY, tileKey, groupId } = group;

  // 🔍 Filter matching encounter events
  const eventsSnap = await db.collection('encounterEvents')
    .where('type', '==', type)
    .where('minLevel', '<=', level)
    .where('maxLevel', '>=', level)
    .get();

  if (eventsSnap.empty) {
    throw new Error(`❌ No suitable ${type} events found for level ${level}`);
  }

  const eventDocs = eventsSnap.docs;
  const selected = eventDocs[Math.floor(Math.random() * eventDocs.length)];
  const eventData = selected.data();
  const eventId = selected.id;

  // 🧠 Scaling logic
  const scale = eventData.scale ?? { base: 1, scalePerLevel: 0.1, max: 5 };
  const scaledCount = Math.min(
    scale.max ?? 5,
    Math.floor(scale.base + scale.scalePerLevel * level)
  );

  const now = admin.firestore.Timestamp.now();

  // 🧾 Update tile's lastEventAt
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
        ...eventData.enemy, // base enemy template
        currentHp: eventData.enemy.hp, // instantiate HP
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
    // Peaceful: write directly to finishedJobs (or another report collection)
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
