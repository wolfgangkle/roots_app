export async function getCloudTasksClient() {
  const { CloudTasksClient } = await import('@google-cloud/tasks');
  return new CloudTasksClient();
}
