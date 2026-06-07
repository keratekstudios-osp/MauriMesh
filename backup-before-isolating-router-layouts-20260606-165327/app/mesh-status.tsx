import React, { useEffect, useState } from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { DeliveryLedgerPanel } from "../src/components/DeliveryLedgerPanel";
import { InventionEngineCard } from "../src/components/InventionEngineCard";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { SynthPanel } from "../src/components/SynthPanel";
import { getInventionEngineStatus } from "../src/lib/inventionEngineClient";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

type Snapshot = Awaited<ReturnType<typeof getInventionEngineStatus>>;

export default function MeshStatusScreen() {
  const [mesh, setMesh] = useState<MeshStatus | null>(null);
  const [engine, setEngine] = useState<Snapshot | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh);
    getInventionEngineStatus().then(setEngine);
  }, []);

  return (
    <AppShell>
      <Text style={styles.title}>Mesh Status</Text>

      <MeshSignalCard
        title="Replit Mesh API"
        value={mesh?.message || "Checking..."}
        status={mesh?.mode || "UNAVAILABLE"}
      />

      <InventionEngineCard
        title="Mauri AI Core"
        value={engine?.message || "Checking invention engine..."}
        tone="success"
      />

      <InventionEngineCard
        title="Self-Learning Route Memory"
        value={`${engine?.routeMemoryCount || 0} route learning record(s).`}
        tone="info"
      />

      <InventionEngineCard
        title="Decentralised Trust Memory"
        value={`${engine?.trustCount || 0} trust record(s).`}
        tone="info"
      />

      <InventionEngineCard
        title="Delivery Proof Ledger"
        value={`${engine?.ledgerCount || 0} delivery proof event(s).`}
        tone="info"
      />

      <SynthPanel messages={engine?.lastResult?.synth || []} />
      <DeliveryLedgerPanel ledger={engine?.lastResult?.ledger || []} />

      <Text style={styles.truth}>
        Replit status proves UI wiring and logic-engine operation only. Native BLE,
        Wi-Fi Direct, APK runtime, background service, and real phone-to-phone proof
        must be validated on physical Android devices.
      </Text>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  truth: {
    color: mauriTheme.colors.warning,
    fontSize: 13,
    lineHeight: 20,
    fontWeight: "700",
  },
});
