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

  // 🗺️ Ensure tileKey
  let tileKey = group.tileKey;
  if (!tileKey || typeof tileKey !== 'string' || tileKey.trim() === '') {
    console.warn(`⚠️ tileKey missing or invalid for group ${groupId}, reconstructing from tileX/tileY`);
    tileKey = `${tileX}_${tileY}`;
  }

  // ⏲️ Update lastEventAt on this tile
  const now = admin.firestore.Timestamp.now();
  await db.collection('mapTiles').doc(tileKey).set({ lastEventAt: now }, { merge: true });

  // 🔍 Query encounterEvents
  const minField = type === 'combat' ? 'minLevel' : 'minCombatLevel';
  const maxField = type === 'combat' ? 'maxLevel' : 'maxCombatLevel';

  const allEventsSnap = await db.collection('encounterEvents')
    .where('type', '==', type)
    .where(minField, '<=', level)
    .where(maxField, '>=', level)
    .get();

  const terrainFiltered = allEventsSnap.docs.filter(doc => {
    const ev = doc.data();
    const allowed = ev.possibleTerrains ?? ['any'];
    return allowed.includes('any') || allowed.includes(terrain);
  });

  if (terrainFiltered.length === 0) {
    throw new Error(`❌ No ${type} events found for level ${level} on terrain '${terrain}'`);
  }

  const selected = terrainFiltered[Math.floor(Math.random() * terrainFiltered.length)];
  const eventData = selected.data();
  const eventId = selected.id;

  if (type === 'combat') {
    // 🎲 Select and load enemies
    const enemyTypeIds: string[] = eventData.enemyTypes ?? [];
    if (!enemyTypeIds.length) {
      throw new Error(`⚠️ No enemyTypes defined in event ${eventId}`);
    }

    const scale = eventData.scale ?? { base: 1, scalePerLevel: 0.1, max: 5 };
    const scaledCount = Math.min(scale.max ?? 5, Math.floor(scale.base + scale.scalePerLevel * level));

    const chosenIds = Array.from({ length: scaledCount }, () => {
      const i = Math.floor(Math.random() * enemyTypeIds.length);
      return enemyTypeIds[i];
    });

    const enemyDocs = await db.getAll(...chosenIds.map(id => db.doc(`enemyTypes/${id}`)));
    const enemies = enemyDocs.map((snap, idx) => {
      if (!snap.exists) {
        throw new Error(`❌ Enemy type '${chosenIds[idx]}' not found`);
      }
      const data = snap.data()!;
      const stats = data.baseStats!;
      return {
        instanceId:   `enemy_${randomUUID()}`,
        enemyTypeId:  snap.id,
        name:         data.name        ?? 'Unknown',
        description:  data.description ?? '',
        xp:           data.xp          ?? 0,
        combatLevel:  data.combatLevel ?? 1,
        refPath:      snap.ref.path,

        // Combat stats
        hp:            stats.hp,
        hpMax:         stats.hp,
        currentHp:     stats.hp,
        attackMin:     stats.minDamage,
        attackMax:     stats.maxDamage,
        attackSpeedMs: stats.attackSpeedMs ?? 15000,
        attackRating:  stats.at        ?? 0,
        defense:       stats.def       ?? 0,

        baseStats:     stats,
      };
    });

    // 🦸 Fetch hero docs & snapshot stats
    const heroDocs = await db.getAll(...members.map(id => db.doc(`heroes/${id}`)));
    const heroes = await Promise.all(heroDocs.map(async snap => {
      const d = snap.data() || {};

      // Raw HP fields
      const baseHp    = d.hp      ?? 100;
      const baseHpMax = d.hpMax   ?? baseHp;
      const regenRate = d.hpRegen ?? 0;

      const lastRegen = typeof d.lastRegenAt?.toMillis === 'function'
        ? d.lastRegenAt.toMillis()
        : Date.now();

      // Regen simulation
      const { hp, hpMax } = simulateRegenForHero({
        hp:          baseHp,
        hpMax:       baseHpMax,
        hpRegen:     regenRate,
        mana:        d.mana        ?? 0,
        manaMax:     d.manaMax     ?? 0,
        manaRegen:   d.manaRegen   ?? 0,
        lastRegenAt: lastRegen,
      });

      // Assigned spells
      const spellsSnap = await db.collection(`heroes/${snap.id}/assignedSpells`).get();
      const assignedSpells = spellsSnap.docs.map(sp => {
        const sd = sp.data() || {};
        return {
          spellId:     sp.id,
          conditions:  sd.conditions ?? {},
          castSpeedMs: sd.castSpeedMs ?? 90000,
        };
      });

      return {
        id:        snap.id,
        name:      d.heroName ?? d.name ?? 'Unnamed Hero',
        race:      d.race ?? 'unknown',
        level:     d.level ?? 1,
        xp:        d.xp    ?? 0,

        // Combat snapshot
        hp,
        hpMax,
        hpRegen:   regenRate,

        // Other combat stats
        attackMin:    d.combat?.attackMin     ?? 5,
        attackMax:    d.combat?.attackMax     ?? 10,
        attackSpeedMs:d.combat?.attackSpeedMs ?? 15000,
        attackRating: d.combat?.at            ?? 0,
        defense:      d.combat?.def           ?? d.combat?.defense ?? 0,

        assignedSpells,
      };
    }));

    // 📝 Write combat doc
    const combatRef = db.collection('combats').doc();
    await combatRef.set({
      groupId,
      eventId,
      tileX,
      tileY,
      tileKey,
      state:       'ongoing',
      tick:        0,
      createdAt:   now,
      type:        'pve',
      enemies,
      heroes,
      heroActions: [],
      enemyActions: [],
      combatLog:   [],
      lastRegenAt: Date.now(),
    });

    return { type: 'combat', eventId, combatId: combatRef.id };
  } else {
    // 🌳 Peaceful encounter
    const peacefulRef = db.collection('peacefulReports').doc();
    await peacefulRef.set({
      groupId,
      eventId,
      tileX,
      tileY,
      tileKey,
      createdAt:   now,
      reward:      eventData.reward     ?? {},
      title:       eventData.title      ?? 'Peaceful Encounter',
      description: eventData.description?? 'You experienced a peaceful moment.',
      source:      'pve',
      members,
    });
    return { type: 'peaceful', eventId, peacefulReportId: peacefulRef.id };
  }
}
