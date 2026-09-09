# Неделя 11: первый вертикальный Django-сценарий

Статус: **подготовлена заранее и заблокирована до полного зачёта недели 10**.

Эта неделя соединяет отдельные знания о Django и ORM в один работающий путь от ввода данных до HTTP-ответа. Администратор создаёт марку, модель автомобиля, поставщика и позицию каталога поставщика; автосалон закупает автомобиль через атомарный service; read-only endpoint возвращает доступный каталог без N+1; migrations, constraints, admin, logging и tests доказывают корректность пути.

Это первый вертикальный срез, а не попытка закончить весь проект. Он должен быть маленьким, полностью работающим и объяснимым на каждом слое.

## Что такое вертикальный срез

Горизонтальная работа создаёт слой целиком: «сначала все models», затем «все services», затем «все views». Вертикальный срез проводит один пользовательский сценарий через нужную часть каждого слоя:

```text
admin input
    -> validated models and database constraints
    -> procurement service and transaction
    -> inventory state and immutable history
    -> optimized catalog selector
    -> JSON view
    -> integration tests and logs
```

Ценность среза в том, что результат можно запустить и проверить end-to-end, а архитектурные границы проверяются реальным потоком данных.

## Итоговый сценарий

1. Staff user через Django admin создаёт `CarMake` и `CarModel`.
2. Staff user создаёт `SupplierProfile` и `SupplierCatalogItem`.
3. Подготовленный `DealershipProfile` закупает выбранное количество через management command, который вызывает один service.
4. Service внутри `transaction.atomic()` блокирует нужные rows, повторно проверяет остаток и баланс, создаёт `Purchase`, движения денег/товара и обновляет текущие balances/inventory.
5. `GET /api/v1/catalog/` возвращает только активные позиции с положительным остатком.
6. Selector заранее загружает одиночные и коллекционные relations без N+1.
7. Tests доказывают success, rollback, constraints, HTTP contract и неизменный query budget при росте числа позиций.
8. Logs позволяют восстановить outcome по identifiers, но не содержат secrets или лишние персональные данные.

## Результат недели

После завершения ученик умеет:

- формулировать use case через вход, результат, ошибки и инварианты;
- отделять input boundary, service, selector и HTTP presentation;
- настраивать ModelAdmin для рабочих справочников и связей;
- понимать, почему admin не заменяет business service и public API;
- делать historical models read-only в обычном admin workflow;
- создавать management command как тонкую границу над service;
- применять `transaction.atomic()` и `select_for_update()` в реальной закупке;
- обновлять balances/stock только вместе с immutable movement rows;
- использовать `transaction.on_commit()` для будущих внешних side effects;
- возвращать стабильный JSON envelope через `JsonResponse`;
- сериализовать `Decimal` как строку и timestamps в ISO 8601;
- писать selector, который не печатает, не знает о HTTP и не скрывает N+1;
- измерять query count штатными Django test tools;
- различать unit-like service test, integration test и HTTP contract test;
- проверять database constraints и rollback без повреждения test transaction;
- добавлять структурированные безопасные logs с request/operation ID;
- воспроизводить вертикальный путь на чистой PostgreSQL database.

## Предварительные требования

- Недели 0–10 завершены полностью.
- Все дни недели 10 имеют минимум 7/10.
- Итоговый ORM-прототип недели 10 принят минимум на 8/10.
- Полная migration chain недели 10 разворачивается на чистой PostgreSQL database.
- N+1 и конкурентная продажа недели 10 фактически проверены.
- В `week_10_django_orm/ASSESSMENT.md` указано: «Допуск к неделе 11: да».

## Версии и зависимости

Неделя продолжает Django-проект и набор direct dependencies, принятые на неделе 10. Для Python 3.11 roadmap ориентируется на поддерживаемую ветку **Django 5.2 LTS**. Перед фактическим началом наставник повторно проверяет актуальную patch-версию и security advisories.

Новые обязательные dependencies не добавляются:

- HTTP endpoint использует встроенный `JsonResponse`;
- tests запускаются штатным Django test runner;
- query budget проверяется `assertNumQueries()` или `CaptureQueriesContext`;
- logging использует стандартный Python/Django logging;
- management command использует встроенный command framework.

Django Debug Toolbar допускается позже как удобный development-инструмент, но не является условием зачёта и не устанавливается только ради этой недели.

## Продолжение проекта недели 10

После допуска ученик переносит **принятый** проект:

```text
week_10_django_orm/day_07_django_orm/
```

в рабочую область:

```text
week_11_first_vertical_slice/day_07_vertical_slice/
```

Способ переноса и source commit фиксируются в `day_01_slice_contract.md`. Проект недели 10 не переписывается задним числом.

## Архитектурные границы

| Компонент | Делает | Не делает |
|---|---|---|
| `ModelAdmin` | ввод/поиск справочных данных, staff UI | не содержит длинную procurement transaction |
| management command | разбирает CLI arguments, вызывает service, отображает outcome | не дублирует business rules |
| `procurement_service` | проверяет use case, блокирует rows, атомарно меняет состояние | не формирует HTTP response |
| selector | строит оптимизированный read query и документирует result shape | не изменяет database |
| JSON view | проверяет method, вызывает selector, собирает response | не содержит ORM-цикл с дополнительными queries |
| tests | доказывают contracts, rollback и query budget | не зависят от порядка запуска и внешней database |
| logging | фиксирует событие, identifiers, outcome и duration | не пишет passwords, tokens, request body и полные персональные данные |

## HTTP-контракт недели

Пока используется один read-only endpoint:

```text
GET /api/v1/catalog/
```

Успешный ответ имеет envelope:

```json
{
  "count": 1,
  "results": [
    {
      "inventory_id": 42,
      "car_code": "skoda-octavia-7",
      "make": "Skoda",
      "model": "Octavia",
      "dealership": "Central Auto",
      "country": "GE",
      "price": "25000.00",
      "quantity": 3
    }
  ]
}
```

Это пример формата, а не готовое решение. Обязательные правила:

- верхний уровень — JSON object, поэтому `safe=False` не нужен;
- `price` — decimal string, а не binary float;
- `count` равен длине `results` для текущего непагинированного endpoint;
- выводятся только активные dealership/inventory/car model/make с `quantity > 0`;
- ordering детерминирован: price, car code, dealership id либо другой заранее записанный эквивалент;
- неизвестные internal fields, balances, supplier cost и персональные данные не возвращаются;
- `POST` и другие неподдерживаемые methods дают корректный `405`;
- DRF pagination/filtering/error schema появятся на неделе 12.

## Структура модуля

- [THEORY.md](THEORY.md) — теория вертикального среза, admin, services, JSON, tests и logging;
- [PRACTICE.md](PRACTICE.md) — семь подробных практических дней;
- [ASSESSMENT.md](ASSESSMENT.md) — оценки, ошибки, пересдачи и допуск;
- [notes.md](notes.md) — прогнозы и вопросы ученика;
- `day_01_slice_contract.md` — контракт, flow и baseline audit;
- `day_02_admin_catalog.md` — проверки admin и permissions;
- `day_03_procurement_service.md` — transaction/movement experiments;
- `day_04_catalog_selector.md` — SQL и N+1 measurements;
- `day_05_json_endpoint.md` — HTTP contract experiments;
- `day_06_tests_logging.md` — test matrix, logs и clean replay;
- `day_07_vertical_slice/` — накапливаемый Django-проект недели;
- `day_07_vertical_slice/VERTICAL_SLICE.md` — итоговая карта потока;
- `day_07_vertical_slice/TEST_MATRIX.md` — итоговая матрица проверок.

## Целевое дерево изменений

Точный models layout наследуется из принятой недели 10. Новые и существенно изменяемые файлы недели 11:

```text
day_07_vertical_slice/
├── manage.py
├── README.md
├── config/
│   ├── settings.py                  # logging config без secrets
│   └── urls.py                      # include catalog API URLs
├── catalog/
│   ├── admin.py                     # make/model/spec admin
│   ├── selectors.py                 # optimized catalog QuerySet
│   ├── urls.py                      # namespaced endpoint
│   ├── views.py                     # thin JsonResponse view
│   └── tests/
├── suppliers/
│   ├── admin.py                     # supplier and catalog item admin
│   └── tests/
├── dealerships/
│   ├── admin.py                     # profile/inventory admin
│   └── management/commands/
│       └── procure_inventory.py     # thin CLI boundary
├── trading/
│   ├── admin.py                     # read-only operational history
│   ├── services.py                  # procurement use case
│   └── tests/
├── VERTICAL_SLICE.md
└── TEST_MATRIX.md
```

Если tests остаются в одном `tests.py`, это допустимо для маленького app. Деление на package выполняется только при реальной необходимости и должно сохранять discovery штатного runner.

## Порядок прохождения

1. Получить допуск из недели 10.
2. Подтвердить source commit и отдельную учебную PostgreSQL database.
3. Создать working branch и перенести принятый ORM project.
4. Пройти baseline checks до изменений.
5. Читать только теорию текущего дня.
6. Записывать прогноз до команды или HTTP request.
7. Реализовывать один проходящий slice за раз.
8. Запускать узкие tests, затем regression suite.
9. Заполнять дневную самооценку.
10. Писать: `Проверь день N недели 11`.

## Безопасность и сохранность

- Работать только с учебной PostgreSQL database и test database Django.
- Не использовать production dump, реальные email, tokens или balances.
- Не добавлять `.env`, database URL или secret key в Git/logs.
- Не удалять migration history и не переписывать применённые migrations.
- Не отключать admin authentication/CSRF.
- Не выдавать обычному user staff/superuser flags ради прохождения теста.
- Не логировать passwords, Authorization/Cookie headers, raw request body и полный environment.
- Не выполнять network call внутри transaction.
- Не удерживать row locks во время input/output или sleep.
- Не запускать concurrency test на production-like shared database.
- Не объявлять query budget проверенным без фактического измерения.

