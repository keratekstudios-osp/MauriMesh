#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "REPAIR 2-HOP PROOF NOTIFICATIONS — NO EXTERNAL DEPENDENCY"
echo "Fixes failed expo-notifications install path"
echo "Uses in-app banner + Alert popup stage notifications"
echo "============================================================"
echo ""

ROOT="$(pwd)"
SCREEN="$ROOT/app/proof-2-hop.tsx"
BACKUP="$ROOT/backup-before-2-hop-proof-notification-repair-$(date +%Y%m%d-%H%M%S)"

if [ ! -f "$SCREEN" ]; then
  echo "ERROR: app/proof-2-hop.tsx not found."
  exit 1
fi

mkdir -p "$BACKUP"
cp "$SCREEN" "$BACKUP/proof-2-hop.tsx"

cat > "$SCREEN" <<'TSX'
import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  Alert,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";

type Role = "A06_SENDER" | "S10_RELAY";
type StepState = "locked" | "ready" | "active" | "done" | "ack";

type ProofLog = {
  time: string;
  event: string;
  packetId: string;
  deviceRole: Role;
  truth: string;
};

const COLORS = {
  bg: "#020403",
  panel: "rgba(2,12,8,0.88)",
  border: "rgba(34,197,94,0.28)",
  white: "#FFFFFF",
  muted: "rgba(255,255,255,0.68)",
  locked: "#334155",
  ready: "#F59E0B",
  active: "#38BDF8",
  done: "#22C55E",
  ack: "#A855F7",
  danger: "#EF4444",
  greenstone: "#00D084",
};

function makePacketId() {
  const now = Date.now().toString(36).toUpperCase();
  const rand = Math.random().toString(36).slice(2, 8).toUpperCase();
  return `MM-${now}-${rand}`;
}

function nowStamp() {
  return new Date().toISOString();
}

function stateColor(state: StepState) {
  if (state === "ready") return COLORS.ready;
  if (state === "active") return COLORS.active;
  if (state === "done") return COLORS.done;
  if (state === "ack") return COLORS.ack;
  return COLORS.locked;
}

function StepButton({
  label,
  detail,
  state,
  onPress,
}: {
  label: string;
  detail: string;
  state: StepState;
  onPress: () => void;
}) {
  const enabled = state !== "locked" && state !== "done" && state !== "active";

  return (
    <Pressable
      disabled={!enabled}
      onPress={onPress}
      style={({ pressed }) => [
        styles.stepButton,
        {
          borderColor: stateColor(state),
          backgroundColor:
            state === "locked"
              ? "rgba(51,65,85,0.18)"
              : `${stateColor(state)}26`,
          shadowColor: stateColor(state),
          elevation: state === "ready" || state === "ack" ? 10 : 2,
          opacity: pressed ? 0.72 : state === "locked" ? 0.46 : 1,
          transform: pressed ? [{ scale: 0.985 }] : [{ scale: 1 }],
        },
      ]}
    >
      <View style={[styles.light, { backgroundColor: stateColor(state) }]} />
      <View style={{ flex: 1 }}>
        <Text style={styles.stepLabel}>{label}</Text>
        <Text style={styles.stepDetail}>{detail}</Text>
      </View>
      <Text style={[styles.stepState, { color: stateColor(state) }]}>
        {state.toUpperCase()}
      </Text>
    </Pressable>
  );
}

