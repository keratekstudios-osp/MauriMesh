/**
 * MauriMesh AI Self-Governance Validation Script
 * Run: pnpm --filter @workspace/mauri-mesh-engine run validate
 */

import { MauriMeshP2PEngine } from "./mauriMeshP2PEngine";

async function main() {
  const engine = new MauriMeshP2PEngine("phone-a");

  engine.ingestPeer({
    id: "phone-b",
    label: "Phone B",
    transport: "ble",
    rssi: -55,
    signal: 82,
    trust: 84,
    latencyMs: 160,
  });

  engine.ingestPeer({
    id: "phone-c",
    label: "Phone C Relay",
    transport: "wifi-lan",
    signal: 72,
    trust: 76,
    latencyMs: 220,
    status: "relay",
  });

  const direct = await engine.sendMessage("phone-b", {
    text: "Direct JumpCode test",
    timestamp: Date.now(),
  });

  const relayOrStore = await engine.sendMessage("phone-z", {
    text: "Unknown target route test",
    timestamp: Date.now(),
  });

  console.log("=== MauriMesh AI Self-Governance Validation ===");
  console.log("Direct result:", JSON.stringify(direct, null, 2));
  console.log("Relay/store result:", JSON.stringify(relayOrStore, null, 2));
  console.log("Snapshot:", JSON.stringify(engine.getSnapshot(), null, 2));

  if (!direct.packet.jumpCode.startsWith("JM-")) {
    throw new Error(`JumpCode was not generated. Got: ${direct.packet.jumpCode}`);
  }

  if (!engine.getSnapshot().governance.routeDecisions) {
    throw new Error("Governance route decisions were not recorded.");
  }

  console.log("\nVALIDATION PASSED ✓");
}

main().catch((err: unknown) => {
  console.error("VALIDATION FAILED", err);
  process.exit(1);
});
