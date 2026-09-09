# Практика недели 7: транзакции и производительность PostgreSQL

Статус: **заблокирована до полного зачёта недель 0–6**.

Все решения пишутся в файлах `week_07_transactions_performance`. Готовые решения намеренно отсутствуют.

## Общие правила

1. Работай только после допуска из недели 6.
2. PostgreSQL database должна быть явно подтверждена как одноразовая учебная.
3. Fixture запускается наставником/учеником только после проверки connection.
4. Isolation/locking лаборатории выполняются в двух подписанных sessions.
5. Перед каждой blocking command установи local timeout.
6. До запуска запиши прогноз: выполнится, будет ждать или упадёт.
7. После каждого опыта выполни `COMMIT`/`ROLLBACK` и reconciliation query.
8. Не оставляй session `idle in transaction`.
9. Не используй `DROP ... CASCADE`, `TRUNCATE ... CASCADE` и чужие schemas.
10. Не выполняй `EXPLAIN ANALYZE` modifying statement без внешнего `BEGIN`/`ROLLBACK`.
11. Index создаётся только после записи workload и baseline plan.
12. Не выдумывай plan nodes, times или buffer numbers: прикладывай фактический результат.
13. Не меняй teacher-owned `fixtures/postgresql_lab.sql`.

## Подготовка PostgreSQL при активации

Сейчас эти действия не выполняются. При фактическом начале недели:

1. проверить `psql` и server;
2. согласовать точное имя learning database;
3. подключиться к ней;
4. выполнить `SELECT current_database(), current_user, version();`;
5. загрузить fixture один раз с остановкой на первой ошибке;
6. сверить итоговые row counts;
7. открыть две connections к той же database;
8. записать способ безопасно пересоздать лабораторию без риска для других данных.

Fixture намеренно не удаляет существующую `week7_lab`. Повторный запуск должен завершиться на `CREATE SCHEMA`, а не уничтожить старую работу.

## Формат записи каждого эксперимента

В комментариях рядом с SQL фиксируй:

```text
Experiment:
Invariant:
Initial state:
Session order:
Prediction:
Actual result:
SQLSTATE/error, если был:
Final state:
Explanation:
```

Для index/plan experiment:

```text
Workload:
Parameters:
Expected rows:
Baseline plan:
Hypothesis:
Candidate index/query rewrite:
Plan after:
Correctness check:
Write/storage cost:
Decision: keep/reject
```

## Самооценка дня

В конце каждого файла заполни:

```text
1. Что получилось:
2. Где прогноз отличался от результата:
3. Какой invariant/plan node был главным:
4. Что я проверил фактически:
5. Что пока не могу объяснить:
```

---

# День 1. Transactions, ACID, rollback и savepoints

## Паспорт задания

- **Цель:** управлять границей транзакции и доказать атомарность через состояния до, внутри и после неё.
- **Рабочий файл:** `day_01_transactions.sql` и наблюдения по формату эксперимента в этом же файле.
- **Порядок:** опиши термины; зафиксируй baseline; проведи rollback; воспроизведи partial failure; добавь savepoint; затем обоснуй business boundary и исследуй gaps идентификаторов.
- **Наблюдаемый результат:** каждый опыт содержит setup, sessions, ожидаемое/фактическое состояние и cleanup; повторный SELECT доказывает commit или rollback.
- **Готово, если:** transaction boundary включает весь бизнес-инвариант; failure не оставляет половинчатых данных; savepoint не подменяет полную атомарность; gaps не считаются ошибкой последовательности.
- **Пример:** после отката количество и баланс совпадают с baseline, хотя внутри транзакции были видны изменения.
- **Обязательно:** шесть заданий и сценарии. **Рекомендация:** отмечать момент, с которого изменение видит другая session.

## Результат дня

Ты умеешь объединять несколько changes одной business operation, безопасно откатывать их и объяснять каждый элемент ACID без завышенных обещаний.

## Теория

Прочитай разделы 1–8 и 23–24 в `THEORY.md`.

## Задание 1. Transaction vocabulary

В `day_01_transactions.sql` своими словами опиши:

- transaction;
- transaction boundary;
- autocommit;
- atomicity, consistency, isolation, durability;
- commit и rollback;
- savepoint;
- aborted transaction.

Для каждого термина приведи маленький пример из покупки автомобиля.

## Задание 2. Baseline и rollback

Для customer `id = 1` и inventory `(dealership_id = 1, car_model_id = 1)`:

1. прочитай исходные balance, quantity и price;
2. начни transaction;
3. уменьши balance на price;
4. уменьши quantity на 1;
5. внутри той же session покажи изменённые values;
6. выполни `ROLLBACK`;
7. докажи, что оба значения вернулись точно к baseline.

Не используй hardcoded сумму, если её можно получить из locked/selected row. В первом дне lock ещё не обязателен: concurrency появится позже.

## Задание 3. Partial failure

Внешняя transaction должна:

1. выполнить допустимое изменение balance;
2. затем намеренно нарушить quantity constraint;
3. записать точную PostgreSQL error;
4. показать, что следующий `SELECT` не выполняется из-за aborted state;
5. выполнить `ROLLBACK`;
6. подтвердить восстановление baseline.

Failing statement после исследования оставь закомментированным, чтобы полный файл мог запускаться с остановкой на неожиданных errors.

## Задание 4. Savepoint

Смоделируй:

- основной допустимый шаг transaction;
- optional Offer update после `SAVEPOINT`;
- ошибку optional step;
- `ROLLBACK TO SAVEPOINT`;
- завершение основной части;
- финальный `ROLLBACK`, чтобы fixture не изменилась.

