# Неделя 6: SQL и проектирование реляционной базы данных

Статус: **подготовлена заранее и заблокирована**.

Начало разрешается только после полного зачёта недель 0–5 и явного допуска в `week_05_web_linux_git/ASSESSMENT.md`. Текущей активной работой остаётся неделя 0.

## Цель недели

Научиться превращать текстовые требования итогового Django-проекта в реляционную модель и проверяемые SQL-запросы. К концу модуля ученик должен уметь:

- объяснить различие database, schema, table, row, column и relation;
- выбирать базовые PostgreSQL data types осознанно;
- понимать `NULL` и трёхзначную SQL-логику;
- создавать таблицы и изменять их схему;
- выбирать primary, natural, surrogate и foreign keys;
- моделировать one-to-one, one-to-many и many-to-many;
- применять `NOT NULL`, `UNIQUE`, `CHECK`, `DEFAULT` и referential actions;
- безопасно писать `INSERT`, `UPDATE`, `DELETE` и понимать отличие `DELETE` от `TRUNCATE`;
- строить `SELECT` с фильтрацией, сортировкой, `CASE`, `DISTINCT` и pagination;
- использовать `INNER`, `LEFT`, `RIGHT`, `FULL` и `CROSS JOIN` по смыслу;
- решать задачи через correlated/non-correlated subqueries и CTE;
- использовать aggregates, `GROUP BY` и `HAVING`;
- отличать aggregate functions от window functions;
- применять `ROW_NUMBER`, `RANK`, `LAG`, `SUM() OVER` и явный window frame;
- понимать обычные и materialized views;
- нормализовать схему до разумной 3NF и обосновывать денормализацию;
- нарисовать первую ER-диаграмму итогового проекта;
- подготовить PostgreSQL DDL, seed data и ключевые аналитические запросы.

## Источники требований проекта

Неделя использует предметную область из `Django task.docx`:

- автосалоны, покупатели и поставщики;
- марки и модели автомобилей;
- предпочтения и остатки;
- каталоги и цены поставщиков;
- акции и скидки;
- Offer покупателя;
- розничные продажи и закупки;
- движения денег и товара;
- статистические запросы;
- `is_active`, `created_at`, `updated_at` как исходное требование.

Документ является источником требований, а не готовой схемой. Решения о сущностях, keys, cardinality, optionality и deletion policy ученик обосновывает самостоятельно.

## Предварительные требования

- Недели 0–5 полностью завершены.
- Ученик понимает коллекции, функции, классы, `Decimal` и обработку ошибок.
- Ученик знает основы HTTP и риск SQL injection.
- Ученик умеет безопасно выполнять команды в учебной папке.
- Ученик использует Git в рамках согласованного workflow.
- В `week_05_web_linux_git/ASSESSMENT.md` указан допуск к неделе 6.

## Структура

- [THEORY.md](THEORY.md) — теория, SQL-примеры, прогнозы и вопросы;
- [PRACTICE.md](PRACTICE.md) — семь последовательных практических дней;
- [ASSESSMENT.md](ASSESSMENT.md) — будущие оценки, ошибки и пересдачи;
- [notes.md](notes.md) — личный словарь, таблица связей и журнал запросов;
- [fixtures/sqlite_dealership.sql](fixtures/sqlite_dealership.sql) — учебный набор данных для исполнимой практики общего SQL;
- `day_01_relational_basics.sql` — таблицы, типы, `NULL` и DDL;
- `day_02_keys_relationships.sql` — keys, constraints и связи;
- `day_03_dml_select.sql` — DML и базовый `SELECT`;
- `day_04_joins_subqueries_cte.sql` — joins, set operations, subqueries и CTE;
- `day_05_aggregates_windows.sql` — aggregation и window functions;
- `day_06_normalization_views.sql` — normalization, views и materialized views;
- `day_06_erd.md` — первая самостоятельная ER-диаграмма;
- `day_07_database_prototype/` — итоговый PostgreSQL-прототип базы проекта.

## Учебная среда

SQL делится на два слоя:

1. Базовый переносимый SQL дней 1–5 можно выполнять в локальной SQLite через стандартный `sqlite3`. Это позволяет практиковаться без установки сервера.
2. PostgreSQL-specific DDL, `RETURNING`, materialized views и итоговый прототип пишутся в отдельных файлах и должны проверяться в PostgreSQL, когда безопасная локальная среда будет согласована перед активацией соответствующего дня.

SQLite не объявляется заменой PostgreSQL. У неё отличаются type enforcement, auto-generated identifiers, date/time behavior, functions, DDL и некоторые детали SQL. Каждый несовпадающий пример помечается.

Не устанавливать PostgreSQL, Docker или Python-драйвер заранее без отдельной необходимости. В день активации сначала проверить доступную среду и выбрать минимальный локальный способ.

## Порядок прохождения

1. Прочитать только назначенные разделы теории.
2. До выполнения запроса записать ожидаемые rows и причины.
3. Выполнить задания текущего дня в назначенном `.sql` или `.md` файле.
4. Проверить результат на fixture data.
5. Перед `UPDATE`/`DELETE` сначала выполнить эквивалентный `SELECT` с тем же `WHERE`.
6. Не применять destructive-команды к данным вне одноразовой учебной базы.
7. Заполнить самооценку и журнал запросов.
8. Написать: `Проверь день N недели 6`.
9. Самостоятельно исправить обязательные замечания.
10. Получить явный статус в `ASSESSMENT.md`.

Один учебный день может занять несколько реальных дней. Итоговую ER-диаграмму можно уточнять после замечаний, но нельзя начинать Django models до завершения SQL-этапа.

## Границы сложности

На этой неделе не требуются:

- установка или администрирование production PostgreSQL;
- роли, grants, row-level security и управление пользователями БД;
- транзакционные isolation levels и блокировки — неделя 7;
- индексы, `EXPLAIN` и оптимизация — неделя 7;
- MVCC, WAL, `VACUUM`, TOAST, partitioning и sharding — неделя 8;
- stored procedures, functions и triggers — неделя 8;
- PostGIS — осознанный обзор будет на неделе 8;
- Django models, migrations и ORM — недели 9–10;
- production data migration;
- рекурсивные CTE сложнее одного понятного примера;
- сложные `GROUPING SETS`, `CUBE`, `ROLLUP`;
- полнотекстовый поиск, JSONB schema design и массивы;
- физическое проектирование и расчёт storage size.

## Оценивание

| Критерий | Баллы |
|---|---:|
| Корректность результата | 0–3 |
| Выполнение условий задания | 0–2 |
| Граничные и ошибочные сценарии | 0–2 |
| Читаемость и имена | 0–1 |
| Понимание и самооценка | 0–1 |
| Самостоятельность исправлений | 0–1 |

Для следующего дня требуется минимум 7/10 без критической ошибки. Для итогового прототипа — минимум 8/10.

## Критические ошибки

- `UPDATE` или `DELETE` запускается без осознанного `WHERE` в неодноразовой таблице;
- `TRUNCATE ... CASCADE` используется как обычная очистка;
- пользовательский ввод объединяется со SQL строкой;
- `NULL` сравнивается через `= NULL` или `<> NULL`;
- порядок rows предполагается без `ORDER BY`;
- join condition отсутствует случайно и создаёт Cartesian product;
- `LEFT JOIN` неосознанно превращается в `INNER JOIN` условием в `WHERE`;
- агрегат смешивает столбцы разных уровней детализации и даёт неверный результат;
- many-to-many хранится списком identifiers в текстовом поле;
- foreign key отсутствует там, где требуется referential integrity;
- деньги хранятся в floating-point типе;
- вычисляемые итоги дублируются без правила согласованности;
- view и materialized view считаются одним и тем же;
- физическое удаление уничтожает требуемую историю финансовой операции;
- `is_active` объявляется универсальной заменой корректной deletion/audit policy без анализа;
- итоговая ERD не совпадает с DDL по tables, keys или cardinality;
- seed/check script изменяет данные вне учебной базы;
- ученик не может объяснить получившееся количество rows после join/grouping.

## Критерий завершения

- все дни имеют минимум 7/10;
- итоговый PostgreSQL-прототип имеет минимум 8/10;
- закрыты критические замечания;
- уверенно отвечено минимум на 18 из 24 контрольных вопросов;
- схема содержит осмысленные primary/foreign keys и constraints;
- все three relationship types показаны и объяснены;
- `NULL` используется только для действительно неизвестного/неприменимого значения;
- DML безопасен и проверяется до изменения;
- joins и aggregates дают ожидаемую cardinality;
- минимум три window queries объяснены по partition/order/frame;
- нормализация и две возможные денормализации разобраны с trade-offs;
- ERD, PostgreSQL DDL и документация согласованы;
- подготовлены запросы для каталога, лучших поставщиков, Offer и статистики;
- ученик может объяснить, какие invariants защищает БД, а какие останутся application layer.

## Официальные материалы

- [PostgreSQL tutorial](https://www.postgresql.org/docs/current/tutorial.html);
- [SQL language](https://www.postgresql.org/docs/current/sql.html);
- [Data types](https://www.postgresql.org/docs/current/datatype.html);
- [Constraints](https://www.postgresql.org/docs/current/ddl-constraints.html);
- [Queries](https://www.postgresql.org/docs/current/queries.html);
- [Window functions](https://www.postgresql.org/docs/current/tutorial-window.html);
- [Common Table Expressions](https://www.postgresql.org/docs/current/queries-with.html);
- [Views](https://www.postgresql.org/docs/current/sql-createview.html);
- [Materialized views](https://www.postgresql.org/docs/current/rules-materializedviews.html);
- [TRUNCATE](https://www.postgresql.org/docs/current/sql-truncate.html).

## Текущий статус

Неделя 6 только подготовлена. Не заполнять решения, ERD и журнал до допуска из недели 5.