export default function TwoHopProofScreen() {
  const [role, setRole] = useState<Role>("A06_SENDER");
  const [packetId, setPacketId] = useState("");
  const [aSent, setASent] = useState(false);
  const [bRx, setBRx] = useState(false);
  const [bAck, setBAck] = useState(false);
  const [aAckReceived, setAAckReceived] = useState(false);
  const [logs, setLogs] = useState<ProofLog[]>([]);
  const [stageBanner, setStageBanner] = useState(
    "Select A06 or S10 role. The next button will light amber when ready."
  );

  const lastStageRef = useRef("");

  const roleLabel =
    role === "A06_SENDER"
      ? "PHONE A · Samsung A06 · Sender"
      : "PHONE B · Samsung S10 · Relay / ACK Return";

  const proofComplete =
    role === "A06_SENDER" ? aSent && aAckReceived : bRx && bAck;

  const notifyStage = (stageKey: string, title: string, body: string) => {
    if (lastStageRef.current === stageKey) return;
    lastStageRef.current = stageKey;
    setStageBanner(body);

    // Dependency-free notification. Works immediately inside APK/app session.
    Alert.alert(title, body);
  };

  const addLog = (event: string, truth: string) => {
    setLogs((prev) => [
      {
        time: nowStamp(),
        event,
        packetId: packetId || "NO_PACKET_ID",
        deviceRole: role,
        truth,
      },
      ...prev,
    ]);
  };

  const resetProof = () => {
    setPacketId("");
    setASent(false);
    setBRx(false);
    setBAck(false);
    setAAckReceived(false);
    setLogs([]);
    lastStageRef.current = "";
    setStageBanner(
      "Proof reset. Select A06 or S10 role. The next button will light amber when ready."
    );
  };

  const switchRole = (nextRole: Role) => {
    setRole(nextRole);
    resetProof();
  };

  const aStates = useMemo(() => {
    return {
      generate: packetId ? ("done" as StepState) : ("ready" as StepState),
      send: !packetId ? "locked" : aSent ? "done" : "ready",
      wait: !aSent ? "locked" : aAckReceived ? "done" : "active",
      ack: !aSent ? "locked" : aAckReceived ? "done" : "ack",
    };
  }, [packetId, aSent, aAckReceived]);

  const bStates = useMemo(() => {
    return {
      confirm: packetId ? ("done" as StepState) : ("ready" as StepState),
      rx: !packetId ? "locked" : bRx ? "done" : "ready",
      relayAck: !bRx ? "locked" : bAck ? "done" : "ack",
      complete: bRx && bAck ? "done" : "locked",
    };
  }, [packetId, bRx, bAck]);

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

  const copyBlock = logs
    .slice()
    .reverse()
    .map(
      (l) =>
        `${l.time} | ${l.deviceRole} | ${l.event} | packetId=${l.packetId} | ${l.truth}`
    )
    .join("\n");

  return (
    <ScrollView style={styles.safe} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <Text style={styles.kicker}>MAURIMESH PROOF MODE</Text>
        <Text style={styles.title}>2-Hop Lit Button Proof</Text>
        <Text style={styles.subtitle}>
          Goal: PHONE A06 sends packet to PHONE S10. S10 receives, then returns
          ACK back to A06. PASS only when the same packetId appears across TX,
          RX, and ACK proof logs.
        </Text>
      </View>

      <View style={styles.stageBanner}>
        <Text style={styles.stageBannerTitle}>NEXT STAGE READY</Text>
        <Text style={styles.stageBannerText}>{stageBanner}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.sectionTitle}>Choose this phone role</Text>

        <View style={styles.roleRow}>
          <Pressable
            onPress={() => switchRole("A06_SENDER")}
            style={[
              styles.roleButton,
              role === "A06_SENDER" && styles.roleSelected,
            ]}
          >
            <Text style={styles.roleTitle}>A06</Text>
            <Text style={styles.roleSub}>PHONE A / Sender</Text>
          </Pressable>

          <Pressable
            onPress={() => switchRole("S10_RELAY")}
            style={[
              styles.roleButton,
              role === "S10_RELAY" && styles.roleSelected,
            ]}
          >
            <Text style={styles.roleTitle}>S10</Text>
            <Text style={styles.roleSub}>PHONE B / Relay ACK</Text>
          </Pressable>
        </View>

        <View style={styles.roleBadge}>
          <Text style={styles.roleBadgeText}>{roleLabel}</Text>
        </View>
      </View>

      <View style={styles.card}>
        <Text style={styles.sectionTitle}>Packet proof identity</Text>
        <Text style={styles.muted}>
          Use the same packetId on both phones. A06 generates it. S10 must enter
          the same ID before RX / ACK.
        </Text>

        <TextInput
          value={packetId}
          onChangeText={(text) => setPacketId(text.trim().toUpperCase())}
          placeholder="PACKET ID"
          placeholderTextColor="rgba(255,255,255,0.38)"
          autoCapitalize="characters"
          style={styles.input}
        />

        <Text style={styles.packetText}>
          {packetId || "No packetId generated yet"}
        </Text>
      </View>

      {role === "A06_SENDER" ? (
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>A06 sender sequence</Text>

          <StepButton
            label="1. Generate Packet ID"
            detail="Amber means ready. Press this on the A06 only."
            state={aStates.generate}
            onPress={() => {
              const id = makePacketId();
              setPacketId(id);
              addLog("PACKET_ID_GENERATED", "A06 generated proof packetId.");
            }}
          />

          <StepButton
            label="2. Send A06 → S10"
            detail="This lights after packetId exists. Press when ready to start TX."
            state={aStates.send}
            onPress={() => {
              setASent(true);
              addLog(
                "TX_A06_TO_S10",
                "PHONE_A transmitted packet toward PHONE_B."
              );
              Alert.alert(
                "A06 TX marked",
                "Now go to the S10 screen. The RX button should be the next lit button."
              );
            }}
          />

          <StepButton
            label="3. Wait for S10 ACK"
            detail="Blue means A06 is waiting. Do not complete until S10 returns ACK."
            state={aStates.wait}
            onPress={() => {}}
          />

          <StepButton
            label="4. ACK received back on A06"
            detail="Purple means final A06 proof step. Press after S10 relay ACK."
            state={aStates.ack}
            onPress={() => {
              setAAckReceived(true);
              addLog(
                "ACK_BACK_TO_A06",
                "PHONE_A confirmed ACK returned from PHONE_B."
              );
            }}
          />
        </View>
      ) : (
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>S10 relay / ACK sequence</Text>

          <StepButton
            label="1. Confirm Packet ID from A06"
            detail="Enter the same packetId shown on the A06."
            state={bStates.confirm}
            onPress={() => {
              if (!packetId) {
                Alert.alert("Packet ID needed", "Enter the A06 packetId first.");
                return;
              }
              addLog(
                "PACKET_ID_CONFIRMED_ON_S10",
                "PHONE_B confirmed matching packetId."
              );
            }}
          />

          <StepButton
            label="2. RX packet from A06"
            detail="This lights when packetId is entered. Press when S10 receives A06 packet."
            state={bStates.rx}
            onPress={() => {
              setBRx(true);
              addLog(
                "RX_S10_FROM_A06",
                "PHONE_B received packet from PHONE_A."
              );
            }}
          />

          <StepButton
            label="3. Relay ACK S10 → A06"
            detail="Purple means return path is ready. Press to send ACK back to A06."
            state={bStates.relayAck}
            onPress={() => {
              setBAck(true);
              addLog(
                "ACK_RELAY_S10_TO_A06",
                "PHONE_B returned ACK back toward PHONE_A."
              );
              Alert.alert(
                "S10 ACK marked",
                "Now go back to the A06 screen and press ACK received back on A06."
              );
            }}
          />

          <StepButton
            label="4. S10 proof complete"
            detail="Green means S10 RX and ACK return sequence is complete."
            state={bStates.complete}
            onPress={() => {}}
          />
        </View>
      )}

      <View
        style={[
          styles.card,
          {
            borderColor: proofComplete ? COLORS.done : COLORS.border,
            backgroundColor: proofComplete
              ? "rgba(34,197,94,0.12)"
              : COLORS.panel,
          },
        ]}
      >
        <Text style={styles.sectionTitle}>
          {proofComplete ? "LOCAL ROLE COMPLETE" : "PROOF NOT COMPLETE YET"}
        </Text>
        <Text style={styles.muted}>
          Final two-phone PASS still requires both phone logs showing the same
          packetId across TX_A06_TO_S10, RX_S10_FROM_A06, and
          ACK_BACK_TO_A06 / ACK_RELAY_S10_TO_A06.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.sectionTitle}>Copy proof log block</Text>
        <Text style={styles.logBox}>
          {copyBlock || "No proof events yet. Press the lit buttons in order."}
        </Text>

        <Pressable
          onPress={resetProof}
          style={[styles.resetButton, { borderColor: COLORS.danger }]}
        >
          <Text style={[styles.resetText, { color: COLORS.danger }]}>
            Reset Proof Screen
          </Text>
        </Pressable>
      </View>

      <View style={styles.truthCard}>
        <Text style={styles.truthTitle}>Truth rule</Text>
        <Text style={styles.truthText}>
          This screen controls proof order and visual operator timing. It does
          not fake BLE. Real proof is only valid when APK device logs show the
          same packetId moving A06 TX → S10 RX → S10 ACK → A06 ACK.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: COLORS.bg,
  },
  content: {
    padding: 20,
    gap: 16,
    paddingBottom: 48,
  },
  header: {
    gap: 8,
    paddingTop: 10,
  },
  kicker: {
    color: COLORS.greenstone,
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 1.4,
  },
  title: {
    color: COLORS.white,
    fontSize: 34,
    fontWeight: "900",
    letterSpacing: -0.6,
  },
  subtitle: {
    color: COLORS.muted,
    fontSize: 14,
    lineHeight: 21,
  },
  card: {
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
  },
  sectionTitle: {
    color: COLORS.white,
    fontSize: 18,
    fontWeight: "900",
  },
  muted: {
    color: COLORS.muted,
    fontSize: 13,
    lineHeight: 19,
  },
  roleRow: {
    flexDirection: "row",
    gap: 10,
  },
  roleButton: {
    flex: 1,
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: 18,
    padding: 14,
    backgroundColor: "rgba(255,255,255,0.04)",
  },
  roleSelected: {
    borderColor: COLORS.greenstone,
    backgroundColor: "rgba(0,208,132,0.16)",
  },
  roleTitle: {
    color: COLORS.white,
    fontSize: 22,
    fontWeight: "900",
  },
  roleSub: {
    color: COLORS.muted,
    fontSize: 12,
    marginTop: 4,
  },
  roleBadge: {
    borderWidth: 1,
    borderColor: COLORS.greenstone,
    borderRadius: 999,
    paddingHorizontal: 12,
    paddingVertical: 8,
    alignSelf: "flex-start",
    backgroundColor: "rgba(0,208,132,0.10)",
  },
  roleBadgeText: {
    color: COLORS.greenstone,
    fontWeight: "900",
    fontSize: 12,
    letterSpacing: 0.6,
  },
  input: {
    minHeight: 52,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: COLORS.border,
    backgroundColor: "rgba(0,0,0,0.28)",
    color: COLORS.white,
    paddingHorizontal: 14,
    fontSize: 15,
    fontWeight: "800",
  },
  packetText: {
    color: COLORS.greenstone,
    fontWeight: "900",
    fontSize: 14,
    letterSpacing: 0.5,
  },
  stepButton: {
    minHeight: 82,
    borderWidth: 2,
    borderRadius: 20,
    padding: 14,
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    shadowOpacity: 0.8,
    shadowRadius: 10,
  },
  light: {
    width: 18,
    height: 18,
    borderRadius: 9,
  },
  stepLabel: {
    color: COLORS.white,
    fontSize: 15,
    fontWeight: "900",
  },
  stepDetail: {
    color: COLORS.muted,
    fontSize: 12,
    lineHeight: 17,
    marginTop: 3,
  },
  stepState: {
    fontSize: 10,
    fontWeight: "900",
    letterSpacing: 0.7,
  },
  logBox: {
    color: COLORS.white,
    fontSize: 11,
    lineHeight: 17,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.14)",
    borderRadius: 14,
    backgroundColor: "rgba(0,0,0,0.28)",
    padding: 12,
  },
  resetButton: {
    borderWidth: 1,
    borderRadius: 16,
    paddingVertical: 12,
    alignItems: "center",
  },
  resetText: {
    fontWeight: "900",
  },
  truthCard: {
    borderWidth: 1,
    borderColor: "rgba(245,158,11,0.48)",
    borderRadius: 24,
    backgroundColor: "rgba(245,158,11,0.10)",
    padding: 16,
    gap: 8,
  },
  truthTitle: {
    color: COLORS.ready,
    fontSize: 16,
    fontWeight: "900",
  },
  truthText: {
    color: COLORS.white,
    fontSize: 13,
    lineHeight: 20,
  },
});
TSX

echo ""
echo "Checking dashboard button..."
if [ -f "$ROOT/app/dashboard.tsx" ]; then
  if grep -q 'proof-2-hop' "$ROOT/app/dashboard.tsx"; then
    echo "Dashboard already has /proof-2-hop button."
  else
    echo "WARNING: dashboard does not contain /proof-2-hop button."
    echo 'Add this inside the dashboard grid if needed:'
    echo '<MauriButton title="Proof 2-Hop" onPress={() => router.push("/proof-2-hop")} />'
  fi
fi

echo ""
echo "Running TypeScript check..."
npx tsc --noEmit

echo ""
echo "============================================================"
echo "REPAIR COMPLETE"
echo "============================================================"
echo "The proof screen now has:"
echo "- Lit next-stage buttons"
echo "- In-app NEXT STAGE READY banner"
echo "- Alert popup when the next stage is ready"
echo "- No expo-notifications dependency"
echo "- No pnpm install required"
echo ""
echo "Next command:"
echo "npx expo start --clear"
echo ""
