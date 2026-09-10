# Scenario matrix: R01–R56

## Правила

Одна строка — один отличимый risk/scenario. Укажите exact command или pytest node ID, фактический API/Redis/PostgreSQL result и cleanup. Допустимы `PASS`, `FAIL`, `N/A with evidence`; обязательный scenario нельзя заменить N/A без согласования.

| ID | Risk/area | Given | Operation | Expected Redis/DB/API | Command/node ID | Actual/cleanup/status |
|---|---|---|---|---|---|---|
| R01 | connection safety | | | | | |
| R02 | PING | | | | | |
| R03 | string | | | | | |
| R04 | missing key | | | | | |
| R05 | decode contract | | | | | |
| R06 | TTL state | | | | | |
| R07 | wrong type | | | | | |
| R08 | outage/cleanup | | | | | |
| R09 | string | | | | | |
| R10 | overwrite | | | | | |
| R11 | counter | | | | | |
| R12 | hash | | | | | |
| R13 | hash missing/partial | | | | | |
| R14 | hash numeric | | | | | |
| R15 | set uniqueness | | | | | |
| R16 | set membership | | | | | |
| R17 | sorted set rank | | | | | |
| R18 | sorted set tie/update | | | | | |
| R19 | stream overview | | | | | |
| R20 | pipeline/transaction | | | | | |
| R21 | uncached baseline | | | | | |
| R22 | cache contract | | | | | |
| R23 | canonical params | | | | | |
| R24 | resource/filter key | | | | | |
| R25 | authorization scope | | | | | |
| R26 | version/key safety | | | | | |
| R27 | cold miss | | | | | |
| R28 | warm hit | | | | | |
| R29 | response equivalence | | | | | |
| R30 | TTL range | | | | | |
| R31 | expiry/reload | | | | | |
| R32 | negative/empty cache | | | | | |
| R33 | dependency map | | | | | |
| R34 | write map/bypass | | | | | |
| R35 | generation init | | | | | |
| R36 | generation increment | | | | | |
| R37 | filter namespace switch | | | | | |
| R38 | commit invalidation | | | | | |
| R39 | rollback no invalidation | | | | | |
| R40 | nested rollback | | | | | |
| R41 | delete/bulk path | | | | | |
| R42 | old reader race | | | | | |
| R43 | concurrent cold miss | | | | | |
| R44 | concurrent warm hit | | | | | |
| R45 | loader exception/cleanup | | | | | |
| R46 | lock ownership/expiry | | | | | |
| R47 | TTL jitter | | | | | |
| R48 | Redis read failure | | | | | |
| R49 | Redis write/lock failure | | | | | |
| R50 | unexpected exception visibility | | | | | |
| R51 | read-only config facts | | | | | |
| R52 | persistence decision | | | | | |
| R53 | eviction/role separation | | | | | |
| R54 | security policy | | | | | |
| R55 | metrics behavior | | | | | |
| R56 | degraded health/clean gate | | | | | |

## Итог

- PASS:
- FAIL:
- N/A with evidence:
- Mandatory skipped/xfail:
- Redis/PostgreSQL safety:
- Cleanup/sentinel:
- Clean runs:
- Итоговый статус:

