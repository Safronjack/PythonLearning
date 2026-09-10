# Redis operations runbook

## Actual test environment, sanitized

| Item | Safe read-only source | Actual |
|---|---|---|
| Redis version | | |
| RDB status/save policy | | |
| AOF status | | |
| maxmemory/policy | | |
| used memory | | |
| hits/misses/evicted/expired | | |

## Role decisions

| Role | Loss tolerance | Persistence | TTL/eviction | Isolation | Rationale |
|---|---|---|---|---|---|
| Week 17 cache | | | | | |
| Week 18 broker | | | | | |
| Future result backend | | | | | |

## Security checklist

- [ ] Redis port доступен только trusted network/application.
- [ ] Named ACL user имеет least privilege.
- [ ] Admin/flush/config commands запрещены application identity.
- [ ] TLS используется при недоверенной сети.
- [ ] Credentials поступают из secret environment/storage.
- [ ] Logs/reports не содержат credentials, keys с PII или payload.
- [ ] Redis process не требует root.

## Диагностика

### Низкий hit ratio

- Проверить:
- Метрики:
- Safe action:

### Высокие evictions/memory

- Проверить:
- Метрики:
- Safe action:

### Redis unavailable

- Application behavior:
- Readiness/degraded signal:
- Recovery verification:

