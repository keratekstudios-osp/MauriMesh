#!/usr/bin/env bash
set -e
curl http://localhost:3000/api/health || true
echo ""
curl http://localhost:3000/api/mesh/status || true
echo ""
