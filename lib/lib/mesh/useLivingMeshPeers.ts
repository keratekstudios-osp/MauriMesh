/**
 * useLivingMeshPeers — maps live BLE peers from the Zustand store into
 * MeshNode objects suitable for the Living Mesh 3D visualiser.
 *
 * Real data        : nodeId, rssi, lastSeen  (from BlePeer)
 * Estimated data   : displayName (short device label), trustScore (RSSI-derived)
 * Derived status   : NodeStatus.TRUSTED for all reachable BLE peers
 */

import { useMeshStore } from "../store/meshStore";
import { NodeStatus, type MeshNode } from "../mesh-core/types";
import type { BlePeer } from "./useBleTransport";

function rssiToTrustScore(rssi: number): number {
  if (rssi >= -45) return 92;
  if (rssi >= -60) return 78;
  if (rssi >= -75) return 62;
  if (rssi >= -88) return 44;
  return 22;
}

function peerLabel(peer: BlePeer): string {
  const shortId = peer.nodeId.replace(/[^a-zA-Z0-9]/g, "").slice(-6).toUpperCase();
  return `BLE-${shortId}`;
}

export interface LivingMeshPeerState {
  bleMeshNodes: MeshNode[];
  hasRealPeers: boolean;
}

export function useLivingMeshPeers(): LivingMeshPeerState {
  const peers = useMeshStore((s) => s.peers);

  const bleMeshNodes: MeshNode[] = peers.map((peer) => {
    const node: MeshNode = {
      nodeId: peer.nodeId,
      displayName: peerLabel(peer),
      status: NodeStatus.TRUSTED,
      rssi: peer.rssi,
      lastSeenAt: peer.lastSeen,
      trustScore: rssiToTrustScore(peer.rssi),
    };
    console.log(
      `[MauriMesh][BLEPeer] mapped nodeId=${peer.nodeId} rssi=${peer.rssi} trust=${node.trustScore}`
    );
    return node;
  });

  return {
    bleMeshNodes,
    hasRealPeers: bleMeshNodes.length > 0,
  };
}
