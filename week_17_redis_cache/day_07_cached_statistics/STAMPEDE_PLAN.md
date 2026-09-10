# Stampede protection plan

## Contract

- Protected hot key:
- Loader:
- Lock name derivation:
- Owner token mechanism:
- Lock TTL:
- Blocking/wait/poll deadline:
- Double-check point:
- Non-owner fallback:
- Loader exception cleanup:

## Concurrency evidence

| Scenario | Callers | Cache initial | Loader behavior | Expected calls/responses/lock | Actual |
|---|---:|---|---|---|---|
| Cold success | 8 | missing | success | | |
| Warm | 8 | present | must not run | | |
| Loader error | 2+ | missing | raises | | |
| Owner lock expires | 2+ | missing | delayed | | |
| Wait deadline | 2+ | missing | delayed | | |

## Safety assertions

- [ ] Atomic acquisition through supported primitive.
- [ ] Lock has TTL.
- [ ] Only owner releases.
- [ ] `finally` cleanup.
- [ ] All workers have timeout/join.
- [ ] Redis lock does not protect PostgreSQL money/stock.

