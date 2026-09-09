# Теория недели 7: транзакции, конкурентный доступ и производительность

Материал рассчитан на ученика, который уже завершил SQL-модуль недели 6, но ещё не работал с concurrency и query planner. Примеры предназначены только для отдельной учебной PostgreSQL database.

## 1. Почему корректный одиночный запрос может ломаться при concurrency

Concurrency — одновременное или перекрывающееся выполнение нескольких операций.

Допустим, на складе осталась одна Camry. Два покупателя почти одновременно:

1. читают `quantity = 1`;
2. оба решают, что товар доступен;
3. оба создают sale;
4. оба уменьшают остаток.

Каждый code path по отдельности кажется правильным. Вместе они могут:

- продать одну машину дважды;
- потерять одно изменение;
- списать деньги, но не уменьшить stock;
- оставить половину financial history;
- нарушить правило, которое невозможно проверить одним row-level constraint.

Значит, кроме корректных таблиц и запросов нужны:

- transaction boundary;
- isolation guarantees;
- атомарные изменения;
- locks там, где они действительно нужны;
- retry policy для ожидаемых конфликтов.

## 2. Transaction boundary

Transaction — группа SQL statements, которая фиксируется как одно целое или полностью отменяется.

Граница транзакции отвечает на вопрос:

> Какие изменения должны стать видимыми вместе, чтобы business invariant всегда оставался истинным?

Для покупки автомобиля это обычно не весь HTTP request и не один `UPDATE`, а согласованный набор:

1. проверить buyer eligibility;
2. проверить и защитить нужный inventory row;
3. проверить balance;
4. создать sale;
5. уменьшить stock;
6. уменьшить balance;
7. добавить stock/balance history;
8. изменить Offer status, если покупка появилась из Offer.

Отправка email или ожидание ответа внешнего API обычно не должны удерживать database transaction открытой.

## 3. Autocommit и явная transaction

PostgreSQL выполняет каждый отдельный statement внутри transaction, даже без явного `BEGIN`. Client library часто предоставляет autocommit behavior: один успешный statement фиксируется отдельно.

```sql
UPDATE customer
SET balance = balance - 30000
WHERE id = 10;

UPDATE dealership_inventory
SET quantity = quantity - 1
WHERE dealership_id = 2 AND car_model_id = 7;
```

Если это два независимых commits, ошибка между ними оставит половинчатое состояние.

Явная группа:

```sql
BEGIN;

UPDATE customer
SET balance = balance - 30000
WHERE id = 10;

UPDATE dealership_inventory
SET quantity = quantity - 1
WHERE dealership_id = 2 AND car_model_id = 7;

COMMIT;
```

Теперь приложение должно либо подтвердить всю операцию, либо выполнить `ROLLBACK`.

## 4. ACID без магии

### Atomicity

Все изменения transaction применяются вместе или не применяются вовсе.

### Consistency

После корректной transaction database остаётся в допустимом состоянии. Это не означает, что PostgreSQL угадает все business rules. Consistency создают вместе:

- constraints;
- корректная transaction logic;
- правильные locks/isolation;
- проверки приложения.

### Isolation

Concurrent transactions не должны создавать результат, запрещённый выбранным isolation level. Isolation не означает, что каждая transaction всегда полностью невидима другим до конца во всех режимах; точные гарантии зависят от уровня.

### Durability

После успешного commit подтверждённые изменения должны пережить сбой согласно гарантиям настроенной СУБД. Подробности WAL и crash recovery относятся к неделе 8.

## 5. `BEGIN`, `COMMIT`, `ROLLBACK`

```sql
BEGIN;

UPDATE week7_lab.customer
SET balance = balance - 1000
WHERE id = 1;

-- Проверка до решения.
SELECT balance
FROM week7_lab.customer
WHERE id = 1;

ROLLBACK;
```

После `ROLLBACK` изменение исчезает. После `COMMIT` оно становится durable result transaction.

Важно: `COMMIT` — не обязательная последняя строка любого опыта. В лаборатории изменение часто намеренно откатывается, чтобы fixture оставалась известной.

## 6. Ошибка переводит transaction в aborted state

Если statement внутри PostgreSQL transaction завершился ошибкой, нельзя просто выполнить следующий обычный statement:

```sql
BEGIN;

UPDATE week7_lab.dealership_inventory
SET quantity = -1
WHERE dealership_id = 1 AND car_model_id = 1;

-- Transaction уже aborted.
SELECT 1;

ROLLBACK;
```

До `ROLLBACK` либо `ROLLBACK TO SAVEPOINT` PostgreSQL будет отклонять дальнейшие команды этой transaction. Ошибку нельзя «проигнорировать» и затем сделать `COMMIT` ожидая частичный успех.

## 7. Savepoint

Savepoint — точка частичного отката внутри transaction.

```sql
BEGIN;

UPDATE week7_lab.customer
SET balance = balance - 500
WHERE id = 1;

SAVEPOINT optional_step;

-- Дополнительный шаг оказался ненужным.
UPDATE week7_lab.customer_offer
SET status = 'completed'
WHERE id = 999999;

ROLLBACK TO SAVEPOINT optional_step;

COMMIT;
```

`ROLLBACK TO` отменяет изменения после savepoint, но не завершает внешнюю transaction. Savepoint полезен для локального восстановления, однако не должен скрывать нарушение основного invariant.

## 8. Transaction должна быть короткой

Открытая transaction удерживает resources и может:

- дольше держать locks;
- блокировать другие operations;
- увеличивать вероятность deadlock;
- мешать обслуживанию старых row versions;
- оставить session в состоянии `idle in transaction`.

Плохая граница:

