import * as admin from 'firebase-admin';
import { maybeContinueGroupMovement } from '../../movement/maybeContinueGroupMovement.js';
import { finalizeHeroDeath } from '../../deaths/finalizeHeroDeath.js';
import { grantXpForCombatOutcome } from './grantXpForCombatOutcome.js';


const db = admin.firestore();

export async function handleCombatEnded(combat: any): Promise<void> {
  const combatId: string = combat.id;
  const groupId: string | undefined = combat.groupId;

  if (!groupId) {
    console.warn(`⚠️ Combat ${combatId} has no groupId. Skipping cleanup.`);
    return;
  }

  // Build authoritative sets from combat.heroes (final HP list)
  const combatHeroes: Array<{ id: string; hp: number }> = Array.isArray(combat.heroes) ? combat.heroes : [];
  const deadIds = new Set<string>(
    combatHeroes.filter((h) => (h?.hp ?? 0) <= 0).map((h) => String(h.id))
  );
  const aliveIdsFromCombat = new Set<string>(
    combatHeroes.filter((h) => (h?.hp ?? 0) > 0).map((h) => String(h.id))
  );
  console.log(`[handleCombatEnded] combat=${combatId} groupId=${groupId} combatHeroes=${combatHeroes.length} deadIds=[${[...deadIds].join(',')}] aliveIds=[${[...aliveIdsFromCombat].join(',')}]`);

  const groupRef = db.collection('heroGroups').doc(groupId);
  const groupSnap = await groupRef.get();
  if (!groupSnap.exists) {
    console.warn(`❌ Group ${groupId} not found for post-combat cleanup.`);
    return;
  }

  const group = groupSnap.data()!;
  const movementQueue: any[] = group.movementQueue ?? [];
  const resumeMovement = movementQueue.length > 0;

  // Your schema uses 'members'
  const heroIds: string[] = Array.isArray(group.members) ? group.members : [];

  // Survivors get state update; dead heroes are finalized by finalizeHeroDeath()
  const heroSnaps = await db.getAll(...heroIds.map((id: string) => db.doc(`heroes/${id}`)));
  const batch = db.batch();

  const aliveHeroIds: string[] = [];
  const deadHeroIds: string[] = [];

  for (const snap of heroSnaps) {
    if (!snap.exists) continue;
    const heroId = snap.id;

    // If a hero appears in group but not in combat.heroes, treat as DEAD (fail-closed).
    const appearsInCombat = aliveIdsFromCombat.has(heroId) || deadIds.has(heroId);
    const isDead = appearsInCombat ? deadIds.has(heroId) : true;

    const heroRef = snap.ref;

    if (isDead) {
      // Minimal mark (optional). finalizeHeroDeath() will copy + delete hero and update group/slots.
      batch.update(heroRef, {
        state: 'dead',
        // activeCombatId will be irrelevant after deletion; not necessary to clear here.
      });
      deadHeroIds.push(heroId);
      console.log(`☠️ Hero ${heroId} flagged dead in combat ${combatId} (appearsInCombat=${appearsInCombat})`);
    } else {
      // Survived → clear combat, set state according to queue
      batch.update(heroRef, {
        state: resumeMovement ? 'moving' : 'idle',
        activeCombatId: admin.firestore.FieldValue.delete(),
      });
      aliveHeroIds.push(heroId);
    }
  }

  // Clear combat flags on the group; don't touch membership here (death finalizer will manage it).
  const groupUpdate: Record<string, any> = {
    activeCombatId: admin.firestore.FieldValue.delete(),
    arrivesAt: admin.firestore.FieldValue.delete(),
    currentMovementTaskName: admin.firestore.FieldValue.delete(),
  };

  // Group state is tentative; after finalizers run, the group might be deleted or have different members.
  if (resumeMovement) {
    groupUpdate.state = 'arrived'; // cleanup done, movement may resume
  } else {
    groupUpdate.state = aliveHeroIds.length === 0 ? 'dead' : 'idle';
  }

  batch.update(groupRef, groupUpdate);
  await batch.commit();

  // ✅ IDP XP AWARD (safe to run before/after death finalization; marker prevents double-grant)
  try {
    // Prefer the combat.enemies array (final snapshot at end of combat)
    const enemies: Array<{ hp?: number; xp?: number }> = Array.isArray(combat.enemies) ? combat.enemies : [];
    if (enemies.length === 0) {
      console.log(`[handleCombatEnded] No enemies on combat ${combatId}; skipping XP award.`);
    } else {
      const totalXp = enemies
        .filter((e) => (e.hp ?? 1) <= 0)
        .reduce((sum, e) => sum + (Number(e.xp) || 0), 0);

      const recipients = aliveHeroIds.slice();
      const xpPerHero = recipients.length > 0 ? Math.floor(totalXp / recipients.length) : 0;

      console.log(`[handleCombatEnded] XP award eval: totalXp=${totalXp}, recipients=${recipients.length}, xpPerHero=${xpPerHero}`);

      if (xpPerHero > 0 && recipients.length > 0) {
        await grantXpForCombatOutcome({
          combatId,
          recipientHeroIds: recipients,
          xpPerHero,
        });
      } else {
        console.log(`[handleCombatEnded] Skipping XP grant (xpPerHero=${xpPerHero}, recipients=${recipients.length}).`);
      }
    }
  } catch (e) {
    console.error(`❌ XP grant failed for combat ${combatId}:`, e);
    // Non-fatal: continue with death finalization & movement resume.
  }

  // Finalize deaths (copy → graveyard, copy learned_spells, update group membership/leader, slot usage, delete hero)
  if (deadHeroIds.length > 0) {
    console.log(`[handleCombatEnded] finalizing deaths for: ${deadHeroIds.join(',')}`);
    // Pull tile from group (authoritative position for the group)
    const tileX: number = group.tileX ?? 0;
    const tileY: number = group.tileY ?? 0;
    const insideVillage: boolean = !!group.insideVillage;

    const nowTs = admin.firestore.Timestamp.now();

    for (const snap of heroSnaps) {
      if (!snap.exists) continue;
      const heroId = snap.id;
      if (!deadHeroIds.includes(heroId)) continue;

      const h = snap.data() || {};
      const ownerId: string | undefined = h.ownerId;

      if (!ownerId) {
        console.warn(`⚠️ Skipping death finalization for hero ${heroId}: missing ownerId`);
        continue;
      }

      try {
        await finalizeHeroDeath({
          heroId,
          ownerId,
          tileX,
          tileY,
          insideVillage,
          combatId,
          cause: 'pve', // or 'pvp' if you detect PvP elsewhere
          diedAt: nowTs,
          groupId, // pass to avoid group lookup by array-contains
        });
      } catch (e) {
        console.error(`❌ finalizeHeroDeath failed for hero ${heroId} in combat ${combatId}:`, e);
      }
    }
  } else {
    console.log(`[handleCombatEnded] no dead heroes to finalize for combat ${combatId}`);
  }

  // After finalizers, the group may have been modified or deleted. Re-read to decide movement.
  const postGroupSnap = await groupRef.get();

  if (!postGroupSnap.exists) {
    console.log(`🪦 Group ${groupId} deleted during death finalization (likely all members died).`);
    return;
  }

  const postGroup = postGroupSnap.data()!;
  const postMembers: string[] = Array.isArray(postGroup.members) ? postGroup.members : [];

  if (postMembers.length === 0) {
    console.log(`🪦 Group ${groupId} has no members after finalization; nothing to resume.`);
    return;
  }

  const postQueue: any[] = Array.isArray(postGroup.movementQueue) ? postGroup.movementQueue : [];
  if (postQueue.length > 0) {
    console.log(`🚚 Resuming movement for group ${groupId} with ${postMembers.length} member(s).`);
    await maybeContinueGroupMovement(groupId);
  } else {
    console.log(`✅ Post-combat cleanup completed for group ${groupId}; idle with ${postMembers.length} member(s).`);
  }
}
