# Redis keyspace contract

## Общие правила

- Environment/service/schema version:
- Run/test prefix:
- Encoding/canonicalization:
- Maximum key/input length:
- PII/secret exclusion:
- Cleanup ownership:

| Key kind | Format/example with fake IDs | Type | Owner | TTL | Source | Readers | Writers/invalidation |
|---|---|---|---|---:|---|---|---|
| statistics generation | | string/integer | | | PostgreSQL change sequence | | |
| statistics payload | | string/hash | | | PostgreSQL | | |
| negative sentinel | | string | | | PostgreSQL absence | | |
| single-flight lock | | string/lock | | | coordination only | | |
| lab keys | | mixed | student run | | synthetic | | cleanup |

## Scope tests

| Changed input | Same/different key expected | Actual |
|---|---|---|
| Query parameter order only | same | |
| Dealership id | different | |
| Organization/permission scope | different | |
| Schema version | different | |
| Generation | different | |

## Запрещённые операции

- [ ] Нет `FLUSHALL`.
- [ ] Нет `FLUSHDB`.
- [ ] Нет `KEYS *`.
- [ ] Нет raw email/token/credential в key.
- [ ] Cleanup ограничена точным owned prefix.

