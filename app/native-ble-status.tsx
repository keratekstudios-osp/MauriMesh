import React, { useEffect, useState } from "react";
import {
  NativeModules,
  PermissionsAndroid,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";

const MARKER = "NATIVE_BLE_GETSTATUS_PROOF_20260607_A";

type PermissionState = {
  scan: string;
  connect: string;
  location: string;
};

type NativeStatus = {
  module?: string;
  mode?: string;
  modulePresent?: boolean;
  liveBleActive?: boolean;
  truth?: string;
  error?: string;
};

async function checkPermissions(): Promise<PermissionState> {
  if (Platform.OS !== "android") {
    return {
      scan: "not_android",
      connect: "not_android",
      location: "not_android",
    };
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

async function readNativeStatus(): Promise<NativeStatus> {
  const mod = NativeModules.MauriMeshBle;

  if (!mod) {
    return {
      module: "MauriMeshBle",
      modulePresent: false,
      liveBleActive: false,
      mode: "missing",
      error: "NativeModules.MauriMeshBle was not found.",
      truth:
        "The JS bridge did not find the native module. No BLE was activated.",
    };
  }

  if (typeof mod.getStatus !== "function") {
    return {
      module: "MauriMeshBle",
      modulePresent: true,
      liveBleActive: false,
      mode: "present_no_getStatus",
      error: "MauriMeshBle exists, but getStatus() is not exposed.",
      truth:
        "The native module is present, but the read-only status method is not available in this APK.",
    };
  }

  try {
    const status = await mod.getStatus();
    return {
      module: String(status?.module ?? "MauriMeshBle"),
      mode: String(status?.mode ?? "unknown"),
      modulePresent: Boolean(status?.modulePresent),
      liveBleActive: Boolean(status?.liveBleActive),
      truth: String(
        status?.truth ??
          "Native getStatus() returned successfully. No live BLE action was activated."
      ),
    };
  } catch (error: any) {
    return {
      module: "MauriMeshBle",
      modulePresent: true,
      liveBleActive: false,
      mode: "getStatus_error",
      error: String(error?.message ?? error),
      truth:
        "Native module exists, but getStatus() threw an error. No live BLE action was activated.",
    };
  }
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

export default function NativeBleStatusScreen() {
  const [permissions, setPermissions] = useState<PermissionState>({
    scan: "checking",
    connect: "checking",
    location: "checking",
  });

  const [status, setStatus] = useState<NativeStatus>({
    module: "MauriMeshBle",
    modulePresent: false,
    liveBleActive: false,
    mode: "checking",
    truth: "Checking read-only native bridge status.",
  });

  useEffect(() => {
    let alive = true;

    async function run() {
      const [perm, native] = await Promise.all([
        checkPermissions(),
        readNativeStatus(),
      ]);

      if (!alive) return;

      setPermissions(perm);
      setStatus(native);
    }

    run();

    return () => {
      alive = false;
    };
  }, []);

  const modulePresent = status.modulePresent === true;
  const liveBleActive = status.liveBleActive === true;

  return (
    <ScrollView style={styles.page} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Native BLE Status</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <Card title="Truth Boundary" warning>
        <Text style={styles.body}>
          Read-only native BLE bridge proof. This screen calls getStatus() only.
          It does not scan, advertise, connect, send, receive, ACK, or relay.
        </Text>
      </Card>

      <Card title="Native Module">
        <Text style={modulePresent ? styles.good : styles.bad}>
          {modulePresent ? "PRESENT" : "NOT CONFIRMED"}
        </Text>
        <Text style={styles.body}>Module name: {status.module}</Text>
      </Card>

      <Card title="Native getStatus()">
        <Text style={modulePresent ? styles.good : styles.bad}>
          {status.mode ?? "unknown"}
        </Text>
        <Text style={styles.body}>
          modulePresent: {String(status.modulePresent)}
        </Text>
        <Text style={styles.body}>
          liveBleActive: {String(status.liveBleActive)}
        </Text>
        {status.error ? <Text style={styles.error}>{status.error}</Text> : null}
      </Card>

      <Card title="Platform">
        <Text style={styles.body}>{Platform.OS}</Text>
      </Card>

      <Card title="Android Permissions">
        <Text style={styles.body}>BLUETOOTH_SCAN: {permissions.scan}</Text>
        <Text style={styles.body}>BLUETOOTH_CONNECT: {permissions.connect}</Text>
        <Text style={styles.body}>
          ACCESS_FINE_LOCATION: {permissions.location}
        </Text>
      </Card>

      <Card title="Live BLE Active">
        <Text style={liveBleActive ? styles.bad : styles.good}>
          {liveBleActive ? "YES" : "NO"}
        </Text>
        <Text style={styles.body}>
          This status must stay NO until we intentionally add a separate live
          BLE scan/advertise test screen.
        </Text>
      </Card>

      <Card title="Native Truth">
        <Text style={styles.body}>{status.truth}</Text>
      </Card>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: {
    flex: 1,
    backgroundColor: "#050816",
  },
  content: {
    padding: 24,
    paddingTop: 56,
    paddingBottom: 80,
  },
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
    fontSize: 18,
    lineHeight: 28,
    marginBottom: 6,
  },
  good: {
    color: "#00D084",
    fontSize: 34,
    fontWeight: "900",
    letterSpacing: 2,
    marginBottom: 12,
  },
  bad: {
    color: "#FF4D5E",
    fontSize: 34,
    fontWeight: "900",
    letterSpacing: 2,
    marginBottom: 12,
  },
  error: {
    color: "#F59E0B",
    fontSize: 16,
    lineHeight: 24,
    marginTop: 8,
  },
});
