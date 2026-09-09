# Теория недели 11: первый вертикальный Django-сценарий

Читайте только разделы, назначенные текущему дню в `PRACTICE.md`. Код в примерах демонстрирует одну идею и не является готовым решением итогового проекта.

## 1. От таблиц к пользовательскому сценарию

После недели 10 отдельные models и QuerySet могут работать, но это ещё не доказывает, что система выполняет полезное действие. Вертикальный срез отвечает на конкретный вопрос: может ли сотрудник завести предложение поставщика, провести закупку и увидеть новый товар через HTTP-каталог?

Полезный use case описывается четырьмя частями:

1. **Вход:** какие identifiers и значения приходят.
2. **Предусловия:** что обязано быть истинно до изменения.
3. **Результат:** какие данные создаются и изменяются.
4. **Ошибки:** какие ожидаемые отказы возможны и что остаётся неизменным.

Пример контракта закупки:

```text
Input: dealership_id, supplier_item_id, units
Preconditions: active entities, units > 0, enough supplier stock and dealership balance
Success: Purchase + movements; both stocks and balances updated
Expected failures: missing entity, inactive entity, insufficient stock, insufficient money
Atomicity: on every failure, no partial state remains
```

### Прогноз

1. Достаточно ли проверить balance перед `transaction.atomic()`?
2. Должен ли management command самостоятельно менять inventory?
3. Может ли правильный JSON скрывать N+1?

## 2. Архитектурные границы

Граница помогает одному компоненту иметь одну основную причину изменения.

- Admin меняется при изменении staff workflow.
- Command меняется при изменении CLI contract.
- Service меняется при изменении бизнес-операции.
- Selector меняется при изменении read model/query.
- View меняется при изменении HTTP contract.
- Test меняется, когда меняется проверяемый contract.

Если один и тот же расчёт закупки скопирован в admin, command и view, исправление правила придётся повторять трижды. Поэтому внешние границы собирают input и вызывают один service.

```python
def handle(self, *args, **options):
    result = procure_inventory(
        dealership_id=options["dealership_id"],
        supplier_item_id=options["supplier_item_id"],
        units=options["units"],
    )
    self.stdout.write(self.style.SUCCESS(f"Purchase {result.purchase_id}"))
```

Command знает про CLI output, но не про SQL implementation service.

## 3. Contract first

До code полезно составить таблицу:

```text
Scenario | Input | Expected state | Expected error | Observable evidence
```

Это предотвращает две типичные ошибки:

- implementation случайно определяет требования задним числом;
- проверяется только happy path, а rollback и границы забываются.

Contract не обязан быть огромным. Он обязан быть однозначным. Например, `units=0` либо invalid input, либо осмысленная no-op операция. Для закупки выбираем invalid input, потому что создание пустой истории не несёт смысла.

## 4. Django admin — внутренний интерфейс

Django admin предназначен для trusted staff operations и управления models. Это не public frontend и не API для внешних клиентов.

Доступ требует:

- authenticated user;
- `is_staff=True`;
- model permissions для конкретных actions;
- CSRF protection для state-changing forms.

`is_staff` разрешает вход в admin, но не автоматически даёт все model permissions. Superuser обходит обычные permission checks, поэтому тестировать только superuser недостаточно.

### Что admin не гарантирует

- Он не заменяет database constraints.
- Он не является отдельной authorization policy всего продукта.
- Он не делает длинный workflow атомарным автоматически.
- Он не предотвращает гонку, если custom action использует read-modify-write без lock.

## 5. Полезный `ModelAdmin`

Небольшая настройка делает staff workflow проверяемым:

```python
@admin.register(CarModel)
class CarModelAdmin(admin.ModelAdmin):
    list_display = ("code", "name", "make", "is_active")
    list_filter = ("is_active", "make")
    search_fields = ("code", "name", "make__name")
    readonly_fields = ("created_at", "updated_at")
```

- `list_display` показывает поля для решения задачи.
- `list_filter` добавляет предсказуемые фильтры.
- `search_fields` определяет server-side search lookups.
- `readonly_fields` защищает технические или исторические значения от обычного form editing.
- `autocomplete_fields` помогает выбирать relation при большом справочнике, но target admin должен иметь `search_fields`.
- `list_select_related` может устранить N+1 на change list для foreign keys.

Не добавляйте methods в `list_display`, которые для каждой row выполняют отдельный query. Admin тоже может иметь N+1.

## 6. История в admin

