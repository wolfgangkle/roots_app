import { HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function updateGuildRole(request: any) {
  const callerId = request.auth?.uid;
  const { targetUserId, newRole } = request.data;

  if (!callerId) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  if (!targetUserId || typeof targetUserId !== 'string') {
    throw new HttpsError('invalid-argument', 'Missing or invalid targetUserId.');
  }

  const isKick = newRole === null;
  if (!isKick && !['member', 'officer'].includes(newRole)) {
    throw new HttpsError('invalid-argument', 'Invalid newRole value.');
  }

  const callerRef = db.doc(`users/${callerId}/profile/main`);
  const targetRef = db.doc(`users/${targetUserId}/profile/main`);

  const [callerSnap, targetSnap] = await Promise.all([
    callerRef.get(),
    targetRef.get(),
  ]);

  if (!callerSnap.exists || !targetSnap.exists) {
    throw new HttpsError('not-found', 'Caller or target profile not found.');
  }

  const caller = callerSnap.data();
  const target = targetSnap.data();

  if (!caller || !target) {
    throw new HttpsError('not-found', 'Caller or target profile data missing.');
  }

  if (caller.guildId !== target.guildId || !caller.guildId) {
    throw new HttpsError('failed-precondition', 'Both users must be in the same guild.');
  }

  if (targetUserId === callerId) {
    throw new HttpsError('permission-denied', 'You cannot change your own role.');
  }

  if (target.guildRole === 'leader') {
    throw new HttpsError('permission-denied', 'You cannot modify the leader.');
  }

  if (caller.guildRole !== 'leader' && caller.guildRole !== 'officer') {
    throw new HttpsError('permission-denied', 'You must be a leader or officer to do this.');
  }

  await db.runTransaction(async (tx) => {
    if (isKick) {
      tx.update(targetRef, {
        guildId: admin.firestore.FieldValue.delete(),
        guildRole: admin.firestore.FieldValue.delete(),
      });
    } else {
      tx.update(targetRef, {
        guildRole: newRole,
      });
    }
  });

  console.log(`🔧 ${callerId} changed role of ${targetUserId} to ${newRole ?? 'kicked'}`);

  return {
    targetUserId,
    newRole,
    status: isKick ? 'kicked' : 'updated',
  };
}
