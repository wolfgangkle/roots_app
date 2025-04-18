import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

export async function transferHeroResources(request: any) {
  const db = admin.firestore();
  const userId = request.auth?.uid;

  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  const { heroId, tileKey, resourceChanges } = request.data;

  if (!heroId || typeof heroId !== 'string') {
    throw new HttpsError('invalid-argument', 'heroId must be provided and must be a string.');
  }

  if (!tileKey || typeof tileKey !== 'string') {
    throw new HttpsError('invalid-argument', 'tileKey must be provided and must be a string.');
  }

  if (!resourceChanges || typeof resourceChanges !== 'object') {
    throw new HttpsError('invalid-argument', 'resourceChanges must be provided as an object.');
  }

  const allowedResources = ['wood', 'stone', 'iron', 'food', 'gold'];

  await db.runTransaction(async (tx) => {
    const heroRef = db.collection('heroes').doc(heroId);
    const heroSnap = await tx.get(heroRef);

    if (!heroSnap.exists) {
      throw new HttpsError('not-found', 'Hero not found.');
    }

    const heroData = heroSnap.data()!;
    if (heroData.ownerId !== userId) {
      throw new HttpsError('permission-denied', 'You do not own this hero.');
    }

    if (heroData.state !== 'idle') {
      throw new HttpsError('failed-precondition', 'Hero must be idle to transfer resources.');
    }

    if (heroData.tileKey !== tileKey) {
      throw new HttpsError('invalid-argument', `Hero is not currently on tile ${tileKey}.`);
    }

    const tileRef = db.collection('mapTiles').doc(tileKey);
    const tileSnap = await tx.get(tileRef);
    const tileData = tileSnap.exists ? tileSnap.data() ?? {} : {};

    const heroRes: Record<string, number> = { ...(heroData.carriedResources || {}) };
    let targetRef: FirebaseFirestore.DocumentReference;
    let targetRes: Record<string, number> = {};
    let isVillage = false;

    if (tileData.villageId) {
      if (!heroData.insideVillage) {
        throw new HttpsError('failed-precondition', 'You must be inside the village to access its storage.');
      }

      const villageId = tileData.villageId;
      const villageRef = db.doc(`users/${userId}/villages/${villageId}`);
      const villageSnap = await tx.get(villageRef);
      if (!villageSnap.exists) {
        throw new HttpsError('not-found', 'Village data not found.');
      }

      const villageData = villageSnap.data()!;
      const lastUpdated: Date = villageData.lastUpdated?.toDate?.() ?? new Date(0);
      const now = new Date();

      const elapsedMinutes = (now.getTime() - lastUpdated.getTime()) / 60000;

      const production: Record<string, number> = villageData.productionPerHour || {};
      const stored: Record<string, number> = villageData.resources || {};

      if (Object.keys(production).length > 0 && elapsedMinutes > 0.05) {
        const gain: Record<string, number> = {
          wood: Math.floor((production.wood || 0) * (elapsedMinutes / 60)),
          stone: Math.floor((production.stone || 0) * (elapsedMinutes / 60)),
          food: Math.floor((production.food || 0) * (elapsedMinutes / 60)),
          iron: Math.floor((production.iron || 0) * (elapsedMinutes / 60)),
          gold: Math.floor((production.gold || 0) * (elapsedMinutes / 60)),
        };

        for (const res of allowedResources) {
          stored[res] = (stored[res] || 0) + (gain[res] || 0);
        }

        tx.update(villageRef, {
          resources: stored,
          lastUpdated: admin.firestore.Timestamp.fromDate(now),
        });

        console.log(`🌾 Refreshed village ${villageId} before resource transfer.`, gain);
      }

      targetRef = villageRef;
      targetRes = { ...(villageData.resources || {}) };
      isVillage = true;
    } else {
      targetRef = tileRef;
      targetRes = { ...(tileData.resources || {}) };
    }

    for (const res of allowedResources) {
      const change = resourceChanges[res];

      if (typeof change !== 'number' || change === 0) continue;

      const heroAmount = heroRes[res] ?? 0;
      const targetAmount = targetRes[res] ?? 0;

      if (change > 0) {
        if (targetAmount < change) {
          throw new HttpsError('failed-precondition', `Not enough ${res} to pick up.`);
        }
        heroRes[res] = heroAmount + change;
        targetRes[res] = targetAmount - change;
      } else {
        const dropAmount = Math.abs(change);
        if (heroAmount < dropAmount) {
          throw new HttpsError('failed-precondition', `Not enough ${res} to drop.`);
        }
        heroRes[res] = heroAmount - dropAmount;
        targetRes[res] = targetAmount + dropAmount;
      }
    }

    tx.update(heroRef, { carriedResources: heroRes });

    tx.set(targetRef, isVillage
      ? { resources: targetRes }
      : {
          tileKey,
          x: heroData.tileX,
          y: heroData.tileY,
          resources: targetRes,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        },
      { merge: true }
    );

    console.log(`💰 Hero ${heroId} transferred resources:`, resourceChanges, `→ ${isVillage ? 'village' : 'tile'} storage`);
  });

  return {
    success: true,
    message: 'Resources transferred successfully.',
  };
}
