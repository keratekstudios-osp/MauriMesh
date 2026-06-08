import {
  acceptNativeAttestation,
  getRuntimeTruthState,
  isProofCapable,
} from "../runtime/RuntimeTruthEngine";

export const TASK_223_RUNTIME_VERIFY_ROUTE_MARKER =
  "TASK_223_RUNTIME_VERIFY_ROUTE_20260608_A";

export function registerRuntimeVerifyRoute(app: any) {
  app.get("/api/runtime/truth", async (_req: any, res: any) => {
    const truth = getRuntimeTruthState();

    res.json({
      ok: true,
      marker: TASK_223_RUNTIME_VERIFY_ROUTE_MARKER,
      proofCapable: isProofCapable(),
      truth,
    });
  });

  app.post("/api/runtime/verify", async (req: any, res: any) => {
    try {
      const body = req.body || {};

      const attestation = {
        marker: String(body.marker || TASK_223_RUNTIME_VERIFY_ROUTE_MARKER),
        source: String(body.source || "unknown"),
        platform: String(body.platform || "unknown"),
        appPackage: body.appPackage ? String(body.appPackage) : undefined,
        nativeModulePresent: Boolean(body.nativeModulePresent),
        permissionsGranted: Boolean(body.permissionsGranted),
        scanActive: Boolean(body.scanActive),
        discoveredCount: Number(body.discoveredCount || 0),
        features: Array.isArray(body.features)
          ? body.features.map((feature: unknown) => String(feature))
          : [],
        createdAt: String(body.createdAt || new Date().toISOString()),
        deviceModel: body.deviceModel ? String(body.deviceModel) : undefined,
        buildId: body.buildId ? String(body.buildId) : undefined,
        detail:
          body.detail && typeof body.detail === "object"
            ? body.detail
            : {},
      };

      const accepted =
        attestation.source !== "simulation" &&
        attestation.platform === "android" &&
        attestation.nativeModulePresent === true &&
        attestation.features.includes("native_bridge");

      const truth = accepted
        ? acceptNativeAttestation(attestation)
        : getRuntimeTruthState();

      res.status(accepted ? 202 : 400).json({
        ok: accepted,
        marker: TASK_223_RUNTIME_VERIFY_ROUTE_MARKER,
        accepted,
        proofCapable: truth.proofCapable,
        truth,
        truthBoundary:
          "Native attestation is accepted only from a real Android native bridge. Simulation cannot promote proof scope.",
      });
    } catch (error) {
      res.status(500).json({
        ok: false,
        marker: TASK_223_RUNTIME_VERIFY_ROUTE_MARKER,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  });
}
