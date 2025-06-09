import * as admin from 'firebase-admin';
import { randomUUID } from 'crypto';

const db = admin.firestore();

interface HeroGroupData {
  tileX: number;
  tileY: number;
  tileKey?: string;
  members?: string[];
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
  let { tileX, tileY, members = [] } = group;

  // 🧙 Fallback: fetch members if missing
  if (!members.length) {
    console.warn(`⚠️ No members passed to createPveEvent for group ${groupId}. Fetching from Firestore...`);
    const groupSnap = await db.collection('heroGroups').doc(groupId).get();
    const groupData = groupSnap.data();
    if (groupData?.members?.length) {
      members = groupData.members;
      console.log(`✅ Members recovered from Firestore: ${members.length}`);
    } else {
      console.warn(`❌ Still no members found for group ${groupId}. Report will be empty.`);
    }
  }

  let tileKey = group.tileKey;
  if (!tileKey || typeof tileKey !== 'string' || tileKey.trim() === '') {
    console.warn(`⚠️ tileKey missing or invalid for group ${groupId}, reconstructing from tileX/tileY`);
    tileKey = `${tileX}_${tileY}`;
  }

  const now = admin.firestore.Timestamp.now();
  console.log(`📍 About to update mapTiles/${tileKey}`);
  try {
    await db.collection('mapTiles').doc(tileKey).set({ lastEventAt: now }, { merge: true });
  } catch (err) {
    console.error(`🔥 Failed to update mapTiles/${tileKey}:`, err);
    throw new Error(`❌ Could not update tile ${tileKey} for group ${groupId}`);
  }

  const minField = type === 'combat' ? 'minLevel' : 'minCombatLevel';
  const maxField = type === 'combat' ? 'maxLevel' : 'maxCombatLevel';

  const eventsSnap = await db.collection('encounterEvents')
    .where('type', '==', type)
    .where(minField, '<=', level)
    .where(maxField, '>=', level)
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

  // ... top unchanged ...
  if (type === 'combat') {
    const enemyTypeIds: string[] = eventData.enemyTypes ?? [];

    if (!Array.isArray(enemyTypeIds) || enemyTypeIds.length === 0) {
      throw new Error(`⚠️ No enemyTypes defined in event ${eventId}`);
    }

    // 🎲 Randomly select enemy type IDs up to scaledCount
    const chosenIds = Array.from({ length: scaledCount }, () => {
      const i = Math.floor(Math.random() * enemyTypeIds.length);
      return enemyTypeIds[i];
    });

    const enemyDocs = await db.getAll(...chosenIds.map(id => db.doc(`enemyTypes/${id}`)));

    const enemies = enemyDocs.map((snap, index) => {
      if (!snap.exists) {
        throw new Error(`❌ Enemy type '${chosenIds[index]}' not found`);
      }

      const data = snap.data();
      const stats = data?.baseStats;

      if (
        !stats ||
        typeof stats.hp !== 'number' ||
        typeof stats.minDamage !== 'number' ||
        typeof stats.maxDamage !== 'number'
      ) {
        throw new Error(`❌ Enemy type '${chosenIds[index]}' is missing required baseStats`);
      }

      return {
        instanceId: `enemy_${randomUUID()}`,
        enemyTypeId: snap.id,
        name: data.name ?? 'Unknown',
        currentHp: stats.hp,
        hp: stats.hp,
        minDamage: stats.minDamage,
        maxDamage: stats.maxDamage,
        armor: stats.defense ?? 0,
        xp: data.xp ?? 0,
        type: snap.id,
        baseStats: stats,
      };
    });

    // 🦸 Fetch hero documents and snapshot stats
    const heroDocs = await db.getAll(...members.map(id => db.doc(`heroes/${id}`)));

    const heroes = heroDocs.map((snap) => {
      const data = snap.data() || {};
      return {
        id: snap.id,
        name: data.name ?? 'Unknown Hero',
        currentHp: data.currentHp ?? data.hp ?? 100,
        hp: data.hp ?? 100,
        mana: data.mana ?? 0,
        maxMana: data.maxMana ?? 0,
        minDamage: data.minDamage ?? 0,
        maxDamage: data.maxDamage ?? 0,
        armor: data.armor ?? 0,
        xp: data.xp ?? 0,
        level: data.level ?? 1,
        race: data.race ?? 'unknown',
        spellIds: data.spellIds ?? [],
      };
    });

    const combatRef = db.collection('combats').doc();
    await combatRef.set({
      groupId,
      eventId,
      tileX,
      tileY,
      tileKey,
      state: 'ongoing',
      tick: 0,
      createdAt: now,
      type: 'pve',
      enemies,
      heroes, // 💾 Store combat-ready hero snapshots
      heroActions: [],
      enemyActions: [],
      combatLog: [],
    });

    return {
      type: 'combat',
      eventId,
      combatId: combatRef.id,
    };
  }
 else {
    const peacefulRef = db.collection('peacefulReports').doc();
    await peacefulRef.set({
      groupId,
      eventId,
      tileX,
      tileY,
      tileKey,
      createdAt: now,
      reward: eventData.reward ?? {},
      title: eventData.title ?? 'Peaceful Encounter',
      description: eventData.description ?? 'You experienced a peaceful moment.',
      source: 'pve',
      members,
    });

    return {
      type: 'peaceful',
      eventId,
      peacefulReportId: peacefulRef.id,
    };
  }
}
