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
  const validRoles = ['member', 'officer'];
  if (!isKick && !validRoles.includes(newRole)) {
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

  const caller = callerSnap.data()!;
  const target = targetSnap.data()!;


  if (!caller?.guildId || caller.guildId !== target.guildId) {
    throw new HttpsError('failed-precondition', 'Both users must be in the same guild.');
  }

  if (targetUserId === callerId) {
    throw new HttpsError('permission-denied', 'You cannot change your own role.');
  }

  if (target.guildRole === 'leader') {
    throw new HttpsError('permission-denied', 'You cannot modify the leader.');
  }

  const callerRole = caller.guildRole;
  const targetRole = target.guildRole;

  const isCallerLeader = callerRole === 'leader';
  const isCallerOfficer = callerRole === 'officer';

  if (!isCallerLeader && !isCallerOfficer) {
    throw new HttpsError('permission-denied', 'You must be a leader or officer to do this.');
  }

  if (isCallerOfficer) {
    if (!isKick || targetRole !== 'member') {
      throw new HttpsError('permission-denied', 'Officers can only kick members.');
    }
  }

  const heroName = target.heroName ?? 'Unnamed Hero';
  const guildId = caller.guildId;

  const logRef = db.collection(`guilds/${guildId}/log`).doc();

  await db.runTransaction(async (tx) => {
    if (isKick) {
      tx.update(targetRef, {
        guildId: admin.firestore.FieldValue.delete(),
        guildRole: admin.firestore.FieldValue.delete(),
      });

      tx.set(logRef, {
        type: 'system',
        content: `👢 ${heroName} was kicked from the guild.`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      tx.update(targetRef, {
        guildRole: newRole,
      });

      const action = newRole === 'officer' ? 'promoted to officer' : 'demoted to member';
      tx.set(logRef, {
        type: 'system',
        content: `📜 ${heroName} was ${action}.`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

  console.log(`🔧 ${callerId} (${callerRole}) ${isKick ? 'kicked' : 'changed role of'} ${targetUserId} to ${newRole ?? 'none'}`);

  return {
    status: isKick ? 'kicked' : 'updated',
    targetUserId,
    newRole,
    message: isKick
      ? 'Member kicked from guild.'
      : `Guild role updated to ${newRole}.`,
  };
}
