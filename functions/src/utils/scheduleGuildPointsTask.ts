import { getCloudTasksClient } from './cloudTasksClient.js';

export async function scheduleGuildPointsTask({
  delaySeconds = 3600,
}: {
  delaySeconds?: number;
}) {
  const project = process.env.GCLOUD_PROJECT!;
  const location = 'us-central1'; // Or 'us-central1' if you're still using it
  const queue = 'default';

  const url = `https://${location}-${project}.cloudfunctions.net/recalculateGuildAndAlliancePointsScheduled`;

  const client = await getCloudTasksClient();
  const parent = client.queuePath(project, location, queue);

  const taskName = `guildPoints-${Date.now()}`;
  const fullTaskName = `${parent}/tasks/${taskName}`;

  const task = {
    name: fullTaskName,
    httpRequest: {
      httpMethod: 'POST' as const,
      url,
      headers: { 'Content-Type': 'application/json' },
      body: Buffer.from(JSON.stringify({})).toString('base64'),
    },
    scheduleTime: {
      seconds: Math.floor(Date.now() / 1000) + delaySeconds,
    },
  };

  await client.createTask({ parent, task });

  console.log(`📅 Scheduled guild/alliance point update in ${delaySeconds}s as ${taskName}`);
}
