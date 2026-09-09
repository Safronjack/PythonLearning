# Практика недели 8: внутренности PostgreSQL и масштабирование

Статус: **заблокирована до полного зачёта недели 7**.

## Общие правила

- Работай только в отдельной учебной database и schema `week8_lab`.
- В начале каждого файла сохрани `version()`, `current_database()`, `current_user` и `current_setting('application_name')`.
- До каждого опыта запиши прогноз: что увидишь и почему.
- После опыта сохрани фактический вывод либо `EXPLAIN` plan.
- Не выдумывай runtime results, если PostgreSQL недоступен.
- Не меняй server configuration и роли.
- Не отключай autovacuum.
- Не выполняй `VACUUM FULL`, `CHECKPOINT`, failover, restore или destructive partition lifecycle на общей базе.
- После transaction experiments выполни `COMMIT`/`ROLLBACK` и reconciliation query.
- Сведения из statistics views помечай как counters/estimates.
- Решения пишутся учеником. Заготовки содержат только структуру.

## Подготовка при активации

Наставник сначала проверяет доступную среду PostgreSQL. Только после допуска:

1. создать или выбрать отдельную database;
2. выполнить connection proof;
3. прочитать safety header fixture;
4. запустить `fixtures/postgresql_lab.sql` ровно один раз;
5. проверить expected row counts;
6. не повторять fixture поверх существующей schema;
7. для нового прогона использовать новую database или согласованное имя schema.

Ожидаемое состояние fixture:

| Relation | Rows |
|---|---:|
| `inventory` | 200 |
| `sales_log` | 12 000 |
| `churn_probe` | 5 000 |
| `wal_probe` | 0 |
| `large_notes` | 4 |
| `inventory_audit` | 0 |

## Формат каждого опыта

```sql
-- Experiment ID:
-- Question:
-- Invariant:
-- Prediction:
-- Command:
-- Actual result:
-- Explanation:
-- Cleanup/reconciliation:
```

## Самооценка дня

В конце файла ответь:

1. Что получилось самостоятельно?
2. Где прогноз отличался от факта?
3. Какой риск для Django-проекта обнаружен?
4. Какие результаты измерены, а какие только предполагаются?
5. Что пока не можешь объяснить без конспекта?

---

# День 1. MVCC и snapshots

## Паспорт задания

- **Цель:** наблюдать версии строк и snapshots и связать их с видимостью данных между транзакциями.
- **Рабочий файл:** `day_01_mvcc.sql`; двухсессионные шаги и выводы хранятся рядом с опытом.
- **Порядок:** докажи подключение и baseline; проведи update/rollback и изучи tuple metadata; повтори READ COMMITTED и REPEATABLE READ в двух sessions; затем long transaction и HOT observation.
- **Наблюдаемый результат:** каждая session показывает ожидаемую версию строки, а комментарии различают логическую строку и физические tuple versions.
- **Готово, если:** snapshot объясняет видимость; rollback не считается отсутствием созданной версии; системные columns используются только как учебное наблюдение; HOT-вывод сформулирован осторожно.
- **Пример:** одна session после чужого commit видит новое значение в READ COMMITTED, но сохраняет snapshot в REPEATABLE READ.
- **Обязательно:** шесть заданий и сценарии. **Рекомендация:** рядом с каждым SELECT указать ожидаемую видимую версию.

## Результат дня

Ученик наблюдает смену tuple version, объясняет visibility в двух isolation levels и связывает long transaction с cleanup horizon.

## Теория

Прочитать разделы 1–9 `THEORY.md`.

## Файл

`day_01_mvcc.sql`.

## Задание 1. Connection proof и baseline

Сохрани:

- PostgreSQL version;
- database/user/application name;
- текущие `id`, `quantity`, `xmin`, `xmax`, `ctid` для `inventory.id = 1`;
- точное business значение quantity.

Объясни, какие columns внутренние и почему на них нельзя строить public API.

## Задание 2. Rollback и tuple version

В transaction:

1. сохрани tuple metadata;
2. обнови `quantity` относительным выражением;
3. снова прочитай metadata;
4. предскажи состояние после `ROLLBACK`;
5. откати;
6. выполни reconciliation query.

Не требуй, чтобы `ctid` после rollback обязательно совпал на всех implementations/scenarios; зафиксируй фактический результат и logical invariant.

## Задание 3. `READ COMMITTED` в двух sessions

Используй два окна. Session A начинает transaction и читает row. Session B меняет её и commits. Session A выполняет второй `SELECT`.

Сохрани:

- порядок statements;
- значения quantity и metadata;
- объяснение нового snapshot на второй statement;
- финальный rollback/restore.

## Задание 4. `REPEATABLE READ`

Повтори choreography. Докажи, что Session A продолжает видеть согласованный snapshot. После завершения transaction покажи новое committed состояние.

## Задание 5. Long transaction observation

Открой учебную transaction с `application_name = 'week8_long_tx'`, получи snapshot и из второй session найди её в `pg_stat_activity`.

Зафиксируй:

- `xact_start`;
- `state`;
- `backend_xmin`, если доступен;
- почему `idle in transaction` отличается от обычного `idle`;
- действие cleanup.

Не оставляй session открытой после опыта.

## Задание 6. HOT observation

Сравни `n_tup_upd`/`n_tup_hot_upd` до и после серии updates неиндексированной column `note`. Затем измени indexed column в rollback-only опыте.

Не обещай конкретный HOT count: он зависит от page layout/fillfactor и statistics timing. Итог — объяснение условий, а не обязательное число.

## Обязательные сценарии

- M01 baseline system columns;
- M02 update создаёт наблюдаемую новую version;
- M03 rollback сохраняет business invariant;
- M04 `READ COMMITTED` получает новый snapshot;
- M05 `REPEATABLE READ` сохраняет snapshot;
- M06 новая transaction видит commit;
- M07 long transaction найдена в activity view;
- M08 cleanup подтверждён;
- M09 `ctid` отвергнут как business ID;
- M10 HOT result описан без ложной гарантии.

## Контрольные вопросы дня

1. Что создаёт новую tuple version?
2. От чего зависит visibility?
3. Почему nonzero `xmax` нельзя интерпретировать без контекста?
4. Как long transaction влияет на cleanup?

---

# День 2. Vacuum, autovacuum, freeze и bloat

## Паспорт задания

- **Цель:** понять, почему старые tuple versions требуют обслуживания, и безопасно оценить vacuum/freeze/bloat без опасных команд.
- **Рабочий файл:** `day_02_vacuum_autovacuum.sql` и текстовые решения внутри него.
- **Порядок:** определи термины; сними статистику; создай контролируемый churn; сравни cleanup с long snapshot; выполни обычный VACUUM ANALYZE; рассчитай threshold; проведи read-only freeze audit и решение по VACUUM FULL.
- **Наблюдаемый результат:** before/after metrics записаны вместе с ограничениями интерпретации, а maintenance-решения имеют причину и безопасное окно.
- **Готово, если:** dead tuples не приравнены напрямую к точному bloat; autovacuum threshold рассчитан; long transaction учтён; VACUUM FULL не запускается как обычная профилактика.
- **Пример:** расчёт порога показывает, после какого ориентировочного числа изменений таблица становится кандидатом autovacuum.
- **Обязательно:** восемь заданий и сценарии. **Рекомендация:** не делать вывод по одной системной метрике без контекста workload.

## Результат дня

Ученик различает maintenance mechanisms, читает table statistics и проводит безопасный churn/vacuum experiment.

## Теория

Разделы 10–19.

## Файл

`day_02_vacuum_autovacuum.sql`.

## Задание 1. Maintenance vocabulary

Своими словами заполни matrix:

| Operation | Dead-space reuse | Planner stats | Visibility map | Return space to OS | Lock/rewrite risk |
|---|---|---|---|---|---|
| `VACUUM` | | | | | |
| `ANALYZE` | | | | | |
| `VACUUM (ANALYZE)` | | | | | |
| `VACUUM FULL` | | | | | |

