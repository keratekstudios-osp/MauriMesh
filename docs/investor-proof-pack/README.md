# MauriMesh Investor / Company Proof Pack

Status: **READY FOR REVIEW**  
Created: 2026-06-13T17:02:20.483Z

This folder contains the current MauriMesh proof pack for technical review, investor review, company review, or grant review.

## Main Documents

1. `MAURIMESH_INVESTOR_PROOF_PACK.md`
2. `MAURIMESH_DUE_DILIGENCE_SUMMARY.md`
3. `MAURIMESH_TECHNICAL_PROOF_SUMMARY.md`
4. `MAURIMESH_PROOF_LIMITS_AND_NEXT_STEPS.md`
5. `MAURIMESH_PROOF_PACK_INDEX.json`

## Verification Commands

Run from project root:

```bash
node tools/proof-verifiers/verify-store-forward-proof.js
node tools/proof-verifiers/verify-store-forward-hash-manifest.js
node tools/proof-verifiers/verify-maurimesh-master-proof-index.js
node tools/proof-verifiers/verify-maurimesh-investor-proof-pack.js
```

Expected result:

```text
Verdict: PASS
HASH VERDICT: PASS
MASTER INDEX VERDICT: PASS
PROOF PACK VERDICT: PASS
```
