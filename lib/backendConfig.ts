export async function pingBackend(url?: string) {
  return {
    ok: false,
    url: url || "",
    status: "offline",
  };
}

export async function saveBackendConfig(_config: any) {
  return true;
}

export async function loadBackendConfig() {
  return {
    url: "",
    status: "offline",
  };
}
