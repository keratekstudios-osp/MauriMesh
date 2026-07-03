import { deterministicHash } from "../proof/hashEngine";

export type SecurityAssessment = {
  ok: boolean;
  reason: string;
  threats: string[];
};

export function createDeviceIdentity(seed: string): string {
  return `device_${deterministicHash({ seed, purpose: "mauricore_device_identity" })}`;
}

export function createPacketSignature(packetHash: string, deviceId: string): string {
  return deterministicHash({
    packetHash,
    deviceId,
    warning: "development_signature_replace_with_native_crypto",
  });
}

export function verifyPacketSignature(packetHash: string, deviceId: string, signature: string): boolean {
  return createPacketSignature(packetHash, deviceId) === signature;
}

export function detectSecurityThreats(input: {
  replay?: boolean;
  duplicatePacket?: boolean;
  unknownRelay?: boolean;
  identityMismatch?: boolean;
  memoryPoisoning?: boolean;
  unsafePermissionChange?: boolean;
}): SecurityAssessment {
  const threats: string[] = [];

  if (input.replay) threats.push("replay_attack");
  if (input.duplicatePacket) threats.push("duplicate_packet");
  if (input.unknownRelay) threats.push("unknown_relay");
  if (input.identityMismatch) threats.push("identity_mismatch");
  if (input.memoryPoisoning) threats.push("memory_poisoning");
  if (input.unsafePermissionChange) threats.push("unsafe_permission_change");

  return {
    ok: threats.length === 0,
    reason: threats.length === 0 ? "No security threats detected." : "Security threats require block or review.",
    threats,
  };
}
