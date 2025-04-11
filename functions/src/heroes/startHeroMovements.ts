import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { scheduleHeroArrivalTask } from './scheduleHeroArrivalTask.js';

const MOVEMENT_SPEED_PER_TILE = 20 * 60 * 1000; // 20 minutes

export async function startHeroMovements(request: any) {
  const db = admin.firestore(); // ✅ moved inside the function
  const { heroId, destinationX, destinationY, movementQueue } = request.data;
  const userId = request.auth?.uid;

  if (!userId) {
    throw new HttpsError('unauthenticated', 'You must be logged in.');
  }

  if (
    !heroId ||
    typeof destinationX !== 'number' ||
    typeof destinationY !== 'number'
  ) {
    throw new HttpsError('invalid-argument', 'Missing or invalid arguments.');
  }

  const heroRef = db.collection('heroes').doc(heroId);
  const heroSnap = await heroRef.get();
  const hero = heroSnap.data();

  if (!hero || hero.ownerId !== userId) {
    throw new HttpsError('not-found', 'Hero not found or access denied.');
  }

  if (hero.state !== 'idle') {
    throw new HttpsError('failed-precondition', 'Hero is currently busy.');
  }

  // ✅ Optional: check if destination is adjacent
  const dx = Math.abs(destinationX - hero.tileX);
  const dy = Math.abs(destinationY - hero.tileY);
  if (dx > 1 || dy > 1) {
    throw new HttpsError('invalid-argument', 'Can only move to adjacent tiles (for now).');
  }

  // ✅ Optional validation of movementQueue
  if (movementQueue && !Array.isArray(movementQueue)) {
    throw new HttpsError('invalid-argument', 'movementQueue must be an array of {x, y} coordinates.');
  }

  const now = Date.now();
  const travelDuration = MOVEMENT_SPEED_PER_TILE;
  const arrivesAt = new Date(now + travelDuration);

  const updateData: any = {
    state: 'moving',
    destinationX,
    destinationY,
    arrivesAt: admin.firestore.Timestamp.fromDate(arrivesAt),
  };

  if (movementQueue && movementQueue.length > 0) {
    updateData.movementQueue = movementQueue;
  }

  await heroRef.update(updateData);

  const delaySeconds = Math.floor((arrivesAt.getTime() - Date.now()) / 1000);
  await scheduleHeroArrivalTask({ heroId, delaySeconds });

  console.log(`🧙 Hero ${heroId} started moving to (${destinationX}, ${destinationY})`);
  if (movementQueue?.length) {
    console.log(`📜 Waypoints queued: ${JSON.stringify(movementQueue)}`);
  }

  return {
    success: true,
    arrivesAt: arrivesAt.toISOString(),
    hasQueue: !!movementQueue?.length,
  };
}
