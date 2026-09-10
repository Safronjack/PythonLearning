# День 3: ownership и object scope

Статус: заблокировано до зачёта дня 2.

## Controlled dataset

| Resource | Own actor/org | Foreign actor/org | State | Public/private fields |
|---|---|---|---|---|
| — | — | — | — | — |

## Selector contracts

| Selector | Actor branch | Returned scope | Default | Ordering/eager loading |
|---|---|---|---|---|
| — | — | — | `.none()` | — |

## List/detail/create boundary

| Action | View gate | Queryset scope | Object policy | Server-owned fields | Expected denial |
|---|---|---|---|---|---|
| list | — | — | not per row | — | — |
| retrieve | — | — | — | — | — |
| create | — | not object scope | no object yet | — | — |

## Query budgets

| Endpoint/actor | N=2 | N=20 | SQL roles | Budget regression test |
|---|---:|---:|---|---|
| — | — | — | — | — |

## Сценарии 1–12

| ID | Actor/resource | Prediction | Actual status/rows | Count/fields | DB/side effects |
|---|---|---|---|---|---|
| 1 | — | — | — | — | — |

## Самооценка

1. Где scope применяется к list?
2. Как выполняется detail lookup?
3. Почему object permission не защищает create?
4. Какие fields server-owned?
5. Как доказано отсутствие N+1?
6. Самая полезная ошибка:
7. Вопрос наставнику:
8. Время:

