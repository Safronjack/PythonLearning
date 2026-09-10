# Redis/cache failure policy

Redis is an accelerator; PostgreSQL remains authoritative.

| Failure | Expected/handled? | Retry/budget | DB loader | API result | Log/metric | Recovery |
|---|---|---|---|---|---|---|
| Connect timeout | | | | | | |
| Command timeout | | | | | | |
| Cache GET error | | | | | | |
| Cache SET error | | | | | | |
| Invalidation error after DB commit | | | | | | |
| Lock acquisition/release error | | | | | | |
| Corrupt/unreadable payload | | | | | | |
| PostgreSQL loader error | | | | | | |
| Programming exception | no broad catch | none | | error | visible | fix code |

## Rules

- Exact handled exception classes:
- Total Redis time budget:
- Idempotent operations eligible for retry:
- Forbidden retries:
- Secret redaction:
- Health/readiness degraded semantics:

