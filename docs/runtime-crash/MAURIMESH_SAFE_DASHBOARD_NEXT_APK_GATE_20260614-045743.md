# MauriMesh Safe Dashboard Next APK Gate

Generated: 20260614-045743

## Required in next APK

- Safe Dashboard Entry v2
- Store-Forward proof vault save call
- Proof Vault Health route
- Learner Core route
- Raw Proof Vault route

## Route markers

21:    route: "/ble-2-hop-proof",
26:    route: "/3-device-proof",
31:    route: "/ble-3-device-proof",
36:    route: "/store-forward-proof",
41:    route: "/locked-proof-vault",
46:    route: "/proof-vault-health",
51:    route: "/learner-core",
61:      console.log(`MAURIMESH_SAFE_DASHBOARD_OPEN | route=${route}`);
84:        <Text style={styles.title}>Safe Dashboard</Text>

## Store-Forward vault save call

220:      // MAURIMESH_STORE_FORWARD_VAULT_SAVE_CALL_V1
661:    const key = `maurimesh_proof_store_forward_${safePacketId}`;

## Proof Vault Health route

92:        `MAURIMESH_PROOF_VAULT_HEALTH | entries=${next.length} | bytes=${next.reduce(
100:      console.log(`MAURIMESH_PROOF_VAULT_HEALTH_ERROR | error=${message}`);
115:      type: "MAURIMESH_PROOF_VAULT_HEALTH_EXPORT",
166:      <Text style={styles.title}>Proof Vault Health</Text>

## Truth

This gate confirms source readiness only.
Physical APK must still be installed and tested on A06/S10/A16.
Native BLE/GATT packet-bound PASS is not claimed.
