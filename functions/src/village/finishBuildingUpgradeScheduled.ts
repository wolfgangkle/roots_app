import * as functions from 'firebase-functions';
import { finishBuildingUpgradeLogic } from './finishBuildingUpgrade.js'; // Reuse your existing logic
import { CallableRequest } from 'firebase-functions/v2/https';


/**
 * 🌐 HTTP-triggered function for scheduled building upgrade via Cloud Tasks
 * Accepts { userId, villageId } as POST JSON body
 */
export const finishBuildingUpgradeScheduled = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const { userId, villageId, forceFinish = false } = req.body;

    if (!userId || !villageId) {
      res.status(400).send('Missing userId or villageId in request body.');
      return;
    }

    // ✅ Include forceFinish here
    const fakeRequest = {
      data: { villageId, forceFinish },
      auth: { uid: userId },
    } as CallableRequest<any>;

    const result = await finishBuildingUpgradeLogic(fakeRequest);

    console.log(`✅ Scheduled upgrade executed for village ${villageId}`);
    res.status(200).json({ success: true, result });
  } catch (error: any) {
    console.error('❌ Scheduled upgrade error:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

