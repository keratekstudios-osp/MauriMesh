import AsyncStorage from "@react-native-async-storage/async-storage";
import React, { useMemo, useState } from "react";
import {
  Alert,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";

type VaultEntry = {
  key: string;
  bytes: number;
  value: string;
  parsedType: string;
  packetId: string;
  nativeBleGattPacketBoundPass: boolean;
};

function simpleChecksum(text: string): string {
  let hash = 2166136261;
  for (let i = 0; i < text.length; i += 1) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16).padStart(8, "0");
}

function classifyKey(key: string): string {
  if (key.includes("store_forward")) return "STORE_FORWARD";
  if (key.includes("ble_3_device")) return "BLE_3_DEVICE";
  if (key.includes("3_device")) return "THREE_DEVICE";
  if (key.includes("ble_2_hop")) return "BLE_2_HOP";
  if (key.includes("learner_report")) return "LEARNER_REPORT";
  if (key.includes("routing")) return "ROUTING_SETTING";
  if (key.includes("proof")) return "PROOF_OTHER";
  return "OTHER";
}

function parseEntry(key: string, value: string | null): VaultEntry {
  const safeValue = value ?? "";
  let parsedType = classifyKey(key);
  let packetId = "NO_PACKET_ID";
  let nativeBleGattPacketBoundPass = false;

  try {
    const json = JSON.parse(safeValue);
    parsedType = String(json.type || parsedType);
    packetId = String(json.packetId || packetId);
    nativeBleGattPacketBoundPass = Boolean(json.nativeBleGattPacketBoundPass);
  } catch (_) {
    const match = safeValue.match(/packetId=([A-Z0-9-]+)/) || key.match(/(MMN-[A-Z0-9-]+|MM3-[A-Z0-9]+-[A-Z0-9]+|MMSF-[A-Z0-9]+-[A-Z0-9]+|MM-[A-Z0-9]+-[A-Z0-9]+)/);
    if (match?.[1]) packetId = match[1];
  }

  return {
    key,
    bytes: safeValue.length,
    value: safeValue,
    parsedType,
    packetId,
    nativeBleGattPacketBoundPass,
  };
}

export default function ProofVaultHealthScreen() {
  const [entries, setEntries] = useState<VaultEntry[]>([]);
  const [lastRefresh, setLastRefresh] = useState<string>("Not refreshed yet");
  const [error, setError] = useState<string>("");

  async function refreshVault() {
    try {
      setError("");
      const keys = await AsyncStorage.getAllKeys();
      const vaultKeys = keys
        .filter((key) =>
          key.startsWith("maurimesh_") ||
          key.includes("proof") ||
          key.includes("learner") ||
          key.includes("routing")
        )
        .sort();

      const pairs = await AsyncStorage.multiGet(vaultKeys);
      const next = pairs.map(([key, value]) => parseEntry(key, value));
      setEntries(next);
      setLastRefresh(new Date().toISOString());

      console.log(
        `MAURIMESH_PROOF_VAULT_HEALTH | entries=${next.length} | bytes=${next.reduce(
          (sum, row) => sum + row.bytes,
          0
        )}`
      );
    } catch (err) {
      const message = err instanceof Error ? err.message : "Unknown vault error";
      setError(message);
      console.log(`MAURIMESH_PROOF_VAULT_HEALTH_ERROR | error=${message}`);
    }
  }

  const exportReport = useMemo(() => {
    const totalBytes = entries.reduce((sum, row) => sum + row.bytes, 0);
    const proofEntries = entries.filter((row) => row.key.includes("proof"));
    const nativePassEntries = entries.filter((row) => row.nativeBleGattPacketBoundPass);

    const byType = entries.reduce<Record<string, number>>((acc, row) => {
      acc[row.parsedType] = (acc[row.parsedType] || 0) + 1;
      return acc;
    }, {});

    const payload = {
      type: "MAURIMESH_PROOF_VAULT_HEALTH_EXPORT",
      generatedAt: new Date().toISOString(),
      lastRefresh,
      entriesFound: entries.length,
      proofEntries: proofEntries.length,
      totalBytes,
      byType,
      packetIds: Array.from(new Set(entries.map((row) => row.packetId).filter((id) => id !== "NO_PACKET_ID"))),
      nativeBleGattPacketBoundPassCount: nativePassEntries.length,
      truth:
        "This report audits local vault storage. It does not claim native BLE/GATT packet-bound PASS unless entries contain nativeBleGattPacketBoundPass=true backed by native transport logs.",
      entries: entries.map((row) => ({
        key: row.key,
        bytes: row.bytes,
        parsedType: row.parsedType,
        packetId: row.packetId,
        nativeBleGattPacketBoundPass: row.nativeBleGattPacketBoundPass,
      })),
    };

    const json = JSON.stringify(payload, null, 2);
    return {
      json,
      checksum: simpleChecksum(json),
      totalBytes,
      proofEntries: proofEntries.length,
      nativePassEntries: nativePassEntries.length,
    };
  }, [entries, lastRefresh]);

  async function saveHealthReport() {
    try {
      const key = `maurimesh_vault_health_export_${Date.now()}`;
      await AsyncStorage.setItem(
        key,
        JSON.stringify({
          savedAt: new Date().toISOString(),
          checksum: exportReport.checksum,
          report: JSON.parse(exportReport.json),
          nativeBleGattPacketBoundPass: false,
        })
      );
      Alert.alert("Vault Health Saved", `Saved key:\n${key}`);
      await refreshVault();
    } catch (err) {
      Alert.alert("Save failed", err instanceof Error ? err.message : "Unknown error");
    }
  }

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.title}>Proof Vault Health</Text>
      <Text style={styles.subtitle}>
        Local vault audit, export report, packet index, byte count, and integrity checksum.
      </Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Status</Text>
        <Text style={styles.line}>Entries found: {entries.length}</Text>
        <Text style={styles.line}>Proof entries: {exportReport.proofEntries}</Text>
        <Text style={styles.line}>Approx stored bytes: {exportReport.totalBytes}</Text>
        <Text style={styles.line}>Native BLE/GATT packet-bound PASS entries: {exportReport.nativePassEntries}</Text>
        <Text style={styles.line}>Checksum: {exportReport.checksum}</Text>
        <Text style={styles.warning}>
          Native BLE/GATT PASS is not claimed unless packetId appears inside native transport logs.
        </Text>
      </View>

      {error ? <Text style={styles.error}>Error: {error}</Text> : null}

      <TouchableOpacity style={styles.button} onPress={refreshVault}>
        <Text style={styles.buttonText}>Refresh Vault Health</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.secondaryButton} onPress={saveHealthReport}>
        <Text style={styles.buttonText}>Save Health Export Into Vault</Text>
      </TouchableOpacity>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Entries</Text>
        {entries.length === 0 ? (
          <Text style={styles.line}>No vault entries found yet.</Text>
        ) : (
          entries.map((entry) => (
            <View key={entry.key} style={styles.entry}>
              <Text style={styles.entryKey}>{entry.key}</Text>
              <Text style={styles.line}>Type: {entry.parsedType}</Text>
              <Text style={styles.line}>Packet: {entry.packetId}</Text>
              <Text style={styles.line}>Bytes: {entry.bytes}</Text>
              <Text style={styles.line}>
                Native pass: {entry.nativeBleGattPacketBoundPass ? "true" : "false"}
              </Text>
            </View>
          ))
        )}
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Export JSON</Text>
        <TextInput
          value={exportReport.json}
          multiline
          editable={false}
          style={styles.exportBox}
        />
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 18, gap: 14 },
  title: { color: "#FFFFFF", fontSize: 30, fontWeight: "900" },
  subtitle: { color: "rgba(255,255,255,0.72)", lineHeight: 21 },
  card: {
    padding: 16,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.28)",
    backgroundColor: "rgba(2,12,8,0.84)",
    gap: 8,
  },
  cardTitle: { color: "#00D084", fontSize: 18, fontWeight: "900" },
  line: { color: "#FFFFFF", lineHeight: 20 },
  warning: { color: "#F59E0B", lineHeight: 20, fontWeight: "700" },
  error: { color: "#EF4444", fontWeight: "800" },
  button: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    padding: 16,
    alignItems: "center",
  },
  secondaryButton: {
    backgroundColor: "rgba(255,255,255,0.08)",
    borderColor: "rgba(34,197,94,0.28)",
    borderWidth: 1,
    borderRadius: 18,
    padding: 16,
    alignItems: "center",
  },
  buttonText: { color: "#FFFFFF", fontSize: 16, fontWeight: "900" },
  entry: {
    borderTopColor: "rgba(255,255,255,0.12)",
    borderTopWidth: 1,
    paddingTop: 10,
    gap: 3,
  },
  entryKey: { color: "#38BDF8", fontWeight: "900" },
  exportBox: {
    minHeight: 280,
    color: "#FFFFFF",
    backgroundColor: "rgba(255,255,255,0.06)",
    borderColor: "rgba(34,197,94,0.28)",
    borderWidth: 1,
    borderRadius: 14,
    padding: 12,
    textAlignVertical: "top",
    fontSize: 12,
  },
});
