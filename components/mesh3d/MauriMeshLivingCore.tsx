import { useCallback, useEffect, useRef, useState } from "react";
import {
  Animated,
  Pressable,
  StyleSheet,
  Text,
  View,
  type LayoutChangeEvent,
} from "react-native";
import { NodeStatus, PacketType, type MeshNode } from "@/lib/mesh-core/types";
import { MeshNodeOrb, statusColor } from "./MeshNodeOrb";
import { MeshRouteBeam } from "./MeshRouteBeam";
import { MeshSignalPulse } from "./MeshSignalPulse";
import { GreenstoneGlassPanel } from "./GreenstoneGlassPanel";

interface NodeLayout {
  node: MeshNode;
  x: number;
  y: number;
}

const HEALTH_COLORS = ["#ef4444", "#f59e0b", "#10b981"];

function healthColor(score: number): string {
  if (score < 0.35) return HEALTH_COLORS[0];
  if (score < 0.65) return HEALTH_COLORS[1];
  return HEALTH_COLORS[2];
}

function distributeNodes(nodes: MeshNode[]): NodeLayout[] {
  if (nodes.length === 0) return [];
  return nodes.map((node, i) => {
    const angle = (i / nodes.length) * 2 * Math.PI - Math.PI / 2;
    const radius = nodes.length === 1 ? 0 : 0.35;
    return {
      node,
      x: 0.5 + radius * Math.cos(angle),
      y: 0.5 + radius * Math.sin(angle),
    };
  });
}

export interface MauriMeshLivingCoreProps {
  nodes: MeshNode[];
  routeHealthScore?: number;
  onPulseSent?: (packetId: string) => void;
  pulseTargetNodeId?: string;
  triggerPulse?: boolean;
  onNodePress?: (node: MeshNode) => void;
  /** RouteScore [0,1] keyed by nodeId — drives beam thickness and glow. */
  routeScores?: Record<string, number>;
}

export function MauriMeshLivingCore({
  nodes,
  routeHealthScore = 0.8,
  onPulseSent,
  pulseTargetNodeId,
  triggerPulse = false,
  onNodePress,
  routeScores = {},
}: MauriMeshLivingCoreProps) {
  const [size, setSize] = useState({ width: 300, height: 260 });
  const [sendingPulse, setSendingPulse] = useState(false);
  const healthAnim = useRef(new Animated.Value(routeHealthScore)).current;

  useEffect(() => {
    Animated.timing(healthAnim, {
      toValue: routeHealthScore,
      duration: 600,
      useNativeDriver: false,
    }).start();
  }, [routeHealthScore, healthAnim]);

  useEffect(() => {
    if (triggerPulse && !sendingPulse) {
      setSendingPulse(true);
    }
  }, [triggerPulse, sendingPulse]);

  const handleLayout = useCallback((e: LayoutChangeEvent) => {
    const { width, height } = e.nativeEvent.layout;
    setSize({ width, height });
  }, []);

  const layouts = distributeNodes(nodes);
  const selfLayout = layouts.find((l) => l.node.status === NodeStatus.SELF);
  const others = layouts.filter((l) => l.node.status !== NodeStatus.SELF);
  const pulseTarget = pulseTargetNodeId
    ? layouts.find((l) => l.node.nodeId === pulseTargetNodeId)
    : others[0];

  const healthWidth = healthAnim.interpolate({
    inputRange: [0, 1],
    outputRange: ["0%", "100%"],
  });

  const hColor = healthColor(routeHealthScore);

  return (
    <View style={styles.root}>
      <View style={styles.canvasWrapper} onLayout={handleLayout}>
        {/* Route beams */}
        {selfLayout &&
          others.map((ol) => (
            <MeshRouteBeam
              key={ol.node.nodeId}
              from={selfLayout}
              to={ol}
              active={nodes.length > 1}
              color={statusColor(ol.node.status)}
              containerWidth={size.width}
              containerHeight={size.height}
              routeScore={routeScores[ol.node.nodeId] ?? 0.5}
            />
          ))}

        {/* Signal pulse */}
        {selfLayout && pulseTarget && sendingPulse && (
          <MeshSignalPulse
            from={selfLayout}
            to={pulseTarget}
            sendPulse={sendingPulse}
            containerWidth={size.width}
            containerHeight={size.height}
            onComplete={() => {
              setSendingPulse(false);
              onPulseSent?.(pulseTarget.node.nodeId);
            }}
          />
        )}

        {/* Node orbs */}
        {layouts.map((nl) => (
          <Pressable
            key={nl.node.nodeId}
            style={[
              styles.orbContainer,
              {
                left: nl.x * size.width - 24,
                top: nl.y * size.height - 24,
              },
            ]}
            onPress={() => {
              console.log(`[MauriMesh][LivingMesh] node tapped nodeId=${nl.node.nodeId}`);
              onNodePress?.(nl.node);
            }}
          >
            <MeshNodeOrb
              nodeId={nl.node.nodeId}
              displayName={nl.node.displayName}
              status={nl.node.status}
              size={48}
              active={nl.node.status === NodeStatus.SELF || nl.node.status === NodeStatus.TRUSTED}
            />
            <Text style={styles.nodeLabel} numberOfLines={1}>
              {nl.node.displayName}
            </Text>
          </Pressable>
        ))}
      </View>

      {/* Route health meter */}
      <GreenstoneGlassPanel style={styles.healthPanel} noPadding>
        <View style={styles.healthInner}>
          <Text style={styles.healthLabel}>Route Health</Text>
          <View style={styles.healthTrack}>
            <Animated.View
              style={[styles.healthBar, { width: healthWidth, backgroundColor: hColor }]}
            />
          </View>
          <Text style={[styles.healthPct, { color: hColor }]}>
            {Math.round(routeHealthScore * 100)}%
          </Text>
        </View>
      </GreenstoneGlassPanel>

      {/* Offline badge */}
      <View style={styles.offlineBadge}>
        <View style={styles.offlineDot} />
        <Text style={styles.offlineText}>OFFLINE MESH · NO INTERNET</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    width: "100%",
  },
  canvasWrapper: {
    width: "100%",
    height: 260,
    position: "relative",
    marginBottom: 16,
  },
  orbContainer: {
    position: "absolute",
    alignItems: "center",
    width: 48,
  },
  nodeLabel: {
    marginTop: 4,
    fontSize: 9,
    color: "rgba(255,255,255,0.55)",
    fontFamily: "Inter_500Medium",
    letterSpacing: 0.3,
    textAlign: "center",
    maxWidth: 64,
  },
  healthPanel: {
    marginHorizontal: 0,
    marginBottom: 12,
    borderRadius: 12,
    padding: 0,
  },
  healthInner: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  healthLabel: {
    fontSize: 11,
    color: "rgba(255,255,255,0.55)",
    fontFamily: "Inter_500Medium",
    width: 80,
  },
  healthTrack: {
    flex: 1,
    height: 6,
    borderRadius: 3,
    backgroundColor: "rgba(255,255,255,0.1)",
    overflow: "hidden",
  },
  healthBar: {
    height: "100%",
    borderRadius: 3,
  },
  healthPct: {
    fontSize: 11,
    fontFamily: "Inter_700Bold",
    width: 34,
    textAlign: "right",
  },
  offlineBadge: {
    flexDirection: "row",
    alignItems: "center",
    alignSelf: "center",
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 5,
    borderRadius: 20,
    backgroundColor: "rgba(16,185,129,0.10)",
    borderWidth: 1,
    borderColor: "rgba(16,185,129,0.22)",
  },
  offlineDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: "#10b981",
  },
  offlineText: {
    fontSize: 9,
    letterSpacing: 1.5,
    color: "rgba(16,185,129,0.8)",
    fontFamily: "Inter_700Bold",
  },
});
