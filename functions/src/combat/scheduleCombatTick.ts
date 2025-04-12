export async function scheduleCombatTick({
  combatId,
  delaySeconds,
}: {
  combatId: string;
  delaySeconds: number;
}) {
  const project = process.env.GCLOUD_PROJECT!;
  const location = 'us-central1'; // update if you're using a different region
  const queue = 'default';
  const url = `https://${location}-${project}.cloudfunctions.net/processCombatTickScheduled`;

  const { CloudTasksClient } = await import('@google-cloud/tasks'); // ✅ dynamic import
  const client = new CloudTasksClient();
  const parent = client.queuePath(project, location, queue);

  const task = {
    httpRequest: {
      httpMethod: 'POST' as const,
      url,
      headers: { 'Content-Type': 'application/json' },
      body: Buffer.from(JSON.stringify({ combatId })).toString('base64'),
    },
    scheduleTime: {
      seconds: Math.floor(Date.now() / 1000) + delaySeconds,
    },
  };

  await client.createTask({ parent, task });

  console.log(`🗡️ Scheduled combat tick for ${combatId} in ${delaySeconds} seconds`);
}
