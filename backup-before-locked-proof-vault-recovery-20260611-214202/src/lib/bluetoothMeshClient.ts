import {
  bluetoothMeshSuperEngine,
  BluetoothMode,
  TransportKind,
} from "../mesh/bluetoothMeshSuperEngine";

export function startBluetoothMeshRuntime() {
  bluetoothMeshSuperEngine.startRuntimeLoop();
  return bluetoothMeshSuperEngine.getSnapshot();
}

export function stopBluetoothMeshRuntime() {
  bluetoothMeshSuperEngine.stopRuntimeLoop();
  return bluetoothMeshSuperEngine.getSnapshot();
}

export function ingestBluetoothPeer(input: {
  id: string;
  label?: string;
  name?: string;
  rssi?: number;
  mode?: BluetoothMode;
  transport?: TransportKind;
}) {
  bluetoothMeshSuperEngine.ingestBluetoothPeer({
    id: input.id,
    label: input.label,
    name: input.name,
    rssi: input.rssi,
    mode: input.mode || "BLE_SCAN",
    transport: input.transport,
  });

  return bluetoothMeshSuperEngine.getSnapshot();
}

export async function sendBluetoothMeshMessage(to: string, text: string) {
  return bluetoothMeshSuperEngine.sendPacket(to, {
    text,
    timestamp: Date.now(),
  });
}

export function receiveBluetoothMeshPacket(packet: any) {
  return bluetoothMeshSuperEngine.receivePacket(packet);
}

export function learnBluetoothMeshRoute(input: {
  packetId: string;
  peerId: string;
  ok: boolean;
  latencyMs: number;
  reason?: string;
}) {
  bluetoothMeshSuperEngine.learn({
    ...input,
    timestamp: Date.now(),
  });

  return bluetoothMeshSuperEngine.getSnapshot();
}

export function getBluetoothMeshSnapshot() {
  return bluetoothMeshSuperEngine.getSnapshot();
}

export function seedBluetoothMeshDemo() {
  bluetoothMeshSuperEngine.ingestBluetoothPeer({
    id: "phone-a",
    name: "Phone A BLE GATT",
    rssi: -52,
    mode: "BLE_GATT",
  });

  bluetoothMeshSuperEngine.ingestBluetoothPeer({
    id: "relay-b",
    name: "Relay B Advertiser",
    rssi: -61,
    mode: "BLE_ADVERTISE",
    state: "relay",
    channel: "relay",
  } as any);

  bluetoothMeshSuperEngine.ingestBluetoothPeer({
    id: "phone-c",
    name: "Phone C Recovery",
    rssi: -78,
    mode: "BLE_SCAN",
    state: "recovering",
  } as any);

  return bluetoothMeshSuperEngine.getSnapshot();
}
