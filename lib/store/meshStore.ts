export type ChatMessage = {
  id: string;
  text?: string;
  body?: string;
  sender?: string;
  createdAt?: number;
};

export function useMeshStore() {
  return {
    messages: [],
    addMessage: () => {},
    sendMessage: () => {},
    clearMessages: () => {},
  };
}