```text
BEGIN
lock inventory
ждать пользовательского подтверждения оплаты 40 секунд
вызвать внешний API
COMMIT
```

Лучше подготовить внешние данные до transaction, а внутри оставить только быстрые database reads/writes, необходимые для атомарности.

## 9. Anomaly vocabulary

### Dirty read

Transaction читает изменение другой transaction, которая ещё не committed и может rollback.

### Non-repeatable read

Один и тот же row читается повторно, но между чтениями другая transaction committed update, поэтому значение изменилось.

### Phantom read

Повторный predicate query возвращает другое множество rows из-за committed insert/delete другой transaction.

### Lost update

Две операции читают старое значение, независимо рассчитывают новое, а поздняя запись затирает эффект ранней.

### Serialization anomaly

Concurrent result нельзя объяснить никаким последовательным порядком выполнения тех же transactions.

Не все аномалии из стандартной таблицы одинаково воспроизводятся в PostgreSQL: нужно изучать фактическую реализацию PostgreSQL.

## 10. Уровни isolation в PostgreSQL

| Requested level | Dirty read | Non-repeatable read | Phantom read | Serialization anomaly |
|---|---|---|---|---|
| Read Uncommitted | не допускается в PostgreSQL | возможно | возможно | возможно |
| Read Committed | не допускается | возможно | возможно | возможно |
| Repeatable Read | не допускается | не допускается | не допускается в PostgreSQL | возможно |
| Serializable | не допускается | не допускается | не допускается | не допускается у успешно committed transactions |

PostgreSQL реализует `READ UNCOMMITTED` как `READ COMMITTED`. Кроме того, PostgreSQL `REPEATABLE READ` сильнее минимального стандарта и не допускает phantom reads.

Уровень задаётся в начале transaction:

```sql
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```

Нельзя выбирать уровень по принципу «самый строгий всегда лучше»: более сильная гарантия может приводить к ожидаемым abort/retry и дополнительным накладным расходам.

## 11. `READ COMMITTED`

Это default isolation level PostgreSQL.

Каждый обычный `SELECT` видит snapshot committed data на начало именно этого statement. Поэтому два `SELECT` внутри одной transaction могут увидеть разные committed состояния.

```text
Session A: BEGIN
Session A: SELECT quantity -> 1
Session B: UPDATE quantity -> 0; COMMIT
Session A: SELECT quantity -> 0
```

Dirty read не происходит: до commit Session B её изменение Session A не увидит.

`READ COMMITTED` удобен для многих коротких операций, но несколько отдельных read-then-write steps требуют аккуратной атомарной формулировки или locking.

## 12. `REPEATABLE READ`

Transaction видит стабильный snapshot относительно начала первой значимой команды. Последующие reads не начинают видеть commits других transactions.

Если concurrent transaction изменила row, который текущая `REPEATABLE READ` transaction позже пытается изменить или lock, возможен abort:

```text
ERROR: could not serialize access due to concurrent update
```

Application должна отменить и повторить всю transaction с новыми данными. Нельзя продолжить со старыми вычислениями.

Стабильный snapshot ещё не гарантирует отсутствие всех serialization anomalies. Для максимальной гарантии существует `SERIALIZABLE`.

## 13. `SERIALIZABLE`

Успешно committed concurrent transactions дают эффект, совместимый с некоторым последовательным порядком. PostgreSQL может прервать одну transaction с SQLSTATE `40001`, если обнаружит опасную dependency.

Пример write skew: два officers оба видят, что на дежурстве находятся двое, и каждый в своей transaction снимает с дежурства самого себя. Они меняют разные rows, поэтому простой row lock conflict может не возникнуть. В `REPEATABLE READ` обе transactions способны commit и нарушить cross-row правило «минимум один на дежурстве». В `SERIALIZABLE` PostgreSQL должен abort одну из несовместимых transactions, чтобы успешно committed result соответствовал последовательному выполнению.

Отсюда контракт:

- успех означает сильную гарантию;
- конфликт не является загадочным database failure;
- application обязана уметь повторить transaction целиком;
- повтор должен быть bounded и безопасным;
- значения, прочитанные aborted transaction, нельзя использовать как окончательный результат.

## 14. Sequence не откатывается как обычная row

Значения PostgreSQL sequence, используемые в том числе `serial`, сразу видимы другим transactions и не возвращаются назад при rollback. Поэтому gaps в surrogate identifiers нормальны.

Нельзя использовать непрерывность `id` как business invariant, количество записей или доказательство отсутствия удалений.

## 15. Lost update: read-modify-write

Опасный application pattern:

```text
прочитать quantity = 5
в Python вычислить new_quantity = 4
UPDATE ... SET quantity = 4
```

Две sessions могут обе прочитать `5` и обе записать `4`. Было две продажи, а уменьшение сохранилось только одно.

### Вариант 1: atomic update

```sql
UPDATE week7_lab.dealership_inventory
SET quantity = quantity - 1
WHERE dealership_id = 1
  AND car_model_id = 1
  AND quantity >= 1
RETURNING quantity;
```

Изменение вычисляется относительно row version, с которой работает PostgreSQL. Проверка `quantity >= 1` и `RETURNING` превращают update в конкурентно безопасную попытку для простого invariant.

`0 rows returned` здесь является business result: товар уже недоступен.

### Вариант 2: pessimistic row lock

Если между чтением и изменением нужна сложная логика:

```sql
BEGIN;

SELECT quantity, sale_price
FROM week7_lab.dealership_inventory
WHERE dealership_id = 1 AND car_model_id = 1
FOR UPDATE;

-- Короткие проверки и связанные изменения.

COMMIT;
```

