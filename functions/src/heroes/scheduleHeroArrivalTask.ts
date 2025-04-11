export async function scheduleHeroArrivalTask({
  heroId,
  delaySeconds,
}: {
  heroId: string;
  delaySeconds: number;
}) {
  const project = process.env.GCLOUD_PROJECT!;
  const location = 'us-central1'; // Update if you use a different region
  const queue = 'default';
  const url = `https://${location}-${project}.cloudfunctions.net/processHeroArrival`;

  // Dynamic import to avoid ESM/CommonJS issues
  const { CloudTasksClient } = await import('@google-cloud/tasks');
  const client = new CloudTasksClient();
  const parent = client.queuePath(project, location, queue);

  const task = {
    httpRequest: {
      httpMethod: 'POST' as const,
      url,
      headers: { 'Content-Type': 'application/json' },
      body: Buffer.from(JSON.stringify({ heroId })).toString('base64'),
    },
    scheduleTime: {
      seconds: Math.floor(Date.now() / 1000) + delaySeconds,
    },
  };

  await client.createTask({ parent, task });

  console.log(`🧙 Scheduled hero arrival for heroId=${heroId} in ${delaySeconds} seconds`);
}
