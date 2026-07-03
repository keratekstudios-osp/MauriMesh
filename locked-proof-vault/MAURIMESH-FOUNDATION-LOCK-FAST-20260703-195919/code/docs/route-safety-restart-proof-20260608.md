# Route Safety Restart Proof

Marker: `ROUTE_SAFETY_RESTART_PROOF_20260608_A`

## Proves

- Route blacklist persists after restart.
- Blacklisted route remains blocked after new engine instance loads persistence.
- Seen-packet duplicate cache is memory-only.
- Duplicate packet detection works inside one process.
- Same packet is accepted after restart because seen-cache is not persisted.

## Command

```bash
bash scripts/run-route-safety-restart-proof.sh
