# Итоговый PostgreSQL readiness audit

Статус: **не начато**.

## Safety boundary

- Exact learning database: TODO
- PostgreSQL version: TODO
- Database user: TODO
- Application name: TODO
- Fixture state: TODO
- Timeouts: TODO
- Cleanup/reconciliation: TODO

## Prerequisites

- Week 6 schema/design accepted: TODO
- Week 7 transaction/performance audit accepted: TODO
- Week 8 days 1–6 accepted: TODO

## Run order

TODO

## Evidence index

| Decision | Evidence file/query | Measured / inferred / deferred | Revisit trigger |
|---|---|---|---|
| MVCC/long transactions | TODO | TODO | TODO |
| Vacuum/autovacuum | TODO | TODO | TODO |
| WAL/recovery | TODO | TODO | TODO |
| TOAST/projections | TODO | TODO | TODO |
| Functions/triggers | TODO | TODO | TODO |
| Partitioning | TODO | TODO | TODO |
| Replication/read routing | TODO | TODO | TODO |
| Sharding | TODO | TODO | TODO |
| PostgreSQL/MySQL | TODO | TODO | TODO |
| PostGIS | TODO | TODO | TODO |

## Results of 30 required scenarios

TODO

## Known limitations

TODO

## Deferred work

TODO: Django models/migrations, ORM transaction/loading tests and production operations.

## Самооценка

1. Что получилось самостоятельно:
2. Какой риск оказался самым важным:
3. Какое усложнение было отклонено и почему:
4. Какие conclusions основаны на измерениях:
5. Что пока не могу объяснить:
