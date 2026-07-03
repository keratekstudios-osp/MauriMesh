export async function checkMauriMeshBlePermissions() {
  return {
    granted: false,
    bluetooth: false,
    location: false,
  };
}

export async function requestMauriMeshBlePermissions() {
  return {
    granted: false,
    bluetooth: false,
    location: false,
  };
}

export default {
  checkMauriMeshBlePermissions,
  requestMauriMeshBlePermissions,
};
