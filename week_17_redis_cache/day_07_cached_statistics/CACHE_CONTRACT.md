# Cache contract

## Source и public behavior

- Endpoint/use case:
- PostgreSQL source of truth:
- Authorized scopes:
- Response schema/types/order:
- Baseline queries/loader duration:

## Cache-aside

| Outcome | Redis action | PostgreSQL loader | API response | Metric/log |
|---|---|---|---|---|
| Hit | | no | | |
| Miss | | yes | | |
| Cached empty | | no | | |
| Expired | | yes | | |
| Read error | | per failure policy | | |
| Write error | | already loaded | | |

## Payload/TTL

- Serialization/schema version:
- Positive TTL and allowed staleness:
- Maximum staleness after invalidation failure:
- Jitter range:
- Negative sentinel/TTL:
- TTL=0/None guard:
- Maximum payload size:

## Equivalence evidence

- Cold response hash/summary:
- Warm response hash/summary:
- Types/order/security equal:
- Warm loader/query count:
