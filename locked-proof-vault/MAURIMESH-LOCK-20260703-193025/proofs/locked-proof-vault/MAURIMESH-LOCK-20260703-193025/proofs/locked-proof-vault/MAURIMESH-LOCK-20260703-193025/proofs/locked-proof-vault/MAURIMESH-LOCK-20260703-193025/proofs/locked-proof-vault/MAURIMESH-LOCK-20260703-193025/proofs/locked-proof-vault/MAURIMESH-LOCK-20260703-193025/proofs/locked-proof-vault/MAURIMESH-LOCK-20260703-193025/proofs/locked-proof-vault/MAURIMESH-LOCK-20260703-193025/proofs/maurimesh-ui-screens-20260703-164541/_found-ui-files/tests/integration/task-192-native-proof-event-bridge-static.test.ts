import {
  MAURIMESH_RAW_PACKET_PROOF_EVENT_NAME,
  TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER,
} from "../../src/maurimesh/live/nativeProofEventBridgeConstants";
import {
  TASK_192_API_CONFIG_HELPER_MARKER,
  getApiConfigStatus,
} from "../../src/maurimesh/config/apiConfig";

if (
  TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER !==
  "TASK_192_NATIVE_PROOF_EVENT_BRIDGE_20260608_A"
) {
  throw new Error("Wrong native proof event bridge marker");
}

if (MAURIMESH_RAW_PACKET_PROOF_EVENT_NAME !== "MauriMeshRawPacketProofEvent") {
  throw new Error("Wrong native proof event name");
}

if (
  TASK_192_API_CONFIG_HELPER_MARKER !==
  "TASK_192_API_CONFIG_HELPER_20260608_A"
) {
  throw new Error("Wrong API config marker");
}

const status = getApiConfigStatus();
if (typeof status.configured !== "boolean") {
  throw new Error("API config status failed");
}

console.log("PASS: TASK_192_NATIVE_PROOF_EVENT_BRIDGE_STATIC_TEST_20260608_A");
