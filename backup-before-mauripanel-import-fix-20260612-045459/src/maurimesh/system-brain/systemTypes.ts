export type SystemLayerStatus =
  | "ACTIVE"
  | "WIRED"
  | "LEARNING"
  | "OPTIMISING"
  | "NEEDS_NATIVE_PROOF"
  | "NEEDS_REVIEW";

export type SystemLayer = {
  id: string;
  name: string;
  status: SystemLayerStatus;
  purpose: string;
  belongsBecause: string;
  optimises: string[];
  dependencies: string[];
  proofBoundary: string;
};

export type ButtonDecision = {
  screen: string;
  buttonTitle: string;
  targetRoute: string;
  decisionLayer: string;
  reason: string;
  status: "CONNECTED" | "RECOMMENDED" | "MISSING_SCREEN" | "NEEDS_NATIVE_PROOF";
};

export type SystemEvolutionSnapshot = {
  atMs: number;
  score: number;
  summary: string;
  activeLayers: number;
  totalLayers: number;
  buttonConnections: ButtonDecision[];
  layerMap: SystemLayer[];
  recommendations: string[];
};
