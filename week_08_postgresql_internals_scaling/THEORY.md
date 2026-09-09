# Теория недели 8: внутренности PostgreSQL и масштабирование

## Как читать конспект

Неделя объясняет внутреннее поведение базы настолько глубоко, насколько это нужно backend-разработчику. Термин «внутренности» здесь не означает изучение исходного кода PostgreSQL.

Для каждого дня:

1. прочитай назначенный раздел;
2. до запуска SQL письменно предскажи результат;
3. выполни опыт только в `week8_lab`;
4. сравни прогноз с фактом;
5. объясни наблюдение своими словами.

`current` в официальных ссылках означает актуальную поддерживаемую документацию. Перед лабораторией всегда сохраняй `SELECT version();`: названия отдельных statistics columns могут отличаться между версиями.

---

# День 1. MVCC, snapshot и версии строк

## 1. Logical row и tuple version

Приложение думает о записи автомобиля как об одной строке:

```text
inventory id=42, quantity=3
```

PostgreSQL при `UPDATE` обычно создаёт новую физическую версию строки — tuple version. Старая версия не может исчезнуть сразу: её ещё может видеть transaction со старым snapshot.

```sql
UPDATE week8_lab.inventory
SET quantity = quantity - 1
WHERE id = 42;
```

Логически `id = 42` остался тем же объектом. Физически могла появиться новая tuple version.

## 2. Что такое MVCC

MVCC — Multi-Version Concurrency Control, управление конкурентностью через несколько версий данных. SQL statement или transaction видит согласованный snapshot, а не произвольную смесь параллельных изменений.

Главные следствия:

- обычное чтение не обязано блокировать обычную запись;
- обычная запись не обязана блокировать обычное чтение;
- это не означает отсутствия locks;
- конфликтующие writers по-прежнему могут ждать друг друга;
- видимая версия зависит от isolation level и snapshot.

## 3. Snapshot

Snapshot — правило видимости версий на конкретный момент. Упрощённо PostgreSQL учитывает, какие transactions завершились, какие ещё работают, кто создал и кто удалил версию, а также isolation level.

В `READ COMMITTED` каждый statement получает новый snapshot. В `REPEATABLE READ` transaction обычно продолжает читать snapshot, сформированный при первом релевантном statement. Эти различия уже наблюдались на неделе 7; теперь мы связываем их с версиями строк.

## 4. Системные столбцы

| Column | Упрощённый смысл |
|---|---|
| `xmin` | transaction ID, создавший tuple version |
| `xmax` | transaction ID, удаливший/заменивший версию, либо специальное значение |
| `ctid` | физическое положение текущей версии внутри table |
| `tableoid` | OID физической table, полезен для partitions |

```sql
SELECT id, quantity, xmin, xmax, ctid
FROM week8_lab.inventory
WHERE id = 1;
```

После `UPDATE` видимый `ctid` часто изменится. Однако:

- `ctid` не является business ID;
- `ctid` меняется при update и table rewrite;
- `xmin`/`xmax` имеют внутреннюю семантику и не являются вечными уникальными IDs;
- nonzero `xmax` не всегда означает, что видимая версия уже удалена: значение может быть связано с незавершённой или отменённой через rollback transaction либо с row-locking internals.

Для приложения используется primary key, например `id`.

## 5. Visibility и isolation

Две sessions могут одновременно получить разные корректные ответы:

1. Session A начала `REPEATABLE READ` и увидела `quantity = 3`.
2. Session B изменила значение на `2` и сделала `COMMIT`.
3. Session A всё ещё видит `3` в своём старом snapshot.
4. Новая transaction видит `2`.

Это не «кэширование строки» и не потеря commit. Это обещание isolation level.

## 6. Почему долгие transactions опасны

Пока старый snapshot потенциально видит старую tuple version, PostgreSQL не может считать её полностью ненужной. Долгая transaction может задерживать очистку dead tuples, увеличивать bloat, удерживать locks, мешать DDL и ухудшать latency.

Web request не должен открыть transaction, ждать ввода пользователя или внешнего API и лишь потом делать `COMMIT`.

## 7. HOT update — обзорно

Если update не меняет indexed columns и на heap page есть место, PostgreSQL иногда выполняет Heap-Only Tuple update. Новая версия связывается с предыдущей без добавления новой записи во все indexes. Это оптимизация, а не контракт приложения.

Нельзя предполагать, что конкретный update обязательно будет HOT. Наблюдать можно по `n_tup_hot_upd`, помня, что statistics приблизительны и накопительны.

## 8. Прогноз

1. Останется ли `ctid` постоянным после `UPDATE`?
2. Увидит ли старая `REPEATABLE READ` transaction commit другой session?
3. Может ли обычный `SELECT` читать старую версию, пока writer уже committed новую?
4. Можно ли выдавать `xmin` клиенту как вечный version ID?

## 9. Самопроверка

1. Чем logical row отличается от tuple version?
2. Почему MVCC не означает «locks не нужны»?
3. Чем snapshot в `READ COMMITTED` отличается от `REPEATABLE READ`?
4. Почему transaction нельзя держать открытой во время сетевого ожидания?

---

# День 2. `VACUUM`, autovacuum, freeze и bloat

## 10. Dead tuple

Старая tuple version становится dead для всех relevant transactions, когда её больше никто не может увидеть. До этого она нужна MVCC. После этого занятое место можно подготовить к повторному использованию.

`DELETE` тоже обычно не вырезает bytes немедленно. Он помечает версию как удалённую для последующих snapshots.

## 11. Четыре разные задачи обслуживания

| Механизм | Основная задача |
|---|---|
| `VACUUM` | сделать место dead tuples пригодным для повторного использования, обновить visibility map, участвовать в freeze |
| `ANALYZE` | собрать planner statistics |
| autovacuum | автоматически запускать vacuum/analyze по необходимости |
| `VACUUM FULL` | переписать table и вернуть больше места ОС ценой тяжёлого lock/rewrite |

Обычный `VACUUM` обычно не уменьшает файл до минимального размера. Он делает пространство доступным для будущих versions внутри relation.

## 12. Почему `VACUUM FULL` не routine-команда

`VACUUM FULL` переписывает table, требует дополнительное место, берёт `ACCESS EXCLUSIVE` lock, блокирует обычную работу и не лечит причину постоянного bloat.

Правильный первый вопрос — почему routine autovacuum не успевает или почему workload создаёт столько churn.

## 13. Autovacuum

Backend-разработчику важно:

- не отключать autovacuum глобально;
- следить за часто обновляемыми tables отдельно;
- понимать, что одна настройка не идеальна для всех tables;
- не копировать production-параметры без workload;
- различать vacuum и analyze triggers.

В этой неделе параметры только читаются:

```sql
SELECT name, setting, unit, source
FROM pg_settings
WHERE name IN (
    'autovacuum',
    'autovacuum_vacuum_threshold',
    'autovacuum_vacuum_scale_factor',
    'autovacuum_analyze_threshold',
    'autovacuum_analyze_scale_factor'
);
```

## 14. Statistics views

```sql
SELECT
    relname, n_live_tup, n_dead_tup,
    n_tup_ins, n_tup_upd, n_tup_del, n_tup_hot_upd,
    last_vacuum, last_autovacuum, last_analyze, last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'week8_lab';
```

Нюансы:

- counters накопительны;
- `n_live_tup` и `n_dead_tup` — estimates;
- statistics могут обновляться не мгновенно;
- `ANALYZE` собирает planner statistics, а не точный business count;
- точное количество business rows требует `COUNT(*)` с понятным snapshot.

## 15. Bloat

Bloat — избыточно занятое пространство относительно полезных данных. Возможные причины: частые update/delete, отстающий autovacuum, долгие transactions, replication slots, массовые изменения и index churn.

