# Invalidation map

## Strategy

- Exact delete / generation:
- Generation key/init/increment:
- Payload key relation:
- Old-key TTL:
- Missing Redis behavior:
- Invalidation-failure stale window/visibility:

| Statistics dependency | Fields | Write entry points | Transaction owner | `on_commit` action | Test/node ID |
|---|---|---|---|---|---|
| | | | | | |

## Commit matrix

| Scenario | DB outcome | Callback expected | Generation/cache expected | Next API response |
|---|---|---|---|---|
| Commit | | | | |
| Inner rollback | | | | |
| Outer rollback | | | | |
| Redis error after commit | | | | |
| Concurrent increments | | | | |
| Old reader finishes late | | | | |

## Known bypass audit

- Signals:
- `QuerySet.update()`/bulk:
- Raw SQL:
- Admin/API/service paths:
- Forbidden or additionally handled paths:
