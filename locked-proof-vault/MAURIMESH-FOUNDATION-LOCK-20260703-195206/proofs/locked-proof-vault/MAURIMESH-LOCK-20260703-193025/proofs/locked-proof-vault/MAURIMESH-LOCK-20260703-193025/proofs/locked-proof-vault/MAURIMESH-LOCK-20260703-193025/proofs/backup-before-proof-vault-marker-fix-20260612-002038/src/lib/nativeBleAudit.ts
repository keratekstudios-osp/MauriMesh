export type NativeBleAuditStatus = {
  reportPath: string;
  nativeSignalCount: number;
  androidPermissionsSeen: "YES" | "NO";
  riskyStartupPatternSeen: "YES" | "NO";
  truth: string;
};

export const nativeBleAuditStatus: NativeBleAuditStatus = {
  reportPath: "docs/maurimesh-native-ble-proof-audit-20260607-015353.md",
  nativeSignalCount: Number("403"),
  androidPermissionsSeen: "YES" as "YES" | "NO",
  riskyStartupPatternSeen: "NO" as "YES" | "NO",
  truth:
    "Audit only. This confirms project evidence exists; it does not activate live BLE.",
};
