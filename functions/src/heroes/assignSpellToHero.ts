import { HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function assignSpellToHeroLogic(request: CallableRequest<any>) {
  const userId = request.auth?.uid;
  const { heroId, spellId, conditions } = request.data;

  if (!userId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  if (!heroId || typeof heroId !== 'string') {
    throw new HttpsError('invalid-argument', 'heroId is required.');
  }

  if (!spellId || typeof spellId !== 'string') {
    throw new HttpsError('invalid-argument', 'spellId is required.');
  }

  if (typeof conditions !== 'object' || Array.isArray(conditions)) {
    throw new HttpsError('invalid-argument', 'conditions must be an object.');
  }

  if (Object.keys(conditions).length === 0) {
    throw new HttpsError(
      'invalid-argument',
      'At least one condition must be provided. Use removeAssignedSpellFromHero() to fully remove the assignment.'
    );
  }

  const heroRef = db.collection('heroes').doc(heroId);
  const heroSnap = await heroRef.get();

  if (!heroSnap.exists) {
    throw new HttpsError('not-found', 'Hero not found.');
  }

  const heroData = heroSnap.data();
  if (heroData?.ownerId !== userId) {
    throw new HttpsError('permission-denied', 'You do not own this hero.');
  }

  const allowedKeys = [
    'manaPercentageAbove',
    'manaAbove',
    'enemiesInCombatMin',
    'onlyIfEnemyHeroPresent',
    'maxCastsPerFight',
    'allyHpBelowPercentage',
  ];

  const sanitized: Record<string, any> = {};
  for (const [key, value] of Object.entries(conditions)) {
    if (!allowedKeys.includes(key)) {
      throw new HttpsError('invalid-argument', `Unknown condition key: ${key}`);
    }

    if (key === 'onlyIfEnemyHeroPresent') {
      if (typeof value !== 'boolean') {
        throw new HttpsError('invalid-argument', `Condition ${key} must be a boolean.`);
      }
    } else if (typeof value !== 'number' || isNaN(value)) {
      throw new HttpsError('invalid-argument', `Condition ${key} must be a number.`);
    } else {
      if (key.includes('Percentage') && (value < 1 || value > 100)) {
        throw new HttpsError('invalid-argument', `${key} must be between 1 and 100.`);
      }
      if (value < 0) {
        throw new HttpsError('invalid-argument', `${key} must be positive.`);
      }
    }

    sanitized[key] = value;
  }

  const ref = heroRef.collection('assignedSpells').doc(spellId);
  await ref.set(
    {
      spellId,
      conditions: sanitized,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }
  );

  console.log(
    `🧠 Spell "${spellId}" assigned to hero ${heroId} with conditions: ${JSON.stringify(sanitized)}`
  );

  return {
    success: true,
    message: 'Spell assigned successfully.',
  };
}
