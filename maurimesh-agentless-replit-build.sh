#!/usr/bin/env bash
set -e

echo "=================================================="
echo "MAURIMESH AGENTLESS REPLIT BUILD"
echo "Shell-only repair + UI/API scaffold"
echo "=================================================="

ROOT="$(pwd)"
BACKUP="$ROOT/backup-before-agentless-$(date +%Y%m%d-%H%M%S)"

echo ""
echo "1. Backup existing protected files"
mkdir -p "$BACKUP"

for path in app src server package.json tsconfig.json .env.example; do
  if [ -e "$ROOT/$path" ]; then
    cp -R "$ROOT/$path" "$BACKUP/" || true
  fi
done

echo "Backup saved to: $BACKUP"

echo ""
echo "2. Create required folders"
mkdir -p app src/components src/theme src/lib server scripts

echo ""
echo "3. Install required packages"

if [ -f pnpm-lock.yaml ]; then
  echo "Using pnpm"
  npm install -g pnpm || true
  pnpm install || true
  pnpm add express cors dotenv expo-router expo-status-bar expo-constants react-native-safe-area-context react-native-screens || true
  pnpm add -D typescript tsx @types/node @types/react @types/express || true
else
  echo "Using npm"
  npm install --legacy-peer-deps || true
  npm install --legacy-peer-deps express cors dotenv expo-router expo-status-bar expo-constants react-native-safe-area-context react-native-screens
  npm install --legacy-peer-deps -D typescript tsx @types/node @types/react @types/express
fi

echo ""
echo "4. Update package.json scripts safely"
node <<'NODE'
const fs = require("fs");
const path = "package.json";

if (!fs.existsSync(path)) {
  fs.writeFileSync(path, JSON.stringify({
    scripts: {},
    dependencies: {},
    devDependencies: {}
  }, null, 2));
}

const pkg = JSON.parse(fs.readFileSync(path, "utf8"));
pkg.scripts = pkg.scripts || {};

pkg.scripts.start = pkg.scripts.start || "expo start --web";
pkg.scripts.dev = pkg.scripts.dev || "expo start --web";
pkg.scripts.web = pkg.scripts.web || "expo start --web";
pkg.scripts.typecheck = "tsc --noEmit";
pkg.scripts.check = "tsc --noEmit";
pkg.scripts.api = "tsx server/index.ts";

fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
NODE

echo ""
echo "5. Create tsconfig.json if missing"
if [ ! -f tsconfig.json ]; then
cat > tsconfig.json <<'TS'
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": false,
    "baseUrl": ".",
    "jsx": "react-jsx",
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": [
    "**/*.ts",
    "**/*.tsx",
    ".expo/types/**/*.ts",
    "expo-env.d.ts"
  ]
}
TS
fi

echo ""
echo "6. Create MauriMesh theme"
cat > src/theme/mauriTheme.ts <<'TS'
export const mauriTheme = {
  colors: {
    black: "#020403",
    deepBlack: "#000000",
    navy: "#020617",
    greenstone: "#00D084",
    emerald: "#10B981",
    jade: "#22C55E",
    blueWeb: "#38BDF8",
    white: "#FFFFFF",
    mutedWhite: "rgba(255,255,255,0.72)",
    softWhite: "rgba(255,255,255,0.12)",
    danger: "#EF4444",
    warning: "#F59E0B",
    success: "#22C55E",
    panel: "rgba(2,12,8,0.84)",
    panelSoft: "rgba(255,255,255,0.06)",
    panelBorder: "rgba(34,197,94,0.28)"
  },
  radius: {
    sm: 10,
    md: 16,
    lg: 24,
    xl: 32
  },
  spacing: {
    xs: 6,
    sm: 10,
    md: 16,
    lg: 24,
    xl: 36
  }
};
TS

echo ""
echo "7. Create API client + mesh simulation"
cat > src/lib/api.ts <<'TS'
const DEFAULT_TIMEOUT_MS = 6000;

export type ApiResult<T> =
  | { ok: true; data: T; source: "live" }
  | { ok: false; error: string; source: "unavailable" };

export const API_BASE =
  process.env.EXPO_PUBLIC_MESH_API_URL ||
  process.env.REACT_APP_MESH_API_URL ||
  "";

export async function apiGet<T>(
  path: string,
  timeoutMs = DEFAULT_TIMEOUT_MS
): Promise<ApiResult<T>> {
  if (result.ok) {
    return {
      mode: "LIVE",
      message: "Connected to Mesh API.",
      nodes: result.data.nodes || [],
      routes: result.data.routes || []
    };
  }

  return {
    mode: "SIMULATION",
    message: "Mesh API unavailable in Replit preview. Showing labelled simulation only.",
    nodes: simulatedNodes,
    routes: simulatedRoutes
  };
}
TS
cat >> maurimesh-agentless-replit-build.sh <<'EOF'

echo ""
echo "8. Create reusable UI components"

cat > src/components/AppShell.tsx <<'TSX'
import React from "react";
import { SafeAreaView, ScrollView, StyleSheet, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function AppShell({
  children,
  scroll = true
}: {
  children: React.ReactNode;
  scroll?: boolean;
}) {
  const content = <View style={styles.content}>{children}</View>;

  return (
    <SafeAreaView style={styles.safe}>
      {scroll ? <ScrollView>{content}</ScrollView> : content}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: mauriTheme.colors.black
  },
  content: {
    flex: 1,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.md
  }
});
TSX

cat > src/components/MauriButton.tsx <<'TSX'
import React from "react";
import { Pressable, StyleSheet, Text } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function MauriButton({
  title,
  onPress,
  variant = "primary"
}: {
  title: string;
  onPress: () => void;
  variant?: "primary" | "secondary" | "danger";
}) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.base,
        variant === "primary" && styles.primary,
        variant === "secondary" && styles.secondary,
        variant === "danger" && styles.danger,
        pressed && { opacity: 0.76, transform: [{ scale: 0.98 }] }
      ]}
    >
      <Text style={styles.text}>{title}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    minHeight: 52,
    borderRadius: mauriTheme.radius.lg,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: mauriTheme.spacing.lg,
    borderWidth: 1
  },
  primary: {
    backgroundColor: mauriTheme.colors.greenstone,
    borderColor: mauriTheme.colors.greenstone
  },
  secondary: {
    backgroundColor: mauriTheme.colors.panel,
    borderColor: mauriTheme.colors.panelBorder
  },
  danger: {
    backgroundColor: "rgba(239,68,68,0.16)",
    borderColor: "rgba(239,68,68,0.5)"
  },
  text: {
    color: mauriTheme.colors.white,
    fontSize: 16,
    fontWeight: "800"
  }
});
TSX

cat > src/components/StatusPill.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function StatusPill({
  label,
  tone = "success"
}: {
  label: string;
  tone?: "success" | "warning" | "danger" | "info";
}) {
  const color =
    tone === "success"
      ? mauriTheme.colors.success
      : tone === "warning"
        ? mauriTheme.colors.warning
        : tone === "danger"
          ? mauriTheme.colors.danger
          : mauriTheme.colors.blueWeb;

  return (
    <View style={[styles.pill, { borderColor: color }]}>
      <Text style={[styles.text, { color }]}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  pill: {
    alignSelf: "flex-start",
    borderWidth: 1,
    borderRadius: 999,
    paddingVertical: 6,
    paddingHorizontal: 12,
    backgroundColor: "rgba(255,255,255,0.05)"
  },
  text: {
    fontWeight: "800",
    fontSize: 12,
    letterSpacing: 0.6
  }
});
TSX

cat > src/components/MeshSignalCard.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function MeshSignalCard({
  title,
  value,
  status
}: {
  title: string;
  value: string;
  status: "LIVE" | "SIMULATION" | "UNAVAILABLE";
}) {
  return (
    <View style={styles.card}>
      <StatusPill
        label={status}
        tone={status === "LIVE" ? "success" : status === "SIMULATION" ? "warning" : "danger"}
      />
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.value}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 18,
    fontWeight: "900"
  },
  value: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 14,
    lineHeight: 20
  }
});
TSX

cat > src/components/ChatBubble.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function ChatBubble({
  text,
  mine,
  status
}: {
  text: string;
  mine?: boolean;
  status?: string;
}) {
  return (
    <View style={[styles.wrap, mine ? styles.mine : styles.theirs]}>
      <Text style={styles.text}>{text}</Text>
      {status ? <Text style={styles.status}>{status}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    maxWidth: "84%",
    padding: mauriTheme.spacing.md,
    borderRadius: mauriTheme.radius.lg,
    borderWidth: 1,
    marginVertical: 4
  },
  mine: {
    alignSelf: "flex-end",
    backgroundColor: "rgba(0,208,132,0.18)",
    borderColor: mauriTheme.colors.greenstone
  },
  theirs: {
    alignSelf: "flex-start",
    backgroundColor: mauriTheme.colors.panel,
    borderColor: mauriTheme.colors.panelBorder
  },
  text: {
    color: mauriTheme.colors.white,
    fontSize: 15,
    lineHeight: 21
  },
  status: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 11,
    marginTop: 6
  }
});
TSX

cat > src/components/LivingMeshCanvas.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { SimNode, SimRoute } from "../lib/simulation";
import { mauriTheme } from "../theme/mauriTheme";

export function LivingMeshCanvas({
  nodes,
  routes
}: {
  nodes: SimNode[];
  routes: SimRoute[];
}) {
  return (
    <View style={styles.canvas}>
      {routes.map((route) => {
        const from = nodes.find((n) => n.id === route.from);
        const to = nodes.find((n) => n.id === route.to);
        if (!from || !to) return null;

        const left = Math.min(from.x, to.x);
        const top = Math.min(from.y, to.y);
        const width = Math.abs(from.x - to.x) + 4;

        return (
          <View
            key={`${route.from}-${route.to}`}
            style={[
              styles.route,
              {
                left: `${left}%`,
                top: `${top}%`,
                width: `${width}%`,
                opacity: Math.max(0.25, route.quality / 100)
              }
            ]}
          />
        );
      })}

      {nodes.map((node) => (
        <View
          key={node.id}
          style={[
            styles.node,
            {
              left: `${node.x}%`,
              top: `${node.y}%`,
              opacity: node.status === "offline" ? 0.42 : 1
            }
          ]}
        >
          <Text style={styles.nodeId}>{node.id}</Text>
          <Text style={styles.nodeLabel}>{node.signal}%</Text>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  canvas: {
    height: 360,
    borderRadius: mauriTheme.radius.xl,
    backgroundColor: "#020806",
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    overflow: "hidden",
    position: "relative"
  },
  route: {
    position: "absolute",
    height: 3,
    backgroundColor: mauriTheme.colors.greenstone,
    borderRadius: 999
  },
  node: {
    position: "absolute",
    width: 64,
    height: 64,
    marginLeft: -32,
    marginTop: -32,
    borderRadius: 32,
    backgroundColor: "rgba(0,208,132,0.16)",
    borderWidth: 1,
    borderColor: mauriTheme.colors.greenstone,
    alignItems: "center",
    justifyContent: "center"
  },
  nodeId: {
    color: mauriTheme.colors.white,
    fontWeight: "900",
    fontSize: 18
  },
  nodeLabel: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 11,
    fontWeight: "700"
  }
});
TSX
cat >> maurimesh-agentless-replit-build.sh <<'EOF'

echo ""
echo "9. Create Expo Router screens"

cat > app/_layout.tsx <<'TSX'
import { Stack } from "expo-router";
import React from "react";

export default function RootLayout() {
  return (
    <Stack
      screenOptions={{
        headerShown: false,
        contentStyle: { backgroundColor: "#020403" }
      }}
    />
  );
}
TSX

cat > app/index.tsx <<'TSX'
import { Redirect } from "expo-router";
import React from "react";

export default function Index() {
  return <Redirect href="/login" />;
}
TSX

cat > app/login.tsx <<'TSX'
import { useRouter } from "expo-router";
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function LoginScreen() {
  const router = useRouter();

  return (
    <AppShell scroll={false}>
      <View style={styles.hero}>
        <StatusPill label="MAURIMESH MESSENGER" tone="success" />
        <Text style={styles.title}>MauriMesh</Text>
        <Text style={styles.tagline}>Messenger</Text>
        <Text style={styles.subtitle}>
          Secure mesh communication prepared for offline routing, relay logic, and future native device proof.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Enter Network</Text>
        <Text style={styles.cardText}>
          Replit preview supports UI, navigation, API fallback, and simulation. Real BLE proof requires APK on physical phones.
        </Text>
        <MauriButton title="Open Dashboard" onPress={() => router.replace("/dashboard")} />
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  hero: { flex: 1, justifyContent: "center", gap: mauriTheme.spacing.md },
  title: { color: mauriTheme.colors.white, fontSize: 54, lineHeight: 58, fontWeight: "900", letterSpacing: -1.5 },
  tagline: { color: mauriTheme.colors.greenstone, fontSize: 28, fontWeight: "900", letterSpacing: 2 },
  subtitle: { color: mauriTheme.colors.mutedWhite, fontSize: 16, lineHeight: 24 },
  card: { borderRadius: mauriTheme.radius.xl, borderWidth: 1, borderColor: mauriTheme.colors.panelBorder, backgroundColor: mauriTheme.colors.panel, padding: mauriTheme.spacing.lg, gap: mauriTheme.spacing.md },
  cardTitle: { color: mauriTheme.colors.white, fontSize: 22, fontWeight: "900" },
  cardText: { color: mauriTheme.colors.mutedWhite, lineHeight: 21 }
});
TSX

cat > app/dashboard.tsx <<'TSX'
import { useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function DashboardScreen() {
  const router = useRouter();
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh);
  }, []);

  const mode = mesh?.mode || "UNAVAILABLE";

  return (
    <AppShell>
      <Text style={styles.title}>Dashboard</Text>
      <Text style={styles.subtitle}>
        Command centre for messenger, mesh visibility, friend discovery, and Pixel Calling shell.
      </Text>

      <MeshSignalCard title="Mesh Status" value={mesh?.message || "Checking mesh status..."} status={mode} />

      <View style={styles.grid}>
        <MauriButton title="Chat" onPress={() => router.push("/chat")} />
        <MauriButton title="Living Mesh" onPress={() => router.push("/living-mesh")} />
        <MauriButton title="Add Friend" onPress={() => router.push("/add-friend")} />
        <MauriButton title="Pixel Calling" onPress={() => router.push("/pixel-calling")} />
        <MauriButton title="Mesh Status" onPress={() => router.push("/mesh-status")} />
        <MauriButton title="Settings" onPress={() => router.push("/settings")} />
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 36, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, fontSize: 15, lineHeight: 22 },
  grid: { gap: mauriTheme.spacing.md }
});
TSX

cat > app/chat.tsx <<'TSX'
import React, { useState } from "react";
import { StyleSheet, Text, TextInput, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { ChatBubble } from "../src/components/ChatBubble";
import { MauriButton } from "../src/components/MauriButton";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function ChatScreen() {
  const [message, setMessage] = useState("");

  return (
    <AppShell>
      <Text style={styles.title}>Chat</Text>
      <Text style={styles.subtitle}>
        Messenger interface wired for Replit preview. Native BLE send/receive proof remains APK/device work.
      </Text>

      <View style={styles.thread}>
        <ChatBubble text="MauriMesh route prepared." status="SIMULATION" />
        <ChatBubble mine text="ACK, TTL, dedupe, relay, and store-forward remain protected architecture." status="local shell" />
      </View>

      <View style={styles.inputWrap}>
        <TextInput
          placeholder="Type message..."
          placeholderTextColor="rgba(255,255,255,0.45)"
          style={styles.input}
          value={message}
          onChangeText={setMessage}
        />
        <MauriButton title="Send" onPress={() => setMessage("")} />
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 },
  thread: { minHeight: 360, gap: 8 },
  inputWrap: { gap: mauriTheme.spacing.sm },
  input: {
    minHeight: 52,
    borderRadius: mauriTheme.radius.lg,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    color: mauriTheme.colors.white,
    paddingHorizontal: mauriTheme.spacing.md,
    backgroundColor: mauriTheme.colors.panel
  }
});
TSX

cat > app/living-mesh.tsx <<'TSX'
import React, { useEffect, useState } from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { LivingMeshCanvas } from "../src/components/LivingMeshCanvas";
import { StatusPill } from "../src/components/StatusPill";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function LivingMeshScreen() {
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh);
  }, []);

  return (
    <AppShell>
      <StatusPill label={mesh?.mode || "CHECKING"} tone={mesh?.mode === "LIVE" ? "success" : "warning"} />
      <Text style={styles.title}>Living Mesh</Text>
      <Text style={styles.subtitle}>
        {mesh?.message || "Checking Mesh API. Replit fallback displays simulation only."}
      </Text>
      <LivingMeshCanvas nodes={mesh?.nodes || []} routes={mesh?.routes || []} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 }
});
TSX

cat > app/add-friend.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function AddFriendScreen() {
  return (
    <AppShell>
      <StatusPill label="QR + NETWORK SEARCH SHELL" tone="info" />
      <Text style={styles.title}>Add Friend</Text>
      <Text style={styles.subtitle}>
        Camera QR scanning and BLE discovery require APK/device validation.
      </Text>

      <View style={styles.qrBox}>
        <Text style={styles.qrText}>MAURIMESH QR</Text>
      </View>

      <MauriButton title="Scan QR Code" onPress={() => {}} />
      <MauriButton title="Search Nearby Mesh" variant="secondary" onPress={() => {}} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 },
  qrBox: {
    height: 260,
    borderRadius: mauriTheme.radius.xl,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    alignItems: "center",
    justifyContent: "center"
  },
  qrText: { color: mauriTheme.colors.greenstone, fontWeight: "900", letterSpacing: 2 }
});
TSX

cat > app/pixel-calling.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function PixelCallingScreen() {
  return (
    <AppShell>
      <StatusPill label="UI SHELL ONLY" tone="warning" />
      <Text style={styles.title}>Pixel Calling</Text>
      <Text style={styles.subtitle}>
        Interface prepared. Real media transport requires native WebRTC/device proof outside Replit.
      </Text>

      <View style={styles.videoBox}>
        <Text style={styles.videoText}>Pixel Stream Preview</Text>
        <Text style={styles.videoSub}>SIMULATION / UI ONLY</Text>
      </View>

      <MauriButton title="Start Call" onPress={() => {}} />
      <MauriButton title="End Call" variant="danger" onPress={() => {}} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 },
  videoBox: {
    height: 380,
    borderRadius: mauriTheme.radius.xl,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: "#030B09",
    alignItems: "center",
    justifyContent: "center",
    gap: 8
  },
  videoText: { color: mauriTheme.colors.white, fontSize: 22, fontWeight: "900" },
  videoSub: { color: mauriTheme.colors.warning, fontSize: 12, fontWeight: "800", letterSpacing: 1 }
});
TSX

cat > app/mesh-status.tsx <<'TSX'
import React, { useEffect, useState } from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function MeshStatusScreen() {
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh);
  }, []);

  return (
    <AppShell>
      <Text style={styles.title}>Mesh Status</Text>
      <MeshSignalCard title="API Connection" value={mesh?.message || "Checking..."} status={mesh?.mode || "UNAVAILABLE"} />
      <MeshSignalCard title="Nodes Visible" value={`${mesh?.nodes.length || 0} node(s) visible in current mode.`} status={mesh?.mode || "UNAVAILABLE"} />
      <MeshSignalCard title="Routes Visible" value={`${mesh?.routes.length || 0} route(s) visible in current mode.`} status={mesh?.mode || "UNAVAILABLE"} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" }
});
TSX

cat > app/settings.tsx <<'TSX'
import { useRouter } from "expo-router";
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function SettingsScreen() {
  const router = useRouter();

  return (
    <AppShell>
      <Text style={styles.title}>Settings</Text>
      <Text style={styles.subtitle}>
        User controls, language shell, app state, and safe logout.
      </Text>

      <View style={styles.card}>
        <StatusPill label="LANGUAGE" tone="info" />
        <Text style={styles.cardTitle}>Preferred Language</Text>
        <Text style={styles.cardText}>
          English selected. Te reo Māori and additional languages can be wired into i18n next.
        </Text>
      </View>

      <View style={styles.card}>
        <StatusPill label="REPLIT MODE" tone="warning" />
        <Text style={styles.cardTitle}>Runtime Notice</Text>
        <Text style={styles.cardText}>
          Replit preview supports UI and API testing. Real BLE/offline proof requires APK on physical devices.
        </Text>
      </View>

      <MauriButton title="Log Out" variant="danger" onPress={() => router.replace("/login")} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 },
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm
  },
  cardTitle: { color: mauriTheme.colors.white, fontSize: 18, fontWeight: "900" },
  cardText: { color: mauriTheme.colors.mutedWhite, lineHeight: 21 }
});
TSX

echo ""
echo "10. Create Replit API server"
cat > server/index.ts <<'TS'
import express from "express";

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(express.json());

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "maurimesh-replit-api",
    mode: "development",
    truth: "Replit API is development only."
  });
});

app.get("/api/mesh/status", (_req, res) => {
  res.json({
    mode: "SIMULATION",
    truth: "Replit API simulation only. Not live BLE.",
    nodes: [
      { id: "A", label: "Device A", status: "online", signal: 96, x: 18, y: 30 },
      { id: "B", label: "Relay B", status: "relay", signal: 82, x: 48, y: 54 },
      { id: "C", label: "Device C", status: "online", signal: 74, x: 78, y: 28 },
      { id: "D", label: "Stored D", status: "offline", signal: 31, x: 66, y: 78 }
    ],
    routes: [
      { from: "A", to: "B", quality: 92 },
      { from: "B", to: "C", quality: 84 },
      { from: "B", to: "D", quality: 38 }
    ]
  });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`[MauriMesh] Replit API running on port ${port}`);
});
TS

echo ""
echo "11. Create env example"
cat > .env.example <<'ENV'
EXPO_PUBLIC_MESH_API_URL=
ENV

echo ""
echo "12. Create health-check script"
cat > scripts/health-check.sh <<'SH'
#!/usr/bin/env bash
set -e
curl http://localhost:3000/api/health || true
echo ""
curl http://localhost:3000/api/mesh/status || true
echo ""
SH

chmod +x scripts/health-check.sh

echo ""
echo "13. Clean Expo cache"
rm -rf .expo node_modules/.cache || true

echo ""
echo "14. TypeScript check"
npx tsc --noEmit || true

echo ""
echo "=================================================="
echo "MAURIMESH AGENTLESS BUILD COMPLETE"
echo "=================================================="
echo ""
echo "Next run:"
echo "npx expo start --clear --port 8082"
echo ""
echo "Optional API server:"
echo "npx tsx server/index.ts"
echo ""
echo "Backup:"
echo "$BACKUP"
echo ""

echo ""
echo "8. Create reusable UI components"

cat > src/components/AppShell.tsx <<'TSX'
import React from "react";
import { SafeAreaView, ScrollView, StyleSheet, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function AppShell({
  children,
  scroll = true
}: {
  children: React.ReactNode;
  scroll?: boolean;
}) {
  const content = <View style={styles.content}>{children}</View>;

  return (
    <SafeAreaView style={styles.safe}>
      {scroll ? <ScrollView>{content}</ScrollView> : content}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: mauriTheme.colors.black
  },
  content: {
    flex: 1,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.md
  }
});
TSX

cat > src/components/MauriButton.tsx <<'TSX'
import React from "react";
import { Pressable, StyleSheet, Text } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function MauriButton({
  title,
  onPress,
  variant = "primary"
}: {
  title: string;
  onPress: () => void;
  variant?: "primary" | "secondary" | "danger";
}) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.base,
        variant === "primary" && styles.primary,
        variant === "secondary" && styles.secondary,
        variant === "danger" && styles.danger,
        pressed && { opacity: 0.76, transform: [{ scale: 0.98 }] }
      ]}
    >
      <Text style={styles.text}>{title}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    minHeight: 52,
    borderRadius: mauriTheme.radius.lg,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: mauriTheme.spacing.lg,
    borderWidth: 1
  },
  primary: {
    backgroundColor: mauriTheme.colors.greenstone,
    borderColor: mauriTheme.colors.greenstone
  },
  secondary: {
    backgroundColor: mauriTheme.colors.panel,
    borderColor: mauriTheme.colors.panelBorder
  },
  danger: {
    backgroundColor: "rgba(239,68,68,0.16)",
    borderColor: "rgba(239,68,68,0.5)"
  },
  text: {
    color: mauriTheme.colors.white,
    fontSize: 16,
    fontWeight: "800"
  }
});
TSX

cat > src/components/StatusPill.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function StatusPill({
  label,
  tone = "success"
}: {
  label: string;
  tone?: "success" | "warning" | "danger" | "info";
}) {
  const color =
    tone === "success"
      ? mauriTheme.colors.success
      : tone === "warning"
        ? mauriTheme.colors.warning
        : tone === "danger"
          ? mauriTheme.colors.danger
          : mauriTheme.colors.blueWeb;

  return (
    <View style={[styles.pill, { borderColor: color }]}>
      <Text style={[styles.text, { color }]}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  pill: {
    alignSelf: "flex-start",
    borderWidth: 1,
    borderRadius: 999,
    paddingVertical: 6,
    paddingHorizontal: 12,
    backgroundColor: "rgba(255,255,255,0.05)"
  },
  text: {
    fontWeight: "800",
    fontSize: 12,
    letterSpacing: 0.6
  }
});
TSX

cat > src/components/MeshSignalCard.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function MeshSignalCard({
  title,
  value,
  status
}: {
  title: string;
  value: string;
  status: "LIVE" | "SIMULATION" | "UNAVAILABLE";
}) {
  return (
    <View style={styles.card}>
      <StatusPill
        label={status}
        tone={status === "LIVE" ? "success" : status === "SIMULATION" ? "warning" : "danger"}
      />
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.value}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 18,
    fontWeight: "900"
  },
  value: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 14,
    lineHeight: 20
  }
});
TSX

cat > src/components/ChatBubble.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function ChatBubble({
  text,
  mine,
  status
}: {
  text: string;
  mine?: boolean;
  status?: string;
}) {
  return (
    <View style={[styles.wrap, mine ? styles.mine : styles.theirs]}>
      <Text style={styles.text}>{text}</Text>
      {status ? <Text style={styles.status}>{status}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    maxWidth: "84%",
    padding: mauriTheme.spacing.md,
    borderRadius: mauriTheme.radius.lg,
    borderWidth: 1,
    marginVertical: 4
  },
  mine: {
    alignSelf: "flex-end",
    backgroundColor: "rgba(0,208,132,0.18)",
    borderColor: mauriTheme.colors.greenstone
  },
  theirs: {
    alignSelf: "flex-start",
    backgroundColor: mauriTheme.colors.panel,
    borderColor: mauriTheme.colors.panelBorder
  },
  text: {
    color: mauriTheme.colors.white,
    fontSize: 15,
    lineHeight: 21
  },
  status: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 11,
    marginTop: 6
  }
});
TSX

cat > src/components/LivingMeshCanvas.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { SimNode, SimRoute } from "../lib/simulation";
import { mauriTheme } from "../theme/mauriTheme";

export function LivingMeshCanvas({
  nodes,
  routes
}: {
  nodes: SimNode[];
  routes: SimRoute[];
}) {
  return (
    <View style={styles.canvas}>
      {routes.map((route) => {
        const from = nodes.find((n) => n.id === route.from);
        const to = nodes.find((n) => n.id === route.to);
        if (!from || !to) return null;

        const left = Math.min(from.x, to.x);
        const top = Math.min(from.y, to.y);
        const width = Math.abs(from.x - to.x) + 4;

        return (
          <View
            key={`${route.from}-${route.to}`}
            style={[
              styles.route,
              {
                left: `${left}%`,
                top: `${top}%`,
                width: `${width}%`,
                opacity: Math.max(0.25, route.quality / 100)
              }
            ]}
          />
        );
      })}

      {nodes.map((node) => (
        <View
          key={node.id}
          style={[
            styles.node,
            {
              left: `${node.x}%`,
              top: `${node.y}%`,
              opacity: node.status === "offline" ? 0.42 : 1
            }
          ]}
        >
          <Text style={styles.nodeId}>{node.id}</Text>
          <Text style={styles.nodeLabel}>{node.signal}%</Text>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  canvas: {
    height: 360,
    borderRadius: mauriTheme.radius.xl,
    backgroundColor: "#020806",
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    overflow: "hidden",
    position: "relative"
  },
  route: {
    position: "absolute",
    height: 3,
    backgroundColor: mauriTheme.colors.greenstone,
    borderRadius: 999
  },
  node: {
    position: "absolute",
    width: 64,
    height: 64,
    marginLeft: -32,
    marginTop: -32,
    borderRadius: 32,
    backgroundColor: "rgba(0,208,132,0.16)",
    borderWidth: 1,
    borderColor: mauriTheme.colors.greenstone,
    alignItems: "center",
    justifyContent: "center"
  },
  nodeId: {
    color: mauriTheme.colors.white,
    fontWeight: "900",
    fontSize: 18
  },
  nodeLabel: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 11,
    fontWeight: "700"
  }
});
TSX
cat >> maurimesh-agentless-replit-build.sh <<'EOF'

echo ""
echo "9. Create Expo Router screens"

cat > app/_layout.tsx <<'TSX'
import { Stack } from "expo-router";
import React from "react";

export default function RootLayout() {
  return (
    <Stack
      screenOptions={{
        headerShown: false,
        contentStyle: { backgroundColor: "#020403" }
      }}
    />
  );
}
TSX

cat > app/index.tsx <<'TSX'
import { Redirect } from "expo-router";
import React from "react";

export default function Index() {
  return <Redirect href="/login" />;
}
TSX

cat > app/login.tsx <<'TSX'
import { useRouter } from "expo-router";
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function LoginScreen() {
  const router = useRouter();

  return (
    <AppShell scroll={false}>
      <View style={styles.hero}>
        <StatusPill label="MAURIMESH MESSENGER" tone="success" />
        <Text style={styles.title}>MauriMesh</Text>
        <Text style={styles.tagline}>Messenger</Text>
        <Text style={styles.subtitle}>
          Secure mesh communication prepared for offline routing, relay logic, and future native device proof.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Enter Network</Text>
        <Text style={styles.cardText}>
          Replit preview supports UI, navigation, API fallback, and simulation. Real BLE proof requires APK on physical phones.
        </Text>
        <MauriButton title="Open Dashboard" onPress={() => router.replace("/dashboard")} />
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  hero: { flex: 1, justifyContent: "center", gap: mauriTheme.spacing.md },
  title: { color: mauriTheme.colors.white, fontSize: 54, lineHeight: 58, fontWeight: "900", letterSpacing: -1.5 },
  tagline: { color: mauriTheme.colors.greenstone, fontSize: 28, fontWeight: "900", letterSpacing: 2 },
  subtitle: { color: mauriTheme.colors.mutedWhite, fontSize: 16, lineHeight: 24 },
  card: { borderRadius: mauriTheme.radius.xl, borderWidth: 1, borderColor: mauriTheme.colors.panelBorder, backgroundColor: mauriTheme.colors.panel, padding: mauriTheme.spacing.lg, gap: mauriTheme.spacing.md },
  cardTitle: { color: mauriTheme.colors.white, fontSize: 22, fontWeight: "900" },
  cardText: { color: mauriTheme.colors.mutedWhite, lineHeight: 21 }
});
TSX

cat > app/dashboard.tsx <<'TSX'
import { useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function DashboardScreen() {
  const router = useRouter();
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh);
  }, []);

  const mode = mesh?.mode || "UNAVAILABLE";

  return (
    <AppShell>
      <Text style={styles.title}>Dashboard</Text>
      <Text style={styles.subtitle}>
        Command centre for messenger, mesh visibility, friend discovery, and Pixel Calling shell.
      </Text>

      <MeshSignalCard title="Mesh Status" value={mesh?.message || "Checking mesh status..."} status={mode} />

      <View style={styles.grid}>
        <MauriButton title="Chat" onPress={() => router.push("/chat")} />
        <MauriButton title="Living Mesh" onPress={() => router.push("/living-mesh")} />
        <MauriButton title="Add Friend" onPress={() => router.push("/add-friend")} />
        <MauriButton title="Pixel Calling" onPress={() => router.push("/pixel-calling")} />
        <MauriButton title="Mesh Status" onPress={() => router.push("/mesh-status")} />
        <MauriButton title="Settings" onPress={() => router.push("/settings")} />
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 36, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, fontSize: 15, lineHeight: 22 },
  grid: { gap: mauriTheme.spacing.md }
});
TSX

