import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

export async function executeTrade(request: any) {
  const db = admin.firestore();
  const userId = request.auth?.uid;
  if (!userId) throw new HttpsError('unauthenticated', 'You must be logged in.');

  const { villageId, direction, resourceType, amount } = request.data;

  const allowedResources = ['wood', 'stone', 'iron', 'food'];
  if (!villageId || typeof villageId !== 'string') {
    throw new HttpsError('invalid-argument', 'villageId must be a string.');
  }
  if (!['resourceToGold', 'goldToResource'].includes(direction)) {
    throw new HttpsError('invalid-argument', 'Invalid trade direction.');
  }
  if (!allowedResources.includes(resourceType)) {
    throw new HttpsError('invalid-argument', 'Invalid resource type.');
  }
  if (typeof amount !== 'number' || amount <= 0 || !Number.isFinite(amount)) {
    throw new HttpsError('invalid-argument', 'Amount must be a positive number.');
  }

  console.log('💱 Trade request received:', { villageId, direction, resourceType, amount });

  await db.runTransaction(async (tx) => {
    const villageRef = db.doc(`users/${userId}/villages/${villageId}`);
    const villageSnap = await tx.get(villageRef);
    if (!villageSnap.exists) {
      throw new HttpsError('not-found', 'Village not found.');
    }

    const village = villageSnap.data()!;
    const resources = village.resources ?? {};
    const now = new Date();
    const todayStr = now.toISOString().split('T')[0];

    const tradingToday = village.tradingToday ?? {};
    const tradedResources = (tradingToday.date === todayStr ? tradingToday.tradedResources : 0) ?? 0;
    const tradedGold = (tradingToday.date === todayStr ? tradingToday.tradedGold : 0) ?? 0;

    const maxResource = village.maxDailyResourceTradeAmount ?? 0;
    const maxGold = village.maxDailyGoldTradeAmount ?? 0;

    const configRef = db.doc('config/tradingRates');
    const configSnap = await tx.get(configRef);
    if (!configSnap.exists) throw new HttpsError('not-found', 'Trading rates config not found.');

    const config = configSnap.data()!;
    const rate = direction === 'resourceToGold'
      ? config.resourceToGold?.[resourceType]
      : config.goldToResource?.[resourceType];

    if (typeof rate !== 'number' || rate <= 0) {
      throw new HttpsError('failed-precondition', `Invalid rate for ${resourceType}.`);
    }

    const newResources = { ...resources };
    let newTradedResources = tradedResources;
    let newTradedGold = tradedGold;

    if (direction === 'resourceToGold') {
      if ((resources[resourceType] ?? 0) < amount) {
        throw new HttpsError('failed-precondition', `Not enough ${resourceType} to trade.`);
      }
      if (tradedResources + amount > maxResource) {
        throw new HttpsError('resource-exhausted', `Resource trade limit exceeded (${tradedResources + amount} > ${maxResource}).`);
      }

      newResources[resourceType] -= amount;
      const goldGained = Math.floor(amount * rate);
      newResources['gold'] = (newResources['gold'] ?? 0) + goldGained;
      newTradedResources += amount;

      console.log(`🔁 Traded ${amount} ${resourceType} → ${goldGained} gold`);
    } else {
      if ((resources['gold'] ?? 0) < amount) {
        throw new HttpsError('failed-precondition', 'Not enough gold.');
      }
      if (tradedGold + amount > maxGold) {
        throw new HttpsError('resource-exhausted', `Gold trade limit exceeded (${tradedGold + amount} > ${maxGold}).`);
      }

      const storageCapacity = village.storageCapacity ?? {};
      const current = resources[resourceType] ?? 0;
      const capacity = storageCapacity[resourceType] ?? 0;
      const resourceGained = Math.floor(amount * rate);
      const projected = current + resourceGained;

      if (projected > capacity) {
        throw new HttpsError(
          'failed-precondition',
          `Not enough storage for ${resourceType}. Would exceed limit: ${projected} > ${capacity}`
        );
      }

      newResources['gold'] -= amount;
      newResources[resourceType] = projected;
      newTradedGold += amount;

      console.log(`🔁 Traded ${amount} gold → ${resourceGained} ${resourceType}`);
    }

    tx.update(villageRef, {
      resources: newResources,
      tradingToday: {
        date: todayStr,
        tradedResources: newTradedResources,
        tradedGold: newTradedGold,
      },
      lastUpdated: admin.firestore.Timestamp.fromDate(now),
    });
  });

  console.log('✅ Trade completed successfully.');
  return { success: true, message: 'Trade completed.' };
}