Объясни, почему savepoint нельзя использовать для commit покупки с уже нарушенным stock/balance invariant.

## Задание 5. Boundary decision

Для сценариев «покупка», «закупка у поставщика», «отправка email после покупки» заполни transaction map:

- что входит в database transaction;
- что должно происходить до неё;
- что должно происходить после commit;
- что делать при business rejection;
- какие histories создаются вместе с current-state changes.

## Задание 6. Id gaps

Используй teacher-owned `week7_lab.learning_id_sequence`: получи `nextval` внутри transaction, выполни rollback, затем получи следующее значение. Проверь, возвращается ли sequence value назад после rollback.

Не делай вывод, что gap означает пропавшую business operation.

## Обязательные сценарии

1. `ROLLBACK` отменяет оба изменения.
2. Внутри transaction собственные изменения видны.
3. Constraint violation переводит transaction в aborted state.
4. После полного rollback session снова выполняет query.
5. `ROLLBACK TO SAVEPOINT` отменяет только нужную часть.
6. Основной invariant не скрывается savepoint.
7. Transaction boundary покупки охватывает current state и history.
8. Внешнее ожидание не держит transaction открытой.
9. Sequence gap объяснён корректно.
10. Fixture после всех опытов совпадает с baseline.

## Контрольные вопросы дня

1. Как из business invariant получить transaction boundary?
2. Почему consistency не создаётся одним словом `BEGIN`?
3. Что происходит со следующими statements после error внутри transaction?
4. Чем `ROLLBACK TO SAVEPOINT` отличается от полного `ROLLBACK`?

---

# День 2. Isolation levels и read anomalies

## Паспорт задания

- **Цель:** воспроизвести конкурентные чтения в двух sessions и выбрать isolation level по требуемому инварианту.
- **Рабочие файлы:** `day_02_isolation_session_a.sql`, `day_02_isolation_session_b.sql` и `day_02_isolation_notes.md`.
- **Порядок:** докажи разные connections; проверь отсутствие dirty read; воспроизведи non-repeatable и predicate change; повтори в REPEATABLE READ; затем update conflict и SERIALIZABLE anomaly с retry-выводом.
- **Наблюдаемый результат:** шаги A/B пронумерованы, а notes содержит матрицу «уровень → что увидела session → какой инвариант защищён».
- **Готово, если:** каждый эффект воспроизводим в указанном порядке; snapshot границы объяснены; PostgreSQL READ UNCOMMITTED описан корректно; serialization failure считается штатным поводом retry.
- **Пример:** session A дважды читает одну строку, session B между чтениями commit-ит изменение, а результат зависит от выбранного уровня.
- **Обязательно:** восемь заданий и сценарии. **Рекомендация:** после каждого шага записывать, какая транзакция открыта.

## Результат дня

Ты наблюдаешь snapshots двух sessions и отличаешь стандартные названия anomalies от фактических гарантий PostgreSQL.

## Теория

Прочитай разделы 9–14 в `THEORY.md`.

## Файлы

- `day_02_isolation_session_a.sql`;
- `day_02_isolation_session_b.sql`.

Команды пронумеруй как `A01`, `B01`, `A02`, чтобы порядок можно было повторить точно.

## Задание 1. Connection proof

В обеих sessions выведи:

- current database;
- backend PID;
- current transaction isolation;
- исходное значение одного выбранного customer balance;
- подпись `session_a`/`session_b`.

## Задание 2. Dirty read, который не произойдёт

Порядок:

1. A начинает `READ COMMITTED` и читает balance.
2. B начинает transaction и меняет balance без commit.
3. A читает balance повторно.
4. B делает rollback.
5. A завершает transaction.

До опыта предскажи, увидит ли A uncommitted value. Зафиксируй факт.

## Задание 3. Non-repeatable read в `READ COMMITTED`

1. A начинает transaction и читает balance.
2. B изменяет тот же balance и commits.
3. A повторяет тот же `SELECT`.
4. A rollback/commit без изменений.
5. отдельной cleanup transaction верни baseline.

Покажи, почему это не dirty read.

## Задание 4. Phantom-like predicate result

Используй predicate на `customer_offer`, например active pending Offers после фиксированной даты.

1. A считает rows.
2. B inserts подходящую row и commits.
3. A повторяет query в `READ COMMITTED`.
4. cleanup удаляет только row с заранее выбранным unique test id.

Проверь не только count, но и identifier добавленной row.

## Задание 5. `REPEATABLE READ`

Повтори experiments 3–4 в `REPEATABLE READ`:

- A сохраняет стабильный snapshot;
- B может commit своё изменение;
- A не видит новый committed state внутри старой transaction;
- после завершения A новая transaction видит current state.

Не называй это блокировкой обычного read.

## Задание 6. Concurrent update conflict

В `REPEATABLE READ` после старого read Session A пытается изменить row, уже committed Session B. Зафиксируй:

- wait, если был;
- точный error;
- SQLSTATE, если client показывает;
- необходимость rollback;
- почему retry должен начинать всю transaction заново.

## Задание 7. PostgreSQL isolation matrix

В обоих файлах либо `notes.md` заполни фактическую таблицу для PostgreSQL:

- requested levels;
- snapshot granularity;
- dirty read;
- non-repeatable read;
- phantom read;
- serialization anomaly;
- необходимость retry.

## Задание 8. Serialization anomaly и `SERIALIZABLE`

На teacher-owned `approval_officer` действует cross-row invariant: хотя бы один officer должен оставаться `is_on_duty = true`.

Сначала в двух `REPEATABLE READ` transactions воспроизведи write skew:

1. A и B видят двух on-duty officers;
2. A выключает officer 1;
3. B выключает officer 2;
4. обе пытаются commit;
5. проверь, может ли invariant стать ложным;
6. восстанови baseline.

Затем повтори тот же choreography в `SERIALIZABLE`. Зафиксируй, какая transaction получила `40001`, и докажи, что у успешно committed состояния остаётся минимум один on-duty officer. Нельзя рассчитывать, какая session будет aborted.

## Обязательные сценарии

1. Sessions подключены к одной learning database.
2. PID sessions различаются.
3. Dirty read не наблюдается в `READ COMMITTED`.
4. Два reads `READ COMMITTED` могут увидеть разные committed values.
5. Predicate result `READ COMMITTED` может измениться.
6. `REPEATABLE READ` сохраняет snapshot.
7. PostgreSQL `REPEATABLE READ` не показывает phantom из минимальной стандартной таблицы.
8. Concurrent update conflict обработан rollback.
9. `READ UNCOMMITTED` не описан как отдельное фактическое поведение PostgreSQL.
10. Write skew наблюдался в `REPEATABLE READ`.
11. `SERIALIZABLE` не допускает commit несовместимого состояния и возвращает `40001` одной transaction.
12. Cleanup возвращает baseline.

## Контрольные вопросы дня

1. Чем dirty read отличается от non-repeatable read?
2. Когда создаётся новый snapshot в `READ COMMITTED` и `REPEATABLE READ`?
3. Чем PostgreSQL isolation matrix отличается от минимальной таблицы SQL standard?
4. Почему данные aborted/retried transaction нельзя использовать как финальный ответ?

---

# День 3. Lost update, row locks и deadlock

## Паспорт задания

- **Цель:** защищать конкурентное изменение остатков с помощью атомарного SQL, блокировок и ограниченного retry.
- **Рабочие файлы:** два session-script дня и `day_03_locking_notes.md`, перечисленные ниже.
- **Порядок:** воспроизведи lost update; замени его relative update; проверь conditional decrement; затем `FOR UPDATE`, `NOWAIT`, очередь `SKIP LOCKED`; осознанно вызови deadlock; исправь порядок locks и опиши retry contract.
- **Наблюдаемый результат:** финальный stock соответствует числу успешных операций; блокировки и ошибки наблюдаются в двух sessions; cleanup возвращает fixture.
- **Готово, если:** stock не уходит ниже нуля; NOWAIT и SKIP LOCKED не перепутаны; deadlock не оставлен случайным; порядок захвата одинаков; retry ограничен и относится только к временным конфликтам.
- **Пример:** из stock `1` два конкурентных списания дают ровно один успех и итог `0`.
- **Обязательно:** девять заданий и сценарии. **Рекомендация:** фиксировать SQLSTATE конфликтов в заметках.

## Результат дня

Ты воспроизводишь опасные interleavings, выбираешь минимальную защиту и оставляешь database в согласованном состоянии.

## Теория

Прочитай разделы 15–22 в `THEORY.md`.

## Файлы

- `day_03_locking_session_a.sql`;
- `day_03_locking_session_b.sql`.

## Задание 1. Lost update

На отдельном выбранном customer balance:

1. A и B читают одинаковое baseline;
2. обе sessions вне SQL рассчитывают разные new values от старого baseline;
3. A записывает и commits;
4. B записывает своё old-based value и commits;
5. reconciliation показывает потерянный effect;
6. cleanup возвращает baseline.

В комментарии запиши, какое именно изменение потерялось. Не воспроизводи опыт на реальном финансовом row.

## Задание 2. Atomic relative update

Повтори два concurrent изменения через:

```text
SET balance = balance + delta
```

Докажи, что оба effects сохраняются. Объясни, почему atomic update решает этот простой случай без предварительного `SELECT FOR UPDATE`.

## Задание 3. Conditional decrement последней единицы

Для inventory `(1, 1)` с quantity 1 две sessions пытаются уменьшить stock через один conditional statement:

- `quantity = quantity - 1`;
- `WHERE quantity >= 1`;
- `RETURNING`.

Ожидание: ровно одна transaction изменяет row, другая получает zero affected rows после ожидания/recheck. Верни baseline отдельной cleanup transaction.

## Задание 4. `FOR UPDATE`

1. A начинает transaction, задаёт timeouts и locks inventory row.
2. B пытается изменить тот же row.
3. Зафиксируй ожидание либо timeout B.
4. A завершает transaction.
5. B rollback после error либо продолжает согласно точному результату.
6. Reconciliation проверяет final state.

Отдельно покажи, что обычный read без locking clause не обязан ждать этот row lock.

## Задание 5. `NOWAIT`

При lock от A, B выполняет `FOR UPDATE NOWAIT`. Зафиксируй немедленный error вместо ожидания и корректно откати B.

## Задание 6. Queue и `SKIP LOCKED`

Два workers выбирают разные pending `work_item`:

1. общий deterministic `ORDER BY priority DESC, id`;
2. `FOR UPDATE SKIP LOCKED LIMIT 1`;
3. A удерживает первый item;
4. B получает следующий unlocked item;
5. обе transactions rollback после доказательства.

Объясни, почему тот же подход нельзя использовать для полного финансового отчёта.

## Задание 7. Deadlock

Используй только два заранее выбранных customer rows и короткий `statement_timeout`:

1. A locks row 1;
2. B locks row 2;
3. A запрашивает row 2;
4. B запрашивает row 1;
5. PostgreSQL aborts одну transaction;
6. обе sessions явно завершаются;
7. данные сверяются.

