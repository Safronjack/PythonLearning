# День 6: normalization и первая ERD

Статус: **не начато**.

## Anomalies исходной плоской структуры

### Update anomalies

TODO

### Insert anomaly

TODO

### Delete anomaly

TODO

### Repeating groups и dependencies

TODO

### Намеренный historical snapshot

TODO

## Шаг к 1NF

TODO: tables, grain и устранённая проблема.

## Шаг к 2NF

TODO: candidate/composite keys и partial dependencies.

## Шаг к 3NF

TODO: transitive dependencies.

## Первая ERD

```mermaid
erDiagram
    %% TODO: entities, PK/FK, cardinality и labels
```

## Grain и lifecycle entities

| Entity | Одна row представляет | Current/history/derived | Deletion policy |
|---|---|---|---|
| TODO | TODO | TODO | TODO |

## Соответствие требованиям

| Требование | Entity/relation | Source of truth | История или состояние | Открытый вопрос |
|---|---|---|---|---|
| Остатки | TODO | TODO | TODO | TODO |
| Лучшие поставщики | TODO | TODO | TODO | TODO |
| Offer | TODO | TODO | TODO | TODO |
| Акции | TODO | TODO | TODO | TODO |
| Продажи | TODO | TODO | TODO | TODO |
| Баланс | TODO | TODO | TODO | TODO |

## Вопросы product owner

1. TODO
2. TODO
3. TODO
4. TODO
5. TODO

## Denormalization candidates

| Candidate | Source of truth | Update/refresh | Freshness | Reconciliation |
|---|---|---|---|---|
| TODO | TODO | TODO | TODO | TODO |

## Самооценка

1. Что получилось:
2. Где было трудно:
3. Какая cardinality пока непонятна:
4. Как ERD сверена с DDL:
