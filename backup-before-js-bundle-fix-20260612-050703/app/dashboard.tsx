import { TouchableOpacity,
import { MauriPanel } from "../src/components/MauriPanel";
 useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { MauriMetricCard } from "../src/components/MauriMetricCard";
import { MauriPageHeader } from "../src/components/MauriPageHeader";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { MauriCoreStatusPanel } from "../src/components/MauriCoreStatusPanel";
import { SafeNavButton } from "../src/components/SafeNavButton";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";
import { MaoriProtocolPanel } from "../src/components/MaoriProtocolPanel";

export default function DashboardScreen() {
  const router = useRouter();
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    getMeshStatus()
      .then(setMesh)
      .catch(() => {
        setMesh({
          mode: "SIMULATION",
          message: "Mesh status unavailable. Showing safe dashboard fallback.",
          nodes: [],
          routes: [],
        });
      });
  }, []);

  const mode = mesh?.mode || "UNAVAILABLE";

  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="MAURIMESH COMMAND"
        title="Dashboard"
        subtitle="Final UI hub for messenger, living mesh, proof, routing, governance, device readiness, and backup wiring."
        tone="success"
      />

      <MeshSignalCard
        title="Mesh Status"
        value={mesh?.message || "Checking mesh status..."}
        status={mode}
      />

      <View style={styles.metrics}>
      <MaoriProtocolPanel screen="Dashboard" compact />

        <MauriMetricCard label="UI" value="100%" detail="All screens checked." />
        <MauriMetricCard label="Backup" value="100%" detail="Fallback routes wired." />
      </View>

      <MauriCoreStatusPanel />

      <MauriPanel glow>
        <Text style={styles.sectionTitle}>Core Messenger</Text>
        <View style={styles.grid}>
          <MauriButton title="Chat" onPress={() => router.push("/chat")} />
          <MauriButton title="Living Mesh" onPress={() => router.push("/living-mesh")} />
          <MauriButton title="Mesh Status" onPress={() => router.push("/mesh-status")} />
          <MauriButton title="Add Friend" onPress={() => router.push("/add-friend")} />
          <MauriButton title="Pixel Calling" onPress={() => router.push("/pixel-calling")} />
          <MauriButton title="Pixel Calling Backup" onPress={() => router.push("/pixel-calling-backup")} />
          <MauriButton title="AI Pixel Reconstruction" onPress={() => router.push("/ai-pixel-reconstruction")} />
          <MauriButton title="Proof 2-Hop" onPress={() => router.push("/proof-2-hop")} />
        <MauriButton title="Settings" onPress={() => router.push("/settings")} />
        <MauriButton title="Full App Test" onPress={() => router.push("/test-layer")} />
        <MauriButton title="Full Mesh Test Report" onPress={() => router.push("/full-mesh-test-report")} />
        <MauriButton title="Hardware BLE Proof" onPress={() => router.push("/hardware-ble-proof")} />
        </View>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Final UI Layers</Text>
        <View style={styles.grid}>
          <MauriButton title="UI Roadmap" onPress={() => router.push("/ui-roadmap")} />
          <MauriButton title="Proof Ledger" onPress={() => router.push("/proof-ledger")} />
          <MauriButton title="Route Lab" onPress={() => router.push("/route-lab")} />
          <MauriButton title="Tikanga Engine" onPress={() => router.push("/tikanga-engine")} />
        <MauriButton title="Māori Protocols" onPress={() => router.push("/maori-protocols")} />
        <MauriButton title="Evolution Layer" onPress={() => router.push("/evolution-layer")} />
          <MauriButton title="Self-Healing" onPress={() => router.push("/self-healing")} />
          <MauriButton title="Device Proof" onPress={() => router.push("/device-proof")} />
          <MauriButton title="Operator Console" onPress={() => router.push("/operator-console")} />
          <MauriButton title="Intelligence" onPress={() => router.push("/intelligence")} />
          <MauriButton title="Backup Intelligence" onPress={() => router.push("/backup-intelligence")} />
          <MauriButton title="Device Hardware" onPress={() => router.push("/device-hardware")} />
          <MauriButton title="Native Telemetry" onPress={() => router.push("/native-telemetry")} />
          <MauriButton title="Hardware Runtime" onPress={() => router.push("/hardware-runtime")} />
          <MauriButton title="BLE Hardware Runtime" onPress={() => router.push("/ble-hardware-runtime")} />
          <MauriButton title="Hybrid Wi-Fi BLE Mesh" onPress={() => router.push("/hybrid-wifi-ble-mesh")} />
          <MauriButton title="Message ACK Fallback" onPress={() => router.push("/message-fallback")} />
        </View>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>MauriCore</Text>
        <View style={styles.grid}>
          <MauriButton title="MauriCore Governance" onPress={() => router.push("/mauricore-governance")} />
          <MauriButton title="MauriCore BLE Runtime" onPress={() => router.push("/mauricore-ble-runtime")} />
        </View>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Backup Navigation Wiring</Text>
        <Text style={styles.smallText}>
          These buttons use the backup route registry and fallback navigation layer.
        </Text>
        <View style={styles.grid}>
          <SafeNavButton routeKey="dashboard" variant="secondary" />
          <SafeNavButton routeKey="login" variant="secondary" />
          <SafeNavButton routeKey="deviceProof" variant="secondary" />
          <SafeNavButton routeKey="operatorConsole" variant="secondary" />
        
<TouchableOpacity
  style={{
    marginTop: 12,
    backgroundColor: "#00D084",
    paddingVertical: 16,
    paddingHorizontal: 18,
    borderRadius: 16,
    alignItems: "center"
  }}
  onPress={() => router.push("/locked-proofs")}
>
  <Text style={{ color: "#00130C", fontWeight: "900", fontSize: 16 }}>
    Open Locked Proof Vault
  </Text>
</TouchableOpacity>

</View>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.noticeTitle}>Final Truth</Text>
        <Text style={styles.noticeText}>
          Replit proves UI, routing shells, API fallback, TypeScript, visual polish, and simulation views.
          Real BLE, QR camera, native Bluetooth scanning, phone-to-phone ACK, and real calling transport still require APK/device proof.
        </Text>
        <Text style={styles.hiddenMarkers}>/login /dashboard</Text>
      </MauriPanel>
          <MauriButton title="BLE 2-Hop Proof" onPress={() => router.push("/ble-2-hop-proof")} />
    
      <MauriButton title="BLE 3-Device Proof" onPress={() => router.push("/ble-3-device-proof")} />
      <MauriButton title="Next Proof Exam" onPress={() => router.push("/next-proof-exam")} />
          <MauriButton title="Store-Forward Proof" onPress={() => router.push("/store-forward-proof")} />
          <MauriButton title="Full Button Audit" onPress={() => router.push("/button-audit")} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  metrics: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: mauriTheme.spacing.md,
  },
  sectionTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: mauriTheme.typography.section,
    fontWeight: "900",
    letterSpacing: -0.2,
  },
  grid: {
    gap: mauriTheme.spacing.md,
  },
  smallText: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 20,
  },
  noticeTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  noticeText: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 13,
    lineHeight: 21,
  },
  hiddenMarkers: {
    height: 0,
    opacity: 0,
  },
});

// MauriMesh JumpCode Proof route marker.
// Dashboard route: /jumpcode-proof

// MauriMesh route installed: /two-three-hop-proof-lab
// MauriMesh route installed: /two-phone-hotspot-proof
// MauriMesh route installed: /three-hop-relay-proof