cat > app/chat.tsx <<'TSX'
import React, { useState } from "react";
import { StyleSheet, Text, TextInput, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { ChatBubble } from "../src/components/ChatBubble";
import { MauriButton } from "../src/components/MauriButton";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function ChatScreen() {
  const [message, setMessage] = useState("");

  return (
    <AppShell>
      <Text style={styles.title}>Chat</Text>
      <Text style={styles.subtitle}>
        Messenger interface wired for Replit preview. Native BLE send/receive proof remains APK/device work.
      </Text>

      <View style={styles.thread}>
        <ChatBubble text="MauriMesh route prepared." status="SIMULATION" />
        <ChatBubble mine text="ACK, TTL, dedupe, relay, and store-forward remain protected architecture." status="local shell" />
      </View>

      <View style={styles.inputWrap}>
        <TextInput
          placeholder="Type message..."
          placeholderTextColor="rgba(255,255,255,0.45)"
          style={styles.input}
          value={message}
          onChangeText={setMessage}
        />
        <MauriButton title="Send" onPress={() => setMessage("")} />
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 },
  thread: { minHeight: 360, gap: 8 },
  inputWrap: { gap: mauriTheme.spacing.sm },
  input: {
    minHeight: 52,
    borderRadius: mauriTheme.radius.lg,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    color: mauriTheme.colors.white,
    paddingHorizontal: mauriTheme.spacing.md,
    backgroundColor: mauriTheme.colors.panel
  }
});
TSX

cat > app/living-mesh.tsx <<'TSX'
import React, { useEffect, useState } from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { LivingMeshCanvas } from "../src/components/LivingMeshCanvas";
import { StatusPill } from "../src/components/StatusPill";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function LivingMeshScreen() {
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh);
  }, []);

  return (
    <AppShell>
      <StatusPill label={mesh?.mode || "CHECKING"} tone={mesh?.mode === "LIVE" ? "success" : "warning"} />
      <Text style={styles.title}>Living Mesh</Text>
      <Text style={styles.subtitle}>
        {mesh?.message || "Checking Mesh API. Replit fallback displays simulation only."}
      </Text>
      <LivingMeshCanvas nodes={mesh?.nodes || []} routes={mesh?.routes || []} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 }
});
TSX

cat > app/add-friend.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function AddFriendScreen() {
  return (
    <AppShell>
      <StatusPill label="QR + NETWORK SEARCH SHELL" tone="info" />
      <Text style={styles.title}>Add Friend</Text>
      <Text style={styles.subtitle}>
        Camera QR scanning and BLE discovery require APK/device validation.
      </Text>

      <View style={styles.qrBox}>
        <Text style={styles.qrText}>MAURIMESH QR</Text>
      </View>

      <MauriButton title="Scan QR Code" onPress={() => {}} />
      <MauriButton title="Search Nearby Mesh" variant="secondary" onPress={() => {}} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 },
  qrBox: {
    height: 260,
    borderRadius: mauriTheme.radius.xl,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    alignItems: "center",
    justifyContent: "center"
  },
  qrText: { color: mauriTheme.colors.greenstone, fontWeight: "900", letterSpacing: 2 }
});
TSX

cat > app/pixel-calling.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function PixelCallingScreen() {
  return (
    <AppShell>
      <StatusPill label="UI SHELL ONLY" tone="warning" />
      <Text style={styles.title}>Pixel Calling</Text>
      <Text style={styles.subtitle}>
        Interface prepared. Real media transport requires native WebRTC/device proof outside Replit.
      </Text>

      <View style={styles.videoBox}>
        <Text style={styles.videoText}>Pixel Stream Preview</Text>
        <Text style={styles.videoSub}>SIMULATION / UI ONLY</Text>
      </View>

      <MauriButton title="Start Call" onPress={() => {}} />
      <MauriButton title="End Call" variant="danger" onPress={() => {}} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 },
  videoBox: {
    height: 380,
    borderRadius: mauriTheme.radius.xl,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: "#030B09",
    alignItems: "center",
    justifyContent: "center",
    gap: 8
  },
  videoText: { color: mauriTheme.colors.white, fontSize: 22, fontWeight: "900" },
  videoSub: { color: mauriTheme.colors.warning, fontSize: 12, fontWeight: "800", letterSpacing: 1 }
});
TSX

cat > app/mesh-status.tsx <<'TSX'
import React, { useEffect, useState } from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function MeshStatusScreen() {
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh);
  }, []);

  return (
    <AppShell>
      <Text style={styles.title}>Mesh Status</Text>
      <MeshSignalCard title="API Connection" value={mesh?.message || "Checking..."} status={mesh?.mode || "UNAVAILABLE"} />
      <MeshSignalCard title="Nodes Visible" value={`${mesh?.nodes.length || 0} node(s) visible in current mode.`} status={mesh?.mode || "UNAVAILABLE"} />
      <MeshSignalCard title="Routes Visible" value={`${mesh?.routes.length || 0} route(s) visible in current mode.`} status={mesh?.mode || "UNAVAILABLE"} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" }
});
TSX

cat > app/settings.tsx <<'TSX'
import { useRouter } from "expo-router";
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function SettingsScreen() {
  const router = useRouter();

  return (
    <AppShell>
      <Text style={styles.title}>Settings</Text>
      <Text style={styles.subtitle}>
        User controls, language shell, app state, and safe logout.
      </Text>

      <View style={styles.card}>
        <StatusPill label="LANGUAGE" tone="info" />
        <Text style={styles.cardTitle}>Preferred Language</Text>
        <Text style={styles.cardText}>
          English selected. Te reo Māori and additional languages can be wired into i18n next.
        </Text>
      </View>

      <View style={styles.card}>
        <StatusPill label="REPLIT MODE" tone="warning" />
        <Text style={styles.cardTitle}>Runtime Notice</Text>
        <Text style={styles.cardText}>
          Replit preview supports UI and API testing. Real BLE/offline proof requires APK on physical devices.
        </Text>
      </View>

      <MauriButton title="Log Out" variant="danger" onPress={() => router.replace("/login")} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 },
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm
  },
  cardTitle: { color: mauriTheme.colors.white, fontSize: 18, fontWeight: "900" },
  cardText: { color: mauriTheme.colors.mutedWhite, lineHeight: 21 }
});
TSX

echo ""
echo "10. Create Replit API server"
cat > server/index.ts <<'TS'
import express from "express";

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(express.json());

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "maurimesh-replit-api",
    mode: "development",
    truth: "Replit API is development only."
  });
});

app.get("/api/mesh/status", (_req, res) => {
  res.json({
    mode: "SIMULATION",
    truth: "Replit API simulation only. Not live BLE.",
    nodes: [
      { id: "A", label: "Device A", status: "online", signal: 96, x: 18, y: 30 },
      { id: "B", label: "Relay B", status: "relay", signal: 82, x: 48, y: 54 },
      { id: "C", label: "Device C", status: "online", signal: 74, x: 78, y: 28 },
      { id: "D", label: "Stored D", status: "offline", signal: 31, x: 66, y: 78 }
    ],
    routes: [
      { from: "A", to: "B", quality: 92 },
      { from: "B", to: "C", quality: 84 },
      { from: "B", to: "D", quality: 38 }
    ]
  });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`[MauriMesh] Replit API running on port ${port}`);
});
TS

echo ""
echo "11. Create env example"
cat > .env.example <<'ENV'
EXPO_PUBLIC_MESH_API_URL=
ENV

echo ""
echo "12. Create health-check script"
cat > scripts/health-check.sh <<'SH'
#!/usr/bin/env bash
set -e
curl http://localhost:3000/api/health || true
echo ""
curl http://localhost:3000/api/mesh/status || true
echo ""
SH

chmod +x scripts/health-check.sh

echo ""
echo "13. Clean Expo cache"
rm -rf .expo node_modules/.cache || true

echo ""
echo "14. TypeScript check"
npx tsc --noEmit || true

echo ""
echo "=================================================="
echo "MAURIMESH AGENTLESS BUILD COMPLETE"
echo "=================================================="
echo ""
echo "Next run:"
echo "npx expo start --clear --port 8082"
echo ""
echo "Optional API server:"
echo "npx tsx server/index.ts"
echo ""
echo "Backup:"
echo "$BACKUP"
echo ""

echo ""
echo "9. Create Expo Router screens"

cat > app/_layout.tsx <<'TSX'
import { Stack } from "expo-router";
import React from "react";

export default function RootLayout() {
  return (
    <Stack
      screenOptions={{
        headerShown: false,
        contentStyle: { backgroundColor: "#020403" }
      }}
    />
  );
}
TSX

cat > app/index.tsx <<'TSX'
import { Redirect } from "expo-router";
import React from "react";

export default function Index() {
  return <Redirect href="/login" />;
}
TSX

cat > app/login.tsx <<'TSX'
import { useRouter } from "expo-router";
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function LoginScreen() {
  const router = useRouter();

  return (
    <AppShell scroll={false}>
      <View style={styles.hero}>
        <StatusPill label="MAURIMESH MESSENGER" tone="success" />
        <Text style={styles.title}>MauriMesh</Text>
        <Text style={styles.tagline}>Messenger</Text>
        <Text style={styles.subtitle}>
          Secure mesh communication prepared for offline routing, relay logic, and future native device proof.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Enter Network</Text>
        <Text style={styles.cardText}>
          Replit preview supports UI, navigation, API fallback, and simulation. Real BLE proof requires APK on physical phones.
        </Text>
        <MauriButton title="Open Dashboard" onPress={() => router.replace("/dashboard")} />
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  hero: { flex: 1, justifyContent: "center", gap: mauriTheme.spacing.md },
  title: { color: mauriTheme.colors.white, fontSize: 54, lineHeight: 58, fontWeight: "900", letterSpacing: -1.5 },
  tagline: { color: mauriTheme.colors.greenstone, fontSize: 28, fontWeight: "900", letterSpacing: 2 },
  subtitle: { color: mauriTheme.colors.mutedWhite, fontSize: 16, lineHeight: 24 },
  card: { borderRadius: mauriTheme.radius.xl, borderWidth: 1, borderColor: mauriTheme.colors.panelBorder, backgroundColor: mauriTheme.colors.panel, padding: mauriTheme.spacing.lg, gap: mauriTheme.spacing.md },
  cardTitle: { color: mauriTheme.colors.white, fontSize: 22, fontWeight: "900" },
  cardText: { color: mauriTheme.colors.mutedWhite, lineHeight: 21 }
});
TSX

cat > app/dashboard.tsx <<'TSX'
import { useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function DashboardScreen() {
  const router = useRouter();
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh);
  }, []);

  const mode = mesh?.mode || "UNAVAILABLE";

  return (
    <AppShell>
      <Text style={styles.title}>Dashboard</Text>
      <Text style={styles.subtitle}>
        Command centre for messenger, mesh visibility, friend discovery, and Pixel Calling shell.
      </Text>

      <MeshSignalCard title="Mesh Status" value={mesh?.message || "Checking mesh status..."} status={mode} />

      <View style={styles.grid}>
        <MauriButton title="Chat" onPress={() => router.push("/chat")} />
        <MauriButton title="Living Mesh" onPress={() => router.push("/living-mesh")} />
        <MauriButton title="Add Friend" onPress={() => router.push("/add-friend")} />
        <MauriButton title="Pixel Calling" onPress={() => router.push("/pixel-calling")} />
        <MauriButton title="Mesh Status" onPress={() => router.push("/mesh-status")} />
        <MauriButton title="Settings" onPress={() => router.push("/settings")} />
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 36, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, fontSize: 15, lineHeight: 22 },
  grid: { gap: mauriTheme.spacing.md }
});
TSX

cat > app/chat.tsx <<'TSX'
import React, { useState } from "react";
import { StyleSheet, Text, TextInput, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { ChatBubble } from "../src/components/ChatBubble";
import { MauriButton } from "../src/components/MauriButton";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function ChatScreen() {
  const [message, setMessage] = useState("");

  return (
    <AppShell>
      <Text style={styles.title}>Chat</Text>
      <Text style={styles.subtitle}>
        Messenger interface wired for Replit preview. Native BLE send/receive proof remains APK/device work.
      </Text>

      <View style={styles.thread}>
        <ChatBubble text="MauriMesh route prepared." status="SIMULATION" />
        <ChatBubble mine text="ACK, TTL, dedupe, relay, and store-forward remain protected architecture." status="local shell" />
      </View>

      <View style={styles.inputWrap}>
        <TextInput
          placeholder="Type message..."
          placeholderTextColor="rgba(255,255,255,0.45)"
          style={styles.input}
          value={message}
          onChangeText={setMessage}
        />
        <MauriButton title="Send" onPress={() => setMessage("")} />
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 },
  thread: { minHeight: 360, gap: 8 },
  inputWrap: { gap: mauriTheme.spacing.sm },
  input: {
    minHeight: 52,
    borderRadius: mauriTheme.radius.lg,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    color: mauriTheme.colors.white,
    paddingHorizontal: mauriTheme.spacing.md,
    backgroundColor: mauriTheme.colors.panel
  }
});
TSX

