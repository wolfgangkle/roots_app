// functions/src/deaths/finalizeHeroDeath.ts
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';

const db = admin.firestore();

export type DeathContext = {
  heroId: string;
  ownerId: string;
  tileX: number;
  tileY: number;
  insideVillage?: boolean;
  combatId?: string;
  cause: 'pve' | 'pvp' | 'other';
  diedAt: FirebaseFirestore.Timestamp;
  groupId?: string; // optional fast-path if you have it
};

type HeroDoc = FirebaseFirestore.DocumentData & {
  ownerId: string;
  type?: 'mage' | 'companion'; // ✅ matches schema
  // any other fields are preserved in heroSnapshot
};

type GroupDoc = FirebaseFirestore.DocumentData & {
  leaderHeroId?: string;
  members?: string[];              // primary
  memberIds?: string[];            // legacy/fallback (not used, but kept for safety)
  memberJoinedAt?: Record<string, FirebaseFirestore.Timestamp>;
  connections?: Record<string, string>;
  movementSpeed?: number;
  combatLevel?: number;
  insideVillage?: boolean;
};

function logPrefix(ctx: DeathContext) {
  return `[finalizeHeroDeath][hero:${ctx.heroId}][owner:${ctx.ownerId}][combat:${ctx.combatId || 'noCombat'}]`;
}

function jobIdFor(ctx: DeathContext) {
  return `${ctx.combatId || 'noCombat'}_${ctx.heroId}`;
}

function tileKey(x: number, y: number) {
  return `${x}_${y}`;
}

function pickNewLeader(
  memberIds: string[],
  departingHeroId: string,
  preferOwnerId?: string,
  joinedAt?: Record<string, FirebaseFirestore.Timestamp>
): string | null {
  const remaining = memberIds.filter((id) => id !== departingHeroId);
  if (remaining.length === 0) return null;

  // If joinedAt exists, sort by joinedAt ascending; fall back to lexicographic.
  const sorted = [...remaining].sort((a, b) => {
    const aj = joinedAt?.[a]?.toMillis?.() ?? Number.MAX_SAFE_INTEGER;
    const bj = joinedAt?.[b]?.toMillis?.() ?? Number.MAX_SAFE_INTEGER;
    if (aj !== bj) return aj - bj;
    return a.localeCompare(b);
  });

  if (preferOwnerId) {
    // TODO(schema): If the group stores owner per member, prioritize same-owner here.
  }

  return sorted[0];
}

/**
 * Copies a subcollection `learned_spells` from heroes/{heroId} to users/{ownerId}/graveyard/{heroId}.
 * Idempotent: overwrites same doc ids.
 */
async function copyLearnedSpellsToGraveyard(ownerId: string, heroId: string, lp = '[finalizeHeroDeath]') {
  const srcCol = db.collection('heroes').doc(heroId).collection('learned_spells');
  const dstCol = db.collection('users').doc(ownerId).collection('graveyard').doc(heroId).collection('learned_spells');

  const snap = await srcCol.get();
  if (snap.empty) {
    console.log(`${lp} learned_spells: none to copy for hero ${heroId}`);
    return;
  }

  const batch = db.batch();
  snap.docs.forEach((d) => {
    const dstRef = dstCol.doc(d.id);
    batch.set(dstRef, d.data(), { merge: true });
  });
  await batch.commit();
  console.log(`${lp} learned_spells: copied ${snap.size} docs for hero ${heroId}`);
}

/**
 * Remove hero from group, reassign leader, or delete group if empty.
 * Uses your schema: members[], connections{}, leaderHeroId (no memberIds).
 * Keeps the group doc id stable (even if leader changes).
 * 🔧 NEW: Propagates groupLeaderId to all surviving heroes.
 */
