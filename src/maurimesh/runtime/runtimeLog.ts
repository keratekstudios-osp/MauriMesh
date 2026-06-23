export type MauriRuntimeLogLevel = "INFO" | "PASS" | "WARN" | "FAIL" | "PROOF" | "NAV" | "BUTTON";

export type MauriRuntimeLogEvent = {
  id: string;
  ts: string;
  level: MauriRuntimeLogLevel;
  scope: string;
  message: string;
  data?: Record<string, unknown>;
};

const MAX_LOGS = 600;

let logs: MauriRuntimeLogEvent[] = [];
const listeners = new Set<(events: MauriRuntimeLogEvent[]) => void>();

function safeData(data?: Record<string, unknown>) {
  if (!data) return undefined;
  try {
    return JSON.parse(JSON.stringify(data));
  } catch {
    return { note: "unserializable_data" };
  }
}

export function recordRuntimeLog(
  level: MauriRuntimeLogLevel,
  scope: string,
  message: string,
  data?: Record<string, unknown>
): MauriRuntimeLogEvent {
  const event: MauriRuntimeLogEvent = {
    id: `MMLOG-${Date.now()}-${Math.random().toString(36).slice(2, 8).toUpperCase()}`,
    ts: new Date().toISOString(),
    level,
    scope,
    message,
    data: safeData(data),
  };

  logs = [event, ...logs].slice(0, MAX_LOGS);

  try {
    const line = `[MAURIMESH_RUNTIME_LOG] ${event.ts} ${event.level} ${event.scope} ${event.message}`;
    if (event.level === "FAIL") console.error(line, event.data || "");
    else if (event.level === "WARN") console.warn(line, event.data || "");
    else console.log(line, event.data || "");
  } catch {}

  for (const listener of listeners) {
    try {
      listener([...logs]);
    } catch {}
  }

  return event;
}

export function getRuntimeLogs(): MauriRuntimeLogEvent[] {
  return [...logs];
}

export function clearRuntimeLogs() {
  logs = [];
  recordRuntimeLog("INFO", "runtime.logs", "Runtime logs cleared");
}

export function subscribeRuntimeLogs(listener: (events: MauriRuntimeLogEvent[]) => void) {
  listeners.add(listener);
  listener([...logs]);
  return () => {
    listeners.delete(listener);
  };
}

export function runtimeLogText(): string {
  const header = [
    "============================================================",
    "MAURIMESH APK RUNTIME LOG REPORT",
    "============================================================",
    `Generated: ${new Date().toISOString()}`,
    `Events: ${logs.length}`,
    "Truth: These are in-app runtime events. BLE proof still requires physical-device packet/ACK logs.",
    "============================================================",
    "",
  ].join("\n");

  const body = logs
    .map((e, index) => {
      const data = e.data ? `\nDATA: ${JSON.stringify(e.data)}` : "";
      return `${String(index + 1).padStart(3, "0")} | ${e.ts} | ${e.level} | ${e.scope} | ${e.message}${data}`;
    })
    .join("\n\n");

  return `${header}${body || "No runtime events recorded yet."}\n`;
}

export function markAppBoot(source = "unknown") {
  recordRuntimeLog("INFO", "app.boot", "MauriMesh app runtime boot observed", { source });
}

export function markScreenOpen(screen: string, data?: Record<string, unknown>) {
  recordRuntimeLog("NAV", "screen.open", screen, data);
}

export function markButtonPress(title: string, data?: Record<string, unknown>) {
  recordRuntimeLog("BUTTON", "button.press", title, data);
}

export function markProofEvent(message: string, data?: Record<string, unknown>) {
  recordRuntimeLog("PROOF", "proof.event", message, data);
}

export function markPass(scope: string, message: string, data?: Record<string, unknown>) {
  recordRuntimeLog("PASS", scope, message, data);
}

export function markFail(scope: string, message: string, data?: Record<string, unknown>) {
  recordRuntimeLog("FAIL", scope, message, data);
}

recordRuntimeLog("INFO", "runtime.logger", "Runtime logger module loaded");