`Purchase`, `StockMovement` и `BalanceMovement` — следствие service operation. Разрешить staff произвольно менять сумму или ссылку задним числом значит разрушить audit trail.

На учебной стадии можно:

- зарегистрировать history models для просмотра;
- сделать meaningful fields read-only;
- запретить обычное добавление и удаление через ModelAdmin;
- оставить filters/search для расследования операции.

Это UI-защита, а не абсолютная immutability. Более сильные database/audit механизмы рассматриваются отдельно. Но основной write path уже должен идти через service.

## 7. Validation в admin и constraints в database

ModelForm обычно запускает field/model validation. Однако constraint остаётся последней линией защиты для конкурирующих transactions, shell, command и прямого SQL.

Проверять нужно оба уровня:

- admin form показывает понятную ошибку пользователя;
- database не принимает invalid row при обходе формы.

Успешный `full_clean()` не сохраняет object. Обычный `save()` не вызывает `full_clean()` автоматически. Это ещё одна причина не считать Python validation единственной гарантией.

## 8. Custom management command

Command подходит для воспроизводимого ручного запуска внутреннего use case до появления полноценного API/Celery boundary.

Структура:

```text
app/
└── management/
    └── commands/
        └── procure_inventory.py
```

Command наследуется от `BaseCommand` и определяет:

- `help`;
- `add_arguments(parser)`;
- `handle(*args, **options)`.

Для output используются `self.stdout` и `self.stderr`, а не случайный `print()`: это упрощает tests и соответствует command framework.

Command обязан:

- разобрать identifiers и units;
- вызвать service ровно один раз;
- преобразовать ожидаемую domain error в понятный `CommandError`;
- вернуть короткий success result;
- не содержать копию transaction logic.

## 9. Service layer

Service — обычная Python function или небольшой class, выражающий use case. Он не обязан называться «service» ради архитектурной моды; здесь он полезен, потому что операция затрагивает несколько models и будет вызываться разными boundaries.

Хороший contract:

```python
@dataclass(frozen=True)
class ProcurementResult:
    purchase_id: int
    inventory_id: int
    units: int
```

Result не возвращает HTTP response и не печатает текст. Он даёт boundary минимальные данные для отображения.

Ожидаемые отказы получают конкретные domain exceptions:

```python
class InsufficientSupplierStock(Exception):
    pass

class InsufficientDealershipFunds(Exception):
    pass
```

Не ловите общий `Exception` и не превращайте любую programming/database ошибку в «недостаточно товара».

## 10. Порядок атомарной закупки

Пример reasoning, а не готовый code:

1. До transaction отвергнуть `units <= 0`.
2. Открыть `transaction.atomic()`.
3. В стабильном порядке заблокировать dealership balance, supplier balance/catalog item и inventory row.
4. Внутри lock повторно проверить active state, available quantity и balance.
5. Зафиксировать unit price/discount contract.
6. Создать `Purchase` snapshot.
7. Создать `StockMovement` для supplier/dealership sides.
8. Создать `BalanceMovement` debit/credit.
9. Изменить current stock и balances.
10. Вернуть result после успешного завершения atomic block.

Если inventory row ещё не существует, получение/создание под конкуренцией требует database uniqueness и обработки race. Один подход — заблокировать родительскую dealership row, затем `get_or_create()` inventory с unique constraint. Точный порядок фиксируется в `VERTICAL_SLICE.md`.

## 11. Цена закупки

Источник текущей базовой цены — `SupplierCatalogItem`. Supplier promotion и loyalty discount могут уменьшать цену. В этом срезе разрешены два варианта:

- обязательный базовый вариант использует `unit_price` catalog item;
- расширенный вариант вычисляет effective price из активной promotion/loyalty policy, если эти правила уже полностью определены и протестированы.

Нельзя частично внедрить discounts так, чтобы разные boundaries рассчитывали цену по-разному. `Purchase.unit_price` хранит snapshot фактически согласованной цены.

Стоимость:

```text
total = unit_price * units
```

вычисляется через `Decimal`. Dealership balance должен быть не меньше total. Равенство разрешает закупку и оставляет balance zero.

## 12. Lock ordering и deadlock

Две transactions могут блокировать одинаковые rows в разном порядке:

```text
T1: lock dealership -> wait supplier
T2: lock supplier -> wait dealership
```

Это создаёт deadlock cycle. PostgreSQL разорвёт его, откатив одну transaction. Риск уменьшается, если все services используют одинаковый документированный порядок locks, например:

1. profiles/balances по `(model label, pk)`;
2. catalog/inventory rows по `pk`;
3. history создаётся после проверок.

