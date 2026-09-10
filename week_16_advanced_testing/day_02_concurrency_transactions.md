# День 2: transactions и concurrency — рабочий журнал

## Прогнозы до запуска

1. Что случится без lock/check в одной transaction?
2. Можно ли гарантировать, какой buyer победит?
3. Что должен увидеть второй worker?
4. Какие rows обязаны остаться согласованными?

## Environment safety

- Database vendor/version:
- Test database name/alias proof:
- Transaction marker/fixture:
- Timeout policy:
- Connection cleanup:

## Transaction map

| Step | Row/resource | Read/write/lock | Possible failure | Rollback expectation |
|---|---|---|---|---|
| | | | | |

## Worker design

- Public service called:
- Synchronization primitive/point:
- Separate connection proof:
- Result/exception collection:
- Join/timeout/hang diagnostics:

## S11–S24

| ID | Initial state | Worker/actions | Allowed outcomes | Final invariants | Node ID | Actual/status |
|---|---|---|---|---|---|---|
| S11 | | | | | | |

## Repeat evidence

- Command:
- Repetitions:
- Outcome counts:
- Slowest duration:
- Unexpected result:

## Самооценка

- Что получилось:
- Где нужна подсказка:
- Как я исключил зависание:
- Моя оценка /10 и почему:

