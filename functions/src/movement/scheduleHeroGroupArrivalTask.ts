import * as admin from 'firebase-admin';

export async function scheduleHeroGroupArrivalTask({
  groupId,
  delaySeconds,
}: {
  groupId: string;
  delaySeconds: number;
}) {
  const { CloudTasksClient } = await import('@google-cloud/tasks'); // ✅ now inside the function

  const project = process.env.GCLOUD_PROJECT!;
  const location = 'europe-central2';
  const queue = 'default';
  const url = `https://${location}-${project}.cloudfunctions.net/processHeroGroupArrival`;

  const client = new CloudTasksClient();
  const parent = client.queuePath(project, location, queue);

  const taskName = `heroGroup-arrival-${groupId}-${Date.now()}`;
  const fullTaskName = `${parent}/tasks/${taskName}`;

  const task = {
    name: fullTaskName,
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

  await admin.firestore().collection('heroGroups').doc(groupId).update({
    currentMovementTaskName: fullTaskName,
  });

  console.log(`📅 Scheduled hero group arrival task: ${fullTaskName} (in ${delaySeconds}s)`);
}
