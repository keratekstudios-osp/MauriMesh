export function useBleReadiness() {
  return {
    ready: false,
    bluetooth: false,
    permissions: false,
    location: false,
    status: "offline",
  };
}
