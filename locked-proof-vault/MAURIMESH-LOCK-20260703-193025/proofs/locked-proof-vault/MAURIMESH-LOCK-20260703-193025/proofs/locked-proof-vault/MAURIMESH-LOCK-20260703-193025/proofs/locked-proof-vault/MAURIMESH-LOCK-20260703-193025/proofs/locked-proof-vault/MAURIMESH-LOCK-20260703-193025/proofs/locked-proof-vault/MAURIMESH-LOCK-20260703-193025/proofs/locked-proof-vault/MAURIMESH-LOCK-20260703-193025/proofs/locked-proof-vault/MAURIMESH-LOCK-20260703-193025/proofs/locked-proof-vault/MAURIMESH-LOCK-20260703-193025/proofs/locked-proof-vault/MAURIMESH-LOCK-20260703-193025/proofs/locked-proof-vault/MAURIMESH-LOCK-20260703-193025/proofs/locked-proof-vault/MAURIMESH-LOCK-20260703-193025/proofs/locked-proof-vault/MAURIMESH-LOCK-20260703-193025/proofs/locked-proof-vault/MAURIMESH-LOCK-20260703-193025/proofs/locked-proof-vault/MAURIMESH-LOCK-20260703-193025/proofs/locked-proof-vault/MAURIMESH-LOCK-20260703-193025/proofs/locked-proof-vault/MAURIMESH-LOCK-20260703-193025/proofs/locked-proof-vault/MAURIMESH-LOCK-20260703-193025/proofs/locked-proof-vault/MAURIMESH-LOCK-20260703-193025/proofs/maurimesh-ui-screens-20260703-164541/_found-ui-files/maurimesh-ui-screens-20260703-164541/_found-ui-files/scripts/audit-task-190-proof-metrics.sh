#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "#190 Proof Metrics Spine Audit"
echo "============================================================"

grep -RniE "TASK_190|recordProofMetricEvent|Proof Metrics|proofMetricsSpine|useProofMetrics|send_attempt|ack_received|delivery_failed" \
  app src tests scripts docs 2>/dev/null || true

echo ""
echo "Required checks:"
test -f src/maurimesh/live/proofMetricsSpine.ts && echo "✅ proofMetricsSpine.ts"
test -f src/maurimesh/live/useProofMetrics.ts && echo "✅ useProofMetrics.ts"
test -f app/proof-metrics.tsx && echo "✅ proof metrics screen"
grep -q "recordProofMetricEvent" app/raw-packet-proof.tsx && echo "✅ raw packet proof records metrics"
grep -q "Proof Metrics" app/proof-metrics.tsx && echo "✅ proof metrics UI present"
