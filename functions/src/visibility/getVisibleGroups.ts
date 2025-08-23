// functions/src/visibility/getVisibleGroups.ts
import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';

const db = admin.firestore();

function maxScanRadius(spy: number, T = 10) {
  return Math.max(0, Math.floor(spy / T));
}
function isVisible(spy: number, camo: number, distance: number, T = 10, k = 1) {
  const R = maxScanRadius(spy, T);
  if (distance > R) return false;
  const S = (spy - camo) + k * (R - distance);
  return S >= 0;
}
function manhattan(aX: number, aY: number, bX: number, bY: number) {
  return Math.abs(aX - bX) + Math.abs(aY - bY); // or use Chebyshev if your movement is 8‑dir
}

export const getVisibleGroups = onCall(async (req) => {
  const uid = req.auth?.uid;
  const { viewerGroupId, T = 10, k = 1 } = req.data || {};
  if (!uid) throw new HttpsError('unauthenticated', 'Login required.');
  if (typeof viewerGroupId !== 'string') {
    throw new HttpsError('invalid-argument', 'viewerGroupId is required.');
  }

  // Load viewer group (and verify ownership)
  const viewRef = db.doc(`heroGroups/${viewerGroupId}`);
  const viewSnap = await viewRef.get();
  if (!viewSnap.exists) throw new HttpsError('not-found', 'Viewer group not found.');
  const viewer = viewSnap.data()!;
  if (viewer.ownerId !== uid) throw new HttpsError('permission-denied', 'Not your group.');

  const { tileX: cx, tileY: cy, spy = 0 } = viewer;
  const R = maxScanRadius(spy, T);
  if (R <= 0) return { groups: [], radius: 0 };

  // Bounding-box query
  const minX = cx - R, maxX = cx + R, minY = cy - R, maxY = cy + R;

  // If your data is big, consider indexing by sharded keys (e.g., region buckets)
  const q = db.collection('heroGroups')
    .where('tileX', '>=', minX).where('tileX', '<=', maxX)
    .where('tileY', '>=', minY).where('tileY', '<=', maxY);

  const snap = await q.get();

  const results:any[] = [];
  for (const doc of snap.docs) {
    if (doc.id === viewerGroupId) continue; // don't return self
    const g = doc.data()!;
    // Optional: skip same-owner allies, or mark them differently
    const d = manhattan(cx, cy, g.tileX, g.tileY); // or Chebyshev
    const camo = g.camo ?? 0;
    if (isVisible(spy, camo, d, T, k)) {
      // Redact sensitive fields
      results.push({
        groupId: doc.id,
        tileX: g.tileX,
        tileY: g.tileY,
        faction: g.faction ?? null,
        // Optional minimal summary (no ownerId, no emails)
        approxPower: g.combatLevel ?? null,
        lastSeenAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  return { groups: results, radius: R };
});