async function updateGroupOnDeath(ctx: DeathContext) {
  const lp = logPrefix(ctx) + '[group]';
  let groupRef: FirebaseFirestore.DocumentReference | null = null;
  let groupSnap: FirebaseFirestore.DocumentSnapshot<GroupDoc> | null = null;

  if (ctx.groupId) {
    groupRef = db.collection('heroGroups').doc(ctx.groupId);
    groupSnap = await groupRef.get() as FirebaseFirestore.DocumentSnapshot<GroupDoc>;
    console.log(`${lp} using provided groupId=${ctx.groupId}`);
  } else {
    // Discover via 'members'
    const q = await db.collection('heroGroups')
      .where('members', 'array-contains', ctx.heroId)
      .limit(1)
      .get();
    if (!q.empty) {
      groupRef = q.docs[0].ref;
      groupSnap = q.docs[0] as FirebaseFirestore.DocumentSnapshot<GroupDoc>;
      console.log(`${lp} discovered groupId=${groupRef.id} via members lookup`);
    }
  }

  if (!groupRef || !groupSnap?.exists) {
    console.warn(`${lp} no group found for hero ${ctx.heroId}; skipping group update`);
    return;
  }

  const groupData = groupSnap.data() as GroupDoc;
  const members = Array.isArray(groupData.members) ? [...groupData.members] : [];

  if (!members.includes(ctx.heroId)) {
    console.log(`${lp} hero ${ctx.heroId} already not in group ${groupRef.id}; skipping`);
    return;
  }

  // Remove the dead hero
  const remaining = members.filter(id => id !== ctx.heroId);

  if (remaining.length === 0) {
    console.log(`${lp} deleting empty group ${groupRef.id}`);
    await groupRef.delete();
    return;
  }

  // Reassign leader if needed
  const prevLeader = groupData.leaderHeroId;
  let leaderHeroId = prevLeader;
  if (!leaderHeroId || leaderHeroId === ctx.heroId) {
    leaderHeroId = pickNewLeader(members, ctx.heroId, /*preferOwnerId*/ ctx.ownerId, groupData.memberJoinedAt) ?? remaining[0];
    console.log(`${lp} leader reassigned: ${prevLeader} -> ${leaderHeroId}`);
  }

  // Prune connections entry for the dead hero (if present)
  const newConnections = { ...(groupData as any).connections };
  if (newConnections && newConnections[ctx.heroId]) {
    delete newConnections[ctx.heroId];
  }

  // (Optional) Recompute movementSpeed & combatLevel from remaining heroes
  let movementSpeed = groupData.movementSpeed;
  let combatLevel = groupData.combatLevel;
  try {
    const remainingRefs = remaining.map(id => db.collection('heroes').doc(id));
    const snaps = await db.getAll(...remainingRefs);
    const speeds: number[] = [];
    let clSum = 0;
    for (const s of snaps) {
      const d = s.data() || {};
      if (typeof d.movementSpeed === 'number') speeds.push(d.movementSpeed);
      clSum += (d.combatLevel ?? 0);
    }
    if (speeds.length > 0) movementSpeed = Math.max(...speeds);
    combatLevel = clSum;
    console.log(`${lp} recomputed movementSpeed=${movementSpeed}, combatLevel=${combatLevel}`);
  } catch (e) {
    console.warn(`${lp} failed to recompute speed/CL; keeping previous values`, e);
  }

  // Update group (doc id stays the same)
  await groupRef.update({
    members: remaining,
    connections: newConnections ?? admin.firestore.FieldValue.delete(),
    leaderHeroId,
    movementSpeed,
    combatLevel,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`${lp} updated group ${groupRef.id}: removed=${ctx.heroId}, membersNow=${remaining.length}, leader=${leaderHeroId}`);

  // 🔧 IMPORTANT: propagate new leader to all surviving heroes (so UI doesn't point to a dead leader)
  try {
    const batch = db.batch();
    for (const memberId of remaining) {
      batch.update(db.collection('heroes').doc(memberId), {
        groupLeaderId: leaderHeroId,
        // keep groupId unchanged (stable = groupRef.id)
      });
    }
    await batch.commit();
    console.log(`${lp} propagated groupLeaderId=${leaderHeroId} to ${remaining.length} hero(es)`);
  } catch (e) {
    console.warn(`${lp} failed to propagate groupLeaderId to survivors`, e);
  }
}

/**
 * Updates companion slot usage when a companion dies.
 * For main heroes ("mage"), we don't touch slot usage.
 */
async function updateSlotUsageOnDeath(ownerId: string, heroType?: 'mage' | 'companion', lp = '[finalizeHeroDeath][slots]') {
  // Only companions affect slot usage
  if (heroType !== 'companion') {
    console.log(`${lp} heroType=${heroType}; no slot update needed`);
    return;
  }

  const profileRef = db.doc(`users/${ownerId}/profile/main`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(profileRef);
    if (!snap.exists) {
      console.error(`${lp} profile missing for owner ${ownerId}`);
      throw new HttpsError('failed-precondition', 'Profile not initialized with slot limits.');
    }

    const data = snap.data() || {};
    const usage = data.currentSlotUsage || {};
    const before = usage.companions || 0;
    const next = Math.max(0, before - 1);

    tx.update(profileRef, { 'currentSlotUsage.companions': next });
    console.log(`${lp} companions slot usage: ${before} -> ${next} (owner=${ownerId})`);
  });
}

/**
 * Writes the graveyard doc with a full snapshot of the hero (top-level doc only) and metadata.
 * Idempotent: if graveyard doc already exists, we treat the job as already completed.
 */
async function writeGraveyardDoc(ctx: DeathContext, hero: HeroDoc) {
  const lp = logPrefix(ctx) + '[graveyard]';
  const gyRef = db.doc(`users/${ctx.ownerId}/graveyard/${ctx.heroId}`);
  const now = admin.firestore.FieldValue.serverTimestamp();

  // If already exists, short-circuit (idempotent)
  const existing = await gyRef.get();
  if (existing.exists) {
    console.log(`${lp} already exists; skipping write`);
    return;
  }

  const body = {
    ownerId: ctx.ownerId,
    heroId: ctx.heroId,
    heroSnapshot: hero,
    diedAt: ctx.diedAt,
    diedAtTile: {
      x: ctx.tileX,
      y: ctx.tileY,
      insideVillage: !!ctx.insideVillage,
      tileKey: tileKey(ctx.tileX, ctx.tileY),
    },
    combatId: ctx.combatId || null,
    cause: ctx.cause,
    revivable: true,
    source: 'system',
    createdAt: now,
    updatedAt: now,
  };

  await gyRef.set(body, { merge: false });
  console.log(`${lp} wrote graveyard doc at users/${ctx.ownerId}/graveyard/${ctx.heroId}`);
}

/**
 * Simple idempotency guard document.
 */
async function markJobRunning(jobRef: FirebaseFirestore.DocumentReference, ctx: DeathContext) {
  const lp = logPrefix(ctx) + '[job]';
  await db.runTransaction(async (tx) => {
    const s = await tx.get(jobRef);
    if (s.exists) {
      const d = s.data()!;
      if (d.state === 'done') {
        console.log(`${lp} already done; short-circuit`);
        // Already done → throw a sentinel we catch and treat as success.
        throw new Error('__JOB_ALREADY_DONE__');
      }
      // else set to running (idempotently increment attempt)
      tx.update(jobRef, {
        state: 'running',
        attempt: (d.attempt || 0) + 1,
        lastStartedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`${lp} set to running; attempt=${(d.attempt || 0) + 1}`);
    } else {
      tx.set(jobRef, {
        state: 'running',
        attempt: 1,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastStartedAt: admin.firestore.FieldValue.serverTimestamp(),
        ctx: {
          heroId: ctx.heroId,
          combatId: ctx.combatId || null,
          ownerId: ctx.ownerId,
        },
      });
      console.log(`${lp} created job doc (running, attempt=1)`);
    }
  });
}

async function markJobDone(jobRef: FirebaseFirestore.DocumentReference, ctx: DeathContext) {
  const lp = logPrefix(ctx) + '[job]';
  await jobRef.set(
    {
      state: 'done',
      finalizedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  console.log(`${lp} marked done`);
}

/**
 * Main orchestrator for Step 1 (MVP, no loot yet).
 * - Copies hero doc to graveyard
 * - Copies learned_spells subcollection to graveyard/learned_spells
 * - Removes hero from group (reassigns leader or delete)
 * - Updates slot usage
 * - Deletes hero doc
 * - Idempotent (job doc + graveyard presence)
 */
export async function finalizeHeroDeath(ctx: DeathContext): Promise<{ graveyardDocPath: string }> {
  const lp = logPrefix(ctx);

  // Minimal validation
  if (!ctx.heroId || !ctx.ownerId) {
    console.error(`${lp} invalid ctx: missing heroId/ownerId`);
    throw new HttpsError('invalid-argument', 'heroId and ownerId are required.');
  }

  console.log(`${lp} start: tile=(${ctx.tileX},${ctx.tileY}), cause=${ctx.cause}, diedAt=${ctx.diedAt.toDate?.() || ''}`);

  const jobRef = db.collection('jobs_deaths').doc(jobIdFor(ctx));
  try {
    await markJobRunning(jobRef, ctx);
  } catch (e: any) {
    if (e?.message === '__JOB_ALREADY_DONE__') {
      console.log(`${lp} short-circuit: job already done`);
      return { graveyardDocPath: `users/${ctx.ownerId}/graveyard/${ctx.heroId}` };
    }
    console.error(`${lp} job start error:`, e);
    throw e;
  }

  const heroRef = db.doc(`heroes/${ctx.heroId}`);
  const gyRefPath = `users/${ctx.ownerId}/graveyard/${ctx.heroId}`;

  // Load hero (must exist at this point; if not, we check if graveyard exists and bail)
  const heroSnap = await heroRef.get();
  if (!heroSnap.exists) {
    console.warn(`${lp} hero doc missing; checking graveyard existence`);
    const gySnap = await db.doc(gyRefPath).get();
    if (gySnap.exists) {
      await markJobDone(jobRef, ctx);
      console.log(`${lp} hero already finalized earlier; returning existing graveyard path`);
      return { graveyardDocPath: gyRefPath };
    }
    console.error(`${lp} hero not found and no graveyard record exists`);
    throw new HttpsError('not-found', `Hero ${ctx.heroId} not found and no graveyard record exists.`);
  }
  const heroData = heroSnap.data() as HeroDoc;
  console.log(`${lp} loaded hero doc; type=${heroData.type}`);

  // 1) Write graveyard doc (idempotent)
  await writeGraveyardDoc(ctx, heroData);

  // 2) Copy learned_spells subcollection (idempotent overwrites)
  await copyLearnedSpellsToGraveyard(ctx.ownerId, ctx.heroId, lp);

  // 3) Update group (remove hero; reassign leader or delete) + propagate leader to survivors
  await updateGroupOnDeath(ctx);

  // 4) Update slot usage
  await updateSlotUsageOnDeath(ctx.ownerId, heroData.type, `${lp}[slots]`);

  // 5) Delete hero document (simple; recursive subcollection cleanup is optional Step 4)
  await heroRef.delete();
  console.log(`${lp} deleted hero doc heroes/${ctx.heroId}`);

  await markJobDone(jobRef, ctx);
  console.log(`${lp} finished successfully → ${gyRefPath}`);
  return { graveyardDocPath: gyRefPath };
}
