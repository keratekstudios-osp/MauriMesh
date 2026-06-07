import { useState } from "react";
import { Alert, StyleSheet, Text, View, Pressable } from "react-native";
import { useRouter } from "expo-router";
import * as Haptics from "expo-haptics";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshButton } from "../../src/components/ui/MeshButton";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";
import { safeNavigate } from "../../lib/safeNavigate";

const INITIAL_DEVICES = [
  { id: "DEV-001", name: "Kupe's iPhone",   platform: "iOS 17.4",    paired: "12 May 2026", status: "online"  as const },
  { id: "DEV-002", name: "Tama's Pixel 8",  platform: "Android 14",  paired: "10 May 2026", status: "offline" as const },
  { id: "DEV-003", name: "Rangi's iPad",    platform: "iPadOS 17",   paired: "5 Apr 2026",  status: "offline" as const },
];

export default function DevicePairingScreen() {
  const router = useRouter();
  const [devices, setDevices] = useState(INITIAL_DEVICES);

  function handleRemove(id: string, name: string) {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    Alert.alert(
      "Remove Device",
      `Remove "${name}" from trusted devices? It will need to be re-paired to rejoin the mesh.`,
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Remove",
          style: "destructive",
          onPress: () => {
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
            setDevices((prev) => prev.filter((d) => d.id !== id));
          },
        },
      ],
    );
  }

  function handlePairNew() {
    Haptics.selectionAsync();
    safeNavigate(router, "/add-friend");
  }

  return (
    <ScreenWithHeader title="Device Pairing" subtitle="Trusted & paired devices">
      <MeshCard title={`Paired Devices (${devices.length})`}>
        {devices.length === 0 ? (
          <Text style={styles.empty}>No paired devices. Tap "Pair New Device" to add one.</Text>
        ) : (
          devices.map((d) => (
            <View key={d.id} style={styles.device}>
              <View style={styles.deviceIcon}>
                <Text style={styles.deviceIconText}>⊙</Text>
              </View>
              <View style={styles.deviceMeta}>
                <View style={styles.deviceNameRow}>
                  <Text style={styles.deviceName}>{d.name}</Text>
                  <MeshStatusPill
                    label={d.status === "online" ? "Online" : "Last seen"}
                    variant={d.status === "online" ? "online" : "offline"}
                  />
                </View>
                <Text style={styles.deviceSub}>{d.platform} · Paired {d.paired}</Text>
                <Text style={styles.deviceId}>{d.id}</Text>
              </View>
              <Pressable
                onPress={() => handleRemove(d.id, d.name)}
                style={({ pressed }) => [styles.removeBtn, pressed && { opacity: 0.7 }]}
              >
                <Text style={styles.removeBtnText}>✕</Text>
              </Pressable>
            </View>
          ))
        )}
      </MeshCard>

      <MeshButton
        label="⊕  Pair New Device"
        onPress={handlePairNew}
        variant="secondary"
        fullWidth
      />

      <MeshCard title="Pairing Mode">
        {[
          ["Discovery window",   "30 seconds"],
          ["Max paired devices", "16"        ],
          ["Encryption",         "AES-256"   ],
        ].map(([label, value]) => (
          <View key={label as string} style={styles.row}>
            <Text style={styles.rowLabel}>{label}</Text>
            <Text style={styles.rowValue}>{value}</Text>
          </View>
        ))}
      </MeshCard>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  device:         { flexDirection: "row", alignItems: "center", gap: spacing.sm, paddingVertical: spacing.xs, borderBottomWidth: 1, borderBottomColor: DS.divider },
  deviceIcon:     { width: 40, height: 40, borderRadius: radius.sm, backgroundColor: DS.blueDim, alignItems: "center", justifyContent: "center", flexShrink: 0 },
  deviceIconText: { fontSize: 20, color: DS.meshBlue },
  deviceMeta:     { flex: 1, gap: 2 },
  deviceNameRow:  { flexDirection: "row", alignItems: "center", gap: spacing.xs },
  deviceName:     { color: DS.textPrimary,   fontSize: typography.sizes.base, fontFamily: typography.fonts.semibold },
  deviceSub:      { color: DS.textSecondary, fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular  },
  deviceId:       { color: DS.mutedText,     fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular  },
  removeBtn:      { width: 32, height: 32, borderRadius: radius.full, backgroundColor: DS.redDim, alignItems: "center", justifyContent: "center", flexShrink: 0 },
  removeBtnText:  { color: DS.dangerRed, fontSize: typography.sizes.sm, fontFamily: typography.fonts.bold },
  row:            { flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 },
  rowLabel:       { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular  },
  rowValue:       { color: DS.textPrimary,   fontSize: typography.sizes.sm, fontFamily: typography.fonts.semibold },
  empty:          { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular, textAlign: "center", paddingVertical: spacing.md },
});
