# PostgreSQL-прототип базы автосалонов

Статус: **не начато**.

## Назначение

TODO

## Safety boundary

- Точное имя учебной database: TODO
- Как проверить current connection: TODO
- Как исключить production/чужую database: TODO
- Какие destructive operations отсутствуют: TODO

## Prerequisites

TODO: PostgreSQL client/server availability is checked only when this day is activated.

## Порядок запуска

1. Проверить connection и пустую учебную database.
2. Выполнить `schema_postgresql.sql`.
3. Выполнить `seed_postgresql.sql`.
4. Выполнить `queries_postgresql.sql`.
5. Выполнить `checks_postgresql.sql`.

Добавь точные безопасные commands только после согласования среды. Не добавляй credentials.

## Schema scope

TODO

## Seed contract

TODO

## Query catalog

TODO

## Constraint and diagnostic results

| Check | Expected | Actual | Status |
|---|---|---|---|
| TODO | TODO | TODO | TODO |

## SQLite vs PostgreSQL

TODO

## Known limitations

TODO

## Переход к Django

TODO: what becomes models/migrations and what still requires design.

## Самооценка

1. Что получилось:
2. Где было трудно:
3. Какие constraints поймали ошибки:
4. Какой query был сложнее всего:
5. Что пока не могу объяснить:
