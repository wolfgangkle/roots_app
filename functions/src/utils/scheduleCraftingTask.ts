export async function scheduleCraftingTask({
  villageId,
  userId,
  delaySeconds,
}: {
  villageId: string;
  userId: string;
  delaySeconds: number;
}) {
  const project = process.env.GCLOUD_PROJECT!;
  const location = 'us-central1'; // Or europe-west3 if you moved your region
  const queue = 'default'; // Or 'crafting-jobs' if you created a separate queue
  const url = `https://${location}-${project}.cloudfunctions.net/finishCraftingJobScheduled`;

  const { CloudTasksClient } = await import('@google-cloud/tasks');

  const client = new CloudTasksClient();
  const parent = client.queuePath(project, location, queue);

  const task = {
    httpRequest: {
      httpMethod: 'POST' as const,
      url,
      headers: { 'Content-Type': 'application/json' },
      body: Buffer.from(JSON.stringify({ villageId, userId })).toString('base64'),
    },
    scheduleTime: {
      seconds: Math.floor(Date.now() / 1000) + delaySeconds,
    },
  };

  await client.createTask({ parent, task });
}