Запиши точный SQLSTATE `40P01`, если client его показывает. Не запускай новый опыт, пока обе старые transactions не закрыты.

## Задание 8. Consistent lock order

Повтори логическую операцию, но обе sessions берут rows по `id ASC`. Deadlock не должен возникнуть; одна session может корректно ждать другую.

## Задание 9. Retry contract

Без Python-кода напиши точный pseudocode bounded retry:

- максимум attempts;
- whole-transaction restart;
- SQLSTATE allowlist;
- rollback;
- свежие reads;
- backoff;
- idempotency key;
- final error.

## Обязательные сценарии

1. Lost update реально воспроизведён.
2. Atomic relative update сохраняет оба effects.
3. Conditional decrement не создаёт negative stock.
4. Ровно одна попытка забирает последнюю единицу.
5. `FOR UPDATE` блокирует conflicting write.
6. Обычный read не объявлен автоматически blocking.
7. `NOWAIT` быстро возвращает error.
8. `SKIP LOCKED` выдаёт workers разные rows.
9. Queue ordering deterministic.
10. Deadlock реально обнаружен PostgreSQL.
11. Consistent order не создаёт deadlock.
12. После каждого опыта нет открытой transaction и baseline восстановлен.

## Контрольные вопросы дня

1. Почему atomic relative update предотвращает конкретный lost update?
2. Когда всё-таки нужен `SELECT FOR UPDATE`?
3. Чем blocking отличается от deadlock?
4. Какие errors повторяются и почему повторяется вся transaction?

---

# День 4. B-tree, Hash, GIN, GiST, SP-GiST и BRIN

## Паспорт задания

- **Цель:** выбирать семейство индекса по форме запроса, данным и цене записи/хранения.
- **Рабочий файл:** `day_04_index_families.sql` с таблицей решений и наблюдениями.
- **Порядок:** сними inventory индексов; сопоставь workload; создай по одному обоснованному опыту для каждого семейства; проверь планы/результаты; в конце реши, какие учебные индексы удалить.
- **Наблюдаемый результат:** для каждого индекса есть query shape, DDL, evidence и вывод «оставить/не оставлять», а не только факт создания.
- **Готово, если:** B-tree используется для подходящих сравнений; GIN/GiST не объявлены взаимозаменяемыми; BRIN связан с корреляцией/размером; лишние индексы не выдаются за улучшение.
- **Пример:** строка матрицы связывает оператор запроса с возможным индексом и объясняет ограничение выбора.
- **Обязательно:** девять заданий и сценарии. **Рекомендация:** сравнивать не только план чтения, но и размер индекса.

## Результат дня

Ты выбираешь index access method по operator/data/workload и проверяешь candidate через plan, не требуя от planner конкретного node.

## Теория

Прочитай разделы 25–35 и 42–45 в `THEORY.md`.

## Задание 1. Index inventory

До создания новых indexes запроси PostgreSQL catalogs и составь список indexes, уже созданных fixture constraints.

Для каждого укажи:

- table;
- index keys;
- unique/non-unique;
- какой constraint его создал;
- является ли новый похожий index duplicate.

Отдельно докажи, что FK на `retail_sale.customer_id` не создал child-side index автоматически.

## Задание 2. Workload mapping

Сопоставь access method и причину минимум для десяти queries:

1. equality lookup;
2. range по `sold_at`;
3. recent sales с `ORDER BY ... LIMIT`;
4. equality по `supplier.external_ref`;
5. array contains tag;
6. JSONB containment;
7. active moment внутри promotion range;
8. nearest dealerships по point;
9. широкий append-like time range;
10. query, для которого новый index не нужен.

Для каждого запиши нужный operator, не только data type.

## Задание 3. B-tree

Выбери два B-tree candidates:

- equality/range query;
- ordered limited query.

Для каждого:

1. сохранить baseline `EXPLAIN`;
2. создать index с осмысленным name;
3. выполнить `ANALYZE` нужной table;
4. сохранить новый plan;
5. проверить result rows;
6. принять либо отклонить candidate.

## Задание 4. Hash

Создай Hash candidate для equality query по `supplier.external_ref`. Сравни с B-tree alternative:

- equality plan;
- невозможность range/order use;
- index size;
- универсальность;
- итоговое решение.

Не оставляй оба indexes без необходимости.

## Задание 5. GIN

Создай и проверь:

- GIN для `car_model.tags` с operator `@>`;
- отдельный JSONB candidate либо аргументированный отказ для `specs @>`.

Проверь минимум common и rare predicate. Разный plan на них является допустимым результатом.

## Задание 6. GiST

Для `promotion.active_period`:

- query containment фиксированного moment;
- baseline plan;
- GiST index;
- plan after;
- correctness result;
- краткое объяснение range boundary `[)`.

## Задание 7. SP-GiST

Сформулируй point-neighborhood/nearest query для `dealership.location`, проверь доступную SP-GiST operator class в своей PostgreSQL version и создай candidate только если operator/query совместимы.

Если planner не выбирает index на 20 rows, не подделывай доказательство: объясни small-table effect и оставь decision как учебный experiment.

## Задание 8. BRIN

Для `retail_sale.sold_at` сравни:

- B-tree size;
- BRIN size;
- narrow date range;
- wide date range;
- plan и buffers;
- физическую correlation по sequence-like insertion order.

Не требуй от BRIN точечного поведения B-tree.

## Задание 9. Cleanup decision

Итоговый файл должен явно перечислять:

- kept indexes;
- rejected indexes;
- dropped learning-only candidates;
- почему решение может измениться на production distribution.

Удаляй только indexes, созданные в этом дне и указанные exact names. Не удаляй constraint-owned indexes.

## Обязательные сценарии

1. Baseline plans сохранены до indexes.
2. PK/unique indexes не дублируются.
3. Отсутствие automatic child FK index доказано.
4. B-tree проверен на equality/range/order use.
5. Hash не объявлен универсально лучше B-tree.
6. GIN сопоставлен с конкретным containment operator.
7. GiST сопоставлен с range operator.
8. SP-GiST decision учитывает operator class и small table.
9. BRIN сравнивается на correlated append-like column.
10. Узкий и широкий predicates проверены отдельно.
11. Index sizes записаны фактически.
12. Ни один index не оставлен только потому, что его удалось создать.

## Контрольные вопросы дня

1. Почему access method выбирают вместе с operator class?
2. Когда B-tree обычно уместнее Hash?
3. Для каких данных нужны GIN, GiST/SP-GiST и BRIN?
4. Почему Seq Scan после создания index не доказывает ошибку planner?

---

# День 5. Multicolumn, expression, partial и covering indexes

## Паспорт задания

- **Цель:** спроектировать составной индекс под реальный query shape и проверить его пользу без дублирования.
- **Рабочий файл:** `day_05_index_design.sql` и решения/замеры внутри него.
- **Порядок:** выпиши workload; проверь порядок столбцов; затем expression, partial и covering index; проведи аудит FK и избыточности; измерь цену записи/размера; закончи production note.
- **Наблюдаемый результат:** для каждого кандидата есть baseline plan, новый DDL, повторный plan, корректность результата и решение о сохранении.
- **Готово, если:** leading-column правило учтено; выражение запроса совпадает с индексом; partial predicate применим; INCLUDE не перепутан с key; эквивалентные индексы замечены.
- **Пример:** два запроса с разным порядком фильтров оцениваются против одного `(a, b)` индекса с объяснением фактической применимости.
- **Обязательно:** девять заданий и сценарии. **Рекомендация:** хранить число строк и размер таблицы рядом с каждым timing.

## Результат дня

Ты проектируешь indexes под форму query, проверяешь overlap и учитываешь write/storage cost.

## Теория

Прочитай разделы 36–45 в `THEORY.md`.

## Задание 1. Query shapes

Для каждого workload выпиши отдельно:

- equality predicates;
- range predicate;
- join keys;
- `ORDER BY` и direction;
- `LIMIT`;
- returned columns;
- приблизительную долю rows;
- write frequency table.

Workloads:

1. pending Offer queue;
2. recent sales dealership;
3. purchase history customer;
4. available inventory dealership;
5. case-insensitive customer lookup;
6. active promotions at a moment.

## Задание 2. Multicolumn order

Сравни минимум три candidates для recent dealership sales:

- `(dealership_id, sold_at DESC, id DESC)`;
- `(sold_at DESC, dealership_id, id DESC)`;
- отдельные indexes на `dealership_id` и `sold_at`.

Проверь:

- query с equality dealership + time range + order/limit;
- query только по time range;
- другой dealership;
- plan и result stability.

Объясни leading-column effect без правила «самый selective всегда первый».

## Задание 3. Expression index

Проверь query `lower(email) = ...`:

1. baseline;
2. existing plain unique email index;
3. expression candidate;
4. план после;
5. нужен ли unique expression index как business rule;
6. конфликт emails, различающихся только case, в отдельной rollback transaction.

Не меняй допустимые данные случайно: unique candidate требует design decision.

## Задание 4. Partial index

Для небольшой доли pending Offers создай candidate с explicit predicate и проверь:

- matching query;
- query другого status;
- query без `is_active`, если predicate его требует;
- parameterized form на уровне `PREPARE`/`EXPLAIN EXECUTE` обзорно;
- size против full index.

Объясни, почему planner должен доказать implication query predicate → index predicate.

## Задание 5. Covering index

Для available inventory candidate используй `INCLUDE` только после определения output columns. Сравни:

- key columns;
- payload columns;
- index size;
- `Index Scan`/`Index Only Scan`;
- heap fetches, если отображаются;
- update cost при изменении included value.

Не объявляй `INCLUDE` гарантией index-only behavior.

## Задание 6. FK index audit

Для каждой высокой-traffic transaction table недели 6 проверь referencing FKs:

- join/filter workload;
- parent delete/update behavior;
- existing composite prefix;
- candidate либо documented no-index decision.

Минимум: sale → customer, sale → dealership, offer → customer/model, catalog → model.

## Задание 7. Redundancy audit

Найди минимум:

- один exact duplicate либо докажи отсутствие;
- два overlapping candidates;
- constraint-owned index;
- composite index, чей prefix может покрывать отдельный workload;
- index, который нельзя удалять только по одному plan.

## Задание 8. Write/storage price

На одинаковых rollback-able batches сравни insert/update до и после нескольких indexes. Запиши:

- количество rows;
- один и тот же statement;
- несколько runs;
- median либо честный диапазон;
- cache/testing limitations;
- sizes table и indexes.

Не оставляй test rows после опыта.

## Задание 9. Production creation note

Письменно объясни:

- какой blocking создаёт обычный `CREATE INDEX`;
- зачем существует `CONCURRENTLY`;
- почему он не «бесплатный»;
- что проверять после failure;
- почему эта лаборатория не выполняется в production.

## Обязательные сценарии

