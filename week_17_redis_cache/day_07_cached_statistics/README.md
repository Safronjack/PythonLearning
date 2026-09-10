# Cached Dealership Statistics API

Статус: шаблон. После допуска сюда копируется принятый Week 16 project; исходник не изменяется.

## Source и versions

- Source path/commit:
- Python/Django/pytest/redis-py:
- PostgreSQL:
- Redis server/CLI:
- Compatibility evidence:

## Safe environment

- PostgreSQL test target proof:
- `TEST_REDIS_URL` proof without secret:
- Unique run prefix:
- Connection/socket timeouts:
- External sentinel:
- Cleanup command/method:

## Clean setup

Опишите установку dependencies, запуск предоставленного test Redis, migrations и tests. Не включайте пароли, tokens и полные DSN.

```text
TODO
```

## Проверочные команды

| Stage | Purpose | Command | Expected | Actual |
|---|---|---|---|---|
| Baseline | Week 16 suite | | | |
| Redis smoke | connection/safety | | | |
| Unit | key/TTL/policies | | | |
| Integration/API | cache/invalidation | | | |
| Concurrency | stampede | | | |
| Full gate | all mandatory | | | |

## Clean runs

| Run | Commit/prefix | Passed/failed/skipped | Duration | Cleanup/sentinel | Result |
|---|---|---|---|---|---|
| 1 | | | | | |
| 2 | | | | | |

## Быстрая диагностика

- Redis unavailable:
- Unsafe target/prefix:
- Unexpected stale response:
- Lock timeout:
- Low hit ratio/high eviction:

