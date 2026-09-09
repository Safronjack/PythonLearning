# Неделя 8. Внутренности PostgreSQL и масштабирование

Статус: **подготовлена заранее и заблокирована до полного зачёта недель 0–7**.

Текущий активный модуль остаётся `week_00_basics`. Эта папка не меняет порядок обучения и не является разрешением пропустить предыдущие недели.

## Зачем нужна эта неделя

На неделях 6–7 база данных рассматривалась со стороны схемы, SQL, транзакций, индексов и планов. Теперь нужно понять, почему PostgreSQL хранит несколько версий строки, откуда появляются dead tuples, зачем нужны WAL и autovacuum и какие проблемы действительно решают partitioning, replication и sharding.

Цель — не стать DBA за семь дней. К концу блока ученик должен уметь безопасно разговаривать с DBA/SRE, замечать эксплуатационные риски в своей Django-схеме и не предлагать масштабирование без измеримой причины.

## Результат недели

К концу модуля ученик умеет:

- объяснять связь transaction, snapshot, tuple version, `xmin`, `xmax` и `ctid`;
- отличать logical row от её физических версий;
- объяснять, почему долгие transactions мешают очистке старых версий;
- читать основные показатели `pg_stat_user_tables` без объявления приблизительных счётчиков абсолютной истиной;
- различать `VACUUM`, `ANALYZE`, autovacuum и `VACUUM FULL`;
- объяснять bloat, visibility map и XID wraparound на прикладном уровне;
- объяснять правило write-ahead logging, роль checkpoint и общую схему crash recovery/PITR;
- измерять приблизительный объём WAL через LSN на отдельной учебной базе;
- понимать назначение TOAST и не считать размер видимого значения размером всей строки;
- выбирать между function, procedure, trigger и application service;
- писать небольшую чистую SQL-function и безопасный audit-trigger;
- проектировать declarative partitioning и доказывать partition pruning через `EXPLAIN`;
- отличать partitioning, replication и sharding;
- применять CAP/PACELC только к распределённому сценарию, а не к одной PostgreSQL-инстанции;
- сравнивать PostgreSQL и MySQL по требованиям проекта, а не по лозунгам;
- принять обоснованное решение, нужен ли проекту PostGIS;
- подготовить PostgreSQL readiness audit перед началом Django.

## Предварительные требования

- Недели 0–7 завершены полностью.
- Итоговый PostgreSQL-прототип недели 6 принят минимум на 8/10.
- Transaction/performance audit недели 7 принят минимум на 8/10.
- Реально выполнены двухсессионные опыты недели 7.
- Ученик объясняет transaction boundary, lock order, retry contract и минимум шесть index decisions.
- В `week_07_transactions_performance/ASSESSMENT.md` указано: «Допуск к неделе 8: да».

## Связь с итоговым Django-проектом

Неделя готовит решения, которые понадобятся позже:

- частые обновления остатков и Offer не должны незаметно накапливать bloat;
- долгие web/worker transactions не должны удерживать старый snapshot;
- backup — это не то же самое, что replica;
- replica не отменяет transaction correctness на primary;
- таблица продаж может стать кандидатом на partitioning только после появления объёма и lifecycle-запросов;
- триггеры допустимы для узкого database-level аудита, но не должны прятать основной сценарий покупки;
- географический поиск по расстоянию требует другой модели, чем фильтр по стране;
- шардирование не вводится до доказанного предела одной корректно настроенной базы.

## Структура

