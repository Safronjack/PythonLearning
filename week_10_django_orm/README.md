# Неделя 10: Django ORM

Статус: **подготовлена заранее и заблокирована до полного зачёта недели 9**.

На этой неделе каркас Django Foundation превращается в предметную модель системы автосалонов. Главная задача — научиться переводить бизнес-правила в таблицы, связи, ограничения, миграции и объяснимые ORM-запросы. Любой важный QuerySet нужно уметь связать с ожидаемым SQL и количеством обращений к базе.

Итог недели — воспроизводимый ORM-прототип на PostgreSQL: каталог автомобилей, автосалоны, поставщики, остатки, предложения покупателей, продажи, закупки и акции. API, JWT, Celery, Redis и Docker появятся позже.

## Результат недели

После завершения модуля ученик умеет:

- переводить сущности и связи предметной области в Django models;
- выбирать поля, `null`, `blank`, `default`, `choices` и `on_delete` осознанно;
- использовать абстрактную базовую model для общих технических полей;
- моделировать `ForeignKey`, `OneToOneField` и `ManyToManyField` с явной `through`-model;
- управлять прямыми и обратными связями через `related_name`;
- создавать schema migrations и безопасные обратимые data migrations;
- читать план миграций и SQL через `showmigrations`, `migrate --plan` и `sqlmigrate`;
- понимать ленивость QuerySet, момент его вычисления и кэширование результата;
- писать custom `QuerySet` и manager без скрытого исчезновения данных;
- применять `F`, `Q`, `annotate`, `aggregate`, `values`, `exists` и `update`;
- измерять N+1 и выбирать `select_related` либо `prefetch_related` по типу связи;
- задавать `CheckConstraint`, `UniqueConstraint` и индексы под доказанные запросы;
- выполнять связанные изменения внутри `transaction.atomic()`;
- защищать конкурентное изменение остатка через `select_for_update()`;
- объяснить назначение ORM и отличия Django ORM от SQLAlchemy Core/ORM;
- обзорно объяснить `Session`, `flush`, `commit`, result methods и Alembic.

## Предварительные требования

- Недели 0–9 завершены полностью.
- Итоговый Django Foundation недели 9 принят минимум на 8/10.
- В `week_09_django_foundation/ASSESSMENT.md` указано: «Допуск к неделе 10: да».
- Custom user уже создан до первой migration.
- Django подключён к отдельной учебной PostgreSQL database.
- Ученик умеет читать SQL, понимает транзакции, индексы и MVCC на уровне недель 6–8.

## Версии и зависимости

Модуль продолжает проект недели 9 и ориентируется на **Django 5.2 LTS** с Python 3.11 и PostgreSQL. Перед фактическим началом наставник повторно проверяет актуальные patch-версии и security advisories.

Новые зависимости заранее не устанавливаются. После допуска разрешается добавить только то, что действительно нужно моделям недели:

- `django-countries` — для стандартизированного поля страны из исходного задания;
- уже согласованный PostgreSQL driver из недели 9.

SQLAlchemy и Alembic в этой неделе изучаются обзорно. Их не нужно устанавливать и нельзя подключать к migrations Django-проекта.

## Продолжение проекта недели 9

В начале активной недели ученик создаёт `day_07_django_orm/` как продолжение **принятого** проекта `week_09_django_foundation/day_07_django_foundation/`. Способ переноса фиксируется в журнале: новая Git branch, аккуратная копия учебного каталога или согласованный общий рабочий каталог.

Канонический код недели 10 находится только в:

```text
week_10_django_orm/day_07_django_orm/
```

Проект недели 9 после зачёта не переписывается задним числом.

## Предметная область недели

Минимальный набор сущностей:

| App | Models | Ответственность |
|---|---|---|
| `common` | `TimeStampedActiveModel` | абстрактные технические поля |
| `accounts` | существующий `User`, `BuyerProfile` | пользователь, подтверждение email и профиль покупателя |
| `catalog` | `CarMake`, `CarModel`, `CarSpecification` | марки, модели и характеристики автомобилей |
| `dealerships` | `DealershipProfile`, `DealershipPreference`, `DealershipInventory` | данные салона, предпочтения и остатки |
| `suppliers` | `SupplierProfile`, `SupplierCatalogItem`, `SupplierLoyaltyDiscount`, `BestSupplierChoice` | поставщик, ассортимент, лояльность и сохранённый выбор |
| `trading` | `Offer`, `Purchase`, `Sale`, `StockMovement`, `BalanceMovement` | предложения и неизменяемая история сделок, товара и денег |
| `promotions` | `DealershipPromotion`, `SupplierPromotion` | скидки продавцов и область их действия |
| `analytics` | без обязательной model | запросы статистики; таблицы не создаются без необходимости |

`DealershipInventory` и `SupplierCatalogItem` — не «технические» join tables: они хранят данные самой связи. Поэтому именно они становятся явными промежуточными models для M2M.

Список лучших поставщиков не вычисляется и не сохраняется вручную в случайном JSON-поле. `BestSupplierChoice` хранит выбранного поставщика для пары «автосалон + модель», рассчитанную цену, причину и время расчёта. Сам периодический пересчёт появится вместе с Celery; на этой неделе проектируются integrity rules и обычный ORM-запрос.

### Обязательные общие поля

Все конкретные предметные models получают через абстрактную базу:

- `is_active`;
- `created_at`;
- `updated_at`.

`accounts.User` уже наследует `is_active` от `AbstractUser`, поэтому нельзя повторно объявлять конфликтующий field через вторую model base. В неделю 10 ему явно добавляются `created_at` и `updated_at`; существующий `date_joined` сохраняет auth-смысл и не подменяет требуемые поля. Остальные предметные models наследуют общую abstract base.

Исторические сущности `Sale`, `Purchase`, `StockMovement` и `BalanceMovement` не должны исчезать из обычных запросов только из-за деактивации связанного справочника. Физическое удаление и каскады выбираются особенно осторожно.

### Деньги и проценты

- деньги хранятся в `DecimalField`, не во `float`;
- денежные значения неотрицательны;
- процент скидки ограничен диапазоном от 0 до 100 включительно;
- итоговая цена не хранится повторно без доказанной необходимости;
- округление и currency policy записываются явно.

По исходному заданию все денежные операции выполняются в USD. На этой стадии допускается единая documented currency `USD` без мультивалютной конвертации; числовое значение всё равно хранится через `DecimalField`.

## Что хранится, а что вычисляется

- Балансы профилей хранятся для быстрых проверок, но каждое изменение подтверждается immutable `BalanceMovement`.
- Текущий остаток хранится в `DealershipInventory`/`SupplierCatalogItem`, а изменение подтверждается `StockMovement` или исторической purchase/sale row.
- История продаж и закупок хранится как snapshot price/quantity, чтобы изменение текущего прайса не переписывало прошлое.
- Статистика покупателей, салонов и поставщиков вычисляется QuerySet/aggregation, а не дублируется без необходимости.
- Preferred models/specifications являются явными relations, а не строкой со списком.
- Выбор лучшего поставщика хранится отдельно, потому что исходное задание требует актуальный список и причину выбора; источник истины для цены всё равно остаётся supplier catalog/promotions.

## Структура модуля

- [THEORY.md](THEORY.md) — теория, небольшие примеры, прогнозы и самопроверка;
- [PRACTICE.md](PRACTICE.md) — семь подробных дней и итоговый audit;
- [ASSESSMENT.md](ASSESSMENT.md) — оценки, ошибки, пересдачи и допуск;
- [notes.md](notes.md) — словарь, прогнозы и вопросы ученика;
- `day_01_models_fields.md` — карта models, полей и принятых решений;
- `day_02_relationships.md` — матрица связей и результаты related-access;
- `day_03_migrations.md` — журнал schema/data migrations и clean replay;
- `day_04_querysets_managers.md` — журнал QuerySet и manager;
- `day_05_expressions_aggregates.md` — запросы с `F`, `Q` и агрегатами;
- `day_06_performance_transactions.md` — N+1, планы, индексы и блокировки;
- `day_07_django_orm/` — накапливаемый Django-проект недели;
- `day_07_django_orm/SCHEMA_MAP.md` — итоговая карта таблиц и бизнес-правил;
- `day_07_django_orm/ORM_COMPARISON.md` — обзор Django ORM, SQLAlchemy и Alembic.

## Целевое дерево итогового проекта

Ученик дополняет существующие apps; точные номера migration-файлов определяются фактической историей:

```text
day_07_django_orm/
├── manage.py
├── README.md
├── config/
├── accounts/
│   ├── models.py
│   └── migrations/
├── catalog/
│   ├── models.py
│   └── migrations/
├── common/
│   └── models.py
├── dealerships/
│   ├── models.py
│   ├── management/commands/seed_orm_demo.py
│   └── migrations/
├── suppliers/
│   ├── models.py
│   └── migrations/
├── trading/
│   ├── models.py
│   ├── services.py
│   └── migrations/
├── promotions/
│   ├── models.py
│   └── migrations/
├── analytics/
│   └── queries.py
├── SCHEMA_MAP.md
└── ORM_COMPARISON.md
```

Дополнительные файлы разрешены, если их обязанность объяснима. Большой `models.py` можно делить на package только после появления реальной проблемы, а не ради внешнего вида.

## Порядок прохождения

1. Получить допуск из недели 9.
2. Подтвердить версии и сделать backup учебной database.
3. Создать рабочую branch и перенести принятый Django Foundation.
4. Читать только теорию текущего дня.
5. До запуска записывать прогнозы в дневной журнал.
6. Изменять накапливаемый проект маленькими migration-safe шагами.
7. Запускать обязательные сценарии и сохранять фактические результаты.
8. Заполнить самооценку.
9. Написать: `Проверь день N недели 10`.
10. Самостоятельно исправить обязательные замечания.

## Безопасность данных

- Работать только с отдельной учебной database.
- Перед destructive migration или reset явно проверить host, database name и user.
- Не выполнять `flush`, `dropdb`, удаление migration-файлов или истории без отдельного согласования.
- Не менять применённую migration задним числом: создавать следующую.
- Data migration использует historical models через `apps.get_model()`.
- В миграцию не помещать сетевые запросы, чтение случайного local state и импорт текущей model.
- `select_for_update()` проверять внутри транзакции и на PostgreSQL, а не делать вывод по SQLite.
- Не хранить пароли, DSN, email реальных людей и production dumps.

## Границы недели

На неделе 10 не требуются:

- REST API, serializers и DRF views;
- JWT, регистрация и email confirmation;
- формы основного пользовательского интерфейса;
- Celery, Redis и фоновые задачи;
- Docker и deployment;
- pytest как новый инструмент, если он ещё не введён; разрешены штатные Django tests;
- repository pattern поверх ORM только ради дополнительного слоя;
- generic foreign keys для связи promotions;
- database triggers и stored procedures;
- sharding и read replicas;
- production data migration на реальном наборе данных;
- практическая реализация второй версии проекта на SQLAlchemy.

## Оценивание

| Критерий | Баллы |
|---|---:|
| Корректность результата | 0–3 |
| Выполнение условий задания | 0–2 |
| Граничные и ошибочные сценарии | 0–2 |
| Читаемость и структура | 0–1 |
| Понимание и самооценка | 0–1 |
| Самостоятельность исправлений | 0–1 |

Для следующего дня нужно минимум 7/10 без критической ошибки. Для итогового ORM-прототипа — минимум 8/10.

## Критические ошибки

