#!/usr/bin/env bash
set -euo pipefail

BASE="${1:-http://localhost:3000}"

echo ""
echo "============================================================"
echo "TESTING MAURIMESH FULL INTELLIGENT API DRIVER"
echo "BASE: $BASE"
echo "============================================================"
echo ""

pretty() {
  node -e 'let s="";process.stdin.on("data",d=>s+=d);process.stdin.on("end",()=>{try{console.log(JSON.stringify(JSON.parse(s),null,2))}catch(e){console.log(s)}})'
}

echo ""
echo "1. Health check"
curl -sS "$BASE/api/health" | pretty || true

echo ""
echo "2. Ingest BLE send event"
curl -sS -X POST "$BASE/api/activity/ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "packetId":"MM-INTEL-TEST-001",
    "stage":"TX_BLE_START",
    "status":"SEND",
    "transport":"BLE",
    "fromPeerId":"PHONE-A",
    "toPeerId":"PHONE-B",
    "payloadBytes":128,
    "detail":"Test BLE packet send into intelligent API driver"
  }' | pretty || true

echo ""
echo "3. Ingest waiting ACK event"
curl -sS -X POST "$BASE/api/activity/ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "packetId":"MM-INTEL-TEST-001",
    "stage":"WAITING_FOR_ACK",
    "status":"PENDING_ACK",
    "transport":"BLE",
    "fromPeerId":"PHONE-A",
    "toPeerId":"PHONE-B",
    "detail":"Testing ACK intelligence state"
  }' | pretty || true

echo ""
echo "4. Read activity intelligence"
curl -sS "$BASE/api/activity" | pretty || true

echo ""
echo "5. Request packet route decision"
curl -sS -X POST "$BASE/api/mesh/packet/decision" \
  -H "Content-Type: application/json" \
  -d '{
    "packetId":"MM-INTEL-TEST-001",
    "payloadBytes":128,
    "preferredTransport":"BLE",
    "targetPeerId":"PHONE-B",
    "ttl":8
  }' | pretty || true

echo ""
echo "6. Ingest ACK delivered event"
curl -sS -X POST "$BASE/api/activity/ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "packetId":"MM-INTEL-TEST-001",
    "stage":"ACK",
    "status":"DELIVERED",
    "transport":"BLE",
    "fromPeerId":"PHONE-B",
    "toPeerId":"PHONE-A",
    "latencyMs":42,
    "detail":"Test ACK delivered into intelligent API driver"
  }' | pretty || true

echo ""
echo "7. Final activity state"
curl -sS "$BASE/api/activity" | pretty || true

echo ""
echo "============================================================"
echo "TEST COMPLETE"
echo "============================================================"
