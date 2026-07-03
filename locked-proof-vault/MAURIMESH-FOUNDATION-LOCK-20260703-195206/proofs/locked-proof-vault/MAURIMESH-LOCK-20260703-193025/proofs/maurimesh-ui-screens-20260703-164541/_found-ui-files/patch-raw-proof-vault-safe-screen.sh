#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH RAW PROOF VAULT SAFE SCREEN PATCH"
echo "============================================================"
echo "Goal:"
echo "- Stop Raw Proof Vault crash"
echo "- Replace route with safe dependency-light screen"
echo "- Backup existing file first"
echo "- Run TypeScript check"
echo "- Do NOT claim native BLE/GATT pass"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +"%Y%m%d-%H%M%S")"
PATCH_ID="MM-RAW-PROOF-VAULT-SAFE-$STAMP"

mkdir -p "$ROOT/backups/$PATCH_ID" "$ROOT/docs/runtime-crash" "$ROOT/archives"

TARGET="$ROOT/app/locked-proof-vault.tsx"
REPORT="$ROOT/docs/runtime-crash/MAURIMESH_RAW_PROOF_VAULT_SAFE_PATCH_$STAMP.md"
TSC_OUT="$ROOT/docs/runtime-crash/typecheck-after-raw-proof-vault-safe-patch-$STAMP.txt"

if [ -f "$TARGET" ]; then
  cp "$TARGET" "$ROOT/backups/$PATCH_ID/locked-proof-vault.tsx.before"
  echo "Backed up existing route:"
  echo "$ROOT/backups/$PATCH_ID/locked-proof-vault.tsx.before"
else
  echo "Route did not exist. Creating:"
  echo "$TARGET"
fi

cat > "$TARGET" <<'TSX'
import AsyncStorage from '@react-native-async-storage/async-storage';
import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

type VaultEntry = {
  key: string;
  valuePreview: string;
  bytes: number;
};

const MATCH_TERMS = [
  'proof',
  'vault',
  'packet',
  'maurimesh',
  'mesh',
  'ack',
  'relay',
  'store',
  'native',
];

function safePreview(value: string | null): string {
  if (value == null) return 'null';
  const compact = value.replace(/\s+/g, ' ').trim();
  if (compact.length <= 240) return compact;
  return `${compact.slice(0, 240)}…`;
}

function keyLooksRelevant(key: string): boolean {
  const lower = key.toLowerCase();
  return MATCH_TERMS.some((term) => lower.includes(term));
}

export default function LockedProofVaultScreen() {
  const [loading, setLoading] = useState(false);
  const [entries, setEntries] = useState<VaultEntry[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [lastLoadedAt, setLastLoadedAt] = useState<string | null>(null);

  const loadVault = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const allKeys = await AsyncStorage.getAllKeys();
      const relevantKeys = allKeys.filter(keyLooksRelevant).sort();

      const pairs = await AsyncStorage.multiGet(relevantKeys);
      const nextEntries = pairs.map(([key, value]) => ({
        key,
        valuePreview: safePreview(value),
        bytes: value ? value.length : 0,
      }));

      setEntries(nextEntries);
      setLastLoadedAt(new Date().toISOString());
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      setError(message);
      setEntries([]);
      setLastLoadedAt(new Date().toISOString());
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadVault();
  }, [loadVault]);

  const summary = useMemo(() => {
    const totalBytes = entries.reduce((sum, entry) => sum + entry.bytes, 0);
    return {
      count: entries.length,
      totalBytes,
    };
  }, [entries]);

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={styles.container}>
        <View style={styles.headerCard}>
          <Text style={styles.kicker}>MauriMesh Runtime Vault</Text>
          <Text style={styles.title}>Raw Proof Vault</Text>
          <Text style={styles.subtitle}>
            Crash-safe vault view. This screen reads local proof-related storage keys and never claims native BLE/GATT packet-bound proof by itself.
          </Text>
        </View>

        <View style={styles.truthCard}>
          <Text style={styles.sectionTitle}>Truth Status</Text>
          <Text style={styles.truthLine}>APK opens: yes</Text>
          <Text style={styles.truthLine}>Dashboard route: /locked-proof-vault</Text>
          <Text style={styles.truthLine}>Native BLE/GATT packet-bound PASS: not claimed</Text>
          <Text style={styles.truthLine}>Vault entries found: {summary.count}</Text>
          <Text style={styles.truthLine}>Approx stored bytes: {summary.totalBytes}</Text>
          <Text style={styles.truthLine}>Last loaded: {lastLoadedAt ?? 'loading'}</Text>
        </View>

        <Pressable
          accessibilityRole="button"
          onPress={() => {
            void loadVault();
          }}
          style={({ pressed }) => [styles.button, pressed && styles.buttonPressed]}
        >
          <Text style={styles.buttonText}>
            {loading ? 'Scanning Vault…' : 'Refresh Vault'}
          </Text>
        </Pressable>

        {error ? (
          <View style={styles.errorCard}>
            <Text style={styles.errorTitle}>Vault read warning</Text>
            <Text style={styles.errorText}>{error}</Text>
          </View>
        ) : null}

        <View style={styles.listCard}>
          <Text style={styles.sectionTitle}>Proof Storage Entries</Text>

          {entries.length === 0 ? (
            <Text style={styles.emptyText}>
              No proof-related AsyncStorage keys found yet. This is safe. New proof sessions can populate this vault later.
            </Text>
          ) : (
            entries.map((entry) => (
              <View key={entry.key} style={styles.entry}>
                <Text style={styles.entryKey}>{entry.key}</Text>
                <Text style={styles.entryMeta}>{entry.bytes} bytes</Text>
                <Text style={styles.entryValue}>{entry.valuePreview}</Text>
              </View>
            ))
          )}
        </View>

        <View style={styles.footerCard}>
          <Text style={styles.footerText}>
            This screen is intentionally dependency-light to prevent proof-vault crashes. Reconnect richer proof archive features only after this route stays stable on device.
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: '#07110D',
  },
  container: {
    padding: 18,
    gap: 14,
  },
  headerCard: {
    borderRadius: 22,
    padding: 18,
    backgroundColor: '#10241A',
    borderWidth: 1,
    borderColor: '#2D6A4F',
  },
  kicker: {
    color: '#95D5B2',
    fontSize: 12,
    letterSpacing: 1.4,
    textTransform: 'uppercase',
    marginBottom: 8,
  },
  title: {
    color: '#FFFFFF',
    fontSize: 28,
    fontWeight: '800',
    marginBottom: 8,
  },
  subtitle: {
    color: '#CDE8D5',
    fontSize: 14,
    lineHeight: 20,
  },
  truthCard: {
    borderRadius: 18,
    padding: 16,
    backgroundColor: '#0C1B14',
    borderWidth: 1,
    borderColor: '#1B4332',
  },
  sectionTitle: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '800',
    marginBottom: 10,
  },
  truthLine: {
    color: '#D8F3DC',
    fontSize: 14,
    lineHeight: 22,
  },
  button: {
    borderRadius: 16,
    paddingVertical: 14,
    paddingHorizontal: 16,
    alignItems: 'center',
    backgroundColor: '#2D6A4F',
  },
  buttonPressed: {
    opacity: 0.75,
  },
  buttonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '800',
  },
  errorCard: {
    borderRadius: 16,
    padding: 14,
    backgroundColor: '#3A1111',
    borderWidth: 1,
    borderColor: '#B00020',
  },
  errorTitle: {
    color: '#FFD6D6',
    fontSize: 16,
    fontWeight: '800',
    marginBottom: 6,
  },
  errorText: {
    color: '#FFECEC',
    fontSize: 13,
    lineHeight: 19,
  },
  listCard: {
    borderRadius: 18,
    padding: 16,
    backgroundColor: '#091710',
    borderWidth: 1,
    borderColor: '#1B4332',
  },
  emptyText: {
    color: '#B7E4C7',
    fontSize: 14,
    lineHeight: 20,
  },
  entry: {
    borderRadius: 14,
    padding: 12,
    marginTop: 10,
    backgroundColor: '#10241A',
    borderWidth: 1,
    borderColor: '#244D3A',
  },
  entryKey: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '800',
    marginBottom: 4,
  },
  entryMeta: {
    color: '#95D5B2',
    fontSize: 12,
    marginBottom: 6,
  },
  entryValue: {
    color: '#D8F3DC',
    fontSize: 12,
    lineHeight: 18,
  },
  footerCard: {
    borderRadius: 16,
    padding: 14,
    backgroundColor: '#08130D',
    borderWidth: 1,
    borderColor: '#143524',
  },
  footerText: {
    color: '#9FBFA9',
    fontSize: 12,
    lineHeight: 18,
  },
});
TSX

echo ""
echo "[1/4] Route patched:"
echo "$TARGET"

echo ""
echo "[2/4] Running TypeScript..."
set +e
npx tsc --noEmit > "$TSC_OUT" 2>&1
TSC_CODE="$?"
set -e

if [ "$TSC_CODE" -eq 0 ]; then
  TSC_STATUS="PASS"
  echo "TypeScript: PASS"
else
  TSC_STATUS="FAILED"
  echo "TypeScript: FAILED"
  tail -120 "$TSC_OUT" || true
fi

echo ""
echo "[3/4] Writing report..."

cat > "$REPORT" <<MD
# MauriMesh Raw Proof Vault Safe Screen Patch

Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Patch ID

\`\`\`txt
$PATCH_ID
\`\`\`

## Target

\`\`\`txt
$TARGET
\`\`\`

## Reason

Device crash log showed:

\`\`\`txt
TypeError: undefined is not a function
LockedProofVaultScreen
route=/locked-proof-vault
\`\`\`

## Action

Replaced Raw Proof Vault route with a dependency-light crash-safe screen.

## TypeScript

\`\`\`txt
$TSC_STATUS
\`\`\`

Output:

\`\`\`txt
$TSC_OUT
\`\`\`

## Truth

Native BLE/GATT packet-bound PASS is **NOT CLAIMED**.

This patch only fixes the Raw Proof Vault runtime crash path.
MD

echo ""
echo "[4/4] Creating archive..."

ARCHIVE="$ROOT/archives/maurimesh-raw-proof-vault-safe-patch-$STAMP.tar.gz"
tar -czf "$ARCHIVE" \
  -C "$ROOT" \
  "app/locked-proof-vault.tsx" \
  "docs/runtime-crash" \
  "backups/$PATCH_ID" \
  >/dev/null 2>&1 || true

echo ""
echo "============================================================"
echo "MAURIMESH RAW PROOF VAULT SAFE SCREEN PATCH COMPLETE"
echo "============================================================"
echo "Patch ID:"
echo "$PATCH_ID"
echo ""
echo "TypeScript:"
echo "$TSC_STATUS"
echo ""
echo "Target:"
echo "$TARGET"
echo ""
echo "Report:"
echo "$REPORT"
echo ""
echo "Archive:"
echo "$ARCHIVE"
echo ""
echo "FINAL TRUTH:"
echo "Raw Proof Vault crash-safe route patched."
echo "No EAS build was started."
echo "Native BLE/GATT packet-bound PASS is NOT claimed."
echo "============================================================"
