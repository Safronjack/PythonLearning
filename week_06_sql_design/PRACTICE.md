# Практика недели 6: SQL и проектирование базы данных

Статус: **заблокирована до полного зачёта недель 0–5**.

Решения пишет ученик. Готовые business queries и итоговая схема намеренно отсутствуют. Fixture data принадлежит наставнику и нужна только как стабильная среда проверки.

## Общие правила

1. До задания прочитай назначенные разделы `THEORY.md`.
2. До запуска каждого query запиши ожидаемый grain, количество rows и ключевые значения.
3. Используй только текущий файл дня.
4. Не меняй `fixtures/sqlite_dealership.sql`.
5. Любой `UPDATE`/`DELETE` сначала предваряй `SELECT` с тем же `WHERE`.
6. Destructive DDL выполняй только в одноразовой `:memory:` или явно учебной database.
7. Не используй `TRUNCATE ... CASCADE` в практических файлах.
8. Не подставляй пользовательский ввод конкатенацией в SQL.
9. В каждом result query добавляй deterministic `ORDER BY`, если порядок проверяется.
10. После самопроверки напиши: `Проверь день N недели 6`.
11. Оценки и замечания записывает наставник только в `ASSESSMENT.md`.

## Запуск общего SQL через SQLite

Из корня проекта:

```sh
sqlite3 :memory: \
  ".read week_06_sql_design/fixtures/sqlite_dealership.sql" \
  ".read week_06_sql_design/day_03_dml_select.sql"
```

Замени имя файла для дня 4 или 5. `:memory:` означает, что база исчезнет после завершения процесса. Не добавляй `.exit` внутрь учебного SQL-файла: это усложнит автоматическую проверку.

PostgreSQL-specific statements помечай комментарием `-- PostgreSQL only`. Не пытайся «починить» их под SQLite в итоговой схеме.

## Формат записи задания

Перед каждым query:

```sql
-- Q01. Активные автосалоны
-- Grain: одна row на dealership.
-- Прогноз: 4 rows; первая row ...
-- Почему: ...

-- SELECT ...;

-- Фактически: ...
-- Вывод: прогноз совпал/не совпал, потому что ...
```

Во время решения query раскомментируется. Заглушки с одним `SELECT NULL` не считаются выполнением.

## Самооценка дня

В конце каждого файла:

```sql
-- Самооценка
-- 1. Что получилось:
-- 2. Где было трудно:
-- 3. Какой grain у самого сложного query:
-- 4. Какой граничный случай проверен:
-- 5. Что пока не могу объяснить:
```

---

# День 1. Реляционная модель, data types, `NULL` и DDL

## Паспорт задания

- **Цель:** перевести факты предметной области в таблицы, столбцы и ограничения с явным grain.
- **Рабочие файлы:** `day_01_relational_model.sql` и ответы в `notes.md`.
- **Порядок:** ответь на вопросы; классифицируй факты; создай одноразовую schema; заполни таблицу решений по типам; исследуй DDL; последним проведи NULL-лабораторию.
- **Наблюдаемый результат:** SQL создаёт объекты и выдаёт подписанные результаты запросов; комментарии объясняют одну строку каждой таблицы и выбор nullable-полей.
- **Готово, если:** money не хранится float; `NULL`, `0` и пустая строка не смешаны; имена и types согласованы; повторный лабораторный запуск имеет понятную процедуру очистки.
- **Пример:** одна строка inventory означает остаток конкретной модели в конкретном салоне, а не «автомобиль вообще».
- **Обязательно:** пять заданий и сценарии. **Рекомендация:** до каждого `CREATE TABLE` написать его grain одним предложением.

## Результат дня

Ты различаешь структуру и данные, можешь определить grain таблицы, выбрать базовый type и создать небольшую согласованную schema.

## Теория

Прочитай разделы 1–8 и прогнозы 1–2.

## До кода

В `notes.md` ответь:

1. Что представляет одна row в `car_model`?
2. Чем database отличается от schema и table?
3. Почему `NULL`, `0` и пустая строка имеют разный смысл?
4. Почему для USD нужен exact numeric type?
5. Почему `updated_at DEFAULT CURRENT_TIMESTAMP` не обновляется автоматически?
6. Какие различия SQLite и PostgreSQL важны для этого модуля?

## Задание 1. Классификация фактов

Для каждого факта назови table, column и предполагаемый type:

- название автосалона;
- страна автосалона;
- текущий баланс;
- название модели;
- год выпуска;
- остаток конкретной модели в конкретном салоне;
- момент продажи;
- дата окончания акции, которая может быть не задана;
- подтверждение email;
- статус Offer.

Запиши решения SQL-комментариями в `day_01_relational_basics.sql`.

## Задание 2. Первая schema

Создай в одноразовой SQLite-базе tables с prefix `learning_`:

- `learning_car_make`;
- `learning_car_model`;
- `learning_dealership`.

Минимальные columns:

- integer primary key;
- смысловые text/integer/boolean-like values;
- `is_active` с default;
- `created_at` и `updated_at`;
- nullable `country_code` у марки;
- точный денежный формат для dealership balance в выбранной SQLite-модели.

Поскольку SQLite не повторяет PostgreSQL `numeric` enforcement, выбери для исполнимой лаборатории integer cents и объясни это. Ниже отдельным закомментированным блоком напиши PostgreSQL-вариант balance через `numeric(14, 2)` и timestamps через `timestamptz`.

## Задание 3. Types decision table

Заполни SQL-комментариями:

| Значение | PostgreSQL type | Nullable? | Constraint/default | Почему |
|---|---|---:|---|---|
| `dealership.name` |  |  |  |  |
| `dealership.balance` |  |  |  |  |
| `car_model.production_year` |  |  |  |  |
| `promotion.ends_at` |  |  |  |  |
| `offer.status` |  |  |  |  |
| `created_at` |  |  |  |  |

## Задание 4. DDL inspection

После создания выполни:

```sql
.schema learning_car_make
.schema learning_car_model
.schema learning_dealership
```

Meta-команды `.schema` разрешены только в ручном SQLite-сеансе и не должны оставаться в `.sql`, который наставник запускает как обычный script. В файл перенеси наблюдения комментариями.

## Задание 5. `NULL` laboratory

Создай временную `learning_promotion` с nullable `ends_at`, вставь три rows: с датой, без даты и с другой датой. Напиши queries:

- `ends_at IS NULL`;
- `ends_at IS NOT NULL`;
- намеренно предскажи результат `ends_at = NULL`, затем оставь неверную форму только комментарием;
- `COALESCE(ends_at, 'open-ended')`;
- сравнение через `IS`/`IS NOT` в SQLite и эквивалентный PostgreSQL `IS [NOT] DISTINCT FROM` в комментарии.

## Обязательные сценарии

1. Все четыре learning tables создаются в `:memory:` без ошибки.
2. Повторяющееся имя table не скрывается случайным `IF NOT EXISTS`.
3. Balance не использует `REAL`/`double precision`.
4. Обязательные business values имеют `NOT NULL`.
5. Nullable column выбран осознанно.
6. Default и explicit `NULL` не считаются одним поведением.
7. `= NULL` не используется в рабочем query.
8. Имена lower `snake_case`, без quoted mixed-case identifiers.

## Контрольные вопросы дня

1. Чем DDL отличается от DML?
2. Почему SQL table не гарантирует порядок rows?
3. Как type и constraint дополняют друг друга?
4. В каких двух случаях `NULL` действительно уместен в этой schema?

---

# День 2. Keys, constraints и relationships

## Паспорт задания

- **Цель:** закрепить идентичность строк и связи так, чтобы база сама запрещала некорректные данные.
- **Рабочий файл:** `day_02_keys_relationships.sql`.
- **Порядок:** создай ключи таблиц; реализуй 1:1, 1:N и M:N; вставь корректные данные; затем каждый ожидаемый отказ выполняй изолированно; заверши решениями по composite key и soft delete.
- **Наблюдаемый результат:** положительные вставки проходят, а дубли и нарушения FK/constraints дают ожидаемые ошибки без разрушения последующих проверок.
- **Готово, если:** one-to-one обеспечен UNIQUE; business uniqueness выражена constraint; действия `ON DELETE` выбраны осознанно; failing-сценарии подписаны и отделены.
- **Пример:** второй профиль для того же user отвергается базой, а не только проверкой в комментарии.
- **Обязательно:** шесть заданий и сценарии. **Рекомендация:** рядом с каждым FK указать допустимость удаления родителя.

## Результат дня

Ты умеешь защищать уникальность и referential integrity, а также моделировать три основных вида связей.

## Теория

Прочитай разделы 9–18 и прогнозы 2–3.

## Задание 1. Keys

В `day_02_keys_relationships.sql` создай новую одноразовую schema с tables:

- `learning_user` с surrogate PK и unique email;
- `learning_buyer_profile` с one-to-one к user;
- `learning_car_make`;
- `learning_car_model`;
- `learning_dealership`;
- `learning_dealership_inventory` как many-to-many relation.

Условия:

- one-to-one обеспечен database constraint, а не комментарием;
- `(make_id, name, production_year)` имеет business uniqueness;
- inventory не допускает duplicate dealership/model pair;
- `quantity >= 0`, `sale_price_cents > 0`;
- every foreign key имеет выбранное `ON DELETE` behavior;
- для каждого `ON DELETE` есть комментарий с причиной.

## Задание 2. Three cardinalities

В `notes.md` заполни связи:

- make → model;
- user → buyer profile;
- dealership ↔ car model через inventory.

Для каждой укажи minimum/maximum с обеих сторон, где FK и какая uniqueness нужна.

## Задание 3. Positive inserts

Вставь:

- 2 users и 2 profiles;
- 2 makes и 3 models;
- 2 dealerships;
- 4 inventory rows.

После каждой группы выполни `SELECT` с explicit columns и `ORDER BY`.

## Задание 4. Expected constraint failures

Подготовь, но оставь закомментированными после исследования:

- duplicate email;
- второй profile для того же user;
- model с отсутствующим make;
- duplicate inventory pair;
- negative quantity;
- zero price;
- delete parent, на который ссылаются children.

Каждый statement запускай отдельно в одноразовой базе. Рядом запиши название violated constraint и почему ошибка полезна.

## Задание 5. Composite key decision

Сравни варианты inventory:

1. `PRIMARY KEY (dealership_id, car_model_id)`;
2. отдельный `id` плюс `UNIQUE (dealership_id, car_model_id)`.

Выбери один для итогового проекта и назови условие, при котором решение стоит пересмотреть.

## Задание 6. Soft deletion analysis

Для каждой category выбери политику:

- car make/model;
- dealership/supplier;
- inventory row;
- customer Offer;
- completed retail sale;
- balance ledger entry.

Варианты: deactivate, restrict physical delete, cascade dependent drafts, immutable history. Поле `is_active` из исходного задания не используй как единственный ответ — объясни смысл history.

## Обязательные сценарии

1. PK уникален и not null.
2. Surrogate id не заменяет unique email.
3. One-to-one нельзя превратить в one-to-many второй row.
4. Orphan model не создаётся.
5. Duplicate bridge pair отклоняется.
6. Zero inventory разрешён, negative — нет.
7. Transaction quantity и inventory quantity получают разные checks.
8. Referential actions объяснены для каждой FK.
9. Ни один `CASCADE` не выбран просто для удобства.
10. Expected failures не мешают финальному script выполняться.

## Контрольные вопросы дня

1. Чем primary key отличается от natural/business unique key?
2. Почему обычный FK не создаёт one-to-one?
3. Какие attributes принадлежат inventory relation?
4. Когда `ON DELETE RESTRICT` полезнее `CASCADE`?

---

# День 3. `INSERT`, `UPDATE`, `DELETE` и базовый `SELECT`

## Паспорт задания

- **Цель:** читать и изменять строки предсказуемо, контролируя фильтр и порядок результата.
- **Рабочий файл:** `day_03_dml_select.sql`, запускаемый вместе с `fixtures/sqlite_dealership.sql` в памяти.
- **Порядок:** изучи fixture только SELECT-запросами; добавь stable ordering; выполни INSERT; перед UPDATE/DELETE сначала запусти равнозначный SELECT; затем сравни delete/truncate и опиши parameter boundary.
- **Наблюдаемый результат:** каждый изменяющий запрос сопровождается проверкой до и после, а итоговые выборки имеют явные столбцы и детерминированный порядок.
- **Готово, если:** нет опасного UPDATE/DELETE без WHERE; cents не перепутаны с USD; NULL проверяется через `IS`; изменение затрагивает ожидаемое число rows.
- **Пример:** перед удалением запрос SELECT показывает ровно те записи, которые затем исчезнут.
- **Обязательно:** семь заданий и сценарии. **Рекомендация:** комментарием записывать ожидаемое число затронутых строк.

## Результат дня

Ты безопасно изменяешь rows и строишь детерминированные выборки с учётом `NULL`, filters и aliases.

## Теория

Прочитай разделы 19–24 и прогноз 1.

## Среда

Запускай файл вместе с `fixtures/sqlite_dealership.sql` в `:memory:`. Все изменения исчезнут после завершения команды.

## Задание 1. Исследование fixture

В `day_03_dml_select.sql` напиши queries:

1. все makes с explicit columns;
2. только active models;
3. active dealerships из GE;
4. dealerships с balance от 90 000 до 200 000 USD включительно — пересчитай cents;
5. suppliers без известного `founded_year`;
6. verified active customers;
7. offers в `pending`/`processing`;
8. первые три active models по make/name/id;
9. unique country codes из dealerships и suppliers двумя отдельными queries;
10. inventory status через `CASE`.

До запуска укажи прогноз row count и порядок.

## Задание 2. Stable ordering

Покажи на комментариях, почему `ORDER BY sale_price_cents` недостаточен при равной цене. Добавь deterministic tie-breakers. Query с `LIMIT` обязан иметь полный ожидаемый order.

## Задание 3. `INSERT`

Добавь в fixture только в памяти:

- нового active customer;
- его pending Offer;
- новый supplier catalog item с явным списком columns.

После каждого insert выбери добавленную row по PK/business key. Не полагайся на `SELECT *`.

Отдельным PostgreSQL-only комментарием покажи, где использовался бы `RETURNING id, ...`.

## Задание 4. Safe `UPDATE`

Нужно повысить balance только `Boris` на 500 USD.

1. Напиши preview `SELECT` с тем же predicate.
2. Убедись, что preview даёт ровно одну row.
3. Выполни `UPDATE` с тем же `WHERE`.
4. Проверь новое и неизменённые соседние значения.
5. Рядом напиши PostgreSQL-only `RETURNING` вариант.

Второй update меняет status только одного Offer из `pending` в `processing`. Predicate должен включать exact identifier и expected old status.

## Задание 5. Safe `DELETE`

Создай временную test customer row, проверь её exact key, удали только её и докажи отсутствие. Не удаляй fixture customers.

Оставь комментарий, что `DELETE FROM customer;` без `WHERE` является syntactically valid и почему это опасно.

## Задание 6. `DELETE` против `TRUNCATE`

Составь таблицу различий PostgreSQL:

- row filtering;
- triggers;
- FK behavior;
- identity restart;
- locking;
- transaction rollback;
- типичный use case.

Не выполняй `TRUNCATE` в этом дне.

## Задание 7. Parameter boundary

В SQL-комментарии покажи только template:

```text
SELECT ... WHERE email = <driver placeholder>
```

Объясни, почему value parameter не подходит для client-selected column name. Код Python и собственный escaping не нужны.

## Обязательные сценарии

1. Все 10 read queries имеют explicit columns.
2. Проверяемый порядок имеет `ORDER BY` и tie-breaker.
3. `NULL` проверяется через `IS NULL`.
4. `INSERT` перечисляет columns.
5. Каждый update/delete имеет preview и post-check.
6. Update затрагивает ровно ожидаемую row.
7. Fixture history не удаляется.
8. Неподтверждённый customer отличается от inactive customer.
9. `TRUNCATE` не выполняется.
10. SQL injection не «решается» ручными кавычками.

## Контрольные вопросы дня

1. Почему `SELECT *` слаб для стабильного application contract?
2. Почему `LIMIT` требует `ORDER BY`?
3. Как безопасно подготовить `UPDATE`?
4. Какие важные отличия есть у `TRUNCATE`?

---

# День 4. Joins, subqueries, CTE и set operations

## Паспорт задания

- **Цель:** объединять таблицы без случайного размножения строк и выбирать подходящую форму многошагового запроса.
- **Рабочий файл:** `day_04_joins_subqueries_cte.sql` с общим SQLite fixture.
- **Порядок:** перед каждым запросом запиши grain/cardinality; выполни базовые joins; исследуй отсутствие связи через LEFT JOIN; сравни фильтр в ON/WHERE; затем subqueries, NULL-safe anti-join, CTE и set operations.
- **Наблюдаемый результат:** запросы показывают ожидаемые строки и явно демонстрируют случаи потери/сохранения отсутствующих связей.
- **Готово, если:** нет непреднамеренного Cartesian product; NULL-строки LEFT JOIN сохраняются там, где нужны; `NOT IN` с NULL разобран; UNION-совместимые столбцы имеют общий смысл.
- **Пример:** список всех салонов включает салон без продаж с NULL в полях продажи.
- **Обязательно:** восемь заданий и сценарии. **Рекомендация:** сравнивать число строк до и после каждого join.

## Результат дня

Ты объединяешь relations без случайного fan-out, различаешь отсутствующие связи и строишь многошаговые запросы.

## Теория

Прочитай разделы 25–32 и прогнозы 4–5.

## Среда

Используй fixture в `:memory:`. Перед каждым join запиши grain и ожидаемую cardinality.

## Задание 1. Базовые joins

В `day_04_joins_subqueries_cte.sql` напиши:

1. model вместе с make;
2. inventory вместе с dealership, make и model;
3. supplier catalog вместе с supplier и model;
4. offers вместе с customer и model;
5. sales вместе с dealership, customer и model.

В result не выводи технические duplicates columns. Используй понятные aliases и deterministic ordering.

## Задание 2. `LEFT JOIN` и отсутствие связи

Получить:

- все dealerships и количество их inventory rows, включая zero;
- все models и доступный inventory, даже если model нигде не продаётся;
- все customers и их Offers, включая отсутствие Offer;
- suppliers и catalog items, включая inactive supplier без active items.

Для первого query сравни `COUNT(*)` и `COUNT(inventory.car_model_id)`. Объясни различие.

## Задание 3. Условие в `ON` и `WHERE`

Напиши две версии списка всех dealerships с active inventory:

- filter right table в `ON`;
- тот же filter в `WHERE`.

Запиши, какие dealerships исчезли и почему. Выбери правильную форму для требования «показать все салоны, даже пустые».

## Задание 4. `CROSS JOIN` только осознанно

Создай через CTE два маленьких набора: 3 reporting months и 2 active dealerships. Выполни `CROSS JOIN`, предскажи 6 rows и объясни use case «нулевые месяцы в отчёте».

Никакой `JOIN` без `ON` не должен быть случайным.

## Задание 5. Subqueries

Напиши queries:

1. dealerships с balance выше среднего;
2. inventory дороже средней sale price своего model;
3. customers, у которых существует pending Offer (`EXISTS`);
4. models без active supplier catalog (`NOT EXISTS`);
5. sales с amount равным максимальному amount;
6. suppliers, продающие models из active inventory.

Отметь correlated и non-correlated subqueries.

## Задание 6. `NOT IN` и `NULL`

На маленьком CTE-наборе покажи прогноз для:

```sql
WHERE value NOT IN (1, NULL)
```

Рабочий business query перепиши через `NOT EXISTS`. Не используй фильтрацию `NULL` как механическое исправление без объяснения contract.

## Задание 7. CTE

Реши через именованные steps:

- active inventory с quantity > 0;
- eligible Offers только active/verified customers;
- dealerships, где нужная model есть и price не выше max Offer price;
- result candidate dealership rows.

На этом дне не проводи сделку и не меняй данные. Если кандидатов несколько, выведи все и зафиксируй grain «одна row на Offer + dealership».

## Задание 8. Set operations

- объединить country codes dealership и supplier через `UNION`;
- повторить через `UNION ALL` и сравнить duplicates;
- найти customers, покупавших и в dealership 1, и в dealership 2 через `INTERSECT`;
- найти active models без inventory через `EXCEPT`.

Перед выполнением предскажи, где duplicates сохранятся.

## Обязательные сценарии

1. Все joins имеют объявленный grain.
2. Model/make join не создаёт лишние rows.
3. Empty dealership остаётся в нужном `LEFT JOIN`.
4. Inactive rows учитываются только по явно заданному правилу.
5. `COUNT(child.id)` используется для zero children.
6. Cartesian product имеет ровно ожидаемые 6 rows.
7. `NOT EXISTS` корректно работает при nullable values.
8. Candidate Offer query ничего не изменяет.
9. `UNION` и `UNION ALL` не перепутаны.
10. Каждый проверяемый result отсортирован.

## Контрольные вопросы дня

1. Что определяет grain join result?
2. Как `LEFT JOIN` может случайно превратиться в inner join?
3. Когда `EXISTS` понятнее join?
4. Что CTE улучшает, но не гарантирует?

---

# День 5. Aggregates, `GROUP BY`, `HAVING` и window functions

## Паспорт задания

- **Цель:** получать сводные показатели и сохранять детальные строки там, где нужен оконный расчёт.
- **Рабочий файл:** `day_05_aggregates_windows.sql`.
- **Порядок:** вычисли общие агрегаты; добавь группировки; раздели WHERE и HAVING; сохрани группы с нулём; исправь fan-out; затем ranking и detail-plus-total через windows.
- **Наблюдаемый результат:** каждый отчёт имеет понятный grain, стабильный порядок и контрольную итоговую сумму в cents.
- **Готово, если:** все non-aggregate столбцы корректно сгруппированы; zero groups не исчезают; выручка не удваивается join-ом; ranking имеет tie-breaker; window не сворачивает detail.
- **Пример:** каждая продажа остаётся отдельной строкой, но рядом отображается общая выручка её салона.
- **Обязательно:** восемь заданий и сценарии. **Рекомендация:** для каждого запроса записать «одна строка результата означает…».

## Результат дня

Ты строишь статистику итогового проекта и понимаешь, когда rows нужно сгруппировать, а когда сохранить detail с window calculation.

## Теория

Прочитай разделы 33–39 и прогнозы 6–9.

## Задание 1. Простые aggregates

В `day_05_aggregates_windows.sql` вычисли:

1. количество active dealerships;
2. минимальную, максимальную и среднюю sale price inventory;
3. общее количество проданных автомобилей;
4. общий revenue;
5. количество non-null `founded_year` и всех suppliers;
6. unique customers среди sales.

Для money fixture использует cents. Result может оставаться integer cents; не переводить через floating-point.

## Задание 2. Grouping

Сделай отчёты:

- sale count, sold units, revenue и unique customers по dealership;
- количество моделей и суммарный stock по dealership;
- число supplier offers и minimum effective price по model;
- spending и purchase count по customer;
- sales count по calendar month, извлечённому из ISO timestamp fixture.

У каждой row отчёта назови grain.

Для effective supplier price используй integer arithmetic так, чтобы не внести floating rounding. Объясни выбранную формулу и её ограничение.

## Задание 3. `WHERE` и `HAVING`

Найди:

- только active dealerships до grouping;
- dealerships с revenue больше 5 000 000 cents после grouping;
- customers минимум с двумя sales;
- models минимум с двумя active suppliers;
- dealerships с минимум двумя unique customers.

Каждый predicate помести на правильный этап и объясни почему.

## Задание 4. Zero groups

Отчёт по всем active dealerships должен показать zero для салона без sales/inventory.

- начни с dimension table `dealership`;
- используй `LEFT JOIN`;
- сравни `COUNT(*)` и `COUNT(sale.id)`;
- применяй `COALESCE(SUM(...), 0)` только по осознанному output contract;
- не фильтруй child rows в `WHERE`, если нужно сохранить zero group.

## Задание 5. Fan-out report

Попробуй соединить dealership одновременно с inventory и sales, затем посчитать quantity/revenue. До запуска предскажи умножение rows.

Неверную версию оставь комментариями. Рабочую версию построй через две заранее агрегированные CTE и только затем соедини results по dealership.

## Задание 6. Ranking

Напиши window queries:

1. все supplier offers с `ROW_NUMBER` по effective price для каждой model;
2. все ties минимальной effective price через `RANK` или `DENSE_RANK`;
3. top-1 deterministic supplier через `ROW_NUMBER` и tie-breaker;
4. rank dealership по revenue;
5. две самые дорогие sales каждого dealership.

Для фильтра `position <= 2` используй CTE/subquery.

## Задание 7. Detail plus totals

Для каждой sale добавь:

- total revenue dealership;
- running revenue dealership по `sold_at, id`;
- долю sale в revenue dealership без деления на zero;
- номер покупки customer;
- previous purchase amount customer через `LAG`;
- difference с предыдущей purchase, где она существует.

Running total должен иметь явный `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`.

## Задание 8. Aggregate против window

Для customer 1 выведи:

- одну aggregated row с total spending;
- все detail sales с тем же total через `SUM() OVER`.

Запиши точное различие row count и grain.

## Обязательные сценарии

1. `COUNT(column)` не считается равным `COUNT(*)` при `NULL`.
2. Sold units использует `SUM(quantity)`, а не row count.
3. Zero dealership не исчезает.
4. `WHERE` фильтрует rows, `HAVING` — groups.
5. Fan-out исправлен pre-aggregation.
6. Ranking partition выбран по model/dealership осознанно.
7. Top-1 имеет deterministic tie-breaker.
8. Tied minimum suppliers не теряются в отдельном query.
9. Running total имеет explicit frame.
10. `LAG` первой row даёт осознанный `NULL`.
11. Window calculation не уменьшает detail row count.
12. Top-level result имеет `ORDER BY`.

## Контрольные вопросы дня

1. Чем `COUNT(*)` отличается от `COUNT(column)`?
2. Почему несколько one-to-many joins ломают суммы?
3. Чем aggregate отличается от window function?
4. Зачем window нужны partition, order и frame?

---

# День 6. Normalization, views и первая ERD

## Паспорт задания

- **Цель:** разложить плоский отчёт на нормализованные сущности и синхронизировать DDL с ERD и требованиями проекта.
- **Рабочие файлы:** `day_06_normalization_views.sql`, `day_06_erd.md` и `day_06_design_notes.md`.
- **Порядок:** найди anomalies; выполни шаги нормализации; напиши PostgreSQL DDL; создай обычные views; обоснуй materialized view; затем ERD, coverage требований и кандидаты денормализации.
- **Наблюдаемый результат:** документы позволяют проследить каждое требование до таблицы/связи, а views имеют определённый grain и назначение.
- **Готово, если:** повторяющиеся группы устранены; snapshots отделены от случайных дублей; PK/FK/uniqueness отражены и в SQL, и ERD; материализация не предлагается без refresh-стратегии.
- **Пример:** email покупателя хранится в одном каноническом месте, а историческое имя в продаже остаётся только при осознанном snapshot-решении.
- **Обязательно:** восемь заданий и сценарии. **Рекомендация:** вести таблицу «требование → сущность → constraint».

## Результат дня

Ты превращаешь плоскую таблицу требований в согласованную relational schema, отличаешь намеренный snapshot от опасного дублирования и документируешь связи.

## Теория

Прочитай разделы 40–51 и прогнозы 10–12.

## Задание 1. Найди anomalies

Рассмотри исходную структуру:

```text
sale_report(
    sale_id,
    sold_at,
    dealership_id,
    dealership_name,
    dealership_country,
    customer_id,
    customer_email,
    customer_name,
    car_model_id,
    make_name,
    model_name,
    supplier_names_csv,
    current_catalog_price,
    agreed_unit_price,
    quantity,
    total_amount
)
```

В `day_06_erd.md` опиши минимум:

- две update anomalies;
- одну insert anomaly;
- одну delete anomaly;
- repeating/non-atomic group;
- columns, которые зависят только от части фактов;
- намеренный historical snapshot, который нельзя удалять как duplicate.

## Задание 2. Normalization steps

Покажи три последовательных шага:

1. 1NF — убрать CSV/repeating groups;
2. 2NF — перенести attributes, не зависящие от полного relation key;
3. 3NF — убрать transitive dependencies.

Для каждого шага перечисли появившиеся tables и их grain. Не ограничивайся фразой «разделил таблицу».

## Задание 3. PostgreSQL normal form DDL

В `day_06_normalization_views.sql` напиши сокращённую PostgreSQL schema нормализованного примера:

- `car_make`;
- `car_model`;
- `dealership`;
- `customer`;
- `supplier`;
- `supplier_catalog_item`;
- `retail_sale`.

Она должна показывать PK, FK, exact money, business uniqueness, positive amounts, timestamps и safe deletion policy. Это подготовительная schema, не копия итогового дня 7.

## Задание 4. Обычные views

Спроектируй PostgreSQL views:

- `active_dealership_inventory`;
- `available_dealership_catalog` — active row, quantity > 0;
- `dealership_sales_summary` — dealership, sale count, sold units, revenue, unique customers;
- `customer_purchase_summary` — customer, count, spending.

Для каждой запиши:

- grain;
- base tables;
- ожидаемую свежесть;
- можно ли безопасно изменять её напрямую;
- что произойдёт после изменения base row.

## Задание 5. Materialized view decision

Напиши `CREATE MATERIALIZED VIEW` для тяжёлого отчёта лучших supplier prices по каждой model. Добавь отдельный `REFRESH MATERIALIZED VIEW`.

Это design exercise: без PostgreSQL statement можно не запускать. Объясни:

- почему result может устареть;
- кто и когда запускает refresh;
- какую freshness допускает business;
- почему первая версия проекта может использовать обычный query/view;
- какой source of truth остаётся.

## Задание 6. Первая ERD итогового проекта

В `day_06_erd.md` создай Mermaid `erDiagram`. Минимально отрази capabilities:

- user и buyer profile;
- dealership и supplier;
- make и model;
- preferences;
- dealership inventory;
- supplier catalog/prices;
- promotions и их models;
- customer Offer;
- retail sale и procurement;
- stock movement;
- balance/ledger entry.

Для каждой entity укажи PK, важные FK и business unique keys. В тексте после diagram опиши optionality и lifecycle.

## Задание 7. Проверка требований `Django task.docx`

Сопоставь ERD с требованиями:

| Требование | Entity/relation | Source of truth | История или текущее состояние | Открытый вопрос |
|---|---|---|---|---|
| Остатки автосалона | TODO | TODO | TODO | TODO |
| Лучшие поставщики | TODO | TODO | TODO | TODO |
| Offer покупателя | TODO | TODO | TODO | TODO |
| Акции | TODO | TODO | TODO | TODO |
| История продаж | TODO | TODO | TODO | TODO |
| Баланс | TODO | TODO | TODO | TODO |

Зафиксируй минимум пять вопросов, которые нужно уточнить у product owner. Примеры областей: роли пользователя, валюта, жизненный цикл Offer, пересечение акций, возвраты, изменение email и политика удаления данных.

## Задание 8. Denormalization candidates

Разбери:

- `best_supplier_choice`;
- текущий balance рядом с immutable balance entries;
- current inventory рядом со stock movements;
- dealership statistics summary.

Для каждого укажи source of truth, update mechanism, acceptable staleness и reconciliation. Не добавляй derived table в ERD как обычный независимый факт без отметки.

## Обязательные сценарии

