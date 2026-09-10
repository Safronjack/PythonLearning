# День 6: reliability audit — рабочий журнал

## Прогнозы до запуска

1. Какие tests вероятнее всего зависят от порядка?
2. Какие зависят от timezone/random?
3. Где возможен N+1?
4. Что сохранится при первом flaky failure?

## Environment fingerprint

- Commit:
- Python/Django/pytest/pytest-django:
- PostgreSQL:
- Settings/markers/workers:
- Timezone/locale:
- Random policy/seed:
- Secret-safe environment names:

## S51–S60

| ID | Audit | Command/input | Expected invariant | Actual result | Failure class/fix | Status |
|---|---|---|---|---|---|---|
| S51 | environment | | | | | |

## Repeat/order evidence

- Isolated repeat:
- Group repeat:
- A→B:
- B→A:
- Full after group:

## Query/time evidence

| Endpoint/test | Small dataset/query count | Larger dataset/query count | Budget | Bounded duration | Result |
|---|---:|---:|---:|---:|---|
| | | | | | |

## Найденные нестабильности

| Symptom | Test/product/environment | Root cause | Fix | Repeat evidence |
|---|---|---|---|---|
| | | | | |

## Самооценка

- Что получилось:
- Где нужна подсказка:
- Почему retry не использован:
- Моя оценка /10 и почему:

