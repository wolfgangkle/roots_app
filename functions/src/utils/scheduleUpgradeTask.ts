import * as admin from 'firebase-admin';

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
  const location = 'us-central1'; // Change to 'europe-central2' if needed
  const queue = 'default';
  const url = `https://${location}-${project}.cloudfunctions.net/finishBuildingUpgradeScheduled`;

  const { getCloudTasksClient } = await import('../utils/cloudTasksClient.js');
  const client = await getCloudTasksClient();

  const parent = client.queuePath(project, location, queue);

  // 🏷️ Give the task a custom name so we can delete it later
  const taskName = `upgrade-${villageId}-${Date.now()}`;
  const fullTaskName = `${parent}/tasks/${taskName}`;

  const task = {
    name: fullTaskName,
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

  // ✅ Create the scheduled task
  await client.createTask({ parent, task });

  // 🧾 Save task name to Firestore so we can delete it later
  const villageRef = admin
    .firestore()
    .collection('users')
    .doc(userId)
    .collection('villages')
    .doc(villageId);

  await villageRef.update({
    currentBuildTaskName: fullTaskName,
  });

  console.log(`📅 Scheduled upgrade task: ${fullTaskName} (in ${delaySeconds}s)`);
}
