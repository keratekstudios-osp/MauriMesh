import React, { useEffect, useState } from "react";
import {
  NativeModules,
  PermissionsAndroid,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

const MARKER = "NATIVE_BLE_SCAN_PROOF_20260607_A";

type ScanStatus = {
  module?: string;
  mode?: string;
  modulePresent?: boolean;
  liveBleActive?: boolean;
  scanActive?: boolean;
  discoveredCount?: number;
  lastError?: string;
  lastDeviceName?: string;
  lastDeviceAddress?: string;
  truth?: string;
};

type PermissionState = {
  scan: string;
  connect: string;
  location: string;
};

const emptyStatus: ScanStatus = {
  module: "MauriMeshBle",
  mode: "not_started",
  modulePresent: false,
  liveBleActive: false,
  scanActive: false,
  discoveredCount: 0,
  truth: "Scan proof not started.",
};

async function checkPermissions(): Promise<PermissionState> {
  if (Platform.OS !== "android") {
    return { scan: "not_android", connect: "not_android", location: "not_android" };
  }

  const scan = await PermissionsAndroid.check(
    PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN as any
  );

  const connect = await PermissionsAndroid.check(
    PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT as any
  );

  const location = await PermissionsAndroid.check(
    PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION
  );

  return {
    scan: scan ? "granted" : "denied",
    connect: connect ? "granted" : "denied",
    location: location ? "granted" : "denied",
  };
}

async function callNative(method: string): Promise<ScanStatus> {
  const mod = NativeModules.MauriMeshBle;

  if (!mod) {
    return {
      ...emptyStatus,
      mode: "missing_module",
      modulePresent: false,
      lastError: "NativeModules.MauriMeshBle not found.",
    };
  }

  if (typeof mod[method] !== "function") {
    return {
      ...emptyStatus,
      mode: "missing_method",
      modulePresent: true,
      lastError: `MauriMeshBle.${method}() not found in this APK.`,
    };
  }

  const result = await mod[method]();

  return {
    module: String(result?.module ?? "MauriMeshBle"),
    mode: String(result?.mode ?? method),
    modulePresent: Boolean(result?.modulePresent),
    liveBleActive: Boolean(result?.liveBleActive),
    scanActive: Boolean(result?.scanActive),
    discoveredCount: Number(result?.discoveredCount ?? 0),
    lastError: String(result?.lastError ?? ""),
    lastDeviceName: String(result?.lastDeviceName ?? ""),
    lastDeviceAddress: String(result?.lastDeviceAddress ?? ""),
    truth: String(result?.truth ?? ""),
  };
}

function Card({
  title,
  children,
  warning,
}: {
  title: string;
  children: React.ReactNode;
  warning?: boolean;
}) {
  return (
    <View style={[styles.card, warning && styles.warningCard]}>
      <Text style={styles.cardTitle}>{title}</Text>
      {children}
    </View>
  );
}

export default function NativeBleScanProofScreen() {
  const [permissions, setPermissions] = useState<PermissionState>({
    scan: "checking",
    connect: "checking",
    location: "checking",
  });

  const [status, setStatus] = useState<ScanStatus>(emptyStatus);
  const [busy, setBusy] = useState(false);

  async function refresh() {
    const [perm, native] = await Promise.all([
      checkPermissions(),
      callNative("getScanProofStatus"),
    ]);
    setPermissions(perm);
    setStatus(native);
  }

  async function startScan() {
    setBusy(true);
    try {
      const native = await callNative("startScanProof");
      setStatus(native);
      setPermissions(await checkPermissions());
    } finally {
      setBusy(false);
    }
  }

  async function stopScan() {
    setBusy(true);
    try {
      const native = await callNative("stopScanProof");
      setStatus(native);
      setPermissions(await checkPermissions());
    } finally {
      setBusy(false);
    }
  }

  useEffect(() => {
    refresh();
    const timer = setInterval(refresh, 2000);
    return () => clearInterval(timer);
  }, []);

  const scanActive = status.scanActive === true;

  return (
    <ScrollView style={styles.page} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Native BLE Scan Proof</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <Card title="Truth Boundary" warning>
        <Text style={styles.body}>
          Controlled scan proof only. This screen may start and stop BLE scanning.
          It does not advertise, connect, send, receive, ACK, relay, or claim mesh delivery.
        </Text>
      </Card>

      <Card title="Native Module">
        <Text style={status.modulePresent ? styles.good : styles.bad}>
          {status.modulePresent ? "PRESENT" : "NOT CONFIRMED"}
        </Text>
        <Text style={styles.body}>Module name: {status.module}</Text>
      </Card>

      <Card title="Scan State">
        <Text style={scanActive ? styles.good : styles.bad}>
          {scanActive ? "SCAN ACTIVE" : "SCAN STOPPED"}
        </Text>
        <Text style={styles.body}>Mode: {status.mode}</Text>
        <Text style={styles.body}>
          Discovered count: {String(status.discoveredCount ?? 0)}
        </Text>
        <Text style={styles.body}>
          Last device name: {status.lastDeviceName || "none"}
        </Text>
        <Text style={styles.body}>
          Last device address: {status.lastDeviceAddress || "none"}
        </Text>
        {status.lastError ? <Text style={styles.error}>{status.lastError}</Text> : null}
      </Card>

      <Card title="Android Permissions">
        <Text style={styles.body}>BLUETOOTH_SCAN: {permissions.scan}</Text>
        <Text style={styles.body}>BLUETOOTH_CONNECT: {permissions.connect}</Text>
        <Text style={styles.body}>ACCESS_FINE_LOCATION: {permissions.location}</Text>
      </Card>

      <TouchableOpacity
        disabled={busy}
        style={[styles.button, scanActive && styles.stopButton]}
        onPress={scanActive ? stopScan : startScan}
      >
        <Text style={styles.buttonText}>
          {busy ? "Working..." : scanActive ? "Stop Scan Proof" : "Start Scan Proof"}
        </Text>
      </TouchableOpacity>

      <TouchableOpacity disabled={busy} style={styles.secondaryButton} onPress={refresh}>
        <Text style={styles.secondaryButtonText}>Refresh Status</Text>
      </TouchableOpacity>

      <Card title="Native Truth">
        <Text style={styles.body}>{status.truth}</Text>
      </Card>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: { flex: 1, backgroundColor: "#050816" },
  content: { padding: 24, paddingTop: 56, paddingBottom: 80 },
  brand: {
    color: "#00D084",
    fontSize: 42,
    fontWeight: "900",
    marginBottom: 24,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 30,
    fontWeight: "900",
    marginBottom: 12,
  },
  marker: {
    color: "#4FC3F7",
    fontSize: 14,
    fontWeight: "900",
    letterSpacing: 1.5,
    marginBottom: 28,
  },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.28)",
    borderRadius: 20,
    padding: 22,
    marginBottom: 18,
    backgroundColor: "rgba(255,255,255,0.035)",
  },
  warningCard: {
    borderColor: "rgba(245, 158, 11, 0.55)",
    backgroundColor: "rgba(245, 158, 11, 0.055)",
  },
  cardTitle: {
    color: "#FFFFFF",
    fontSize: 22,
    fontWeight: "900",
    marginBottom: 16,
  },
  body: {
    color: "rgba(255,255,255,0.74)",
    fontSize: 17,
    lineHeight: 27,
    marginBottom: 6,
  },
  good: {
    color: "#00D084",
    fontSize: 30,
    fontWeight: "900",
    letterSpacing: 1.5,
    marginBottom: 12,
  },
  bad: {
    color: "#FF4D5E",
    fontSize: 30,
    fontWeight: "900",
    letterSpacing: 1.5,
    marginBottom: 12,
  },
  error: {
    color: "#F59E0B",
    fontSize: 16,
    lineHeight: 24,
    marginTop: 8,
  },
  button: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    padding: 20,
    alignItems: "center",
    marginBottom: 14,
  },
  stopButton: {
    backgroundColor: "#FF4D5E",
  },
  buttonText: {
    color: "#03120C",
    fontSize: 18,
    fontWeight: "900",
  },
  secondaryButton: {
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.5)",
    borderRadius: 18,
    padding: 18,
    alignItems: "center",
    marginBottom: 20,
  },
  secondaryButtonText: {
    color: "#00D084",
    fontSize: 17,
    fontWeight: "900",
  },
});