Размер relation сам по себе не доказывает bloat. Нужны baseline, workload, statistics и подходящий метод измерения.

## 16. Visibility map

Visibility map отмечает heap pages с all-visible/all-frozen information. Она помогает vacuum пропускать часть pages и позволяет index-only scan не обращаться к heap для каждой entry.

Поэтому covering index ещё не гарантирует нулевые heap fetches: видимость должна быть подтверждена.

## 17. XID wraparound и freeze

Обычные transaction IDs имеют ограниченное пространство и циклическую семантику. PostgreSQL замораживает достаточно старые versions, чтобы они продолжали считаться старыми после wraparound.

Практический вывод:

- autovacuum нужен не только для скорости;
- anti-wraparound vacuum связан с доступностью и корректностью;
- `age(datfrozenxid)` и `age(relfrozenxid)` — диагностические сигналы, а не повод менять settings наугад.

## 18. Безопасная лаборатория

Разрешены update/delete/rollback в fixture, `VACUUM (ANALYZE)` своей table вне transaction block и read-only statistics. Не разрешены глобальное отключение autovacuum, `VACUUM FULL` на общей table, изменение freeze settings и искусственное приближение cluster к wraparound.

## 19. Прогноз и самопроверка

1. Вернёт ли обычный `VACUUM` всё свободное место ОС?
2. Почему `VACUUM` нельзя заменить одним `ANALYZE`?
3. Почему `n_dead_tup` не является точным `COUNT(*)`?
4. Как long transaction связана с bloat?

---

# День 3. WAL, checkpoint, recovery и TOAST

## 20. Правило WAL

Write-Ahead Logging означает: описание изменения должно быть надёжно записано в WAL прежде, чем соответствующая изменённая data page обязана попасть на постоянное хранение.

После commit PostgreSQL не обязан немедленно записать каждую data page. При crash он может повторить необходимые изменения из WAL — REDO.

WAL нужен для crash recovery, physical replication, continuous archiving, PITR и logical decoding при подходящей конфигурации.

WAL не заменяет backup: ошибочный committed `DELETE` тоже попадёт в WAL и может воспроизвестись на replicas.

## 21. LSN

LSN — Log Sequence Number, позиция в WAL stream типа `pg_lsn`.

```sql
SELECT pg_current_wal_lsn();
SELECT pg_wal_lsn_diff(:after_lsn, :before_lsn);
```

Concurrent/background activity тоже генерирует WAL. Один запуск не является benchmark, а LSN distance не равен размеру logical row.

## 22. Commit и durability

По умолчанию успешный commit означает, что необходимый WAL flushed согласно durability settings. Настройки asynchronous commit меняют trade-off latency/durability; в учебной неделе мы их не меняем.

Нельзя обещать durability без учёта server settings, storage flush guarantees, backup/restore testing и failure domain.

## 23. Checkpoint

Checkpoint создаёт известную recovery point и продвигает dirty buffers к storage по правилам сервера. Слишком частые checkpoints могут создавать I/O pressure; слишком редкие увеличивают recovery work и WAL/storage requirements.

Безопасно читать:

```sql
SELECT * FROM pg_stat_checkpointer;
SELECT * FROM pg_stat_wal;
```

Доступность columns зависит от версии и permissions. `CHECKPOINT` вручную в общей базе не выполняется.

## 24. Crash recovery, backup и PITR

- crash recovery восстанавливает consistency после незапланированного завершения;
- base backup — физическая исходная копия cluster;
- WAL archive — сохранённая последовательность WAL segments;
- PITR — base backup плюс replay WAL до выбранной точки;
- replica — обслуживаемая copy, но не автоматически независимый backup;
- restore test — доказательство восстанавливаемости.

RPO — сколько данных допустимо потерять по времени. RTO — сколько времени допустимо восстанавливать сервис.

## 25. TOAST

