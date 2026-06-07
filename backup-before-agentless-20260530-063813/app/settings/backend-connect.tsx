import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { useRouter } from "expo-router";
import { useRef, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useBackendConfig, type BackendStatus } from "../../contexts/BackendConfigContext";
import { useColors, type Colors } from "../../hooks/useColors";

// ── Status colours ─────────────────────────────────────────────────────────

function statusColor(status: BackendStatus, colors: Colors): string {
  switch (status) {
    case "connected": return "#10b981";
    case "checking":  return "#FACC15";
    case "error":     return colors.destructive;
    default:          return colors.mutedForeground;
  }
}

function statusLabel(status: BackendStatus): string {
  switch (status) {
    case "connected": return "Connected";
    case "checking":  return "Connecting…";
    case "error":     return "Connection Failed";
    default:          return "Not Connected";
  }
}

function statusIcon(status: BackendStatus): React.ComponentProps<typeof Feather>["name"] {
  switch (status) {
    case "connected": return "check-circle";
    case "checking":  return "loader";
    case "error":     return "x-circle";
    default:          return "wifi-off";
  }
}

// ── ExampleRow ────────────────────────────────────────────────────────────

function ExampleRow({ label, url, onPress }: { label: string; url: string; onPress: () => void }) {
  const colors = useColors();
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [xStyles.exRow, pressed && xStyles.exRowPressed, { borderColor: colors.border }]}
    >
      <Text style={[xStyles.exLabel, { color: colors.mutedForeground }]}>{label}</Text>
      <Text style={[xStyles.exUrl, { color: colors.primary }]} numberOfLines={1}>{url}</Text>
    </Pressable>
  );
}

const xStyles = StyleSheet.create({
  exRow:        { borderWidth: 1, borderRadius: 10, padding: 12, marginBottom: 8 },
  exRowPressed: { opacity: 0.7 },
  exLabel:      { fontSize: 11, fontFamily: "Inter_600SemiBold", letterSpacing: 0.5, textTransform: "uppercase", marginBottom: 2 },
  exUrl:        { fontSize: 13, fontFamily: "Inter_400Regular" },
});

// ── Main Screen ───────────────────────────────────────────────────────────

export default function BackendConnectScreen() {
  const colors    = useColors();
  const insets    = useSafeAreaInsets();
  const router    = useRouter();
  const { url, status, latencyMs, version, errorMessage, saveAndConnect, disconnect, retest } = useBackendConfig();

  const [inputUrl, setInputUrl] = useState(url);
  const [testing,  setTesting]  = useState(false);
  const [saving,   setSaving]   = useState(false);
  const inputRef = useRef<TextInput>(null);

  const topInset    = Platform.OS === "web" ? 67 : insets.top;
  const bottomInset = Platform.OS === "web" ? 34 : insets.bottom;
  const accent      = statusColor(status, colors);
  const styles      = makeStyles(colors, topInset, bottomInset, accent);

  async function handleSaveConnect() {
    const trimmed = inputUrl.trim();
    if (!trimmed) {
      Alert.alert("Enter a URL", "Provide a backend URL before connecting.");
      return;
    }
    if (!trimmed.startsWith("http://") && !trimmed.startsWith("https://")) {
      Alert.alert("Invalid URL", "URL must start with http:// or https://");
      return;
    }
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium).catch(() => {});
    setSaving(true);
    const result = await saveAndConnect(trimmed);
    setSaving(false);
    if (result.ok) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success).catch(() => {});
    } else {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error).catch(() => {});
    }
  }

  async function handleTest() {
    const trimmed = inputUrl.trim();
    if (!trimmed) {
      Alert.alert("Enter a URL", "Provide a backend URL to test.");
      return;
    }
    Haptics.selectionAsync().catch(() => {});
    setTesting(true);
    const { pingBackend } = await import("../../lib/backendConfig");
    const result = await pingBackend(trimmed);
    setTesting(false);
    if (result.ok) {
      Alert.alert("✓ Reachable", `Server responded in ${result.latencyMs}ms${result.version ? `\nVersion: ${result.version}` : ""}`);
    } else {
      Alert.alert("Unreachable", result.error ?? "Could not reach the server.");
    }
  }

  async function handleDisconnect() {
    Alert.alert(
      "Disconnect Backend",
      "The app will run in fully offline mode using local simulation data.",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Disconnect",
          style: "destructive",
          onPress: async () => {
            await disconnect();
            setInputUrl("");
            Haptics.selectionAsync().catch(() => {});
          },
        },
      ]
    );
  }

  function fillExample(exUrl: string) {
    setInputUrl(exUrl);
    Haptics.selectionAsync().catch(() => {});
  }

  const isBusy  = saving || testing || status === "checking";
  const hasUrl  = inputUrl.trim().length > 0;
  const changed = inputUrl.trim() !== url;

  return (
    <KeyboardAvoidingView
      style={styles.root}
      behavior={Platform.OS === "ios" ? "padding" : "height"}
    >
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.content}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
      >
        {/* ── Header ── */}
        <View style={styles.header}>
          <Pressable onPress={() => router.back()} style={styles.backBtn}>
            <Feather name="arrow-left" size={20} color={colors.foreground} />
          </Pressable>
          <View>
            <Text style={styles.headerTitle}>Connect Backend</Text>
            <Text style={styles.headerSub}>Point your APK to a live server</Text>
          </View>
        </View>

        {/* ── Status Card ── */}
        <View style={[styles.statusCard, { borderColor: accent + "55" }]}>
          <View style={[styles.statusIconWrap, { backgroundColor: accent + "22" }]}>
            {status === "checking" ? (
              <ActivityIndicator size="small" color={accent} />
            ) : (
              <Feather name={statusIcon(status)} size={22} color={accent} />
            )}
          </View>
          <View style={styles.statusText}>
            <Text style={[styles.statusLabel, { color: accent }]}>{statusLabel(status)}</Text>
            {status === "connected" && url ? (
              <Text style={styles.statusUrl} numberOfLines={1}>{url}</Text>
            ) : null}
            {status === "connected" && (latencyMs !== null || version) ? (
              <Text style={styles.statusMeta}>
                {latencyMs !== null ? `${latencyMs}ms` : ""}
                {latencyMs !== null && version ? "  ·  " : ""}
                {version ? `v${version}` : ""}
              </Text>
            ) : null}
            {status === "error" && errorMessage ? (
              <Text style={styles.statusError} numberOfLines={2}>{errorMessage}</Text>
            ) : null}
            {status === "idle" ? (
              <Text style={styles.statusUrl}>Fully offline — using local simulation</Text>
            ) : null}
          </View>
          {status === "connected" && (
            <Pressable onPress={retest} style={styles.retestBtn} hitSlop={10}>
              <Feather name="refresh-cw" size={15} color={accent} />
            </Pressable>
          )}
        </View>

        {/* ── URL Input ── */}
        <View style={styles.inputSection}>
          <Text style={styles.inputLabel}>BACKEND URL</Text>
          <View style={[styles.inputWrap, { borderColor: colors.border }]}>
            <Feather name="server" size={16} color={colors.mutedForeground} style={styles.inputIcon} />
            <TextInput
              ref={inputRef}
              style={[styles.input, { color: colors.foreground }]}
              value={inputUrl}
              onChangeText={setInputUrl}
              placeholder="https://your-server.com"
              placeholderTextColor={colors.mutedForeground}
              autoCapitalize="none"
              autoCorrect={false}
              keyboardType="url"
              returnKeyType="done"
              onSubmitEditing={handleSaveConnect}
              editable={!isBusy}
            />
            {inputUrl.length > 0 && (
              <Pressable onPress={() => setInputUrl("")} hitSlop={10}>
                <Feather name="x" size={15} color={colors.mutedForeground} />
              </Pressable>
            )}
          </View>
          <Text style={styles.inputHint}>
            Include the full base path if your API is not at root
            {"\n"}(e.g. https://myhost.com/api-v2)
          </Text>
        </View>

        {/* ── Action Buttons ── */}
        <View style={styles.actions}>
          {/* Save & Connect */}
          <Pressable
            style={({ pressed }) => [
              styles.primaryBtn,
              { backgroundColor: colors.primary, opacity: pressed || isBusy || !hasUrl ? 0.65 : 1 },
            ]}
            onPress={handleSaveConnect}
            disabled={isBusy || !hasUrl}
          >
            {saving ? (
              <ActivityIndicator size="small" color="#000" />
            ) : (
              <Feather name={changed ? "save" : "check"} size={16} color="#000" />
            )}
            <Text style={styles.primaryBtnText}>
              {saving ? "Connecting…" : changed ? "Save & Connect" : "Connected"}
            </Text>
          </Pressable>

          {/* Test (no save) */}
          <Pressable
            style={({ pressed }) => [
              styles.secondaryBtn,
              { borderColor: colors.border, opacity: pressed || isBusy || !hasUrl ? 0.55 : 1 },
            ]}
            onPress={handleTest}
            disabled={isBusy || !hasUrl}
          >
            {testing ? (
              <ActivityIndicator size="small" color={colors.foreground} />
            ) : (
              <Feather name="activity" size={15} color={colors.foreground} />
            )}
            <Text style={[styles.secondaryBtnText, { color: colors.foreground }]}>
              {testing ? "Pinging…" : "Test Connection"}
            </Text>
          </Pressable>

          {/* Disconnect (only shown when a URL is saved) */}
          {url ? (
            <Pressable
              style={({ pressed }) => [
                styles.destructBtn,
                { borderColor: colors.destructive + "60", opacity: pressed ? 0.65 : 1 },
              ]}
              onPress={handleDisconnect}
            >
              <Feather name="wifi-off" size={15} color={colors.destructive} />
              <Text style={[styles.destructBtnText, { color: colors.destructive }]}>
                Disconnect
              </Text>
            </Pressable>
          ) : null}
        </View>

        {/* ── Offline Mode Notice ── */}
        <View style={[styles.offlineNotice, { backgroundColor: colors.card, borderColor: colors.border }]}>
          <Feather name="shield" size={16} color={colors.primary} />
          <View style={styles.offlineNoticeText}>
            <Text style={[styles.offlineNoticeTitle, { color: colors.foreground }]}>
              Offline-First Design
            </Text>
            <Text style={[styles.offlineNoticeBody, { color: colors.mutedForeground }]}>
              Without a backend the app works fully offline using BLE mesh transport,
              local message storage, and simulated network data. No internet required.
            </Text>
          </View>
        </View>

        {/* ── Examples ── */}
        <Text style={[styles.examplesTitle, { color: colors.mutedForeground }]}>EXAMPLE ENDPOINTS</Text>
        <ExampleRow label="Local network"    url="http://192.168.1.100:8080" onPress={() => fillExample("http://192.168.1.100:8080")} />
        <ExampleRow label="Home server"      url="https://mesh.example.com"  onPress={() => fillExample("https://mesh.example.com")}  />
        <ExampleRow label="Replit Dev"       url="https://yourrepl.replit.dev" onPress={() => fillExample("https://yourrepl.replit.dev")} />
        <ExampleRow label="Custom port"      url="http://10.0.0.5:3000"      onPress={() => fillExample("http://10.0.0.5:3000")}      />

        {/* ── Setup Guide ── */}
        <View style={[styles.guideCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
          <Text style={[styles.guideTitle, { color: colors.foreground }]}>APK Setup Guide</Text>
          {[
            ["1", "Install the APK on your Android device"],
            ["2", "Run the MauriMesh API server on your host machine"],
            ["3", "Ensure the device can reach the server (same WiFi or VPN)"],
            ["4", "Enter the server URL above and tap Save & Connect"],
            ["5", "Green status confirms live data is flowing"],
          ].map(([num, step]) => (
            <View key={num} style={styles.guideRow}>
              <View style={[styles.guideNum, { backgroundColor: colors.primary + "22", borderColor: colors.primary + "44" }]}>
                <Text style={[styles.guideNumText, { color: colors.primary }]}>{num}</Text>
              </View>
              <Text style={[styles.guideStep, { color: colors.mutedForeground }]}>{step}</Text>
            </View>
          ))}
        </View>

        <View style={{ height: bottomInset + 24 }} />
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

function makeStyles(colors: Colors, topInset: number, bottomInset: number, accent: string) {
  return StyleSheet.create({
    root:   { flex: 1, backgroundColor: colors.background },
    scroll: { flex: 1 },
    content: { paddingBottom: bottomInset + 24 },

    header: {
      flexDirection: "row", alignItems: "center", gap: 14,
      paddingTop: topInset + 12, paddingHorizontal: 20, paddingBottom: 20,
      borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: colors.border,
    },
    backBtn: {
      width: 38, height: 38, borderRadius: 12,
      backgroundColor: colors.card, borderWidth: 1, borderColor: colors.border,
      alignItems: "center", justifyContent: "center",
    },
    headerTitle: { fontSize: 20, fontWeight: "700" as const, color: colors.foreground, fontFamily: "Inter_700Bold", letterSpacing: -0.4 },
    headerSub:   { fontSize: 12, color: colors.mutedForeground, fontFamily: "Inter_400Regular", marginTop: 2 },

    statusCard: {
      flexDirection: "row", alignItems: "center", gap: 14,
      margin: 20, padding: 16, borderRadius: 16,
      backgroundColor: colors.card, borderWidth: 1,
    },
    statusIconWrap: { width: 46, height: 46, borderRadius: 14, alignItems: "center", justifyContent: "center", flexShrink: 0 },
    statusText:     { flex: 1 },
    statusLabel:    { fontSize: 15, fontWeight: "700" as const, fontFamily: "Inter_700Bold" },
    statusUrl:      { fontSize: 12, color: colors.mutedForeground, fontFamily: "Inter_400Regular", marginTop: 2 },
    statusMeta:     { fontSize: 11, fontFamily: "Inter_500Medium", color: accent, marginTop: 3 },
    statusError:    { fontSize: 12, color: colors.destructive, fontFamily: "Inter_400Regular", marginTop: 2 },
    retestBtn:      { padding: 8 },

    inputSection: { paddingHorizontal: 20, marginBottom: 20 },
    inputLabel:   { fontSize: 11, fontWeight: "700" as const, color: colors.mutedForeground, letterSpacing: 1.5, fontFamily: "Inter_700Bold", marginBottom: 8 },
    inputWrap: {
      flexDirection: "row", alignItems: "center", gap: 10,
      borderWidth: 1, borderRadius: 14,
      backgroundColor: colors.card, paddingHorizontal: 14, height: 52,
    },
    inputIcon: { flexShrink: 0 },
    input:     { flex: 1, fontSize: 15, fontFamily: "Inter_400Regular" },
    inputHint: { fontSize: 11, color: colors.mutedForeground, fontFamily: "Inter_400Regular", marginTop: 8, lineHeight: 16 },

    actions: { paddingHorizontal: 20, gap: 10, marginBottom: 24 },
    primaryBtn: {
      flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 8,
      borderRadius: 14, height: 52,
      shadowColor: colors.primary, shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.4, shadowRadius: 12, elevation: 6,
    },
    primaryBtnText: { fontSize: 15, fontWeight: "700" as const, color: "#000", fontFamily: "Inter_700Bold" },
    secondaryBtn: {
      flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 8,
      borderRadius: 14, height: 48, borderWidth: 1, backgroundColor: colors.card,
    },
    secondaryBtnText: { fontSize: 14, fontWeight: "600" as const, fontFamily: "Inter_600SemiBold" },
    destructBtn: {
      flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 8,
      borderRadius: 14, height: 44, borderWidth: 1,
    },
    destructBtnText: { fontSize: 14, fontWeight: "600" as const, fontFamily: "Inter_600SemiBold" },

    offlineNotice: {
      flexDirection: "row", gap: 12, alignItems: "flex-start",
      marginHorizontal: 20, marginBottom: 28, padding: 16,
      borderRadius: 14, borderWidth: 1,
    },
    offlineNoticeText: { flex: 1 },
    offlineNoticeTitle: { fontSize: 13, fontWeight: "700" as const, fontFamily: "Inter_700Bold", marginBottom: 4 },
    offlineNoticeBody:  { fontSize: 12, fontFamily: "Inter_400Regular", lineHeight: 18 },

    examplesTitle: {
      fontSize: 11, fontWeight: "700" as const, fontFamily: "Inter_700Bold",
      letterSpacing: 1.5, paddingHorizontal: 20, marginBottom: 10,
    },

    guideCard: { margin: 20, padding: 20, borderRadius: 16, borderWidth: 1, gap: 12 },
    guideTitle: { fontSize: 14, fontWeight: "700" as const, fontFamily: "Inter_700Bold", marginBottom: 4 },
    guideRow:   { flexDirection: "row", alignItems: "flex-start", gap: 12 },
    guideNum:   { width: 24, height: 24, borderRadius: 12, borderWidth: 1, alignItems: "center", justifyContent: "center", flexShrink: 0, marginTop: 1 },
    guideNumText: { fontSize: 11, fontWeight: "700" as const, fontFamily: "Inter_700Bold" },
    guideStep:  { flex: 1, fontSize: 13, fontFamily: "Inter_400Regular", lineHeight: 19 },
  });
}
