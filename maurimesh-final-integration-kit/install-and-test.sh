#!/usr/bin/env bash
set -e

echo ""
echo "MauriMesh Final Integration Kit Check"
echo "===================================="
echo ""

if [ ! -f "docs/REPLIT_AGENT_FINAL_RULES.md" ]; then
  echo "Missing rules file."
  exit 1
fi

if [ ! -f "docs/REMAINING_100_PERCENT_CHECKLIST.md" ]; then
  echo "Missing checklist file."
  exit 1
fi

echo "Rules file found."
echo "Checklist file found."
echo "Folder structure ready."
echo ""
echo "MauriMesh final integration kit base installed."
echo ""
echo "Next:"
echo "Tell Replit Agent to read:"
echo "maurimesh-final-integration-kit/docs/REPLIT_AGENT_FINAL_RULES.md"
echo "maurimesh-final-integration-kit/docs/REMAINING_100_PERCENT_CHECKLIST.md"
