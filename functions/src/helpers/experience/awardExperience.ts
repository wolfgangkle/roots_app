// functions/src/helpers/experience/awardExperience.ts
import * as admin from 'firebase-admin';
import { levelFromTotalXp } from './xpCurve.js';

const db = admin.firestore();

export type AwardResult = {
  prevLevel: number;
  newLevel: number;
  prevXp: number;
  newXp: number;
  levelDelta: number;
  grantedPoints: number;  // points granted *this* award
  leveledUp: boolean;
};

export async function awardExperience(heroId: string, gainedXp: number): Promise<AwardResult | null> {
  if (gainedXp <= 0) return null;

  const heroRef = db.doc(`heroes/${heroId}`);

  return await db.runTransaction(async (tx) => {
    const snap = await tx.get(heroRef);
    if (!snap.exists) throw new Error(`Hero not found: ${heroId}`);

    const data = snap.data() || {};
    const prevXp = Number(data.xp ?? 0);
    const prevLevel = Number(data.level ?? 1);
    const newXp = prevXp + gainedXp;

    const computedLevel = levelFromTotalXp(newXp);
    const newLevel = Math.max(prevLevel, computedLevel);

    if (newLevel === prevLevel) {
      tx.update(heroRef, { xp: newXp });
      return {
        prevLevel, newLevel, prevXp, newXp,
        levelDelta: 0, grantedPoints: 0, leveledUp: false
      };
    }

    const levelDelta = newLevel - prevLevel;

    // ✅ 5 points per level
    const pointsPerLevel = 5;
    const currentUnspent = Number(data.unspentAttributePoints ?? 0);
    const grantedNow = levelDelta * pointsPerLevel;

    tx.update(heroRef, {
      xp: newXp,
      level: newLevel,
      unspentAttributePoints: currentUnspent + grantedNow,
      lastLevelUpAt: admin.firestore.FieldValue.serverTimestamp(),
      pendingLevelUp: {
        from: prevLevel,
        to: newLevel,
        points: grantedNow, // 5 * levels gained
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }
    });

    return {
      prevLevel, newLevel, prevXp, newXp,
      levelDelta, grantedPoints: grantedNow, leveledUp: true
    };
  });
}
