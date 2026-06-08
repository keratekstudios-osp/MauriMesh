export const TASK_192_API_CONFIG_HELPER_MARKER =
  "TASK_192_API_CONFIG_HELPER_20260608_A";

export function getConfiguredMeshApiUrl(): string {
  return (
    process.env.EXPO_PUBLIC_MESH_API_URL ||
    process.env.REACT_APP_MESH_API_URL ||
    ""
  ).trim();
}

export function getApiConfigStatus() {
  const url = getConfiguredMeshApiUrl();

  return {
    marker: TASK_192_API_CONFIG_HELPER_MARKER,
    configured: Boolean(url),
    url,
    message: url
      ? "Mesh API URL configured."
      : "Mesh API URL not configured. Set EXPO_PUBLIC_MESH_API_URL in EAS/Replit environment.",
  };
}
