# MauriMesh Store-Forward Delay Proof — Hash Manifest

## Proof Identity

- Proof: MauriMesh Store-Forward Delay Proof
- Packet ID: `MMSF-TEJFNH-K3FKYM`
- Archive status: **Tamper-evident hash manifest created**
- Hash algorithm: **SHA-256**
- Created at: 2026-06-13T16:56:29.463Z

## Purpose

This manifest seals the cloned proof archive, verifier, external verifier certificate, and JSON verifier report.

If any sealed file is edited, replaced, truncated, or corrupted, its SHA-256 hash will change and the manifest verification will fail.

## Sealed Files

| # | File | Size bytes | SHA-256 |
|---:|---|---:|---|
| 1 | `docs/proof-archives/store-forward/store_forward_MMSF-TEJFNH-K3FKYM.log` | 1684 | `29beeda1422ec4153b10aa8ae93d7ee37d4748b94fff7128d1aa6ce5a4a421a3` |
| 2 | `tools/proof-verifiers/verify-store-forward-proof.js` | 8948 | `8bbb9100a93865b033b8a3cfc3db6197ce67a9d95ec5e4c5fbf3be8f49066f64` |
| 3 | `docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_certificate.md` | 2588 | `52f3a7cbc8cf91e9a957fd4d4d62b357c26d25551140a0f3201b92cae5335aa6` |
| 4 | `docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_verifier_report.json` | 3847 | `156a099efbd265129aab684b4381b5feeffab76f8eb18535c33524fa7dd219ae` |

## Verification Rule

Run:

```bash
node tools/proof-verifiers/verify-store-forward-hash-manifest.js
```

Expected result:

```text
HASH VERDICT: PASS
```
