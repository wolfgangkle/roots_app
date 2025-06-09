import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { runGroupPveCombatTick } from './modes/runGroupPveCombatTick.js';
// import { runGroupPvpCombatTick } from './modes/runGroupPvpCombatTick.js';

const db = admin.firestore();

export async function processCombatTickHandler(req: any, res: any) {
  try {
    const { combatId } = req.body;
    if (!combatId || typeof combatId !== 'string') {
      throw new HttpsError('invalid-argument', 'Missing or invalid combatId.');
    }

    const combatRef = db.collection('combats').doc(combatId);
    const combatSnap = await combatRef.get();

    if (!combatSnap.exists) {
      console.warn(`❌ Combat ${combatId} not found.`);
      res.status(404).send('Combat not found.');
      return;
    }

    const combat = combatSnap.data()!;
    if (combat.state !== 'ongoing') {
      console.log(`⚠️ Combat ${combatId} already ended.`);
      res.status(200).send('Combat already ended.');
      return;
    }

    if (combat.eventId && !combat.pvp) {
      await runGroupPveCombatTick(combatId, combat);
    } else {
      throw new HttpsError('failed-precondition', 'Unrecognized combat configuration.');
    }

    res.status(200).send('Tick processed.');
  } catch (err: any) {
    console.error('❌ Error in processCombatTick:', err);
    res.status(500).send(err.message || 'Internal error');
  }
}
