#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE BLE/GATT TRUTH GATE v1"
echo "============================================================"
echo "Goal:"
echo "- Add safe APK route: /native-ble-gatt-proof"
echo "- Capture native BLE scan callbacks through react-native-ble-plx if available"
echo "- Bind every attempt to a packetId"
echo "- Save attempt evidence into local vault"
echo "- Export logcat capture helper"
echo "- Never claim native BLE/GATT PASS unless packet-bound native logs exist"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-native-ble-gatt-truth-gate-v1-$STAMP"
REPORT_DIR="$ROOT/docs/native-ble-gatt"
TOOLS_DIR="$ROOT/tools"
APP_DIR="$ROOT/app"

mkdir -p "$BACKUP" "$REPORT_DIR" "$TOOLS_DIR" "$APP_DIR"

for f in \
  "$APP_DIR/native-ble-gatt-proof.tsx" \
  "$ROOT/app/dashboard.tsx"
do
  if [ -f "$f" ]; then
    mkdir -p "$BACKUP/$(dirname "${f#$ROOT/}")"
    cp "$f" "$BACKUP/${f#$ROOT/}"
  fi
done

cat > "$APP_DIR/native-ble-gatt-proof.tsx" <<'TSX'
import React, { useMemo, useRef, useState } from "react";
import {
  Alert,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";

declare const require: any;

type Marker = {
  ts: string;
  event: string;
  line: string;
};

type VaultEntry = {
  type: "NATIVE_BLE_GATT_TRUTH_GATE_ATTEMPT";
  parsedType: "NATIVE_BLE_GATT_ATTEMPT";
  packetId: string;
  generatedAt: string;
  nativeCallbackSeen: boolean;
  nativePacketIdInsideTransportLog: boolean;
  nativeBleGattPacketBoundPass: false;
  verdict:
    | "NATIVE_CALLBACK_PENDING"
    | "NATIVE_CALLBACK_SEEN_PACKET_BOUND_PENDING";
  score: number;
  reason: string;
  markers: Marker[];
  truth: string;
};

function nowIso() {
  return new Date().toISOString();
}

function makePacketId() {
  const a = Math.random().toString(36).slice(2, 8).toUpperCase();
  const b = Math.random().toString(36).slice(2, 8).toUpperCase();
  return `MMN-${a}-${b}`;
}

function clean(value: unknown) {
  return String(value ?? "unknown").replace(/\s+/g, "_").slice(0, 80);
}

async function safeVaultSave(key: string, value: unknown) {
  try {
    const AsyncStorage =
      require("@react-native-async-storage/async-storage").default;
    await AsyncStorage.setItem(key, JSON.stringify(value));
    return true;
  } catch (err) {
    console.log(
      `MAURIMESH_NATIVE_BLE_GATT | VAULT_SAVE_FAILED | error=${clean(
        err instanceof Error ? err.message : err
      )}`
    );
    return false;
  }
}

function getBlePlx() {
  try {
    return require("react-native-ble-plx");
  } catch (err) {
    return null;
  }
}

export default function NativeBleGattProofScreen() {
  const [packetId, setPacketId] = useState(makePacketId());
  const [markers, setMarkers] = useState<Marker[]>([]);
  const [scanActive, setScanActive] = useState(false);
  const [vaultSaved, setVaultSaved] = useState(false);
  const managerRef = useRef<any>(null);
  const stateSubRef = useRef<any>(null);

  const nativeCallbackSeen = useMemo(() => {
    return markers.some((m) =>
      [
        "BLE_MANAGER_CREATED",
        "BLE_STATE_CALLBACK",
        "BLE_SCAN_CALLBACK_DEVICE",
        "BLE_SCAN_CALLBACK_ERROR",
      ].includes(m.event)
    );
  }, [markers]);

  const addMarker = (event: string, extra = "") => {
    const ts = nowIso();

    const line =
      `MAURIMESH_NATIVE_BLE_GATT | ${event}` +
      ` | packetId=${packetId}` +
      ` | nativePacketBound=false` +
      (extra ? ` | ${extra}` : "");

    const marker = { ts, event, line };

    setMarkers((prev) => [marker, ...prev].slice(0, 120));
    console.log(line);
  };

  const stopScan = () => {
    try {
      if (managerRef.current) {
        managerRef.current.stopDeviceScan();
      }
    } catch (err) {
      addMarker(
        "BLE_STOP_SCAN_ERROR",
        `error=${clean(err instanceof Error ? err.message : err)}`
      );
    }

    try {
      if (stateSubRef.current?.remove) {
        stateSubRef.current.remove();
      }
    } catch {
      // no-op
    }

    setScanActive(false);
    addMarker("BLE_SCAN_STOPPED");
  };

  const startScan = async () => {
    setVaultSaved(false);

    const BlePlx = getBlePlx();

    if (!BlePlx?.BleManager) {
      addMarker(
        "BLE_PLX_UNAVAILABLE",
        "truth=react-native-ble-plx_not_available_on_this_runtime"
      );
      Alert.alert(
        "BLE unavailable",
        "react-native-ble-plx is not available in this runtime. This is expected in Replit/web. Test this route inside the APK on phones."
      );
      return;
    }

    try {
      if (!managerRef.current) {
        managerRef.current = new BlePlx.BleManager();
        addMarker("BLE_MANAGER_CREATED");
      }

      const manager = managerRef.current;

      try {
        const currentState = await manager.state();
        addMarker("BLE_STATE_READ", `state=${clean(currentState)}`);
      } catch (err) {
        addMarker(
          "BLE_STATE_READ_ERROR",
          `error=${clean(err instanceof Error ? err.message : err)}`
        );
      }

      try {
        stateSubRef.current = manager.onStateChange((state: string) => {
          addMarker("BLE_STATE_CALLBACK", `state=${clean(state)}`);
        }, true);
      } catch (err) {
        addMarker(
          "BLE_STATE_CALLBACK_ERROR",
          `error=${clean(err instanceof Error ? err.message : err)}`
        );
      }

      addMarker("BLE_SCAN_START_REQUESTED");

      manager.startDeviceScan(
        null,
        { allowDuplicates: false },
        (error: any, device: any) => {
          if (error) {
            addMarker(
              "BLE_SCAN_CALLBACK_ERROR",
              `error=${clean(error.message || error.reason || error)}`
            );
            return;
          }

          if (device) {
            addMarker(
              "BLE_SCAN_CALLBACK_DEVICE",
              [
                `deviceId=${clean(device.id)}`,
                `name=${clean(device.name || device.localName)}`,
                `rssi=${clean(device.rssi)}`,
                `mtu=${clean(device.mtu)}`,
              ].join(" | ")
            );
          }
        }
      );

      setScanActive(true);
    } catch (err) {
      addMarker(
        "BLE_SCAN_START_FATAL",
        `error=${clean(err instanceof Error ? err.message : err)}`
      );
      setScanActive(false);
    }
  };

  const resetPacket = () => {
    stopScan();
    const next = makePacketId();
    setPacketId(next);
    setMarkers([]);
    setVaultSaved(false);
    console.log(
      `MAURIMESH_NATIVE_BLE_GATT | PACKET_RESET | packetId=${next} | nativePacketBound=false`
    );
  };

  const saveAttempt = async () => {
    const entry: VaultEntry = {
      type: "NATIVE_BLE_GATT_TRUTH_GATE_ATTEMPT",
      parsedType: "NATIVE_BLE_GATT_ATTEMPT",
      packetId,
      generatedAt: nowIso(),
      nativeCallbackSeen,
      nativePacketIdInsideTransportLog: false,
      nativeBleGattPacketBoundPass: false,
      verdict: nativeCallbackSeen
        ? "NATIVE_CALLBACK_SEEN_PACKET_BOUND_PENDING"
        : "NATIVE_CALLBACK_PENDING",
      score: nativeCallbackSeen ? 72 : 40,
      reason: nativeCallbackSeen
        ? "Native BLE callback activity was observed, but packetId was not proven inside a native GATT/advertising transport payload."
        : "No native BLE callback has been observed yet. Run inside APK on physical phones.",
      markers,
      truth:
        "This entry never claims native BLE/GATT packet-bound PASS. PASS requires the same packetId inside native BLE/GATT transport logs.",
    };

    addMarker("ATTEMPT_SAVE_REQUESTED", `verdict=${entry.verdict}`);

    const key = `maurimesh_native_ble_gatt_attempt_${packetId}_${Date.now()}`;
    const saved = await safeVaultSave(key, entry);

    setVaultSaved(saved);

    addMarker(
      saved ? "ATTEMPT_SAVED_TO_VAULT" : "ATTEMPT_SAVE_NOT_CONFIRMED",
      `key=${key}`
    );

    Alert.alert(
      saved ? "Attempt saved" : "Attempt not saved",
      saved
        ? "Native BLE/GATT attempt saved to local vault. Truth state remains PENDING until packet-bound native logs exist."
        : "Could not save to vault. Check AsyncStorage availability."
    );
  };

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.kicker}>MAURIMESH NATIVE PROOF GATE</Text>
      <Text style={styles.title}>Native BLE/GATT Truth Gate</Text>

      <View style={styles.card}>
        <Text style={styles.label}>Packet ID</Text>
        <TextInput
          value={packetId}
          onChangeText={setPacketId}
          autoCapitalize="characters"
          style={styles.input}
        />
        <Text style={styles.small}>
          Use the same packetId when comparing APK workflow logs, ReactNativeJS
          logs, and native transport logs.
        </Text>
      </View>

      <View style={styles.grid}>
        <ActionButton title="Start BLE Callback Capture" onPress={startScan} />
        <ActionButton
          title="Stop Capture"
          onPress={stopScan}
          variant="secondary"
        />
        <ActionButton
          title="Save Attempt Into Vault"
          onPress={saveAttempt}
          variant="secondary"
        />
        <ActionButton title="Reset Packet" onPress={resetPacket} variant="dark" />
      </View>

      <View style={styles.card}>
        <Text style={styles.section}>Truth State</Text>
        <Text style={styles.row}>Scan active: {scanActive ? "YES" : "NO"}</Text>
        <Text style={styles.row}>
          Native callback seen: {nativeCallbackSeen ? "YES" : "NO"}
        </Text>
        <Text style={styles.row}>
          Native BLE/GATT packet-bound PASS: NOT CLAIMED
        </Text>
        <Text style={styles.row}>
          Vault saved this attempt: {vaultSaved ? "YES" : "NO"}
        </Text>
        <Text style={styles.warning}>
          PASS requires packetId inside native BLE/GATT transport logs. BLE scan
          callbacks alone are useful evidence but not final transport proof.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.section}>Required Final PASS Rule</Text>
        <Text style={styles.body}>
          PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF is allowed only when the same
          packetId appears across app workflow logs and native BLE/GATT transport
          markers from physical-device logcat capture.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.section}>Markers</Text>
        {markers.length === 0 ? (
          <Text style={styles.small}>No markers yet.</Text>
        ) : (
          markers.map((marker, index) => (
            <View key={`${marker.ts}-${index}`} style={styles.marker}>
              <Text style={styles.markerTs}>{marker.ts}</Text>
              <Text style={styles.markerLine}>{marker.line}</Text>
            </View>
          ))
        )}
      </View>

      <Text style={styles.footer}>
        Final truth: this screen captures native callback attempts only. It does
        not claim native BLE/GATT packet-bound PASS.
      </Text>
    </ScrollView>
  );
}