PostgreSQL pages имеют фиксированный размер, обычно 8 KiB. Большие variable-length values могут сжиматься и/или храниться вне основной heap tuple в связанной TOAST table.

| Strategy | Идея |
|---|---|
| `PLAIN` | без out-of-line хранения |
| `EXTENDED` | compression и out-of-line обычно разрешены |
| `EXTERNAL` | out-of-line без compression |
| `MAIN` | предпочитать inline, out-of-line как крайняя мера |

```sql
SELECT
    id,
    length(description) AS characters,
    octet_length(description) AS bytes,
    pg_column_size(description) AS stored_datum_bytes
FROM week8_lab.large_notes;
```

Эти функции отвечают на разные вопросы. Unicode text может иметь разное число characters и bytes; compression меняет stored size. TOAST прозрачен, но detoasting имеет цену, поэтому `SELECT *` для больших documents нежелателен без причины.

## 26. Прогноз и самопроверка

1. Почему commit не ждёт записи каждой data page?
2. Чем LSN отличается от transaction ID?
3. Почему replica не является backup?
4. Почему `length(text)` и `pg_column_size(text)` могут отличаться?

---

# День 4. Functions, procedures и triggers

## 27. Где должна жить логика

Возможные места: constraint, view, database function, procedure, trigger, application service или worker.

Правило курса:

- простое всегда истинное правило данных — constraint;
- переиспользуемое вычисление рядом с данными — function-кандидат;
- явно вызываемая database operation — procedure-кандидат;
- неизбежная реакция независимо от caller — trigger-кандидат;
- основной use case покупки/закупки остаётся явным application service.

## 28. Function

Function возвращает value/set и может использоваться в expression.

```sql
CREATE FUNCTION week8_lab.inventory_value(
    quantity integer,
    unit_price numeric
)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
STRICT
RETURN quantity * unit_price;
```

Volatility categories:

- `VOLATILE` — result может меняться даже внутри statement; default;
- `STABLE` — не меняет database и стабилен в рамках statement;
- `IMMUTABLE` — одинаковые arguments всегда дают одинаковый result.

Function, зависящая от table, current time или settings, обычно не immutable.

## 29. Procedure

Procedure вызывается через `CALL` и не используется как обычное expression. Возможность transaction control внутри procedure зависит от контекста вызова; нельзя обещать, что любой `CALL` может делать `COMMIT`.

На этой неделе procedure остаётся небольшой и не заменяет Django service layer.

## 30. Trigger

Trigger вызывает function при событии `INSERT`, `UPDATE`, `DELETE` или иногда `TRUNCATE`. Он бывает `BEFORE`/`AFTER`, row-level/statement-level и может иметь `WHEN`.

Для audit trail часто подходит `AFTER ... FOR EACH ROW`: записывается уже принятое изменение. В trigger function доступны `OLD`, `NEW`, `TG_OP`, `TG_TABLE_NAME`.

## 31. Риски triggers

- скрытый control flow и неожиданные writes;
- recursion и порядок нескольких triggers;
- сложные migrations и диагностика;
- row trigger вызывается для каждой row bulk operation;
- side effects откатываются вместе с transaction;
- внешний I/O становится несогласованным;
- privilege и `search_path` risks у `SECURITY DEFINER`.

Trigger не должен отправлять email, HTTP request или message. Для интеграции позже применяется outbox/Celery.

## 32. Security

По умолчанию предпочитай `SECURITY INVOKER`. `SECURITY DEFINER` выполняет function с правами owner и требует строгих permissions и безопасного `search_path`.

Нельзя конкатенировать непроверенный identifier в dynamic SQL. Values передаются parameters/`USING`; identifiers требуют allowlist и безопасного quoting.

## 33. Decision record

Для routine ответь:

1. Какой invariant/расчёт она обслуживает?
2. Почему constraint/view/service недостаточны?
3. Когда она выполняется?
4. С какими правами?
5. Как тестируется rollback?
6. Где наблюдается failure?
7. Как меняется migration?

