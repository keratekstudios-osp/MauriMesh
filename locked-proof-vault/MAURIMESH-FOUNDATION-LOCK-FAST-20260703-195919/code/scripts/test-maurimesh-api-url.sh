#!/usr/bin/env bash
set -euo pipefail

API="https://mauri-mesh-messenger.replit.app/api"

echo ""
echo "============================================================"
echo "TEST MAURIMESH API URL"
echo "============================================================"
echo ""
echo "API=$API"
echo ""

echo "Testing health:"
curl -i "$API/healthz" || true

echo ""
echo "Testing activity:"
curl -i "$API/activity" || true

echo ""
echo "Result guide:"
echo "HTTP 200 = route works"
echo "HTTP 401 = route exists but login/operator token required"
echo "HTTP 404 = route missing"
echo "HTTP 502/503/timeout = API server not running"
echo ""
