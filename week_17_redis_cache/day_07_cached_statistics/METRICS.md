# Cache metrics and logs

## Application metrics

| Metric | Type | Allowed labels | Meaning | Expected change scenario |
|---|---|---|---|---|
| cache access | counter | outcome | hit/miss/error | |
| cache loader | counter/timer | outcome | DB fallback work | |
| cache invalidation | counter | outcome | commit callbacks | |
| stampede lock | counter/timer | outcome | acquire/wait/fallback | |
| cache payload bytes | histogram | resource type | size control | |

## Forbidden labels/content

- user ID/email;
- full cache key;
- verification/access token;
- request payload;
- unbounded error/user text.

## Redis/server indicators

| Indicator | Source | Alert/question it answers |
|---|---|---|
| keyspace hits/misses | `INFO stats` | Is cache useful? |
| evicted/expired keys | `INFO stats` | Memory or TTL pressure? |
| used memory/maxmemory | `INFO memory`/config | Near capacity? |
| clients/errors/latency | safe monitoring | Connectivity/load issue? |
| persistence status | `INFO persistence` | Snapshot/AOF healthy if enabled? |

## Evidence

| Scenario | Before | Action | After | Expected | Result |
|---|---|---|---|---|---|
| Hit | | | | | |
| Miss | | | | | |
| Read error | | | | | |
| Invalidation | | | | | |
| Stampede wait | | | | | |