cat > app/living-mesh.tsx <<'TSX'
import React, { useEffect, useState } from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { LivingMeshCanvas } from "../src/components/LivingMeshCanvas";
import { StatusPill } from "../src/components/StatusPill";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function LivingMeshScreen() {
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh);
  }, []);

  return (
    <AppShell>
      <StatusPill label={mesh?.mode || "CHECKING"} tone={mesh?.mode === "LIVE" ? "success" : "warning"} />
      <Text style={styles.title}>Living Mesh</Text>
      <Text style={styles.subtitle}>
        {mesh?.message || "Checking Mesh API. Replit fallback displays simulation only."}
      </Text>
      <LivingMeshCanvas nodes={mesh?.nodes || []} routes={mesh?.routes || []} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 }
});
TSX

cat > app/add-friend.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function AddFriendScreen() {
  return (
    <AppShell>
      <StatusPill label="QR + NETWORK SEARCH SHELL" tone="info" />
      <Text style={styles.title}>Add Friend</Text>
      <Text style={styles.subtitle}>
        Camera QR scanning and BLE discovery require APK/device validation.
      </Text>

      <View style={styles.qrBox}>
        <Text style={styles.qrText}>MAURIMESH QR</Text>
      </View>

      <MauriButton title="Scan QR Code" onPress={() => {}} />
      <MauriButton title="Search Nearby Mesh" variant="secondary" onPress={() => {}} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 },
  qrBox: {
    height: 260,
    borderRadius: mauriTheme.radius.xl,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    alignItems: "center",
    justifyContent: "center"
  },
  qrText: { color: mauriTheme.colors.greenstone, fontWeight: "900", letterSpacing: 2 }
});
TSX

cat > app/pixel-calling.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function PixelCallingScreen() {
  return (
    <AppShell>
      <StatusPill label="UI SHELL ONLY" tone="warning" />
      <Text style={styles.title}>Pixel Calling</Text>
      <Text style={styles.subtitle}>
        Interface prepared. Real media transport requires native WebRTC/device proof outside Replit.
      </Text>

      <View style={styles.videoBox}>
        <Text style={styles.videoText}>Pixel Stream Preview</Text>
        <Text style={styles.videoSub}>SIMULATION / UI ONLY</Text>
      </View>

      <MauriButton title="Start Call" onPress={() => {}} />
      <MauriButton title="End Call" variant="danger" onPress={() => {}} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 },
  videoBox: {
    height: 380,
    borderRadius: mauriTheme.radius.xl,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: "#030B09",
    alignItems: "center",
    justifyContent: "center",
    gap: 8
  },
  videoText: { color: mauriTheme.colors.white, fontSize: 22, fontWeight: "900" },
  videoSub: { color: mauriTheme.colors.warning, fontSize: 12, fontWeight: "800", letterSpacing: 1 }
});
TSX

cat > app/mesh-status.tsx <<'TSX'
import React, { useEffect, useState } from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function MeshStatusScreen() {
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh);
  }, []);

  return (
    <AppShell>
      <Text style={styles.title}>Mesh Status</Text>
      <MeshSignalCard title="API Connection" value={mesh?.message || "Checking..."} status={mesh?.mode || "UNAVAILABLE"} />
      <MeshSignalCard title="Nodes Visible" value={`${mesh?.nodes.length || 0} node(s) visible in current mode.`} status={mesh?.mode || "UNAVAILABLE"} />
      <MeshSignalCard title="Routes Visible" value={`${mesh?.routes.length || 0} route(s) visible in current mode.`} status={mesh?.mode || "UNAVAILABLE"} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" }
});
TSX

cat > app/settings.tsx <<'TSX'
import { useRouter } from "expo-router";
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function SettingsScreen() {
  const router = useRouter();

  return (
    <AppShell>
      <Text style={styles.title}>Settings</Text>
      <Text style={styles.subtitle}>
        User controls, language shell, app state, and safe logout.
      </Text>

      <View style={styles.card}>
        <StatusPill label="LANGUAGE" tone="info" />
        <Text style={styles.cardTitle}>Preferred Language</Text>
        <Text style={styles.cardText}>
          English selected. Te reo Māori and additional languages can be wired into i18n next.
        </Text>
      </View>

      <View style={styles.card}>
        <StatusPill label="REPLIT MODE" tone="warning" />
        <Text style={styles.cardTitle}>Runtime Notice</Text>
        <Text style={styles.cardText}>
          Replit preview supports UI and API testing. Real BLE/offline proof requires APK on physical devices.
        </Text>
      </View>

      <MauriButton title="Log Out" variant="danger" onPress={() => router.replace("/login")} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 },
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm
  },
  cardTitle: { color: mauriTheme.colors.white, fontSize: 18, fontWeight: "900" },
  cardText: { color: mauriTheme.colors.mutedWhite, lineHeight: 21 }
});
TSX

echo ""
echo "10. Create Replit API server"
cat > server/index.ts <<'TS'
import express from "express";

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(express.json());

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "maurimesh-replit-api",
    mode: "development",
    truth: "Replit API is development only."
  });
});

app.get("/api/mesh/status", (_req, res) => {
  res.json({
    mode: "SIMULATION",
    truth: "Replit API simulation only. Not live BLE.",
    nodes: [
      { id: "A", label: "Device A", status: "online", signal: 96, x: 18, y: 30 },
      { id: "B", label: "Relay B", status: "relay", signal: 82, x: 48, y: 54 },
      { id: "C", label: "Device C", status: "online", signal: 74, x: 78, y: 28 },
      { id: "D", label: "Stored D", status: "offline", signal: 31, x: 66, y: 78 }
    ],
    routes: [
      { from: "A", to: "B", quality: 92 },
      { from: "B", to: "C", quality: 84 },
      { from: "B", to: "D", quality: 38 }
    ]
  });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`[MauriMesh] Replit API running on port ${port}`);
});
TS

echo ""
echo "11. Create env example"
cat > .env.example <<'ENV'
EXPO_PUBLIC_MESH_API_URL=
ENV

echo ""
echo "12. Create health-check script"
cat > scripts/health-check.sh <<'SH'
#!/usr/bin/env bash
set -e
curl http://localhost:3000/api/health || true
echo ""
curl http://localhost:3000/api/mesh/status || true
echo ""
SH

chmod +x scripts/health-check.sh

echo ""
echo "13. Clean Expo cache"
rm -rf .expo node_modules/.cache || true

echo ""
echo "14. TypeScript check"
npx tsc --noEmit || true

echo ""
echo "=================================================="
echo "MAURIMESH AGENTLESS BUILD COMPLETE"
echo "=================================================="
echo ""
echo "Next run:"
echo "npx expo start --clear --port 8082"
echo ""
echo "Optional API server:"
echo "npx tsx server/index.ts"
echo ""
echo "Backup:"
echo "$BACKUP"
echo ""
