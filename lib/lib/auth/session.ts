import AsyncStorage from "@react-native-async-storage/async-storage";

const SESSION_KEY = "@maurimesh/session/v1";
const CREDENTIALS_KEY = "@maurimesh/credentials/v1";

export interface MauriSession {
  username: string;
  loggedInAt: number;
}

interface StoredCredentials {
  username: string;
  passphrase: string;
}

export async function getSession(): Promise<MauriSession | null> {
  try {
    const raw = await AsyncStorage.getItem(SESSION_KEY);
    return raw ? (JSON.parse(raw) as MauriSession) : null;
  } catch {
    return null;
  }
}

export async function saveSession(username: string): Promise<void> {
  const session: MauriSession = { username, loggedInAt: Date.now() };
  await AsyncStorage.setItem(SESSION_KEY, JSON.stringify(session));
}

export async function clearSession(): Promise<void> {
  await AsyncStorage.removeItem(SESSION_KEY);
}

export async function getCredentials(): Promise<StoredCredentials | null> {
  try {
    const raw = await AsyncStorage.getItem(CREDENTIALS_KEY);
    return raw ? (JSON.parse(raw) as StoredCredentials) : null;
  } catch {
    return null;
  }
}

export async function registerAccount(
  username: string,
  passphrase: string
): Promise<void> {
  const creds: StoredCredentials = { username: username.trim().toLowerCase(), passphrase };
  await AsyncStorage.setItem(CREDENTIALS_KEY, JSON.stringify(creds));
  await saveSession(username.trim());
}

export async function loginAccount(
  username: string,
  passphrase: string
): Promise<boolean> {
  const creds = await getCredentials();
  if (!creds) return false;
  const match =
    creds.username === username.trim().toLowerCase() &&
    creds.passphrase === passphrase;
  if (match) await saveSession(username.trim());
  return match;
}

export async function accountExists(): Promise<boolean> {
  const creds = await getCredentials();
  return creds !== null;
}

export async function deleteAccount(): Promise<void> {
  await AsyncStorage.multiRemove([SESSION_KEY, CREDENTIALS_KEY]);
}
