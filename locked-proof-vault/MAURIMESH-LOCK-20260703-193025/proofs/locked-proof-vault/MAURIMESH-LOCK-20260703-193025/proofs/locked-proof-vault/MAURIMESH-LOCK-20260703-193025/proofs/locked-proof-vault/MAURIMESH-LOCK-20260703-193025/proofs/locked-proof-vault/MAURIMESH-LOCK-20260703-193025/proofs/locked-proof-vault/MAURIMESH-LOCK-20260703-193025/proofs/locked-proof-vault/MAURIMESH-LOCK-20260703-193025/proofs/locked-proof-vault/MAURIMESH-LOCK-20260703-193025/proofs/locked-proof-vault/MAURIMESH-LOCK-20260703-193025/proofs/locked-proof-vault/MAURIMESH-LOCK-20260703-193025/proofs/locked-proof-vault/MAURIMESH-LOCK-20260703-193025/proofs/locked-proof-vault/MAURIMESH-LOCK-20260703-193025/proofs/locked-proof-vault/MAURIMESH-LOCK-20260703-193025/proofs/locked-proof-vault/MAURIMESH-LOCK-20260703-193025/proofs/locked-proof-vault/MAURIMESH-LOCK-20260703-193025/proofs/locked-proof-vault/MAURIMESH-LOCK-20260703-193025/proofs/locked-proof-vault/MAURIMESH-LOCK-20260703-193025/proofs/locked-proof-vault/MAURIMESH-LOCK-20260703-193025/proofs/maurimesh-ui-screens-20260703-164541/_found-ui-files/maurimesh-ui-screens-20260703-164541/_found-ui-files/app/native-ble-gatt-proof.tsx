
/*
  Native BLE/GATT Exam Lights v2
  Required truth rule:
  FINAL PASS only when same packetId has:
  GATT_PACKET_PAYLOAD + GATT_CLIENT_WRITE_ATTEMPT + GATT_SERVER_WRITE_RECEIVED
*/

const EXAM_LIGHTS_V2 = [
  "BUTTON_PRESS_START_CAPTURE",
  "SHARED_PACKET_V9_APPLIED",
  "BUTTON_PRESS_NATIVE_GATT_TRIGGER",
  "nativeMethodEntered=true",
  "GATT_PACKET_PAYLOAD",
  "GATT_CLIENT_WRITE_ATTEMPT",
  "GATT_SERVER_WRITE_RECEIVED",
  "VAULT_SAVE_ATTEMPT saved=true",
];

const NATIVE_GATT_FINAL_RULE_V2 =
  "PASS_READY_TO_LOCK requires same packetId GATT_PACKET_PAYLOAD + GATT_CLIENT_WRITE_ATTEMPT + GATT_SERVER_WRITE_RECEIVED";

import React, { useCallback, useState } from "react";
import {
  NativeModules,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
  TextInput,
} from "react-native";
import {
  sendRawPacketUtf8,
  startRawPacketReceiver,
  getRawPacketReceiverStatus,
} from "../src/maurimesh/ble/rawPacketProofClient";

// MM_GATT_JS_RESOLVER_V8B_BEGIN
const getMauriMeshNativeGattModuleV8B = () => {
  const rn: any = require('react-native');
  const nativeModules: any = rn.NativeModules || NativeModules || {};

  let turboRegistry: any = rn.TurboModuleRegistry || null;
  try {
    turboRegistry = turboRegistry || require('react-native/Libraries/TurboModule/TurboModuleRegistry');
  } catch (err: any) {
    console.log(
      `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_TURBO_REGISTRY_REQUIRE_ERROR | error=${String(err?.message || err)} | finalPassClaimed=false`
    );
  }

  const nativeKeys = Object.keys(nativeModules || {});
  console.log(
    `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_KEYS | NativeModules=${nativeKeys.join(',')} | finalPassClaimed=false`
  );

  const candidateNames = [
    'MauriMeshNativeBlePacket',
    'MauriMeshNativeBlePacketModule',
    'NativeMauriMeshNativeBlePacket',
    'MauriMeshBlePacket',
    'MauriMeshBleModule',
  ];

  for (const name of candidateNames) {
    const mod = nativeModules?.[name];
    if (mod) {
      const methodKeys = Object.keys(mod || {});
      console.log(
        `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_NATIVE_MODULE_FOUND | name=${name} | methods=${methodKeys.join(',')} | finalPassClaimed=false`
      );
      return { name, mod, source: 'NativeModules' };
    }
  }

  if (turboRegistry && typeof turboRegistry.get === 'function') {
    for (const name of candidateNames) {
      try {
        const mod = turboRegistry.get(name);
        if (mod) {
          const methodKeys = Object.keys(mod || {});
          console.log(
            `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_TURBO_MODULE_FOUND | name=${name} | methods=${methodKeys.join(',')} | finalPassClaimed=false`
          );
          return { name, mod, source: 'TurboModuleRegistry.get' };
        }
      } catch (err: any) {
        console.log(
          `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_TURBO_GET_ERROR | name=${name} | error=${String(err?.message || err)} | finalPassClaimed=false`
        );
      }
    }
  }

  const turboProxy = (globalThis as any).__turboModuleProxy;
  if (typeof turboProxy === 'function') {
    for (const name of candidateNames) {
      try {
        const mod = turboProxy(name);
        if (mod) {
          const methodKeys = Object.keys(mod || {});
          console.log(
            `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_GLOBAL_TURBO_PROXY_FOUND | name=${name} | methods=${methodKeys.join(',')} | finalPassClaimed=false`
          );
          return { name, mod, source: 'globalThis.__turboModuleProxy' };
        }
      } catch (err: any) {
        console.log(
          `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_GLOBAL_TURBO_PROXY_ERROR | name=${name} | error=${String(err?.message || err)} | finalPassClaimed=false`
        );
      }
    }
  }

  console.log(
    `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_MODULE_NOT_FOUND | candidates=${candidateNames.join(',')} | NativeModules=${nativeKeys.join(',')} | finalPassClaimed=false`
  );

  return null;
};

const callMauriMeshNativeGattTriggerV8B = async (packetId: string) => {
  const resolved = getMauriMeshNativeGattModuleV8B();

  if (!resolved?.mod) {
    throw new Error(
      'Native GATT trigger unavailable after v8b resolver. NativeModules=' +
        Object.keys((NativeModules as any) || {}).join(',')
    );
  }

  const methodNames = [
    'triggerGattPacketPayloadProof',
    'triggerNativeGattPacketPayload',
    'triggerGattPacketPayload',
    'writeGattPacketProof',
    'sendGattPacketProof',
    'runGattPacketProof',
  ];

  for (const methodName of methodNames) {
    const candidate = resolved.mod?.[methodName];
    if (typeof candidate === 'function') {
      console.log(
        `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_CALLING_METHOD | module=${resolved.name} | source=${resolved.source} | method=${methodName} | packetId=${packetId} | finalPassClaimed=false`
      );
      return await candidate(packetId);
    }
  }

  throw new Error(
    'Native GATT module found but no trigger method. module=' +
      resolved.name +
      ' source=' +
      resolved.source +
      ' methods=' +
      Object.keys(resolved.mod || {}).join(',')
  );
};
// MM_GATT_JS_RESOLVER_V8B_END


const LOG_TAG = "MAURIMESH_NATIVE_BLE_GATT";

type ProofAttempt = {
  packetId: string;
  savedAt: string;
  scanActive: boolean;
  nativeTriggerAttempted: boolean;
  nativeTriggerResult: string;
  nativeTriggerError: string;
  finalPassClaimed: false;
};

type NativeFnRef = {
  moduleName: string;
  methodName: string;
  fn: (...args: unknown[]) => unknown;
};

function nowIso(): string {
  return new Date().toISOString();
}

function createPacketId(): string {
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  const part = (length: number) =>
    Array.from({ length })
      .map(() => alphabet[Math.floor(Math.random() * alphabet.length)])
      .join("");

  return `MMN-${part(6)}-${part(6)}`;
}

function safeError(error: unknown): string {
  if (error instanceof Error) return error.message;
  try {
    return JSON.stringify(error);
  } catch {
    return String(error);
  }
}

function safeJson(value: unknown): string {
  try {
    return JSON.stringify(value);
  } catch {
    return String(value);
  }
}

function listNativeModuleNames(): string {
  try {
    return Object.keys(NativeModules || {}).sort().join(", ");
  } catch {
    return "NativeModules unavailable";
  }
}

function findNativeFunction(
  moduleNames: string[],
  methodNames: string[]
): NativeFnRef | null {
  for (const moduleName of moduleNames) {
    const nativeModule = (getMauriMeshNativeGattModuleV8B()?.mod || (NativeModules as any)[moduleName]) as
      | Record<string, unknown>
      | undefined;

    if (!nativeModule) continue;

    for (const methodName of methodNames) {
      const candidate = nativeModule[methodName];
      if (typeof candidate === "function") {
        return {
          moduleName,
          methodName,
          fn: candidate as (...args: unknown[]) => unknown,
        };
      }
    }
  }

  return null;
}

