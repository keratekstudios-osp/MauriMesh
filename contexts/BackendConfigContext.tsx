import React from "react";

export function BackendConfigProvider({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}

export function useBackendConfig() {
  return { backendUrl: "", setBackendUrl: () => {} };
}

export default BackendConfigProvider;
