# Architecture decisions: scaling и выбор хранилища

Статус: **не начато**.

## Environment и источники

- PostgreSQL version: TODO
- Official PostgreSQL docs: TODO
- Official MySQL docs/version: TODO
- PostGIS docs: TODO
- Measured workload from weeks 6–7: TODO

## Physical vs logical replication

TODO: comparison matrix and current decision.

## Read-after-write routing

| Use case | Required consistency | Primary/replica | Допустимый lag | Причина |
|---|---|---|---|---|
| Покупка завершилась | TODO | TODO | TODO | TODO |
| Каталог | TODO | TODO | TODO | TODO |
| Аналитика | TODO | TODO | TODO | TODO |
| Проверка остатка перед lock | TODO | TODO | TODO | TODO |
| Audit view | TODO | TODO | TODO | TODO |

## Replica vs backup failure matrix

TODO

## Sharding

TODO: compare `dealership_id`, country and customer hash; decide now and set revisit trigger.

## CAP/PACELC scenario

TODO

## PostgreSQL vs MySQL

TODO: at least eight project-specific, official-source-backed criteria.

## PostGIS

TODO: current requirements, country-code option, spatial trigger, geometry/geography, index/query and decision.

## Самооценка

1. Что получилось самостоятельно:
2. Какое решение было самым трудным:
3. Где не хватает измерений:
4. Какой revisit trigger самый важный:
5. Что пока не могу объяснить:
