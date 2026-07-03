export const MAURIMESH_BACKEND_BASE_URL =
  process.env.EXPO_PUBLIC_BACKEND_BASE_URL ||
  process.env.VITE_BACKEND_BASE_URL ||
  "https://mauri-mesh-messenger.replit.app";

export const MAURIMESH_API_BASE_URL =
  process.env.EXPO_PUBLIC_API_BASE_URL ||
  process.env.VITE_API_BASE_URL ||
  process.env.API_BASE_URL ||
  "https://mauri-mesh-messenger.replit.app/api";

export function getMauriMeshApiBaseUrl(): string {
  return MAURIMESH_API_BASE_URL.replace(/\/$/, "");
}

export function getMauriMeshBackendBaseUrl(): string {
  return MAURIMESH_BACKEND_BASE_URL.replace(/\/$/, "");
}

export function buildMauriMeshApiUrl(path: string): string {
  const cleanPath = path.startsWith("/") ? path : `/${path}`;
  return `${getMauriMeshApiBaseUrl()}${cleanPath}`;
}