## 34. Самопроверка

1. Чем function отличается от procedure?
2. Почему constraint лучше trigger для `quantity >= 0`?
3. Почему HTTP request из trigger опасен?
4. Когда `SECURITY DEFINER` требует security review?

---

# День 5. Declarative partitioning

## 35. Что решает partitioning

Partitioning делит одну logical table на physical partitions по ключу:

- `RANGE` — интервалы, например месяц продажи;
- `LIST` — дискретные группы, например регион;
- `HASH` — распределение по remainder.

Польза возможна для большой table, запросов по partition key, lifecycle целых диапазонов и maintenance по partitions. Partitioning не заменяет indexes и часто вредит маленькой table.

## 36. Range example

```sql
CREATE TABLE week8_lab.sales_partitioned (
    sale_id bigint GENERATED ALWAYS AS IDENTITY,
    sold_at timestamptz NOT NULL,
    dealership_id bigint NOT NULL,
    amount numeric(12, 2) NOT NULL,
    PRIMARY KEY (sale_id, sold_at)
) PARTITION BY RANGE (sold_at);
```

Bounds не пересекаются: `FROM` включается, `TO` исключается.

## 37. Default partition и gaps

Если row не подходит ни в одну partition, insert завершается ошибкой. Default partition может принять unmatched rows, но требует monitoring; иначе она становится свалкой.

## 38. Partition pruning

Planner/executor может исключить partitions, которые не удовлетворяют predicate.

```sql
EXPLAIN (COSTS OFF)
SELECT *
FROM week8_lab.sales_partitioned
WHERE sold_at >= TIMESTAMPTZ '2026-02-01 00:00:00+00'
  AND sold_at <  TIMESTAMPTZ '2026-03-01 00:00:00+00';
```

Нужно доказать по plan, какие partitions читаются.

## 39. Constraints и indexes

- data лежат в leaf partitions;
- parent index создаёт соответствующие child indexes;
- global index в обычном смысле отсутствует;
- `PRIMARY KEY`/`UNIQUE` должен включать все columns partition key, а сам key такого ограничения не должен содержать expressions/functions;
- ограничения и foreign keys нужно сверять для используемой версии.

## 40. Lifecycle operations

Detach/drop старой partition может быть дешевле огромного `DELETE`, но требует retention policy, backup/archive decision, dependency/lock check и recovery plan. В fixture destructive lifecycle command остаётся закомментированным.

## 41. Типичные ошибки

- partition key отсутствует в queries;
- слишком много мелких partitions;
- key часто обновляется;
- нет future partitions или timezone boundary;
- default partition не мониторится;
- uniqueness предполагается глобальной без доказательства;
- pruning не проверен;
- partitioning заменяет retention design.

## 42. Самопроверка

1. Чем partition отличается от shard?
2. Почему bounds удобны как `[from, to)`?
3. Почему PK часто включает partition key?
4. Как доказать pruning?

---

# День 6. Replication, sharding, CAP/PACELC и выбор технологии

## 43. Три разных инструмента

| Механизм | Где лежат данные | Основная цель |
|---|---|---|
| Partitioning | части table внутри deployment | lifecycle, pruning, maintenance |
| Replication | copies на нескольких nodes | availability, failover, read scaling |
| Sharding | разные subsets на разных nodes | распределение storage/write load |

## 44. Physical replication

Physical streaming replication передаёт WAL changes совместимому standby. Primary принимает writes; standby replay может отставать. Asynchronous mode допускает committed data, ещё не replayed на standby. Synchronous mode меняет latency/availability trade-off.

Failover требует orchestration и защиты от split brain. Read-after-write может не сработать на lagging replica: критичное чтение направляют на primary, ждут нужный LSN или явно принимают eventual visibility.

## 45. Logical replication

Logical replication публикует logical row changes выбранных tables. Она полезна для выборочной передачи, некоторых migrations и read models.

