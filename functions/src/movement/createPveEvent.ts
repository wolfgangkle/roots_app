import * as admin from 'firebase-admin';
import { randomUUID } from 'crypto';
import { simulateRegenForHero } from './simulateRegenForHero.js';


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
  level: number,
  terrain: string
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

  const allEventsSnap = await db.collection('encounterEvents')
    .where('type', '==', type)
    .where(minField, '<=', level)
    .where(maxField, '>=', level)
    .get();

  const terrainFilteredEvents = allEventsSnap.docs.filter(doc => {
    const event = doc.data();
    const allowedTerrains = event.possibleTerrains ?? ['any'];
    return allowedTerrains.includes('any') || allowedTerrains.includes(terrain);
  });

  if (terrainFilteredEvents.length === 0) {
    throw new Error(`❌ No ${type} events found for level ${level} on terrain '${terrain}'`);
  }

  const selected = terrainFilteredEvents[Math.floor(Math.random() * terrainFilteredEvents.length)];





  const eventData = selected.data();
  console.log(`🎲 Selected event '${selected.id}' (${eventData.name}) for terrain '${terrain}'`);
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
        type: snap.id,
        name: data.name ?? 'Unknown',
        description: data.description ?? '',
        xp: data.xp ?? 0,
        combatLevel: data.combatLevel ?? 1,
        refPath: snap.ref.path,

        // 🧠 Combat Stats (normalized)
        hp: stats.hp,
        hpMax: stats.hp,
        currentHp: stats.hp,
        attackMin: stats.minDamage,
        attackMax: stats.maxDamage,
        attackSpeedMs: stats.attackSpeedMs ?? 15000,
        attackRating: stats.at ?? 0,
        defense: stats.def ?? 0,

        // 🔍 For debug / spell conditions / logging
        baseStats: stats,
      };
    });



    // 🦸 Fetch hero documents and snapshot stats
    const heroDocs = await db.getAll(...members.map(id => db.doc(`heroes/${id}`)));

    const heroes = await Promise.all(heroDocs.map(async (snap) => {
      const data = snap.data() || {};
      const combat = data.combat ?? {};

      // 🔮 Assigned Spells (from subcollection)
      const spellsSnap = await db.collection(`heroes/${snap.id}/assignedSpells`).get();
      const assignedSpells = spellsSnap.docs.map(spellSnap => {
        const spellData = spellSnap.data() || {};
        return {
          spellId: spellSnap.id,
          conditions: spellData.conditions ?? {},
          castSpeedMs: spellData.castSpeedMs ?? 90000,
        };
      });

      console.log(`🧙 Hero ${data.heroName ?? snap.id} has ${assignedSpells.length} assigned spells`);

      // First simulate regen
      const regen = simulateRegenForHero({
        hp: data.hp ?? 100,
        hpMax: data.hpMax ?? data.hp ?? 100,
        mana: data.mana ?? 0,
        manaMax: data.manaMax ?? 0,
        hpRegen: data.hpRegen ?? 0,
        manaRegen: data.manaRegen ?? 0,
        lastRegenAt: data.lastRegenAt ?? Date.now(),
      });

      return {
        id: snap.id,
        name: data.heroName ?? data.name ?? 'Unknown Hero',
        refPath: snap.ref.path,
        groupId: data.groupId ?? null,
        race: data.race ?? 'unknown',
        level: data.level ?? 1,
        xp: data.xp ?? 0,

        // 🧠 Stats
        hp: regen.hp,
        hpMax: regen.hpMax,
        hpRegen: data.hpRegen ?? 0,
        mana: regen.mana,
        manaMax: regen.manaMax,
        manaRegen: data.manaRegen ?? 0,
        carryCapacity: data.carryCapacity ?? 0,
        currentWeight: data.currentWeight ?? 0,
        combatLevel: data.combatLevel ?? 1,

        // ⚔️ Combat Stats
        attackMin: combat.attackMin ?? 5,
        attackMax: combat.attackMax ?? 10,
        attackSpeedMs: combat.attackSpeedMs ?? 15000,
        attackRating: combat.at ?? 0,
        defense: combat.def ?? combat.defense ?? 0,
        regenPerTick: combat.regenPerTick ?? 0,

        // 🔮 Spell logic
        assignedSpells,
      };

    }));




    const combatRef = db.collection('combats').doc();

    const enemyXpTotal = enemies.reduce((sum, e) => sum + (e.xp ?? 0), 0);

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
      enemyXpTotal,
      enemyCount: enemies.length,
      enemyName: eventData.name ?? enemies[0]?.name ?? 'Enemy',
      heroActions: [],
      enemyActions: [],
      combatLog: [],
      lastRegenAt: Date.now(),
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
