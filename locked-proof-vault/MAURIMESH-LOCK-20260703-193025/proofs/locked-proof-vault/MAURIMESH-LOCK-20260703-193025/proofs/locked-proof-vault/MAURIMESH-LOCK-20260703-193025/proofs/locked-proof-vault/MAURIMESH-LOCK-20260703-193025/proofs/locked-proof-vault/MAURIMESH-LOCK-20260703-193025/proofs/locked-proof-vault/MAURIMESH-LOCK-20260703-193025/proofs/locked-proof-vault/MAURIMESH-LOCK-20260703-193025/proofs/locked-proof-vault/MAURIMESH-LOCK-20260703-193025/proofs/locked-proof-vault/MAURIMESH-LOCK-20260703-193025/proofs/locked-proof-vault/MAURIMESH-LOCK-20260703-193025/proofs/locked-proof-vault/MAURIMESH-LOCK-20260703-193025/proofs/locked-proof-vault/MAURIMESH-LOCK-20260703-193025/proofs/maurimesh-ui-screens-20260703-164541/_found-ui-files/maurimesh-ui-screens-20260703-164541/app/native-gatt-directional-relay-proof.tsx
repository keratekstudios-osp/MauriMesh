import React, { useMemo, useState } from "react";
import {
  NativeModules,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";

const LOG_TAG = "MAURIMESH_NATIVE_GATT_DIRECTIONAL_RELAY";
const FIXED_PACKET = "MMN-DIRECT1-RELAY01";

const stages = [
  "NATIVE_TX_A06",
  "NATIVE_RX_S10_FROM_A06",
  "NATIVE_RELAY_S10_TO_A16",
  "NATIVE_RX_A16_FROM_S10",
  "NATIVE_ACK_A16_TO_S10",
  "NATIVE_ACK_RELAY_S10_TO_A06",
  "NATIVE_ACK_RECEIVED_A06",
  "EXAM_APPROVED",
];

type Role = "A06_SENDER" | "S10_RELAY" | "A16_RECEIVER";

function getNativeModule() {
  return (
    NativeModules.MauriMeshNativeBlePacket ||
    NativeModules.MauriMeshBleModule ||
    null
  );
}

export default function NativeGattDirectionalRelayProof() {
  const [packetId, setPacketId] = useState(FIXED_PACKET);
  const [role, setRole] = useState<Role>("A06_SENDER");
  const [events, setEvents] = useState<string[]>([]);

  const completed = useMemo(() => {
    return stages.filter((stage) =>
      events.some((line) => line.includes(stage) && line.includes(packetId))
    );
  }, [events, packetId]);

  const append = (line: string) => {
    console.warn(line);
    setEvents((prev) => [line, ...prev].slice(0, 80));
  };

  const emitStage = async (stage: string) => {
    const line = `${LOG_TAG} ${stage} packetId=${packetId} role=${role} finalPassClaimed=false`;
    append(line);

    const nativeModule = getNativeModule();
    const fn = nativeModule?.triggerGattPacketPayloadProof;

    if (typeof fn === "function") {
      try {
        const result = await fn(packetId);
        append(
          `${LOG_TAG} NATIVE_TRIGGER_RESULT packetId=${packetId} stage=${stage} result=${JSON.stringify(
            result
          )} finalPassClaimed=false`
        );
      } catch (err: any) {
        append(
          `${LOG_TAG} NATIVE_TRIGGER_ERROR packetId=${packetId} stage=${stage} error=${String(
            err?.message || err
          )} finalPassClaimed=false`
        );
      }
    } else {
      append(
        `${LOG_TAG} NATIVE_TRIGGER_UNAVAILABLE packetId=${packetId} stage=${stage} finalPassClaimed=false`
      );
    }
  };

  const startExam = () => {
    setEvents([]);
    append(`${LOG_TAG} EXAM_STARTED packetId=${packetId} finalPassClaimed=false`);
  };

  const autoForRole = async () => {
    if (role === "A06_SENDER") {
      await emitStage("NATIVE_TX_A06");
      await emitStage("NATIVE_ACK_RECEIVED_A06");
    }

    if (role === "S10_RELAY") {
      await emitStage("NATIVE_RX_S10_FROM_A06");
      await emitStage("NATIVE_RELAY_S10_TO_A16");
      await emitStage("NATIVE_ACK_RELAY_S10_TO_A06");
    }

    if (role === "A16_RECEIVER") {
      await emitStage("NATIVE_RX_A16_FROM_S10");
      await emitStage("NATIVE_ACK_A16_TO_S10");
    }
  };

  const approveIfComplete = () => {
    const missing = stages.filter((s) => !completed.includes(s) && s !== "EXAM_APPROVED");
    if (missing.length === 0) {
      append(`${LOG_TAG} EXAM_APPROVED packetId=${packetId} finalPassClaimed=false`);
    } else {
      append(
        `${LOG_TAG} EXAM_REVIEW_REQUIRED packetId=${packetId} missing=${missing.join(
          ","
        )} finalPassClaimed=false`
      );
    }
  };

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.title}>Native GATT Directional Relay Proof</Text>
      <Text style={styles.body}>
        Target: A06 TX → S10 RX/Relay → A16 RX/ACK → S10 ACK Relay → A06 ACK Received.
        PASS is only lockable from Mac logcat after same packetId markers appear across all three devices.
      </Text>

      <View style={styles.card}>
        <Text style={styles.label}>Packet ID</Text>
        <TextInput
          style={styles.input}
          value={packetId}
          onChangeText={(v) => setPacketId(v.trim().toUpperCase())}
          autoCapitalize="characters"
          autoCorrect={false}
        />

        <Pressable style={styles.button} onPress={() => setPacketId(FIXED_PACKET)}>
          <Text style={styles.buttonText}>Use Fixed Directional Packet</Text>
        </Pressable>

        <Pressable style={styles.button} onPress={startExam}>
          <Text style={styles.buttonText}>Start Directional Relay Exam</Text>
        </Pressable>
      </View>

      <View style={styles.card}>
        <Text style={styles.label}>Role</Text>

        <Pressable style={styles.button} onPress={() => setRole("A06_SENDER")}>
          <Text style={styles.buttonText}>Set Role: A06 Sender</Text>
        </Pressable>

        <Pressable style={styles.button} onPress={() => setRole("S10_RELAY")}>
          <Text style={styles.buttonText}>Set Role: S10 Relay</Text>
        </Pressable>

        <Pressable style={styles.button} onPress={() => setRole("A16_RECEIVER")}>
          <Text style={styles.buttonText}>Set Role: A16 Receiver</Text>
        </Pressable>

        <Text style={styles.mono}>Current role: {role}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.label}>Auto Guided Role Action</Text>
        <Pressable style={styles.primary} onPress={autoForRole}>
          <Text style={styles.buttonText}>AUTO GUIDE: Emit Role Stages + Trigger Native GATT</Text>
        </Pressable>

        <Pressable style={styles.button} onPress={approveIfComplete}>
          <Text style={styles.buttonText}>Check Exam Approval</Text>
        </Pressable>

        <Text style={styles.mono}>Progress: {completed.length}/8</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.label}>Manual Stage Buttons</Text>
        {stages.filter((s) => s !== "EXAM_APPROVED").map((stage) => (
          <Pressable key={stage} style={styles.button} onPress={() => emitStage(stage)}>
            <Text style={styles.buttonText}>{stage}</Text>
          </Pressable>
        ))}
      </View>

      <View style={styles.card}>
        <Text style={styles.label}>Events</Text>
        {events.map((event, idx) => (
          <Text key={`${idx}-${event}`} style={styles.event}>
            {event}
          </Text>
        ))}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 18, gap: 14 },
  title: { color: "white", fontSize: 28, fontWeight: "900" },
  body: { color: "rgba(255,255,255,0.75)", lineHeight: 21 },
  card: {
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.35)",
    backgroundColor: "rgba(2,12,8,0.86)",
    borderRadius: 18,
    padding: 14,
    gap: 10,
  },
  label: { color: "#00D084", fontWeight: "900", fontSize: 16 },
  input: {
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.25)",
    borderRadius: 12,
    padding: 12,
    color: "white",
  },
  button: {
    minHeight: 48,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.45)",
    alignItems: "center",
    justifyContent: "center",
    padding: 10,
  },
  primary: {
    minHeight: 52,
    borderRadius: 14,
    backgroundColor: "#00D084",
    alignItems: "center",
    justifyContent: "center",
    padding: 10,
  },
  buttonText: { color: "white", fontWeight: "900", textAlign: "center" },
  mono: { color: "#38BDF8", fontFamily: "monospace" },
  event: { color: "rgba(255,255,255,0.78)", fontSize: 11, fontFamily: "monospace" },
});