## Задание 2. Baseline statistics

Сохрани `pg_stat_user_tables`, `pg_total_relation_size`, `pg_relation_size` и `pg_indexes_size` для lab tables.

Рядом напиши, какие поля estimates/counters и почему между sessions возможна задержка.

## Задание 3. Churn

В отдельной table fixture выполни воспроизводимую серию updates и deletes. Не затрагивай все rows без predicate. Сравни:

- exact current row count;
- estimated live/dead tuples;
- table/index sizes;
- timestamps последнего maintenance.

## Задание 4. Long snapshot и cleanup

С открытой старой transaction в Session A создай churn в Session B. Выполни обычный `VACUUM` в B и зафиксируй observation. Закрой A, повтори maintenance и объясни разницу без требования конкретного размера файла.

Обязательны timeout, cleanup и reconciliation.

## Задание 5. `VACUUM (ANALYZE)`

Выполни только для `week8_lab.churn_probe` вне transaction block. Сравни statistics before/after. Объясни, почему exact file size может не уменьшиться.

## Задание 6. Autovacuum threshold calculation

Прочитай effective settings и рассчитай примерный vacuum trigger для `churn_probe` по текущей documented formula. Отдели global values от возможных table storage parameters.

Это расчёт для понимания, не изменение настроек.

## Задание 7. Freeze-risk read-only audit

Прочитай `age(datfrozenxid)` для текущей database и `age(relfrozenxid)` для lab tables. Не объявляй число безопасным/опасным без сравнения с effective settings и документацией версии.

## Задание 8. `VACUUM FULL` decision

Не выполнять. Напиши короткий runbook decision:

- когда его вообще рассматривать;
- какой lock;
- какое дополнительное место;
- какой rollback/fallback;
- почему сначала ищется root cause.

## Обязательные сценарии

- V01 baseline stats и sizes;
- V02 exact count отделён от estimate;
- V03 update/delete churn ограничен fixture;
- V04 long snapshot завершён;
- V05 ordinary vacuum выполнен вне transaction;
- V06 analyze timestamp/counters проверены;
- V07 file size не объявлен bloat без evidence;
- V08 autovacuum settings только прочитаны;
- V09 freeze ages прочитаны безопасно;
- V10 `VACUUM FULL` не выполнен и описан как exceptional.

## Контрольные вопросы дня

1. Какие четыре задачи выполняет vacuuming ecosystem?
2. Почему ordinary vacuum не обязан уменьшать файл?
3. Что даёт visibility map?
4. Почему freeze важнее производительности?

---

# День 3. WAL, recovery и TOAST

## Паспорт задания

- **Цель:** связать журналирование изменений с recovery и исследовать хранение больших значений без неверных гарантий.
- **Рабочий файл:** `day_03_wal_toast.sql` плюс recovery-решение в предусмотренном текстовом разделе.
- **Порядок:** определи WAL-термины; зафиксируй LSN; измерь WAL distance для операций; сравни rollback; спроектируй backup/PITR; затем проведи TOAST и narrow-projection опыты.
- **Наблюдаемый результат:** LSN-наблюдения и размерные показатели подписаны, а recovery design содержит RPO/RTO, backup, WAL archive и процедуру проверки восстановления.
- **Готово, если:** WAL не назван backup; rollback не означает отсутствие WAL; PITR включает base backup; TOAST-вывод основан на наблюдении; `SELECT *` сравнивается с узкой проекцией.
- **Пример:** recovery-план отвечает, до какого момента можно восстановиться и как доказать, что резервная копия действительно читается.
- **Обязательно:** семь заданий и сценарии. **Рекомендация:** указывать версию PostgreSQL рядом с системными функциями измерения.

## Результат дня

Ученик измеряет WAL distance, объясняет durability/recovery chain и наблюдает хранение больших values.

## Теория

Разделы 20–26.

## Файл

