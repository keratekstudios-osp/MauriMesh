import { MeshMemory, RoutePipeline } from "./types";

const basePipelines: RoutePipeline[] = [
  {
    id: "A_B_WIFI_HOTSPOT_2HOP",
    label: "A06 PHONE_A_GATEWAY -> S10 PHONE_B_CLIENT -> ACK",
    hops: ["PHONE_A_GATEWAY", "PHONE_B_CLIENT", "PHONE_A_GATEWAY_ACK"],
    transports: ["WIFI_HOTSPOT", "LOCAL_WIFI", "APP_LOGIC"],
    trust: 62,
    latencyMs: 42,
    mistakes: 0,
    successes: 0,
    signedOff: false,
    truth: "Physical 2-phone proof requires A06 and S10 both present in ADB/logcat.",
  },
  {
    id: "A_B_C_APP_3HOP",
    label: "PHONE_A -> PHONE_B_RELAY -> PHONE_C_RECEIVER -> reverse ACK",
    hops: ["PHONE_A_SENDER", "PHONE_B_RELAY", "PHONE_C_RECEIVER", "PHONE_B_RELAY_ACK", "PHONE_A_SENDER_ACK"],
    transports: ["BLE", "BLE", "APP_LOGIC"],
    trust: 45,
    latencyMs: 88,
    mistakes: 0,
    successes: 0,
    signedOff: false,
    truth: "App-readiness only until a third MauriMesh relay device or Mac bridge exists.",
  },
  {
    id: "MAC_C_BRIDGE_CANDIDATE",
    label: "PHONE_A -> PHONE_B -> MAC_C_BRIDGE -> reverse ACK",
    hops: ["PHONE_A_SENDER", "PHONE_B_RELAY", "MAC_C_BRIDGE_CANDIDATE", "PHONE_B_RELAY_ACK", "PHONE_A_SENDER_ACK"],
    transports: ["BLE", "LOCAL_WIFI", "APP_LOGIC"],
    trust: 30,
    latencyMs: 120,
    mistakes: 0,
    successes: 0,
    signedOff: false,
    truth: "Mac can become C only after a companion relay bridge is built.",
  },
  {
    id: "AIRPODS_OBSERVED_ONLY",
    label: "AirPods BLE observed only",
    hops: ["BLE_PERIPHERAL_OBSERVED_ONLY"],
    transports: ["BLE"],
    trust: 5,
    latencyMs: 999,
    mistakes: 0,
    successes: 0,
    signedOff: false,
    truth: "AirPods cannot relay MauriMesh packets. Discovery only, no packet forwarding.",
  },
];

export function createInitialMemory(): MeshMemory {
  return {
    version: 1,
    generatedAt: new Date().toISOString(),
    routePipelines: basePipelines,
    mistakes: [],
    signedProofs: [],
    governanceWarnings: [],
  };
}

export function cloneMemory(memory: MeshMemory): MeshMemory {
  return JSON.parse(JSON.stringify(memory));
}
