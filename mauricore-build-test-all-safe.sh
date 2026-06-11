#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURICORE BUILD + WIRE + TEST ALL SAFE PASS"
echo "Creates UI route, verifies folders, runs TypeScript, smoke,"
echo "Expo export, optional Rust check, optional EAS build gate"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-mauricore-build-test-all-$STAMP"
REPORTS="$ROOT/reports/mauricore"
REPORT="$REPORTS/mauricore-build-test-all-$STAMP.md"

mkdir -p "$BACKUP" "$REPORTS"

echo "Project root: $ROOT"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from /home/runner/workspace."
  exit 1
fi

if [ ! -d "$ROOT/app" ]; then
  echo "ERROR: app/ folder not found."
  exit 1
fi

if [ ! -d "$ROOT/src/mauricore" ]; then
  echo "ERROR: src/mauricore not found. MauriCore v1 must be installed first."
  exit 1
fi

cat > "$BACKUP/README.txt" <<TXT
Backup marker before MauriCore build/test all pass.
Timestamp: $STAMP

This script writes/updates:
- app/mauricore-governance.tsx
- src/mauricore/dashboard/MauriCoreGovernanceScreen.tsx
- src/mauricore/dashboard/mauriCoreGovernanceRoute.ts
- reports/mauricore/*

It does not delete BLE/router/ACK/store-forward/native files.
TXT

echo ""
echo "1. Verify required MauriCore files"

REQUIRED=(
  "$ROOT/src/mauricore/index.ts"
  "$ROOT/src/mauricore/dashboard/governanceDashboard.ts"
  "$ROOT/src/mauricore/acceptance/acceptanceProof.ts"
  "$ROOT/src/mauricore/deployment/deploymentReadiness.ts"
  "$ROOT/src/mauricore/builder/adapterRegistry.ts"
  "$ROOT/src/mauricore/testing/smoke.ts"
  "$ROOT/scripts/mauricore-smoke-test.ts"
)

for f in "${REQUIRED[@]}"; do
  if [ -f "$f" ]; then
    echo "PASS: ${f#$ROOT/}"
  else
    echo "FAIL: missing ${f#$ROOT/}"
    exit 1
  fi
done

echo ""
echo "2. Create/refresh MauriCore Governance route + screen in correct folders"

mkdir -p "$ROOT/src/mauricore/dashboard" "$ROOT/app"

cat > "$ROOT/src/mauricore/dashboard/mauriCoreGovernanceRoute.ts" <<'TS'
export const MAURICORE_GOVERNANCE_ROUTE = "/mauricore-governance";
TS

cat > "$ROOT/app/mauricore-governance.tsx" <<'TSX'
export { default } from "../src/mauricore/dashboard/MauriCoreGovernanceScreen";
TSX

cat > "$ROOT/src/mauricore/dashboard/MauriCoreGovernanceScreen.tsx" <<'TSX'
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
TSX

echo ""
echo "3. Attempt safe dashboard button wiring"

node <<'NODE'
const fs = require("fs");
const path = require("path");

const root = process.cwd();
const route = "/mauricore-governance";

function walk(dir, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const item of fs.readdirSync(dir)) {
    const full = path.join(dir, item);
    const stat = fs.statSync(full);
    if (stat.isDirectory()) {
      if (["node_modules", ".git", "dist", "android", "ios", "rust"].includes(item)) continue;
      walk(full, out);
    } else if (/\.(tsx|ts|jsx|js)$/.test(item)) {
      out.push(full);
    }
  }
  return out;
}

const files = [
  ...walk(path.join(root, "app")),
  ...walk(path.join(root, "screens")),
  ...walk(path.join(root, "src/screens")),
].filter(Boolean);

let target = files.find((file) => {
  const s = fs.readFileSync(file, "utf8");
  return s.includes("Proof Ledger") && s.includes("Back Home");
});

if (!target) {
  target = files.find((file) => {
    const s = fs.readFileSync(file, "utf8");
    return s.includes("Dashboard") && s.includes("Settings") && s.includes("Chat");
  });
}

if (!target) {
  console.log("No safe dashboard target found. Route exists at /mauricore-governance.");
  process.exit(0);
}

let source = fs.readFileSync(target, "utf8");

if (source.includes(route) || source.includes("MauriCore Governance")) {
  console.log(`Dashboard already wired: ${path.relative(root, target)}`);
  process.exit(0);
}

const backup = `${target}.before-mauricore-button-${Date.now()}.bak`;
fs.copyFileSync(target, backup);

const needsRouterImport = !source.includes("useRouter");
const needsPressableImport = !source.includes("Pressable");

if (needsRouterImport) {
  source = source.replace(
    /import React[^;]*;/,
    (m) => `${m}\nimport { useRouter } from "expo-router";`
  );
}

if (needsPressableImport) {
  source = source.replace(
    /import\s*{([^}]+)}\s*from\s*["']react-native["'];/,
    (m, imports) => {
      if (imports.includes("Pressable")) return m;
      return `import { Pressable,${imports} } from "react-native";`;
    }
  );
}

if (!source.includes("const router = useRouter();")) {
  source = source.replace(
    /(export default function[^{]+{)/,
    `$1\n  const router = useRouter();`
  );
}

const button = `
      <Pressable
        onPress={() => router.push("${route}")}
        style={{
          minHeight: 52,
          borderRadius: 14,
          backgroundColor: "rgba(0,208,132,0.14)",
          borderWidth: 1,
          borderColor: "rgba(0,208,132,0.35)",
          justifyContent: "center",
          paddingHorizontal: 16,
          marginTop: 10,
          marginBottom: 10
        }}
      >
        <Text style={{ color: "#FFFFFF", fontWeight: "900", fontSize: 15 }}>
          MauriCore Governance
        </Text>
      </Pressable>
`;

let inserted = false;
const backHome = source.indexOf("Back Home");

if (backHome !== -1) {
  const before = source.lastIndexOf("<", backHome);
  if (before !== -1) {
    source = source.slice(0, before) + button + "\n" + source.slice(before);
    inserted = true;
  }
}

if (!inserted) {
  const lastScrollClose = source.lastIndexOf("</ScrollView>");
  if (lastScrollClose !== -1) {
    source = source.slice(0, lastScrollClose) + button + "\n" + source.slice(lastScrollClose);
    inserted = true;
  }
}

if (!inserted) {
  console.log(`Could not safely insert into ${path.relative(root, target)}. Backup kept.`);
  process.exit(0);
}

fs.writeFileSync(target, source);
console.log(`Injected MauriCore Governance button into ${path.relative(root, target)}`);
console.log(`Backup: ${path.relative(root, backup)}`);
NODE

echo ""
echo "4. Verify correct file placement"

FILES=(
  "$ROOT/app/mauricore-governance.tsx"
  "$ROOT/src/mauricore/dashboard/MauriCoreGovernanceScreen.tsx"
  "$ROOT/src/mauricore/dashboard/mauriCoreGovernanceRoute.ts"
)

for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    echo "PASS: ${f#$ROOT/}"
  else
    echo "FAIL: ${f#$ROOT/}"
    exit 1
  fi
done

echo ""
echo "5. Run TypeScript check"
set +e
npm run mauricore:check > "$REPORTS/typescript-$STAMP.log" 2>&1
TS_STATUS=$?
set -e
cat "$REPORTS/typescript-$STAMP.log"
if [ "$TS_STATUS" -ne 0 ]; then
  echo "ERROR: TypeScript check failed."
  exit 1
fi

echo ""
echo "6. Run MauriCore smoke test"
set +e
npm run mauricore:test > "$REPORTS/smoke-$STAMP.log" 2>&1
SMOKE_STATUS=$?
set -e
cat "$REPORTS/smoke-$STAMP.log"
if [ "$SMOKE_STATUS" -ne 0 ]; then
  echo "ERROR: MauriCore smoke test failed."
  exit 1
fi

echo ""
echo "7. Run Expo export check"
set +e
npx expo export --platform android --output-dir dist-mauricore-check > "$REPORTS/expo-export-$STAMP.log" 2>&1
EXPORT_STATUS=$?
set -e
cat "$REPORTS/expo-export-$STAMP.log"
if [ "$EXPORT_STATUS" -ne 0 ]; then
  echo "ERROR: Expo export failed."
  exit 1
fi

echo ""
echo "8. Rust check if cargo exists"
if command -v cargo >/dev/null 2>&1; then
  set +e
  npm run mauricore:rust:check > "$REPORTS/rust-$STAMP.log" 2>&1
  RUST_STATUS=$?
  set -e
  cat "$REPORTS/rust-$STAMP.log"
else
  RUST_STATUS=127
  echo "SKIP: cargo not installed in this Replit environment." | tee "$REPORTS/rust-$STAMP.log"
fi

echo ""
echo "9. Optional EAS build gate"
EAS_STATUS="SKIPPED"
if [ "${RUN_EAS_BUILD:-0}" = "1" ]; then
  echo "RUN_EAS_BUILD=1 detected. Starting EAS build."
  set +e
  npx --yes eas-cli@latest build --platform android --profile preview-apk --clear-cache > "$REPORTS/eas-build-$STAMP.log" 2>&1
  EAS_EXIT=$?
  set -e
  cat "$REPORTS/eas-build-$STAMP.log"
  if [ "$EAS_EXIT" -eq 0 ]; then
    EAS_STATUS="PASS"
  else
    EAS_STATUS="FAIL"
    exit 1
  fi
else
  echo "EAS build skipped by default to protect build quota."
  echo "To run it intentionally:"
  echo "  RUN_EAS_BUILD=1 ./mauricore-build-test-all-safe.sh"
fi

echo ""
echo "10. Write final report"

cat > "$REPORT" <<MD
# MauriCore Build + Test All Report

Timestamp: $STAMP

## File Placement

- app/mauricore-governance.tsx
- src/mauricore/dashboard/MauriCoreGovernanceScreen.tsx
- src/mauricore/dashboard/mauriCoreGovernanceRoute.ts

## Results

- TypeScript: PASS
- MauriCore smoke test: PASS
- Expo export: PASS
- Rust/Cargo: $([ "$RUST_STATUS" = "127" ] && echo "SKIPPED - cargo not installed" || echo "CHECKED")
- EAS build: $EAS_STATUS

## Route

/mauricore-governance

## Notes

Real BLE/native proof still requires APK installed on physical devices.
Replit simulation/export must not be treated as live BLE proof.
MD

cat "$REPORT"

echo ""
echo "============================================================"
echo "MAURICORE BUILD + WIRE + TEST ALL SAFE PASS COMPLETE"
echo "Report:"
echo "  ${REPORT#$ROOT/}"
echo ""
echo "Open route:"
echo "  /mauricore-governance"
echo ""
echo "EAS build was skipped unless RUN_EAS_BUILD=1 was set."
echo "============================================================"
