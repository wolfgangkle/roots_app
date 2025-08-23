// functions/src/movement/createPveEvent.ts
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

    const scale = eventData.scale ?? { base: 1, scalePerLevel: 0.015, max: 3 };
    const scaledCount = Math.min(scale.max ?? 5, Math.floor((scale.base ?? 1) + (scale.scalePerLevel ?? 0.015) * level));

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

    // 🦸 Fetch hero docs & build snapshot **without** re-simulating regen
    console.log(`🦸 Fetching hero snapshots for group ${groupId} → members: ${JSON.stringify(members)}`);

    const heroDocs = await db.getAll(...members.map(id => db.doc(`heroes/${id}`)));
    const heroes = await Promise.all(heroDocs.map(async snap => {
      const data = snap.data() || {};
      console.log(`📄 Loaded hero doc for ${snap.id}`);

      // Use DB values as-is (they were just updated on arrival)
      const hp    = data.hp      ?? 100;
      const hpMax = data.hpMax   ?? hp;

      if (data.hp === undefined)     console.warn(`⚠️ Hero ${snap.id} is missing 'hp', using fallback 100`);
      if (data.hpMax === undefined)  console.warn(`⚠️ Hero ${snap.id} is missing 'hpMax', using fallback = hp`);

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

      console.log(`🪄 ${snap.id} assigned spells: ${assignedSpells.length}`);

      const heroSnapshot = {
        id:            snap.id,
        name:          data.heroName ?? data.name ?? 'Unnamed Hero',
        race:          data.race ?? 'unknown',
        level:         data.level ?? 1,
        xp:            data.xp ?? 0,

        // ✅ No regen here — use current DB state
        hp,
        hpMax,
        hpRegen:       data.hpRegen ?? null,
        mana:          data.mana ?? undefined,
        manaMax:       data.manaMax ?? undefined,
        manaRegen:     data.manaRegen ?? null,

        attackMin:     data.combat?.attackMin ?? 0,
        attackMax:     data.combat?.attackMax ?? 0,
        attackSpeedMs: data.combat?.attackSpeedMs ?? 15000,
        attackRating:  data.combat?.at ?? 0,
        defense:       data.combat?.def ?? data.combat?.defense ?? 0,

        assignedSpells,
      };

      console.log(`📦 Hero snapshot for ${snap.id}:`, JSON.stringify(heroSnapshot, null, 2));
      return heroSnapshot;
    }));

    // 👥 Denormalize participant owner ids (resilient reports list)
    const participantOwnerIds = Array.from(new Set(
      heroDocs
        .map(snap => (snap.data()?.ownerId as string | undefined) || null)
        .filter((v): v is string => !!v)
    ));
    const participantHeroIds = members.slice(); // optional, but useful

    console.log(`👥 participantOwnerIds = ${JSON.stringify(participantOwnerIds)}`);
    console.log(`📥 Preparing to write combat document with ${heroes.length} heroes and ${enemies.length} enemies.`);

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
      // 🔗 New denormalized fields
      participantOwnerIds, // ✅ query by player
      participantHeroIds,  // optional helper for hero-scoped UIs
      // lastTickAt: admin.firestore.Timestamp.now(),
    });

    console.log(`✅ Combat document written: ${combatRef.id}`);

    return { type: 'combat', eventId, combatId: combatRef.id };
  } else {
    // 🌳 Peaceful encounter
    // We still want resilience if heroes/groups disappear later.
    // Fetch minimal hero docs to collect ownerIds (if any members present).
    let participantOwnerIds: string[] = [];
    if (members.length) {
      const heroDocs = await db.getAll(...members.map(id => db.doc(`heroes/${id}`)));
      participantOwnerIds = Array.from(new Set(
        heroDocs
          .map(snap => (snap.data()?.ownerId as string | undefined) || null)
          .filter((v): v is string => !!v)
      ));
      console.log(`👥 (peaceful) participantOwnerIds = ${JSON.stringify(participantOwnerIds)}`);
    }
    const participantHeroIds = members.slice(); // optional

    const peacefulRef = db.collection('peacefulReports').doc();
    await peacefulRef.set({
      groupId,
      eventId,
      tileX,
      tileY,
      tileKey,
      createdAt:   now,
      reward:      eventData.reward       ?? {},
      title:       eventData.title        ?? 'Peaceful Encounter',
      description: eventData.description  ?? 'You experienced a peaceful moment.',
      source:      'pve',
      members,
      // 🔗 New denormalized fields for resilient listing
      participantOwnerIds,
      participantHeroIds,
    });

    console.log(`✅ Peaceful report written: ${peacefulRef.id}`);
    return { type: 'peaceful', eventId, peacefulReportId: peacefulRef.id };
  }
}
