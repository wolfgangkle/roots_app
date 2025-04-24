import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import {
  calculateHeroWeight,
  calculateAdjustedMovementSpeed,
} from '../helpers/heroWeight';

export async function transferHeroResources(request: any) {
  const db = admin.firestore();
  const userId = request.auth?.uid;
  if (!userId) throw new HttpsError('unauthenticated', 'User must be logged in.');

  const { heroId, tileKey, action, resourceChanges } = request.data;

  if (!['pickup', 'drop'].includes(action)) {
    throw new HttpsError('invalid-argument', 'Action must be "pickup" or "drop".');
  }
  if (!heroId || typeof heroId !== 'string') {
    throw new HttpsError('invalid-argument', 'heroId must be a valid string.');
  }
  if (!tileKey || typeof tileKey !== 'string') {
    throw new HttpsError('invalid-argument', 'tileKey must be a valid string.');
  }
  if (typeof resourceChanges !== 'object') {
    throw new HttpsError('invalid-argument', 'resourceChanges must be an object.');
  }

  const allowedResources = ['wood', 'stone', 'iron', 'food', 'gold'];
  console.log("📥 transferHeroResources called with", { heroId, tileKey, action, resourceChanges });

  let groupId: string | undefined;

  await db.runTransaction(async (tx) => {
    const heroRef = db.collection('heroes').doc(heroId);
    const heroSnap = await tx.get(heroRef);
    if (!heroSnap.exists) throw new HttpsError('not-found', 'Hero not found.');
    const hero = heroSnap.data()!;
    if (hero.ownerId !== userId) {
      throw new HttpsError('permission-denied', 'You do not own this hero.');
    }

    if (['dead', 'in_combat'].includes(hero.state)) {
      throw new HttpsError('failed-precondition', `Cannot transfer resources while hero is ${hero.state}.`);
    }
    if (action === 'pickup' && hero.state === 'moving') {
      throw new HttpsError('failed-precondition', 'Cannot pick up resources while moving.');
    }

    groupId = hero.groupId;
    if (!groupId) throw new HttpsError('failed-precondition', 'Hero is not in a valid group.');

    const groupRef = db.collection('heroGroups').doc(groupId);
    const groupSnap = await tx.get(groupRef);
    const group = groupSnap.data();
    if (!group || group.tileKey !== tileKey) {
      throw new HttpsError('invalid-argument', 'Hero is not on the specified tile.');
    }

    const insideVillage = group.insideVillage ?? false;
    const tileRef = db.collection('mapTiles').doc(tileKey);
    const tileSnap = await tx.get(tileRef);
    const tile = tileSnap.exists ? tileSnap.data() ?? {} : {};

    let sourceRef: FirebaseFirestore.DocumentReference;
    let sourceRes: Record<string, number> = {};

    if (insideVillage) {
      if (!tile.villageId) {
        throw new HttpsError('failed-precondition', 'Tile has no villageId while hero is inside a village.');
      }

      const villageRef = db.doc(`users/${userId}/villages/${tile.villageId}`);
      const villageSnap = await tx.get(villageRef);
      if (!villageSnap.exists) throw new HttpsError('not-found', 'Village not found.');

      const village = villageSnap.data()!;
      const lastUpdated = village.lastUpdated?.toDate?.() ?? new Date(0);
      const now = new Date();
      const elapsedMinutes = (now.getTime() - lastUpdated.getTime()) / 60000;
      const production = village.productionPerHour ?? {};
      const stored = village.resources ?? {};

      if (elapsedMinutes > 0.05) {
        for (const res of allowedResources) {
          const gain = Math.floor((production[res] || 0) * (elapsedMinutes / 60));
          stored[res] = (stored[res] || 0) + gain;
        }
        tx.update(villageRef, {
          resources: stored,
          lastUpdated: admin.firestore.Timestamp.fromDate(now),
        });
        console.log(`🌾 Refreshed village ${tile.villageId} before resource transfer.`, stored);
      }

      sourceRef = villageRef;
      sourceRes = { ...stored };
    } else {
      sourceRef = tileRef;
      sourceRes = tile.resources ?? {};
    }

    const heroRes = { ...hero.carriedResources };
    const equipped = hero.equipped || {};
    const backpack = hero.backpack || [];

    for (const res of allowedResources) {
      const change = resourceChanges[res];
      if (typeof change !== 'number' || change <= 0) continue;

      const sourceAmount = sourceRes[res] ?? 0;
      const heroAmount = heroRes[res] ?? 0;

      if (action === 'pickup') {
        if (sourceAmount < change) {
          throw new HttpsError('failed-precondition', `Not enough ${res} to pick up.`);
        }
        sourceRes[res] = sourceAmount - change;
        heroRes[res] = heroAmount + change;
      } else {
        if (heroAmount < change) {
          throw new HttpsError('failed-precondition', `Not enough ${res} to drop.`);
        }
        heroRes[res] = heroAmount - change;
        sourceRes[res] = sourceAmount + change;
      }
    }

    const currentWeight = calculateHeroWeight(equipped, backpack, heroRes);
    const carryCapacity = hero.carryCapacity ?? 100;
    const baseSpeed = hero.baseMovementSpeed ?? hero.movementSpeed ?? 1200;
    const newSpeed = calculateAdjustedMovementSpeed(baseSpeed, currentWeight, carryCapacity);

    if (currentWeight > carryCapacity) {
      throw new HttpsError('failed-precondition', `Transfer would exceed carry capacity (${currentWeight.toFixed(2)} > ${carryCapacity}).`);
    }

    tx.update(heroRef, {
      carriedResources: heroRes,
      currentWeight,
      movementSpeed: newSpeed,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(sourceRef,
      insideVillage
        ? { resources: sourceRes }
        : {
            tileKey,
            x: group.tileX,
            y: group.tileY,
            resources: sourceRes,
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          },
      { merge: true }
    );

    console.log(`💰 Hero ${heroId} ${action}ped resources:`, resourceChanges, `→ ${insideVillage ? 'village' : 'tile'} storage`);
  });

  // ✅ Recalculate group movementSpeed after the transaction
  if (groupId) {
    try {
      const { updateGroupMovementSpeed } = await import('../helpers/updateGroupMovementSpeed.js');
      await Promise.race([
        updateGroupMovementSpeed(groupId),
        new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout updating group speed')), 3000)),
      ]);
      console.log(`✅ Group movement speed updated for group ${groupId}`);
    } catch (err) {
      console.warn(`⚠️ Failed to update group speed for group ${groupId}:`, (err as any).message);
    }
  }

  console.log(`🏁 transferHeroResources completed for hero ${heroId} (${action})`);
  return { success: true, message: `Resources ${action}ped successfully.` };
}
