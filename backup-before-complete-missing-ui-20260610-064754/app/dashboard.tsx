import { useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function DashboardScreen() {
  const router = useRouter();
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh).catch(() => {
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
        MauriMesh command centre for messenger UI, mesh visibility, proof layers,
        governance, route design, and remaining UI completion.
      </Text>

      <MeshSignalCard
        title="Mesh Status"
        value={mesh?.message || "Checking mesh status..."}
        status={mode}
      />

      <View style={styles.grid}>
        <MauriButton title="Chat" onPress={() => router.push("/chat")} />
        <MauriButton title="Living Mesh" onPress={() => router.push("/living-mesh")} />
        <MauriButton title="Mesh Status" onPress={() => router.push("/mesh-status")} />
        <MauriButton title="Add Friend" onPress={() => router.push("/add-friend")} />
        <MauriButton title="Pixel Calling" onPress={() => router.push("/pixel-calling")} />
        <MauriButton title="Settings" onPress={() => router.push("/settings")} />

        <MauriButton title="UI Roadmap" onPress={() => router.push("/ui-roadmap")} />
      </View>

      <View style={styles.notice}>
        <Text style={styles.noticeTitle}>Final Truth</Text>
        <Text style={styles.noticeText}>
          Replit can complete UI, routing shells, API fallback, and simulation views.
          Real BLE, native Bluetooth scanning, QR camera proof, and phone-to-phone ACK
          still require APK/device proof.
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
  grid: {
    gap: mauriTheme.spacing.md,
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
