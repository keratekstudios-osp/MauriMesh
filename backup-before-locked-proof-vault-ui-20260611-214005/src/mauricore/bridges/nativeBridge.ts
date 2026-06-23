export type NativeBridgeStatus = {
  available: boolean;
  platform: "android" | "ios" | "web" | "unknown";
  reason: string;
};

export function getNativeBridgeStatus(): NativeBridgeStatus {
  return {
    available: false,
    platform: "unknown",
    reason:
      "Native bridge placeholder active. Real BLE/device bridge requires Android Kotlin/iOS Swift native module and physical-device proof.",
  };
}

export async function requestNativeBleSend(): Promise<{
  ok: false;
  reason: string;
}> {
  return {
    ok: false,
    reason:
      "Native BLE send is not available from Replit/JS scaffold. Wire Kotlin/Swift bridge and validate on phones.",
  };
}
