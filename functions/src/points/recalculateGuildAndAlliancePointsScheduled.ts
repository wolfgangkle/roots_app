import { Request, Response } from 'express';
import { onRequest } from 'firebase-functions/v2/https';
import { recalculateGuildAndAlliancePoints } from '../helpers/recalculateGuildAndAlliancePoints.js';
import { scheduleGuildPointsTask } from '../utils/scheduleGuildPointsTask.js';

export const recalculateGuildAndAlliancePointsScheduled = onRequest(async (req: Request, res: Response) => {
  try {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    await recalculateGuildAndAlliancePoints();

    // 🔁 Automatically schedule the next one
    await scheduleGuildPointsTask({ delaySeconds: 3600 });

    console.log('✅ Recalculated + rescheduled guild/alliance point update');
    res.status(200).json({ success: true, message: 'Points updated and rescheduled' });
  } catch (error: any) {
    console.error('❌ Error in point recalculation:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});