Она не копирует всё cluster state автоматически. DDL, sequences, conflicts и replica identity требуют отдельного плана. Отстающий replication slot может удерживать WAL и заполнить disk.

## 46. Backup не равен replica

Ошибка приложения может быстро реплицироваться. Backup требует независимого хранения, retention, контроля доступа, проверки целостности, restore test и согласованных RPO/RTO.

## 47. Sharding

Возможные shard keys: `dealership_id`, region/country, customer hash или time range. Каждый создаёт routing, cross-shard join/transaction, distributed uniqueness, rebalancing, hot-shard и migration trade-offs.

До sharding проверяют schema, indexes, caching, connection management, vertical scaling, replicas, archival и partitioning.

## 48. CAP без лозунга «выбери два»

CAP относится к distributed system во время network partition:

- Consistency — в формальной модели близка к linearizability, не буква C из ACID;
- Availability — каждый request к неупавшему node получает response;
- Partition tolerance — система работает при потере/задержке сообщений между groups nodes.

Во время реального partition нельзя одновременно гарантировать строгую consistency и availability для всех сторон. В нормальном режиме лозунг «выбери два» вводит в заблуждение.

## 49. PACELC

PACELC спрашивает: при Partition — Availability или Consistency; Else — Latency или Consistency. Это модель мышления, не вечный ярлык продукта. Guarantees могут различаться по operations и configuration.

## 50. PostgreSQL и MySQL

Сравнивать нужно конкретные версии и storage engine; для MySQL обычно InnoDB.

| Вопрос | PostgreSQL | MySQL/InnoDB |
|---|---|---|
| MVCC old versions | heap versions и vacuum | undo records и purge |
| Primary storage | heap плюс отдельный PK index | clustered primary index |
| FK child index | не создаётся автоматически | supporting index обычно создаётся автоматически |
| JSON indexing | `jsonb`, GIN/expression indexes | binary JSON, generated/functional/multi-valued approaches |
| Extensibility | rich extension/type/operator model | другой extension/plugin model |
| Partition/FK details | PostgreSQL-specific | InnoDB-specific; сверять версию |

Для проекта PostgreSQL уже выбран из-за учебной цели и требований roadmap. Это не утверждение, что он всегда лучше MySQL.

## 51. PostGIS или страна

Для страны достаточно нормализованного country code; позже можно рассмотреть `django-countries`. PostGIS оправдан для coordinates, radius search, nearest dealership, polygons, spatial index и coordinate systems.

Для radius query применяется `ST_DWithin`, способный использовать spatial index. Нужны осознанные `geometry`/`geography`, SRID и units.

Текущее решение проекта: **PostGIS не нужен**, пока требования ограничены страной/городом и нет radius/polygon queries. Нужно записать условие пересмотра.

## 52. Самопроверка

1. Почему replica может нарушить read-after-write?
2. Чем physical replication отличается от logical?
3. Как slot может заполнить disk?
4. Когда применяется CAP?
5. Что добавляет PACELC?
6. Какой requirement оправдает PostGIS?

---

# День 7. PostgreSQL readiness audit

## 53. Цель аудита

Итог недели — принять минимальные доказанные решения перед Django, связав workload и transaction map недели 7 с MVCC risks, maintenance, WAL/recovery, TOAST, routines, partitions и scaling choices.

## 54. Формат решения

Каждая рекомендация содержит:

```text
Observation → Risk → Options → Decision → Evidence → Revisit trigger
```

Если проблема ещё не измерена, допустимое решение — ничего не усложнять и записать условие пересмотра.

## 55. Production-thinking checklist

- Кто владеет migrations?
- Как обнаружить long/idle transactions?
- Какие tables имеют высокий churn?
- Как наблюдать vacuum/analyze freshness?
- Каковы RPO/RTO и где restore proof?
- Какие writes создают WAL?
- Какие большие values читаются выборочно?
- Где живут invariants и side effects?
- Есть ли доказанный partition candidate?
- Какой consistency contract у replica reads?
- Что станет сигналом для sharding?
- Почему PostGIS нужен или не нужен?

