export type MeshStatus = {
  online?: boolean;
  nodes?: number;
  state?: string;
};

export async function getMeshStatus(): Promise<MeshStatus> {
  return {
    online: false,
    nodes: 0,
    state: "offline",
  };
}
