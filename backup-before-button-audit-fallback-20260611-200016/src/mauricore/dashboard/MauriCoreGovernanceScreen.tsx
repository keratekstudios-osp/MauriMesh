import React, { useMemo } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";
import { getGovernanceDashboardData } from "./governanceDashboard";
import { createAcceptanceProof } from "../acceptance/acceptanceProof";
import { deploymentChecklist } from "../deployment/deploymentReadiness";
import { runAdapters } from "../builder/adapterRegistry";

function pct(value: number): string {
  return `${Math.round(value * 100)}%`;
}

function StatusPill({
  label,
  tone = "neutral",
}: {
  label: string;
  tone?: "good" | "warn" | "bad" | "neutral";
}) {
  const color =
    tone === "good"
      ? "#00D084"
      : tone === "warn"
        ? "#F59E0B"
        : tone === "bad"
          ? "#EF4444"
          : "#38BDF8";

  return (
    <View style={[styles.pill, { borderColor: color }]}>
      <Text style={[styles.pillText, { color }]}>{label}</Text>
    </View>
  );
}

function Card({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <View style={styles.card}>
      <Text style={styles.cardTitle}>{title}</Text>
      {children}
    </View>
  );
}

export default function MauriCoreGovernanceScreen() {
  const router = useRouter();

  const data = useMemo(() => getGovernanceDashboardData(), []);
  const acceptance = useMemo(() => createAcceptanceProof(), []);
  const deployment = useMemo(() => deploymentChecklist(), []);
  const adapters = useMemo(() => runAdapters(), []);

  const weakLayers = data.layers.filter((layer) => {
    return (
      layer.status === "missing" ||
      layer.status === "partial" ||
      layer.status === "unsafe" ||
      layer.confidence < 0.72
    );
  });

  return (
    <ScrollView style={styles.safe} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>MauriCore Governance</Text>
      <Text style={styles.code}>LIVING_KERNEL_V1_GOVERNANCE_DASHBOARD</Text>

      <View style={styles.row}>
        <StatusPill
          label={data.core.proofChainOk ? "PROOF_CHAIN_OK" : "PROOF_CHAIN_BROKEN"}
          tone={data.core.proofChainOk ? "good" : "bad"}
        />
        <StatusPill
          label={data.build.canBuildApk ? "APK_READY" : "APK_NOT_READY"}
          tone={data.build.canBuildApk ? "good" : "warn"}
        />
      </View>

      <Card title="Core Status">
        <Text style={styles.line}>Name: {data.core.name}</Text>
        <Text style={styles.line}>Version: {data.core.version}</Text>
        <Text style={styles.line}>Layers: {data.layers.length}</Text>
        <Text style={styles.line}>Proof records: {data.proofCount}</Text>
        <Text style={styles.line}>Memory records: {data.memoryCount}</Text>
      </Card>

      <Card title="Build Readiness">
        <Text style={styles.line}>
          APK gate: {data.build.canBuildApk ? "READY" : "NOT READY"}
        </Text>
        <Text style={styles.line}>Warnings: {data.build.warnings.length}</Text>
        <Text style={styles.line}>Missing gates: {data.build.missing.length}</Text>
        {data.build.missing.slice(0, 12).map((item) => (
          <Text key={item} style={styles.warnLine}>
            • {item}
          </Text>
        ))}
      </Card>

      <Card title="Mauri AI Review">
        <Text style={styles.line}>{data.mauriAi.summary}</Text>
        <Text style={styles.line}>Weak layers: {data.mauriAi.weakLayers.length}</Text>
        <Text style={styles.line}>
          Memory poisoning alerts: {data.mauriAi.poisoningAlerts.length}
        </Text>
      </Card>

      <Card title="Layer Registry">
        {data.layers.map((layer) => (
          <View key={layer.id} style={styles.layer}>
            <View style={styles.layerTop}>
              <Text style={styles.layerName}>{layer.name}</Text>
              <Text style={styles.layerConfidence}>{pct(layer.confidence)}</Text>
            </View>
            <Text style={styles.layerMeta}>
              {layer.status} · risk {layer.riskLevel} · proof{" "}
              {layer.proofRequired ? "required" : "not required"}
            </Text>
          </View>
        ))}
      </Card>

      <Card title="Weak / Pending Layers">
        {weakLayers.length === 0 ? (
          <Text style={styles.goodLine}>No weak layers detected.</Text>
        ) : (
          weakLayers.map((layer) => (
            <Text key={layer.id} style={styles.warnLine}>
              • {layer.id} — {layer.status} — {pct(layer.confidence)}
            </Text>
          ))
        )}
      </Card>

      <Card title="Adapters">
        {adapters.map((adapter) => (
          <View key={adapter.adapterId} style={styles.layer}>
            <Text style={styles.layerName}>{adapter.adapterId}</Text>
            <Text style={adapter.ok ? styles.goodLine : styles.warnLine}>
              {adapter.ok ? "OK" : "Needs work"} · risk {adapter.risk}
            </Text>
            {adapter.missing.slice(0, 4).map((missing) => (
              <Text key={missing} style={styles.warnLine}>
                • {missing}
              </Text>
            ))}
          </View>
        ))}
      </Card>

      <Card title="Deployment Checklist">
        <Text style={deployment.ready ? styles.goodLine : styles.warnLine}>
          Deployment ready: {deployment.ready ? "YES" : "NO"}
        </Text>
        {deployment.checklist.map((item) => (
          <Text key={item} style={styles.line}>
            • {item}
          </Text>
        ))}
      </Card>

      <Card title="Acceptance Proof">
        <Text style={acceptance.accepted ? styles.goodLine : styles.warnLine}>
          Accepted: {acceptance.accepted ? "YES" : "NO"}
        </Text>
        <Text style={styles.line}>{acceptance.summary}</Text>

        {acceptance.passed.map((item) => (
          <Text key={item} style={styles.goodLine}>
            PASS · {item}
          </Text>
        ))}

        {acceptance.failed.map((item) => (
          <Text key={item} style={styles.badLine}>
            FAIL · {item}
          </Text>
        ))}
      </Card>

      <Pressable style={styles.backButton} onPress={() => router.back()}>
        <Text style={styles.backText}>Back</Text>
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: "#020617",
  },
  content: {
    padding: 20,
    paddingBottom: 44,
  },
  brand: {
    color: "#00D084",
    fontSize: 32,
    fontWeight: "900",
    marginTop: 18,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 26,
    fontWeight: "900",
    marginTop: 18,
  },
  code: {
    color: "#38BDF8",
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 1,
    marginTop: 8,
    marginBottom: 20,
  },
  row: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
    marginBottom: 12,
  },
  pill: {
    borderWidth: 1,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
    backgroundColor: "rgba(255,255,255,0.04)",
  },
  pillText: {
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0.8,
  },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.25)",
    backgroundColor: "rgba(0,40,34,0.72)",
    borderRadius: 18,
    padding: 16,
    marginTop: 12,
  },
  cardTitle: {
    color: "#FFFFFF",
    fontSize: 18,
    fontWeight: "900",
    marginBottom: 10,
  },
  line: {
    color: "rgba(255,255,255,0.78)",
    fontSize: 14,
    lineHeight: 21,
    fontWeight: "600",
  },
  goodLine: {
    color: "#00D084",
    fontSize: 14,
    lineHeight: 21,
    fontWeight: "800",
  },
  warnLine: {
    color: "#F59E0B",
    fontSize: 14,
    lineHeight: 21,
    fontWeight: "800",
  },
  badLine: {
    color: "#EF4444",
    fontSize: 14,
    lineHeight: 21,
    fontWeight: "800",
  },
  layer: {
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.08)",
    paddingTop: 10,
    marginTop: 10,
  },
  layerTop: {
    flexDirection: "row",
    justifyContent: "space-between",
    gap: 12,
  },
  layerName: {
    color: "#FFFFFF",
    fontSize: 14,
    fontWeight: "900",
    flex: 1,
  },
  layerConfidence: {
    color: "#00D084",
    fontSize: 13,
    fontWeight: "900",
  },
  layerMeta: {
    color: "rgba(255,255,255,0.62)",
    fontSize: 12,
    marginTop: 4,
    fontWeight: "700",
  },
  backButton: {
    marginTop: 18,
    minHeight: 52,
    borderRadius: 16,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#00D084",
  },
  backText: {
    color: "#020617",
    fontWeight: "900",
    fontSize: 16,
  },
});
