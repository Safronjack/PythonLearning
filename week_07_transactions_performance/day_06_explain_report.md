# День 6: отчёт по планам и N+1

Статус: **не начато**.

## Environment

TODO: PostgreSQL version, fixture version, row counts and relevant settings.

## Plan vocabulary своими словами

TODO

## Plans

| Plan | Query/grain | Parameters | Main nodes | Estimates vs actual | Rows × loops | Buffers | Conclusion |
|---|---|---|---|---|---|---|---|
| P01 | TODO | TODO | TODO | TODO | TODO | TODO | TODO |

## Controlled optimization

### Baseline and correctness

TODO

### Hypothesis

TODO

### Change

TODO

### Same-result verification

TODO

### Plan after and trade-off

TODO

### Keep/reject decision

TODO

## Safe modifying EXPLAIN ANALYZE

TODO: prove execution and rollback.

## N+1

| Variant | N | SQL statement count | Result matches | Complexity of query count |
|---|---:|---:|---|---|
| N+1 | TODO | TODO | TODO | TODO |
| Set-based | TODO | TODO | TODO | TODO |

## Query budgets

| Use case | Budget | What is included | Future Django check |
|---|---:|---|---|
| TODO | TODO | TODO | TODO |

## Самооценка

1. Что получилось:
2. Где прогноз отличался:
3. Какой plan node был главным:
4. Что измерено фактически:
5. Что пока не могу объяснить:
