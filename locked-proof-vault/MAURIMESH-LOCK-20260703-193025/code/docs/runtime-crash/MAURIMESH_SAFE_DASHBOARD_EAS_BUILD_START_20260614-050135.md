# MauriMesh Safe Dashboard EAS Build Start

Generated: 20260614-050135

## Required markers

### Dashboard
21:    route: "/ble-2-hop-proof",
26:    route: "/3-device-proof",
31:    route: "/ble-3-device-proof",
36:    route: "/store-forward-proof",
41:    route: "/locked-proof-vault",
46:    route: "/proof-vault-health",
51:    route: "/learner-core",
61:      console.log(`MAURIMESH_SAFE_DASHBOARD_OPEN | route=${route}`);
84:        <Text style={styles.title}>Safe Dashboard</Text>

### Store-Forward vault save
220:      // MAURIMESH_STORE_FORWARD_VAULT_SAVE_CALL_V1
661:    const key = `maurimesh_proof_store_forward_${safePacketId}`;

### Proof Vault Health
92:        `MAURIMESH_PROOF_VAULT_HEALTH | entries=${next.length} | bytes=${next.reduce(
100:      console.log(`MAURIMESH_PROOF_VAULT_HEALTH_ERROR | error=${message}`);
115:      type: "MAURIMESH_PROOF_VAULT_HEALTH_EXPORT",
166:      <Text style={styles.title}>Proof Vault Health</Text>

## Truth

This build should fix the Open Dashboard crash path by using Safe Dashboard v2.
Native BLE/GATT packet-bound PASS is not claimed.
