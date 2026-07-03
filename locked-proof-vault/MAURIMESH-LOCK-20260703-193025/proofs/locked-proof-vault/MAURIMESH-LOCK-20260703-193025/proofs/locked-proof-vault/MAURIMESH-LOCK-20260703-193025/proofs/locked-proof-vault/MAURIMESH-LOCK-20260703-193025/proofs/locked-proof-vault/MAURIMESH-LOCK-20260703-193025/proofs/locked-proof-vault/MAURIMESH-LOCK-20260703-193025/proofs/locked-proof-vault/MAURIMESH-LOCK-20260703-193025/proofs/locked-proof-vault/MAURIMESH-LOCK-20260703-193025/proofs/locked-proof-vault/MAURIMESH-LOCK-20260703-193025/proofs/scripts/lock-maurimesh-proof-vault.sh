#!/usr/bin/env bash
set -euo pipefail

VAULT="archives/maurimesh-locked-proof-vault"
HASH_FILE="$VAULT/VAULT_SHA256SUMS.txt"
LOCK_FILE="$VAULT/VAULT_LOCK_CERTIFICATE.md"

if [ ! -d "$VAULT" ]; then
  echo "ERROR: Proof vault not found: $VAULT"
  exit 1
fi

echo ""
echo "============================================================"
echo "LOCKING MAURIMESH PROOF VAULT"
echo "============================================================"
echo ""

rm -f "$HASH_FILE"

find "$VAULT" \
  -type f \
  ! -name "VAULT_SHA256SUMS.txt" \
  ! -name "VAULT_LOCK_CERTIFICATE.md" \
  -print0 \
  | sort -z \
  | xargs -0 shasum -a 256 > "$HASH_FILE"

ROOT_HASH="$(shasum -a 256 "$HASH_FILE" | awk '{print $1}')"
LOCKED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat > "$LOCK_FILE" <<CERT
# MauriMesh Proof Vault Lock Certificate

Locked UTC: $LOCKED_AT

Vault:

\`\`\`txt
$VAULT
\`\`\`

Root hash:

\`\`\`txt
$ROOT_HASH
\`\`\`

Hash file:

\`\`\`txt
$HASH_FILE
\`\`\`

Locked proofs:

\`\`\`txt
MM-PROOF-002-2HOP
MM-PROOF-003-3DEVICE-HOP
MM-PROOF-004-STORE-FORWARD
\`\`\`

Truth rule:

\`\`\`txt
A proof is valid only when the same packetId appears across every required device role and every required proof stage.
\`\`\`
CERT

echo "VAULT LOCKED"
echo "Root hash: $ROOT_HASH"
echo "Hash file: $HASH_FILE"
echo "Certificate: $LOCK_FILE"
