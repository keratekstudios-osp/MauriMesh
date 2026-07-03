const fs = require("fs");
const path = require("path");

const root = process.cwd();
const targets = [
"app/3-device-proof.tsx",
"app/ble-3-device-proof.tsx",
"app/store-forward-proof.tsx",
"app/ble-2-hop-proof.tsx",
];

const importLine =
'import { nativeBlePacketLogSafe } from "../src/maurimesh/native/nativeBlePacketLogger";';

function detectRole(stage) {
if (/A06|PHONE_A|ACK_RECEIVED|TX_A06/i.test(stage)) return "A06_PHONE_A";
if (/S10|PHONE_B|RELAY|RX_S10|ACK_RELAY/i.test(stage)) return "S10_PHONE_B";
if (/A16|PHONE_C|RX_A16|ACK_A16/i.test(stage)) return "A16_PHONE_C";
return "PHONE_UNKNOWN";
}

function nativeStageFor(stage) {
if (/TX_A06_TO_S10/i.test(stage)) return "GATT_WRITE_PACKET";
if (/RX_S10_FROM_A06/i.test(stage)) return "GATT_READ_PACKET";
if (/RELAY_S10_TO_A16/i.test(stage)) return "RELAY_PACKET_NATIVE";
if (/RX_A16_FROM_S10/i.test(stage)) return "GATT_READ_PACKET";
if (/ACK_A16_TO_S10/i.test(stage)) return "ACK_PACKET_NATIVE";
if (/ACK_RELAY_S10_TO_A06/i.test(stage)) return "ACK_PACKET_NATIVE";
if (/ACK_RECEIVED_A06/i.test(stage)) return "GATT_CHARACTERISTIC_CHANGED";
if (/STORE/i.test(stage)) return "GATT_WRITE_PACKET";
if (/EXAM_APPROVED/i.test(stage)) return "GATT_CHARACTERISTIC_CHANGED";
return "BLE_STAGE";
}

let changed = [];

for (const rel of targets) {
const file = path.join(root, rel);
if (!fs.existsSync(file)) continue;

let src = fs.readFileSync(file, "utf8");

if (!src.includes("nativeBlePacketLogSafe")) {
const firstImport = src.match(/^import .*?;$/m);
if (firstImport) {
src = src.replace(firstImport[0], ${firstImport[0]}\n${importLine});
} else {
src = ${importLine}\n${src};
}
}

// Patch console/log calls that include packetId and known proof stages.
const stages = [
"TX_A06_TO_S10",
"RX_S10_FROM_A06",
"RELAY_S10_TO_A16",
"RX_A16_FROM_S10",
"ACK_A16_TO_S10",
"ACK_RELAY_S10_TO_A06",
"ACK_RECEIVED_A06",
"TX_A06_TO_S10_STORE_REQUEST",
"S10_STORE_PACKET",
"S10_FORWARD_STORED_TO_A16",
"RX_A16_STORED_PACKET",
"ACK_A16_TO_S10_STORED",
"ACK_RELAY_S10_TO_A06_STORED",
"ACK_RECEIVED_A06_STORED",
"EXAM_APPROVED",
];

if (!src.includes("MAURIMESH_NATIVE_BLE_PACKET_PATCH_MARKER")) {
const helper = `

function mauriMeshNativePacketProofLog(stage: string, packetId: string, detail?: string) {
nativeBlePacketLogSafe({
role: "${rel.includes("store") ? "PHONE_STORE_FORWARD" : "PHONE_PROOF"}",
stage,
packetId,
transport: "BRIDGE_LOG_ONLY",
detail: detail || stage,
});
}
// MAURIMESH_NATIVE_BLE_PACKET_PATCH_MARKER
`;
src += helper;
}

// Add a visible comment block describing required calls; avoids destructive AST rewriting.
if (!src.includes("MAURIMESH_NATIVE_BLE_PACKET_REQUIRED_STAGE_MAP")) {
src += `

/*
MAURIMESH_NATIVE_BLE_PACKET_REQUIRED_STAGE_MAP

When proof stage buttons/log events fire, call:

nativeBlePacketLogSafe({
role: "A06_PHONE_A" | "S10_PHONE_B" | "A16_PHONE_C",
stage: "GATT_WRITE_PACKET" | "GATT_READ_PACKET" | "RELAY_PACKET_NATIVE" | "ACK_PACKET_NATIVE" | "GATT_CHARACTERISTIC_CHANGED",
packetId,
transport: "BRIDGE_LOG_ONLY",
detail: "TX_A06_TO_S10" | "RX_S10_FROM_A06" | "RELAY_S10_TO_A16" | "RX_A16_FROM_S10" | "ACK_A16_TO_S10" | "ACK_RELAY_S10_TO_A06" | "ACK_RECEIVED_A06"
});

This patch does not claim real BLE/GATT proof.
Real native PASS requires transport=BLE_GATT inside Android Bluetooth/GATT callbacks.
*/
`;
}

fs.writeFileSync(file, src);
changed.push(rel);
}

console.log("Patched proof files:");
for (const rel of changed) console.log("- " + rel);
if (changed.length === 0) {
console.log("No proof screen files found to patch. Logger files were still created.");
}