### Вариант 3: optimistic version check

Row хранит `version`. Update выполняется только если version не изменилась:

```sql
UPDATE some_table
SET value = :new_value,
    version = version + 1
WHERE id = :id
  AND version = :expected_version;
```

Ноль изменённых rows означает conflict. Это полезная модель, но выбор между подходами зависит от use case.

## 16. Conditional DML как invariant guard

Многие проверки лучше объединить с изменением:

```sql
UPDATE week7_lab.customer
SET balance = balance - 30000
WHERE id = 1
  AND is_active
  AND email_verified
  AND balance >= 30000
RETURNING id, balance;
```

Это уменьшает окно между check и write. Но если одна business operation меняет несколько rows/tables, всё равно нужна общая transaction boundary.

## 17. Row-level locks

Основные locking clauses:

- `FOR UPDATE` — сильная row lock для планируемого update/delete;
- `FOR NO KEY UPDATE` — слабее, когда key columns не меняются;
- `FOR SHARE` — shared protection от более сильных changes;
- `FOR KEY SHARE` — защищает referenced key от delete/key change, позволяя некоторые другие updates.

На первой практике главный рабочий инструмент — `FOR UPDATE`. Более слабый mode выбирается только когда ученик может объяснить conflict matrix.

Обычный `SELECT` без locking clause не блокирует обычный concurrent update выбранных rows.

## 18. `NOWAIT` и `SKIP LOCKED`

```sql
SELECT id
FROM week7_lab.work_item
WHERE status = 'pending'
ORDER BY priority DESC, id
FOR UPDATE SKIP LOCKED
LIMIT 1;
```

`NOWAIT` немедленно возвращает lock error вместо ожидания.

`SKIP LOCKED` пропускает уже locked rows. Это полезно нескольким workers, забирающим независимые queue items. Но результат представляет неполную, inconsistent view и не подходит для обычного отчёта, reconciliation или выбора «всех подходящих» предложений.

## 19. Table locks

SQL statements автоматически берут подходящие table-level locks. Явный `LOCK TABLE` нужен значительно реже row locks.

Название некоторых table-lock modes содержит слово `ROW`, но это всё равно table-level mode. Не нужно заучивать всю conflict matrix в первую неделю. Нужно понимать:

- DDL часто конфликтует сильнее DML;
- `TRUNCATE` требует `ACCESS EXCLUSIVE`;
- широкий table lock снижает concurrency;
- точный row lock обычно лучше соответствует покупке одной позиции.

## 20. Blocking, timeout и диагностика

Если нужная row locked другой transaction, statement обычно ждёт. В лаборатории ожидание должно быть ограничено:

```sql
BEGIN;
SET LOCAL lock_timeout = '2s';
SET LOCAL statement_timeout = '5s';
```

`SET LOCAL` действует до завершения transaction. Timeout нужен для безопасного опыта, но не исправляет неправильную lock strategy.

Текущие locks можно исследовать через `pg_locks`, а sessions — через `pg_stat_activity`. Для начала достаточно различать:

- кто ждёт;
- кто держит transaction открытой;
- какой target row/resource участвует;
- чем завершится каждая session.

## 21. Deadlock

Deadlock — цикл ожиданий:

```text
Session A держит customer 1 и ждёт customer 2
Session B держит customer 2 и ждёт customer 1
```

PostgreSQL обнаружит deadlock и abort одну transaction. Нельзя рассчитывать, какая именно будет выбрана.

Основная профилактика — одинаковый порядок блокировок во всех code paths:

```text
сначала rows по table priority,
внутри одной table — по id ascending
```

Для набора identifiers порядок должен быть явным и стабильным. Transaction остаётся короткой, а SQLSTATE `40P01` обрабатывается bounded whole-transaction retry.

## 22. Retry — часть transaction contract

Retry допустим для transient conflicts, например:

- serialization failure `40001`;
- deadlock detected `40P01`;
- иногда согласованный lock timeout, если use case это допускает.

Retry не нужен для:

- недостатка balance;
- отсутствия stock;
- нарушенного unique/check constraint из-за неверных данных;
- syntax error;
- неверной authorization.

Правила:

1. rollback failed transaction;
2. повторить всю business transaction, включая reads;
3. ограничить число попыток;
4. добавить небольшую задержку/backoff при необходимости;
5. логировать attempt и SQLSTATE;
6. обеспечить idempotency внешнего command;
7. после лимита вернуть контролируемую ошибку.

SQL сам не описывает application retry loop; на этой неделе ученик фиксирует точный contract псевдокодом, а Python/Django реализация появится позже.

## 23. Constraints продолжают защищать concurrency

Locks не заменяют constraints. Например, два concurrent inserts могут одновременно не увидеть строку, но unique constraint всё равно не даст создать два одинаковых business keys.

Правильные уровни защиты дополняют друг друга:

- `CHECK` защищает локальное значение row;
- `UNIQUE` защищает uniqueness при concurrency;
- FK защищает relation;
- conditional DML защищает простой state transition;
- transaction связывает несколько changes;
- isolation/locks управляют взаимодействием transactions;
- application определяет permissions и сложный workflow.

Паттерн «сначала `SELECT`, убедиться что нет, затем `INSERT`» без unique constraint имеет race condition.

## 24. Transaction map проекта

До написания SQL для каждого use case заполняется карта:

| Вопрос | Пример покупки |
|---|---|
| Command identity | `purchase_request_id` |
| Какие rows читаем | buyer, inventory, optional offer |
| Какие rows меняем | balance, inventory, offer |
| Что создаём | sale, balance entry, stock movement |
| Главные invariants | один command один раз; stock/balance неотрицательны |
| Lock order | buyer → inventory → offer либо другой единый documented order |
| Business rejection | inactive buyer, unverified email, no stock, insufficient balance |
| Retryable conflicts | `40001`, `40P01` |
| Reconciliation | current state согласуется с transaction history |

