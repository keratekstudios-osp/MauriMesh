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

const requiredComment = `
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

const helper = `
function mauriMeshNativePacketProofLog(stage: string, packetId: string, detail?: string) {
  nativeBlePacketLogSafe({
    role: "PHONE_PROOF",
    stage,
    packetId,
    transport: "BRIDGE_LOG_ONLY",
    detail: detail || stage,
  });
}
// MAURIMESH_NATIVE_BLE_PACKET_PATCH_MARKER
`;

function addImport(src) {
  if (src.includes("nativeBlePacketLogSafe")) return src;

  const lines = src.split(/\r?\n/);
  let lastImportIndex = -1;

  for (let i = 0; i < lines.length; i++) {
    if (/^import\s.+?;?\s*$/.test(lines[i])) {
      lastImportIndex = i;
    }
  }

  if (lastImportIndex >= 0) {
    lines.splice(lastImportIndex + 1, 0, importLine);
    return lines.join("\n");
  }

  return importLine + "\n" + src;
}

let changed = [];

for (const rel of targets) {
  const file = path.join(root, rel);
  if (!fs.existsSync(file)) continue;

  let src = fs.readFileSync(file, "utf8");

  src = addImport(src);

  if (!src.includes("MAURIMESH_NATIVE_BLE_PACKET_PATCH_MARKER")) {
    src += "\n" + helper;
  }

  if (!src.includes("MAURIMESH_NATIVE_BLE_PACKET_REQUIRED_STAGE_MAP")) {
    src += "\n" + requiredComment;
  }

  fs.writeFileSync(file, src);
  changed.push(rel);
}

console.log("Patched proof files:");
if (changed.length === 0) {
  console.log("- No proof screen files found to patch.");
} else {
  for (const rel of changed) console.log("- " + rel);
}
