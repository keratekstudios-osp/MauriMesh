import React, { useMemo, useState } from "react";
import {
  SafeAreaView,
  ScrollView,
  View,
  Text,
  Pressable,
  StyleSheet,
  TextInput,
  Platform,
  Share,
} from "react-native";
import { NativeModules } from "react-native";

type Role = "PHONE_A" | "PHONE_B" | "PHONE_C";
type StepStatus = "LOCKED" | "ACTIVE" | "DONE";
type NativeBridgeState = "AVAILABLE" | "UNAVAILABLE";

type Step = {
  id: number;
  role: Role;
  title: string;
  instruction: string;
  marker: string;
  color: string;
  timeoutMs: number;
};

const STEPS: Step[] = [
  {
    id: 1,
    role: "PHONE_A",
    title: "Use Shared Packet ID",
    instruction: "Lock the shared packet ID before any native proof action.",
    marker: "SHARED_PACKET_V9_APPLIED",
    color: "#00E676",
    timeoutMs: 20000,
  },
  {
    id: 2,
    role: "PHONE_A",
    title: "Start BLE Callback Capture",
    instruction: "Start the callback capture on sender before native transport.",
    marker: "BUTTON_PRESS_START_CAPTURE",
    color: "#00E676",
    timeoutMs: 30000,
  },
  {
    id: 3,
    role: "PHONE_B",
    title: "Start Raw Packet Receiver",
    instruction: "Relay phone starts the raw receiver and waits for packet traffic.",
    marker: "BUTTON_PRESS_START_REAL_GATT_RECEIVER",
    color: "#28A8FF",
    timeoutMs: 45000,
  },
  {
    id: 4,
    role: "PHONE_A",
    title: "Send Real GATT Packet",
    instruction: "Sender writes the packet to the target BLE/GATT address.",
    marker: "GATT_CLIENT_WRITE_ATTEMPT",
    color: "#00E676",
    timeoutMs: 30000,
  },
  {
    id: 5,
    role: "PHONE_A",
    title: "Trigger Native GATT Payload",
    instruction: "Trigger the native payload marker for the same packet ID.",
    marker: "GATT_PACKET_PAYLOAD",
    color: "#FFC107",
    timeoutMs: 30000,
  },
  {
    id: 6,
    role: "PHONE_C",
    title: "Confirm Packet Received",
    instruction: "Receiver confirms server-side packet receipt for the same packet ID.",
    marker: "GATT_SERVER_WRITE_RECEIVED",
    color: "#B76CFF",
    timeoutMs: 45000,
  },
  {
    id: 7,
    role: "PHONE_B",
    title: "Relay ACK",
    instruction: "Relay confirms ACK path back toward the sender.",
    marker: "GATT_ACK_RELAY_ATTEMPT",
    color: "#28A8FF",
    timeoutMs: 30000,
  },
  {
    id: 8,
    role: "PHONE_A",
    title: "Save Attempt Into Vault",
    instruction: "Sender saves the completed attempt summary into the vault/report.",
    marker: "BUTTON_PRESS_SAVE_ATTEMPT",
    color: "#00E676",
    timeoutMs: 30000,
  },
];

function roleLabel(role: Role) {
  if (role === "PHONE_A") return "PHONE_A / SENDER";
  if (role === "PHONE_B") return "PHONE_B / RELAY";
  return "PHONE_C / RECEIVER";
}

function roleDescription(role: Role) {
  if (role === "PHONE_A") return "Sender, GATT writer, native payload trigger, vault saver.";
  if (role === "PHONE_B") return "Relay, raw packet receiver setup, ACK relay.";
  return "Final receiver and packet-received confirmation.";
}

function nowIso() {
  return new Date().toISOString();
}

function getNativeBridgeState(): NativeBridgeState {
  const candidates = [
    "MauriMeshBle",
    "MauriMeshNativeBle",
    "MauriMeshGattPacketProof",
    "MauriMeshNativeBlePacketModule",
  ];
  return candidates.some((name) => !!NativeModules?.[name]) ? "AVAILABLE" : "UNAVAILABLE";
}