async function callNativeWithFallbackArgs(
  nativeRef: NativeFnRef,
  packetId: string
): Promise<unknown> {
  const argSets: unknown[][] = [
    [packetId],
    [{ packetId, stage: "BUTTON_PRESS_NATIVE_GATT_TRIGGER", source: "truth-gate" }],
    [packetId, "BUTTON_PRESS_NATIVE_GATT_TRIGGER"],
    ["BUTTON_PRESS_NATIVE_GATT_TRIGGER", packetId],
  ];

  let lastError = "";

  for (const args of argSets) {
    try {
      const result = nativeRef.fn(...args);
      return await Promise.resolve(result);
    } catch (error) {
      lastError = safeError(error);
    }
  }

  throw new Error(
    `${nativeRef.moduleName}.${nativeRef.methodName} exists but all call signatures failed. Last error: ${lastError}`
  );
}

function saveAttemptInMemory(attempt: ProofAttempt): number {
  const key = "__MAURIMESH_NATIVE_GATT_TRUTH_VAULT__";
  const root = globalThis as unknown as Record<string, unknown>;
  const current = Array.isArray(root[key]) ? (root[key] as ProofAttempt[]) : [];
  const next = [attempt, ...current].slice(0, 50);
  root[key] = next;
  return next.length;
}



function appendEvent(line: string) {
  try {
    console.log("[NATIVE_BLE_GATT_PROOF_EVENT]", line);
  } catch {}
}


function GateButton({
  title,
  onPress,
  tone = "primary",
}: {
  title: string;
  onPress: () => void | Promise<void>;
  tone?: "primary" | "secondary" | "danger" | "warning";
}) {
  return (
    <Pressable
      onPress={() => {
        void onPress();
      }}
      style={({ pressed }) => [
        styles.button,
        tone === "primary" && styles.buttonPrimary,
        tone === "secondary" && styles.buttonSecondary,
        tone === "danger" && styles.buttonDanger,
        tone === "warning" && styles.buttonWarning,
        pressed && styles.buttonPressed,
      ]}
    >
      <Text style={styles.buttonText}>{title}</Text>
    </Pressable>
  );
}


const EXAM_LIGHTS = [
  { key: "START_CAPTURE", label: "Start Capture", marker: "BUTTON_PRESS_START_CAPTURE", tone: "blue" },
  { key: "SHARED_PACKET", label: "Shared Packet", marker: "SHARED_PACKET_V9_APPLIED", tone: "green" },
  { key: "NATIVE_TRIGGER", label: "Native Trigger", marker: "BUTTON_PRESS_NATIVE_GATT_TRIGGER", tone: "blue" },
  { key: "NATIVE_METHOD_ENTERED", label: "Native Method Entered", marker: "nativeMethodEntered=true", tone: "green" },
  { key: "GATT_PAYLOAD", label: "GATT Payload", marker: "GATT_PACKET_PAYLOAD", tone: "green" },
  { key: "CLIENT_WRITE", label: "Client Write", marker: "GATT_CLIENT_WRITE_ATTEMPT", tone: "green" },
  { key: "SERVER_RECEIVED", label: "Server Received", marker: "GATT_SERVER_WRITE_RECEIVED", tone: "green" },
  { key: "VAULT_SAVED", label: "Vault Saved", marker: "VAULT_SAVE_ATTEMPT saved=true", tone: "green" },
];

function hasMarker(events: string[], marker: string) {
  return events.some((line) => line.includes(marker));
}

function hasSamePacketMarker(events: string[], packetId: string, marker: string) {
  return events.some((line) => line.includes(packetId) && line.includes(marker));
}

function examLightColor(passed: boolean, tone: string) {
  if (!passed) return "#2b2b2b";
  if (tone === "blue") return "#38BDF8";
  if (tone === "gold") return "#F59E0B";
  return "#22C55E";
}

