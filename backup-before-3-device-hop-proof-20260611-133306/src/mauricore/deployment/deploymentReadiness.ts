import { checkBuildReadiness } from "../build/buildPipeline";

export function deploymentChecklist() {
  const build = checkBuildReadiness();

  return {
    ready: build.canBuildApk,
    checklist: [
      "Replit preview opens",
      "TypeScript passes",
      "MauriCore smoke test passes",
      "Proof ledger writes records",
      "Layer registry reports state",
      "Dashboard renders",
      "Simulation is labelled",
      "Native BLE is not claimed in Replit",
      "EAS/local APK build passes",
      "APK installs",
      "App opens without crash",
      "Two-phone BLE proof captured",
    ],
    build,
  };
}
