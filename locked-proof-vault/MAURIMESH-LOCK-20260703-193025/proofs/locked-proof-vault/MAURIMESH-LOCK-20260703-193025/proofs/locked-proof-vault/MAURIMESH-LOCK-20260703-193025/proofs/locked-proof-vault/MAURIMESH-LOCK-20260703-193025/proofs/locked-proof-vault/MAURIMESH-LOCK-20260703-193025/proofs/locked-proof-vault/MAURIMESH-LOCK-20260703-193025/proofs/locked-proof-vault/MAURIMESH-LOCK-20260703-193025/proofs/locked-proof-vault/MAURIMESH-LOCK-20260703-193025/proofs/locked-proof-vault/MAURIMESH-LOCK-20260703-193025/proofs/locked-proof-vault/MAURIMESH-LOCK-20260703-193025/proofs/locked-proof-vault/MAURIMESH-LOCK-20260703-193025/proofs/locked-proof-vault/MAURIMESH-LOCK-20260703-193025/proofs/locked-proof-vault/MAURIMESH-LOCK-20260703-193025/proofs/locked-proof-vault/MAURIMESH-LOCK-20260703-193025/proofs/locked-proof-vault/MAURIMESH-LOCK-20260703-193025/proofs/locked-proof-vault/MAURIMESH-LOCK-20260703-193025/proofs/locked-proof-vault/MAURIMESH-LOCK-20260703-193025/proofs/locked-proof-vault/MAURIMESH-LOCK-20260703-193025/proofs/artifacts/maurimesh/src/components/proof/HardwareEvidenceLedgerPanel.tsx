import React, { useEffect, useState } from "react";

export const TASK_189_WEB_HARDWARE_EVIDENCE_PANEL_MARKER =
  "TASK_189_WEB_HARDWARE_EVIDENCE_PANEL_20260608_A";

type HardwareEvidenceEntry = {
  id: string;
  type: "two_phone_hardware_evidence";
  createdAt: string;
  sha256: string;
  evidenceJson: unknown;
};

export function HardwareEvidenceLedgerPanel() {
  const [entries, setEntries] = useState<HardwareEvidenceEntry[]>([]);
  const [error, setError] = useState<string>("");

  useEffect(() => {
    fetch("/api/proof/evidence?type=two_phone_hardware_evidence")
      .then((res) => res.json())
      .then((json) => {
        if (!json?.ok) throw new Error(json?.error || "Failed to load evidence");
        setEntries(json.entries || []);
      })
      .catch((err) => setError(err instanceof Error ? err.message : String(err)));
  }, []);

  return (
    <section style={{ border: "1px solid rgba(0,208,132,0.35)", borderRadius: 18, padding: 16, marginTop: 16 }}>
      <h2>Hardware Evidence Ledger</h2>
      <p>Filter: <code>type = two_phone_hardware_evidence</code></p>
      <p style={{ fontSize: 12 }}>{TASK_189_WEB_HARDWARE_EVIDENCE_PANEL_MARKER}</p>

      {error ? <pre style={{ color: "#EF4444" }}>{error}</pre> : null}

      {entries.length === 0 ? (
        <p>No hardware evidence entries saved yet.</p>
      ) : (
        entries.map((entry) => (
          <details key={entry.id} style={{ marginTop: 12 }}>
            <summary>
              {entry.createdAt} · {entry.type} · {entry.sha256?.slice(0, 12)}
            </summary>
            <pre style={{ whiteSpace: "pre-wrap", overflowX: "auto" }}>
              {JSON.stringify(entry.evidenceJson, null, 2)}
            </pre>
          </details>
        ))
      )}
    </section>
  );
}
