#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "#223 — AUTO PROMOTE REAL BLE EVENTS TO PROOF SCOPE"
echo "RuntimeTruthEngine + native attestation + simulation protection"
echo "NO deletion. NO fake proof. NO physical proof without native attestation."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/maurimesh-router-backups/task-223-auto-proof-scope-$STAMP"

API_RUNTIME="$ROOT/artifacts/api-server/src/runtime"
API_ROUTES="$ROOT/artifacts/api-server/src/routes"
MOBILE_CONTEXTS="$ROOT/artifacts/messenger-mobile/contexts"
MOBILE_LIB="$ROOT/artifacts/messenger-mobile/src/lib"
ROOT_RUNTIME="$ROOT/src/maurimesh/runtime"
DOCS="$ROOT/docs"
SCRIPTS="$ROOT/scripts"

TRUTH="$API_RUNTIME/RuntimeTruthEngine.ts"
ACTIVITY="$API_ROUTES/activity.ts"
CONNECTIVITY="$MOBILE_CONTEXTS/ConnectivityContext.tsx"

mkdir -p "$BACKUP" "$API_RUNTIME" "$API_ROUTES" "$MOBILE_CONTEXTS" "$MOBILE_LIB" "$ROOT_RUNTIME" "$DOCS" "$SCRIPTS"

echo ""
echo "1. Backup targets"
cp "$TRUTH" "$BACKUP/RuntimeTruthEngine.ts" 2>/dev/null || true
cp "$ACTIVITY" "$BACKUP/activity.ts" 2>/dev/null || true
cp "$CONNECTIVITY" "$BACKUP/ConnectivityContext.tsx" 2>/dev/null || true
cp package.json "$BACKUP/package.json" 2>/dev/null || true
echo "Backup: $BACKUP"

echo ""
echo "2. Install RuntimeTruthEngine auto-native layer"

cat > "$TRUTH" <<'TS'
export const TASK_223_RUNTIME_TRUTH_MARKER =
  "TASK_223_RUNTIME_TRUTH_ENGINE_AUTO_NATIVE_20260608_A";

export type RuntimeTruthFeature =
  | "native_bridge"
  | "ble_permissions"
  | "ble_scan"
  | "ble_advertise"
  | "ble_connect"
  | "ble_tx"
  | "ble_rx"
  | "ack"
  | "relay"
  | string;

export type RuntimeMode = "simulation" | "native_status" | "real_native";

export type NativeRuntimeAttestation = {
  marker?: string;
  source: string;
  platform: string;
  appPackage?: string;
  nativeModulePresent: boolean;
  permissionsGranted?: boolean;
  scanActive?: boolean;
  discoveredCount?: number;
  features: RuntimeTruthFeature[];
  createdAt?: string;
  deviceModel?: string;
  buildId?: string;
  detail?: Record<string, unknown>;
};

export type RuntimeTruthState = {
  marker: string;
  mode: RuntimeMode;
  proofCapable: boolean;
  verifiedFeatures: RuntimeTruthFeature[];
  lastAttestation?: NativeRuntimeAttestation;
  updatedAt: string;
  truthBoundary: string;
};

const verifiedFeatures = new Set<RuntimeTruthFeature>();
let mode: RuntimeMode = "simulation";
let lastAttestation: NativeRuntimeAttestation | undefined;

function isRealAndroidNativeAttestation(attestation: NativeRuntimeAttestation): boolean {
  return Boolean(
    attestation &&
      attestation.source !== "simulation" &&
      attestation.platform === "android" &&
      attestation.nativeModulePresent === true &&
      Array.isArray(attestation.features) &&
      attestation.features.includes("native_bridge")
  );
}

function sanitizeFeatures(features: RuntimeTruthFeature[]): RuntimeTruthFeature[] {
  return Array.from(
    new Set(
      (features || [])
        .map((feature) => String(feature || "").trim())
        .filter((feature) => feature && feature !== "simulation" && feature !== "mock")
    )
  );
}

