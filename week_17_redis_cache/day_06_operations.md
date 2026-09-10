# День 6: Redis operations — рабочий журнал

## Прогнозы

1. Нужна ли persistence чистому cache?
2. Что случится при `noeviction` и full memory?
3. Можно ли дать cache и broker одну policy?
4. Какие metrics изменятся на hit/miss?

## Sanitized actual config

| Fact | Safe command/source | Actual | Meaning |
|---|---|---|---|
| | | | |

## Role decision

| Role | Loss tolerance | TTL/eviction | Persistence | Isolation | Main risk |
|---|---|---|---|---|---|
| Cache | | | | | |
| Future broker | | | | | |
| Future result backend | | | | | |

## R51–R56

| ID | Check/input | Expected config/metric/health | Actual | Status |
|---|---|---|---|---|
| R51 | | | | |

## Security checklist

- Network/firewall:
- ACL identity/commands:
- TLS:
- Secret source/rotation:
- Forbidden commands:
- Log redaction:

## Самооценка

- Что получилось:
- Что непонятно:
- Как разделены три роли:
- Моя оценка /10:

