import { useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { MauriCoreStatusPanel } from "../src/components/MauriCoreStatusPanel";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

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
      <Text style={styles.title}>Dashboard</Text>
      <Text style={styles.subtitle}>
        MauriMesh command centre for messenger UI, mesh visibility, proof ledger,
        routing, governance, self-healing, device proof, and final completion.
      </Text>

      <MeshSignalCard
        title="Mesh Status"
        value={mesh?.message || "Checking mesh status..."}
        status={mode}
      />

      <MauriCoreStatusPanel />

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Core Messenger</Text>
        <MauriButton title="Chat" onPress={() => router.push("/chat")} />
        <MauriButton title="Living Mesh" onPress={() => router.push("/living-mesh")} />
        <MauriButton title="Mesh Status" onPress={() => router.push("/mesh-status")} />
        <MauriButton title="Add Friend" onPress={() => router.push("/add-friend")} />
        <MauriButton title="Pixel Calling" onPress={() => router.push("/pixel-calling")} />
        <MauriButton title="Settings" onPress={() => router.push("/settings")} />
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Final UI Layers</Text>
        <MauriButton title="UI Roadmap" onPress={() => router.push("/ui-roadmap")} />
        <MauriButton title="Proof Ledger" onPress={() => router.push("/proof-ledger")} />
        <MauriButton title="Route Lab" onPress={() => router.push("/route-lab")} />
        <MauriButton title="Tikanga Engine" onPress={() => router.push("/tikanga-engine")} />
        <MauriButton title="Self-Healing" onPress={() => router.push("/self-healing")} />
        <MauriButton title="Device Proof" onPress={() => router.push("/device-proof")} />
        <MauriButton title="Operator Console" onPress={() => router.push("/operator-console")} />
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>MauriCore</Text>
        <MauriButton title="MauriCore Governance" onPress={() => router.push("/mauricore-governance")} />
        <MauriButton title="MauriCore BLE Runtime" onPress={() => router.push("/mauricore-ble-runtime")} />
      </View>

      
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Navigation Check</Text>
        <MauriButton title="Dashboard Home" onPress={() => router.push("/dashboard")} />
        <MauriButton title="Back To Login" variant="secondary" onPress={() => router.replace("/login")} />
      </View>

      <View style={styles.notice}>
        <Text style={styles.noticeTitle}>Final Truth</Text>
        <Text style={styles.noticeText}>
          Replit proves UI, routing shells, API fallback, TypeScript, and simulation views.
          Real BLE, QR camera, native Bluetooth scanning, phone-to-phone ACK, and real calling transport still require APK/device proof.
        </Text>
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 36,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 15,
    lineHeight: 22,
  },
  section: {
    gap: mauriTheme.spacing.md,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
  },
  sectionTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  notice: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm,
  },
  noticeTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 16,
    fontWeight: "900",
  },
  noticeText: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 13,
    lineHeight: 20,
  },
});
