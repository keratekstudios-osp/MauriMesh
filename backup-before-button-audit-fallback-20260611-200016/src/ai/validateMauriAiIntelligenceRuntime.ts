import { MauriAiIntelligenceRuntime } from "./mauriAiIntelligenceRuntime";
import { MauriAiRouteCandidate, MauriAiSignal } from "./mauriAiTypes";

async function main() {
  const runtime = new MauriAiIntelligenceRuntime();

  const candidates: MauriAiRouteCandidate[] = [
    {
      peerId: "peer-alpha",
      routeId: "route-alpha",
      hops: 1,
      rssi: -48,
      latencyMs: 120,
      ackRate: 0.94,
      trustScore: 0.9,
      queuePressure: 5,
      lastSeenAgeMs: 1000,
    },
    {
      peerId: "peer-beta",
      routeId: "route-beta",
      hops: 2,
      rssi: -70,
      latencyMs: 800,
      ackRate: 0.62,
      trustScore: 0.72,
      queuePressure: 20,
      lastSeenAgeMs: 20000,
    },
    {
      peerId: "peer-gamma",
      routeId: "route-gamma",
      hops: 3,
      rssi: -84,
      latencyMs: 1600,
      ackRate: 0.38,
      trustScore: 0.6,
      queuePressure: 55,
      lastSeenAgeMs: 60000,
    },
  ];

  const replitSignal: MauriAiSignal = {
    peerId: "peer-alpha",
    packetId: "packet-001",
    physicalBleProven: false,
    tikangaSafe: true,
    peerTrusted: true,
    batterySafe: true,
    ackSuccess: true,
  };

  const physicalSignal: MauriAiSignal = {
    peerId: "peer-alpha",
    packetId: "packet-002",
    physicalBleProven: true,
    tikangaSafe: true,
    peerTrusted: true,
    batterySafe: true,
    ackSuccess: true,
  };

  runtime.storePacket("packet-store-001", "peer-beta", {
    text: "Store-forward test payload",
  });

  console.log("");
  console.log("==================================================");
  console.log("MAURI AI ROUTING INTELLIGENCE VALIDATION");
  console.log("==================================================");

  console.log("");
  console.log("REPLIT LOGIC DECISION");
  console.log(JSON.stringify(runtime.decide(replitSignal, candidates), null, 2));

  console.log("");
  console.log("PHYSICAL BLE-PROVEN DECISION");
  console.log(JSON.stringify(runtime.decide(physicalSignal, candidates), null, 2));

  console.log("");
  console.log("STORE-FORWARD SNAPSHOT");
  console.log(JSON.stringify(runtime.storeForwardSnapshot(), null, 2));

  console.log("==================================================");
}

main().catch(error => {
  console.error("[MauriMesh][MauriAiIntelligenceRuntime] validation failed", error);
  process.exit(1);
});
