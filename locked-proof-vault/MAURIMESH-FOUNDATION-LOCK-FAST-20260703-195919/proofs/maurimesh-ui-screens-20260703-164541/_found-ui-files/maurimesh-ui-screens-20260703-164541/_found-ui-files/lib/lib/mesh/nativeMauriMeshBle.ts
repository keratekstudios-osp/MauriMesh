import { NativeEventEmitter, NativeModules } from "react-native";

const { MauriMeshBle } = NativeModules;

const emitter = MauriMeshBle
  ? new NativeEventEmitter(MauriMeshBle)
  : null;

export async function startMauriMeshBlePeripheral(): Promise<boolean> {
  if (!MauriMeshBle?.startPeripheral) return false;
  return await MauriMeshBle.startPeripheral();
}

export async function stopMauriMeshBlePeripheral(): Promise<boolean> {
  if (!MauriMeshBle?.stopPeripheral) return false;
  return await MauriMeshBle.stopPeripheral();
}

export async function startMauriMeshBleScan(durationMs = 0): Promise<boolean> {
  if (!MauriMeshBle?.startScan) return false;
  return await MauriMeshBle.startScan(durationMs);
}

export async function stopMauriMeshBleScan(): Promise<boolean> {
  if (!MauriMeshBle?.stopScan) return false;
  return await MauriMeshBle.stopScan();
}

export async function checkMauriMeshBlePermissions(): Promise<
  Record<string, boolean>
> {
  if (!MauriMeshBle?.checkPermissions) return {};
  return await MauriMeshBle.checkPermissions();
}

export async function requestMauriMeshBlePermissions(): Promise<boolean> {
  if (!MauriMeshBle?.requestPermissions) return false;
  return await MauriMeshBle.requestPermissions();
}

/**
 * Restart the BLE advertiser with a full identity beacon so nearby devices can
 * discover this node via the friend-invite pipeline.
 *
 * On Android 8+ hardware that supports LE extended advertising the full JSON
 * payload { nodeId, publicKey, displayName } is embedded as service data under
 * FRIEND_INVITE_SERVICE_UUID (picked up by parseFriendBeacon in useBleTransport).
 * On older hardware a compact manufacturer-data record is used instead.
 *
 * Safe to call in Expo Go / web — returns false without error.
 */
export async function updateMauriMeshBleIdentityBeacon(
  nodeId: string,
  publicKey: string,
  displayName: string
): Promise<boolean> {
  if (!MauriMeshBle?.updateIdentityBeacon) return false;
  return await MauriMeshBle.updateIdentityBeacon(nodeId, publicKey, displayName);
}

export function onMauriMeshBleMessageReceived(
  callback: (json: string) => void
): () => void {
  if (!emitter) return () => {};
  const sub = emitter.addListener("MauriMeshBleMessageReceived", callback);
  return () => sub.remove();
}

export function onMauriMeshBleStatus(
  callback: (status: string) => void
): () => void {
  if (!emitter) return () => {};
  const sub = emitter.addListener("MauriMeshBleStatus", callback);
  return () => sub.remove();
}

/**
 * MeshCentralClient.kt emits a raw JSON string: {"address":"XX:XX","rssi":-70}
 * Callers are responsible for JSON.parse — the native bridge delivers the
 * payload as a primitive string, not a pre-parsed object.
 */
export function onMauriMeshBlePeerSeen(
  callback: (data: string) => void
): () => void {
  if (!emitter) return () => {};
  const sub = emitter.addListener("MauriMeshBlePeerSeen", callback);
  return () => sub.remove();
}

export function onMauriMeshBleError(
  callback: (error: string) => void
): () => void {
  if (!emitter) return () => {};
  const sub = emitter.addListener("MauriMeshBleError", callback);
  return () => sub.remove();
}
