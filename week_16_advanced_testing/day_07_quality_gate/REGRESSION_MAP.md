# Regression map

| Critical risk/invariant | Positive test | Boundary/negative test | Level/stage | Current evidence | Gap/action |
|---|---|---|---|---|---|
| role permissions | | | API | | |
| verified/unverified email | | | API/E2E | | |
| insufficient balance | | | integration | | |
| insufficient stock | | | integration | | |
| promotion boundaries | | | unit/integration | | |
| concurrent last unit | | | transaction | | |
| Offer transition/idempotency | | | integration/concurrency | | |
| supplier selection | | | unit/integration | | |
| statistics correctness | | | integration/API | | |
| N+1/query growth | | | integration | | |
| repeated Celery task | — | — | DEFERRED week 18–19 | not implemented | define after Celery lesson |

## Правила карты

- Ссылка ведёт на реальный node ID или scenario ID.
- Один test может покрывать несколько рисков, но это объясняется, а не дублируется как разные запуски.
- `DEFERRED` не считается `PASS`.
- Критический uncovered risk блокирует итог, кроме явно запланированного ещё не изученного инструмента.

