export async function scheduleUpgradeTask({
  villageId,
  userId,
  delaySeconds,
}: {
  villageId: string;
  userId: string;
  delaySeconds: number;
}) {
  const project = process.env.GCLOUD_PROJECT!;
  const location = 'us-central1';
  const queue = 'default';
  const url = `https://${location}-${project}.cloudfunctions.net/finishBuildingUpgradeScheduled`;

  // ✅ Dynamic import to support ESM module in CommonJS code
  const { CloudTasksClient } = await import('@google-cloud/tasks');

  const client = new CloudTasksClient();
  const parent = client.queuePath(project, location, queue);

  const task = {
    httpRequest: {
      httpMethod: 'POST' as const, // ✅ Explicit typing to satisfy TS
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