1. В ERD нет CSV/array foreign keys.
2. Every many-to-many имеет bridge entity.
3. One-to-one имеет unique/PK foreign key.
4. Current price и agreed sale price различаются.
5. Current stock и movement history различаются.
6. История сделки не зависит от текущей catalog price.
7. `is_active` не уничтожает audit requirements.
8. Views имеют объявленный grain.
9. Materialized view имеет refresh/freshness policy.
10. ERD cardinality совпадает с планируемыми constraints.
11. Нормализация объяснена functional dependencies, а не количеством tables.
12. Не менее пяти неоднозначностей требований записаны.

## Контрольные вопросы дня

1. Какие anomalies снижает normalization?
2. Почему historical snapshot не является плохим duplicate?
3. Чем view отличается от materialized view?
4. Как проверить, что ERD и DDL согласованы?

---

# День 7. Итоговый PostgreSQL-прототип базы проекта

## Паспорт задания

- **Цель:** создать первую исполнимую схему итогового проекта и доказать её constraints и полезность бизнес-запросами.
- **Рабочая область:** только каталог `day_07_database_prototype/` и семь файлов из структуры ниже.
- **Порядок:** реализуй schema; проверь её статически; добавь seed; затем business queries и отдельные constraint checks; синхронизируй ERD; запиши решения; последним оформи безопасный README.
- **Наблюдаемый результат:** в согласованной учебной PostgreSQL database схема разворачивается с нуля, данные загружаются, отчёты выполняются, а неверные операции дают ожидаемый отказ.
- **Готово, если:** чистый запуск воспроизводим; требования Django task трассируются; constraints проверены изолированно; scripts не направлены на неизвестную базу; ERD и DDL совпадают.
- **Пример:** README ведёт от создания пустой учебной базы к schema, seed, queries и checks в однозначном порядке.
- **Обязательно:** все семь частей и итоговые сценарии; runtime-зачёт только после безопасного запуска. **Рекомендация:** хранить каждый ожидаемый failure так, чтобы он не останавливал остальные проверки.

## Результат дня

Ты создаёшь первую реализуемую data model итогового Django-проекта и доказываешь её полезность business queries и constraint checks.

## Предусловие среды

До выполнения PostgreSQL scripts наставник и ученик отдельно проверяют доступную локальную среду. Не устанавливай server, Docker или driver автоматически. Если PostgreSQL ещё отсутствует, schema проходит полное статическое review, а runtime-зачёт остаётся незакрытым до безопасного запуска в выделенной учебной database.

Работай только с database, чьё точное имя согласовано как учебное, например `dealership_week6`. Никогда не запускай schema/seed script против чужой, рабочей или неизвестной database.

## Структура

```text
day_07_database_prototype/
├── schema_postgresql.sql
├── seed_postgresql.sql
├── queries_postgresql.sql
├── checks_postgresql.sql
├── ERD.md
├── DESIGN_DECISIONS.md
└── README.md
```

## Часть 1. PostgreSQL schema

В `schema_postgresql.sql` создай нормализованную схему, покрывающую:

- application user и buyer profile;
- dealerships и suppliers;
- car makes/models и важные характеристики;
- dealership preferences;
- dealership inventory;
- supplier catalog/prices/stock;
- dealership и supplier promotions либо другую строго ограниченную модель ownership;
- promotion-to-model relation;
- supplier loyalty discount;
- customer Offer;
- retail sale;
- procurement dealership → supplier;
- stock movement;
- immutable balance entry/ledger;
- derived best supplier choice как view/materialized candidate, а не единственный источник цены.

Точные table names можно уточнить, но capabilities нельзя потерять.

### Обязательные DDL-правила

- lower `snake_case` identifiers;
- explicit PostgreSQL data types;
- identity/UUID choice обоснован;
- every table имеет PK;
- every relationship поддержан FK;
- meaningful `NOT NULL`;
- business `UNIQUE`, включая inventory/catalog pairs;
- named `CHECK` constraints для money, quantity, percent, dates и statuses;
- `numeric`, не floating point, для USD;
- `timestamptz` для moments;
- `is_active`, `created_at`, `updated_at` присутствуют согласно исходному заданию;
- comments отмечают исключения для immutable history;
- `ON DELETE` policy выбрана по relation;
- DDL не использует `DROP ... CASCADE`;
- никакие indexes сверх автоматически создаваемых constraints пока не оптимизируются — это неделя 7.

### Business invariants

Минимум:

- balance amount/entry model не допускает недопустимые значения согласно выбранному ledger contract;
- inventory quantity неотрицательно;
- sale/procurement/stock movement quantity положительно;
- prices и totals неотрицательны или положительны по смыслу;
- discount от 0 до 100;
- promotion `ends_at >= starts_at`;
- Offer status только из документированного множества;
- уникальна одна active/current inventory relation per dealership/model в выбранной модели;
- уникальна supplier/model catalog relation;
- agreed historical prices хранятся в transaction rows.

Не пытайся через row-level `CHECK` проверить текущий баланс другой table, наличие stock в момент сделки или «самого дешёвого поставщика». Это transaction/query responsibilities следующих этапов.

## Часть 2. Seed data

`seed_postgresql.sql` должен создавать небольшой, но содержательный набор:

- минимум 3 makes и 5 models;
- 4 dealerships, включая empty/no-sales case;
- 3 suppliers;
- 5 buyers, включая unverified и inactive;
- available, zero и inactive inventory rows;
- supplier prices с минимум одной tie и одной discount;
- active, future и expired promotions относительно фиксированных test dates;
- Offers во всех основных statuses;
- минимум 10 retail sales в разные dates;
- минимум 5 procurements;
- stock/balance movements, согласованные с выбранной моделью.

