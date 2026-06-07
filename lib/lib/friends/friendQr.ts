import type { FriendInvitePayload } from "./friendTypes";

export function createFriendInvite(input: {
  userId: string;
  displayName: string;
  nodeId: string;
  publicKey: string;
}): FriendInvitePayload {
  return {
    type: "MAURIMESH_FRIEND_INVITE",
    version: 1,
    userId: input.userId,
    displayName: input.displayName,
    nodeId: input.nodeId,
    publicKey: input.publicKey,
    createdAt: Date.now(),
  };
}

export function parseFriendInvite(raw: string): FriendInvitePayload {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new Error("Invalid QR code — not valid JSON");
  }

  if (
    !parsed ||
    typeof parsed !== "object" ||
    (parsed as Record<string, unknown>).type !== "MAURIMESH_FRIEND_INVITE"
  ) {
    throw new Error("Not a MauriMesh friend QR code");
  }

  const p = parsed as Record<string, unknown>;
  if (!p.userId || !p.nodeId || !p.publicKey) {
    throw new Error("Friend QR is missing required identity fields");
  }

  return parsed as FriendInvitePayload;
}
