# Route Safety Restart Proof

Marker: `ROUTE_SAFETY_RESTART_PROOF_20260608_A`

## Proves

- route blacklist persists after restart
- blacklisted route remains blocked after new engine instance loads persistence
- seen-packet duplicate cache is memory-only
- duplicate packet detection works inside one process
- same packet is accepted after restart because seen-cache is not persisted

## Command

```bash
bash scripts/run-route-safety-restart-proof.sh
