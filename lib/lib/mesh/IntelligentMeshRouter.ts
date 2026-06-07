/**
 * IntelligentMeshRouter — standalone re-export.
 *
 * The full router implementation lives in maurimesh-intelligent-contract.ts.
 * This file re-exports it and the associated types so consumers can import
 * from the canonical path specified in the build map.
 */

export {
  IntelligentMeshRouter,
  StoreForwardQueue,
} from "./maurimesh-intelligent-contract";

export type {
  MeshNode,
  MeshPacket,
  RouteScore,
  MeshLane,
  MeshPacketType,
  PacketType,
  TrustState,
} from "./maurimesh-intelligent-contract";