Transaction должна быть короткой. Нельзя держать lock во время network request, ввода пользователя, sleep или тяжёлого отчёта.

## 13. `transaction.on_commit`

Иногда после закупки нужно запустить email или Celery task. Если сделать это до commit, внешний side effect может произойти, а database transaction затем откатится.

```python
transaction.on_commit(lambda: notify_purchase(purchase_id))
```

Callback запускается только после успешного commit внешней transaction. На неделе 11 внешние задачи не отправляются, но ученик должен указать будущую точку интеграции. Logging результата можно выполнить после выхода из atomic block без callback, если service контролирует outer boundary.

В `TestCase` callbacks обычно не выполняются как обычный real commit, потому что test обёрнут transaction. Django предоставляет инструменты захвата callbacks; выбирать test type нужно осознанно.

## 14. Selector как read boundary

Selector — функция/QuerySet method для сложного read query. Он отделяет чтение каталога от HTTP formatting:

```python
def available_catalog():
    return (
        DealershipInventory.objects
        .active()
        .in_stock()
        .select_related("dealership", "car_model__make")
        .order_by("sale_price", "car_model__code", "dealership_id")
    )
```

View не должна заново фильтровать rows и строить relation queries в непредсказуемом цикле. Selector не должен возвращать `JsonResponse`: тогда его можно использовать из admin, command, DRF и tests.

## 15. Read model и shape результата

QuerySet model instances удобны, но HTTP contract лучше собирать явно. Возможны:

- model instances с заранее загруженными relations;
- `.values()` rows с документированными aliases;
- immutable dataclass DTOs.

Для первого среза допустим любой один объяснимый вариант. Важны:

- стабильные field names;
- понятные Python types;
- отсутствие lazy relation access после измеренного query scope;
- отсутствие лишних internal fields;
- одинаковое поведение пустого result.

Не создавайте сложную DTO architecture ради восьми полей. Но не передавайте наружу model `__dict__`.

## 16. N+1 внутри serialization

N+1 часто возникает не в selector line, а при построении dictionaries:

```python
for inventory in queryset:
    result.append({
        "make": inventory.car_model.make.name,
        "dealership": inventory.dealership.name,
    })
```

Поэтому query budget измеряется вокруг **полного materialization** результата, а не только вызова функции, вернувшей ленивый QuerySet.

Правильный experiment:

1. Создать N=2 rows.
2. Внутри query-count context построить `list` JSON-ready records.
3. Записать count и SQL roles.
4. Повторить при N=20.
5. Убедиться, что count не растёт с N.

Если endpoint prefetches collections, фиксированное число может быть больше одного. Цель — constant query budget, а не магическое число 1.

## 17. `JsonResponse`

`JsonResponse` кодирует Python data в JSON и по умолчанию ожидает dictionary:

```python
return JsonResponse({"count": len(results), "results": results})
```

Если передать list на верхнем уровне, требуется `safe=False`, но envelope object удобнее расширять и остаётся контрактом недели.

Нельзя передавать ленивый QuerySet напрямую. Его нужно превратить в JSON-ready primitive data: dict, list, string, integer, boolean, null.

## 18. Деньги, даты и JSON

JSON number не хранит информацию о decimal precision так, как `Decimal`. Для денежного API-контракта недели price возвращается строкой с двумя decimal places:

```json
{"price": "25000.00"}
```

Это не означает, что client никогда не сможет использовать numeric contract. Сейчас строка предотвращает незаметное превращение в binary float и делает формат явным.

Datetime передаётся как timezone-aware ISO 8601 string. В текущем catalog response timestamp не обязателен, поэтому не добавляйте его без пользовательской ценности.

## 19. HTTP methods и statuses

Read-only endpoint принимает `GET`. Decorator или явная проверка method возвращает `405 Method Not Allowed` для `POST`, `PUT`, `PATCH`, `DELETE`.

Базовые statuses недели:

- `200` — успешный catalog, включая пустой list;
- `405` — method не поддерживается;
- `500` — unexpected failure, но клиент не получает traceback/secrets.

Пустой каталог — не `404`: endpoint существует и возвращает коллекцию из нуля элементов.

## 20. URL namespace и versioning

URL можно организовать так:

```text
config.urls -> path("api/v1/catalog/", include(...))
```

или include на `api/v1/`, если app URLs содержат `catalog/`. Главное — один итоговый path без случайного duplicate segment.

Используйте `app_name` и named route, например `catalog:list`, чтобы tests делали `reverse()` вместо hard-coded path. `v1` фиксирует публичный contract; это не обещание никогда его не менять, а место для управляемой эволюции.

