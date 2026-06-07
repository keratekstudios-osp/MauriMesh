import React, { useEffect, useState } from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function MeshStatusScreen() {
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh);
  }, []);

  return (
    <AppShell>
      <Text style={styles.title}>Mesh Status</Text>
      <MeshSignalCard title="API Connection" value={mesh?.message || "Checking..."} status={mesh?.mode || "UNAVAILABLE"} />
      <MeshSignalCard title="Nodes Visible" value={`${mesh?.nodes.length || 0} node(s) visible in current mode.`} status={mesh?.mode || "UNAVAILABLE"} />
      <MeshSignalCard title="Routes Visible" value={`${mesh?.routes.length || 0} route(s) visible in current mode.`} status={mesh?.mode || "UNAVAILABLE"} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" }
});