`day_03_wal_toast.sql`.

## Задание 1. WAL vocabulary

Определи: WAL record, LSN, flush, checkpoint, REDO, base backup, archive, PITR, RPO, RTO.

Нарисуй последовательность:

```text
application change → WAL record → WAL flush → commit acknowledged
                     → data page later → crash recovery if needed
```

## Задание 2. LSN baseline

Сохрани `pg_current_wal_lsn()` и доступные поля `pg_stat_wal`/`pg_stat_checkpointer`. Пометь version-dependent columns.

## Задание 3. WAL distance for insert/update

Для ограниченного batch в `wal_probe`:

1. сохрани before LSN;
2. выполни committed inserts;
3. сохрани after LSN и difference;
4. отдельно повтори updates;
5. объясни noise от других sessions/background.

Это observation, не performance benchmark.

## Задание 4. Rollback и WAL

Предскажи, означает ли rollback отсутствие WAL activity. Выполни небольшой rollback-only change и измерь LSN distance. Объясни, почему «business data не changed» и «никакой WAL не появился» — разные утверждения.

## Задание 5. Recovery design

В comments составь план для проекта:

- RPO/RTO;
- base backup cadence;
- WAL archive retention;
- encryption/access;
- restore test cadence;
- owner и evidence;
- почему replica не заменяет backup.

Никаких реальных backup/restore commands без отдельного стенда.

## Задание 6. TOAST observations

Для четырёх rows `large_notes` сравни:

- characters;
- UTF-8 bytes;
- stored datum bytes;
- whole row size;
- main/TOAST relation sizes.

Найди compressible и poorly-compressible examples. Не делай вывод по одному числу: row/header/page и toast chunks отличаются от logical length.

## Задание 7. Narrow projection

Сравни смысл `SELECT id, title` и `SELECT *` для table с большими descriptions. Если измеряемый plan не показывает bytes transfer, не выдумывай их; объясни ожидаемую цену detoast/network на уровне design.

## Обязательные сценарии

- W01 WAL-before-data объяснено;
- W02 before/after LSN сохранены;
- W03 insert WAL distance измерен;
- W04 update WAL distance измерен;
- W05 rollback не приравнен к нулевому WAL;
- W06 checkpoint observation read-only;
- W07 replica отделена от backup;
- W08 RPO/RTO конкретны;
- T01 compressible value исследовано;
- T02 Unicode characters/bytes различены;
- T03 main/TOAST sizes зафиксированы;
- T04 narrow projection обоснована.

## Контрольные вопросы дня

1. Что должно быть flushed до подтверждения durable commit?
2. Почему LSN difference содержит noise?
3. Из чего состоит PITR?
4. Когда значение detoasted?

---

# День 4. Functions, procedures и triggers

## Паспорт задания

- **Цель:** размещать логику в базе только при ясной выгоде и понимать транзакционные последствия routines/triggers.
- **Рабочий файл:** `day_04_routines_triggers.sql` с placement matrix и operational notes.
- **Порядок:** классифицируй кандидатов app/DB; создай простую SQL function; затем table-dependent function; добавь procedure; реализуй audit trigger; проверь rollback и заверши security/operability note.
- **Наблюдаемый результат:** функции возвращают заявленный результат, procedure вызывается по контракту, audit появляется и откатывается вместе с основной операцией.
- **Готово, если:** trigger не скрывает критическую бизнес-логику без причины; recursion/search_path/privileges рассмотрены; ошибки не проглатываются; выбор function/procedure объяснён.
- **Пример:** изменение выбранной строки добавляет одну audit-запись, а rollback удаляет и изменение, и эту запись.
- **Обязательно:** семь заданий и сценарии. **Рекомендация:** для каждой routine указать владельца, права и способ версионирования.

## Результат дня

Ученик выбирает подходящий database mechanism, реализует чистую function, простую procedure и прозрачный audit-trigger с rollback tests.

## Теория

Разделы 27–34.

## Файл

`day_04_routines_triggers.sql`.

