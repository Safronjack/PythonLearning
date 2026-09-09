# Неделя 7: транзакции, конкурентный доступ и производительность PostgreSQL

Статус: **подготовлена заранее и заблокирована**.

Начало разрешается только после полного зачёта недель 0–6 и явного допуска в `week_06_sql_design/ASSESSMENT.md`. Текущей активной работой остаётся неделя 0.

## Цель недели

Научиться сохранять бизнес-инварианты при одновременной работе нескольких запросов и принимать решения об индексах по измеримому workload, а не по догадкам. К концу модуля ученик должен уметь:

- объяснить назначение транзакции и свойства ACID;
- осознанно использовать `BEGIN`, `COMMIT`, `ROLLBACK` и `SAVEPOINT`;
- выбирать границу транзакции для покупки и закупки автомобиля;
- различать dirty read, non-repeatable read, phantom read, lost update и serialization anomaly;
- объяснить фактическое поведение уровней изоляции PostgreSQL;
- воспроизвести конкурентную ошибку в двух sessions;
- исправить lost update атомарным `UPDATE`, условным изменением или row lock;
- применять `SELECT ... FOR UPDATE` и понимать более слабые row-lock modes;
- знать границы `NOWAIT` и `SKIP LOCKED`;
- воспроизвести deadlock и предотвратить его единым порядком блокировок;
- проектировать bounded retry для `40001` и `40P01`;
- выбирать B-tree, Hash, GIN, GiST, SP-GiST или BRIN под конкретные operators и данные;
- проектировать multicolumn, expression, partial и covering indexes;
- объяснить цену индекса для записей, storage и обслуживания;
- читать `EXPLAIN` и безопасно запускать `EXPLAIN ANALYZE`;
- сравнивать estimates и actual rows, замечать плохую cardinality estimate;
- распознавать Seq/Index/Bitmap/Index Only Scan и основные join nodes;
- выявлять N+1 и заменять повторные запросы set-based выборкой;
- составить transaction map и index audit итогового проекта.

## Предварительные требования

- Недели 0–6 полностью завершены.
- Итоговый PostgreSQL-прототип недели 6 реально запущен и принят минимум на 8/10.
- ERD, DDL, seed data и business queries недели 6 согласованы.
- Ученик уверенно понимает PK, FK, constraints, joins, CTE и aggregates.
- В `week_06_sql_design/ASSESSMENT.md` указано: «Допуск к неделе 7: да».

## Связь с итоговым проектом

Предметная область остаётся той же:

- покупатель не должен дважды купить последнюю машину;
- баланс и остаток не могут измениться только наполовину;
- два автосалона не должны одновременно закупить одну последнюю единицу у поставщика;
- Offer должен обрабатываться один раз;
- блокировки balances, inventory и transaction rows должны браться в предсказуемом порядке;
- каталог, поиск предложения, статистика продаж и выбор поставщика требуют разных индексов;
- ускорение одного чтения не должно без причины ухудшать все записи.

Неделя не реализует Django/Celery. Она создаёт SQL-модель поведения, к которой мы вернёмся в ORM и фоновых задачах.

## Структура

- [THEORY.md](THEORY.md) — теория, небольшие примеры, прогнозы и контрольные вопросы;
- [PRACTICE.md](PRACTICE.md) — семь последовательных практических дней;
- [ASSESSMENT.md](ASSESSMENT.md) — будущие оценки, ошибки и пересдачи;
- [notes.md](notes.md) — личный словарь, transaction map и index journal;
- [fixtures/postgresql_lab.sql](fixtures/postgresql_lab.sql) — teacher-owned PostgreSQL schema и deterministic data;
- `day_01_transactions.sql` — транзакции, rollback и savepoints;
- `day_02_isolation_session_a.sql`, `day_02_isolation_session_b.sql` — isolation anomalies в двух sessions;
- `day_03_locking_session_a.sql`, `day_03_locking_session_b.sql` — lost update, row locks и deadlock;
- `day_04_index_types.sql` — выбор и проверка index access methods;
- `day_05_advanced_indexes.sql` — multicolumn, expression, partial и covering indexes;
- `day_06_explain.sql` — чтение планов и оптимизация запросов;
- `day_06_n_plus_one.py` — локальное измерение N+1 без ORM;
- `day_06_explain_report.md` — объяснение планов своими словами;
- `day_07_transaction_performance_audit/` — итоговый аудит схемы недели 6.

## Учебная среда

Транзакции, isolation levels, row locks и PostgreSQL indexes нельзя честно изучить через SQLite. Основная практика недели требует локальный PostgreSQL и две независимые client sessions.

Перед активацией недели наставник и ученик отдельно:

1. проверяют, какой PostgreSQL уже доступен;
2. выбирают отдельную учебную database;
3. подтверждают её точное имя через current connection;
4. запускают fixture только в этой database;
5. открывают две sessions к одной и той же учебной database;
6. задают короткие `lock_timeout`/`statement_timeout` для блокирующих лабораторий.

Сейчас PostgreSQL, Docker или Python-driver не устанавливаются. Runtime-проверка останется ожидающей до фактической активации модуля.

`day_06_n_plus_one.py` использует только стандартный Python `sqlite3` и безопасную fixture недели 6: для самого паттерна N+1 конкретная СУБД несущественна.

Ожидаемые размеры после успешной загрузки `postgresql_lab.sql`:

| Table | Rows |
|---|---:|
| `dealership` | 20 |
| `supplier` | 50 |
| `customer` | 10 000 |
| `car_model` | 200 |
| `dealership_inventory` | 2 000 |
| `supplier_catalog_item` | 2 500 |
| `customer_offer` | 30 000 |
| `retail_sale` | 100 000 |
| `promotion` | 500 |
| `work_item` | 1 000 |
| `approval_officer` | 2 |