1. Workload разобран до index DDL.
2. Три column-order candidates сравнены.
3. Query без leading column проверен.
4. Expression query сопоставлен expression index.
5. Unique expression меняет invariant и проверен отдельно.
6. Partial index используется только matching predicate.
7. Другой status не обслуживается partial index как будто он полный.
8. `INCLUDE` columns не считаются search keys.
9. Index-only behavior проверен фактически.
10. FK audit учитывает existing composite prefixes.
11. Redundant indexes не остаются без причины.
12. Write/storage cost измерен на сопоставимом experiment.

## Контрольные вопросы дня

1. Как query shape определяет порядок multicolumn index?
2. Чем expression и partial indexes решают разные задачи?
3. Что даёт `INCLUDE` и чего не гарантирует?
4. Почему удаление overlapping index требует анализа всего workload?

---

# День 6. `EXPLAIN`, planner statistics и N+1

## Паспорт задания

- **Цель:** читать план снизу вверх, находить подтверждённое узкое место и устранять N+1 с проверкой результата.
- **Рабочие файлы:** `day_06_explain.sql`, `day_06_n_plus_one.py` и отчёт, указанный в разделе файлов.
- **Порядок:** разметь vocabulary; собери шесть plan families; рассчитай rows×loops и качество estimates; оптимизируй один запрос; безопасно исследуй modifying statement; затем измерь и устрани N+1 с budget.
- **Наблюдаемый результат:** before/after планы и query counts сопоставимы, результат запроса не изменён, а вывод указывает конкретную дорогую операцию.
- **Готово, если:** cost не называется миллисекундами; actual rows учитывает loops; stale statistics рассматривается; `EXPLAIN ANALYZE` для изменений защищён транзакцией; N+1 подтверждён счётчиком.
- **Пример:** отчёт показывает `1 + N` запросов до исправления и фиксированное число после него для того же результата.
- **Обязательно:** девять заданий и сценарии. **Рекомендация:** менять за один эксперимент только один существенный фактор.

## Результат дня

Ты читаешь plan как дерево фактической работы, проводишь один controlled optimization cycle и измеряешь N+1.

## Теория

Прочитай разделы 46–60 в `THEORY.md`.

## Файлы

- `day_06_explain.sql`;
- `day_06_explain_report.md`;
- `day_06_n_plus_one.py`.

## Задание 1. Plan vocabulary

В report своими словами определи:

- planner и executor;
- startup/total cost;
- estimated/actual rows;
- width;
- loops;
- filters/index conditions;
- buffers;
- planning/execution time.

Отдельно напиши, почему cost не milliseconds.

## Задание 2. Six plan families

Получи фактические `EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)` минимум для:

1. small-table Seq Scan;
2. selective Index Scan;
3. Bitmap Heap/Index Scan либо честное объяснение, почему planner выбрал иной plan;
4. Index Only candidate;
5. multi-table query с join node;
6. aggregate + sort/order query.

Для каждого запиши output correctness и прочитай дерево снизу вверх.

## Задание 3. Rows × loops

Найди plan с node `loops > 1`. Рассчитай приблизительную суммарную row work этого node и объясни relationship с parent Nested Loop.

Не создавай искусственно огромную Cartesian product.

## Задание 4. Estimate quality

Для трёх predicates сравни estimated и actual rows:

- frequent status;
- rare value;
- correlated combination двух columns.

Выполни `ANALYZE` нужной table и сравни снова. Если estimate не изменился заметно, это нормальный фактический result, а не повод менять цифры вручную.

## Задание 5. Controlled optimization

Выбери один медленный/работающий больше необходимого business query:

1. зафиксируй result и baseline;
2. найди главный costly node/estimate mismatch;
3. сформулируй одну гипотезу;
4. примени один index или query rewrite;
5. повтори тот же plan с теми же parameters;
6. проверь одинаковый logical result;
7. измерь write/storage trade-off;
8. оставь либо отклони изменение.

## Задание 6. Safe modifying `EXPLAIN ANALYZE`

В одноразовой learning database:

1. запиши baseline;
2. начни transaction;
3. выполни `EXPLAIN ANALYZE` для точно ограниченного `UPDATE`;
4. проверь изменение внутри transaction;
5. rollback;
6. докажи восстановление baseline.

В report подчеркни, что `ANALYZE` действительно исполняет statement.

## Задание 7. N+1 baseline

В `day_06_n_plus_one.py` стандартным `sqlite3`:

1. создай in-memory connection;
2. загрузи teacher fixture `week_06_sql_design/fixtures/sqlite_dealership.sql`;
3. включи query counter через `set_trace_callback` или прозрачную wrapper function;
4. одним query получи dealerships;
5. внутри цикла отдельным query получи sale summary каждого dealership;
6. выведи result и фактическое число SQL statements после завершения fixture setup;
7. запиши формулу `1 + N`.

Не считай fixture-loading statements частью endpoint query budget.

## Задание 8. N+1 fix

Получить тот же result set-based query:

- сохранить dealerships с zero sales;
- избежать fan-out;
- stable ordering;
- сравнить значения field-by-field;
- показать constant query count относительно N;
- объяснить trade-off большого joined result, если он появляется.

Не используй ORM: его оптимизация будет позже.

## Задание 9. Query budget

В report зафиксируй budgets минимум для:

- dealership sale summary list;
- customer purchase history;
- active catalog;
- supplier comparison;
- Offer processing.

Пока это SQL/application design budget, не Django test.

## Обязательные сценарии

1. Все plans получены на одной версии fixture.
2. Параметры и result counts записаны.
3. Seq Scan не объявлен автоматически плохим.
4. `rows × loops` объяснено.
5. Estimated и actual rows сравнены.
6. `Index Cond` отделён от `Filter`.
7. Buffers прочитаны без двойного суммирования parents/children.
8. `ANALYZE` statistics не перепутан с `EXPLAIN ANALYZE`.
9. Modifying explain полностью rollback.
10. Optimization сохраняет result.
11. N+1 query count измерен.
12. Set-based result совпадает, включая zero-sales dealership.

## Контрольные вопросы дня

1. Чем estimated plan отличается от фактического execution plan?
2. Почему node читается вместе с children и loops?
3. Какие признаки у плохой cardinality estimate?
4. Как доказать устранение N+1?

---

# День 7. Итоговый transaction/performance audit проекта

## Паспорт задания

- **Цель:** подготовить проверяемый аудит транзакций и производительности схемы итогового проекта.
- **Рабочая область:** только каталог `day_07_transaction_performance_audit/` и файлы из структуры ниже.
- **Порядок:** составь transaction map; реализуй purchase и procurement transactions; докажи concurrency; каталогизируй workload; проведи index audit и EXPLAIN report; добавь regression checks; последним оформи README.
- **Наблюдаемый результат:** другой разработчик может развернуть учебную базу, повторить опыты, увидеть корректность инвариантов и сравнить планы before/after.
- **Готово, если:** критические операции атомарны; конкурентный oversell невозможен; индексы имеют evidence; оптимизации сохраняют результаты; cleanup и safety limits документированы.
- **Пример:** один сценарий покупки показывает успешный commit, недостаточный stock, недостаточный balance и конкурентную последнюю единицу.
- **Обязательно:** девять частей, сценарии и финальная защита. **Рекомендация:** вести traceability «инвариант → SQL → проверка → evidence».

## Результат дня

Ты берёшь принятый PostgreSQL-прототип недели 6, определяешь реальные transaction boundaries и добавляешь минимальный доказанный набор indexes для ключевого workload.

## Предусловие

- Дни 1–6 недели 7 приняты.
- PostgreSQL-прототип недели 6 реально запускается.
- Работа выполняется только на копии/отдельной learning database.
- Baseline schema, seed counts и query results зафиксированы.
- Никакой production connection не используется.

## Структура

```text
day_07_transaction_performance_audit/
├── README.md
├── TRANSACTION_MAP.md
├── schema_changes.sql
├── purchase_transaction.sql
├── procurement_transaction.sql
├── concurrency_session_a.sql
├── concurrency_session_b.sql
├── indexes.sql
├── workload_queries.sql
├── regression_checks.sql
└── EXPLAIN_REPORT.md
```

## Часть 1. Transaction map

В `TRANSACTION_MAP.md` опиши минимум три use cases:

1. покупка автомобиля покупателем;
2. закупка автосалоном у поставщика;
3. обработка Offer ровно одним worker.

Для каждого:

- command/idempotency identity;
- data read before transaction;
- rows read/locked inside transaction;
- rows updated/inserted;
- business rejections;
- invariants;
- exact lock order;
- isolation level и причина;
- retryable SQLSTATE;
- maximum retries/backoff;
- post-commit actions;
- reconciliation query.

Lock order должен быть согласован между всеми use cases, которые могут пересекаться.

Все новые supporting objects, необходимые для concurrency-safe implementation, добавь в `schema_changes.sql`: например, command/idempotency record, documented version column или новый constraint. Не прячь DDL внутри transaction demonstration. Каждое изменение должно иметь связь с invariant и безопасный порядок применения к копии схемы недели 6.

## Часть 2. Purchase transaction

В `purchase_transaction.sql` реализуй parameterized design и runnable fixed-seed demonstration, которая атомарно:

1. защищает command от двойной обработки выбранным idempotency mechanism;
2. проверяет active и verified buyer;
3. получает нужный inventory row;
4. проверяет active dealership/model, quantity и agreed price;
5. проверяет достаточный balance;
6. уменьшает stock без ухода ниже нуля;
7. уменьшает balance без ухода ниже нуля;
8. создаёт immutable retail sale с historical price;
9. создаёт stock movement;
10. создаёт balance ledger entry;
11. завершает Offer только при релевантном переходе;
12. проверяет affected row counts;
13. commits только целостный result.

Не держи transaction открытой для пользовательского ввода или email. Не используй hardcoded current price как historical fact без фиксации внутри transaction.

## Часть 3. Procurement transaction

В `procurement_transaction.sql` атомарно:

- выбери supplier offer по зафиксированным deterministic правилам;
- защити supplier stock и dealership balance;
- не допусти negative stock/balance;
- создай procurement history с agreed unit price/discount;
- обнови dealership inventory;
- запиши обе стороны stock/balance movements согласно схеме;
- учти tie-breaker supplier choice;
- зафиксируй единый lock order.

На неделе 7 query выбирает один сценарий; полная Celery automation будет позже.

## Часть 4. Concurrency proof

В двух session files воспроизведи и проверь:

1. две покупки последней единицы без защиты — только в disposable setup;
2. исправленную покупку, где успех ровно один;
3. повтор того же idempotency key;
4. конкурентное списание balance;
5. конкурентную закупку последней supplier unit;
6. два workers с `SKIP LOCKED` для Offer queue;
7. intentional deadlock на test rows;
8. исправление consistent lock order;
9. `NOWAIT` либо bounded timeout path;
10. cleanup/reconciliation.

Никакой blocking step не выполняется без timeout. Порядок `A01/B01/...` должен позволять наставнику повторить опыт.

## Часть 5. Workload catalog