function ActionButton({
  title,
  onPress,
  variant = "primary",
}: {
  title: string;
  onPress: () => void;
  variant?: "primary" | "secondary" | "dark";
}) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        variant === "primary" && styles.buttonPrimary,
        variant === "secondary" && styles.buttonSecondary,
        variant === "dark" && styles.buttonDark,
        pressed && { opacity: 0.76, transform: [{ scale: 0.98 }] },
      ]}
    >
      <Text style={styles.buttonText}>{title}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#000000",
  },
  content: {
    padding: 20,
    paddingBottom: 52,
    gap: 18,
  },
  kicker: {
    color: "#00D084",
    fontSize: 13,
    fontWeight: "900",
    letterSpacing: 2,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 36,
    lineHeight: 40,
    fontWeight: "900",
  },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.35)",
    backgroundColor: "rgba(0,32,20,0.72)",
    borderRadius: 22,
    padding: 18,
    gap: 10,
  },
  label: {
    color: "rgba(255,255,255,0.72)",
    fontWeight: "800",
    fontSize: 12,
  },
  input: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.4)",
    color: "#00D084",
    backgroundColor: "rgba(0,0,0,0.35)",
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 20,
    fontWeight: "900",
  },
  small: {
    color: "rgba(255,255,255,0.68)",
    lineHeight: 20,
  },
  grid: {
    gap: 12,
  },
  button: {
    minHeight: 54,
    borderRadius: 18,
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 1,
    paddingHorizontal: 16,
  },
  buttonPrimary: {
    backgroundColor: "#00D084",
    borderColor: "#00D084",
  },
  buttonSecondary: {
    backgroundColor: "rgba(255,255,255,0.08)",
    borderColor: "rgba(0,208,132,0.35)",
  },
  buttonDark: {
    backgroundColor: "#050505",
    borderColor: "rgba(255,255,255,0.18)",
  },
  buttonText: {
    color: "#FFFFFF",
    fontWeight: "900",
    fontSize: 15,
  },
  section: {
    color: "#00D084",
    fontSize: 22,
    fontWeight: "900",
  },
  row: {
    color: "#FFFFFF",
    fontSize: 15,
    lineHeight: 22,
    fontWeight: "700",
  },
  warning: {
    color: "#F59E0B",
    lineHeight: 21,
    fontWeight: "800",
  },
  body: {
    color: "rgba(255,255,255,0.78)",
    lineHeight: 22,
  },
  marker: {
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.1)",
    paddingTop: 10,
    gap: 4,
  },
  markerTs: {
    color: "rgba(255,255,255,0.5)",
    fontSize: 11,
  },
  markerLine: {
    color: "#FFFFFF",
    fontSize: 12,
    lineHeight: 18,
  },
  footer: {
    color: "#F59E0B",
    lineHeight: 22,
    fontWeight: "900",
  },
});
TSX

cat > "$TOOLS_DIR/capture-native-ble-gatt-logcat-proof.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

PKG="${1:-com.maurimesh.messenger}"
DURATION="${2:-90}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="native-ble-gatt-logcat-proof-$STAMP"

mkdir -p "$OUT"

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE BLE/GATT LOGCAT CAPTURE"
echo "============================================================"
echo "Package:  $PKG"
echo "Duration: ${DURATION}s"
echo "Output:   $OUT"
echo ""
echo "Truth:"
echo "- Captures ReactNativeJS + native BLE/GATT proof markers"
echo "- Does not claim native BLE/GATT PASS unless packet-bound markers exist"
echo "============================================================"
echo ""

if ! command -v adb >/dev/null 2>&1; then
  echo "FAIL: adb not found."
  exit 1
fi

adb devices -l | tee "$OUT/adb_devices.txt"

mapfile_cmd_available=1
if ! command -v bash >/dev/null 2>&1; then
  mapfile_cmd_available=0
fi

SERIALS="$(adb devices | awk 'NR>1 && $2=="device" {print $1}')"

if [ -z "$SERIALS" ]; then
  echo "FAIL: no adb devices connected."
  exit 1
fi

echo ""
echo "Connected serials:"
echo "$SERIALS"
echo ""

PIDS=""

cleanup() {
  for pid in $PIDS; do
    kill "$pid" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

for serial in $SERIALS; do
  SAFE_SERIAL="$(echo "$serial" | tr ':./' '___')"
  LOG="$OUT/logcat_$SAFE_SERIAL.txt"
  echo "Starting logcat for $serial -> $LOG"

  {
    echo "===== DEVICE $serial ====="
    echo "===== START $(date -u +"%Y-%m-%dT%H:%M:%SZ") ====="
    adb -s "$serial" logcat -v time \
      ReactNativeJS:I \
      BluetoothGatt:D \
      BtGatt:D \
      BluetoothAdapter:D \
      BluetoothLeScanner:D \
      BLE:D \
      "$PKG":D \
      '*:S'
  } > "$LOG" 2>&1 &

  PIDS="$PIDS $!"
done

echo ""
echo "Now open APK route /native-ble-gatt-proof on the phones."
echo "Tap: Start BLE Callback Capture."
echo "Wait for scan callbacks."
echo "Then tap: Save Attempt Into Vault."
echo ""
echo "Capturing for ${DURATION}s..."
sleep "$DURATION"

cleanup
trap - EXIT

echo ""
echo "Extracting MauriMesh markers..."

COMBINED="$OUT/combined_markers.txt"
SUMMARY="$OUT/summary.md"
JSON="$OUT/summary.json"

grep -R \
  -E "MAURIMESH_NATIVE_BLE_GATT|MAURIMESH_3_DEVICE_PROOF|BluetoothGatt|BtGatt|BluetoothLeScanner" \
  "$OUT"/logcat_*.txt > "$COMBINED" 2>/dev/null || true

PACKET_IDS="$(grep -Eo 'packetId=[A-Z0-9-]+' "$COMBINED" | sed 's/packetId=//' | sort -u | tr '\n' ' ')"
NATIVE_MARKER_COUNT="$(grep -c "MAURIMESH_NATIVE_BLE_GATT" "$COMBINED" 2>/dev/null || echo 0)"
SCAN_CALLBACK_COUNT="$(grep -c "BLE_SCAN_CALLBACK_DEVICE" "$COMBINED" 2>/dev/null || echo 0)"
GATT_COUNT="$(grep -Ec "BluetoothGatt|BtGatt" "$COMBINED" 2>/dev/null || echo 0)"
PACKET_BOUND_PASS_COUNT="$(grep -Ec "PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF|NATIVE_PACKET_BOUND_PASS=true|nativeBleGattPacketBoundPass=true" "$COMBINED" 2>/dev/null || echo 0)"

RESULT="PENDING"
REASON="Native BLE/GATT packet-bound PASS is not proven."

if [ "$PACKET_BOUND_PASS_COUNT" -gt 0 ]; then
  RESULT="PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF_CANDIDATE_REVIEW_REQUIRED"
  REASON="Candidate pass markers found. Human review required to confirm same packetId across required native transport stages."
elif [ "$NATIVE_MARKER_COUNT" -gt 0 ] || [ "$SCAN_CALLBACK_COUNT" -gt 0 ] || [ "$GATT_COUNT" -gt 0 ]; then
  RESULT="NATIVE_CALLBACK_ACTIVITY_SEEN_PACKET_BOUND_PENDING"
  REASON="Native callback or BLE/GATT activity was seen, but packet-bound native transport PASS was not proven."
fi

cat > "$SUMMARY" <<MD
# MauriMesh Native BLE/GATT Logcat Proof Capture

Generated: $STAMP

## Result

$RESULT

## Reason

$REASON

## Counts

- MauriMesh native markers: $NATIVE_MARKER_COUNT
- BLE scan callback device markers: $SCAN_CALLBACK_COUNT
- Android BluetoothGatt/BtGatt lines: $GATT_COUNT
- Native packet-bound pass markers: $PACKET_BOUND_PASS_COUNT

## Packet IDs Found

$PACKET_IDS

## Truth Rule

Native BLE/GATT packet-bound PASS is not claimed unless the same packetId appears inside required native BLE/GATT transport logs.

## Files

- ADB devices: adb_devices.txt
- Combined markers: combined_markers.txt
- Raw logcat files: logcat_*.txt
MD

cat > "$JSON" <<JSON
{
  "type": "MAURIMESH_NATIVE_BLE_GATT_LOGCAT_CAPTURE",
  "generatedAt": "$STAMP",
  "result": "$RESULT",
  "reason": "$REASON",
  "packetIds": "$(echo "$PACKET_IDS" | sed 's/"/\\"/g')",
  "nativeMarkerCount": $NATIVE_MARKER_COUNT,
  "scanCallbackDeviceCount": $SCAN_CALLBACK_COUNT,
  "androidBluetoothGattLineCount": $GATT_COUNT,
  "nativePacketBoundPassMarkerCount": $PACKET_BOUND_PASS_COUNT,
  "truth": "Native BLE/GATT packet-bound PASS is not claimed unless same packetId appears inside native BLE/GATT transport logs."
}
JSON

tar -czf "$OUT.tar.gz" "$OUT" >/dev/null 2>&1 || true

echo ""
echo "============================================================"
echo "CAPTURE COMPLETE"
echo "============================================================"
cat "$SUMMARY"
echo ""
echo "Archive:"
echo "$OUT.tar.gz"
echo "============================================================"
SH

chmod +x "$TOOLS_DIR/capture-native-ble-gatt-logcat-proof.sh"

cat > "$REPORT_DIR/NATIVE_BLE_GATT_TRUTH_GATE_v1_$STAMP.md" <<MD
# MauriMesh Native BLE/GATT Truth Gate v1

Generated: $STAMP

## Added

- app/native-ble-gatt-proof.tsx
- tools/capture-native-ble-gatt-logcat-proof.sh

## Route

/native-ble-gatt-proof

## Truth

This patch does not claim native BLE/GATT packet-bound PASS.

It captures native BLE callback attempts through react-native-ble-plx where available, logs packetId-bound markers, and saves an attempt into the local vault.

## PASS Rule

PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF is only allowed when the same packetId appears inside required native BLE/GATT transport logs from physical devices.

## Current Expected Result

NATIVE_CALLBACK_ACTIVITY_SEEN_PACKET_BOUND_PENDING

or

PENDING

until packet-bound native transport proof is captured.
MD

echo ""
echo "============================================================"
echo "PATCH COMPLETE"
echo "============================================================"
echo "Created route:"
echo "  app/native-ble-gatt-proof.tsx"
echo ""
echo "Created Mac/ADB capture helper:"
echo "  tools/capture-native-ble-gatt-logcat-proof.sh"
echo ""
echo "Report:"
echo "  $REPORT_DIR/NATIVE_BLE_GATT_TRUTH_GATE_v1_$STAMP.md"
echo ""
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Next:"
echo "1. Run TypeScript check."
echo "2. Build/install APK."
echo "3. Open /native-ble-gatt-proof on phones."
echo "4. Run logcat capture from Mac."
echo "============================================================"
