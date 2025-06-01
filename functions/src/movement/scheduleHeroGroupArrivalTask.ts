export async function scheduleHeroGroupArrivalTask({
  groupId,
  delaySeconds,
}: {
  groupId: string;
  delaySeconds: number;
}) {
  const project = process.env.GCLOUD_PROJECT!;
  const location = 'us-central1'; // 🔁 Change this if you're using europe-central2 or similar
  const queue = 'default';
  const url = `https://${location}-${project}.cloudfunctions.net/processHeroGroupArrival`;

  const { CloudTasksClient } = await import('@google-cloud/tasks');
  const client = new CloudTasksClient();
  const parent = client.queuePath(project, location, queue);

  const task = {
    httpRequest: {
      httpMethod: 'POST' as const,
      url,
      headers: { 'Content-Type': 'application/json' },
      body: Buffer.from(JSON.stringify({ groupId })).toString('base64'),
    },
    scheduleTime: {
      seconds: Math.floor(Date.now() / 1000) + delaySeconds,
    },
  };

  await client.createTask({ parent, task });

  console.log(`⏳ Scheduled hero group arrival for groupId=${groupId} in ${delaySeconds}s`);
}