## Задание 1. Placement matrix

Для правил ниже выбери constraint/function/procedure/trigger/application service и объясни:

1. `quantity >= 0`;
2. расчёт inventory value;
3. purchase workflow с locks и payment;
4. audit каждого изменения quantity независимо от caller;
5. email после commit;
6. запрет дублирующего external offer ID.

## Задание 2. SQL function

Самостоятельно создай `inventory_value(quantity, unit_price)` с подходящими types, null contract и volatility. Проверь normal, zero, null и negative input. Negative case должен соответствовать явно записанному contract, а не случайному поведению.

## Задание 3. Set-returning или table-dependent function

Создай небольшую function для low-stock report. Выбери `STABLE`/`VOLATILE` осознанно. Не используй `SECURITY DEFINER`.

## Задание 4. Procedure

Создай procedure, которая явно меняет только lab note/status по ID. Она не делает `COMMIT`, не вызывает внешние systems и должна работать внутри caller transaction.

Проверь `CALL`, rollback и missing ID behavior.

## Задание 5. Audit trigger

Создай trigger function и trigger, которые пишут audit только при фактическом изменении quantity. Audit содержит inventory ID, old/new values, operation, timestamp и actor (`current_user` либо agreed application actor field).

## Задание 6. Trigger transaction semantics

Проверь:

- successful update создаёт одну audit row;
- update без изменения quantity не создаёт noise;
- rolled-back update не оставляет audit row;
- multi-row update создаёт ожидаемое число rows;
- trigger не меняет quantity самостоятельно;
- delete/insert behavior соответствует declared event set.

## Задание 7. Security/operability note

Опиши privileges, `search_path`, migration/drop order, observability и почему main purchase logic остаётся в service layer.

## Обязательные сценарии

- R01 placement matrix завершена;
- R02 immutable function действительно чистая;
- R03 null/negative contracts проверены;
- R04 table-reading function не помечена immutable;
- R05 procedure имеет явный call/rollback contract;
- R06 trigger фильтрует unchanged quantity;
- R07 rollback удаляет audit effect;
- R08 multi-row result проверен;
- R09 внешний I/O отсутствует;
- R10 security invoker/search path decision записано;
- R11 objects удаляются в корректном dependency order в cleanup comments;
- R12 business workflow не спрятан в trigger.

## Контрольные вопросы дня

1. Когда constraint лучше trigger?
2. Что означает volatility function?
3. Почему audit row откатывается с основной transaction?
4. Почему `SECURITY DEFINER` опаснее invoker?

---

# День 5. Partitioning

## Паспорт задания

- **Цель:** выбрать реального кандидата на partitioning и доказать routing/pruning вместе с эксплуатационной ценой.
- **Рабочий файл:** `day_05_partitioning.sql` и lifecycle runbook в комментариях/назначенном документе.
- **Порядок:** оцени кандидата; создай parent и partitions; проверь границы; исследуй uniqueness limitation; добавь индексы; докажи pruning; затем опиши lifecycle и окончательное решение.
- **Наблюдаемый результат:** тестовые rows попадают в ожидаемые partitions, планы показывают pruning, а out-of-range и boundary cases имеют явный результат.
- **Готово, если:** partition key выбран по workload/lifecycle; границы не пересекаются; ограничения уникальности учтены; операции создания/архивации partitions описаны; решение допускает отказ от partitioning.
- **Пример:** запись ровно на границе дат попадает только в одну заранее названную partition.
- **Обязательно:** восемь заданий и сценарии. **Рекомендация:** сначала доказать проблему размером/обслуживанием, затем применять partitioning.

## Результат дня

Ученик проектирует range partitions, проверяет routing/pruning и принимает решение, нужен ли partitioning таблице продаж сейчас.

## Теория

Разделы 35–42.

## Файл

`day_05_partitioning.sql`.

## Задание 1. Candidate decision

Для `sales_log` запиши:

- current size/rows;
- dominant queries;
- retention requirement;
- candidate key;
- granularity;
- benefits/costs;
- decision now;
- revisit trigger.

