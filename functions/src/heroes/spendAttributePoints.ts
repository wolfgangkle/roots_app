import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { updateHeroStats } from '../helpers/updateHeroStats.js';

const db = admin.firestore();

/**
 * Request:
 * {
 *   heroId: string,
 *   allocate: { strength?: number, dexterity?: number, intelligence?: number, constitution?: number }
 * }
 */
export const spendAttributePoints = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Login required');

  const { heroId, allocate } = req.data || {};
  if (typeof heroId !== 'string' || !allocate || typeof allocate !== 'object') {
    throw new HttpsError('invalid-argument', 'heroId and allocate are required');
  }

  // Sanitize & sum
  const addSTR = Math.max(0, Math.floor(Number(allocate.strength ?? 0)));
  const addDEX = Math.max(0, Math.floor(Number(allocate.dexterity ?? 0)));
  const addINT = Math.max(0, Math.floor(Number(allocate.intelligence ?? 0)));
  const addCON = Math.max(0, Math.floor(Number(allocate.constitution ?? 0)));
  const spendTotal = addSTR + addDEX + addINT + addCON;
  if (spendTotal <= 0) throw new HttpsError('invalid-argument', 'Nothing to spend');

  const heroRef = db.doc(`heroes/${heroId}`);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(heroRef);
    if (!snap.exists) throw new HttpsError('not-found', 'Hero not found');

    const hero = snap.data()!;
    if (hero.ownerId !== uid) throw new HttpsError('permission-denied', 'Not your hero');

    const unspent = Number(hero.unspentAttributePoints ?? 0);
    if (spendTotal > unspent) {
      throw new HttpsError('failed-precondition', 'Not enough unspent points');
    }

    // Current stats object; default each to 10 if missing
    const stats = {
      strength: Number(hero.stats?.strength ?? 10),
      dexterity: Number(hero.stats?.dexterity ?? 10),
      intelligence: Number(hero.stats?.intelligence ?? 10),
      constitution: Number(hero.stats?.constitution ?? 10),
    };

    // Apply allocation
    const nextStats = {
      strength: stats.strength + addSTR,
      dexterity: stats.dexterity + addDEX,
      intelligence: stats.intelligence + addINT,
      constitution: stats.constitution + addCON,
    };

    tx.update(heroRef, {
      stats: nextStats,
      unspentAttributePoints: unspent - spendTotal,
      lastAttributesSpendAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  // Recompute all derived fields using your existing helper
  await updateHeroStats(heroId);

  return { ok: true };
});
