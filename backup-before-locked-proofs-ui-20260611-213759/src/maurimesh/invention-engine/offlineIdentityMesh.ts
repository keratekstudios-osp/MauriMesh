import { MeshNode, TrustLevel } from "./types";
import { nowMs } from "./utils";

export type MeshIdentity = {
  deviceId: string;
  publicKey: string;
  displayName: string;
  trust: TrustLevel;
  createdAtMs: number;
  rotatedAtMs: number;
};

export class OfflineFirstIdentityMesh {
  private identities = new Map<string, MeshIdentity>();

  createIdentity(displayName: string): MeshIdentity {
    const id = `mmid-${Math.random().toString(36).slice(2)}-${Date.now()}`;
    const identity: MeshIdentity = {
      deviceId: id,
      publicKey: `pub-${id}`,
      displayName,
      trust: "OBSERVED",
      createdAtMs: nowMs(),
      rotatedAtMs: nowMs(),
    };
    this.identities.set(id, identity);
    return identity;
  }

  registerNodeIdentity(node: MeshNode): MeshIdentity {
    const existing = this.identities.get(node.id);
    if (existing) return existing;

    const identity: MeshIdentity = {
      deviceId: node.id,
      publicKey: `pub-${node.id}`,
      displayName: node.label || node.id,
      trust: node.trust,
      createdAtMs: nowMs(),
      rotatedAtMs: nowMs(),
    };

    this.identities.set(node.id, identity);
    return identity;
  }

  verifyKnownIdentity(deviceId: string): boolean {
    const identity = this.identities.get(deviceId);
    return Boolean(identity && identity.trust !== "BLOCKED");
  }

  promoteTrust(deviceId: string, trust: TrustLevel): void {
    const identity = this.identities.get(deviceId);
    if (!identity) return;
    identity.trust = trust;
  }

  listIdentities(): MeshIdentity[] {
    return Array.from(this.identities.values());
  }
}
