import {
  ackLastRoute,
  failLastRoute,
  getUiEngineSnapshot,
  resetUiEngineDemo,
  runDemoMessage,
  sendUiMessage,
  UiEngineSnapshot,
} from "../maurimesh/ui/mauriUiEngine";

export type InventionEngineMode = "LOCAL_ENGINE";

export async function getInventionEngineStatus(): Promise<UiEngineSnapshot> {
  return getUiEngineSnapshot();
}

export async function runInventionDemo(body?: string): Promise<UiEngineSnapshot> {
  runDemoMessage(body);
  return getUiEngineSnapshot();
}

export async function sendMessageThroughInventionEngine(body: string): Promise<UiEngineSnapshot> {
  sendUiMessage({ body });
  return getUiEngineSnapshot();
}

export async function ackInventionRoute(): Promise<UiEngineSnapshot> {
  ackLastRoute();
  return getUiEngineSnapshot();
}

export async function failInventionRoute(): Promise<UiEngineSnapshot> {
  failLastRoute();
  return getUiEngineSnapshot();
}

export async function resetInventionEngine(): Promise<UiEngineSnapshot> {
  return resetUiEngineDemo();
}
