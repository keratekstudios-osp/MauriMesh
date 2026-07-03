#!/usr/bin/env bash
set -euo pipefail

TARGET="app/native-ble-gatt-proof.tsx"
BACKUP="$TARGET.backup-real-gatt-send-v1-$(date +%Y%m%d-%H%M%S)"
cp "$TARGET" "$BACKUP"

python3 <<'PY'
from pathlib import Path

p = Path("app/native-ble-gatt-proof.tsx")
s = p.read_text()

# Add import from existing real transport client
imp = '''import {
  sendRawPacketUtf8,
  startRawPacketReceiver,
  getRawPacketReceiverStatus,
} from "../src/maurimesh/ble/rawPacketProofClient";
'''
if 'rawPacketProofClient' not in s:
    s = s.replace('} from "react-native";\n', '} from "react-native";\n' + imp)

# Add state
anchor = 'const [sharedPacketIdInput, setSharedPacketIdInput] = useState("");'
if anchor in s and 'realGattTargetAddress' not in s:
    s = s.replace(anchor, anchor + '''
  const [realGattTargetAddress, setRealGattTargetAddress] = useState("");
  const [realGattResult, setRealGattResult] = useState("NOT_STARTED");
''')

# Add functions before return
marker = '  return (\n'
if 'sendRealGattPacketFromTruthGate' not in s:
    funcs = r'''
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

'''
    s = s.replace(marker, funcs + marker)

# Add UI panel before Trigger Native GATT button
ui_anchor = '<GateButton\n          title="Trigger Native GATT Packet Payload"'
if ui_anchor in s and 'Real GATT Transport Send' not in s:
    panel = r'''
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

'''
    s = s.replace(ui_anchor, panel + ui_anchor)

p.write_text(s)
PY

npx tsc --noEmit
npx expo export --platform android

echo "READY_FOR_REAL_GATT_SEND_APK_BUILD"
echo "Backup: $BACKUP"
