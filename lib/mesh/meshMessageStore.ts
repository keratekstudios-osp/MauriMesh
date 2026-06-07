export type StoredMeshMessage = {
  id?: string;
  text?: string;
  body?: string;
  sender?: string;
  createdAt?: number;
};

export async function loadMeshMessages(): Promise<StoredMeshMessage[]> {
  return [];
}

export async function saveMeshMessage(_message: StoredMeshMessage) {
  return true;
}

export function storedToChatMessage(message: StoredMeshMessage) {
  return {
    id: message.id || String(Date.now()),
    text: message.text || message.body || "",
    sender: message.sender || "mesh",
    createdAt: message.createdAt || Date.now(),
  };
}

export function chatMessageToStored(message: any): StoredMeshMessage {
  return message;
}