В `workload_queries.sql` сохрани минимум восемь representative queries с fixed parameters и expected result grain:

1. active catalog dealership;
2. pending Offer queue;
3. Offer candidate dealership;
4. effective supplier prices model;
5. recent sales dealership;
6. customer purchase history;
7. dealership statistics date range;
8. active promotions at moment;
9. low stock report — дополнительный;
10. stock/balance reconciliation — дополнительный.

Запросы должны быть корректными до оптимизации.

## Часть 6. Index audit

В `indexes.sql`:

1. перечисли constraint-owned indexes;
2. найди child-side FK gaps;
3. получи baseline plans;
4. создай минимум шесть justified indexes под workload;
5. используй минимум один multicolumn index;
6. используй минимум один partial либо аргументированно отклони;
7. используй expression/GIN/GiST/BRIN только при фактическом workload;
8. найди/reject redundant indexes;
9. измерь index sizes;
10. запиши expected write cost;
11. отдели learning DDL от production deployment plan.

Не существует обязательства использовать все access methods в итоговой schema. Обязателен обоснованный выбор.

## Часть 7. EXPLAIN report

Для минимум шести workload queries в `EXPLAIN_REPORT.md` сохрани before/after:

- PostgreSQL version;
- data row counts;
- parameters;
- logical result verification;
- plan tree summary;
- estimated/actual rows;
- loops;
- scan/join/sort/aggregate nodes;
- buffers;
- planning/execution time с оговорками;
- index size/write trade-off;
- keep/reject decision.

Не требуются одинаковые numeric times на другой machine. Требуется воспроизводимый method и честный analysis.

## Часть 8. Regression checks

`regression_checks.sql` должен проверять:

- negative balance/stock отсутствуют;
- sales согласованы с stock/balance histories в рамках выбранного source of truth;
- повтор command key не создал duplicate operation;
- ровно один winner в last-unit concurrency case;
- Offer state transition допустим;
- business query results не изменились после indexes;
- duplicate/redundant indexes выявлены диагностически;
- invalid indexes отсутствуют;
- открытые long transactions после лаборатории отсутствуют либо query это документирует без вмешательства;
- fixture/test rows очищены.

Diagnostics должны быть read-only. Expected-failure DML оставляется закомментированным либо запускается отдельно внутри rollback.

## Часть 9. README

Опиши:

- точную безопасную среду;
- prerequisite недели 6;
- порядок запуска;
- как открыть две sessions;
- где ожидается waiting/error;
- timeout и cleanup steps;
- transaction boundaries;
- retry contract;
- workload и index decisions;
- limitations экспериментов;
- topics, deferred to week 8/Django/Celery.

Credentials не добавляются.

## Обязательные сценарии итогового проекта

1. Работа запускается только в подтверждённой learning database.
2. Baseline schema/seed недели 6 проходит проверки до изменений.
3. Purchase rollback не оставляет частичных changes.
4. Successful purchase одновременно меняет stock, balance и histories.
5. Inactive/unverified buyer получает business rejection.
6. Insufficient balance ничего не изменяет.
7. Zero stock ничего не изменяет.
8. Exact balance и последняя единица допускают одну покупку.
9. Две concurrent покупки последней единицы дают ровно один success.
10. Stock никогда не становится отрицательным.
11. Balance никогда не становится отрицательным.
12. Повтор idempotency key не создаёт вторую sale.
13. Historical price не меняется вслед за current catalog.
14. Procurement либо фиксируется целиком, либо целиком rollback.
15. Две concurrent procurements не забирают одну supplier unit дважды.
16. Единый lock order документирован и соблюдён.
17. Intentional deadlock наблюдался только на test rows с timeout.
18. Исправленный order не создаёт deadlock.
19. Retry contract ограничен `40001`/`40P01` и повторяет всю transaction.
20. Два queue workers через `SKIP LOCKED` получают разные items.
21. `SKIP LOCKED` не используется для reconciliation/reporting.
22. Восемь workload queries имеют зафиксированный grain/result.
23. Constraint-owned indexes не дублируются.
24. Child-side FK indexes имеют workload-based решения.
25. Минимум шесть index decisions имеют before/after evidence.
26. Narrow и broad predicates не объявлены одним workload.
27. Шесть actual plans объяснены с rows/loops/buffers.
28. `EXPLAIN ANALYZE` side effects безопасно rollback.
29. N+1 query count измерен и reduced result совпадает.
30. Финальные diagnostics не находят необъяснимых нарушений и открытых test transactions.

## Финальное объяснение без подсказки

Будь готов объяснить:

1. три transaction boundaries;
2. actual isolation behavior PostgreSQL;
3. один lost update и его исправление;
4. lock order и deadlock;
5. retryable vs business errors;
6. шесть index decisions и их цену;
7. один rejected index;
8. один plan снизу вверх;
9. estimate mismatch;
10. N+1 measurement и fix.

## Критерий итогового зачёта

- минимум 8/10;
- все 30 сценариев проверены;
- transaction map, SQL, workload и indexes согласованы;
- нет критических ошибок из `README.md`;
- планы и concurrency results фактические, не предполагаемые;
- ученик самостоятельно объясняет и исправляет решения;
- допуск к неделе 8 выставляет наставник.

---

# После каждого ревью

1. Наставник фиксирует первую оценку и причины ошибок в `ASSESSMENT.md`.
2. Ученик сам исправляет обязательные пункты.
3. Повторяются все ранее принятые regression/concurrency scenarios.
4. Следующий день открывается при итоговой оценке минимум 7/10.
5. Неделя 8 остаётся заблокированной до полного зачёта недели 7.
