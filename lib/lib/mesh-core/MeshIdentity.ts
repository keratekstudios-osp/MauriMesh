import { NodeStatus, type MeshNode } from "./types";

function generateUuid(): string {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

function generateDisplayName(): string {
  const prefixes = ["Node", "Relay", "Mesh", "Pulse", "Core"];
  const suffixes = [
    "Alpha", "Beta", "Gamma", "Delta", "Echo",
    "Foxtrot", "Zeta", "Eta", "Theta", "Iota",
  ];
  const prefix = prefixes[Math.floor(Math.random() * prefixes.length)];
  const suffix = suffixes[Math.floor(Math.random() * suffixes.length)];
  return `${prefix}-${suffix}`;
}

let _identity: MeshNode | null = null;

export function getOrCreateIdentity(): MeshNode {
  if (_identity) return _identity;
  _identity = {
    nodeId: generateUuid(),
    displayName: generateDisplayName(),
    status: NodeStatus.SELF,
    lastSeenAt: Date.now(),
    trustScore: 100,
  };
  return _identity;
}

export function getNodeId(): string {
  return getOrCreateIdentity().nodeId;
}

export function resetIdentity(): void {
  _identity = null;
}
