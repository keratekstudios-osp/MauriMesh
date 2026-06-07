---
name: MauriMesh packet trust model
description: How BLE packet authenticity (inbound verify + outbound signing + nodeId→key binding) must be wired in the TS mesh layer.
---

# MauriMesh packet trust model

The TS mesh logic layer (`lib/lib/mesh/*.ts`) enforces packet authenticity. Rules
that are easy to get wrong:

## Trust binding (nodeId → publicKey) must come from verified packets only
- nodeIds are `mm-<ts>-<rand>` (not key-derived), so they are NOT self-certifying.
  A TOFU binding (`KeyBindingStore` in `MeshCryptoIdentity.ts`) is the correct model.
- **Why:** signature verification alone proves "someone holds the private key for
  the key *in the packet*" — it does NOT prove that key belongs to the claimed
  nodeId. Without a binding, an attacker signs with their own key but stamps a
  victim's nodeId and passes.
- **Never** seed the binding from `nearbyPeerRegistry` / `getDiscoveredPeers()`.
  That registry is fed by UNAUTHENTICATED BLE advertisements (`parseFriendBeacon`
  in `useBleTransport.ts`) and its manufacturer-data path stores `fp:<base64>`
  8-byte fingerprint pseudo-keys, not full Ed25519 keys. Seeding from it enables
  binding poisoning AND causes false `conflict` drops when a fingerprint is later
  compared against a real key.
- Correct source: `verifiedIdentityStore.ts` — written ONLY via
  `recordVerifiedIdentity()` after a signature has verified, first-write-wins so a
  later conflicting key can never clobber an established identity. Seed
  `KeyBindingStore` from `loadVerifiedIdentities()` on mount.
- Defense in depth: `KeyBindingStore.seed/reconcile` and `isFullEd25519Key` reject
  `fp:`-prefixed keys so fingerprints can never enter the binding map.

## Inbound: signature mandatory for every type except ROUTE_BEACON
- `verifyAndDispatch` is the single ingress gate. ROUTE_BEACON is the ONLY type
  allowed unsigned (pure routing liveness). All BLE ingress — including the native
  GATT peripheral receive callback — must route through it, never call
  `routeInboundPacket` directly.

## Trust ORDERING: never commit identity state before authentication
- `resolvePeerNodeId(deviceId, fromNodeId)` mutates the deviceId→nodeId map from
  the packet's `fromNodeId`. It MUST run only AFTER `verifyAndDispatch` returns
  an authenticated result, never before.
- **Why:** `fromNodeId` is attacker-controllable. Resolving before verification
  poisons peer identity (misrouting / heartbeat confusion / DoS) even for packets
  that are later dropped (bad sig, key conflict, unsigned).
- **How to apply:** `verifyAndDispatch` returns `VerifyDispatchResult`
  (`verified`|`beacon`|`dropped`); call `resolvePeerNodeId` only on `verified`,
  using the returned nodeId — for BOTH the full-packet and fragment paths
  (fragments resolve only after full reassembly + verification). `beacon`
  (unsigned ROUTE_BEACON) and `dropped` must not touch identity state.
  ROUTE_BEACON liveness still works: PONG uses `refreshPeerActivity(nodeId)` and
  peer.nodeId from the scan path, not packet-driven resolution.

## Outbound: fail-closed at a single egress choke point
- `isOutboundAllowed(packet)` requires both `signature` AND `fromPublicKey` for
  every non-ROUTE_BEACON packet. Apply it at EVERY BLE egress: `trySendViaBle`
  plus the direct `sendToRef.current(...)` strict-ACK sends (forward, relay,
  drain). Easy to miss: strict-ACK paths bypass `trySendViaBle`.
- **Why:** `signOutboundPacket` no-ops while the crypto identity is still loading
  at startup, so a packet can be created/queued unsigned. The gate refuses to leak
  it; the receiver would drop it anyway.
- To avoid a fail-closed *deadlock* of those startup-window packets, re-sign at
  dequeue/drain: `if (!packet.signature) signOutboundPacket(packet)` before the
  egress gate, in both the fallback queue drain and the strict-ACK queue drain.

## Out of scope (hard constraint)
- Never touch native/Rust/Kotlin BLE radio internals, android/ios/eas. Only the
  TS mesh logic is in scope. The non-BLE bridge inbound (`addMessage`) is
  intentionally left unsigned (separate channel, outside the nearby-attacker
  threat model).
