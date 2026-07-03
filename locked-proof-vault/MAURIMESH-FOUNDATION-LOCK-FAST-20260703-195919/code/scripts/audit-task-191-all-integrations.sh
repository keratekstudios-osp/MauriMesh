#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "#191 All Integrations Audit"
echo "============================================================"

grep -RniE "TASK_191|Integration Hub|useAllIntegrations|deliveryAnalytics|ackTracking|storeForward|routeHealth|latency" \
  app src tests scripts docs 2>/dev/null || true

echo ""
echo "Required checks:"
test -f src/maurimesh/integration/allIntegrationsBridge.ts && echo "✅ allIntegrationsBridge.ts"
test -f src/maurimesh/integration/useAllIntegrations.ts && echo "✅ useAllIntegrations.ts"
test -f app/integration-hub.tsx && echo "✅ integration hub screen"
test -f app/delivery-analytics.tsx && echo "✅ delivery analytics screen"
test -f app/ack-tracking.tsx && echo "✅ ACK tracking screen"
test -f app/store-forward-queue.tsx && echo "✅ store-forward queue screen"
test -f app/latency-monitoring.tsx && echo "✅ latency monitoring screen"
test -f app/route-health.tsx && echo "✅ route health screen"
grep -q "Integration Hub" app/dashboard.tsx && echo "✅ dashboard Integration Hub link"
