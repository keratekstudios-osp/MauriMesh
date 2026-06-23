import {
  MauriOperatingDomain,
  MauriOperatingLayer,
} from "./mauriOperatingTypes";

const domainPurposes: Record<MauriOperatingDomain, string> = {
  foundation:
    "identity, shared types, contracts, configuration, versioning, and stable system law",
  physical:
    "device body, Bluetooth permissions, power, foreground runtime, radio health, and hardware proof boundary",
  transport:
    "BLE scan, BLE advertise, BLE GATT, peer-to-peer transport, relay transport, and fallback transport",
  packet:
    "packet structure, encryption envelope, dedupe, TTL, fragmentation, reassembly, and ACK identity",
  routing:
    "route score, JumpCode, √2 balance, relay selection, path memory, latency, and congestion logic",
  learning:
    "permanent memory, cross-layer learning, score updates, pattern recognition, and route wisdom",
  healing:
    "watchdog, replacement layer, last-known-good mode, repair loop, crash containment, and recovery",
  tikanga:
    "purpose, consent, truth labels, kaitiaki safety, manaaki outcome, and cultural intelligence compatibility",
  whanau:
    "peer table, friend graph, trust graph, group resilience, path whakapapa, and relationship memory",
  observability:
    "Living Mesh, telemetry truth, logs, metrics, snapshots, proof reports, and debugging visibility",
  experience:
    "login, dashboard, chat, settings, add friend, pixel calling shell, and human control surface",
  proof:
    "Replit logic proof, TypeScript proof, API proof, APK proof, ADB/logcat proof, and physical phone evidence",
};

