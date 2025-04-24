import * as admin from 'firebase-admin';
import { heroStatFormulas } from './heroStatFormulas';
import {
  calculateHeroWeight,
  calculateAdjustedMovementSpeed,
} from './heroWeight';


const db = admin.firestore();

/**
 * Fully recalculates hero stats and ensures group data is synced.
 */
export async function updateHeroStats(heroId: string): Promise<void> {
  const heroRef = db.collection('heroes').doc(heroId);
  const heroSnap = await heroRef.get();
  if (!heroSnap.exists) return;

  const hero = heroSnap.data()!;
  const stats = hero.stats || {};
  const equipped = hero.equipped || {};
  const backpack = Array.isArray(hero.backpack) ? hero.backpack : [];
  const carriedResources = hero.carriedResources || {};

  const {
    hpMax,
    manaMax,
    hpRegen,
    manaRegen,
    carryCapacity,
    maxWaypoints,
    baseMovementSpeed,
    combatLevel,
    combat,
  } = heroStatFormulas(stats, equipped);

  const currentWeight = calculateHeroWeight(equipped, backpack, carriedResources);
  const movementSpeed = calculateAdjustedMovementSpeed(baseMovementSpeed, currentWeight, carryCapacity);

  await heroRef.update({
    hpMax,
    manaMax,
    hpRegen,
    manaRegen,
    carryCapacity,
    maxWaypoints,
    baseMovementSpeed,
    movementSpeed,
    currentWeight,
    combat,
    combatLevel,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 🔁 Always recalculate group stats if hero is in a group
  const groupId = hero.groupId;
  if (groupId) {
    const groupRef = db.collection('heroGroups').doc(groupId);
    const groupSnap = await groupRef.get();
    if (groupSnap.exists) {
      const groupData = groupSnap.data();
      const memberIds: string[] = groupData?.members || [];

      const memberRefs = memberIds.map(id => db.collection('heroes').doc(id));
      const memberSnaps = await db.getAll(...memberRefs);

      const totalCombatLevel = memberSnaps.reduce((sum, snap) => {
        return sum + (snap.exists ? snap.data()?.combatLevel || 0 : 0);
      }, 0);

      const slowestSpeed = Math.max(
        ...memberSnaps.map(snap => snap.exists ? snap.data()?.movementSpeed ?? 999999 : 999999)
      );

      await groupRef.update({
        combatLevel: totalCombatLevel,
        movementSpeed: slowestSpeed,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`👥 Updated group ${groupId} stats: CL=${totalCombatLevel}, Speed=${slowestSpeed}`);
    }
  }

  console.log(`⚔️ Hero ${heroId} stats updated (CL=${combatLevel}, Speed=${movementSpeed})`);
}