Fixture создаёт отдельную schema `week7_lab`, не содержит `DROP`, `TRUNCATE`, `DELETE` или `UPDATE` и намеренно останавливается, если такая schema уже существует.

## Правила двух sessions

- Session A и Session B должны быть явно подписаны.
- Перед каждой лабораторией записывается исходное состояние.
- До команды ученик прогнозирует: выполнится, будет ждать или завершится ошибкой.
- Блокирующая команда всегда имеет ограничение времени.
- После опыта обе sessions завершаются `COMMIT` или `ROLLBACK`.
- После опыта выполняется reconciliation query.
- Не оставлять transaction со статусом `idle in transaction`.
- Не выполнять лаборатории в общей, рабочей или неизвестной database.

## Порядок прохождения

1. Прочитать только назначенные разделы `THEORY.md`.
2. Записать прогноз поведения и ожидаемые invariants.
3. Выполнить практику дня в назначенном файле.
4. Приложить фактический результат или план без выдуманных цифр.
5. Для plan comparison сохранить состояние before/after и причину изменения.
6. Заполнить самооценку и `notes.md`.
7. Написать: `Проверь день N недели 7`.
8. Самостоятельно исправить обязательные замечания.
9. Получить явный статус в `ASSESSMENT.md`.

## Границы недели

На этой неделе не требуются:

- подробное устройство MVCC snapshots и tuple visibility — неделя 8;
- WAL records, checkpoints и crash recovery — неделя 8;
- `VACUUM`, autovacuum tuning, table/index bloat и freeze — неделя 8;
- TOAST — неделя 8;
- partitioning, sharding, replication, CAP и PACELC — неделя 8;
- stored functions, procedures и triggers — неделя 8;
- production tuning параметров памяти и planner cost constants;
- принудительное отключение planner nodes как способ «оптимизации»;
- production `CREATE INDEX CONCURRENTLY` на реальном сервисе;
- Django ORM, `transaction.atomic` и `select_for_update` — неделя 10;
- connection pooling;
- distributed transactions и two-phase commit;
- advisory locks глубже одного обзорного примера;
- доказательство внутреннего алгоритма каждого access method.

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

- business operation разбита на несколько autocommit statements и допускает частичное изменение;
- `COMMIT` выполняется после нарушенного invariant;
- transaction остаётся открытой во время пользовательского ввода или внешнего ожидания;
- блокирующий опыт запускается без timeout или плана освобождения lock;
- lost update не воспроизведён, но объявлен исправленным;
- row lock берётся после изменения зависимых данных, когда защита уже запоздала;
- разные code paths блокируют одинаковые ресурсы в разном порядке;
- serialization/deadlock retry повторяет не всю transaction;
- retry бесконечен либо повторяет permanent/business error;
- `SKIP LOCKED` используется для обычного согласованного отчёта;
- index добавлен без workload/query и проверки плана;
- выбран access method, не поддерживающий нужный operator;
- предполагается, что foreign key автоматически индексирует referencing columns;
- индекс дублирует PK/unique index без обоснования;
- порядок multicolumn index выбран без учёта predicates/order;
- performance сравнивается на разных данных или до/после с разными условиями;
- время одного случайного запуска объявляется доказательством оптимизации;
- `EXPLAIN ANALYZE` для modifying statement выполнен без rollback в одноразовой среде;
- план оценивается только по наличию `Index Scan`;
- N+1 «исправлен» переносом цикла, но число запросов не уменьшилось;
- ученик не может назвать invariant и transaction boundary итогового сценария.

## Критерий завершения

- все дни имеют минимум 7/10;
- итоговый аудит имеет минимум 8/10;
- закрыты критические замечания;
- уверенно отвечено минимум на 18 из 24 контрольных вопросов;
- транзакция покупки либо полностью фиксируется, либо полностью откатывается;
- isolation matrix PostgreSQL объясняется без подмены стандартной таблицей;
- lost update, blocking и deadlock реально наблюдались в двух sessions;
- для serialization/deadlock documented bounded whole-transaction retry;
- минимум шесть index decisions связаны с конкретным workload;
- показана цена лишнего индекса;
- минимум шесть планов прочитаны по nodes, rows, loops, estimates и buffers;
- `EXPLAIN ANALYZE` использован безопасно;
- N+1 измерен и устранён set-based запросом;
- transaction map и index audit согласованы со схемой недели 6;
- ученик объясняет, что измерено, что только предположено и что отложено.

## Официальные материалы

- [Transactions](https://www.postgresql.org/docs/current/tutorial-transactions.html);
- [Transaction isolation](https://www.postgresql.org/docs/current/transaction-iso.html);
- [Explicit locking](https://www.postgresql.org/docs/current/explicit-locking.html);
- [`SELECT` locking clause](https://www.postgresql.org/docs/current/sql-select.html);
- [Indexes](https://www.postgresql.org/docs/current/indexes.html);
- [Index types](https://www.postgresql.org/docs/current/indexes-types.html);
- [Multicolumn indexes](https://www.postgresql.org/docs/current/indexes-multicolumn.html);
- [Partial indexes](https://www.postgresql.org/docs/current/indexes-partial.html);
- [Index-only scans](https://www.postgresql.org/docs/current/indexes-index-only-scans.html);
- [Using `EXPLAIN`](https://www.postgresql.org/docs/current/using-explain.html);
- [Planner statistics](https://www.postgresql.org/docs/current/planner-stats.html).

## Текущий статус

Неделя 7 только подготовлена. Не заполнять решения, отчёты и журнал до допуска из недели 6.
