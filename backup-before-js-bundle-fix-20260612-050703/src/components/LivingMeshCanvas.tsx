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