Seed должен быть deterministic и не использовать текущую дату там, где это сделает ожидаемые results нестабильными.

## Часть 3. Business queries

В `queries_postgresql.sql` реализуй минимум:

1. active available catalog конкретного dealership;
2. effective supplier prices конкретной model;
3. все cheapest supplier ties per model;
4. deterministic one best supplier per model;
5. candidate dealerships для pending Offer;
6. dealership sales: count, units, revenue, unique customers;
7. all dealerships report, включая zeros;
8. customer spending и purchase history;
9. supplier revenue и distinct partner dealerships;
10. running dealership revenue;
11. top-selling model каждого dealership;
12. models без active supplier;
13. dealerships с stock ниже заданного порога;
14. active promotions на фиксированный момент;
15. reconciliation current stock против sum movements на уровне диагностического query.

У каждого query укажи grain, parameters как comments/placeholders и ожидаемый result на seed data. Не подставляй Python input строковой конкатенацией.

## Часть 4. Constraint checks

`checks_postgresql.sql` содержит:

- read-only diagnostics, которые должны вернуть zero violations;
- проверки duplicate business keys;
- проверки orphan relations;
- отрицательных balance/stock/price;
- invalid statuses/percent/date ranges;
- расхождения transaction totals по документированной формуле;
- расхождения inventory/ledger, если source-of-truth model уже позволяет это проверить;
- expected-failure inserts, оставленные комментариями с названием constraint;
- row-count sanity checks для seed tables.

Runtime check запускается с остановкой на неожиданной ошибке. Expected failures не должны ломать общий проверочный script.

## Часть 5. ERD

`ERD.md` должен содержать:

- Mermaid `erDiagram`;
- PK/FK для каждой entity;
- relationship labels;
- optionality/cardinality;
- описание grain каждой bridge/transaction table;
- distinction current state/history/derived cache;
- таблицу соответствия ERD ↔ DDL.

## Часть 6. Design decisions

В `DESIGN_DECISIONS.md` зафиксируй минимум:

1. identifier strategy;
2. user/profile/role model;
3. money и currency model;
4. promotion ownership/scope;
5. soft deletion vs immutable history;
6. current stock и stock movement source of truth;
7. balance и ledger source of truth;
8. current vs historical price;
9. best supplier derived model;
10. views/materialized candidates;
11. normalized design и допустимые future denormalizations;
12. темы, отложенные до недель 7–10.

Для каждого: context, decision, alternative, consequence, revisit condition.

## Часть 7. README и безопасный запуск

Опиши:

- назначение prototype;
- prerequisites;
- точное имя только учебной database;
- порядок `schema → seed → queries → checks`;
- как подтвердить current connection до DDL;
- как не затронуть другую database;
- SQLite/PostgreSQL differences;
- known limitations;
- что перейдёт в Django models/migrations.

Не добавляй credentials и не используй production connection string.

## Обязательные сценарии итогового проекта

1. Schema создаётся с нуля в пустой учебной PostgreSQL database.
2. Повторный запуск документирован: clean recreation либо migration-like limitation.
3. Seed загружается без FK/constraint errors.
4. Все core tables имеют PK.
5. Все declared relations имеют FK.
6. One-to-one действительно unique.
7. Inventory pair unique.
8. Supplier/model pair unique.
9. Negative inventory отклоняется.
10. Zero transaction quantity отклоняется.
11. Invalid discount отклоняется.
12. End before start отклоняется.
13. Orphan child отклоняется.
14. Duplicate business key отклоняется.
15. Money types exact.
16. Inactive catalog rows исключаются из active catalog.
17. Empty dealership остаётся в all-dealership report.
18. Cheapest supplier ties сохранены.
19. Deterministic best supplier имеет tie-breaker.
20. Unverified/inactive buyer не проходит eligibility query.
21. Offer candidates учитывают model, stock и max price.
22. Aggregates не удваиваются из-за fan-out.
23. Unique customers считаются через правильный grain.
24. Running total имеет explicit ordering/frame.
25. View показывает актуальные base data.
26. Materialized candidate имеет freshness/refresh plan.
27. Historical sale price не зависит от current catalog.
28. Diagnostics возвращают zero unexplained violations.
29. ERD совпадает с DDL.
30. Ни один script не содержит secret/destructive cross-database command.

## Финальное объяснение без подсказки

Будь готов объяснить:

1. grain пяти выбранных tables;
2. три типа relationships;
3. natural и surrogate uniqueness;
4. nullable decisions;
5. deletion policy истории;
6. один fan-out и его исправление;
7. один aggregate и один window query;
8. view/materialized trade-off;
9. одну осознанную denormalization;
10. invariants database/application/transaction layers.

## Критерий итогового зачёта

- минимум 8/10;
- 30 сценариев проверены либо runtime-блокировка явно сохранена;
- schema, ERD и design decisions согласованы;
- нет критических ошибок из `README.md`;
- ученик объясняет запросы и самостоятельно исправляет замечания;
- допуск к неделе 7 выставляется только наставником.

---

# После каждого ревью

1. Наставник записывает результат в `ASSESSMENT.md`.
2. Ученик исправляет обязательные пункты и причину ошибки.
3. Повторно выполняются все уже принятые queries/scenarios.
4. Следующий день открывается только при итоговой оценке минимум 7/10.
5. Неделя 7 остаётся заблокированной до полного зачёта недели 6.
