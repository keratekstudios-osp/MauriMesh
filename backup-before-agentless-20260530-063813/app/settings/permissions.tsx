import { useEffect, useState } from "react";
import { NativeModules, Pressable, StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";
import {
  checkMauriMeshBlePermissions,
  requestMauriMeshBlePermissions,
} from "../../lib/mesh/nativeMauriMeshBle";

// ── Types ─────────────────────────────────────────────────────────────────────

type PermStatus = "granted" | "denied" | "not-requested" | "checking";

interface PermRow {
  key: string;
  icon: string;
  name: string;
  desc: string;
  status: PermStatus;
  required: boolean;
  requestable: boolean;
}

// ── Runtime detection ─────────────────────────────────────────────────────────

const IS_NATIVE = NativeModules.MauriMeshBle != null;

// ── Helpers ───────────────────────────────────────────────────────────────────

const statusVariant: Record<PermStatus, "online" | "offline" | "warning" | "syncing"> = {
  granted:        "online",
  denied:         "offline",
  "not-requested": "warning",
  checking:       "syncing",
};

const statusLabel: Record<PermStatus, string> = {
  granted:        "Granted",
  denied:         "Denied",
  "not-requested": "Not Requested",
  checking:       "Checking…",
};

function bleRawToStatus(
  raw: Record<string, boolean>,
  key12: string,
  keyLegacy: string
): PermStatus {
  if (key12 in raw) return raw[key12] ? "granted" : "denied";
  if (keyLegacy in raw) return raw[keyLegacy] ? "granted" : "denied";
  return "not-requested";
}

// ── Screen ────────────────────────────────────────────────────────────────────

export default function PermissionsScreen() {
  const [requesting, setRequesting] = useState(false);

  const [perms, setPerms] = useState<PermRow[]>([
    {
      key: "bluetooth",
      icon: "ᛒ",
      name: "Bluetooth",
      desc: "Required for BLE mesh transport",
      status: IS_NATIVE ? "checking" : "not-requested",
      required: true,
      requestable: true,
    },
    {
      key: "location",
      icon: "◎",
      name: "Location",
      desc: "Needed for BLE scanning on Android",
      status: IS_NATIVE ? "checking" : "not-requested",
      required: true,
      requestable: false,
    },
    {
      key: "notifications",
      icon: "◈",
      name: "Notifications",
      desc: "Alerts for messages & mesh events",
      status: "granted",
      required: false,
      requestable: false,
    },
    {
      key: "camera",
      icon: "⊙",
      name: "Camera",
      desc: "Scan QR codes to add friends",
      status: "not-requested",
      required: false,
      requestable: false,
    },
    {
      key: "microphone",
      icon: "⊗",
      name: "Microphone",
      desc: "Pixel Calling audio input",
      status: "denied",
      required: false,
      requestable: false,
    },
    {
      key: "storage",
      icon: "▤",
      name: "Local Storage",
      desc: "Store messages & mesh configuration",
      status: "granted",
      required: true,
      requestable: false,
    },
  ]);

  // ── Live permission check on mount ─────────────────────────────────────────
  useEffect(() => {
    if (!IS_NATIVE) return;
    checkMauriMeshBlePermissions().then((raw) => {
      const btStatus  = bleRawToStatus(raw, "BLUETOOTH_SCAN",    "bluetooth");
      const locStatus = bleRawToStatus(raw, "ACCESS_FINE_LOCATION", "location");
      setPerms((prev) =>
        prev.map((p) => {
          if (p.key === "bluetooth") return { ...p, status: btStatus };
          if (p.key === "location")  return { ...p, status: locStatus };
          return p;
        })
      );
    }).catch(() => {
      setPerms((prev) =>
        prev.map((p) =>
          p.key === "bluetooth" || p.key === "location"
            ? { ...p, status: "not-requested" as PermStatus }
            : p
        )
      );
    });
  }, []);

  // ── Request BLE permissions ────────────────────────────────────────────────
  async function handleRequestBle() {
    if (requesting || !IS_NATIVE) return;
    setRequesting(true);
    try {
      await requestMauriMeshBlePermissions();
      // Re-check after request
      const raw = await checkMauriMeshBlePermissions();
      const btStatus  = bleRawToStatus(raw, "BLUETOOTH_SCAN",    "bluetooth");
      const locStatus = bleRawToStatus(raw, "ACCESS_FINE_LOCATION", "location");
      setPerms((prev) =>
        prev.map((p) => {
          if (p.key === "bluetooth") return { ...p, status: btStatus };
          if (p.key === "location")  return { ...p, status: locStatus };
          return p;
        })
      );
    } catch {
      // ignore — user dismissed dialog
    } finally {
      setRequesting(false);
    }
  }

  const bleNotGranted = perms.some(
    (p) => p.key === "bluetooth" && p.status !== "granted"
  );

  return (
    <ScreenWithHeader title="Permissions" subtitle="App permission status">
      <MeshCard title="System Permissions">
        {perms.map((p) => (
          <View key={p.key} style={styles.row}>
            <View style={styles.iconWrap}>
              <Text style={styles.icon}>{p.icon}</Text>
            </View>
            <View style={styles.text}>
              <View style={styles.nameRow}>
                <Text style={styles.name}>{p.name}</Text>
                {p.required && <Text style={styles.required}>Required</Text>}
              </View>
              <Text style={styles.desc}>{p.desc}</Text>
            </View>
            <MeshStatusPill
              label={statusLabel[p.status]}
              variant={statusVariant[p.status]}
            />
          </View>
        ))}
      </MeshCard>

      {/* Request button — only shown on native when BLE not yet granted */}
      {IS_NATIVE && bleNotGranted && (
        <Pressable
          style={({ pressed }) => [
            styles.requestBtn,
            pressed && { opacity: 0.7 },
          ]}
          onPress={handleRequestBle}
          disabled={requesting}
        >
          <Text style={styles.requestBtnText}>
            {requesting ? "Requesting…" : "Request Bluetooth Permissions"}
          </Text>
        </Pressable>
      )}

      <Text style={styles.note}>
        {IS_NATIVE
          ? "Permission status is read live from the device. To change permissions, open Settings → MauriMesh."
          : "Running in simulation mode — install the APK on a physical device to manage live permissions."}
      </Text>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  row:        { flexDirection: "row", alignItems: "center", gap: spacing.sm, paddingVertical: spacing.xs },
  iconWrap:   { width: 36, height: 36, borderRadius: radius.sm, backgroundColor: DS.surface, alignItems: "center", justifyContent: "center", flexShrink: 0 },
  icon:       { fontSize: 18, color: DS.textSecondary },
  text:       { flex: 1, gap: 2 },
  nameRow:    { flexDirection: "row", alignItems: "center", gap: spacing.xs },
  name:       { color: DS.textPrimary,   fontSize: typography.sizes.base, fontFamily: typography.fonts.medium  },
  required:   { color: DS.warningAmber,  fontSize: typography.sizes.xs,   fontFamily: typography.fonts.bold,   backgroundColor: DS.amberDim, paddingHorizontal: 6, paddingVertical: 2, borderRadius: radius.xs },
  desc:       { color: DS.textSecondary, fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular },
  note:       { color: DS.mutedText, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, textAlign: "center", lineHeight: typography.sizes.xs * typography.lineHeight.relaxed, marginTop: spacing.sm },
  requestBtn: { backgroundColor: DS.mauriGreen, borderRadius: radius.md, paddingVertical: spacing.sm, alignItems: "center", marginBottom: spacing.sm },
  requestBtnText: { color: "#000", fontSize: typography.sizes.sm, fontFamily: typography.fonts.bold },
});
