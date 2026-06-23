import { AdapterReport, RiskLevel } from "../types/core.types";

export type CoreAdapter = {
  id: string;
  name: string;
  risk: RiskLevel;
  scan: () => AdapterReport;
};

const adapters = new Map<string, CoreAdapter>();

export function registerAdapter(adapter: CoreAdapter): CoreAdapter {
  adapters.set(adapter.id, adapter);
  return adapter;
}

export function runAdapters(): AdapterReport[] {
  return [...adapters.values()].map((adapter) => adapter.scan());
}

registerAdapter({
  id: "react_native_adapter",
  name: "React Native Adapter",
  risk: "medium",
  scan: () => ({
    adapterId: "react_native_adapter",
    ok: true,
    findings: ["React Native UI layer expected under app/ and src/components/."],
    missing: [],
    risk: "medium",
  }),
});

registerAdapter({
  id: "expo_adapter",
  name: "Expo Adapter",
  risk: "medium",
  scan: () => ({
    adapterId: "expo_adapter",
    ok: true,
    findings: ["Expo/Replit preview can support UI and API testing only."],
    missing: ["Physical-device native proof required for BLE."],
    risk: "medium",
  }),
});

registerAdapter({
  id: "ble_adapter",
  name: "BLE Native Adapter",
  risk: "critical",
  scan: () => ({
    adapterId: "ble_adapter",
    ok: false,
    findings: ["BLE requires native Android/iOS bridge and physical phone validation."],
    missing: ["Two-phone BLE proof", "Native permission verification", "ACK capture"],
    risk: "critical",
  }),
});
