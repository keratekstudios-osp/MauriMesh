import { useState } from "react";
import {
  Alert,
  Linking,
  Pressable,
  ScrollView,
  Share,
  StyleSheet,
  Switch,
  Text,
  View,
} from "react-native";
import { useRouter } from "expo-router";
import * as Haptics from "expo-haptics";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { clearSession } from "../lib/session";
import { safeNavigate } from "../lib/safeNavigate";

const INSTALL_URL = "https://expo.dev/accounts/mauri-mesh-network/projects/maurimesh-messenger/builds";

const rows = [
  {
    section: "FRIENDS",
    items: [
      { title: "Add Friend",    subtitle: "Scan QR or find nearby MauriMesh nodes", icon: "♙", route: "/add-friend"    },
      { title: "My QR Code",   subtitle: "Share your mesh identity",                icon: "⌗", route: "/my-qr"         },
    ],
  },
  {
    section: "SYSTEM",
    items: [
      { title: "Local Storage",         subtitle: "Manage message retention",              icon: "▤", route: "/local-storage"   },
      { title: "Export Diagnostic Logs",subtitle: "Generate local diagnostic bundle",       icon: "⌁", route: "/diagnostic-logs" },
      { title: "Living Mesh Core",      subtitle: "3D mesh visualiser · offline engine",   icon: "▣", route: "/living-mesh"     },
    ],
  },
];