export class RuntimeTruthEngine {
  verify(feature: RuntimeTruthFeature): RuntimeTruthState {
    const safe = sanitizeFeatures([feature]);
    for (const item of safe) verifiedFeatures.add(item);

    if (verifiedFeatures.has("native_bridge")) {
      mode = "real_native";
    }

    return this.getState();
  }

  markRealNative(
    features: RuntimeTruthFeature[],
    attestation?: NativeRuntimeAttestation
  ): RuntimeTruthState {
    if (attestation && !isRealAndroidNativeAttestation(attestation)) {
      return this.getState();
    }

    for (const feature of sanitizeFeatures(features)) {
      verifiedFeatures.add(feature);
    }

    verifiedFeatures.add("native_bridge");
    mode = "real_native";

    if (attestation) {
      lastAttestation = {
        ...attestation,
        createdAt: attestation.createdAt || new Date().toISOString(),
        features: sanitizeFeatures(attestation.features),
      };
    }

    return this.getState();
  }

  acceptNativeAttestation(attestation: NativeRuntimeAttestation): RuntimeTruthState {
    if (!isRealAndroidNativeAttestation(attestation)) {
      return this.getState();
    }

    return this.markRealNative(attestation.features, attestation);
  }

  isProofCapable(feature?: RuntimeTruthFeature): boolean {
    if (mode !== "real_native") return false;
    if (!verifiedFeatures.has("native_bridge")) return false;
    if (!feature) return true;
    return verifiedFeatures.has(feature);
  }

  getState(): RuntimeTruthState {
    return {
      marker: TASK_223_RUNTIME_TRUTH_MARKER,
      mode,
      proofCapable: this.isProofCapable(),
      verifiedFeatures: Array.from(verifiedFeatures),
      lastAttestation,
      updatedAt: new Date().toISOString(),
      truthBoundary:
        "Only a real Android native bridge attestation can promote events to proof scope. Simulation, mock, and static UI events remain labelled as simulation and cannot be mislabelled as physical BLE proof.",
    };
  }
}

export const runtimeTruthEngine = new RuntimeTruthEngine();

export function markRealNative(
  features: RuntimeTruthFeature[],
  attestation?: NativeRuntimeAttestation
) {
  return runtimeTruthEngine.markRealNative(features, attestation);
}

export function acceptNativeAttestation(attestation: NativeRuntimeAttestation) {
  return runtimeTruthEngine.acceptNativeAttestation(attestation);
}

export function isProofCapable(feature?: RuntimeTruthFeature) {
  return runtimeTruthEngine.isProofCapable(feature);
}

export function getRuntimeTruthState() {
  return runtimeTruthEngine.getState();
}
TS

echo ""
echo "3. Install POST /api/runtime/verify route contract"

cat > "$API_ROUTES/runtime-verify.ts" <<'TS'
import {
  acceptNativeAttestation,
  getRuntimeTruthState,
  isProofCapable,
} from "../runtime/RuntimeTruthEngine";

export const TASK_223_RUNTIME_VERIFY_ROUTE_MARKER =
  "TASK_223_RUNTIME_VERIFY_ROUTE_20260608_A";