## 21. Тонкая view

View отвечает за HTTP:

1. принять request;
2. вызвать selector;
3. сформировать JSON-ready representation;
4. вернуть status/headers/body;
5. не раскрыть internal exception details.

View не должна:

- проводить procurement;
- создавать database schema;
- читать environment secrets;
- выполнять relation query в каждой iteration;
- содержать отдельную копию фильтров active/in-stock;
- ловить любой `Exception` и всегда возвращать `200`.

## 22. Уровни tests в этом срезе

### Model/constraint tests

Доказывают database invariants: nonnegative values, unique pair, valid ranges.

### Service integration tests

Проверяют несколько models и transaction: success, insufficient resource, forced rollback.

### Selector tests

Проверяют состав/ordering/read shape и query budget.

### HTTP tests

Через Django test client проверяют path, method, status, content type и JSON body.

### Admin tests

Проверяют login/staff/model permissions, registered pages и readonly behavior.

Один огромный test, который проверяет всё сразу, трудно диагностировать. Но хотя бы один end-to-end-like happy test должен пройти весь доступный путь.

## 23. `TestCase` и `TransactionTestCase`

`TestCase` быстрее и изолирует tests через transactions/savepoints. Это хороший default для models, views и большинства services.

`TransactionTestCase` допускает real commit/rollback behavior и нужен для некоторых transaction/locking scenarios, но работает медленнее и очищает database иначе.

Особенность: `select_for_update()` вне явного atomic block может казаться работающим внутри `TestCase`, потому что сам test уже обёрнут transaction. Нельзя этим случайно «доказать» production contract. Lock/concurrency behavior проверяется осознанным `TransactionTestCase` или отдельным two-connection experiment.

## 24. Arrange Act Assert

Test легче читать в трёх частях:

```text
Arrange: создать supplier item, dealership и balances
Act: вызвать procure_inventory(...)
Assert: проверить result, current state и history rows
```

Название test описывает observable rule:

```text
test_procurement_rolls_back_every_change_when_history_creation_fails
```

Не проверяйте implementation detail вроде количества локальных переменных. Проверяйте состояние и contract.

## 25. Test data

Test обязан владеть своими данными и не зависеть от development seed. Подходы:

- маленькие helper functions;
- `setUpTestData()` для неизменяемых общих objects;
- `setUp()` для state, которую test меняет;
- позже — factories/Faker, когда инструмент введён.

Данные должны быть неоднозначными:

- active и inactive;
- zero и positive quantity;
- одинаковые prices с tie-breaker;
- несколько dealerships/makes;
- достаточный и недостаточный balance.

## 26. Проверка `IntegrityError`

Если constraint test ожидает `IntegrityError`, database transaction становится broken до rollback. Внутри `TestCase` полезна вложенная atomic boundary:

```python
with self.assertRaises(IntegrityError):
    with transaction.atomic():
        create_invalid_row()

# Здесь внешний test transaction снова пригоден.
```

После exception нужно проверить, что invalid row не появилась. Не ловите исключение внутри того же atomic block и не продолжайте queries до rollback.

## 27. Query-count test

`assertNumQueries()` измеряет SQL в контексте:

```python
with self.assertNumQueries(expected_count):
    payload = list(build_catalog_records())
```

`list()` важен, если функция возвращает lazy QuerySet. Query budget включает только code внутри context, поэтому setup выполняется до него.

Хрупкость exact count уменьшается, если:

- contract selector узкий;
- auth/session queries не смешаны с чистым selector test;
- separately tested endpoint budget документирует дополнительные middleware/auth queries;
- test сравнивает N=2 и N=20;
- каждая ожидаемая query имеет объяснение.

Нельзя просто увеличить expected count после regression, не выяснив новую query.

## 28. HTTP contract test

Django test client вызывает URL без настоящего network server:

Проверяются:

- `reverse()` строит path;
- GET даёт `200`;
- `Content-Type` содержит JSON;
- top-level keys точны;
- count/results согласованы;
- price является string;
- ordering стабилен;
- inactive/zero-stock rows отсутствуют;
- POST даёт `405`;
- пустой catalog даёт `200` и пустой result.

Не сравнивайте огромную строку JSON целиком, если важен parsed structure.

## 29. Admin tests

Минимальные роли:

- anonymous;
- authenticated non-staff;
- staff без permission;
- staff с нужными permissions;
- superuser.

Проверки:

- anonymous перенаправляется на login;
- non-staff не получает admin access;
- staff permission влияет на view/add/change/delete;
- history model cannot be mutated through documented UI;
- catalog and supplier forms сохраняют valid data;
- invalid form показывает error и не создаёт row.

Не нужно тестировать внутренний HTML Django до последнего CSS class. Проверяйте status, permissions, form errors и database effect.

## 30. Logging как наблюдаемое поведение

Используйте namespaced logger:

```python
logger = logging.getLogger(__name__)
```

Полезное procurement success event:

```text
event=procurement.completed operation_id=... purchase_id=... dealership_id=... supplier_item_id=... units=...
```

Expected business failure может быть `warning` или `info` по принятой policy; unexpected infrastructure failure — `exception`/`error` с traceback в server logs, но без secret context.

Не логируются:

- password/token/cookie;
- full DSN/environment;
- raw request body;
- полный profile/email без необходимости;
- balance «до и после», если это создаёт лишний sensitive trail без цели.

Tests через `assertLogs()` проверяют event name и safe identifiers. Не привязывайтесь ко всему format string, если formatter не является contract.

## 31. Operation ID и request ID

Request ID из middleware недели 9 связывает HTTP logs одного запроса. Procurement command не имеет HTTP request, поэтому создаёт operation ID на boundary или service entry.

Identifier должен:

- быть уникальным для операции;
- присутствовать в start/success/failure events;
- возвращаться command operator при необходимости;
- не использовать password/email как часть значения.

Это ещё не полноценная distributed tracing system. Цель — восстановить одну операцию по logs.

## 32. Migration hygiene вертикального среза

Неделя 11 в основном использует schema недели 10. Если implementation обнаружила недостающее поле или constraint:

1. записать причину;
2. изменить model;
3. создать новую migration;
4. прочитать operations/SQL;
5. проверить forward и clean replay;
6. не редактировать старую применённую migration.

Команда `makemigrations --check --dry-run` в CI-like проверке доказывает, что model state не забыта без migration. Она не доказывает корректность data migration или business behavior.

## 33. Clean replay

Воспроизводимость означает, что другой разработчик способен:

1. создать isolated database;
2. передать безопасные settings;
3. применить полную migration chain;
4. создать staff user или test fixture;
5. добавить reference data через admin/seed;
6. выполнить procurement command;
7. получить catalog JSON;
8. запустить tests.

Ручное добавление column через SQL или незафиксированная запись в development database нарушает clean replay.

## 34. Что переносится на неделю 12

Текущий endpoint намеренно маленький. На DRF-неделе появятся:

- serializers и явная validation representation;
- APIView/generic views/ViewSet;
- routers;
- pagination;
- filtering/search/ordering;
- единый error schema;
- OpenAPI.

Week 11 должна оставить стабильный selector и documented JSON contract, чтобы DRF менял HTTP layer, а не переписывал business rules.

## 35. Вопросы самопроверки

1. Что делает сценарий вертикальным срезом?
2. Какие четыре части есть у use-case contract?
3. Почему command не должен менять inventory самостоятельно?
4. Чем selector отличается от service?
5. Почему admin не является public API?
6. Чем `is_staff` отличается от superuser permissions?
7. Как `list_select_related` связан с N+1 в admin?
8. Почему historical rows read-only в обычном admin workflow?
9. Вызывает ли `save()` `full_clean()` автоматически?
10. Что должен делать `CommandError`?
11. Зачем service возвращает небольшой result object?
12. Какие ошибки являются domain errors, а какие нельзя скрывать?
13. Где повторно проверяются stock и balance?
14. Зачем `Purchase` хранит snapshot unit price?
15. Что происходит при равенстве balance и total?
16. Как одинаковый lock order уменьшает deadlock risk?
17. Почему network call запрещён внутри transaction?
18. Зачем нужен `transaction.on_commit()`?
19. Почему selector не возвращает `JsonResponse`?
20. Где именно измерять N+1 при lazy QuerySet?
21. Почему постоянный budget важнее «ровно один запрос»?
22. Почему верхний JSON envelope удобнее bare list?
23. Почему price возвращается строкой?
24. Какой status возвращает пустой catalog?
25. Зачем URL name и `reverse()`?
26. Что делает view тонкой?
27. Чем model test отличается от service integration test?
28. Когда нужен `TransactionTestCase`?
29. Зачем вложенный `atomic()` в constraint test?
30. Почему test data не берётся из development seed?
31. Что проверяет query-count test при N=2 и N=20?
32. Какие данные запрещено помещать в logs?