Не начинать DDL со слова «таблица когда-нибудь вырастет».

## Задание 2. Parent и partitions

Создай отдельную `sales_partitioned` с `RANGE (sold_at)` и минимум тремя monthly partitions плюс controlled default partition. Constraints и types должны соответствовать fixture domain.

## Задание 3. Boundary routing

Проверь rows ровно:

- на нижней границе;
- за секунду/микросекунду до верхней;
- ровно на следующей границе;
- вне известных ranges;
- с `NULL`, если column запрещает null.

Используй `tableoid::regclass`, чтобы показать physical destination.

## Задание 4. Unique constraint limitation

До запуска предскажи, примет ли PostgreSQL `UNIQUE (sale_id)` при partition key `sold_at`. Сохрани actual error как закомментированный результат и реализуй корректное ограничение.

## Задание 5. Indexes

Создай parent-level indexes под два query shapes. Проверь child indexes. Не дублируй PK prefix без анализа.

## Задание 6. Pruning

Сохрани `EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)` минимум для:

- одного месяца;
- двух соседних месяцев;
- запроса без partition predicate;
- parameterized/prepared query, если доступно;
- predicate с timezone boundary.

Назови scanned/pruned partitions по plan.

## Задание 7. Lifecycle runbook

Не выполняя destructive step, напиши commands и gates для create-next, attach preloaded, detach/archive и drop-old partition. Отметь locks, validation, backup и approval.

## Задание 8. Decision

Ответь отдельно:

- полезен ли lab result;
- нужен ли partitioning первой версии Django project;
- какое измерение изменит решение.

## Обязательные сценарии

- P01 candidate связан с workload;
- P02 ranges не имеют gaps/overlaps для планового периода;
- P03 lower/upper boundaries доказаны;
- P04 unmatched row обработана осознанно;
- P05 `tableoid` показывает routing;
- P06 unique limitation воспроизведено;
- P07 child indexes проверены;
- P08 single-range pruning доказан;
- P09 multi-range plan сохранён;
- P10 no-key query показывает цену;
- P11 timezone boundary рассмотрена;
- P12 destructive lifecycle не выполнен;
- P13 current decision/revisit trigger записаны.

## Контрольные вопросы дня

1. Что является partition key хорошего range design?
2. Почему default partition требует monitoring?
3. Что означает отсутствие global unique index?
4. Когда pruning может не помочь?

---

# День 6. Scaling decisions

## Паспорт задания

- **Цель:** выбирать репликацию, sharding и расширения по требованиям согласованности, доступности и эксплуатации.
- **Рабочие файлы:** `day_06_scaling_adr.md` и SQL/read-only evidence, перечисленные ниже.
- **Порядок:** собери replication inventory; сравни physical/logical; определи read-after-write; составь failure table; выбери shard key; разберись с CAP/PACELC; сравни СУБД и закончи PostGIS ADR.
- **Наблюдаемый результат:** решения оформлены как варианты с контекстом, компромиссами, рисками, сигналами пересмотра и выбранным вариантом.
- **Готово, если:** replica не называется backup; lag учтён; cross-shard операции названы; CAP не используется как лозунг; PostgreSQL/MySQL сравниваются под конкретный workload.
- **Пример:** ADR прямо говорит, какие чтения можно отправлять на replica, а какие после записи должны идти на primary.
- **Обязательно:** восемь заданий и сценарии. **Рекомендация:** для каждого решения добавить метрику, после которой его следует пересмотреть.

## Результат дня

Ученик различает scaling mechanisms и составляет architecture decision record без установки новых систем.

## Теория

Разделы 43–52.

## Файлы

- `day_06_scaling_observability.sql`;
- `day_06_architecture_decisions.md`.

## Задание 1. Read-only replication inventory

В SQL проверь без ошибки на standalone server:

- `pg_is_in_recovery()`;
- `current_setting('wal_level')`;
- rows в `pg_stat_replication`;
- rows в `pg_replication_slots`;
- доступность `pg_stat_wal_receiver`;
- current/replay LSN functions только когда подходят роли server.

Ноль rows означает «не наблюдаю активную replica/slot», а не доказательство, что архитектура никогда их не использует.

## Задание 2. Physical vs logical matrix

Сравни unit of change, schema compatibility, DDL, sequences, filtering, failover/read use, lag signal и typical risk.

## Задание 3. Read-after-write contract

Для сценариев выбери primary/replica/допустимую задержку:

- ответ сразу после покупки;
- каталог через минуту;
- nightly analytics;
- проверка остатка перед purchase lock;
- admin audit view.

## Задание 4. Replica/backup failure table

Разбери application delete, corrupted primary disk, region loss, ransomware/credential compromise, lagging replica и bad migration. Для каждого укажи, помогает ли replica, backup, PITR или комбинация.

## Задание 5. Shard-key exercise

Сравни `dealership_id`, country и customer hash по routing, hotspots, joins, resharding, uniqueness и transaction boundaries. Итог может быть «не шардировать».

## Задание 6. CAP/PACELC scenarios

Для network partition между primary region и secondary region опиши два возможных продукта: блокировать writes ради consistency или принимать локальные writes ради availability с последующим conflict resolution.

Отдельно опиши normal-mode latency/consistency choice для replica read.

## Задание 7. PostgreSQL/MySQL comparison

Составь не менее восьми criteria текущего проекта. Каждое утверждение снабди ссылкой на official docs конкретной версии. Не проводи случайный benchmark.

## Задание 8. PostGIS ADR

Запиши:

- current geographic requirements;
- достаточно ли country code;
- какой requirement потребует coordinates/radius/polygon;
- `geometry` vs `geography` на уровне выбора;
- index/query candidate (`GiST`, `ST_DWithin`);
- decision now и revisit trigger.

## Обязательные сценарии

- S01 standalone/recovery state проверен;
- S02 replication views прочитаны без мутаций;
- S03 physical/logical различены;
- S04 slot WAL-retention risk назван;
- S05 read-after-write contract заполнен;
- S06 replica не названа backup;
- S07 RPO/RTO связаны с restore;
- S08 три shard keys сравнены;
- S09 current decision — no sharding либо доказанная причина;
- S10 CAP применён только к partition scenario;
- S11 PACELC normal mode описан;
- S12 PostgreSQL/MySQL comparison source-based;
- S13 PostGIS decision соответствует requirements;
- S14 partitioning/replication/sharding не смешаны.

## Контрольные вопросы дня

1. Какие stages replication lag можно измерять?
2. Что удерживает отстающий slot?
3. Почему sharding усложняет uniqueness?
4. Чем CAP consistency отличается от ACID consistency?

---

# День 7. Итоговый PostgreSQL readiness audit

## Паспорт задания

- **Цель:** собрать воспроизводимый аудит готовности PostgreSQL-части проекта к эксплуатации и дальнейшему масштабированию.
- **Рабочая область:** каталог `day_07_postgresql_readiness_audit/` и восемь артефактов, перечисленных ниже.
- **Порядок:** сначала README и безопасные предусловия; затем MVCC/maintenance evidence; recovery plan; routines/triggers; partitioning; scaling ADR; regression checks; последней собери traceability.
- **Наблюдаемый результат:** независимый разработчик может пройти документы по порядку, выполнить безопасные SQL-проверки и связать каждый вывод с evidence.
- **Готово, если:** все 30 сценариев отмечены; production-only действия не запускаются; backup/restore имеет проверку; решения содержат trade-offs; SQL повторяем и ограничен учебной базой.
- **Пример:** таблица traceability связывает требование «не терять подтверждённые покупки» с recovery design, SQL-проверкой и зафиксированным результатом.
- **Обязательно:** восемь частей, 30 сценариев и финальная защита. **Рекомендация:** каждый недоступный runtime-опыт пометить честно, не заменяя его предположением.

## Результат дня

Создать связанный, проверяемый пакет решений перед Django без преждевременного усложнения архитектуры.

## Предусловие

- дни 1–6 приняты;
- audit недели 7 принят;
- fixture восстановлена в согласованное состояние;
- все результаты помечены как measured/inferred/deferred.

## Папка

`day_07_postgresql_readiness_audit/`.

## Часть 1. `README.md`

Заполни environment, prerequisites, run order, safety boundary, evidence index, limitations и cleanup state.

## Часть 2. `mvcc_maintenance.sql`

Read-only audit запросы для:

- long/idle transactions;
- table activity;
- dead/live tuple estimates;
- maintenance timestamps;
- relation/index sizes;
- freeze ages;
- settings snapshot.

Никаких универсальных alarm thresholds без environment context.

## Часть 3. `wal_recovery.md`

Запиши WAL mental model, RPO/RTO, backup/retention, restore test, replica limitations и failure matrix.

## Часть 4. `routines_triggers.sql`

Перенеси только принятые function/trigger decisions. Для каждого object добавь purpose, owner, privilege, transaction/rollback tests и migration cleanup.

## Часть 5. `partitioning.sql`

Сохрани candidate DDL и plans. Если current decision — не partitionировать, файл всё равно показывает корректный future design и measurable trigger.

## Часть 6. `scaling_adr.md`

Отдельные decisions:

- primary/replica reads;
- physical/logical replication;
- backup vs replica;
- shard trigger/key;
- CAP/PACELC scenario;
- PostgreSQL/MySQL;
- PostGIS.

## Часть 7. `regression_checks.sql`

Проверь не менее 30 сценариев: invariants недели 6, transaction/index cases недели 7 и безопасные week8 checks. Checks не изменяют итоговые business data либо выполняются с rollback/cleanup.

## Часть 8. Evidence traceability

В README создай table:

| Decision | Evidence file/query | Status | Revisit trigger |
|---|---|---|---|

Каждое ключевое решение должно иметь evidence или честный статус `deferred`.

## 30 обязательных сценариев

1. environment proof;
2. schema row counts;
3. no long transaction baseline;
4. idle-in-transaction query;
5. table statistics query;
6. exact-vs-estimate note;
7. relation sizes;
8. index sizes;
9. maintenance timestamps;
10. effective autovacuum settings;
11. database freeze age;
12. table freeze ages;
13. WAL LSN read;
14. WAL/checkpointer views or documented permission limit;
15. RPO;
16. RTO;
17. restore test plan;
18. replica-not-backup proof;
19. TOAST candidate inventory;
20. narrow projection decision;
21. routine placement matrix;
22. function contract tests;
23. trigger success test;
24. trigger rollback test;
25. partition boundary routing;
26. partition pruning plan;
27. uniqueness limitation;
28. read-after-write routing;
29. sharding/PostGIS current decisions;
30. all prior business invariants still pass.

## Финальное объяснение без подсказки

Ученик отвечает минимум на 18 из 24 вопросов наставника. Обязательные области: MVCC, vacuum/freeze, WAL/recovery, TOAST, routines/triggers, partitioning, replication/sharding, CAP/PACELC и technology decisions.

## Критерий итогового зачёта

- минимум 8/10;
- 30 сценариев имеют actual evidence либо честное documented limitation;
- нет незакрытых transactions;
- нет destructive production advice;
- audit согласован с weeks 6–7;
- decisions не противоречат друг другу;
- ученик объясняет, почему часть технологий не нужна сейчас;
- `ASSESSMENT.md` содержит явный допуск к неделе 9.

---

# После каждого ревью

1. Наставник фиксирует первую оценку и причины ошибок в `ASSESSMENT.md`.
2. Ученик сам исправляет обязательные пункты.
3. Первая оценка и история ошибок не удаляются.
4. Следующий день открывается при итоговой оценке минимум 7/10 без критической ошибки.
5. После day 7 проводится отдельный контроль понимания.
6. Неделя 9 остаётся заблокированной до полного зачёта недели 8.
