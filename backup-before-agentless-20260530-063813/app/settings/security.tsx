import { useState } from "react";
import { Alert, StyleSheet, Switch, Text, View } from "react-native";
import { useRouter } from "expo-router";
import * as Haptics from "expo-haptics";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { radius } from "../../src/design-system/radius";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshButton } from "../../src/components/ui/MeshButton";
import { clearSession } from "../../lib/session";

type LockTimeout = "immediately" | "1min" | "5min" | "15min" | "never";

export default function SecurityScreen() {
  const router = useRouter();
  const [biometric, setBiometric]     = useState(true);
  const [pinFallback, setPinFallback] = useState(true);
  const [appLock, setAppLock]         = useState(true);
  const [strictMode, setStrictMode]   = useState(true);
  const [lockTimeout, setLockTimeout] = useState<LockTimeout>("5min");

  function handleChangePin() {
    Haptics.selectionAsync();
    Alert.alert(
      "Change PIN",
      "Enter your current 6-digit PIN, then set a new one.\n\nFull PIN management is available in the biometric-unlock screen.",
      [
        { text: "Cancel", style: "cancel" },
        { text: "Open Biometric Unlock", onPress: () => router.push("/biometric-unlock" as never) },
      ],
    );
  }

  function handleSignOutAll() {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    Alert.alert(
      "Sign Out All Sessions",
      "This will end all active sessions and return you to the login screen. Continue?",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Sign Out",
          style: "destructive",
          onPress: async () => {
            await clearSession();
            router.replace("/login");
          },
        },
      ],
    );
  }

  return (
    <ScreenWithHeader title="Security" subtitle="Biometric, PIN & app lock">
      <MeshCard title="Authentication">
        <Toggle label="Biometric Unlock" sub="Face ID or Fingerprint" value={biometric} onChange={setBiometric} />
        <Toggle label="PIN Fallback" sub="Required when biometrics fail" value={pinFallback} onChange={setPinFallback} />
        <MeshButton label="Change PIN" variant="secondary" onPress={handleChangePin} fullWidth style={{ marginTop: spacing.sm }} />
      </MeshCard>

      <MeshCard title="App Lock">
        <Toggle label="Auto-Lock" sub="Lock app when backgrounded" value={appLock} onChange={setAppLock} />
        <Text style={styles.timeoutLabel}>Lock after:</Text>
        <View style={styles.timeoutRow}>
          {(["immediately", "1min", "5min", "15min", "never"] as LockTimeout[]).map((t) => (
            <View
              key={t}
              style={[styles.chip, lockTimeout === t && styles.chipActive]}
            >
              <Text
                onPress={() => { Haptics.selectionAsync(); setLockTimeout(t); }}
                style={[styles.chipText, lockTimeout === t && styles.chipTextActive]}
              >
                {t === "immediately" ? "Now" : t}
              </Text>
            </View>
          ))}
        </View>
      </MeshCard>

      <MeshCard title="Mesh Security">
        <Toggle label="Strict Mode" sub="Drop unverified mesh packets" value={strictMode} onChange={setStrictMode} />
      </MeshCard>

      <MeshCard title="Session">
        {[
          ["Session age",   "Active · 2 h 14 m"],
          ["Last unlock",   "12:30 today"       ],
          ["Unlock method", "Face ID"           ],
        ].map(([label, value]) => (
          <View key={label as string} style={styles.row}>
            <Text style={styles.rowLabel}>{label}</Text>
            <Text style={styles.rowValue}>{value}</Text>
          </View>
        ))}
        <MeshButton
          label="Sign Out All Sessions"
          variant="danger"
          onPress={handleSignOutAll}
          fullWidth
          style={{ marginTop: spacing.sm }}
        />
      </MeshCard>
    </ScreenWithHeader>
  );
}

function Toggle({ label, sub, value, onChange }: { label: string; sub: string; value: boolean; onChange: (v: boolean) => void }) {
  return (
    <View style={styles.toggle}>
      <View style={styles.toggleText}>
        <Text style={styles.toggleLabel}>{label}</Text>
        <Text style={styles.toggleSub}>{sub}</Text>
      </View>
      <Switch
        value={value}
        onValueChange={(v) => { Haptics.selectionAsync(); onChange(v); }}
        trackColor={{ false: DS.surface, true: DS.greenDim }}
        thumbColor={value ? DS.mauriGreen : DS.textSecondary}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  toggle:           { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingVertical: spacing.xs },
  toggleText:       { flex: 1, gap: 2 },
  toggleLabel:      { color: DS.textPrimary,   fontSize: typography.sizes.base, fontFamily: typography.fonts.medium  },
  toggleSub:        { color: DS.textSecondary, fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular },
  timeoutLabel:     { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, marginTop: spacing.sm, marginBottom: spacing.xs },
  timeoutRow:       { flexDirection: "row", gap: spacing.xs, flexWrap: "wrap" },
  chip:             { paddingHorizontal: spacing.sm, paddingVertical: 6, borderRadius: radius.full, backgroundColor: DS.surface, borderWidth: 1, borderColor: DS.divider },
  chipActive:       { backgroundColor: DS.greenDim, borderColor: DS.greenBorder },
  chipText:         { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
  chipTextActive:   { color: DS.mauriGreen,    fontFamily: typography.fonts.semibold },
  row:              { flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 },
  rowLabel:         { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular  },
  rowValue:         { color: DS.textPrimary,   fontSize: typography.sizes.sm, fontFamily: typography.fonts.semibold },
});
