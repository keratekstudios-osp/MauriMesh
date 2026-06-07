import AsyncStorage from "@react-native-async-storage/async-storage";
import type { FriendInvitePayload, MauriFriend } from "./friendTypes";

const FRIENDS_KEY = "maurimesh.friends.v1";

export async function getFriends(): Promise<MauriFriend[]> {
  const raw = await AsyncStorage.getItem(FRIENDS_KEY);
  return raw ? (JSON.parse(raw) as MauriFriend[]) : [];
}

export async function addFriendFromInvite(
  invite: FriendInvitePayload,
  source: "qr" | "network"
): Promise<MauriFriend[]> {
  const friends = await getFriends();

  const exists = friends.some(
    (f) => f.userId === invite.userId || f.nodeId === invite.nodeId
  );

  if (exists) return friends;

  const next: MauriFriend = {
    userId: invite.userId,
    displayName: invite.displayName,
    nodeId: invite.nodeId,
    publicKey: invite.publicKey,
    status: "added",
    source,
    addedAt: Date.now(),
  };

  const updated = [next, ...friends];
  await AsyncStorage.setItem(FRIENDS_KEY, JSON.stringify(updated));
  return updated;
}

export async function removeFriend(nodeId: string): Promise<MauriFriend[]> {
  const friends = await getFriends();
  const updated = friends.filter((f) => f.nodeId !== nodeId);
  await AsyncStorage.setItem(FRIENDS_KEY, JSON.stringify(updated));
  return updated;
}
