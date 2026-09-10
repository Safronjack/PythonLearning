# День 4: async testing decision — рабочий журнал

## Прогнозы до запуска

1. Есть ли в production code `async def`?
2. Выполняется ли coroutine без `await`?
3. Нужен ли новый plugin?
4. Какая ближайшая I/O boundary?

## Inventory

- Production scope searched:
- Excluded paths:
- Commands:

| Location | Entry point/caller | Awaited I/O/task/bridge | Production path? | Decision impact |
|---|---|---|---|---|
| | | | | |

## Решение

- Ветка: A — async path / B — no async path
- Обоснование:
- Runner/plugin:
- Compatibility evidence:
- Dependency change or reason none:

## S35–S40

| ID | Aspect | Test/node ID or N/A evidence | Expected | Actual | Status |
|---|---|---|---|---|---|
| S35 | async entry point | | | | |
| S36 | awaited I/O | | | | |
| S37 | task/error propagation | | | | |
| S38 | cancellation/timeout | | | | |
| S39 | resource cleanup | | | | |
| S40 | sync↔async boundary | | | | |

## Самооценка

- Что получилось:
- Где нужна подсказка:
- Почему выбранная ветка честна:
- Моя оценка /10 и почему:

