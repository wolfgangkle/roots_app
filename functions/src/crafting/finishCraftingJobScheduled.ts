import * as functions from 'firebase-functions';
import { finishCraftingJobLogic } from './finishCraftingJob.js';
import { CallableRequest } from 'firebase-functions/v2/https';

/**
 * 🌐 HTTP-triggered function for scheduled crafting via Cloud Tasks
 * Accepts { userId, villageId } as POST JSON body
 */
export const finishCraftingJobScheduled = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const { userId, villageId } = req.body;

    if (!userId || !villageId) {
      res.status(400).send('Missing userId or villageId in request body.');
      return;
    }

    // Simulate a CallableRequest
    const fakeRequest = {
      data: { villageId },
      auth: { uid: userId },
    } as CallableRequest<any>;

    const result = await finishCraftingJobLogic(fakeRequest);

    console.log(`✅ Scheduled crafting completed for village ${villageId}`);
    res.status(200).json({ success: true, result });
  } catch (error: any) {
    console.error('❌ Scheduled crafting error:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});