const layerNames: Record<MauriOperatingDomain, string[]> = {
  foundation: [
    "Shared Type Contract",
    "Runtime Config",
    "Identity Contract",
    "Device Identity",
    "Version Contract",
    "Permission Contract",
    "Packet Contract",
    "Route Contract",
    "Learning Contract",
    "Tikanga Contract",
    "Proof Contract",
    "Storage Contract",
    "System Law",
  ],
  physical: [
    "Bluetooth Permission Body",
    "BLE Radio State",
    "Foreground Service Guard",
    "Battery State Guard",
    "Thermal State Guard",
    "Device Capability Scan",
    "Android Runtime Bridge",
    "iOS Runtime Bridge",
    "Hardware Availability",
    "Physical Device Detector",
    "Radio Error Guard",
    "Power Optimizer",
    "Native Boundary Stop Guard",
  ],
  transport: [
    "BLE Scan Loop",
    "BLE Advertise Loop",
    "BLE GATT Server",
    "BLE GATT Client",
    "BLE Packet Send Shell",
    "BLE Packet Receive Shell",
    "Peer-to-Peer Channel",
    "Device-to-Device Channel",
    "Relay Channel",
    "Store-Forward Channel",
    "Transport Fallback",
    "Transport Health Score",
    "Transport Truth Label",
  ],
  packet: [
    "Packet ID",
    "Packet Envelope",
    "Packet Encryption",
    "Packet Signature",
    "Packet Deduplication",
    "TTL Guard",
    "Hop Count Guard",
    "Fragmentation",
    "Reassembly",
    "ACK Packet",
    "Reverse Path ACK",
    "Priority Field",
    "Payload Integrity",
  ],
  routing: [
    "Route Table",
    "Route Score",
    "RSSI Weight",
    "Latency Weight",
    "ACK Weight",
    "Recency Weight",
    "JumpCode Path",
    "√2 Balance",
    "Relay Selector",
    "Congestion Guard",
    "Loop Prevention",
    "Path Memory",
    "Route Decision Gate",
  ],
  learning: [
    "Permanent Runtime Memory",
    "Cross-Layer Learning Bus",
    "Route Success Lesson",
    "Route Failure Lesson",
    "ACK Lesson",
    "Peer Availability Lesson",
    "RSSI Pattern Lesson",
    "Latency Pattern Lesson",
    "Fallback Lesson",
    "JumpCode Lesson",
    "Tikanga Lesson",
    "Self-Heal Lesson",
    "Restart Memory Lesson",
  ],
  healing: [
    "Watchdog Loop",
    "Failure Detector",
    "Fallback Activator",
    "Replacement Layer",
    "Last Known Good State",
    "Repair Queue",
    "Retry Backoff",
    "Crash Containment",
    "State Rehydration",
    "Peer Return Recovery",
    "ACK Recovery",
    "Queue Drain Recovery",
    "Healing Score",
  ],
  tikanga: [
    "Purpose Check",
    "Consent Check",
    "Truth Label Check",
    "No Fake BLE Proof",
    "No Fake Telemetry",
    "Manaaki Outcome",
    "Kaitiaki Safety",
    "Tapu Safety Boundary",
    "Whakapapa Continuity",
    "Community Benefit",
    "Risk Reduction",
    "Ethical Route Gate",
    "Cultural Intelligence Compatibility",
  ],
  whanau: [
    "Peer Table",
    "Trusted Peer Memory",
    "Friend Graph",
    "Group Graph",
    "Relay Relationship",
    "Path Whakapapa",
    "Known Safe Peer",
    "Unknown Peer Caution",
    "Blocked Peer Exclusion",
    "Stale Peer Marking",
    "Peer Return Detection",
    "Community Route Health",
    "Whānau Resilience Score",
  ],
  observability: [
    "Living Mesh Snapshot",
    "Node Snapshot",
    "Route Beam Snapshot",
    "Queue Snapshot",
    "Learning Snapshot",
    "Whare Balance Snapshot",
    "Telemetry Truth",
    "Log Stream",
    "Runtime Health",
    "API Health",
    "Proof Log",
    "ADB Logcat Parser",
    "Operator Report",
  ],
  experience: [
    "Login Screen",
    "Dashboard Screen",
    "Chat Screen",
    "Settings Screen",
    "Add Friend Screen",
    "Living Mesh Screen",
    "Mesh Status Screen",
    "Pixel Calling Shell",
    "Status Pill",
    "Signal Card",
    "Route Visibility",
    "Truth Notice",
    "User Control Surface",
  ],
  proof: [
    "Replit Logic Proof",
    "TypeScript Proof",
    "Runtime Validation",
    "API Health Proof",
    "Simulation Label Proof",
    "No Fake BLE Claim Proof",
    "APK Build Proof",
    "Physical Phone Proof",
    "BLE Scan Proof",
    "BLE Advertise Proof",
    "GATT Transfer Proof",
    "ADB Logcat Proof",
    "Final Evidence Report",
  ],
};

const allDomains = Object.keys(layerNames) as MauriOperatingDomain[];

function scoreByCriticality(index: number): "core" | "high" | "medium" | "support" {
  if (index <= 3) return "core";
  if (index <= 7) return "high";
  if (index <= 10) return "medium";
  return "support";
}

export const mauri155LayerCatalog: MauriOperatingLayer[] = allDomains.flatMap(
  (domain, domainIndex) =>
    layerNames[domain].map((name, layerIndex) => {
      const globalIndex = domainIndex * 13 + layerIndex + 1;

      return {
        id: `mauri_${String(globalIndex).padStart(3, "0")}_${domain}_${name
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, "_")
          .replace(/^_|_$/g, "")}`,
        index: globalIndex,
        domain,
        name,
        purpose: `${name} supports ${domainPurposes[domain]}.`,
        criticality: scoreByCriticality(layerIndex + 1),
        state: "idle",
        score: domain === "proof" || domain === "physical" ? 0.45 : 0.72,
        learnsFrom: allDomains.filter(d => d !== domain),
        teachesTo: allDomains.filter(d => d !== domain),
      };
    })
);

export function getMauriLayerCount(): number {
  return mauri155LayerCatalog.length;
}

export function getMauriDomains(): MauriOperatingDomain[] {
  return allDomains;
}