export default function ConfigurationScreen() {
  const router  = useRouter();
  const insets  = useSafeAreaInsets();

  const [dark,   setDark]   = useState(true);
  const [ble,    setBle]    = useState(true);
  const [tx,     setTx]     = useState(false);
  const [hybrid, setHybrid] = useState(true);
  const [strict, setStrict] = useState(true);

  async function go(route: string) {
    await Haptics.selectionAsync();
    safeNavigate(router, route);
  }

  async function logout() {
    await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    Alert.alert(
      "Sign Out",
      "End your session and return to the login screen?",
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

  async function handleShareInvite() {
    await Haptics.selectionAsync();
    try {
      await Share.share({
        title: "Install MauriMesh Messenger",
        message: `Join the MauriMesh private mesh network.\n\nDownload the app here:\n${INSTALL_URL}`,
        url: INSTALL_URL,
      });
    } catch {
      Alert.alert("Share failed", "Could not open the share sheet.");
    }
  }

  async function handleOpenInstall() {
    await Haptics.selectionAsync();
    const canOpen = await Linking.canOpenURL(INSTALL_URL);
    if (canOpen) {
      await Linking.openURL(INSTALL_URL);
    } else {
      Alert.alert("Cannot open link", `Open this URL manually:\n${INSTALL_URL}`);
    }
  }

  return (
    <ScrollView
      style={styles.root}
      contentContainerStyle={{
        paddingTop: insets.top + 24,
        paddingBottom: insets.bottom + 48,
      }}
      showsVerticalScrollIndicator={false}
    >
      <View style={styles.header}>
        <View style={styles.headerIconWrap}>
          <Text style={styles.headerIcon}>⚙</Text>
        </View>
        <View>
          <Text style={styles.title}>Configuration</Text>
          <Text style={styles.subtitle}>System parameters</Text>
        </View>
      </View>

      <SectionLabel label="APPEARANCE" />

      <View style={styles.segment}>
        <Pressable
          onPress={() => { Haptics.selectionAsync(); setDark(true); }}
          style={[styles.segmentButton, dark && styles.segmentActive]}
        >
          <Text style={[styles.segmentText, dark && styles.segmentTextActive]}>
            ☾  Dark
          </Text>
        </Pressable>
        <Pressable
          onPress={() => { Haptics.selectionAsync(); setDark(false); }}
          style={[styles.segmentButton, !dark && styles.segmentActive]}
        >
          <Text style={[styles.segmentText, !dark && styles.segmentTextActive]}>
            ☼  Light
          </Text>
        </Pressable>
      </View>

      <SectionLabel label="RADIO HARDWARE" />

      <ToggleRow icon="ᛒ" title="BLE Transceiver"  subtitle="Primary short-range transport"  value={ble}    setValue={setBle}    />
      <ToggleRow icon="ϟ" title="High Tx Power"     subtitle="Increases range · drains battery" value={tx}     setValue={setTx}     />

      <SectionLabel label="ROUTING & SECURITY" />

      <ToggleRow icon="▣" title="Hybrid Routing"   subtitle="Auto-failover to LoRa"           value={hybrid} setValue={setHybrid} />
      <ToggleRow icon="⬡" title="Strict Mode"      subtitle="Drop unverified packets"         value={strict} setValue={setStrict} />

      {rows.map((group) => (
        <View key={group.section}>
          <SectionLabel label={group.section} />
          {group.items.map((item) => (
            <NavRow
              key={item.title}
              icon={item.icon}
              title={item.title}
              subtitle={item.subtitle}
              onPress={() => go(item.route)}
            />
          ))}
        </View>
      ))}

      <View style={styles.accessCard}>
        <View style={styles.accessTop}>
          <View style={styles.accessIconWrap}>
            <Text style={styles.accessIconText}>⌘</Text>
          </View>
          <View style={styles.trustPill}>
            <View style={styles.trustDot} />
            <Text style={styles.trustText}>Trusted Access</Text>
          </View>
        </View>

        <Text style={styles.accessTitle}>MauriMesh Access</Text>
        <Text style={styles.accessText}>
          Invite a trusted tester to install MauriMesh Messenger and join the private mesh network.
        </Text>

        <View style={styles.linkBox}>
          <Text style={styles.linkText}>{INSTALL_URL}</Text>
        </View>

        <View style={styles.accessRule} />

        <Pressable
          onPress={handleShareInvite}
          style={({ pressed }) => [
            styles.shareButton,
            pressed && { opacity: 0.84, transform: [{ scale: 0.97 }] },
          ]}
        >
          <Text style={styles.shareText}>✈  Share Invite</Text>
        </Pressable>

        <Pressable
          onPress={handleOpenInstall}
          style={({ pressed }) => [styles.openInstall, pressed && { opacity: 0.7 }]}
        >
          <Text style={styles.openInstallText}>↗  Open Install Page</Text>
        </Pressable>
      </View>

      <Pressable
        onPress={logout}
        style={({ pressed }) => [
          styles.logout,
          pressed && { opacity: 0.84, transform: [{ scale: 0.97 }] },
        ]}
      >
        <Text style={styles.logoutText}>↪  Sign Out</Text>
      </Pressable>

      <Text style={styles.footer}>MauriMesh Core v1.4.2-alpha</Text>
      <Text style={styles.footerSmall}>Built for resilience · Decentralized first</Text>
    </ScrollView>
  );
}

function SectionLabel({ label }: { label: string }) {
  return <Text style={styles.section}>{label}</Text>;
}

function ToggleRow({
  icon, title, subtitle, value, setValue,
}: {
  icon: string; title: string; subtitle: string; value: boolean; setValue: (v: boolean) => void;
}) {
  return (
    <View style={styles.row}>
      <View style={styles.rowIcon}>
        <Text style={styles.rowIconText}>{icon}</Text>
      </View>
      <View style={styles.rowTextWrap}>
        <Text style={styles.rowTitle}>{title}</Text>
        <Text style={styles.rowSubtitle}>{subtitle}</Text>
      </View>
      <Switch
        value={value}
        onValueChange={(v) => { Haptics.selectionAsync(); setValue(v); }}
        trackColor={{ false: "#1E2A3A", true: "#1A5C00" }}
        thumbColor={value ? "#39FF14" : "#4A5568"}
      />
    </View>
  );
}

function NavRow({
  icon, title, subtitle, onPress,
}: {
  icon: string; title: string; subtitle: string; onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.row,
        pressed && { opacity: 0.84, transform: [{ scale: 0.99 }] },
      ]}
    >
      <View style={styles.rowIcon}>
        <Text style={styles.rowIconText}>{icon}</Text>
      </View>
      <View style={styles.rowTextWrap}>
        <Text style={styles.rowTitle}>{title}</Text>
        <Text style={styles.rowSubtitle}>{subtitle}</Text>
      </View>
      <Text style={styles.chevron}>›</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#050816" },
  header: { paddingHorizontal: 24, paddingBottom: 28, flexDirection: "row", alignItems: "center", gap: 16, borderBottomWidth: 1, borderColor: "rgba(255,255,255,0.07)" },
  headerIconWrap: { width: 56, height: 56, borderRadius: 16, alignItems: "center", justifyContent: "center", backgroundColor: "rgba(57,255,20,0.08)", borderWidth: 1, borderColor: "rgba(57,255,20,0.18)" },
  headerIcon:  { color: "#39FF14", fontSize: 28 },
  title:       { color: "#FFFFFF", fontSize: 30, fontWeight: "900", fontFamily: "Inter_700Bold" },
  subtitle:    { marginTop: 4, color: "#94A3B8", fontSize: 14, fontWeight: "600", fontFamily: "Inter_600SemiBold" },
  section:     { paddingHorizontal: 24, marginTop: 28, marginBottom: 8, color: "#94A3B8", fontSize: 10, fontWeight: "900", fontFamily: "Inter_700Bold", letterSpacing: 5 },
  segment:     { marginHorizontal: 24, height: 60, borderRadius: 16, padding: 6, flexDirection: "row", backgroundColor: "#0B1220", borderWidth: 1, borderColor: "rgba(255,255,255,0.07)" },
  segmentButton:     { flex: 1, borderRadius: 12, alignItems: "center", justifyContent: "center" },
  segmentActive:     { backgroundColor: "#101827", borderWidth: 1, borderColor: "rgba(57,255,20,0.30)" },
  segmentText:       { color: "#64748B", fontSize: 15, fontWeight: "800", fontFamily: "Inter_700Bold" },
  segmentTextActive: { color: "#39FF14", fontFamily: "Inter_700Bold" },
  row:          { minHeight: 80, paddingHorizontal: 24, flexDirection: "row", alignItems: "center", borderTopWidth: 1, borderColor: "rgba(255,255,255,0.05)", backgroundColor: "#0B1220" },
  rowIcon:      { width: 52, height: 52, borderRadius: 14, alignItems: "center", justifyContent: "center", backgroundColor: "#101827", borderWidth: 1, borderColor: "rgba(255,255,255,0.07)", marginRight: 16 },
  rowIconText:  { color: "#94A3B8", fontSize: 22, fontWeight: "900" },
  rowTextWrap:  { flex: 1 },
  rowTitle:     { color: "#FFFFFF",  fontSize: 16, fontWeight: "800", fontFamily: "Inter_700Bold"     },
  rowSubtitle:  { marginTop: 3, color: "#94A3B8", fontSize: 13, fontWeight: "500", fontFamily: "Inter_500Medium" },
  chevron:      { color: "#94A3B8", fontSize: 32, fontWeight: "300" },
  accessCard:   { marginHorizontal: 24, marginTop: 32, padding: 24, borderRadius: 28, backgroundColor: "#101827", borderWidth: 1, borderColor: "rgba(57,255,20,0.20)", shadowColor: "#39FF14", shadowOpacity: 0.08, shadowRadius: 16, elevation: 4 },
  accessTop:    { flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 16 },
  accessIconWrap:  { width: 56, height: 56, borderRadius: 28, alignItems: "center", justifyContent: "center", backgroundColor: "rgba(57,255,20,0.10)", borderWidth: 1, borderColor: "rgba(57,255,20,0.22)" },
  accessIconText:  { color: "#39FF14", fontSize: 26, fontWeight: "900" },
  trustPill:    { flexDirection: "row", alignItems: "center", gap: 6, paddingHorizontal: 12, paddingVertical: 8, borderRadius: 12, backgroundColor: "rgba(57,255,20,0.08)", borderWidth: 1, borderColor: "rgba(57,255,20,0.20)" },
  trustDot:     { width: 6, height: 6, borderRadius: 3, backgroundColor: "#39FF14" },
  trustText:    { color: "#39FF14", fontSize: 11, fontWeight: "800", fontFamily: "Inter_700Bold" },
  accessTitle:  { color: "#FFFFFF", fontSize: 22, fontWeight: "900", fontFamily: "Inter_700Bold" },
  accessText:   { color: "#94A3B8", fontSize: 14, lineHeight: 22, fontFamily: "Inter_400Regular", marginTop: 10 },
  linkBox:      { marginTop: 16, paddingHorizontal: 14, paddingVertical: 12, borderRadius: 12, backgroundColor: "#0B1220", borderWidth: 1, borderColor: "rgba(255,255,255,0.07)" },
  linkText:     { color: "#64748B", fontSize: 11, fontWeight: "700", fontFamily: "Inter_700Bold" },
  accessRule:   { height: 1, backgroundColor: "rgba(255,255,255,0.08)", marginVertical: 20 },
  shareButton:  { height: 56, borderRadius: 16, alignItems: "center", justifyContent: "center", backgroundColor: "#39FF14", shadowColor: "#39FF14", shadowOpacity: 0.32, shadowRadius: 16, elevation: 6 },
  shareText:    { color: "#050816", fontSize: 16, fontWeight: "900", fontFamily: "Inter_700Bold" },
  openInstall:  { height: 52, alignItems: "center", justifyContent: "center" },
  openInstallText: { color: "#94A3B8", fontSize: 14, fontWeight: "800", fontFamily: "Inter_700Bold" },
  logout:       { marginHorizontal: 24, marginTop: 24, height: 60, borderRadius: 18, alignItems: "center", justifyContent: "center", backgroundColor: "rgba(239,68,68,0.08)", borderWidth: 1, borderColor: "rgba(239,68,68,0.28)" },
  logoutText:   { color: "#EF4444", fontSize: 16, fontWeight: "900", fontFamily: "Inter_700Bold" },
  footer:       { marginTop: 36, textAlign: "center", color: "rgba(255,255,255,0.18)", fontSize: 13, fontWeight: "700", fontFamily: "Inter_700Bold" },
  footerSmall:  { marginTop: 6, textAlign: "center", color: "rgba(255,255,255,0.10)", fontSize: 11, fontWeight: "700", fontFamily: "Inter_700Bold" },
});
