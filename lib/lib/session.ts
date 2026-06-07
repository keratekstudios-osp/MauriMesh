import AsyncStorage from "@react-native-async-storage/async-storage";

export const SESSION_KEY = "maurimesh.session.active";

export async function setSessionActive() {
  await AsyncStorage.setItem(SESSION_KEY, "true");
}

export async function clearSession() {
  await AsyncStorage.removeItem(SESSION_KEY);
}

export async function isSessionActive() {
  return (await AsyncStorage.getItem(SESSION_KEY)) === "true";
}
