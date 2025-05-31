import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function recalculateGuildAndAlliancePoints(): Promise<void> {
  const guildsSnap = await db.collection('guilds').get();
  const allGuildPoints: Record<string, number> = {};

  for (const guildDoc of guildsSnap.docs) {
    const guildId = guildDoc.id;
    const guildData = guildDoc.data();
    const memberIds: string[] = guildData?.memberUserIds ?? [];


    let totalPoints = 0;

    if (memberIds.length > 0) {
      const profileRefs = memberIds.map(uid =>
        db.doc(`users/${uid}/profile/main`)
      );
      const profileSnaps = await db.getAll(...profileRefs);

      for (const snap of profileSnaps) {
        const data = snap.data();
        const buildingPoints = data?.totalBuildingPoints ?? 0;
        const heroPoints = data?.totalHeroPoints ?? 0;
        totalPoints += buildingPoints + heroPoints;
      }
    }

    allGuildPoints[guildId] = totalPoints;

    await db.collection('guilds').doc(guildId).update({
      points: totalPoints,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Guild "${guildId}" updated: ${totalPoints} points (${memberIds.length} members)`);
  }

  // === Update alliance points ===
  const alliancesSnap = await db.collection('alliances').get();

  for (const allianceDoc of alliancesSnap.docs) {
    const allianceId = allianceDoc.id;
    const allianceData = allianceDoc.data();
    const guildIds: string[] = allianceData?.guildIds ?? [];

    const alliancePoints = guildIds.reduce((sum, gid) => {
      return sum + (allGuildPoints[gid] ?? 0);
    }, 0);

    await db.collection('alliances').doc(allianceId).update({
      points: alliancePoints,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`🏰 Alliance "${allianceId}" updated: ${alliancePoints} points (${guildIds.length} guilds)`);
  }

  console.log('🎉 Finished recalculating guild and alliance points.');
}
