import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { scheduleHeroArrivalTask } from './scheduleHeroArrivalTask.js';

export async function startHeroMovements(request: any) {
  const db = admin.firestore();
  const { heroId, destinationX, destinationY, movementQueue } = request.data;
  const userId = request.auth?.uid;

  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  if (!heroId) {
    throw new HttpsError('invalid-argument', 'heroId is required.');
  }

  if (!destinationX && !destinationY && !movementQueue) {
    throw new HttpsError('invalid-argument', 'You must provide a destination or movementQueue.');
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

  const now = Date.now();
  const heroMovementSpeed = typeof hero.movementSpeed === 'number'
    ? hero.movementSpeed * 1000
    : 20 * 60 * 1000; // fallback to 20 minutes

  const updateData: any = {
    state: 'moving',
    arrivesAt: admin.firestore.Timestamp.fromDate(new Date(now + heroMovementSpeed)),
  };

  // Determine how movement will be handled
  if (Array.isArray(movementQueue) && movementQueue.length > 0) {
    // Validate queue format
    for (const step of movementQueue) {
      if (
        typeof step !== 'object' ||
        (!('x' in step && 'y' in step) && !('action' in step))
      ) {
        throw new HttpsError('invalid-argument', 'Each movementQueue step must be a {x, y} or {action} object.');
      }
    }

    const firstStep = movementQueue[0];

    // If the first step is a coordinate, validate adjacency
    if ('x' in firstStep && 'y' in firstStep) {
      const dx = Math.abs(firstStep.x - hero.tileX);
      const dy = Math.abs(firstStep.y - hero.tileY);
      if (dx > 1 || dy > 1) {
        throw new HttpsError('invalid-argument', 'First movement step must be adjacent.');
      }

      updateData.destinationX = firstStep.x;
      updateData.destinationY = firstStep.y;
      updateData.nextTileKey = `${firstStep.x}_${firstStep.y}`;
    }

    updateData.movementQueue = movementQueue;
  } else {
    // Legacy single-step mode
    if (typeof destinationX !== 'number' || typeof destinationY !== 'number') {
      throw new HttpsError('invalid-argument', 'destinationX and destinationY must be numbers.');
    }

    const dx = Math.abs(destinationX - hero.tileX);
    const dy = Math.abs(destinationY - hero.tileY);
    if (dx > 1 || dy > 1) {
      throw new HttpsError('invalid-argument', 'Can only move to adjacent tiles (for now).');
    }

    updateData.destinationX = destinationX;
    updateData.destinationY = destinationY;
    updateData.nextTileKey = `${destinationX}_${destinationY}`;
    updateData.movementQueue = [];
  }

  await heroRef.update(updateData);

  const delaySeconds = Math.floor((updateData.arrivesAt.toDate().getTime() - now) / 1000);
  await scheduleHeroArrivalTask({ heroId, delaySeconds });

  console.log(`🧙 Hero ${heroId} started moving.`);
  if (updateData.movementQueue?.length) {
    console.log(`📜 Waypoints queued: ${JSON.stringify(updateData.movementQueue)}`);
  }

  return {
    success: true,
    arrivesAt: updateData.arrivesAt.toDate().toISOString(),
    hasQueue: updateData.movementQueue.length > 0,
  };
}
