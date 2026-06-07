export type FriendInvitePayload = {
  type: "MAURIMESH_FRIEND_INVITE";
  version: 1;
  userId: string;
  displayName: string;
  nodeId: string;
  publicKey: string;
  createdAt: number;
};

export type MauriFriend = {
  userId: string;
  displayName: string;
  nodeId: string;
  publicKey: string;
  status: "pending" | "added" | "blocked";
  source: "qr" | "network";
  addedAt: number;
};