Порядок выбирается один для всего приложения. Нельзя локально придумать противоположный порядок для закупки, если resources пересекаются.

## 25. Что такое index

Index — отдельная структура данных, помогающая PostgreSQL быстрее находить или упорядочивать подходящие rows для поддерживаемых operators.

Index не меняет логический результат корректного query. Он даёт planner дополнительный access path.

Без подходящего index поиск может читать большую часть table. С index PostgreSQL может найти небольшой subset быстрее. Но planner имеет право выбрать sequential scan, если он оценивает его дешевле.

## 26. Цена index

Index не бывает бесплатным:

- занимает disk space;
- изменяется при `INSERT`;
- может изменяться при `UPDATE` indexed columns;
- очищается/обслуживается вместе с table;
- увеличивает WAL и write amplification;
- усложняет planner choice и schema maintenance;
- создание index на большой live table влияет на workload.

Поэтому правило «индексировать каждый column» неверно. Index создаётся под важный query pattern и проверяется планом/измерением.

## 27. Selectivity и cardinality

Cardinality здесь — ожидаемое количество rows на этапе плана. Selectivity — доля table, проходящая predicate.

```text
100 000 sales, query возвращает 3 rows → высокая selectivity условия
100 000 sales, query возвращает 80 000 rows → низкая избирательность условия
```

Index особенно полезен, когда нужно получить небольшую часть большой table. Для очень частого значения sequential scan может оказаться рациональнее.

Нельзя оценивать пользу index только по типу column. Нужны:

- query predicates;
- join conditions;
- ordering;
- data distribution;
- table size;
- read/write frequency;
- требуемые output columns.

## 28. B-tree

B-tree — default и главный general-purpose index PostgreSQL. Обычно подходит для:

- equality: `=`;
- ranges: `<`, `<=`, `>`, `>=`, `BETWEEN`;
- `IN`;
- `IS NULL`/`IS NOT NULL`;
- ordered retrieval;
- prefix-compatible `ORDER BY`;
- pattern search с подходящими operator classes и anchored prefix, но детали locale/operator class нужно проверять отдельно.

```sql
CREATE INDEX retail_sale_dealership_sold_at_idx
ON week7_lab.retail_sale (dealership_id, sold_at DESC);
```

Это кандидат для recent sales конкретного dealership, но не доказательство ускорения любого query по `sold_at`.

## 29. Hash index

Hash index поддерживает equality comparisons. Он не помогает ranges или sorting.

```sql
CREATE INDEX supplier_external_ref_hash_idx
ON week7_lab.supplier USING hash (external_ref);
```

На практике B-tree тоже поддерживает equality и часто остаётся более универсальным. Выбор Hash должен иметь конкретное измеримое основание, а не делаться только потому, что query содержит `=`.

## 30. GIN

GIN — inverted index для composite values, где один row содержит несколько searchable elements. Типичные случаи:

- arrays;
- `jsonb` containment/existence;
- full-text `tsvector`.

```sql
CREATE INDEX car_model_tags_gin_idx
ON week7_lab.car_model USING gin (tags);

SELECT id, model_name
FROM week7_lab.car_model
WHERE tags @> ARRAY['suv'];
```

Нужно сопоставлять index с operator/operator class. GIN часто ускоряет чтение по содержимому, но может быть тяжелее для writes.

## 31. GiST

GiST — framework для разных tree-like strategies и operator classes. Он применяется, например, для:

- ranges и overlap;
- geometry;
- nearest-neighbor задач при подходящей operator class;
- exclusion constraints.

```sql
CREATE INDEX promotion_active_period_gist_idx
ON week7_lab.promotion USING gist (active_period);

SELECT id
FROM week7_lab.promotion
WHERE active_period @> TIMESTAMPTZ '2026-06-01 12:00:00+00';
```

Фраза «GiST — индекс для географии» слишком узкая. Реальное поведение определяется operator class.

## 32. SP-GiST

SP-GiST поддерживает space-partitioned структуры для данных, естественно разбиваемых на непересекающиеся regions: например, points, некоторые text/inet use cases при доступной operator class.

В лаборатории достаточно:

- сопоставить подходящий point query;
- создать SP-GiST candidate;
- убедиться через `EXPLAIN`, рассматривается ли он planner;
- не объявлять его автоматически лучше GiST.

Выбор между GiST и SP-GiST делается по data/operator/workload и измерению.

## 33. BRIN

BRIN хранит compact summaries для ranges физических table blocks. Он особенно полезен для очень больших tables, где значение коррелирует с physical order, например append-like events по времени.

```sql
CREATE INDEX retail_sale_sold_at_brin_idx
ON week7_lab.retail_sale USING brin (sold_at);
```

BRIN обычно намного меньше B-tree, но даёт более грубый поиск и может читать лишние blocks. На маленькой или хаотично упорядоченной table преимущество может отсутствовать.

## 34. Operator class — скрытая часть решения

Index access method сам по себе недостаточен. Operator class определяет, какие operators и порядок значений поддерживаются.

Вопрос нужно задавать так:

> Может ли этот конкретный index с этой operator class обслужить operator моего query?

Поэтому одинаковый data type может иметь разные index strategies, а похожие на вид predicates — разные планы.

На неделе 7 не требуется заучивать каталог operator classes. Требуется уметь проверить официальную документацию и фактический plan.

## 35. Какие indexes уже созданы constraints