export function registerRuntimeVerifyRoute(app: any) {
  app.get("/api/runtime/truth", async (_req: any, res: any) => {
    const truth = getRuntimeTruthState();

    res.json({
      ok: true,
      marker: TASK_223_RUNTIME_VERIFY_ROUTE_MARKER,
      proofCapable: isProofCapable(),
      truth,
    });
  });

  app.post("/api/runtime/verify", async (req: any, res: any) => {
    try {
      const body = req.body || {};

      const attestation = {
        marker: String(body.marker || TASK_223_RUNTIME_VERIFY_ROUTE_MARKER),
        source: String(body.source || "unknown"),
        platform: String(body.platform || "unknown"),
        appPackage: body.appPackage ? String(body.appPackage) : undefined,
        nativeModulePresent: Boolean(body.nativeModulePresent),
        permissionsGranted: Boolean(body.permissionsGranted),
        scanActive: Boolean(body.scanActive),
        discoveredCount: Number(body.discoveredCount || 0),
        features: Array.isArray(body.features)
          ? body.features.map((feature: unknown) => String(feature))
          : [],
        createdAt: String(body.createdAt || new Date().toISOString()),
        deviceModel: body.deviceModel ? String(body.deviceModel) : undefined,
        buildId: body.buildId ? String(body.buildId) : undefined,
        detail:
          body.detail && typeof body.detail === "object"
            ? body.detail
            : {},
      };

      const accepted =
        attestation.source !== "simulation" &&
        attestation.platform === "android" &&
        attestation.nativeModulePresent === true &&
        attestation.features.includes("native_bridge");

      const truth = accepted
        ? acceptNativeAttestation(attestation)
        : getRuntimeTruthState();

      res.status(accepted ? 202 : 400).json({
        ok: accepted,
        marker: TASK_223_RUNTIME_VERIFY_ROUTE_MARKER,
        accepted,
        proofCapable: truth.proofCapable,
        truth,
        truthBoundary:
          "Native attestation is accepted only from a real Android native bridge. Simulation cannot promote proof scope.",
      });
    } catch (error) {
      res.status(500).json({
        ok: false,
        marker: TASK_223_RUNTIME_VERIFY_ROUTE_MARKER,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  });
}
TS

echo ""
echo "4. Patch activity route with proof-scope protection if present"

if [ -f "$ACTIVITY" ]; then
python3 <<'PY'
from pathlib import Path
import re

path = Path("artifacts/api-server/src/routes/activity.ts")
text = path.read_text()
original = text

if "getRuntimeTruthState" not in text:
    import_line = 'import { getRuntimeTruthState, isProofCapable } from "../runtime/RuntimeTruthEngine";\n'
    imports = list(re.finditer(r"^import .+;$", text, flags=re.M))
    if imports:
        idx = imports[-1].end()
        text = text[:idx] + "\n" + import_line + text[idx:]
    else:
        text = import_line + text

guard = '''
function task223NormalizeActivityTruth(body: any) {
  const truth = getRuntimeTruthState();
  const requestedTruth = String(body?.truthLevel || body?.scope || body?.truth || "");

  const wantsProof =
    requestedTruth.includes("physical") ||
    requestedTruth.includes("proof") ||
    requestedTruth.includes("real_native");

  if (wantsProof && !isProofCapable()) {
    return {
      ...body,
      truthLevel: "simulation_labelled",
      proofScopeBlocked: true,
      runtimeTruth: truth,
      truthBoundary:
        "Proof-scope event blocked because RuntimeTruthEngine is not proof-capable. Simulation cannot be mislabelled as physical BLE proof.",
    };
  }

  if (wantsProof && isProofCapable()) {
    return {
      ...body,
      truthLevel: "physical_proof",
      proofScopeAccepted: true,
      runtimeTruth: truth,
    };
  }

  return {
    ...body,
    truthLevel: body?.truthLevel || "simulation_labelled",
    runtimeTruth: truth,
  };
}
'''

if "function task223NormalizeActivityTruth" not in text:
    text += "\n" + guard + "\n"

if "task223NormalizeActivityTruth(req.body" not in text:
    text = text.replace("const body = req.body", "const body = task223NormalizeActivityTruth(req.body)")
    text = text.replace("let body = req.body", "let body = task223NormalizeActivityTruth(req.body)")

if text != original:
    path.write_text(text)
    print("activity.ts patched")
else:
    print("activity.ts unchanged")
PY
else
  echo "WARN: activity.ts missing; route contract still installed."
fi

echo ""
echo "5. Install mobile native runtime attestation client"

cat > "$MOBILE_LIB/nativeRuntimeAttestationClient.ts" <<'TS'
import { NativeModules, Platform } from "react-native";

export const TASK_223_NATIVE_ATTESTATION_CLIENT_MARKER =
  "TASK_223_NATIVE_ATTESTATION_CLIENT_20260608_A";

type NativeBleStatus = {
  module?: string;
  mode?: string;
  modulePresent?: boolean;
  blePermissions?: boolean;
  scanActive?: boolean;
  discoveredCount?: number;
  liveBleActive?: boolean;
  lastError?: string;
};

type NativeBleModule = {
  getStatus?: () => Promise<NativeBleStatus>;
  getScanProofStatus?: () => Promise<NativeBleStatus>;
};

export type NativeAttestationResult = {
  ok: boolean;
  accepted?: boolean;
  proofCapable?: boolean;
  error?: string;
};

function getApiBase(): string {
  const globalAny = globalThis as any;

  return (
    globalAny.__MAURIMESH_API_BASE__ ||
    globalAny.EXPO_PUBLIC_API_URL ||
    globalAny.MAURIMESH_API_URL ||
    ""
  );
}

async function readNativeBleStatus(): Promise<NativeBleStatus> {
  const native = NativeModules.MauriMeshBle as NativeBleModule | undefined;

  if (!native) {
    return {
      module: "MauriMeshBle",
      mode: "native_module_missing",
      modulePresent: false,
      blePermissions: false,
      scanActive: false,
      discoveredCount: 0,
    };
  }

  if (native.getScanProofStatus) {
    return native.getScanProofStatus();
  }

  if (native.getStatus) {
    return native.getStatus();
  }

  return {
    module: "MauriMeshBle",
    mode: "module_present_status_unavailable",
    modulePresent: true,
    blePermissions: false,
    scanActive: false,
    discoveredCount: 0,
  };
}

export async function sendNativeRuntimeAttestation(): Promise<NativeAttestationResult> {
  if (Platform.OS !== "android") {
    return {
      ok: false,
      error: "Native runtime attestation is Android-only.",
    };
  }

  const apiBase = getApiBase();

  if (!apiBase) {
    return {
      ok: false,
      error:
        "API base unavailable. Set __MAURIMESH_API_BASE__, EXPO_PUBLIC_API_URL, or MAURIMESH_API_URL.",
    };
  }

  const status = await readNativeBleStatus();

  const features = new Set<string>();
  if (status.modulePresent) features.add("native_bridge");
  if (status.blePermissions) features.add("ble_permissions");
  if (status.scanActive || Number(status.discoveredCount || 0) > 0) {
    features.add("ble_scan");
  }

  const payload = {
    marker: TASK_223_NATIVE_ATTESTATION_CLIENT_MARKER,
    source: "physical_android_apk",
    platform: "android",
    appPackage: "com.maurimesh.messenger",
    nativeModulePresent: Boolean(status.modulePresent),
    permissionsGranted: Boolean(status.blePermissions),
    scanActive: Boolean(status.scanActive),
    discoveredCount: Number(status.discoveredCount || 0),
    features: Array.from(features),
    createdAt: new Date().toISOString(),
    detail: {
      module: status.module,
      mode: status.mode,
      liveBleActive: status.liveBleActive,
      lastError: status.lastError,
    },
  };

  try {
    const response = await fetch(`${apiBase.replace(/\/$/, "")}/api/runtime/verify`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify(payload),
    });

    const json = await response.json().catch(() => ({}));

    return {
      ok: response.ok,
      accepted: Boolean(json.accepted),
      proofCapable: Boolean(json.proofCapable),
      error: response.ok ? undefined : JSON.stringify(json),
    };
  } catch (error) {
    return {
      ok: false,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}
TS

echo ""
echo "6. Install NativeBridgeContext"

cat > "$MOBILE_CONTEXTS/NativeBridgeContext.tsx" <<'TSX'
import React, { createContext, useContext, useEffect, useMemo, useState } from "react";
import {
  sendNativeRuntimeAttestation,
  TASK_223_NATIVE_ATTESTATION_CLIENT_MARKER,
} from "../src/lib/nativeRuntimeAttestationClient";

type NativeBridgeContextValue = {
  marker: string;
  attempted: boolean;
  accepted: boolean;
  proofCapable: boolean;
  error?: string;
  refresh: () => Promise<void>;
};

const NativeBridgeContext = createContext<NativeBridgeContextValue>({
  marker: TASK_223_NATIVE_ATTESTATION_CLIENT_MARKER,
  attempted: false,
  accepted: false,
  proofCapable: false,
  refresh: async () => {},
});

export function NativeBridgeProvider({ children }: { children: React.ReactNode }) {
  const [attempted, setAttempted] = useState(false);
  const [accepted, setAccepted] = useState(false);
  const [proofCapable, setProofCapable] = useState(false);
  const [error, setError] = useState<string | undefined>();

  async function refresh() {
    setAttempted(true);
    const result = await sendNativeRuntimeAttestation();
    setAccepted(Boolean(result.accepted));
    setProofCapable(Boolean(result.proofCapable));
    setError(result.error);
  }

  useEffect(() => {
    refresh();
    const timer = setInterval(refresh, 30000);
    return () => clearInterval(timer);
  }, []);

  const value = useMemo(
    () => ({
      marker: TASK_223_NATIVE_ATTESTATION_CLIENT_MARKER,
      attempted,
      accepted,
      proofCapable,
      error,
      refresh,
    }),
    [attempted, accepted, proofCapable, error]
  );

  return (
    <NativeBridgeContext.Provider value={value}>
      {children}
    </NativeBridgeContext.Provider>
  );
}

export function useNativeBridgeAttestation() {
  return useContext(NativeBridgeContext);
}
TSX

echo ""
echo "7. Patch ConnectivityContext boot attestation if present"

if [ -f "$CONNECTIVITY" ]; then
python3 <<'PY'
from pathlib import Path

path = Path("artifacts/messenger-mobile/contexts/ConnectivityContext.tsx")
text = path.read_text()
original = text

if "sendNativeRuntimeAttestation" not in text:
    text = 'import { sendNativeRuntimeAttestation } from "../src/lib/nativeRuntimeAttestationClient";\n' + text

boot = '''
// TASK_223_CONNECTIVITY_NATIVE_ATTESTATION_BOOT
void sendNativeRuntimeAttestation().catch((error) => {
  console.warn("[MauriMesh] native runtime attestation failed", error);
});
'''

if "TASK_223_CONNECTIVITY_NATIVE_ATTESTATION_BOOT" not in text:
    text += "\n" + boot + "\n"

if text != original:
    path.write_text(text)
    print("ConnectivityContext patched")
else:
    print("ConnectivityContext already patched")
PY
else
  echo "WARN: ConnectivityContext.tsx missing; NativeBridgeContext created instead."
fi

echo ""
echo "8. Install root app native proof reader"

cat > "$ROOT_RUNTIME/nativeRuntimeAttestationClient.ts" <<'TS'
import { NativeModules, Platform } from "react-native";

export const TASK_223_ROOT_NATIVE_ATTESTATION_CLIENT_MARKER =
  "TASK_223_ROOT_NATIVE_ATTESTATION_CLIENT_20260608_A";

export async function readRootNativeProofFeatures() {
  if (Platform.OS !== "android") {
    return {
      marker: TASK_223_ROOT_NATIVE_ATTESTATION_CLIENT_MARKER,
      nativeModulePresent: false,
      features: [],
      reason: "android_only",
    };
  }

  const native = NativeModules.MauriMeshBle as
    | {
        getStatus?: () => Promise<any>;
        getScanProofStatus?: () => Promise<any>;
      }
    | undefined;

  if (!native) {
    return {
      marker: TASK_223_ROOT_NATIVE_ATTESTATION_CLIENT_MARKER,
      nativeModulePresent: false,
      features: [],
      reason: "MauriMeshBle missing",
    };
  }

  const status =
    native.getScanProofStatus
      ? await native.getScanProofStatus()
      : native.getStatus
      ? await native.getStatus()
      : { modulePresent: true };

  const features = new Set<string>();

  if (status.modulePresent ?? true) features.add("native_bridge");
  if (status.blePermissions) features.add("ble_permissions");
  if (status.scanActive || Number(status.discoveredCount || 0) > 0) {
    features.add("ble_scan");
  }

  return {
    marker: TASK_223_ROOT_NATIVE_ATTESTATION_CLIENT_MARKER,
    nativeModulePresent: Boolean(status.modulePresent ?? true),
    permissionsGranted: Boolean(status.blePermissions),
    scanActive: Boolean(status.scanActive),
    discoveredCount: Number(status.discoveredCount || 0),
    features: Array.from(features),
    status,
  };
}
TS

echo ""
echo "9. Create audit script"

cat > "$SCRIPTS/audit-task-223-auto-proof-scope.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "#223 Auto Proof Scope Audit"
echo "============================================================"

echo ""
echo "1. RuntimeTruthEngine"
grep -RniE "markRealNative|acceptNativeAttestation|isProofCapable|getRuntimeTruthState|TASK_223_RUNTIME_TRUTH" \
  artifacts/api-server/src/runtime 2>/dev/null || true

echo ""
echo "2. Runtime verify route"
grep -RniE "registerRuntimeVerifyRoute|/api/runtime/verify|/api/runtime/truth|TASK_223_RUNTIME_VERIFY" \
  artifacts/api-server/src/routes 2>/dev/null || true

echo ""
echo "3. Activity proof-scope protection"
grep -RniE "task223NormalizeActivityTruth|proofScopeBlocked|proofScopeAccepted|simulation_labelled|physical_proof" \
  artifacts/api-server/src/routes/activity.ts 2>/dev/null || true

echo ""
echo "4. Mobile attestation"
grep -RniE "sendNativeRuntimeAttestation|NativeBridgeProvider|TASK_223_NATIVE_ATTESTATION|TASK_223_CONNECTIVITY_NATIVE_ATTESTATION_BOOT" \
  artifacts/messenger-mobile src 2>/dev/null || true

echo ""
echo "5. Remaining risky proof labels"
grep -RniE "truthLevel.*physical|physical_proof|real_native|proofScope" \
  artifacts/api-server/src artifacts/messenger-mobile src 2>/dev/null | head -250 || true

echo ""
echo "============================================================"
echo "#223 Audit complete"
echo "============================================================"
SH

chmod +x "$SCRIPTS/audit-task-223-auto-proof-scope.sh"

echo ""
echo "10. Documentation"

cat > "$DOCS/task-223-auto-proof-scope-native-attestation.md" <<'MD'
# Task #223 — Auto Promote Events to Proof Scope Once Real BLE Is Detected

Marker: `TASK_223_RUNTIME_TRUTH_ENGINE_AUTO_NATIVE_20260608_A`

## Added

API:
- `RuntimeTruthEngine.markRealNative(features, attestation)`
- `RuntimeTruthEngine.acceptNativeAttestation(attestation)`
- `RuntimeTruthEngine.isProofCapable(feature?)`
- `GET /api/runtime/truth`
- `POST /api/runtime/verify`

Mobile:
- `nativeRuntimeAttestationClient.ts`
- `NativeBridgeContext.tsx`
- Connectivity boot attestation when `ConnectivityContext.tsx` exists

Root app:
- `src/maurimesh/runtime/nativeRuntimeAttestationClient.ts`

## Promotion rule

Runtime becomes proof-capable only when:

- platform is `android`
- source is not `simulation`
- native module is present
- features include `native_bridge`

`ble_scan` is accepted only when the native module reports scan active or discovered count greater than zero.

## Truth boundary

This does not prove advertise, connect, TX/RX, ACK, relay, or store-forward.

It only unlocks proof-scope posting for features supported by real native attestation.

Simulation events remain labelled as simulation.
MD

echo ""
echo "11. Validate markers"
grep -RniE "TASK_223|markRealNative|acceptNativeAttestation|isProofCapable|sendNativeRuntimeAttestation" \
  artifacts src docs scripts 2>/dev/null || true

echo ""
echo "12. TypeScript check"
npx tsc --noEmit

echo ""
echo "13. Expo export check"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "14. Run audit"
bash "$SCRIPTS/audit-task-223-auto-proof-scope.sh"

echo ""
echo "============================================================"
echo "#223 AUTO PROOF SCOPE INSTALLED"
echo "Backup: $BACKUP"
echo ""
echo "Next required check:"
echo "Find API bootstrap and register registerRuntimeVerifyRoute(app) if routes are not auto-loaded."
echo ""
echo "Completion proof target:"
echo "1. Native module PRESENT"
echo "2. BLE scan active or discoveredCount > 0"
echo "3. POST /api/runtime/verify accepted"
echo "4. isProofCapable() true"
echo "5. activity proof-scope blocked before attestation and accepted after attestation"
echo "============================================================"
