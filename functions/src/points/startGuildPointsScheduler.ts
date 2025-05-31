import { onCall } from 'firebase-functions/v2/https';
import { scheduleGuildPointsTask } from '../utils/scheduleGuildPointsTask.js';

export const startGuildPointsScheduler = onCall(async (request) => {
  const { delaySeconds = 3600 } = request.data || {};

  await scheduleGuildPointsTask({ delaySeconds });

  console.log(`🟢 Manually triggered guild point scheduler for ${delaySeconds} seconds`);
  return { success: true, message: `Scheduled in ${delaySeconds} seconds.` };
});