PostgreSQL автоматически создаёт unique B-tree index для:

- `PRIMARY KEY`;
- `UNIQUE` constraint.

Поэтому это обычно дублирование:

```sql
CREATE TABLE example (
    id bigint PRIMARY KEY
);

CREATE INDEX example_id_idx ON example (id);
```

Foreign key устроен иначе:

- referenced columns обязаны быть unique/primary и уже имеют подходящую protection/index;
- index на referencing columns автоматически не создаётся;
- его часто полезно добавить для joins и проверки parent delete/update, но решение зависит от workload.

Нельзя механически индексировать каждый FK, однако отсутствие automatic index нужно помнить.

## 36. Multicolumn B-tree и leftmost columns

```sql
CREATE INDEX customer_offer_status_created_idx
ON week7_lab.customer_offer (status, created_at, id);
```

Наиболее эффективно B-tree ограничивается equality conditions на leading columns, затем inequality на первом column без equality.

Index `(status, created_at)` естественно соответствует:

```sql
WHERE status = 'pending'
  AND created_at >= :from_time
ORDER BY created_at, id
```

Query только по `created_at` может не использовать этот index эффективно, потому что leading `status` отсутствует.

Порядок columns выбирается не лозунгом «самый selective первый», а на основании реальных equality/range/order patterns.

## 37. Index order и sorting

B-tree может отдавать rows в index order и иногда убрать отдельный `Sort`.

```sql
CREATE INDEX retail_sale_dealership_recent_idx
ON week7_lab.retail_sale (dealership_id, sold_at DESC, id DESC);
```

Query должен иметь compatible predicate/order:

```sql
WHERE dealership_id = :dealership_id
ORDER BY sold_at DESC, id DESC
LIMIT 20
```

`id` добавлен как deterministic tie-breaker. Но каждый дополнительный key увеличивает index; решение проверяется.

## 38. Expression index

Если query фильтрует по expression, обычный index на raw column может не соответствовать expression:

```sql
SELECT id
FROM week7_lab.customer
WHERE lower(email) = lower(:email);
```

Candidate:

```sql
CREATE INDEX customer_lower_email_idx
ON week7_lab.customer (lower(email));
```

Expression в query должно семантически соответствовать indexed expression. Такой index увеличивает стоимость insert/update, потому что expression нужно вычислять и хранить.

Если case-insensitive uniqueness — business rule, можно рассмотреть unique expression index. Но это уже не просто ускорение: он меняет допустимые данные.

## 39. Partial index

Partial index содержит только rows, удовлетворяющие predicate:

```sql
CREATE INDEX customer_offer_pending_created_idx
ON week7_lab.customer_offer (created_at, id)
WHERE status = 'pending' AND is_active;
```

Он может быть меньше и дешевле полного index, если важен небольшой stable subset.

Planner должен суметь доказать, что query predicate подразумевает index predicate. Semantically похожая, но иначе сформулированная или параметризованная проверка не всегда подходит.

Partial index не является заменой partitioning и не должен создавать тысячи mutually exclusive indexes.

## 40. Covering index и `INCLUDE`

Non-key columns можно хранить как payload:

```sql
CREATE INDEX inventory_catalog_cover_idx
ON week7_lab.dealership_inventory (dealership_id, car_model_id)
INCLUDE (quantity, sale_price);
```

Это может позволить index-only scan, если:

- query использует поддерживаемый index type;
- все нужные columns доступны из index;
- visibility conditions позволяют избежать heap visit.

`INCLUDE` columns не участвуют в search ordering/uniqueness как key columns. Они увеличивают index size и write cost. `Index Only Scan` не гарантируется одним наличием `INCLUDE`; detailed visibility map будет на неделе 8.

## 41. Unique index и business rule

Unique index — не только performance object, но и concurrency-safe data invariant.

```sql
CREATE UNIQUE INDEX customer_email_ci_uq
ON week7_lab.customer (lower(email));
```

Partial unique index может выразить правило для subset, например «одна незавершённая operation определённого типа на command key». Но predicate и null semantics нужно документировать и тестировать concurrent inserts.

Если правило легко выражается обычным `UNIQUE` constraint, constraint обычно яснее показывает intent.

## 42. Redundant и overlapping indexes

Подозрительные пары:

- PK `(id)` и дополнительный `(id)`;
- unique `(email)` и обычный `(email)`;
- `(dealership_id)` рядом с `(dealership_id, sold_at)` без workload, которому действительно нужен короткий index;
- два одинаковых indexes с разными names;
- полный и partial index, где полный никогда не нужен.

Один composite index не всегда полностью заменяет короткий, но решение требует plan/use evidence. Перед удалением index в production нужны usage statistics и безопасный процесс; в учебной базе мы только анализируем.

## 43. Почему function на column может ломать index path

Candidate index должен соответствовать predicate. Например:

```sql
WHERE DATE(sold_at) = DATE '2026-06-01'
```

Обычный index на `sold_at` может не использоваться как ожидается. Range часто лучше:

```sql
WHERE sold_at >= TIMESTAMPTZ '2026-06-01 00:00:00+00'
  AND sold_at <  TIMESTAMPTZ '2026-06-02 00:00:00+00'
```

Альтернатива — expression index, если именно expression является стабильным важным workload. Сначала корректность timezone boundary, затем performance.

## 44. Index и write cost experiment

Сравнение должно быть аккуратным:

1. одинаковая schema и data volume;
2. фиксированный workload;
3. baseline plan;
4. candidate index;
5. `ANALYZE` при необходимости;
6. повторный plan;
7. index size;
8. влияние на insert/update измеряется несколькими runs, а не одной случайной цифрой;
9. вывод содержит ограничения эксперимента.

