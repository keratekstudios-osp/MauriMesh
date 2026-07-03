import { getMauriRuntimeIntegrationBridge } from "./mauriRuntimeIntegrationBridge";

async function main() {
  const bridge = getMauriRuntimeIntegrationBridge();

  bridge.feed({
    type: "route_success",
    peerId: "peer-alpha",
    packetId: "packet-001",
  });

  bridge.feed({
    type: "ack_received",
    peerId: "peer-alpha",
    packetId: "packet-001",
  });

  bridge.feed({
    type: "route_failure",
    peerId: "peer-beta",
    packetId: "packet-002",
  });

  bridge.feed({
    type: "tikanga_warning",
    reason: "Do not claim live BLE proof inside Replit.",
  });

  bridge.feed({
    type: "physical_ble_required",
    reason: "Real BLE proof requires APK, physical phones, and ADB/logcat.",
  });

  const snapshot = bridge.snapshot();

  console.log("");
  console.log("==================================================");
  console.log("MAURIMESH RUNTIME INTEGRATION BRIDGE VALIDATION");
  console.log("==================================================");
  console.log(JSON.stringify(snapshot, null, 2));
  console.log("==================================================");

  if (snapshot.layerCount < 155) {
    throw new Error("Runtime layer count is below 155.");
  }
}

main().catch(error => {
  console.error("[MauriMesh][IntegrationBridge] validation failed", error);
  process.exit(1);
});