- migrations применены к непроверенной или неучебной database;
- применённая migration переписана или удалена вместо создания новой;
- data migration импортирует текущую model и ломает replay истории;
- деньги сохраняются во `float`;
- отрицательный остаток, цена или число единиц допускаются основным сценарием;
- уникальность составной связи проверяется только Python-кодом без database constraint;
- custom default manager скрывает данные так, что administrative или related operations становятся неверными, а решение не объяснено;
- N+1 объявлен исправленным без измерения количества запросов;
- `select_related` и `prefetch_related` выбраны без учёта типа связи;
- read-modify-write остатка выполняется без атомарности и допускает потерянное обновление;
- `select_for_update()` вызывается вне рабочей транзакции, а защита заявлена как доказанная;
- исключение целостности или нехватки остатка проглатывается;
- ожидаемый результат выдан за фактически проверенный.

## Критерий завершения

- все шесть учебных дней имеют минимум 7/10;
- итоговый ORM-проект имеет минимум 8/10;
- полный набор migrations разворачивается на чистой учебной database;
- data migration выполняется вперёд и назад либо необратимость осознанно оформлена и обоснована;
- все обязательные constraints существуют в database schema;
- связи и `on_delete` защищены минимум одним обычным и одним граничным сценарием;
- custom QuerySet и manager имеют понятную область ответственности;
- ключевые QuerySet дают правильные результаты на неоднозначных данных;
- N+1 воспроизведён, измерен и устранён с фиксированным query budget;
- индекс обоснован конкретным фильтром/сортировкой и проверкой плана;
- конкурентное уменьшение остатка не приводит к отрицательному значению или потерянному обновлению;
- `SCHEMA_MAP.md` соответствует фактическим models и constraints;
- `ORM_COMPARISON.md` отвечает на все обзорные вопросы из источника;
- минимум 23 из 30 контрольных вопросов отвечены уверенно;
- в `ASSESSMENT.md` указано: «Допуск к неделе 11: да».

## Официальные материалы

- [Models](https://docs.djangoproject.com/en/5.2/topics/db/models/);
- [Model field reference](https://docs.djangoproject.com/en/5.2/ref/models/fields/);
- [Making queries](https://docs.djangoproject.com/en/5.2/topics/db/queries/);
- [QuerySet API](https://docs.djangoproject.com/en/5.2/ref/models/querysets/);
- [Managers](https://docs.djangoproject.com/en/5.2/topics/db/managers/);
- [Query expressions](https://docs.djangoproject.com/en/5.2/ref/models/expressions/);
- [Aggregation](https://docs.djangoproject.com/en/5.2/topics/db/aggregation/);
- [Migrations](https://docs.djangoproject.com/en/5.2/topics/migrations/);
- [Migration operations](https://docs.djangoproject.com/en/5.2/ref/migration-operations/);
- [Constraints](https://docs.djangoproject.com/en/5.2/ref/models/constraints/);
- [Indexes](https://docs.djangoproject.com/en/5.2/ref/models/indexes/);
- [Database transactions](https://docs.djangoproject.com/en/5.2/topics/db/transactions/);
- [Database access optimization](https://docs.djangoproject.com/en/5.2/topics/db/optimization/);
- [django-countries documentation](https://github.com/SmileyChris/django-countries);
- [SQLAlchemy ORM quick start](https://docs.sqlalchemy.org/en/20/orm/quickstart.html);
- [SQLAlchemy Session basics](https://docs.sqlalchemy.org/en/20/orm/session_basics.html);
- [SQLAlchemy result API](https://docs.sqlalchemy.org/en/20/core/connections.html#sqlalchemy.engine.Result);
- [Alembic tutorial](https://alembic.sqlalchemy.org/en/latest/tutorial.html).

## Текущий статус

Неделя 10 только подготовлена. Текущий активный этап остаётся в `week_00_basics/ASSESSMENT.md`. До допуска из недели 9 не переносить Django-проект, не устанавливать новые зависимости и не применять migrations недели 10.