Наличие более низкого execution time в одном warmed-cache запуске не доказывает общий выигрыш.

## 45. Создание index на live system

Обычный `CREATE INDEX` позволяет reads, но блокирует writes на table на время build. `CREATE INDEX CONCURRENTLY` снижает write blocking, однако имеет отдельные ограничения, выполняет больше работы и при failure может оставить invalid index.

На неделе 7:

- изучаем разницу теоретически;
- не тренируемся на production;
- не обещаем zero impact;
- записываем rollback/monitoring plan;
- в одноразовой учебной базе используем обычный `CREATE INDEX` для воспроизводимости.

## 46. Planner и executor

Planner сравнивает допустимые способы выполнить query и выбирает plan с наименьшей оценённой cost. Executor выполняет выбранный plan.

Planner использует:

- query structure;
- доступные indexes и operators;
- table/index size estimates;
- statistics о distribution;
- cost model;
- configuration;
- parameter values или generic assumptions.

Следовательно, «index существует» не означает «index должен быть использован».

## 47. `EXPLAIN`

```sql
EXPLAIN
SELECT *
FROM week7_lab.customer_offer
WHERE status = 'pending';
```

Обычный `EXPLAIN` строит план, но не выполняет query. Он показывает estimates:

- startup cost;
- total cost;
- estimated rows;
- estimated average row width;
- plan nodes и conditions.

Cost — внутренняя безразмерная оценка planner, а не milliseconds. Сравнивать cost полезно внутри сопоставимых вариантов на одной system, но это не фактическое время.

## 48. `EXPLAIN ANALYZE`

```sql
EXPLAIN (ANALYZE, BUFFERS, TIMING OFF)
SELECT ...;
```

`ANALYZE` действительно выполняет statement и добавляет:

- actual time, если timing включён;
- actual rows;
- loops;
- planning/execution summary;
- buffer information при `BUFFERS`.

Критически важно: side effects modifying statement тоже произойдут. Безопасный учебный pattern:

```sql
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE week7_lab.customer
SET balance = balance + 1
WHERE id = 1;

ROLLBACK;
```

Перед `EXPLAIN ANALYZE` нужно отдельно доказать, что target — одноразовая учебная database и rollback действительно охватывает statement.

## 49. Читать plan снизу вверх

Plan представляет дерево. Child nodes создают rows для parent node.

Практический порядок:

1. найти deepest scans;
2. посмотреть `Index Cond` и `Filter`;
3. сравнить rows removed by filter;
4. подняться к joins/aggregates/sorts;
5. учесть `loops`;
6. сравнить estimated и actual rows;
7. посмотреть buffers и disk/temp indicators;
8. проверить final output cardinality.

Нельзя читать только первую строку плана.

## 50. `rows` и `loops`

В `EXPLAIN ANALYZE` actual rows обычно указаны на один loop. Для понимания выполненной работы нужно учитывать:

```text
actual rows × loops
```

Inner node nested loop может возвращать мало rows, но выполняться тысячи раз. Это частый источник неожиданной стоимости.

Большая разница estimated vs actual rows может заставить planner выбрать неподходящий join/scan или неправильно оценить sort/hash size.

## 51. Scan nodes

### Sequential Scan

Читает table pages последовательно и проверяет rows. Это не автоматически плохо. Seq Scan разумен для маленькой table или query, возвращающего большую долю rows.

### Index Scan

Ищет references в index и получает нужные table rows. Полезен для небольшого subset, но random heap access может быть дорогим.

### Bitmap Index Scan + Bitmap Heap Scan

Сначала собирает locations подходящих rows, затем читает heap pages более сгруппированно. Часто полезен для средней доли table или сочетания нескольких indexes.

### Index Only Scan

Пытается получить output из index без обычного heap fetch для каждой row. Возможность зависит не только от listed columns, но и от visibility information.

Ни один node name сам по себе не является оценкой «хорошо/плохо».

## 52. Join nodes

### Nested Loop

Для каждой row outer input ищет matching rows inner input. Хорош для маленького outer set и быстрого indexed lookup. Опасен, когда inner work повторяется слишком много раз.

### Hash Join

Строит hash table для одного input и ищет matches из другого. Часто подходит большим equality joins. Требует memory; spill details изучаются по plan.

### Merge Join

Сопоставляет два ordered inputs. Может быть выгоден, когда они уже ordered или сортировка оправдана.

Planner выбирает algorithm по estimates. Заставлять конкретный join через отключение planner nodes — диагностический эксперимент, а не production fix.

## 53. Sort, aggregate и temporary work

Plan может содержать:

- `Sort`;
- `Incremental Sort`;
- `Aggregate`/`GroupAggregate`/`HashAggregate`;
- `Materialize`;
- parallel nodes;
- temp read/write при spill.

На неделе 7 нужно уметь ответить:

- почему sorting понадобилась;
- сколько rows пришло в node;
- можно ли compatible index убрать sort;
- не возник fan-out до aggregate;
- не расходится ли estimate с actual.

Глубокий memory tuning переносится дальше.

## 54. Buffers

`BUFFERS` показывает page-level работу:

- shared hit — block найден в shared buffers;
- shared read — block пришлось прочитать;
- dirtied/written — изменения blocks;
- temp read/written — временные данные operations.

Execution time меняется из-за cache, machine load и output. Buffers часто дают более устойчивый контекст, но тоже не заменяют понимание workload.

Parent node включает работу child nodes, поэтому buffer numbers нельзя бездумно суммировать по всем строкам.

## 55. Statistics и `ANALYZE`

Planner оценивает cardinality по statistics. После крупной загрузки fixture полезно:

```sql
ANALYZE week7_lab.customer_offer;
```

`ANALYZE` собирает statistics; autovacuum в обычной system обычно делает это автоматически. Если estimates плохие, возможные причины:

- statistics устарели;
- sample недостаточно описывает skew;
- columns коррелированы, а single-column statistics этого не знают;
- expression/predicate сложен для оценки;
- parameter value отличается от typical.

Нельзя автоматически повышать statistics target для всех columns. Сначала найти реальную estimate problem.

## 56. Query optimization workflow

Правильный цикл:

1. определить correctness и output grain;
2. зафиксировать representative parameters/data volume;
3. измерить query count и baseline plan;
4. найти node с наибольшей фактической работой или плохой estimate;
5. сформулировать одну гипотезу;
6. изменить query/schema/index в одном месте;
7. обновить statistics при необходимости;
8. снова измерить тем же способом;
9. проверить correctness/regression;
10. оставить изменение только с объяснимой пользой и приемлемой ценой.

Сначала correctness. Быстрый query с неверным результатом не оптимизирован.

## 57. Sargable predicate

Условие условно называют sargable, когда index может использовать его как search condition, а не только фильтровать после вычисления.

Сравнение:

```sql
-- Часто неудобнее для обычного index на sold_at.
WHERE DATE(sold_at) = DATE '2026-06-01'

-- Чёткий half-open range.
WHERE sold_at >= TIMESTAMPTZ '2026-06-01 00:00:00+00'
  AND sold_at <  TIMESTAMPTZ '2026-06-02 00:00:00+00'
```

Нельзя механически переписывать predicate, забывая timezone и semantics.

## 58. N+1 queries

Паттерн:

1. один query получает N dealerships;
2. цикл делает ещё один query sales для каждого dealership;
3. всего выполняется `1 + N` queries.

```text
SELECT id, name FROM dealership;

for each dealership:
    SELECT COUNT(*) FROM retail_sale WHERE dealership_id = ?;
```

Проблема включает:

- round trips;
- repeated planning/execution;
- рост query count вместе с N;
- нагрузку на connection/database;
- нестабильное latency.

Set-based вариант обычно возвращает данные одним query через join/aggregate. Но join должен сохранять dealerships с zero sales и не создавать fan-out.

N+1 определяется измеренным query count, а не внешним видом Python loop. Иногда несколько bounded queries осознанны; цель — не «ровно один query любой ценой», а понятный budget.

## 59. Query budget

Для endpoint/use case заранее задаётся ожидаемый порядок query count:

```text
list dealerships with sale summary: constant count, не 1 + N
```

В неделе 10 это станет тестом Django ORM через `select_related`/`prefetch_related`. Сейчас паттерн измеряется на `sqlite3` callback и исправляется обычным SQL.

## 60. Project workload → index candidates

| Workload | Возможный candidate | Что проверить |
|---|---|---|
| pending Offers по времени | partial B-tree `(created_at, id) WHERE status='pending'` | доля pending, predicate match, worker ordering |
| inventory конкретного dealership/model | unique/PK pair уже может хватать | не создать duplicate index |
| available catalog dealership | `(dealership_id, car_model_id) INCLUDE (...)` | selectivity, existing PK, index-only feasibility |
| recent sales dealership | `(dealership_id, sold_at DESC, id DESC)` | `LIMIT`, stable order, write cost |
| customer purchase history | `(customer_id, sold_at DESC, id DESC)` | FK index отсутствует автоматически |
| supplier prices per model | `(car_model_id, effective_price, supplier_id)` либо query rewrite | как вычисляется effective price |
| car tags/specs search | GIN | конкретный JSONB/array operator |
| active promotion at moment | GiST range | overlap/containment operator и data volume |
| append-like sales date ranges | BRIN or B-tree | correlation, table size, range width |

Это candidates, не готовый universal answer. Финальное решение следует из schema и plans ученика.

## 61. Типичные ошибки недели

1. Transaction считают просто несколькими statements между `BEGIN` и `COMMIT` без invariant.
2. `COMMIT` выполняют автоматически, не проверив affected row count.
3. После SQL error продолжают aborted transaction.
4. Savepoint используют для сокрытия обязательной ошибки.
5. Transaction держат открытой во время `input()` или network call.
6. `READ UNCOMMITTED` в PostgreSQL считают реально отдельным weaker mode.
7. PostgreSQL `REPEATABLE READ` приписывают phantom behavior из минимальной таблицы стандарта.
8. `SERIALIZABLE` считают режимом без abort/retry.
9. Lost update пытаются исправить только повторным `SELECT`.
10. Lock берут не на source-of-truth row.
11. `FOR UPDATE` добавляют к каждому read.
12. `SKIP LOCKED` используют для финансового отчёта.
13. Deadlock устраняют увеличением timeout, не порядком locks.
14. Retry выполняют бесконечно.
15. Повторяют только failed statement, сохраняя старые reads.
16. Индексируют каждый column.
17. Дублируют PK/unique index.
18. Предполагают automatic FK index на child column.
19. Путают access method и operator class.
20. Выбирают composite order только по «самый selective первый».
21. Partial predicate не соответствует query.
22. `INCLUDE` объявляют гарантией Index Only Scan.
23. `Seq Scan` всегда называют плохим.
24. Cost называют milliseconds.
25. Не умножают actual rows на loops.
26. Сравнивают разные query parameters/data.
27. Оптимизируют до проверки результата.
28. `EXPLAIN ANALYZE UPDATE` неожиданно меняет данные.
29. N+1 считают исправленным без измерения query count.
30. Удаляют index по одному plan без учёта других workloads.

