import React, { useEffect, useState } from "react";
import { Alert, ScrollView, StyleSheet, Text, View } from "react-native";
import {
  getMauriMeshHardwareBleStatus,
  openMauriMeshBluetoothSettings,
  requestMauriMeshHardwareBlePermissions,
  startMauriMeshHardwareBleScan,
  stopMauriMeshHardwareBleScan,
} from "../native/MauriMeshHardwareBle";
import { MaoriProtocolPanel } from "./MaoriProtocolPanel";
import { MauriButton } from "./MauriButton";

const C = {
  bg: "#020403",
  panel: "rgba(2,12,8,0.92)",
  border: "rgba(0,208,132,0.32)",
  green: "#00D084",
  blue: "#38BDF8",
  white: "#FFFFFF",
  muted: "rgba(255,255,255,0.72)",
  warn: "#F59E0B",
  danger: "#FB7185",
};

export function HardwareBleProofPanel() {
  const [status, setStatus] = useState<any>({});
  const [lastAction, setLastAction] = useState("WAITING");

  const refresh = async () => {
    const next = await getMauriMeshHardwareBleStatus();
    setStatus(next);
  };

  useEffect(() => {
    refresh();
    const t = setInterval(refresh, 2500);
    return () => clearInterval(t);
  }, []);

  const requestPermissions = async () => {
    const res = await requestMauriMeshHardwareBlePermissions();
    setLastAction(`PERMISSIONS: ${JSON.stringify(res)}`);
    await refresh();
  };

  const start = async () => {
    try {
      const res = await startMauriMeshHardwareBleScan();
      setLastAction(`START: ${JSON.stringify(res)}`);
      Alert.alert(
        "MauriMesh BLE scan started",
        "Leave MauriMesh open, turn the screen off for 2–5 minutes, then check Android Bluetooth scan history.",
      );
    } catch (e: any) {
      setLastAction(`START_ERROR: ${String(e?.message || e)}`);
      Alert.alert("Start scan failed", String(e?.message || e));
    }
    await refresh();
  };

  const stop = async () => {
    const res = await stopMauriMeshHardwareBleScan();
    setLastAction(`STOP: ${JSON.stringify(res)}`);
    await refresh();
  };

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <Text style={styles.kicker}>MAURIMESH NATIVE HARDWARE BLE</Text>
        <Text style={styles.title}>Hardware BLE Proof</Text>
        <Text style={styles.subtitle}>
          Real Android BluetoothLeScanner foreground-service proof. This is the layer
          that should make MauriMesh appear in Android Bluetooth scan history after
          screen-off scanning.
        </Text>
      </View>

      <MaoriProtocolPanel screen="Hardware BLE Proof" compact />

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Native Status</Text>
        <Text style={styles.line}>Native module: {String(status.nativeModule)}</Text>
        <Text style={styles.line}>Bluetooth adapter: {String(status.bluetoothAdapterPresent)}</Text>
        <Text style={styles.line}>Bluetooth enabled: {String(status.bluetoothEnabled)}</Text>
        <Text style={styles.line}>BLUETOOTH_SCAN: {String(status.scanPermission)}</Text>
        <Text style={styles.line}>BLUETOOTH_CONNECT: {String(status.connectPermission)}</Text>
        <Text style={styles.line}>Location permission: {String(status.fineLocationPermission)}</Text>
        <Text style={styles.line}>Post notifications: {String(status.postNotificationsPermission)}</Text>
        <Text style={styles.line}>Service running: {String(status.serviceRunning)}</Text>
        <Text style={styles.line}>Discovered count: {String(status.discoveredCount || 0)}</Text>
        <Text style={styles.line}>Last device: {String(status.lastDeviceName || "none")}</Text>
        <Text style={styles.line}>Last address: {String(status.lastDeviceAddress || "none")}</Text>
        <Text style={styles.line}>Last RSSI: {String(status.lastRssi || 0)}</Text>
        <Text style={styles.marker}>{String(status.proofMarker || "NO_MARKER")}</Text>
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Actions</Text>
        <MauriButton title="Request BLE Permissions" onPress={requestPermissions} />
        <MauriButton title="Start Native Hardware BLE Scan" onPress={start} />
        <MauriButton title="Stop Native Hardware BLE Scan" onPress={stop} />
        <MauriButton title="Refresh Status" onPress={refresh} />
        <MauriButton title="Open Bluetooth Settings" onPress={openMauriMeshBluetoothSettings} />
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Android Scan History Test</Text>
        <Text style={styles.step}>1. Press Request BLE Permissions.</Text>
        <Text style={styles.step}>2. Press Start Native Hardware BLE Scan.</Text>
        <Text style={styles.step}>3. Confirm service running = true.</Text>
        <Text style={styles.step}>4. Leave MauriMesh open.</Text>
        <Text style={styles.step}>5. Turn screen off for 2–5 minutes.</Text>
        <Text style={styles.step}>6. Turn screen on.</Text>
        <Text style={styles.step}>7. Open Android Bluetooth scan history.</Text>
        <Text style={styles.step}>8. MauriMesh should appear there if native scan ran while screen was off.</Text>
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Logcat Markers</Text>
        <Text style={styles.marker}>MAURIMESH_NATIVE_HARDWARE_BLE_START_REQUESTED</Text>
        <Text style={styles.marker}>MAURIMESH_NATIVE_BLE_SERVICE_CREATED</Text>
        <Text style={styles.marker}>MAURIMESH_NATIVE_BLE_SCAN_STARTED</Text>
        <Text style={styles.marker}>MAURIMESH_NATIVE_BLE_SCAN_RESULT</Text>
        <Text style={styles.marker}>MAURIMESH_NATIVE_BLE_SCAN_STOPPED</Text>
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Last Action</Text>
        <Text style={styles.truth}>{lastAction}</Text>
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Truth Boundary</Text>
        <Text style={styles.truth}>
          This proves native Android BLE scanning when the service starts and Android records scan activity.
          It still does not prove message delivery, receiver ACK, relay, or 3-hop mesh until packet TX/RX/ACK logs exist.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: C.bg },
  content: { padding: 18, gap: 14, paddingBottom: 42 },
  header: { gap: 8 },
  kicker: { color: C.blue, fontSize: 12, fontWeight: "900", letterSpacing: 1 },
  title: { color: C.white, fontSize: 34, fontWeight: "900", letterSpacing: -1 },
  subtitle: { color: C.muted, fontSize: 15, lineHeight: 22 },
  panel: {
    borderWidth: 1,
    borderColor: C.border,
    borderRadius: 22,
    backgroundColor: C.panel,
    padding: 15,
    gap: 8,
  },
  sectionTitle: { color: C.white, fontSize: 20, fontWeight: "900" },
  line: { color: C.muted, fontSize: 14, lineHeight: 20 },
  step: { color: C.muted, fontSize: 13, lineHeight: 20 },
  marker: { color: C.green, fontSize: 12, lineHeight: 18, fontFamily: "monospace" },
  truth: { color: C.warn, fontSize: 12, lineHeight: 18 },
});