- [THEORY.md](THEORY.md) — полный конспект с примерами, прогнозами и вопросами;
- [PRACTICE.md](PRACTICE.md) — семь последовательных практических дней;
- [ASSESSMENT.md](ASSESSMENT.md) — журнал оценок, ошибок и пересдач;
- [notes.md](notes.md) — личный словарь и журналы наблюдений;
- [fixtures/postgresql_lab.sql](fixtures/postgresql_lab.sql) — отдельная безопасная schema и воспроизводимые данные;
- `day_01_mvcc.sql` — snapshots и версии строк;
- `day_02_vacuum_autovacuum.sql` — dead tuples, maintenance и freeze-risk;
- `day_03_wal_toast.sql` — WAL/LSN, checkpoint-наблюдения и TOAST;
- `day_04_routines_triggers.sql` — function, procedure и audit-trigger;
- `day_05_partitioning.sql` — range partitions и pruning;
- `day_06_scaling_observability.sql` — read-only наблюдение replication readiness;
- `day_06_architecture_decisions.md` — replication/sharding, CAP/PACELC, PostgreSQL/MySQL и PostGIS;
- `day_07_postgresql_readiness_audit/` — итоговый аудит перед Django.

## Учебная среда

Основная практика требует PostgreSQL. SQLite не показывает PostgreSQL MVCC, WAL, autovacuum, TOAST, declarative partitioning и replication views.

Перед активацией наставник и ученик:

1. проверяют доступную версию PostgreSQL командой `SELECT version();`;
2. выбирают отдельную учебную database;
3. подтверждают database и пользователя через `current_database()`/`current_user`;
4. задают `application_name = 'week8_lab'`;
5. ограничивают зависающие команды через `statement_timeout` и `lock_timeout`;
6. загружают fixture только после чтения safety-блока;
7. не меняют server configuration и не перезапускают cluster ради лаборатории.

Fixture создаёт schema `week8_lab` и намеренно останавливается, если она уже существует. В ней нет `DROP DATABASE`, `DROP SCHEMA`, `TRUNCATE`, команд файловой системы, изменения ролей или server configuration.

Некоторые наблюдения зависят от версии, прав и настроек сервера. Если view/column недоступна, это фиксируется как ограничение; результат не выдумывается. Команды `CHECKPOINT`, backup/restore, failover и изменение autovacuum settings в этой неделе изучаются концептуально или через read-only наблюдения, если нет отдельного безопасного стенда.

## Порядок прохождения

1. Получить допуск из недели 7.
2. Прочитать только назначенные разделы теории.
3. До команды записать прогноз и проверяемый invariant.
4. Выполнить практику в назначенном файле.
5. Сохранить фактический вывод или план; не подставлять ожидаемый результат вместо запуска.
6. Заполнить самооценку и `notes.md`.
7. Написать: `Проверь день N недели 8`.
8. Самостоятельно исправить обязательные замечания.
9. Получить явный статус в `ASSESSMENT.md`.

## Границы недели

На этой неделе не требуются:

- чтение исходного кода PostgreSQL;
- ручное редактирование `pg_xact`, `pg_wal` или других файлов data directory;
- production tuning параметров autovacuum, checkpoint, planner или памяти;
- намеренное аварийное завершение рабочей базы;
- самостоятельная настройка physical/logical replication и автоматического failover;
- backup/restore production-данных;
- создание shard coordinator или distributed transaction protocol;
- Citus, Patroni, PgBouncer, Kubernetes operators и cloud-specific managed-service API;
- написание функций на C или unsafe procedural languages;
- сложная PL/pgSQL бизнес-логика;
- event triggers;
- наследование таблиц как замена declarative partitioning;
- глубокая геодезия и все функции PostGIS;
- выбор СУБД только по синтетическому benchmark;
- Django ORM — он начинается на неделе 9/10.

## Оценивание

| Критерий | Баллы |
|---|---:|
| Корректность результата | 0–3 |
| Выполнение условий задания | 0–2 |
| Граничные и ошибочные сценарии | 0–2 |
| Читаемость и имена | 0–1 |
| Понимание и самооценка | 0–1 |
| Самостоятельность исправлений | 0–1 |

Для следующего дня требуется минимум 7/10 без критической ошибки. Для итогового аудита — минимум 8/10.

## Критические ошибки

- `ctid`, `xmin` или `xmax` используются как постоянный business identifier;
- long-running transaction оставлена открытой после опыта;
- `VACUUM FULL` предлагается как обычная ежедневная очистка без учёта lock/rewrite;
- autovacuum отключается целиком ради «ускорения»;
- приблизительное значение statistics view объявляется точным бизнес-счётчиком;
- выполняется ручное удаление файлов из data directory;
- durability связывается только с data pages и игнорирует WAL;
- replica называется backup или считается защитой от ошибочного `DELETE`;
- trigger прячет главный сценарий покупки, выполняет внешний I/O или рекурсивно меняет ту же таблицу без защиты;
- procedure/function получает небезопасный `search_path` при security-sensitive design;
- partitioning вводится без partition key, retention/query pattern и `EXPLAIN`;
- уникальность между partitions предполагается без соответствующего ограничения;
- partitioning, replication и sharding используются как синонимы;
- CAP трактуется как «всегда можно выбрать любые два свойства» без network partition context;
- replication lag игнорируется при чтении после записи;
- sharding предлагается до измерения единственного узла и без routing/rebalancing plan;
- PostgreSQL/MySQL выбирается по одному признаку или рекламному тезису;
- PostGIS добавляется только ради хранения названия страны;
- фактический runtime-результат подменяется ожидаемым.

## Критерий завершения

- все дни имеют минимум 7/10;
- итоговый readiness audit имеет минимум 8/10;
- закрыты критические замечания;
- уверенно отвечено минимум на 18 из 24 контрольных вопросов;
- MVCC lifecycle объяснён на фактическом опыте;
- maintenance report содержит evidence, uncertainty и безопасное действие;
- WAL измерен через LSN, а recovery chain объяснена без опасной симуляции crash;
- function/procedure/trigger decision table согласована с SQL;
- audit-trigger сохраняет минимальный useful context и не хранит секреты;
- partition pruning подтверждён планами минимум для трёх форм запроса;
- scaling decision различает single-node, replica, partition и shard;
- определена read-after-write policy для возможной replica;
- зафиксированы обоснованные решения PostgreSQL vs MySQL и PostGIS yes/no;
- итоговый пакет пригоден как вход в проектирование Django-моделей и миграций.

## Официальные материалы

- [PostgreSQL: MVCC introduction](https://www.postgresql.org/docs/current/mvcc-intro.html);
- [PostgreSQL: system columns](https://www.postgresql.org/docs/current/ddl-system-columns.html);
- [PostgreSQL: routine vacuuming](https://www.postgresql.org/docs/current/routine-vacuuming.html);
- [PostgreSQL: TOAST](https://www.postgresql.org/docs/current/storage-toast.html);
- [PostgreSQL: WAL](https://www.postgresql.org/docs/current/wal-intro.html);
- [PostgreSQL: partitioning](https://www.postgresql.org/docs/current/ddl-partitioning.html);
- [PostgreSQL: functions and procedures](https://www.postgresql.org/docs/current/xfunc.html);
- [PostgreSQL: triggers](https://www.postgresql.org/docs/current/triggers.html);
- [PostgreSQL: warm standby](https://www.postgresql.org/docs/current/warm-standby.html);
- [PostgreSQL: logical replication](https://www.postgresql.org/docs/current/logical-replication.html);
- [MySQL: InnoDB multi-versioning](https://dev.mysql.com/doc/refman/8.4/en/innodb-multi-versioning.html);
- [PostGIS: `ST_DWithin`](https://postgis.net/docs/ST_DWithin.html);
- [Gilbert–Lynch: CAP formulation](https://groups.csail.mit.edu/tds/papers/Gilbert/Brewer2.pdf);
- [Abadi: PACELC](https://www.cs.umd.edu/~abadi/papers/abadi-pacelc.pdf).

## Текущий статус

Неделя 8 только подготовлена. Не выполнять SQL, не заполнять решения и не менять журнал до явного допуска из недели 7.
