export const TASK_189_MOBILE_PROOF_EVIDENCE_CLIENT_MARKER =
  "TASK_189_MOBILE_PROOF_EVIDENCE_CLIENT_20260608_A";

const API_BASE =
  process.env.EXPO_PUBLIC_MESH_API_URL ||
  process.env.REACT_APP_MESH_API_URL ||
  "";

export type SaveProofEvidenceResult = {
  ok: boolean;
  marker?: string;
  record?: unknown;
  error?: string;
};

export async function saveTwoPhoneHardwareEvidenceToProofLedger(
  evidenceJson: unknown
): Promise<SaveProofEvidenceResult> {
  if (!API_BASE) {
    return {
      ok: false,
      error: "EXPO_PUBLIC_MESH_API_URL is not configured.",
    };
  }

  const response = await fetch(`${API_BASE}/api/proof/evidence`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      type: "two_phone_hardware_evidence",
      evidenceJson,
    }),
  });

  const json = await response.json().catch(() => ({}));

  if (!response.ok) {
    return {
      ok: false,
      error: json?.error || `HTTP ${response.status}`,
    };
  }

  return json as SaveProofEvidenceResult;
}
