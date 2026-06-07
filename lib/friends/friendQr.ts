export function parseFriendInvite(value: string) {
  try {
    return JSON.parse(value);
  } catch {
    return { raw: value };
  }
}
