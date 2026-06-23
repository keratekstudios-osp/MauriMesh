import { useEffect, useState } from "react";
import {
  AllIntegrationsSnapshot,
  getAllIntegrationsSnapshot,
} from "./allIntegrationsBridge";

export const TASK_191_USE_ALL_INTEGRATIONS_MARKER =
  "TASK_191_USE_ALL_INTEGRATIONS_20260608_A";

export function useAllIntegrations(pollMs = 1500) {
  const [snapshot, setSnapshot] = useState<AllIntegrationsSnapshot | null>(null);

  useEffect(() => {
    let alive = true;

    async function load() {
      const next = await getAllIntegrationsSnapshot();
      if (alive) setSnapshot(next);
    }

    load();
    const timer = setInterval(load, pollMs);

    return () => {
      alive = false;
      clearInterval(timer);
    };
  }, [pollMs]);

  return {
    marker: TASK_191_USE_ALL_INTEGRATIONS_MARKER,
    snapshot,
  };
}
