// functions/src/combat/grantXpForCombatOutcome.ts
import * as admin from 'firebase-admin';
import { awardExperience } from '../../helpers/experience/awardExperience.js';

const db = admin.firestore();

/**
 * Idempotently grants xpPerHero to each hero in recipientHeroIds
 * for a finished combat `combatId`.
 */
export async function grantXpForCombatOutcome(params: {
  combatId: string;
  recipientHeroIds: string[];
  xpPerHero: number;
}) {
  const { combatId, recipientHeroIds, xpPerHero } = params;
  if (xpPerHero <= 0 || recipientHeroIds.length === 0) return;

  await Promise.all(
    recipientHeroIds.map(async (heroId) => {
      const grantRef = db.doc(`heroes/${heroId}/xpGrants/${combatId}`);

      // Use a transaction to ensure idempotency per hero/combat.
      await db.runTransaction(async (tx) => {
        const grantSnap = await tx.get(grantRef);
        if (grantSnap.exists) {
          // Already granted for this combat -> skip
          return;
        }
        // Create the marker first; keeps it idempotent in case of concurrent retries.
        tx.set(grantRef, {
          source: 'combat',
          amount: xpPerHero,
          combatId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      // Outside the marker transaction, actually award the XP
      // (If this fails after the marker, re-calling will immediately skip due to marker).
      await awardExperience(heroId, xpPerHero);
    })
  );
}
