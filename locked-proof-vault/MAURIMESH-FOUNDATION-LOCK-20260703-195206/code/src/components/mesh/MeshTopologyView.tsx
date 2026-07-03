import React from "react";
import { View, Text } from "react-native";

export type TopologyNode = {
  id: string;
  label?: string;
  status?: string;
};

export type TopologyEdge = {
  id: string;
  from: string;
  to: string;
  score?: number;
};

export function MeshTopologyView({
  nodes = [],
  edges = [],
}: {
  nodes?: TopologyNode[];
  edges?: TopologyEdge[];
}) {
  return (
    <View>
      <Text>Topology Nodes: {nodes.length}</Text>
      <Text>Topology Edges: {edges.length}</Text>
    </View>
  );
}

export default MeshTopologyView;
