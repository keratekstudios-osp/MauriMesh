export function useMeshTransport() {
  return {
    isReady: false,
    peers: [],
    sendMessage: async () => false,
    start: async () => false,
    stop: async () => true,
  };
}