export default function NativeBleGattProofScreen() {
  const [packetId, setPacketId] = useState<string>(() => createPacketId());
  
  // MM_GATT_SHARED_PACKET_V9_STATE
  const [sharedPacketIdInput, setSharedPacketIdInput] = useState("");
  const [realGattTargetAddress, setRealGattTargetAddress] = useState("");
  const [realGattResult, setRealGattResult] = useState("NOT_STARTED");

const [scanActive, setScanActive] = useState(false);
  const [vaultSaved, setVaultSaved] = useState(false);

  const [lastButtonPressed, setLastButtonPressed] = useState("NONE");
  const [lastButtonPressedAt, setLastButtonPressedAt] = useState("NONE");
  const [buttonPressCount, setButtonPressCount] = useState(0);

  const [nativeTriggerAttempted, setNativeTriggerAttempted] = useState(false);
  const [nativeTriggerResult, setNativeTriggerResult] = useState("NO");
  const [nativeTriggerError, setNativeTriggerError] = useState("");

  const [events, setEvents] = useState<string[]>([
    `${LOG_TAG} SCREEN_READY packetId=initialising platform=${Platform.OS}`,
  ]);

  const appendEvent = useCallback((line: string) => {
    console.warn(line);
    setEvents((prev) => [line, ...prev].slice(0, 80));
  }, []);

  const logButtonPress = useCallback(
    (marker: string, currentPacketId: string, extra = "") => {
      const at = nowIso();
      const line = `${LOG_TAG} ${marker} packetId=${currentPacketId} at=${at}${
        extra ? ` ${extra}` : ""
      }`;

      setLastButtonPressed(marker);
      setLastButtonPressedAt(at);
      setButtonPressCount((count) => count + 1);
      appendEvent(line);
    },
    [appendEvent]
  );

  const tryOptionalNative = useCallback(
    async (label: string, currentPacketId: string, methodNames: string[]) => {
      const nativeRef = findNativeFunction(
        [
          "MauriMeshBleModule",
          "MauriMeshNativeBleModule",
          "MauriMeshNativeBle",
          "MauriMeshGattPacketProof",
          "NativeBleGattModule",
          "MauriMeshGattModule",
        ],
        methodNames
      );

      if (!nativeRef) {
        appendEvent(
          `${LOG_TAG} OPTIONAL_NATIVE_UNAVAILABLE label=${label} packetId=${currentPacketId} nativeModules=${listNativeModuleNames()}`
        );
        return null;
      }

      try {
        const result = await callNativeWithFallbackArgs(nativeRef, currentPacketId);
        appendEvent(
          `${LOG_TAG} OPTIONAL_NATIVE_CALLED label=${label} packetId=${currentPacketId} native=${nativeRef.moduleName}.${nativeRef.methodName} result=${safeJson(
            result
          )}`
        );
        return result;
      } catch (error) {
        appendEvent(
          `${LOG_TAG} OPTIONAL_NATIVE_ERROR label=${label} packetId=${currentPacketId} error=${safeError(
            error
          )}`
        );
        return null;
      }
    },
    [appendEvent]
  );

  const startCapture = useCallback(async () => {
    logButtonPress("BUTTON_PRESS_START_CAPTURE", packetId);
    setScanActive(true);
    setVaultSaved(false);
    setNativeTriggerError("");

    await tryOptionalNative("START_CAPTURE", packetId, [
      "startBleCallbackCapture",
      "startNativeBleGattCapture",
      "startGattCapture",
      "startScan",
      "startBleScan",
    ]);
  }, [logButtonPress, packetId, tryOptionalNative]);

  const stopCapture = useCallback(async () => {
    logButtonPress("BUTTON_PRESS_STOP_CAPTURE", packetId);
    setScanActive(false);

    await tryOptionalNative("STOP_CAPTURE", packetId, [
      "stopBleCallbackCapture",
      "stopNativeBleGattCapture",
      "stopGattCapture",
      "stopScan",
      "stopBleScan",
    ]);
  }, [logButtonPress, packetId, tryOptionalNative]);

  const saveAttempt = useCallback(() => {
    logButtonPress("BUTTON_PRESS_SAVE_ATTEMPT", packetId);

    const attempt: ProofAttempt = {
      packetId,
      savedAt: nowIso(),
      scanActive,
      nativeTriggerAttempted,
      nativeTriggerResult,
      nativeTriggerError,
      finalPassClaimed: false,
    };

    const vaultCount = saveAttemptInMemory(attempt);
    setVaultSaved(true);

    appendEvent(
      `${LOG_TAG} VAULT_SAVE_ATTEMPT packetId=${packetId} saved=true vaultCount=${vaultCount} finalPassClaimed=false`
    );
  }, [
    appendEvent,
    logButtonPress,
    nativeTriggerAttempted,
    nativeTriggerError,
    nativeTriggerResult,
    packetId,
    scanActive,
  ]);

  const resetPacket = useCallback(() => {
    const oldPacketId = packetId;
    const newPacketId = createPacketId();
    const at = nowIso();

    setPacketId(newPacketId);
    setVaultSaved(false);
    setNativeTriggerAttempted(false);
    setNativeTriggerResult("NO");
    setNativeTriggerError("");
    setLastButtonPressed("BUTTON_PRESS_RESET_PACKET");
    setLastButtonPressedAt(at);
    setButtonPressCount((count) => count + 1);

    appendEvent(
      `${LOG_TAG} BUTTON_PRESS_RESET_PACKET oldPacketId=${oldPacketId} newPacketId=${newPacketId} at=${at}`
    );
  }, [appendEvent, packetId]);


  // MM_GATT_SHARED_PACKET_V9_HELPER
  const applySharedPacketIdV9 = useCallback(() => {
    const clean = sharedPacketIdInput.trim().toUpperCase();
    const valid = /^MMN-[A-Z0-9]+-[A-Z0-9]+$/.test(clean);

    if (!valid) {
      const msg = `${LOG_TAG} SHARED_PACKET_V9_INVALID input=${sharedPacketIdInput}`;
      console.warn(msg);
      appendEvent(msg);
      return;
    }

    setPacketId(clean);
    const msg = `${LOG_TAG} SHARED_PACKET_V9_APPLIED packetId=${clean} finalPassClaimed=false`;
    console.warn(msg);
    appendEvent(msg);
  }, [sharedPacketIdInput]);

  const triggerNativeGattPacketPayload = useCallback(async () => {
    logButtonPress("BUTTON_PRESS_NATIVE_GATT_TRIGGER", packetId);

    setNativeTriggerAttempted(true);
    setNativeTriggerResult("ATTEMPTING");
    setNativeTriggerError("");

    const nativeRef = findNativeFunction(
      [
        "MauriMeshBleModule",
        "MauriMeshNativeBleModule",
        "MauriMeshNativeBle",
        "MauriMeshGattPacketProof",
        "NativeBleGattModule",
        "MauriMeshGattModule",
      ],
      [
        "triggerGattPacketPayloadProof",
        "triggerNativeGattPacketPayload",
        "triggerGattPacketPayload",
        "startGattPacketProof",
        "writeGattPacketProof",
        "sendGattPacketProof",
        "triggerPacketProof",
        "runGattPacketProof",
        "emitRawPacketProofEvent",
      ]
    );

    if (!nativeRef) {
      const error = `Native GATT trigger unavailable. NativeModules=${listNativeModuleNames()}`;
      setNativeTriggerResult("UNAVAILABLE");
      setNativeTriggerError(error);
      appendEvent(`${LOG_TAG} NATIVE_GATT_TRIGGER_UNAVAILABLE packetId=${packetId} error=${error}`);
      return;
    }

    try {
      const result = await callNativeWithFallbackArgs(nativeRef, packetId);

      setNativeTriggerResult(`${nativeRef.moduleName}.${nativeRef.methodName}`);
      setNativeTriggerError("");

      appendEvent(
        `${LOG_TAG} NATIVE_GATT_TRIGGER_CALLED packetId=${packetId} native=${nativeRef.moduleName}.${nativeRef.methodName} result=${safeJson(
          result
        )}`
      );

      appendEvent(
        `${LOG_TAG} TRUTH_NOTE packetId=${packetId} buttonTriggerCalled=true finalPassClaimed=false requiredNativeMarkers=GATT_PACKET_PAYLOAD,GATT_CLIENT_WRITE_ATTEMPT,GATT_SERVER_WRITE_RECEIVED`
      );
    } catch (error) {
      const message = safeError(error);
      setNativeTriggerResult("ERROR");
      setNativeTriggerError(message);

      appendEvent(
        `${LOG_TAG} NATIVE_GATT_TRIGGER_ERROR packetId=${packetId} error=${message}`
      );
    }
  }, [appendEvent, logButtonPress, packetId]);


  const startRealGattReceiverFromTruthGate = useCallback(async () => {
    logButtonPress("BUTTON_PRESS_START_REAL_GATT_RECEIVER", packetId);
    try {
      const result = await startRawPacketReceiver();
      setRealGattResult(`RECEIVER_STARTED ${safeJson(result)}`);
      appendEvent(`${LOG_TAG} REAL_GATT_RECEIVER_STARTED packetId=${packetId} result=${safeJson(result)}`);
    } catch (error) {
      const message = safeError(error);
      setRealGattResult(`RECEIVER_ERROR ${message}`);
      appendEvent(`${LOG_TAG} REAL_GATT_RECEIVER_ERROR packetId=${packetId} error=${message}`);
    }
  }, [appendEvent, logButtonPress, packetId]);

  const refreshRealGattReceiverStatusFromTruthGate = useCallback(async () => {
    logButtonPress("BUTTON_PRESS_REFRESH_REAL_GATT_RECEIVER", packetId);
    try {
      const result = await getRawPacketReceiverStatus();
      setRealGattResult(`RECEIVER_STATUS ${safeJson(result)}`);
      appendEvent(`${LOG_TAG} REAL_GATT_RECEIVER_STATUS packetId=${packetId} result=${safeJson(result)}`);
    } catch (error) {
      const message = safeError(error);
      setRealGattResult(`RECEIVER_STATUS_ERROR ${message}`);
      appendEvent(`${LOG_TAG} REAL_GATT_RECEIVER_STATUS_ERROR packetId=${packetId} error=${message}`);
    }
  }, [appendEvent, logButtonPress, packetId]);

  const sendRealGattPacketFromTruthGate = useCallback(async () => {
    const target = realGattTargetAddress.trim();
    logButtonPress("BUTTON_PRESS_SEND_REAL_GATT_PACKET", packetId);

    if (!target) {
      const message = "Target BLE address is required.";
      setRealGattResult(`SEND_BLOCKED ${message}`);
      appendEvent(`${LOG_TAG} REAL_GATT_SEND_BLOCKED packetId=${packetId} reason=${message}`);
      return;
    }

    try {
      const payload = `${packetId}|MAURIMESH_NATIVE_BLE_GATT_REAL_TRANSPORT|${nowIso()}`;
      appendEvent(`${LOG_TAG} GATT_PACKET_PAYLOAD packetId=${packetId} payloadBytes=${payload.length} source=TruthGateRealGattSend`);

      const ok = await sendRawPacketUtf8(target, payload);
      setRealGattResult(`SEND_RESULT ok=${ok} target=${target}`);
      appendEvent(`${LOG_TAG} REAL_GATT_SEND_RESULT packetId=${packetId} target=${target} ok=${ok}`);

      appendEvent(
        `${LOG_TAG} TRUTH_NOTE packetId=${packetId} realTransportSendAttempted=true requiredNativeMarkers=GATT_PACKET_PAYLOAD,GATT_CLIENT_WRITE_ATTEMPT,GATT_SERVER_WRITE_RECEIVED`
      );
    } catch (error) {
      const message = safeError(error);
      setRealGattResult(`SEND_ERROR ${message}`);
      appendEvent(`${LOG_TAG} REAL_GATT_SEND_ERROR packetId=${packetId} target=${target} error=${message}`);
    }
  }, [appendEvent, logButtonPress, packetId, realGattTargetAddress]);

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <Text style={styles.kicker}>MAURIMESH</Text>
        <Text style={styles.title}>Native BLE/GATT Truth Gate</Text>
        <Text style={styles.subtitle}>
          Button repair build. This screen logs every press before native BLE/GATT is called.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Truth State</Text>

        <View style={styles.row}>
          <Text style={styles.label}>Packet ID</Text>
          <Text style={styles.value}>{packetId}</Text>
        </View>

        <View style={styles.row}>
          <Text style={styles.label}>Scan active</Text>
          <Text style={scanActive ? styles.good : styles.warn}>{scanActive ? "YES" : "NO"}</Text>
        </View>

        <View style={styles.row}>
          <Text style={styles.label}>Vault saved this attempt</Text>
          <Text style={vaultSaved ? styles.good : styles.warn}>{vaultSaved ? "YES" : "NO"}</Text>
        </View>

        <View style={styles.row}>
          <Text style={styles.label}>Native trigger attempted</Text>
          <Text style={nativeTriggerAttempted ? styles.good : styles.warn}>
            {nativeTriggerAttempted ? "YES" : "NO"}
          </Text>
        </View>

        <View style={styles.row}>
          <Text style={styles.label}>Native trigger result</Text>
          <Text style={styles.value}>{nativeTriggerResult}</Text>
        </View>

        <View style={styles.row}>
          <Text style={styles.label}>Final packet-bound PASS</Text>
          <Text style={styles.bad}>NOT CLAIMED</Text>
        </View>

        <Text style={styles.truthNote}>
          Final PASS still requires the same packetId inside native physical GATT logs:
          GATT_PACKET_PAYLOAD, GATT_CLIENT_WRITE_ATTEMPT, and GATT_SERVER_WRITE_RECEIVED.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Button Debug Panel</Text>

        <View style={styles.row}>
          <Text style={styles.label}>Last button</Text>
          <Text style={styles.value}>{lastButtonPressed}</Text>
        </View>

        <View style={styles.row}>
          <Text style={styles.label}>Pressed at</Text>
          <Text style={styles.value}>{lastButtonPressedAt}</Text>
        </View>

        <View style={styles.row}>
          <Text style={styles.label}>Press count</Text>
          <Text style={styles.value}>{buttonPressCount}</Text>
        </View>

        {nativeTriggerError ? (
          <Text style={styles.errorBox}>Native trigger error: {nativeTriggerError}</Text>
        ) : null}
      </View>

      <View style={styles.buttonStack}>
        <GateButton title="Start BLE Callback Capture" onPress={startCapture} />
        <GateButton title="Stop Capture" tone="secondary" onPress={stopCapture} />
        
        {/* MM_GATT_SHARED_PACKET_V9_UI */}
        <View style={styles.card}>
          <Text style={styles.h2}>Shared Packet ID Chain Mode v9</Text>
          <Text style={styles.body}>
            Use this for A06 → S10 → A16 same-packet native GATT proof.
            Generate/reset packet on A06, then type the same packetId on S10 and A16.
          </Text>
          <TextInput
            style={styles.input}
            value={sharedPacketIdInput}
            onChangeText={setSharedPacketIdInput}
            placeholder="MMN-XXXXXX-XXXXXX"
            autoCapitalize="characters"
            autoCorrect={false}
          />
          <Pressable style={styles.button} onPress={applySharedPacketIdV9}>
            <Text style={styles.buttonText}>Use Shared Packet ID</Text>
          </Pressable>
          <Text style={styles.mono}>SHARED_PACKET_V9_APPLIED</Text>
        </View>


        <View style={styles.card}>
          <Text style={styles.h2}>Real GATT Transport Send</Text>
          <Text style={styles.body}>
            This uses MauriMeshBle.startRawPacketReceiver and MauriMeshBle.sendRawPacketUtf8.
            It targets the real MeshCentralClient → writeCharacteristic → MeshRawPacketGattServer path.
          </Text>
          <TextInput
            style={styles.input}
            value={realGattTargetAddress}
            onChangeText={setRealGattTargetAddress}
            placeholder="Target BLE address, e.g. AA:BB:CC:DD:EE:FF"
            autoCapitalize="characters"
            autoCorrect={false}
          />
          <Pressable style={styles.button} onPress={startRealGattReceiverFromTruthGate}>
            <Text style={styles.buttonText}>Start Raw Packet Receiver</Text>
          </Pressable>
          <Pressable style={styles.button} onPress={refreshRealGattReceiverStatusFromTruthGate}>
            <Text style={styles.buttonText}>Refresh Receiver Status</Text>
          </Pressable>
          <Pressable style={styles.button} onPress={sendRealGattPacketFromTruthGate}>
            <Text style={styles.buttonText}>Send Real GATT Packet</Text>
          </Pressable>
          <Text style={styles.mono}>Result: {realGattResult}</Text>
        </View>

<GateButton
          title="Trigger Native GATT Packet Payload"
          tone="warning"
          onPress={triggerNativeGattPacketPayload}
        />
        <GateButton title="Save Attempt Into Vault" tone="secondary" onPress={saveAttempt} />
        <GateButton title="Reset Packet" tone="danger" onPress={resetPacket} />
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Expected logcat markers</Text>
        <Text style={styles.mono}>BUTTON_PRESS_START_CAPTURE</Text>
        <Text style={styles.mono}>BUTTON_PRESS_STOP_CAPTURE</Text>
        <Text style={styles.mono}>BUTTON_PRESS_SAVE_ATTEMPT</Text>
        <Text style={styles.mono}>BUTTON_PRESS_RESET_PACKET</Text>
        <Text style={styles.mono}>BUTTON_PRESS_NATIVE_GATT_TRIGGER</Text>
        <Text style={styles.mono}>GATT_PACKET_PAYLOAD</Text>
        <Text style={styles.mono}>GATT_CLIENT_WRITE_ATTEMPT</Text>
        <Text style={styles.mono}>GATT_SERVER_WRITE_RECEIVED</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Live Events</Text>
        {events.map((event, index) => (
          <Text key={`${event}-${index}`} style={styles.eventLine}>
            {event}
          </Text>
        ))}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({

  examPanel: {
    borderWidth: 1,
    borderColor: "#14532D",
    backgroundColor: "rgba(0, 30, 18, 0.82)",
    borderRadius: 18,
    padding: 14,
    marginVertical: 12,
    gap: 10,
  },
  examTitle: {
    color: "#FFFFFF",
    fontSize: 18,
    fontWeight: "900",
    marginBottom: 4,
  },
  examLightRow: {
    flexDirection: "row",
    gap: 10,
    alignItems: "center",
    borderBottomWidth: 1,
    borderBottomColor: "rgba(255,255,255,0.08)",
    paddingBottom: 8,
  },
  examFinalBox: {
    flexDirection: "row",
    gap: 10,
    alignItems: "center",
    borderWidth: 1,
    borderColor: "#92400E",
    borderRadius: 14,
    padding: 10,
    backgroundColor: "rgba(120,53,15,0.18)",
  },
  examLightDot: {
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.45)",
  },
  examLightTextWrap: {
    flex: 1,
  },
  examLightLabel: {
    color: "#FFFFFF",
    fontSize: 14,
    fontWeight: "900",
  },
  examLightMarker: {
    color: "#38BDF8",
    fontSize: 11,
    fontWeight: "700",
  },
  examPass: {
    color: "#22C55E",
    fontSize: 11,
    fontWeight: "900",
  },
  examWaiting: {
    color: "#F59E0B",
    fontSize: 11,
    fontWeight: "900",
  },

  input: {
    borderWidth: 1,
    borderColor: "#4b5563",
    borderRadius: 8,
    padding: 10,
    marginTop: 8,
    marginBottom: 8,
    color: "#ffffff",
  },
  screen: {
    flex: 1,
    backgroundColor: "#020403",
  },
  content: {
    padding: 18,
    gap: 14,
  },
  header: {
    gap: 8,
    paddingTop: 12,
    paddingBottom: 4,
  },
  kicker: {
    color: "#00D084",
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 2,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 30,
    fontWeight: "900",
  },
  subtitle: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 14,
    lineHeight: 20,
  },
  card: {
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.28)",
    backgroundColor: "rgba(2,12,8,0.84)",
    borderRadius: 22,
    padding: 16,
    gap: 10,
  },
  cardTitle: {
    color: "#FFFFFF",
    fontSize: 18,
    fontWeight: "900",
  },
  row: {
    gap: 4,
  },
  label: {
    color: "rgba(255,255,255,0.55)",
    fontSize: 12,
    fontWeight: "800",
    letterSpacing: 0.4,
  },
  value: {
    color: "#FFFFFF",
    fontSize: 14,
    fontWeight: "800",
  },
  good: {
    color: "#22C55E",
    fontSize: 14,
    fontWeight: "900",
  },
  warn: {
    color: "#F59E0B",
    fontSize: 14,
    fontWeight: "900",
  },
  bad: {
    color: "#EF4444",
    fontSize: 14,
    fontWeight: "900",
  },
  truthNote: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 13,
    lineHeight: 19,
    marginTop: 6,
  },
  errorBox: {
    color: "#FCA5A5",
    backgroundColor: "rgba(239,68,68,0.14)",
    borderColor: "rgba(239,68,68,0.35)",
    borderWidth: 1,
    borderRadius: 14,
    padding: 10,
    fontSize: 12,
    lineHeight: 18,
  },
  buttonStack: {
    gap: 10,
  },
  button: {
    minHeight: 54,
    borderRadius: 18,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 16,
    borderWidth: 1,
  },
  buttonPrimary: {
    backgroundColor: "#00D084",
    borderColor: "#00D084",
  },
  buttonSecondary: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderColor: "rgba(34,197,94,0.28)",
  },
  buttonDanger: {
    backgroundColor: "rgba(239,68,68,0.18)",
    borderColor: "rgba(239,68,68,0.48)",
  },
  buttonWarning: {
    backgroundColor: "rgba(245,158,11,0.18)",
    borderColor: "rgba(245,158,11,0.55)",
  },
  buttonPressed: {
    opacity: 0.72,
    transform: [{ scale: 0.985 }],
  },
  buttonText: {
    color: "#FFFFFF",
    fontSize: 15,
    fontWeight: "900",
    textAlign: "center",
  },
  mono: {
    color: "#38BDF8",
    fontFamily: Platform.select({ ios: "Menlo", android: "monospace", default: "monospace" }),
    fontSize: 12,
  },
  eventLine: {
    color: "rgba(255,255,255,0.75)",
    fontFamily: Platform.select({ ios: "Menlo", android: "monospace", default: "monospace" }),
    fontSize: 11,
    lineHeight: 16,
  },
});