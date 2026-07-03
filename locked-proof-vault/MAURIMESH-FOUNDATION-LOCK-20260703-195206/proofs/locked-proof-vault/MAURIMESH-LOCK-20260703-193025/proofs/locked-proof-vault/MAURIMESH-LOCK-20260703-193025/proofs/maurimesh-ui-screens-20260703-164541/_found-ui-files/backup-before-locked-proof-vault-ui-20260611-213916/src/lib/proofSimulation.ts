export type ProofEvent = {
  id: string;
  stage: string;
  status: "PASS" | "WAITING" | "ISOLATED";
  detail: string;
};

export const proofEvents: ProofEvent[] = [
  {
    id: "apk-shell",
    stage: "APK Launch",
    status: "PASS",
    detail: "com.maurimesh.messenger opens without RootLayout crash.",
  },
  {
    id: "router-stack",
    stage: "Router",
    status: "PASS",
    detail: "Safe Expo Router Stack opens dashboard and UI screens.",
  },
  {
    id: "ble-runtime",
    stage: "BLE Runtime",
    status: "ISOLATED",
    detail: "Native BLE send/receive proof is protected and not active in this UI shell.",
  },
  {
    id: "two-phone-proof",
    stage: "Two-Phone Proof",
    status: "WAITING",
    detail: "Requires physical device test after native proof UI is restored.",
  },
];