function buildNativeBridgeNames() {
  return Object.keys(NativeModules || {})
    .filter((k) => k.toLowerCase().includes("mauri") || k.toLowerCase().includes("ble") || k.toLowerCase().includes("gatt"))
    .sort();
}

export default function NativeGattExamGuide() {
  const [role, setRole] = useState<Role | null>(null);
  const [packetId, setPacketId] = useState("MMN-TRANSPORT-0001");
  const [targetAddress, setTargetAddress] = useState("66:66:66:67:71:C7");
  const [stepIndex, setStepIndex] = useState(0);
  const [examStartedAt, setExamStartedAt] = useState<string | null>(null);
  const [stepStartedAt, setStepStartedAt] = useState<number | null>(null);
  const [packetLocked, setPacketLocked] = useState(false);
  const [preflightDone, setPreflightDone] = useState(false);
  const [preflightPassed, setPreflightPassed] = useState(false);
  const [blockedCount, setBlockedCount] = useState(0);
  const [logs, setLogs] = useState<string[]>([]);
  const [nativeBridgeState, setNativeBridgeState] = useState<NativeBridgeState>(getNativeBridgeState());
  const [nativeBridgeNames, setNativeBridgeNames] = useState<string[]>(buildNativeBridgeNames());

  const current = STEPS[stepIndex];
  const isComplete = stepIndex >= STEPS.length;
  const isThisDeviceTurn = !!role && !!current && role === current.role;
  const dimmed = !!role && !isThisDeviceTurn && !isComplete;
  const elapsedMs = stepStartedAt ? Date.now() - stepStartedAt : 0;
  const timeoutWarning = !!current && elapsedMs > current.timeoutMs;

  const progress = useMemo(() => {
    return STEPS.map((_, i) => (i < stepIndex ? "●" : i === stepIndex ? "◉" : "○")).join(" ");
  }, [stepIndex]);

  function addLog(marker: string, status = "OK", extra = "") {
    const line = `${nowIso()} ${marker} packetId=${packetId} role=${role || "UNSET"} status=${status}${extra ? ` ${extra}` : ""}`;
    setLogs((prev) => [line, ...prev].slice(0, 120));
    console.log("MAURIMESH_NATIVE_BLE_GATT_EXAM", line);
  }

  function runPreflight() {
    const bridge = getNativeBridgeState();
    const names = buildNativeBridgeNames();
    setNativeBridgeState(bridge);
    setNativeBridgeNames(names);

    const checks = {
      roleSelected: !!role,
      packetIdSet: packetId.trim().length >= 8,
      platformAndroid: Platform.OS === "android",
      nativeBridgeVisible: bridge === "AVAILABLE",
      targetAddressSet: targetAddress.trim().length >= 8,
    };

    const pass = checks.roleSelected && checks.packetIdSet && checks.platformAndroid && checks.targetAddressSet;
    setPreflightDone(true);
    setPreflightPassed(pass);
    addLog(
      pass ? "PREFLIGHT_PASS" : "PREFLIGHT_WARN",
      pass ? "READY" : "CHECK_REQUIRED",
      `android=${checks.platformAndroid} packetId=${checks.packetIdSet} target=${checks.targetAddressSet} nativeBridge=${bridge}`
    );
  }

  function startExamIfNeeded() {
    if (!examStartedAt) setExamStartedAt(nowIso());
    if (!stepStartedAt) setStepStartedAt(Date.now());
  }

  function pressStep() {
    if (!role || isComplete || !current) return;

    startExamIfNeeded();

    if (role !== current.role) {
      setBlockedCount((n) => n + 1);
      addLog("WRONG_DEVICE_BLOCKED", `WAIT_FOR_${current.role}`, `attemptedRole=${role} requiredRole=${current.role}`);
      return;
    }

    if (current.id > 1 && !packetLocked) {
      setBlockedCount((n) => n + 1);
      addLog("PACKET_ID_NOT_LOCKED_BLOCKED", "LOCK_PACKET_FIRST");
      return;
    }

    if (current.id === 1) {
      setPacketLocked(true);
      addLog("PACKET_ID_LOCKED", "READ_ONLY_UNTIL_RESET");
    }

    addLog(current.marker, "STEP_ACCEPTED", `step=${current.id}`);
    const nextIndex = Math.min(stepIndex + 1, STEPS.length);
    setStepIndex(nextIndex);
    setStepStartedAt(nextIndex < STEPS.length ? Date.now() : null);
  }

  function resetExam() {
    setStepIndex(0);
    setExamStartedAt(null);
    setStepStartedAt(null);
    setPacketLocked(false);
    setPreflightDone(false);
    setPreflightPassed(false);
    setBlockedCount(0);
    setLogs([]);
    addLog("EXAM_RESET", "RESET");
  }

  function buildReport() {
    return [
      "MAURIMESH NATIVE BLE/GATT 3-DEVICE EXAM REPORT",
      "================================================",
      `createdAt=${nowIso()}`,
      `packetId=${packetId}`,
      `targetAddress=${targetAddress}`,
      `deviceRole=${role || "UNSET"}`,
      `examStartedAt=${examStartedAt || "NOT_STARTED"}`,
      `completedSteps=${Math.min(stepIndex, STEPS.length)}/${STEPS.length}`,
      `packetLocked=${packetLocked}`,
      `preflightDone=${preflightDone}`,
      `preflightPassed=${preflightPassed}`,
      `nativeBridgeState=${nativeBridgeState}`,
      `nativeBridgeNames=${nativeBridgeNames.join(",") || "NONE_VISIBLE"}`,
      `blockedWrongDeviceOrOrderCount=${blockedCount}`,
      "",
      "STEP PLAN",
      ...STEPS.map((s, i) => `${s.id}. ${s.role} ${s.title} marker=${s.marker} status=${i < stepIndex ? "DONE" : i === stepIndex ? "CURRENT" : "LOCKED"}`),
      "",
      "EVENT LOG",
      ...logs,
      "",
      "PASS RULE",
      "Final native packet-bound PASS still requires same packetId in native physical GATT logs:",
      "GATT_PACKET_PAYLOAD",
      "GATT_CLIENT_WRITE_ATTEMPT",
      "GATT_SERVER_WRITE_RECEIVED",
    ].join("\n");
  }

  async function exportReport() {
    const report = buildReport();
    addLog("EXPORT_EXAM_REPORT", "REQUESTED");
    try {
      await Share.share({ message: report });
    } catch {
      console.log(report);
    }
  }

  if (!role) {
    return (
      <SafeAreaView style={styles.safe}>
        <View style={styles.roleWrap}>
          <Text style={styles.brand}>MAURIMESH</Text>
          <Text style={styles.title}>3-Device Truth Gate Exam</Text>
          <Text style={styles.sub}>
            Choose this phone’s allocated role before starting. The exam locks buttons by role, order, packet ID, and proof step.
          </Text>

          {(["PHONE_A", "PHONE_B", "PHONE_C"] as Role[]).map((r) => (
            <Pressable key={r} style={styles.roleBtn} onPress={() => setRole(r)}>
              <Text style={styles.roleTitle}>{roleLabel(r)}</Text>
              <Text style={styles.roleSub}>{roleDescription(r)}</Text>
            </Pressable>
          ))}
        </View>
      </SafeAreaView>
    );
  }

  const activeColor = isComplete ? "#00E676" : current?.color || "#00E676";

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={styles.wrap}>
        <View style={[styles.screenLayer, dimmed && styles.dimmed]}>
          <View style={styles.header}>
            <View style={{ flex: 1 }}>
              <Text style={styles.brand}>MAURIMESH</Text>
              <Text style={styles.title}>Native BLE/GATT Truth Gate</Text>
              <Text style={styles.sub}>High Trust Auto Guide — one bright device, one valid button, one ordered proof chain.</Text>
            </View>
            <Pressable style={styles.rolePill} onPress={() => setRole(null)}>
              <Text style={styles.rolePillText}>{role}</Text>
              <Text style={styles.rolePillSub}>CHANGE ROLE</Text>
            </Pressable>
          </View>

          <View style={[styles.turnBanner, { borderColor: activeColor }]}>
            <Text style={[styles.turnText, { color: activeColor }]}>
              {isComplete ? "EXAM COMPLETE" : isThisDeviceTurn ? `${role} TURN — PRESS NOW` : `STANDBY — WAIT FOR ${current.role}`}
            </Text>
            <Text style={styles.sub}>
              {isComplete ? "Export the report and verify native GATT markers." : current.instruction}
            </Text>
          </View>

          <View style={styles.card}>
            <Text style={styles.cardTitle}>Preflight Check</Text>
            <View style={styles.row}>
              <Text style={styles.check}>Role selected</Text>
              <Text style={styles.pass}>YES</Text>
            </View>
            <View style={styles.row}>
              <Text style={styles.check}>Packet ID set</Text>
              <Text style={packetId.trim().length >= 8 ? styles.pass : styles.fail}>{packetId.trim().length >= 8 ? "YES" : "NO"}</Text>
            </View>
            <View style={styles.row}>
              <Text style={styles.check}>Android platform</Text>
              <Text style={Platform.OS === "android" ? styles.pass : styles.fail}>{Platform.OS === "android" ? "YES" : Platform.OS.toUpperCase()}</Text>
            </View>
            <View style={styles.row}>
              <Text style={styles.check}>Native bridge visible</Text>
              <Text style={nativeBridgeState === "AVAILABLE" ? styles.pass : styles.warn}>{nativeBridgeState}</Text>
            </View>
            <Pressable style={styles.secondaryBtn} onPress={runPreflight}>
              <Text style={styles.actionText}>Run Preflight Check</Text>
            </Pressable>
          </View>

          <View style={styles.card}>
            <Text style={styles.cardTitle}>Auto Guide</Text>
            <Text style={styles.big}>
              {isComplete ? "PROOF SEQUENCE COMPLETE" : isThisDeviceTurn ? "YOU NEED TO PRESS" : `WAITING FOR ${current.role}`}
            </Text>
            <Text style={[styles.stepTitle, { color: activeColor }]}>
              {isComplete ? "All guided steps completed" : current.title}
            </Text>
            <Text style={styles.sub}>Current device: {roleLabel(role)}</Text>
            <Text style={styles.sub}>Progress: {progress}</Text>
            {timeoutWarning ? <Text style={styles.warnText}>WAITING TOO LONG: {current.role} must complete this step.</Text> : null}
          </View>

          <View style={styles.card}>
            <Text style={styles.cardTitle}>Shared Packet ID Lock</Text>
            <TextInput
              value={packetId}
              onChangeText={setPacketId}
              style={[styles.input, packetLocked && styles.inputLocked]}
              placeholder="MMN-TRANSPORT-0001"
              placeholderTextColor="#6b7280"
              editable={!packetLocked}
            />
            <Text style={packetLocked ? styles.passSmall : styles.warnSmall}>
              {packetLocked ? "LOCKED: packet ID cannot change until Reset." : "UNLOCKED: Step 1 will lock this packet ID."}
            </Text>

            <Text style={[styles.cardTitle, { marginTop: 14 }]}>Target BLE Address</Text>
            <TextInput
              value={targetAddress}
              onChangeText={setTargetAddress}
              style={styles.input}
              placeholder="AA:BB:CC:DD:EE:FF"
              placeholderTextColor="#6b7280"
              editable={!packetLocked}
            />
          </View>

          {!isComplete && (
            <Pressable
              onPress={pressStep}
              disabled={!isThisDeviceTurn}
              style={[
                styles.actionBtn,
                { borderColor: current.color },
                isThisDeviceTurn ? { backgroundColor: current.color } : styles.lockedBtn,
              ]}
            >
              <Text style={styles.actionText}>{isThisDeviceTurn ? `☀ PRESS: ${current.title}` : `🔒 LOCKED — ${current.role} TURN`}</Text>
              <Text style={styles.actionSub}>{current.marker}</Text>
            </Pressable>
          )}

          <View style={styles.grid}>
            {STEPS.map((s, i) => {
              const status: StepStatus = i < stepIndex ? "DONE" : i === stepIndex ? "ACTIVE" : "LOCKED";
              const mine = s.role === role;
              const highlight = status === "ACTIVE" && mine;
              return (
                <View
                  key={s.id}
                  style={[
                    styles.stepBox,
                    status === "DONE" && styles.doneBox,
                    highlight && { borderColor: s.color, shadowColor: s.color, shadowOpacity: 0.9, shadowRadius: 18 },
                  ]}
                >
                  <Text style={styles.stepNo}>STEP {s.id}</Text>
                  <Text style={[styles.stepRole, { color: s.color }]}>{s.role}</Text>
                  <Text style={styles.stepSmall}>{s.title}</Text>
                  <Text style={styles.stepStatus}>{status}</Text>
                </View>
              );
            })}
          </View>

          <View style={styles.card}>
            <Text style={styles.cardTitle}>Native Module Truth Badge</Text>
            <Text style={nativeBridgeState === "AVAILABLE" ? styles.pass : styles.warn}>
              Native bridge: {nativeBridgeState}
            </Text>
            <Text style={styles.sub}>
              Visible native names: {nativeBridgeNames.length ? nativeBridgeNames.join(", ") : "NONE_VISIBLE"}
            </Text>
          </View>

          <View style={styles.card}>
            <Text style={styles.cardTitle}>Wrong Device / Wrong Order Log</Text>
            <Text style={styles.sub}>Blocked attempts: {blockedCount}</Text>
            <Text style={styles.sub}>Any wrong-phone or wrong-order press is logged as proof the guide is enforcing trust order.</Text>
          </View>

          <Pressable style={styles.reportBtn} onPress={exportReport}>
            <Text style={styles.actionText}>Export Exam Report</Text>
          </Pressable>

          <Pressable style={styles.resetBtn} onPress={resetExam}>
            <Text style={styles.actionText}>Reset Exam</Text>
          </Pressable>

          <View style={styles.card}>
            <Text style={styles.cardTitle}>Live Exam Events</Text>
            {logs.length === 0 ? <Text style={styles.sub}>No events yet.</Text> : null}
            {logs.map((l, i) => (
              <Text key={i} style={styles.log}>{l}</Text>
            ))}
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: "#000" },
  wrap: { padding: 14, paddingBottom: 40 },
  screenLayer: { opacity: 1 },
  dimmed: { opacity: 0.18 },
  roleWrap: { flex: 1, padding: 22, justifyContent: "center", gap: 16, backgroundColor: "#000" },
  brand: { color: "#00E676", fontWeight: "900", letterSpacing: 2 },
  title: { color: "#fff", fontSize: 27, fontWeight: "900", marginTop: 4 },
  sub: { color: "rgba(255,255,255,0.72)", fontSize: 13, lineHeight: 19 },
  header: { flexDirection: "row", justifyContent: "space-between", gap: 12, alignItems: "center" },
  rolePill: { borderWidth: 1, borderColor: "#00E676", borderRadius: 14, padding: 10, alignItems: "center" },
  rolePillText: { color: "#00E676", fontWeight: "900" },
  rolePillSub: { color: "#fff", fontSize: 9 },
  roleBtn: { borderWidth: 1, borderColor: "#00E676", borderRadius: 18, padding: 18, backgroundColor: "rgba(0,230,118,0.08)" },
  roleTitle: { color: "#fff", fontSize: 20, fontWeight: "900" },
  roleSub: { color: "#00E676", marginTop: 5, lineHeight: 20 },
  turnBanner: { borderWidth: 2, borderRadius: 18, padding: 16, marginTop: 14, backgroundColor: "rgba(255,255,255,0.04)" },
  turnText: { fontSize: 20, fontWeight: "900", marginBottom: 6 },
  card: { borderWidth: 1, borderColor: "rgba(0,230,118,0.35)", backgroundColor: "rgba(0,20,10,0.82)", borderRadius: 18, padding: 16, marginTop: 12 },
  cardTitle: { color: "#fff", fontWeight: "900", fontSize: 16, marginBottom: 8 },
  big: { color: "#00E676", fontSize: 18, fontWeight: "900" },
  stepTitle: { fontSize: 24, fontWeight: "900", marginVertical: 6 },
  input: { borderWidth: 1, borderColor: "rgba(255,255,255,0.25)", borderRadius: 10, color: "#fff", padding: 12, fontWeight: "800" },
  inputLocked: { borderColor: "#00E676", backgroundColor: "rgba(0,230,118,0.08)" },
  actionBtn: { marginTop: 14, borderWidth: 2, borderRadius: 16, padding: 16, alignItems: "center", shadowOffset: { width: 0, height: 0 } },
  lockedBtn: { backgroundColor: "rgba(255,255,255,0.05)", borderColor: "rgba(255,255,255,0.14)" },
  secondaryBtn: { marginTop: 12, borderWidth: 1, borderColor: "#38BDF8", backgroundColor: "rgba(56,189,248,0.14)", borderRadius: 14, padding: 14, alignItems: "center" },
  reportBtn: { marginTop: 14, borderWidth: 1, borderColor: "#B76CFF", backgroundColor: "rgba(183,108,255,0.18)", borderRadius: 16, padding: 16, alignItems: "center" },
  resetBtn: { marginTop: 14, borderWidth: 1, borderColor: "#EF4444", backgroundColor: "rgba(239,68,68,0.16)", borderRadius: 16, padding: 16, alignItems: "center" },
  actionText: { color: "#fff", fontWeight: "900", fontSize: 16 },
  actionSub: { color: "rgba(255,255,255,0.75)", fontSize: 11, marginTop: 4 },
  grid: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginTop: 14 },
  stepBox: { width: "48.5%", borderWidth: 1, borderColor: "rgba(255,255,255,0.12)", borderRadius: 14, padding: 12, backgroundColor: "rgba(255,255,255,0.04)" },
  doneBox: { borderColor: "#00E676", backgroundColor: "rgba(0,230,118,0.1)" },
  stepNo: { color: "rgba(255,255,255,0.5)", fontSize: 10, fontWeight: "900" },
  stepRole: { fontWeight: "900", marginTop: 4 },
  stepSmall: { color: "#fff", fontWeight: "800", marginTop: 4 },
  stepStatus: { color: "rgba(255,255,255,0.55)", fontSize: 10, marginTop: 8 },
  row: { flexDirection: "row", justifyContent: "space-between", paddingVertical: 5, borderBottomWidth: 1, borderBottomColor: "rgba(255,255,255,0.06)" },
  check: { color: "rgba(255,255,255,0.76)" },
  pass: { color: "#00E676", fontWeight: "900" },
  fail: { color: "#EF4444", fontWeight: "900" },
  warn: { color: "#FFC107", fontWeight: "900" },
  passSmall: { color: "#00E676", fontSize: 12, marginTop: 8, fontWeight: "800" },
  warnSmall: { color: "#FFC107", fontSize: 12, marginTop: 8, fontWeight: "800" },
  warnText: { color: "#FFC107", fontWeight: "900", marginTop: 10 },
  log: { color: "#38BDF8", fontFamily: "monospace", fontSize: 11, marginTop: 5 },
});
