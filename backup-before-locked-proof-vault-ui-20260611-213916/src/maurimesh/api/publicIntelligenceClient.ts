const API_BASE =
  process.env.EXPO_PUBLIC_API_BASE_URL ||
  process.env.EXPO_PUBLIC_BACKEND_BASE_URL ||
  process.env.EXPO_PUBLIC_MESH_API_URL ||
  "";

function baseUrl(): string {
  return String(API_BASE || "")
    .trim()
    .replace(/\/+$/, "")
    .replace(/\/api$/, "");
}

async function json(response: Response) {
  const text = await response.text();
  const data = text ? JSON.parse(text) : null;

  if (!response.ok) {
    throw new Error(`MauriMesh public intelligence API failed ${response.status}: ${text}`);
  }

  return data;
}

export async function getPublicMeshActivity() {
  return json(await fetch(`${baseUrl()}/api/mesh-public/activity`));
}

export async function ingestPublicMeshActivity(event: Record<string, unknown>) {
  return json(
    await fetch(`${baseUrl()}/api/mesh-public/activity/ingest`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json"
      },
      body: JSON.stringify(event)
    })
  );
}

export async function getPublicPacketDecision(packet: Record<string, unknown>) {
  return json(
    await fetch(`${baseUrl()}/api/mesh-public/packet/decision`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json"
      },
      body: JSON.stringify(packet)
    })
  );
}
