import { BluetoothMeshSuperEngine } from "./bluetoothMeshSuperEngine";

async function main() {
  const engine = new BluetoothMeshSuperEngine("phone-a");

  engine.ingestBluetoothPeer({
    id: "phone-b",
    name: "Phone B",
    rssi: -53,
    mode: "BLE_GATT",
  });

  engine.ingestBluetoothPeer({
    id: "phone-c",
    name: "Phone C Relay",
    rssi: -63,
    mode: "BLE_ADVERTISE",
    state: "relay",
    channel: "relay",
  });

  const direct = await engine.sendPacket("phone-b", {
    text: "Bluetooth direct device-to-device test",
  });

  const relayOrStore = await engine.sendPacket("phone-z", {
    text: "Bluetooth relay/store-forward test",
  });

  const blocked = await engine.sendPacket("phone-b", {
    text: "attempt to exploit and bypass",
  });

  engine.learn({
    packetId: direct.packet.id,
    peerId: "phone-b",
    ok: false,
    latencyMs: 1800,
    reason: "Forced failure test",
    timestamp: Date.now(),
  });

  engine.selfHeal();
  const drain = engine.drainQueue();
  const snapshot = engine.getSnapshot();

  console.log("=== MAURIMESH BLUETOOTH SUPER ENGINE VALIDATION ===");
  console.log("Direct:", direct);
  console.log("Relay/store:", relayOrStore);
  console.log("Blocked:", blocked);
  console.log("Drain:", drain);
  console.log("Snapshot:", JSON.stringify(snapshot, null, 2));

  if (!direct.packet.jumpCode.startsWith("JM-")) {
    throw new Error("JumpCode failed.");
  }

  if (snapshot.stats.routeDecisions < 3) {
    throw new Error("Route decisions not recorded.");
  }

  if (!snapshot.routes.some((route) => route.sqrt2Balance > 0)) {
    throw new Error("√2 Bluetooth balance failed.");
  }

  if (snapshot.peers.length < 2) {
    throw new Error("Bluetooth peers not recorded.");
  }

  if (blocked.decision.kind !== "BLOCK") {
    throw new Error("Tikanga/cultural intelligence block test failed.");
  }

  console.log("VALIDATION PASSED");
}

main().catch((error) => {
  console.error("VALIDATION FAILED", error);
  process.exit(1);
});