## Границы недели

На неделе 11 не требуются:

- Django REST Framework, serializers, ViewSet, routers и OpenAPI;
- JWT, регистрация и подтверждение email;
- полноценная object-level authorization model;
- Celery, message broker, Redis и periodic procurement;
- автоматический выбор лучшего поставщика;
- обработка buyer Offer целиком;
- frontend или JavaScript client;
- pagination, search и произвольные public filters;
- Docker, Gunicorn, Nginx и deployment;
- pytest/Faker как новые зависимости;
- Debug Toolbar как обязательная зависимость;
- signals для procurement или logging основной сделки;
- raw SQL ради обхода неосвоенного ORM;
- абсолютное число SQL queries, скопированное из ТЗ без измерения своей реализации.

## Оценивание

| Критерий | Баллы |
|---|---:|
| Корректность результата | 0–3 |
| Выполнение условий задания | 0–2 |
| Граничные и ошибочные сценарии | 0–2 |
| Читаемость и архитектурные границы | 0–1 |
| Понимание и самооценка | 0–1 |
| Самостоятельность исправлений | 0–1 |

Для следующего дня нужно минимум 7/10 без критической ошибки. Для итогового vertical slice — минимум 8/10.

## Критические ошибки

- работа начата без принятого проекта недели 10 или на непроверенной database;
- admin доступен анонимному/non-staff user или CSRF отключён;
- business transaction продублирована в command/admin/view вместо одного service;
- procurement частично меняет stock/balance/history при исключении;
- supplier stock, dealership balance или другой invariant становится отрицательным;
- row lock берётся вне transaction либо после изменения зависимого состояния;
- исторические movements редактируются/удаляются обычным admin workflow;
- endpoint возвращает supplier cost, balances, secrets или лишние персональные данные;
- Decimal превращается в float и теряет денежный контракт;
- endpoint выполняет N+1, а query count не измерен;
- test подключается к development/production database вместо isolated test database;
- `IntegrityError` ломает внешний test transaction из-за неверной границы обработки;
- logs содержат password, token, cookie, DSN или raw request body;
- ожидаемый test/query result выдан за фактически полученный.

## Критерий завершения

- все шесть учебных дней имеют минимум 7/10;
- итоговый день имеет минимум 8/10;
- admin создаёт catalog/supplier records и защищён staff authentication;
- procurement command вызывает один service и не дублирует rules;
- successful procurement согласованно обновляет supplier stock, dealership stock/balance, supplier balance и immutable history;
- insufficient stock/balance и forced exception не оставляют partial state;
- catalog endpoint соблюдает documented JSON contract;
- inactive/zero-stock records не попадают в public result;
- query budget измерен при малом и увеличенном dataset и не растёт с N;
- migrations отсутствуют либо только обоснованно добавлены и проходят clean replay;
- `makemigrations --check --dry-run` не обнаруживает забытых model changes;
- admin, service, selector, endpoint и regression tests проходят;
- logs проверены на success/failure и отсутствие sensitive fields;
- `VERTICAL_SLICE.md` соответствует фактическому code flow;
- `TEST_MATRIX.md` содержит фактические результаты 32 сценариев;
- минимум 24 из 32 вопросов защиты отвечены уверенно;
- в `ASSESSMENT.md` указано: «Допуск к неделе 12: да».

## Официальные материалы

- [Django admin site](https://docs.djangoproject.com/en/5.2/ref/contrib/admin/);
- [Admin actions](https://docs.djangoproject.com/en/5.2/ref/contrib/admin/actions/);
- [Custom management commands](https://docs.djangoproject.com/en/5.2/howto/custom-management-commands/);
- [Database transactions](https://docs.djangoproject.com/en/5.2/topics/db/transactions/);
- [QuerySet API](https://docs.djangoproject.com/en/5.2/ref/models/querysets/);
- [Database optimization](https://docs.djangoproject.com/en/5.2/topics/db/optimization/);
- [Request and response objects](https://docs.djangoproject.com/en/5.2/ref/request-response/);
- [View decorators](https://docs.djangoproject.com/en/5.2/topics/http/decorators/);
- [URL dispatcher](https://docs.djangoproject.com/en/5.2/topics/http/urls/);
- [Testing overview](https://docs.djangoproject.com/en/5.2/topics/testing/overview/);
- [Testing tools](https://docs.djangoproject.com/en/5.2/topics/testing/tools/);
- [Advanced testing topics](https://docs.djangoproject.com/en/5.2/topics/testing/advanced/);
- [Django logging](https://docs.djangoproject.com/en/5.2/topics/logging/);
- [How to configure logging](https://docs.djangoproject.com/en/5.2/howto/logging/).

## Текущий статус

Неделя 11 только подготовлена. Текущий активный этап остаётся в `week_00_basics/ASSESSMENT.md`: день 2 недели 0. До допуска из недели 10 не переносить Django-проект, не устанавливать зависимости и не запускать migrations недели 11.
