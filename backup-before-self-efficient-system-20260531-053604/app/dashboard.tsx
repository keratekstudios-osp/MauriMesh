import { useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { CompletionAuditPanel } from "../src/components/CompletionAuditPanel";
import { InventionEngineCard } from "../src/components/InventionEngineCard";
import { MauriButton } from "../src/components/MauriButton";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { getMauriCompletionAudit, MauriCompletionAudit } from "../src/lib/mauriEssentials";
import { getInventionEngineStatus } from "../src/lib/inventionEngineClient";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function DashboardScreen() {
  const router = useRouter();
  const [mesh, setMesh] = useState<MeshStatus | null>(null);
  const [engineMessage, setEngineMessage] = useState("Checking invention engine...");
  const [audit, setAudit] = useState<MauriCompletionAudit | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh);
    getInventionEngineStatus().then((snapshot) => setEngineMessage(snapshot.message));
    setAudit(getMauriCompletionAudit());
  }, []);

  const mode = mesh?.mode || "UNAVAILABLE";

  return (
    <AppShell>
      <Text style={styles.title}>Dashboard</Text>
      <Text style={styles.subtitle}>
        Command centre for MauriMesh Messenger, invention register, living mesh,
        Mauri AI, Tikanga governance, routing intelligence, and Replit-safe proof.
      </Text>

      <MeshSignalCard
        title="Mesh Status"
        value={mesh?.message || "Checking mesh status..."}
        status={mode}
      />

      <InventionEngineCard
        title="Living Self-Governed AI Mesh"
        value={engineMessage}
        tone="success"
      />

      <View style={styles.grid}>
        <MauriButton title="Invention Engine" onPress={() => router.push("/invention-engine")} />
        <MauriButton title="Invention Register" variant="secondary" onPress={() => router.push("/invention-register")} />
        <MauriButton title="Governance" variant="secondary" onPress={() => router.push("/governance")} />
        <MauriButton title="Route Lab" variant="secondary" onPress={() => router.push("/route-lab")} />
        <MauriButton title="System Check" variant="secondary" onPress={() => router.push("/system-check")} />
        <MauriButton title="Chat" onPress={() => router.push("/chat")} />
        <MauriButton title="Living Mesh" onPress={() => router.push("/living-mesh")} />
        <MauriButton title="Mesh Status" onPress={() => router.push("/mesh-status")} />
        <MauriButton title="Add Friend" onPress={() => router.push("/add-friend")} />
        <MauriButton title="Pixel Calling" onPress={() => router.push("/pixel-calling")} />
        <MauriButton title="Settings" onPress={() => router.push("/settings")} />
      </View>

      {audit ? <CompletionAuditPanel audit={audit} /> : null}
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
});
