#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "INSTALL MAURIMESH HYBRID WIFI + BLE MESH"
echo "Adds backup hybrid transport engine: BLE direct, BLE relay,"
echo "store-forward, Wi-Fi local, Wi-Fi Direct-ready, internet gateway."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-hybrid-wifi-ble-mesh-$STAMP"

APP="$ROOT/app"
SRC="$ROOT/src"
MESH="$SRC/maurimesh/hybrid-wifi-ble-mesh"
COMP="$SRC/components"
DOCS="$ROOT/docs"

mkdir -p "$BACKUP" "$APP" "$MESH" "$COMP" "$DOCS"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from Replit project root."
  exit 1
fi

backup_file() {
  local file="$1"
  if [ -f "$ROOT/$file" ]; then
    mkdir -p "$BACKUP/$(dirname "$file")"
    cp "$ROOT/$file" "$BACKUP/$file"
  fi
}

backup_file "app/dashboard.tsx"
backup_file "app/mauricore-ble-runtime.tsx"
backup_file "app/ble-hardware-runtime.tsx"
backup_file "app/device-proof.tsx"
backup_file "app/hybrid-wifi-ble-mesh.tsx"
backup_file "src/lib/uiBackupRoutes.ts"
backup_file "src/maurimesh/hybrid-wifi-ble-mesh/HybridWifiBleMeshTypes.ts"
backup_file "src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts"
backup_file "src/maurimesh/hybrid-wifi-ble-mesh/index.ts"
backup_file "src/components/HybridWifiBleMeshPanel.tsx"

echo "Backup saved: $BACKUP"

# ============================================================
# 1. Types
# ============================================================

cat > "$MESH/HybridWifiBleMeshTypes.ts" <<'TS'
export type HybridTransport =
  | "BLE_DIRECT"
  | "BLE_RELAY"
  | "STORE_FORWARD"
  | "WIFI_LOCAL"
  | "WIFI_DIRECT_READY"
  | "INTERNET_GATEWAY"
  | "OFFLINE_HOLD";

export type HybridLinkState = {
  bleDirectAvailable: boolean;
  bleRelayAvailable: boolean;
  wifiLocalAvailable: boolean;
  wifiDirectAvailable: boolean;
  internetGatewayAvailable: boolean;
  peerTrustScore: number;
  routePressure: "low" | "medium" | "high" | "critical";
  batteryPressure: "low" | "medium" | "high" | "critical";
  thermalPressure: "low" | "medium" | "high" | "critical";
  payloadUrgency: "low" | "normal" | "high" | "emergency";
  payloadSizeBytes: number;
  timestamp: number;
};

export type HybridMeshPacket = {
  packetId: string;
  from: string;
  to: string;
  createdAt: number;
  payloadSizeBytes: number;
  urgency: "low" | "normal" | "high" | "emergency";
  requiresAck: boolean;
};

export type HybridMeshProofEvent = {
  id: string;
  packetId: string;
  stage:
    | "HYBRID_ROUTE_DECISION"
    | "HYBRID_FAILOVER"
    | "HYBRID_STORE_FORWARD"
    | "HYBRID_GATEWAY_READY"
    | "HYBRID_OFFLINE_HOLD";
  transport: HybridTransport;
  status: "READY" | "FALLBACK" | "DEFERRED" | "BLOCKED";
  reason: string;
  timestamp: number;
};

export type HybridMeshDecision = {
  selectedTransport: HybridTransport;
  fallbackOrder: HybridTransport[];
  shouldStoreForward: boolean;
  shouldUseGateway: boolean;
  shouldUseRelay: boolean;
  shouldHoldOffline: boolean;
  maxHops: number;
  ttlMs: number;
  retryLimit: number;
  proofEvents: HybridMeshProofEvent[];
  confidence: number;
  reason: string;
  finalTruth: string;
};
TS

# ============================================================
# 2. Backup Hybrid Wi-Fi BLE Mesh Engine
# ============================================================

cat > "$MESH/BackupHybridWifiBleMeshEngine.ts" <<'TS'
import {
  HybridLinkState,
  HybridMeshDecision,
  HybridMeshPacket,
  HybridMeshProofEvent,
  HybridTransport,
} from "./HybridWifiBleMeshTypes";

function pressureRank(value: HybridLinkState["routePressure"]) {
  if (value === "critical") return 4;
  if (value === "high") return 3;
  if (value === "medium") return 2;
  return 1;
}

function createProofEvent(
  packetId: string,
  stage: HybridMeshProofEvent["stage"],
  transport: HybridTransport,
  status: HybridMeshProofEvent["status"],
  reason: string
): HybridMeshProofEvent {
  return {
    id: `${packetId}-${stage}-${transport}-${Date.now()}`,
    packetId,
    stage,
    transport,
    status,
    reason,
    timestamp: Date.now(),
  };
}

export function createHybridFallbackOrder(
  link: HybridLinkState
): HybridTransport[] {
  const order: HybridTransport[] = [];

  const pressure =
    Math.max(
      pressureRank(link.routePressure),
      pressureRank(link.batteryPressure),
      pressureRank(link.thermalPressure)
    );

  if (link.payloadUrgency === "emergency") {
    if (link.bleDirectAvailable) order.push("BLE_DIRECT");
    if (link.bleRelayAvailable) order.push("BLE_RELAY");
    if (link.wifiLocalAvailable) order.push("WIFI_LOCAL");
    if (link.wifiDirectAvailable) order.push("WIFI_DIRECT_READY");
    if (link.internetGatewayAvailable) order.push("INTERNET_GATEWAY");
    order.push("STORE_FORWARD");
    order.push("OFFLINE_HOLD");
    return order;
  }

  if (pressure >= 4) {
    if (link.internetGatewayAvailable) order.push("INTERNET_GATEWAY");
    order.push("STORE_FORWARD");
    order.push("OFFLINE_HOLD");
    return order;
  }

  if (pressure >= 3) {
    if (link.wifiLocalAvailable) order.push("WIFI_LOCAL");
    if (link.internetGatewayAvailable) order.push("INTERNET_GATEWAY");
    if (link.bleDirectAvailable) order.push("BLE_DIRECT");
    order.push("STORE_FORWARD");
    order.push("OFFLINE_HOLD");
    return order;
  }

  if (link.payloadSizeBytes > 128_000) {
    if (link.wifiLocalAvailable) order.push("WIFI_LOCAL");
    if (link.wifiDirectAvailable) order.push("WIFI_DIRECT_READY");
    if (link.internetGatewayAvailable) order.push("INTERNET_GATEWAY");
    if (link.bleRelayAvailable) order.push("BLE_RELAY");
    if (link.bleDirectAvailable) order.push("BLE_DIRECT");
    order.push("STORE_FORWARD");
    order.push("OFFLINE_HOLD");
    return order;
  }

  if (link.bleDirectAvailable) order.push("BLE_DIRECT");
  if (link.bleRelayAvailable) order.push("BLE_RELAY");
  if (link.wifiLocalAvailable) order.push("WIFI_LOCAL");
  if (link.wifiDirectAvailable) order.push("WIFI_DIRECT_READY");
  if (link.internetGatewayAvailable) order.push("INTERNET_GATEWAY");
  order.push("STORE_FORWARD");
  order.push("OFFLINE_HOLD");

  return order;
}

export function decideBackupHybridWifiBleRoute(
  packet: HybridMeshPacket,
  link: HybridLinkState
): HybridMeshDecision {
  const fallbackOrder = createHybridFallbackOrder(link);
  const selectedTransport = fallbackOrder[0] ?? "OFFLINE_HOLD";
  const proofEvents: HybridMeshProofEvent[] = [];

  proofEvents.push(
    createProofEvent(
      packet.packetId,
      "HYBRID_ROUTE_DECISION",
      selectedTransport,
      selectedTransport === "OFFLINE_HOLD" ? "DEFERRED" : "READY",
      `Selected ${selectedTransport} from hybrid BLE/Wi-Fi fallback order.`
    )
  );

  for (const fallback of fallbackOrder.slice(1, 5)) {
    proofEvents.push(
      createProofEvent(
        packet.packetId,
        "HYBRID_FAILOVER",
        fallback,
        "FALLBACK",
        `${fallback} available as backup path if ${selectedTransport} fails.`
      )
    );
  }

  if (fallbackOrder.includes("STORE_FORWARD")) {
    proofEvents.push(
      createProofEvent(
        packet.packetId,
        "HYBRID_STORE_FORWARD",
        "STORE_FORWARD",
        "DEFERRED",
        "Store-forward queue available if no live path is stable."
      )
    );
  }

  if (fallbackOrder.includes("INTERNET_GATEWAY")) {
    proofEvents.push(
      createProofEvent(
        packet.packetId,
        "HYBRID_GATEWAY_READY",
        "INTERNET_GATEWAY",
        "READY",
        "Internet gateway fallback can complete delivery when online path appears."
      )
    );
  }

  if (selectedTransport === "OFFLINE_HOLD") {
    proofEvents.push(
      createProofEvent(
        packet.packetId,
        "HYBRID_OFFLINE_HOLD",
        "OFFLINE_HOLD",
        "BLOCKED",
        "No active route. Packet must remain offline until a peer, relay, Wi-Fi, or gateway appears."
      )
    );
  }

  const criticalPressure =
    link.routePressure === "critical" ||
    link.batteryPressure === "critical" ||
    link.thermalPressure === "critical";

  const highTrust = link.peerTrustScore >= 80;

  const confidence = Math.max(
    35,
    Math.min(
      98,
      55 +
        (highTrust ? 15 : 0) +
        (selectedTransport === "BLE_DIRECT" ? 18 : 0) +
        (selectedTransport === "WIFI_LOCAL" ? 16 : 0) +
        (selectedTransport === "INTERNET_GATEWAY" ? 12 : 0) -
        (criticalPressure ? 25 : 0)
    )
  );

  return {
    selectedTransport,
    fallbackOrder,
    shouldStoreForward:
      selectedTransport === "STORE_FORWARD" ||
      fallbackOrder.includes("STORE_FORWARD"),
    shouldUseGateway: selectedTransport === "INTERNET_GATEWAY",
    shouldUseRelay: selectedTransport === "BLE_RELAY",
    shouldHoldOffline: selectedTransport === "OFFLINE_HOLD",
    maxHops:
      selectedTransport === "BLE_DIRECT"
        ? 1
        : selectedTransport === "BLE_RELAY"
          ? 8
          : selectedTransport === "STORE_FORWARD"
            ? 12
            : 4,
    ttlMs:
      packet.urgency === "emergency"
        ? 120_000
        : selectedTransport === "STORE_FORWARD"
          ? 86_400_000
          : 600_000,
    retryLimit:
      selectedTransport === "OFFLINE_HOLD"
        ? 0
        : criticalPressure
          ? 1
          : packet.urgency === "emergency"
            ? 5
            : 3,
    proofEvents,
    confidence,
    reason:
      `Hybrid Wi-Fi/BLE mesh selected ${selectedTransport}. ` +
      `Fallback order: ${fallbackOrder.join(" -> ")}.`,
    finalTruth:
      "Hybrid Wi-Fi/BLE Mesh is a routing and failover decision layer. It does not prove real radio delivery until an installed APK produces device TX/RX/ACK logs.",
  };
}

export function runHybridWifiBleMeshDemo(): HybridMeshDecision {
  return decideBackupHybridWifiBleRoute(
    {
      packetId: "MM-HYBRID-DEMO-001",
      from: "PHONE-A",
      to: "PHONE-B",
      createdAt: Date.now(),
      payloadSizeBytes: 4096,
      urgency: "normal",
      requiresAck: true,
    },
    {
      bleDirectAvailable: true,
      bleRelayAvailable: true,
      wifiLocalAvailable: true,
      wifiDirectAvailable: false,
      internetGatewayAvailable: true,
      peerTrustScore: 91,
      routePressure: "low",
      batteryPressure: "low",
      thermalPressure: "low",
      payloadUrgency: "normal",
      payloadSizeBytes: 4096,
      timestamp: Date.now(),
    }
  );
}
TS

cat > "$MESH/index.ts" <<'TS'
export * from "./HybridWifiBleMeshTypes";
export * from "./BackupHybridWifiBleMeshEngine";
TS

# ============================================================
# 3. UI panel
# ============================================================

cat > "$COMP/HybridWifiBleMeshPanel.tsx" <<'TSX'
import React, { useMemo, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import {
  decideBackupHybridWifiBleRoute,
  HybridLinkState,
  HybridMeshDecision,
  HybridMeshPacket,
} from "../maurimesh/hybrid-wifi-ble-mesh";
import { mauriTheme } from "../theme/mauriTheme";
import { MauriButton } from "./MauriButton";
import { MauriPanel } from "./MauriPanel";
import { StatusPill } from "./StatusPill";

function toneForTransport(
  transport: string
): "success" | "warning" | "danger" | "info" {
  if (transport === "BLE_DIRECT") return "success";
  if (transport === "BLE_RELAY") return "info";
  if (transport === "STORE_FORWARD") return "warning";
  if (transport === "OFFLINE_HOLD") return "danger";
  return "success";
}

export function HybridWifiBleMeshPanel() {
  const [scenario, setScenario] = useState<"normal" | "pressure" | "offline">("normal");

  const packet: HybridMeshPacket = {
    packetId: `MM-HYBRID-${scenario.toUpperCase()}`,
    from: "PHONE-A",
    to: "PHONE-B",
    createdAt: Date.now(),
    payloadSizeBytes: scenario === "pressure" ? 196000 : 4096,
    urgency: scenario === "offline" ? "normal" : "high",
    requiresAck: true,
  };

  const link: HybridLinkState = useMemo(() => {
    if (scenario === "offline") {
      return {
        bleDirectAvailable: false,
        bleRelayAvailable: false,
        wifiLocalAvailable: false,
        wifiDirectAvailable: false,
        internetGatewayAvailable: false,
        peerTrustScore: 62,
        routePressure: "high",
        batteryPressure: "medium",
        thermalPressure: "medium",
        payloadUrgency: "normal",
        payloadSizeBytes: packet.payloadSizeBytes,
        timestamp: Date.now(),
      };
    }

    if (scenario === "pressure") {
      return {
        bleDirectAvailable: true,
        bleRelayAvailable: true,
        wifiLocalAvailable: true,
        wifiDirectAvailable: true,
        internetGatewayAvailable: true,
        peerTrustScore: 86,
        routePressure: "high",
        batteryPressure: "high",
        thermalPressure: "high",
        payloadUrgency: "high",
        payloadSizeBytes: packet.payloadSizeBytes,
        timestamp: Date.now(),
      };
    }

    return {
      bleDirectAvailable: true,
      bleRelayAvailable: true,
      wifiLocalAvailable: true,
      wifiDirectAvailable: false,
      internetGatewayAvailable: true,
      peerTrustScore: 91,
      routePressure: "low",
      batteryPressure: "low",
      thermalPressure: "low",
      payloadUrgency: "high",
      payloadSizeBytes: packet.payloadSizeBytes,
      timestamp: Date.now(),
    };
  }, [scenario]);

  const decision: HybridMeshDecision = decideBackupHybridWifiBleRoute(packet, link);

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill
          label={decision.selectedTransport}
          tone={toneForTransport(decision.selectedTransport)}
        />
        <Text style={styles.score}>{decision.confidence}%</Text>
        <Text style={styles.title}>Hybrid Wi-Fi + BLE Mesh</Text>
        <Text style={styles.detail}>{decision.reason}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Fallback Order</Text>
        {decision.fallbackOrder.map((item, index) => (
          <Text key={`${item}-${index}`} style={styles.rowText}>
            {index + 1}. {item}
          </Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Runtime Decision</Text>
        <Text style={styles.rowText}>Store-forward: {decision.shouldStoreForward ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Use gateway: {decision.shouldUseGateway ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Use relay: {decision.shouldUseRelay ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Offline hold: {decision.shouldHoldOffline ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Max hops: {decision.maxHops}</Text>
        <Text style={styles.rowText}>TTL: {decision.ttlMs} ms</Text>
        <Text style={styles.rowText}>Retry limit: {decision.retryLimit}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Proof Events</Text>
        {decision.proofEvents.slice(0, 7).map((event) => (
          <Text key={event.id} style={styles.bullet}>
            • {event.stage} · {event.transport} · {event.status}
          </Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Scenario</Text>
        <Text style={styles.detail}>
          Switch scenarios to test route failover: normal mesh, high hardware/network pressure, or full offline hold.
        </Text>
        <View style={styles.buttons}>
          <MauriButton title="Normal" onPress={() => setScenario("normal")} />
          <MauriButton title="Pressure" onPress={() => setScenario("pressure")} />
          <MauriButton title="Offline" onPress={() => setScenario("offline")} />
        </View>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Final Truth</Text>
        <Text style={styles.detail}>{decision.finalTruth}</Text>
      </MauriPanel>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    gap: mauriTheme.spacing.md,
  },
  score: {
    color: mauriTheme.colors.greenstone,
    fontSize: 54,
    fontWeight: "900",
    letterSpacing: -1.3,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 24,
    fontWeight: "900",
  },
  sectionTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  detail: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  rowText: {
    color: mauriTheme.colors.white,
    lineHeight: 22,
  },
  bullet: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
  buttons: {
    gap: mauriTheme.spacing.sm,
    marginTop: mauriTheme.spacing.md,
  },
});
TSX

# ============================================================
# 4. Route screen
# ============================================================

cat > "$APP/hybrid-wifi-ble-mesh.tsx" <<'TSX'
import React from "react";
import { AppShell } from "../src/components/AppShell";
import { HybridWifiBleMeshPanel } from "../src/components/HybridWifiBleMeshPanel";
import { MauriPageHeader } from "../src/components/MauriPageHeader";

export default function HybridWifiBleMeshScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="HYBRID MESH"
        title="Hybrid Wi-Fi + BLE Mesh"
        subtitle="Backup transport routing across BLE direct, BLE relay, store-forward, Wi-Fi local, Wi-Fi Direct-ready, and internet gateway fallback."
        tone="info"
      />
      <HybridWifiBleMeshPanel />
    </AppShell>
  );
}
TSX

# ============================================================
# 5. Patch existing screens + route registry + dashboard
# ============================================================

node <<'NODE'
const fs = require("fs");

function patchScreen(file, importLine, componentLine) {
  if (!fs.existsSync(file)) return;
  let src = fs.readFileSync(file, "utf8");

  if (!src.includes("HybridWifiBleMeshPanel")) {
    src = `${importLine}\n${src}`;

    if (src.includes("</AppShell>")) {
      src = src.replace("</AppShell>", `      ${componentLine}\n    </AppShell>`);
    } else {
      src += `\n// Hybrid Wi-Fi BLE Mesh available at /hybrid-wifi-ble-mesh\n`;
    }

    fs.writeFileSync(file, src);
  }
}

patchScreen(
  "app/mauricore-ble-runtime.tsx",
  'import { HybridWifiBleMeshPanel } from "../src/components/HybridWifiBleMeshPanel";',
  "<HybridWifiBleMeshPanel />"
);

patchScreen(
  "app/ble-hardware-runtime.tsx",
  'import { HybridWifiBleMeshPanel } from "../src/components/HybridWifiBleMeshPanel";',
  "<HybridWifiBleMeshPanel />"
);

patchScreen(
  "app/device-proof.tsx",
  'import { HybridWifiBleMeshPanel } from "../src/components/HybridWifiBleMeshPanel";',
  "<HybridWifiBleMeshPanel />"
);

const registry = "src/lib/uiBackupRoutes.ts";
if (fs.existsSync(registry)) {
  let src = fs.readFileSync(registry, "utf8");

  if (!src.includes('"hybridWifiBleMesh"')) {
    if (src.includes('| "bleHardwareRuntime";')) {
      src = src.replace(
        '| "bleHardwareRuntime";',
        '| "bleHardwareRuntime"\n  | "hybridWifiBleMesh";'
      );
    } else {
      src = src.replace(/;\s*$/, '\n  | "hybridWifiBleMesh";');
    }
  }

  if (!src.includes('route: "/hybrid-wifi-ble-mesh"')) {
    const entry = `,
  {
    key: "hybridWifiBleMesh",
    title: "Hybrid Wi-Fi BLE Mesh",
    route: "/hybrid-wifi-ble-mesh",
    fallbackRoute: "/ble-hardware-runtime",
    critical: true,
    purpose: "Backup hybrid transport routing across BLE, relay, store-forward, Wi-Fi and gateway paths.",
  }`;
    src = src.replace(/\n\];/, `${entry}\n];`);
  }

  fs.writeFileSync(registry, src);
}

const dashboard = "app/dashboard.tsx";
if (fs.existsSync(dashboard)) {
  let src = fs.readFileSync(dashboard, "utf8");

  if (!src.includes("/hybrid-wifi-ble-mesh")) {
    const button = `          <MauriButton title="Hybrid Wi-Fi BLE Mesh" onPress={() => router.push("/hybrid-wifi-ble-mesh")} />`;

    if (src.includes('<MauriButton title="BLE Hardware Runtime"')) {
      src = src.replace(
        /(\s*<MauriButton title="BLE Hardware Runtime"[\s\S]*?\/>)/,
        `$1\n${button}`
      );
    } else if (src.includes("</AppShell>")) {
      src = src.replace("</AppShell>", `      ${button}\n    </AppShell>`);
    } else {
      src += `\n// Hybrid Wi-Fi BLE Mesh route marker: /hybrid-wifi-ble-mesh\n`;
    }

    fs.writeFileSync(dashboard, src);
  }
}
NODE

# ============================================================
# 6. Checker
# ============================================================

cat > "$ROOT/check-maurimesh-hybrid-wifi-ble-mesh.sh" <<'CHECK'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-hybrid-wifi-ble-mesh-report-$STAMP.md"
LATEST="$DOCS/maurimesh-hybrid-wifi-ble-mesh-report-latest.md"

PASS=0
FAIL=0
WARN=0

line(){ echo "$1" | tee -a "$REPORT"; }
pass(){ PASS=$((PASS+1)); line "- [x] $1"; }
fail(){ FAIL=$((FAIL+1)); line "- [ ] MISSING: $1"; }
warn(){ WARN=$((WARN+1)); line "- [!] PARTIAL: $1"; }

has_file(){ [ -f "$ROOT/$1" ]; }
has_text(){ [ -f "$ROOT/$1" ] && grep -Fq "$2" "$ROOT/$1"; }

: > "$REPORT"

line "# MauriMesh Hybrid Wi-Fi BLE Mesh Report"
line ""
line "Generated: $STAMP"
line ""

line "## Files"
for file in \
  "src/maurimesh/hybrid-wifi-ble-mesh/HybridWifiBleMeshTypes.ts" \
  "src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts" \
  "src/maurimesh/hybrid-wifi-ble-mesh/index.ts" \
  "src/components/HybridWifiBleMeshPanel.tsx" \
  "app/hybrid-wifi-ble-mesh.tsx"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## Transport Capabilities"
for token in \
  "BLE_DIRECT" \
  "BLE_RELAY" \
  "STORE_FORWARD" \
  "WIFI_LOCAL" \
  "WIFI_DIRECT_READY" \
  "INTERNET_GATEWAY" \
  "OFFLINE_HOLD" \
  "createHybridFallbackOrder" \
  "decideBackupHybridWifiBleRoute" \
  "HYBRID_ROUTE_DECISION" \
  "HYBRID_FAILOVER" \
  "HYBRID_STORE_FORWARD" \
  "HYBRID_GATEWAY_READY"
do
  if grep -R "$token" "$ROOT/src/maurimesh/hybrid-wifi-ble-mesh" "$ROOT/src/components/HybridWifiBleMeshPanel.tsx" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route Wiring"
if has_text "app/dashboard.tsx" "/hybrid-wifi-ble-mesh"; then pass "Dashboard has /hybrid-wifi-ble-mesh"; else fail "Dashboard missing /hybrid-wifi-ble-mesh"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/hybrid-wifi-ble-mesh"; then pass "Backup registry has /hybrid-wifi-ble-mesh"; else fail "Backup registry missing /hybrid-wifi-ble-mesh"; fi
if has_text "app/hybrid-wifi-ble-mesh.tsx" "HybridWifiBleMeshPanel"; then pass "Screen uses HybridWifiBleMeshPanel"; else fail "Screen missing panel"; fi

line ""
line "## Embedded Wiring"
if has_file "app/mauricore-ble-runtime.tsx" && has_text "app/mauricore-ble-runtime.tsx" "HybridWifiBleMeshPanel"; then
  pass "MauriCore BLE Runtime includes HybridWifiBleMeshPanel"
else
  warn "MauriCore BLE Runtime embed not confirmed"
fi

if has_file "app/ble-hardware-runtime.tsx" && has_text "app/ble-hardware-runtime.tsx" "HybridWifiBleMeshPanel"; then
  pass "BLE Hardware Runtime includes HybridWifiBleMeshPanel"
else
  warn "BLE Hardware Runtime embed not confirmed"
fi

if has_file "app/device-proof.tsx" && has_text "app/device-proof.tsx" "HybridWifiBleMeshPanel"; then
  pass "Device Proof includes HybridWifiBleMeshPanel"
else
  warn "Device Proof embed not confirmed"
fi

line ""
line "## Truth Protection"
if has_text "src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts" "does not prove real radio delivery"; then
  pass "Truth boundary present"
else
  warn "Truth boundary not confirmed"
fi

line ""
line "## TypeScript"
if npx tsc --noEmit >> "$REPORT" 2>&1; then
  pass "TypeScript passed"
else
  fail "TypeScript failed"
fi

TOTAL=$((PASS + FAIL + WARN))
if [ "$TOTAL" -gt 0 ]; then SCORE=$((PASS * 100 / TOTAL)); else SCORE=0; fi

if [ "$FAIL" -eq 0 ] && [ "$WARN" -eq 0 ]; then
  STATUS="COMPLETE"
elif [ "$FAIL" -eq 0 ]; then
  STATUS="COMPLETE_WITH_WARNINGS"
else
  STATUS="INCOMPLETE"
fi

line ""
line "## Summary"
line ""
line "- Total: $TOTAL"
line "- Complete: $PASS"
line "- Partial: $WARN"
line "- Missing/failed: $FAIL"
line "- Score: $SCORE%"
line "- Status: **$STATUS**"

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "HYBRID WIFI BLE MESH CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
CHECK

chmod +x "$ROOT/check-maurimesh-hybrid-wifi-ble-mesh.sh"

# ============================================================
# 7. Docs
# ============================================================

cat > "$DOCS/maurimesh-hybrid-wifi-ble-mesh-$STAMP.md" <<MD
# MauriMesh Hybrid Wi-Fi BLE Mesh

Generated: $STAMP

## Added

- HybridWifiBleMeshTypes.ts
- BackupHybridWifiBleMeshEngine.ts
- HybridWifiBleMeshPanel.tsx
- /hybrid-wifi-ble-mesh route
- Dashboard button
- Backup route registry entry
- Embedded panel in MauriCore BLE Runtime
- Embedded panel in BLE Hardware Runtime
- Embedded panel in Device Proof
- Checker

## Transport fallback order

- BLE_DIRECT
- BLE_RELAY
- STORE_FORWARD
- WIFI_LOCAL
- WIFI_DIRECT_READY
- INTERNET_GATEWAY
- OFFLINE_HOLD

## Proof events

- HYBRID_ROUTE_DECISION
- HYBRID_FAILOVER
- HYBRID_STORE_FORWARD
- HYBRID_GATEWAY_READY
- HYBRID_OFFLINE_HOLD

## Final Truth

This is a routing and failover decision layer.
Real BLE/Wi-Fi delivery still requires installed APK device proof.
Real BLE delivery requires TX/RX/ACK logcat evidence.
MD

echo ""
echo "Running TypeScript..."
npx tsc --noEmit

echo ""
echo "Running Hybrid Wi-Fi BLE Mesh checker..."
./check-maurimesh-hybrid-wifi-ble-mesh.sh

echo ""
echo "============================================================"
echo "DONE: HYBRID WIFI + BLE MESH INSTALLED"
echo "============================================================"
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Created:"
echo "  src/maurimesh/hybrid-wifi-ble-mesh/HybridWifiBleMeshTypes.ts"
echo "  src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts"
echo "  src/components/HybridWifiBleMeshPanel.tsx"
echo "  app/hybrid-wifi-ble-mesh.tsx"
echo "  check-maurimesh-hybrid-wifi-ble-mesh.sh"
echo ""
echo "Latest report:"
echo "  docs/maurimesh-hybrid-wifi-ble-mesh-report-latest.md"
echo ""
echo "Open route:"
echo "  /hybrid-wifi-ble-mesh"
echo "============================================================"