## 56. Что переносится в Django

Решения переводятся в Django models/migrations, `Meta.constraints`, `Meta.indexes`, `transaction.atomic`, `select_for_update`, QuerySet loading strategy, service layer и runbooks.

Системные columns и maintenance commands не становятся полями Django models.

## 57. Финальные вопросы без конспекта

Ученик объясняет lifecycle tuple version; snapshots и long transactions; vacuum/freeze; WAL/checkpoint/recovery; backup/replica/PITR; TOAST; routine/trigger choices; partition key/pruning; replication/sharding; CAP/PACELC; PostgreSQL/MySQL; PostGIS decision.

---

# Словарь недели

| Термин | Короткое определение |
|---|---|
| MVCC | управление конкурентностью через versions и snapshots |
| Tuple version | физическая версия logical row |
| Snapshot | правило видимости versions |
| Dead tuple | версия, больше не видимая relevant transactions |
| Bloat | избыточное пространство относительно полезных данных |
| Freeze | защита старых versions от XID wraparound |
| Visibility map | карта heap pages с visibility/freeze information |
| WAL | журнал, записываемый до обязательной записи data page |
| LSN | позиция в WAL stream |
| PITR | base backup плюс WAL replay до точки времени |
| TOAST | хранение/сжатие больших variable-length values |
| Partition pruning | исключение ненужных partitions |
| Replication lag | отставание receive/flush/replay |
| Sharding | распределение subsets по разным nodes |
| CAP | trade-off C/A во время network partition |
| PACELC | CAP плюс latency/consistency в normal mode |

# Официальные материалы

- [MVCC introduction](https://www.postgresql.org/docs/current/mvcc-intro.html)
- [System columns](https://www.postgresql.org/docs/current/ddl-system-columns.html)
- [Routine vacuuming](https://www.postgresql.org/docs/current/routine-vacuuming.html)
- [Monitoring activity](https://www.postgresql.org/docs/current/monitoring.html)
- [Write-Ahead Logging](https://www.postgresql.org/docs/current/wal-intro.html)
- [WAL internals](https://www.postgresql.org/docs/current/wal-internals.html)
- [TOAST](https://www.postgresql.org/docs/current/storage-toast.html)
- [`CREATE FUNCTION`](https://www.postgresql.org/docs/current/sql-createfunction.html)
- [`CREATE PROCEDURE`](https://www.postgresql.org/docs/current/sql-createprocedure.html)
- [`CREATE TRIGGER`](https://www.postgresql.org/docs/current/sql-createtrigger.html)
- [Declarative partitioning](https://www.postgresql.org/docs/current/ddl-partitioning.html)
- [Streaming replication](https://www.postgresql.org/docs/current/warm-standby.html)
- [Logical replication](https://www.postgresql.org/docs/current/logical-replication.html)
- [MySQL/InnoDB multi-versioning](https://dev.mysql.com/doc/refman/8.4/en/innodb-multi-versioning.html)
- [PostGIS `ST_DWithin`](https://postgis.net/docs/ST_DWithin.html)
- [Gilbert–Lynch CAP paper](https://groups.csail.mit.edu/tds/papers/Gilbert/Brewer2.pdf)
- [Abadi PACELC paper](https://www.cs.umd.edu/~abadi/papers/abadi-pacelc.pdf)

# Что обязательно, а что обзорно

Обязательно: MVCC mental model, long transactions, vacuum/analyze distinctions, WAL rule, backup/replica distinction, TOAST awareness, safe routine/trigger choice, partition decision/pruning proof, separation of partitioning/replication/sharding и replica consistency contract.

Обзорно: tuple header bits, WAL record formats, checkpoint algorithms, production tuning, replication setup/failover, shard implementation, полная MySQL feature matrix и advanced PostGIS.
