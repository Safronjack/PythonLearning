# День 3: deterministic boundaries — рабочий журнал

## Прогнозы до запуска

1. Активна ли акция точно в `start_at`?
2. Активна ли она точно в `end_at`?
3. Выполнится ли `on_commit` callback после rollback?
4. Что изменится при другой timezone?

## Dependency inventory

| Dependency | Consumer path | Risk | Control/seam | Real integration pair |
|---|---|---|---|---|
| | | | | |

## Interval contract

- Timezone policy:
- Start inclusive/exclusive:
- End inclusive/exclusive:
- Invalid interval behavior:

## S25–S34

| ID | Controlled input/failure | Expected DB/result/effect | Node ID | UTC result | Second timezone result | Status |
|---|---|---|---|---|---|---|
| S25 | | | | | | |

## External-effect safety

- Provider/fake path:
- Patch/injection location:
- Commit call evidence:
- Rollback no-call evidence:
- Failure/repeat contract:
- Proof no real network/email:

## Самооценка

- Что получилось:
- Где нужна подсказка:
- Что было недетерминированным раньше:
- Моя оценка /10 и почему:

