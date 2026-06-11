#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "ADD 2-HOP STAGE READY NOTIFICATIONS"
echo "Target: app/proof-2-hop.tsx"
echo "Adds: local notification + in-app stage banner"
echo "============================================================"
echo ""

ROOT="$(pwd)"
SCREEN="$ROOT/app/proof-2-hop.tsx"
BACKUP="$ROOT/backup-before-2-hop-notifications-$(date +%Y%m%d-%H%M%S)"

if [ ! -f "$SCREEN" ]; then
  echo "ERROR: app/proof-2-hop.tsx not found."
  echo "Install the 2-hop lit proof UI first."
  exit 1
fi

mkdir -p "$BACKUP"
cp "$SCREEN" "$BACKUP/proof-2-hop.tsx"

echo "Installing expo-notifications if missing..."
if command -v pnpm >/dev/null 2>&1; then
  pnpm add expo-notifications || true
else
  npm install expo-notifications || true
fi

node <<'NODE'
const fs = require("fs");
const path = "app/proof-2-hop.tsx";
let src = fs.readFileSync(path, "utf8");

if (!src.includes('expo-notifications')) {
  src = src.replace(
    `import React, { useMemo, useState } from "react";`,
    `import React, { useEffect, useMemo, useRef, useState } from "react";
import * as Notifications from "expo-notifications";`
  );
}

if (!src.includes("Notifications.setNotificationHandler")) {
  src = src.replace(
    `const COLORS = {`,
    `Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

const COLORS = {`
  );
}

if (!src.includes("async function requestProofNotificationPermission")) {
  src = src.replace(
    `function nowStamp() {
  return new Date().toISOString();
}`,
    `function nowStamp() {
  return new Date().toISOString();
}

async function requestProofNotificationPermission() {
  const current = await Notifications.getPermissionsAsync();
  if (current.granted || current.ios?.status === Notifications.IosAuthorizationStatus.PROVISIONAL) {
    return true;
  }

  const requested = await Notifications.requestPermissionsAsync();
  return requested.granted || requested.ios?.status === Notifications.IosAuthorizationStatus.PROVISIONAL;
}

async function sendStageReadyNotification(title: string, body: string) {
  const allowed = await requestProofNotificationPermission();
  if (!allowed) return;

  await Notifications.scheduleNotificationAsync({
    content: {
      title,
      body,
      sound: true,
      priority: Notifications.AndroidNotificationPriority.HIGH,
    },
    trigger: null,
  });
}`
  );
}

if (!src.includes("const [stageBanner, setStageBanner]")) {
  src = src.replace(
    `const [logs, setLogs] = useState<ProofLog[]>([]);`,
    `const [logs, setLogs] = useState<ProofLog[]>([]);
  const [stageBanner, setStageBanner] = useState("Select phone role and begin proof.");
  const lastStageRef = useRef("");`
  );
}

if (!src.includes("const notifyStage = async")) {
  src = src.replace(
    `const addLog = (event: string, truth: string) => {`,
    `const notifyStage = async (stageKey: string, title: string, body: string) => {
    if (lastStageRef.current === stageKey) return;
    lastStageRef.current = stageKey;
    setStageBanner(body);
    await sendStageReadyNotification(title, body);
  };

  const addLog = (event: string, truth: string) => {`
  );
}

if (!src.includes("useEffect(() => {") || !src.includes("A06_STAGE_GENERATE")) {
  const anchor = `const copyBlock = logs
    .slice()
    .reverse()
    .map(
      (l) =>
        \`\${l.time} | \${l.deviceRole} | \${l.event} | packetId=\${l.packetId} | \${l.truth}\`
    )
    .join("\\n");`;

  const effect = `useEffect(() => {
    requestProofNotificationPermission().catch(() => {});
  }, []);

  useEffect(() => {
    if (role === "A06_SENDER") {
      if (!packetId) {
        notifyStage(
          "A06_STAGE_GENERATE",
          "MauriMesh A06 Ready",
          "A06: Generate Packet ID is ready. Press the amber-lit button."
        );
        return;
      }

      if (packetId && !aSent) {
        notifyStage(
          "A06_STAGE_SEND",
          "MauriMesh A06 Next Stage",
          "A06: Send A06 to S10 is ready. Press the amber-lit button."
        );
        return;
      }

      if (aSent && !aAckReceived) {
        notifyStage(
          "A06_STAGE_WAIT_ACK",
          "MauriMesh A06 Waiting",
          "A06: Wait for S10 ACK. When S10 sends ACK, press the purple ACK button."
        );
        return;
      }

      if (aSent && aAckReceived) {
        notifyStage(
          "A06_STAGE_COMPLETE",
          "MauriMesh A06 Complete",
          "A06: ACK received. A06 proof role is complete."
        );
        return;
      }
    }

    if (role === "S10_RELAY") {
      if (!packetId) {
        notifyStage(
          "S10_STAGE_ENTER_PACKET",
          "MauriMesh S10 Ready",
          "S10: Enter the A06 packetId. Then the RX button will light."
        );
        return;
      }

      if (packetId && !bRx) {
        notifyStage(
          "S10_STAGE_RX",
          "MauriMesh S10 Next Stage",
          "S10: RX packet from A06 is ready. Press the amber-lit button."
        );
        return;
      }

      if (bRx && !bAck) {
        notifyStage(
          "S10_STAGE_ACK",
          "MauriMesh S10 ACK Ready",
          "S10: Relay ACK back to A06 is ready. Press the purple-lit button."
        );
        return;
      }

      if (bRx && bAck) {
        notifyStage(
          "S10_STAGE_COMPLETE",
          "MauriMesh S10 Complete",
          "S10: RX and ACK relay complete. Return to A06 and confirm ACK received."
        );
        return;
      }
    }
  }, [role, packetId, aSent, aAckReceived, bRx, bAck]);

  ${anchor}`;

  src = src.replace(anchor, effect);
}

if (!src.includes("styles.stageBanner")) {
  src = src.replace(
    `<View style={styles.card}>
        <Text style={styles.sectionTitle}>Choose this phone role</Text>`,
    `<View style={styles.stageBanner}>
        <Text style={styles.stageBannerTitle}>NEXT STAGE READY</Text>
        <Text style={styles.stageBannerText}>{stageBanner}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.sectionTitle}>Choose this phone role</Text>`
  );
}

if (!src.includes("stageBannerTitle:")) {
  src = src.replace(
    `card: {
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: 24,
    backgroundColor: COLORS.panel,
    padding: 16,
    gap: 12,
  },`,
    `card: {
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: 24,
    backgroundColor: COLORS.panel,
    padding: 16,
    gap: 12,
  },
  stageBanner: {
    borderWidth: 2,
    borderColor: COLORS.ready,
    borderRadius: 24,
    backgroundColor: "rgba(245,158,11,0.14)",
    padding: 16,
    gap: 6,
    shadowColor: COLORS.ready,
    shadowOpacity: 0.8,
    shadowRadius: 14,
    elevation: 12,
  },
  stageBannerTitle: {
    color: COLORS.ready,
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 1.2,
  },
  stageBannerText: {
    color: COLORS.white,
    fontSize: 15,
    lineHeight: 21,
    fontWeight: "800",
  },`
  );
}

fs.writeFileSync(path, src);
console.log("Patched app/proof-2-hop.tsx with stage-ready notifications.");
NODE

echo ""
echo "============================================================"
echo "DONE"
echo "============================================================"
echo ""
echo "Now run:"
echo "npx tsc --noEmit"
echo "npx expo start --clear"
echo ""
echo "For APK build, rebuild after this change so Android notification permission is included."
echo ""
