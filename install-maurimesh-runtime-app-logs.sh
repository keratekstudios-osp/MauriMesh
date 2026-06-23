#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "INSTALL MAURIMESH RUNTIME APP LOGS"
echo "Adds: runtime logger + Runtime Logs screen + dashboard button"
echo "No EAS build in this script."
echo "============================================================"
echo ""

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="backup-before-runtime-app-logs-$STAMP"
mkdir -p "$BACKUP"
cp -R app "$BACKUP/app" 2>/dev/null || true
cp -R src "$BACKUP/src" 2>/dev/null || true

mkdir -p src/maurimesh/runtime

cat > src/maurimesh/runtime/runtimeLog.ts <<'TS'
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
TS

cat > app/runtime-logs.tsx <<'TSX'
import React, { useEffect, useMemo, useState } from "react";
import {
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useRouter } from "expo-router";
import { AppShell } from "../src/components/AppShell";
import { MauriPageHeader } from "../src/components/MauriPageHeader";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";
import {
  clearRuntimeLogs,
  getRuntimeLogs,
  markScreenOpen,
  recordRuntimeLog,
  runtimeLogText,
  subscribeRuntimeLogs,
  MauriRuntimeLogEvent,
} from "../src/maurimesh/runtime/runtimeLog";

export default function RuntimeLogsScreen() {
  const router = useRouter();
  const [events, setEvents] = useState<MauriRuntimeLogEvent[]>(() => getRuntimeLogs());

  useEffect(() => {
    markScreenOpen("Runtime Logs", { route: "/runtime-logs" });
    return subscribeRuntimeLogs(setEvents);
  }, []);

  const report = useMemo(() => runtimeLogText(), [events]);

  const stats = useMemo(() => {
    const pass = events.filter((e) => e.level === "PASS").length;
    const fail = events.filter((e) => e.level === "FAIL").length;
    const proof = events.filter((e) => e.level === "PROOF").length;
    const nav = events.filter((e) => e.level === "NAV").length;
    return { total: events.length, pass, fail, proof, nav };
  }, [events]);

  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="MAURIMESH RUNTIME"
        title="App Logs"
        subtitle="Live in-app runtime events, screen opens, button presses, proof notes, and exportable report block."
        tone="success"
      />

      <View style={styles.card}>
        <Text style={styles.title}>Runtime Status</Text>
        <View style={styles.row}>
          <StatusPill label={`${stats.total} EVENTS`} tone="success" />
          <StatusPill label={`${stats.pass} PASS`} tone="success" />
          <StatusPill label={`${stats.fail} FAIL`} tone={stats.fail > 0 ? "danger" : "neutral"} />
        </View>
        <Text style={styles.text}>
          Open every proof and feature screen. This logger records app runtime movement so the APK can prove which screens were reached without crashing.
        </Text>
      </View>

      <View style={styles.actions}>
        <TouchableOpacity
          style={styles.button}
          onPress={() => {
            recordRuntimeLog("PROOF", "manual.runtime", "Manual runtime checkpoint recorded");
          }}
        >
          <Text style={styles.buttonText}>Add Runtime Checkpoint</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.button}
          onPress={() => {
            clearRuntimeLogs();
          }}
        >
          <Text style={styles.buttonText}>Clear Logs</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.button}
          onPress={() => {
            recordRuntimeLog("NAV", "runtime.logs", "Return to dashboard pressed");
            router.replace("/dashboard");
          }}
        >
          <Text style={styles.buttonText}>Back to Dashboard</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.card}>
        <Text style={styles.title}>Copyable Runtime Report</Text>
        <Text style={styles.text}>
          Long-press inside the box, select all, copy, then paste into ChatGPT or your proof archive.
        </Text>
        <TextInput
          value={report}
          multiline
          editable={false}
          selectTextOnFocus
          style={styles.logBox}
        />
      </View>

      <View style={styles.card}>
        <Text style={styles.title}>Latest Events</Text>
        <ScrollView style={styles.eventList} nestedScrollEnabled>
          {events.slice(0, 80).map((event) => (
            <View key={event.id} style={styles.event}>
              <Text style={styles.eventMeta}>
                {event.level} · {event.scope}
              </Text>
              <Text style={styles.eventMsg}>{event.message}</Text>
              <Text style={styles.eventTs}>{event.ts}</Text>
            </View>
          ))}
        </ScrollView>
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.25)",
    backgroundColor: "rgba(2,12,8,0.86)",
    borderRadius: 22,
    padding: 16,
    marginBottom: 14,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 18,
    fontWeight: "900",
    marginBottom: 8,
  },
  text: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 13,
    lineHeight: 19,
  },
  row: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
    marginBottom: 10,
  },
  actions: {
    gap: 10,
    marginBottom: 14,
  },
  button: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    paddingVertical: 13,
    paddingHorizontal: 14,
    alignItems: "center",
  },
  buttonText: {
    color: "#001F14",
    fontWeight: "900",
  },
  logBox: {
    minHeight: 260,
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.32)",
    borderRadius: 14,
    padding: 12,
    color: "#D8FFE9",
    backgroundColor: "rgba(0,0,0,0.45)",
    fontSize: 11,
    lineHeight: 16,
    marginTop: 12,
  },
  eventList: {
    maxHeight: 420,
  },
  event: {
    borderBottomWidth: 1,
    borderBottomColor: "rgba(255,255,255,0.08)",
    paddingVertical: 10,
  },
  eventMeta: {
    color: "#00D084",
    fontSize: 11,
    fontWeight: "900",
  },
  eventMsg: {
    color: mauriTheme.colors.white,
    fontSize: 13,
    fontWeight: "700",
    marginTop: 3,
  },
  eventTs: {
    color: "rgba(255,255,255,0.45)",
    fontSize: 10,
    marginTop: 3,
  },
});
TSX

echo ""
echo "[1] Patch app/_layout.tsx to mark app boot if possible"
python3 <<'PY'
from pathlib import Path

p = Path("app/_layout.tsx")
if p.exists():
    text = p.read_text()
    if "../src/maurimesh/runtime/runtimeLog" not in text:
        lines = text.splitlines(True)
        insert_at = 0
        while insert_at < len(lines) and lines[insert_at].startswith("import "):
            insert_at += 1
        lines.insert(insert_at, 'import { markAppBoot } from "../src/maurimesh/runtime/runtimeLog";\n')
        text = "".join(lines)

    if "markAppBoot(" not in text:
        marker = "export default function"
        if marker in text:
            text = text.replace(
                marker,
                'markAppBoot("app/_layout.tsx");\n\n' + marker,
                1
            )
    p.write_text(text)
    print("Patched app/_layout.tsx")
else:
    print("WARN: app/_layout.tsx not found")
PY

echo ""
echo "[2] Patch MauriButton to log button presses if possible"
python3 <<'PY'
from pathlib import Path
import re

p = Path("src/components/MauriButton.tsx")
if not p.exists():
    print("WARN: MauriButton not found")
    raise SystemExit(0)

text = p.read_text()

if "../maurimesh/runtime/runtimeLog" not in text:
    lines = text.splitlines(True)
    insert_at = 0
    while insert_at < len(lines) and lines[insert_at].startswith("import "):
        insert_at += 1
    lines.insert(insert_at, 'import { markButtonPress } from "../maurimesh/runtime/runtimeLog";\n')
    text = "".join(lines)

# Conservative patch: replace direct onPress={onPress} with wrapper.
text = text.replace(
    "onPress={onPress}",
    "onPress={() => { markButtonPress(title || \"MauriButton\"); onPress?.(); }}"
)

p.write_text(text)
print("Patched MauriButton")
PY

echo ""
echo "[3] Add Runtime Logs button to dashboard"
python3 <<'PY'
from pathlib import Path

p = Path("app/dashboard.tsx")
if not p.exists():
    print("WARN: dashboard not found")
    raise SystemExit(0)

text = p.read_text()

button = '''
        <SafeNavButton
          title="Runtime App Logs"
          route="/runtime-logs"
          label="Runtime App Logs"
        />
'''

if "/runtime-logs" in text:
    print("Dashboard already has Runtime Logs button")
else:
    # Put it near Full App Test if possible, otherwise before first closing AppShell.
    if 'title="Full App Test"' in text:
        idx = text.find('title="Full App Test"')
        start = text.rfind("<SafeNavButton", 0, idx)
        if start != -1:
            text = text[:start] + button + text[start:]
        else:
            text = text.replace("</AppShell>", button + "\n    </AppShell>", 1)
    else:
        text = text.replace("</AppShell>", button + "\n    </AppShell>", 1)

    p.write_text(text)
    print("Added Runtime Logs button to dashboard")
PY

echo ""
echo "[4] TypeScript check"
npx tsc --noEmit

echo ""
echo "[5] Local Android JS bundle/export check"
npx expo export --platform android --clear

echo ""
echo "============================================================"
echo "PASS: MAURIMESH RUNTIME APP LOGS INSTALLED"
echo "============================================================"
echo "Route added:"
echo "/runtime-logs"
echo ""
echo "Next build command:"
echo "npx eas-cli build --platform android --profile preview-apk --clear-cache"
echo ""
echo "Backup:"
echo "$BACKUP"
echo "============================================================"
