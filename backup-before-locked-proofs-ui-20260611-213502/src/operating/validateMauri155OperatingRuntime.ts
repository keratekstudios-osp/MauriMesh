import { getMauriLayerCount } from "./mauri155LayerCatalog";
import { Mauri155OperatingRuntime } from "./mauri155OperatingRuntime";

async function main() {
  const runtime = new Mauri155OperatingRuntime();

  const startSnapshot = runtime.start();

  runtime.teachRouteSuccess("peer-alpha", "packet-001");
  runtime.teachAckReceived("peer-alpha", "packet-001");
  runtime.teachRouteFailure("peer-beta", "packet-002");
  runtime.teachTikangaWarning("Do not claim live BLE proof inside Replit.");
  runtime.teachPhysicalBleRequired(
    "Real BLE proof requires APK, physical phones, and ADB/logcat."
  );

  const finalSnapshot = runtime.snapshot();

  console.log("");
  console.log("==================================================");
  console.log("MAURIMESH 155+ OPERATING RUNTIME VALIDATION");
  console.log("==================================================");
  console.log(`Layer count: ${getMauriLayerCount()}`);
  console.log(`Start decision: ${startSnapshot.decision}`);
  console.log(`Final decision: ${finalSnapshot.decision}`);
  console.log("");
  console.log(JSON.stringify(finalSnapshot, null, 2));
  console.log("==================================================");

  if (getMauriLayerCount() < 155) {
    throw new Error("Layer count is below 155.");
  }
}

main().catch(error => {
  console.error("[MauriMesh][155OperatingRuntime] validation failed", error);
  process.exit(1);
});
