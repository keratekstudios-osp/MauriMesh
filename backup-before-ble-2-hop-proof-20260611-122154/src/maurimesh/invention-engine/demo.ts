import { LivingSelfGovernedAiMesh, MeshNode } from "./index";

const engine = new LivingSelfGovernedAiMesh();

const nodes: MeshNode[] = [
  {
    id: "PHONE_A",
    label: "Devan Phone",
    role: "ENDPOINT",
    trust: "VERIFIED",
    batteryPct: 88,
    signalPct: 92,
    online: true,
    lastSeenMs: Date.now(),
    transports: ["BLE", "WIFI_DIRECT", "LOCAL_WIFI"],
    culturalState: "WHANAUNGATANGA_TRUSTED",
  },
  {
    id: "PHONE_B",
    label: "Relay Phone",
    role: "RELAY",
    trust: "TRUSTED",
    batteryPct: 71,
    signalPct: 80,
    online: true,
    lastSeenMs: Date.now(),
    transports: ["BLE", "WIFI_DIRECT"],
  },
  {
    id: "PHONE_C",
    label: "Recipient Phone",
    role: "ENDPOINT",
    trust: "OBSERVED",
    batteryPct: 64,
    signalPct: 45,
    online: false,
    lastSeenMs: Date.now() - 60000,
    transports: ["BLE"],
  },
];

engine.setNodes(nodes);

const result = engine.send({
  from: "PHONE_A",
  to: "PHONE_C",
  body: "Kia kaha, emergency help message through MauriMesh.",
});

console.log("");
console.log("============================================================");
console.log("MAURIMESH INVENTION ENGINE DEMO RESULT");
console.log("============================================================");
console.log(JSON.stringify(result, null, 2));

console.log("");
console.log("============================================================");
console.log("VISUAL SNAPSHOT");
console.log("============================================================");
console.log(JSON.stringify(engine.visualSnapshot(), null, 2));