## 62. Контрольные прогнозы

До запуска письменно предположи результат.

### Прогноз 1. Rollback

В transaction balance уменьшен, затем выполнен `ROLLBACK`. Что увидит следующая session?

### Прогноз 2. Aborted transaction

После constraint violation выполняется `SELECT 1` без rollback. Выполнится ли он?

### Прогноз 3. Dirty read

Session B изменила stock, но не committed. Увидит ли значение Session A в `READ COMMITTED`?

### Прогноз 4. Two reads

Могут ли два `SELECT` в одной `READ COMMITTED` transaction увидеть разные committed values?

### Прогноз 5. Repeatable read

Увидит ли второй `SELECT` чужой committed update в уже начатой `REPEATABLE READ` transaction?

### Прогноз 6. Atomic decrement

Две sessions выполняют `quantity = quantity - 1 WHERE quantity > 0` при quantity 1. Сколько updates succeeds?

### Прогноз 7. Row lock

Session A держит row `FOR UPDATE`. Что произойдёт с update того же row в Session B?

### Прогноз 8. `SKIP LOCKED`

Worker B выбирает queue item, который уже locked Worker A. Ждать или пропустить?

### Прогноз 9. Deadlock

Две sessions берут rows 1 и 2 в противоположном порядке. Может ли PostgreSQL оставить обе ждать навсегда?

### Прогноз 10. Index

На table из 20 rows создан index, query возвращает 18. Обязан ли planner выбрать Index Scan?

### Прогноз 11. Composite index

Поможет ли `(status, created_at)` query только по `created_at` так же эффективно, как query с equality по `status`?

### Прогноз 12. Explain analyze

Изменит ли `EXPLAIN ANALYZE UPDATE ...` данные без окружающего rollback?

## 63. Вопросы самопроверки

1. Как определить правильную transaction boundary?
2. Что каждое свойство ACID гарантирует и чего не гарантирует?
3. Чем autocommit statements отличаются от одной явной transaction?
4. Что нужно сделать после error, переведшей transaction в aborted state?
5. Когда savepoint полезен, а когда опасно скрывает ошибку?
6. Чем dirty, non-repeatable и phantom read отличаются друг от друга?
7. Как PostgreSQL фактически обрабатывает `READ UNCOMMITTED`?
8. Почему PostgreSQL `REPEATABLE READ` не равен минимальному стандартному описанию?
9. Что гарантирует `SERIALIZABLE` и почему всё равно нужен retry?
10. Как воспроизводится lost update?
11. Когда хватает conditional atomic `UPDATE`, а когда нужен `FOR UPDATE`?
12. Почему transaction должна быть короткой?
13. Для чего подходят `NOWAIT` и `SKIP LOCKED`?
14. Как единый порядок locks предотвращает deadlock?
15. Какие SQLSTATE считаются retryable в этом модуле и что именно повторяется?
16. Почему index ускоряет не бесплатно?
17. Чем B-tree, Hash, GIN, GiST, SP-GiST и BRIN отличаются по задачам?
18. Какие indexes PostgreSQL создаёт для constraints и чего не создаёт FK?
19. Как выбирается порядок columns multicolumn B-tree?
20. Чем expression, partial и covering index отличаются?
21. Чем `EXPLAIN` отличается от `EXPLAIN ANALYZE`?
22. Почему Seq Scan может быть правильным plan?
23. Как читать actual rows и loops?
24. Что такое N+1 и как доказать, что он устранён?

## 64. Что будет позже

Неделя 8 подробно разберёт:

- MVCC row versions и visibility;
- WAL, checkpoints и crash recovery;
- `VACUUM`, autovacuum, freeze и bloat;
- TOAST;
- functions, procedures и triggers;
- partitioning, sharding, replication;
- CAP/PACELC и PostgreSQL/MySQL comparison.

Неделя 10 перенесёт transaction/index decisions в Django ORM: `transaction.atomic`, `select_for_update`, constraints/indexes в `Meta`, `select_related` и `prefetch_related`.

## 65. Официальные источники

- [PostgreSQL: Transactions](https://www.postgresql.org/docs/current/tutorial-transactions.html);
- [PostgreSQL: Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html);
- [PostgreSQL: Explicit Locking](https://www.postgresql.org/docs/current/explicit-locking.html);
- [PostgreSQL: `SELECT` locking clause](https://www.postgresql.org/docs/current/sql-select.html);
- [PostgreSQL: Index Types](https://www.postgresql.org/docs/current/indexes-types.html);
- [PostgreSQL: Multicolumn Indexes](https://www.postgresql.org/docs/current/indexes-multicolumn.html);
- [PostgreSQL: Indexes on Expressions](https://www.postgresql.org/docs/current/indexes-expressional.html);
- [PostgreSQL: Partial Indexes](https://www.postgresql.org/docs/current/indexes-partial.html);
- [PostgreSQL: Index-only Scans and Covering Indexes](https://www.postgresql.org/docs/current/indexes-index-only-scans.html);
- [PostgreSQL: Constraints and FK indexing note](https://www.postgresql.org/docs/current/ddl-constraints.html);
- [PostgreSQL: `CREATE INDEX`](https://www.postgresql.org/docs/current/sql-createindex.html);
- [PostgreSQL: Using `EXPLAIN`](https://www.postgresql.org/docs/current/using-explain.html);
- [PostgreSQL: `EXPLAIN`](https://www.postgresql.org/docs/current/sql-explain.html);
- [PostgreSQL: Planner Statistics](https://www.postgresql.org/docs/current/planner-stats.html);
- [PostgreSQL: `ANALYZE`](https://www.postgresql.org/docs/current/sql-analyze.html).
