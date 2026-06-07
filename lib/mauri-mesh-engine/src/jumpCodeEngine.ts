import { MeshPacket, MeshPeer, TransportKind } from "./types";

function fnv1a(input: string): string {
  let hash = 0x811c9dc5;
  for (let i = 0; i < input.length; i++) {
    hash ^= input.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193);
  }
  return (hash >>> 0).toString(16).padStart(8, "0").toUpperCase();
}

export function createJumpCode(parts: {
  from: string;
  to: string;
  transport: TransportKind;
  epochBucket?: number;
  routeHint?: string;
}): string {
  const bucket = parts.epochBucket ?? Math.floor(Date.now() / 30000);
  const raw = [
    "MAURIMESH",
    parts.from,
    parts.to,
    parts.transport,
    bucket,
    parts.routeHint ?? "DIRECT",
  ].join(":");

  const hash = fnv1a(raw);
  return `JM-${parts.transport.toUpperCase().replace(/-/g, "_")}-${hash.slice(0, 4)}-${hash.slice(4, 8)}`;
}

export function scoreJumpCompatibility(packet: MeshPacket, peer: MeshPeer): number {
  let score = 0;

  if (packet.to === peer.id) score += 40;
  if (packet.jumpCode.includes(peer.transport.toUpperCase().replace(/-/g, "_"))) score += 20;
  if (!packet.path.includes(peer.id)) score += 20;
  if (peer.status === "online") score += 10;
  if (peer.status === "relay") score += 8;
  if (peer.status === "weak") score -= 10;
  if (peer.status === "blocked") score -= 100;

  return Math.max(0, Math.min(100, score));
}

export function explainJumpCode(code: string): string {
  const parts = code.split("-");
  if (parts.length < 4) return "Invalid JumpCode format.";
  return `JumpCode ${code} identifies a deterministic MauriMesh route-handoff intent for ${parts[1]} transport.`;
}
