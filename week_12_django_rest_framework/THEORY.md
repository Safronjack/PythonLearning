# Теория недели 12: Django REST Framework

Статус: **читать после допуска из недели 11**.

Этот конспект объясняет не набор классов DRF, а полный путь HTTP-запроса. Главная мысль недели: HTTP-слой принимает и проверяет внешние данные, но не забирает у service право владеть бизнес-операцией.

## 1. Зачем нужен Django REST Framework

Обычный Django уже умеет принимать запрос и возвращать `JsonResponse`. DRF добавляет согласованный набор инструментов для API:

- `Request` с разобранным телом запроса;
- serializers для преобразования и проверки данных;
- `Response` и content negotiation;
- generic views, mixins, ViewSets и routers;
- permissions, filtering и pagination;
- единообразные API errors;
- удобные API tests;
- основу для OpenAPI schema.

DRF не заменяет Django ORM, database constraints и services. Он располагается на HTTP-границе системы.

```text
HTTP request
  -> URL/router
  -> authentication/permissions
  -> parser
  -> serializer validation
  -> selector/service/ORM
  -> serializer representation
  -> renderer
  -> HTTP response
```

## 2. `Request`: входящие данные

DRF передаёт view объект `rest_framework.request.Request`. Внутри него остаётся обычный Django request, но появляется удобный API:

- `request.data` — разобранное тело независимо от JSON, form или multipart parser;
- `request.query_params` — query string; это более ясное имя для `request.GET`;
- `request.user` — пользователь после authentication;
- `request.auth` — дополнительные данные механизма authentication;
- `request.method`, `request.headers` — HTTP metadata.

Не смешивайте источники:

```python
page_size = request.query_params.get("page_size")
name = request.data.get("name")
```

Query parameters управляют выборкой. Body описывает создаваемый или изменяемый resource.

## 3. Parsers, renderers и content negotiation

Parser превращает bytes из request body в Python values. `JSONParser` разбирает JSON. Если клиент прислал неподдерживаемый `Content-Type`, корректный ответ — `415 Unsupported Media Type`.

Renderer делает обратное: превращает данные `Response` в JSON или другое представление. DRF выбирает renderer по заголовку `Accept`. Если подходящего renderer нет, возможен `406 Not Acceptable`.

Не следует вручную вызывать `json.loads(request.body)` в DRF view и не следует заранее превращать `Response` в JSON-строку.

## 4. `Response`

`Response` получает простые Python-данные, а renderer формирует HTTP body:

```python
from rest_framework.response import Response
from rest_framework.views import APIView


class HealthView(APIView):
    def get(self, request):
        return Response({"status": "ok"}, status=200)
```

Возвращаемые данные должны состоять из типов, которые способен обработать renderer. Model instance сам по себе таким contract не является — его представляет serializer.

## 5. Serialization и deserialization

Serialization — преобразование внутренних объектов в response representation. Deserialization — проверка входных primitives и подготовка `validated_data`.

```python
serializer = CarMakeSerializer(data=request.data)
serializer.is_valid(raise_exception=True)
make = serializer.save()
return Response(CarMakeSerializer(make).data, status=201)
```

Важно различать:

- `initial_data` — то, что прислал клиент;
- `validated_data` — проверенные Python values после `is_valid()`;
- `instance` — существующий или созданный объект;
- `data` — готовое внешнее представление;
- `errors` — ошибки validation.

Нельзя использовать непроверенный `initial_data` для записи в database.

## 6. `Serializer` и `ModelSerializer`

`Serializer` требует явно описать поля и `create()`/`update()`. Он удобен для команд, не совпадающих с одной model.

`ModelSerializer` может вывести fields и validators из Django model и подходит для простого CRUD. Однако он не отменяет осознанный API contract.

```python
class CarMakeSerializer(serializers.ModelSerializer):
    class Meta:
        model = CarMake
        fields = ("id", "code", "name", "country", "is_active")
        read_only_fields = ("id",)
```

Для public API запрещено полагаться на `fields = "__all__"`: новое внутреннее поле model может случайно стать публичным.

## 7. Read-only, write-only и relations

- `read_only=True` — поле возвращается клиенту, но не принимается для записи;
- `write_only=True` — поле принимается, но не возвращается;
- relation ID удобен для записи;
- nested object удобен для чтения.

Можно разделить эти contracts:

```python
make_id = serializers.PrimaryKeyRelatedField(
    source="make",
    queryset=CarMake.objects.filter(is_active=True),
    write_only=True,
)
make = CarMakeSummarySerializer(read_only=True)
```

Writable nested serializers сложнее: нужно определить create/update/delete semantics дочерних объектов. На этой неделе они запрещены.

## 8. Четыре уровня validation

Validation не должна быть свалена в одно место.

1. Field-level validation проверяет одно поле: формат `code`, положительность числа.
2. Object-level validation проверяет связь нескольких входов: `min_price <= max_price`.
3. Database constraints окончательно защищают uniqueness и целостность при concurrency.
4. Service validation охраняет бизнес-переход: достаточно ли stock и balance для закупки.

```python
def validate_code(self, value):
    normalized = value.strip().upper()
    if not normalized:
        raise serializers.ValidationError("Code must not be blank.", code="blank_code")
    return normalized
```

Serializer validation не является автоматическим вызовом полного `model.full_clean()`. Кроме того, проверка uniqueness перед INSERT подвержена race condition, поэтому database constraint всё равно нужен.

## 9. Object-level validation

Метод `validate(self, attrs)` получает уже преобразованные values.

```python
def validate(self, attrs):
    min_price = attrs.get("min_price")
    max_price = attrs.get("max_price")
    if min_price is not None and max_price is not None and min_price > max_price:
        raise serializers.ValidationError(
            {"max_price": "Must be greater than or equal to min_price."},
            code="invalid_price_range",
        )
    return attrs
```

Для update нужно помнить об instance: отсутствующее поле PATCH означает «оставить старое», а не `None`.

## 10. `PUT` и `PATCH`

- `PUT` обычно означает полную замену изменяемого representation;
- `PATCH` — частичное изменение;
- для PATCH serializer создаётся с `partial=True`;
- omitted field не должен очищаться;
- явно переданный `null` обрабатывается по `allow_null`.

`partial=True` ослабляет required checks отсутствующих fields, но не должен отключать business invariants. При cross-field validation берите отсутствующее значение из `self.instance`, если оно нужно для проверки.

## 11. `create()`, `update()` и services

Простой reference CRUD можно реализовать через `ModelSerializer`. Но serializer не должен повторять сложную atomic business operation.

Граница недели:

- `CarMake`/`CarModel`: простой CRUD через serializer допустим;
- procurement: serializer проверяет HTTP input и вызывает принятый service;
- inventory/balances/movements: не открываются обычным `ModelViewSet`.

Если одно правило должно работать из API, admin action, management command и будущей Celery task, его место — service.

## 12. `APIView`

`APIView` близок к обычной Django view, но добавляет DRF Request/Response, permissions, authentication, exception handling и content negotiation.

Он полезен для необычного endpoint с явно написанным flow. Цена — pagination/filtering/queryset behavior придётся подключать вручную.

## 13. `GenericAPIView`

`GenericAPIView` добавляет:

- `queryset` и `serializer_class`;
- `get_queryset()` и `get_serializer()`;
- filtering и pagination hooks;
- lookup behavior.

Внутри request flow используйте `get_queryset()`, а не прямое вычисление `self.queryset`. QuerySet, вычисленный как class attribute, может закэшироваться неподходящим образом.

## 14. Mixins

Mixins реализуют отдельные actions:

- `ListModelMixin`;
- `RetrieveModelMixin`;
- `CreateModelMixin`;
- `UpdateModelMixin`;
- `DestroyModelMixin`.

Комбинация `GenericAPIView` и нужных mixins делает разрешённые операции явными. Не подключайте mixin «на всякий случай».

## 15. ViewSets

ViewSet группирует related actions в одном классе. Router связывает HTTP methods и actions:

```text
GET collection -> list
POST collection -> create
GET detail -> retrieve
PUT detail -> update
PATCH detail -> partial_update
DELETE detail -> destroy
```

`ReadOnlyModelViewSet` содержит только `list` и `retrieve`. `ModelViewSet` содержит полный CRUD. Для catalog нужен read-only вариант; для staff reference data — полный CRUD с переопределённым `destroy()` для deactivation.

ViewSet экономит повторение и делает API последовательным, но скрывает часть routing. Ученик должен уметь назвать action для каждого method/path.

## 16. Routers и names

Router генерирует URL patterns и route names. Обычно:

```python
router.register("makes", CarMakeViewSet, basename="make")
```

Names вроде `make-list` и `make-detail` лучше получать через `reverse()`, а не собирать строками. `basename` нужен, если router не может вывести его из `queryset`, например когда используется только `get_queryset()`.

Trailing slash — часть API convention. Выберите правило и зафиксируйте его tests/schema.

## 17. Authentication и permissions

Authentication отвечает «кто это?». Permission отвечает «разрешено ли ему действие?».

На этой неделе:

- global default — authenticated access: безопасная fail-closed настройка;
- public catalog явно получает `AllowAny` и read-only ViewSet;
- reference CRUD получает `IsAdminUser`;
- authentication по умолчанию остаётся session/basic только для учебной проверки;
- JWT и детальные роли появятся позже.

Стандартный `IsAdminUser` проверяет `user.is_staff`. Он не проверяет отдельные Django model permissions и не реализует object-level policy. Более узкие права появятся на следующем этапе курса.

При SessionAuthentication небезопасные методы для вошедшего пользователя требуют CSRF. `force_authenticate()` полезен в unit-style API tests, но не доказывает работу реального authentication/CSRF path.

## 18. Soft delete

Reference row может уже использоваться во внешних ключах и истории. Поэтому DELETE этой недели означает деактивацию:

```python
def perform_destroy(self, instance):
    instance.is_active = False
    instance.save(update_fields=("is_active",))
```

Нужны проверки:

- row осталась в database;
- public queryset её больше не возвращает;
- повторный DELETE имеет заранее выбранное поведение;
- historical relations не повреждены.

## 19. Filtering через `django-filter`

`FilterSet` задаёт typed и allowlisted query parameters. Это надёжнее ручного набора `request.query_params` по всей view.

```python
class CatalogFilter(filters.FilterSet):
    min_price = filters.NumberFilter(field_name="price", lookup_expr="gte")
    max_price = filters.NumberFilter(field_name="price", lookup_expr="lte")
```

Неверный filter input должен дать контролируемый `400`, а не игнорироваться и не приводить к `500`.

Filter backends применяются не только к list, но и к queryset retrieve. Поэтому detail resource может вернуть `404`, если существует, но не удовлетворяет указанному filter. Это нужно понимать и либо принять как contract, либо ограничить filtering для retrieve.

## 20. Search

`SearchFilter` даёт простой text search по явному `search_fields`. Search — не замена точному filter.

Проверяйте:

- Latin и Unicode text;
- несколько слов;
- пустую строку;
- поля relations через `make__name`;
- отсутствие внутренних полей в search surface.

## 21. Ordering

`OrderingFilter` должен иметь `ordering_fields`. Без allowlist клиент может сортировать по полям, которые не должны быть частью public contract.

Pagination требует deterministic order. Одной цены недостаточно, если несколько rows равны. Добавьте tie-breaker:

```python
queryset.order_by("price", "pk")
```

Для descending price tie-breaker тоже должен быть явно определён contract.

## 22. Pagination

На неделе используется bounded page-number pagination:

- default page size;
- query parameter `page_size`;
- жёсткий `max_page_size`;
- стабильная ordering;
- стандартный envelope `count`, `next`, `previous`, `results`.

DRF автоматически вызывает pagination для generic views и ViewSets. В обычном `APIView` pagination надо вызывать вручную.

Page-number pagination проста, но `count()` и большие offsets могут стоить дорого. Cursor pagination изучается позже; для неё особенно важна уникальная стабильная ordering.

## 23. Serializers и N+1

Serializer, читающий `item.car_model.make.name`, может инициировать relation query на каждый row. Исправление делается в queryset/selector:

- `select_related()` для foreign key/one-to-one;
- `prefetch_related()` для many relations;
- annotations для aggregates;
- измерение вокруг фактического `response.data`, потому что QuerySet ленивый.

Сравните N=2 и N=20. Цель — constant query budget, а не «на моём компьютере быстро».

## 24. HTTP status codes недели

- `200 OK` — успешные list/retrieve/update;
- `201 Created` — resource создан;
- `204 No Content` — успешная deactivation через DELETE без body;
- `400 Bad Request` — validation/filter error;
- `401 Unauthorized` — credentials отсутствуют/не приняты для соответствующего authenticator;
- `403 Forbidden` — identity известна, но permission не позволяет;
- `404 Not Found` — resource не видна или не существует;
- `405 Method Not Allowed` — route существует, method запрещён;
- `406 Not Acceptable` — нет renderer для `Accept`;
- `415 Unsupported Media Type` — нет parser для `Content-Type`.

Конкретное различие 401/403 зависит от authentication classes. Не пишите test на интуицию — зафиксируйте выбранную конфигурацию.

## 25. Exceptions и единый error envelope

DRF преобразует ожидаемые исключения в HTTP response. Проект добавляет custom exception handler, чтобы клиент получал стабильную форму:

```json
{
  "error": {
    "code": "validation_error",
    "message": "Request validation failed.",
    "details": {"code": [{"message": "...", "code": "unique"}]},
    "request_id": "..."
  }
}
```

Нельзя потерять machine-readable error codes. Используйте данные DRF `ErrorDetail`/`get_full_details()`, а не только human text.

## 26. Неожиданные ошибки

Ожидаемая validation error безопасно возвращается клиенту. Неожиданная programming/database error должна:

- дать generic client message;
- не раскрыть traceback, SQL, credentials и внутренние paths;
- попасть в server log с correlation/request ID;
- сохранить исходное exception handling behavior.

Для единого JSON contract допустима отдельная non-debug policy: записать exception с context в server log и вернуть generic envelope со статусом `500`, не включая детали исключения. Не оборачивайте каждую view в `except Exception: return 400`. Это скрывает дефекты и ложно обвиняет клиента.

## 27. OpenAPI

OpenAPI — machine-readable описание endpoints:

- paths и methods;
- parameters;
- request body;
- responses и schemas;
- authentication requirements.

Swagger UI — интерфейс для просмотра и ручного вызова schema. UI не является самой schema и не заменяет tests.

## 28. `drf-spectacular`

Инструмент выводит schema из `queryset`, `serializer_class`, views, filters и pagination. Чем точнее базовые declarations, тем меньше ручных annotations.

Рабочий порядок:

1. корректные `queryset`/`serializer_class`;
2. generated schema;
3. разбор warnings;
4. `@extend_schema` только для информации, которую introspection не знает;
5. повторная validation;
6. comparison с runtime tests.

Annotation не чинит неправильное runtime behavior. Нельзя описать `201`, если view возвращает `200`.

## 29. Schema validation и runtime audit

Schema validation проверяет структуру OpenAPI и часть consistency. Но дополнительно вручную сопоставьте:

```text
path | method | permission | request schema | response status/schema | filters | pagination | runtime test
```

Особенно легко пропустить custom error envelope, soft-delete semantics и различия PUT/PATCH.

## 30. DRF API tests

`APIClient` умеет отправлять JSON и читать DRF responses:

```python
response = client.post(url, payload, format="json")
self.assertEqual(response.status_code, status.HTTP_201_CREATED)
```

Проверяйте не только status:

- response keys/types;
- database state;
- отсутствие forbidden fields;
- permission matrix;
- repeated request;
- media type;
- query count.

## 31. Тестирование updates и delete

Для PATCH создайте resource с несколькими значениями, измените одно и убедитесь, что остальные сохранились. Для PUT проверьте выбранный full-update contract. Для DELETE проверьте `is_active=False` и сохранность row.

## 32. Contract tests

Contract test отвечает на вопрос: «Сохранился ли обещанный внешний интерфейс?» Он фиксирует минимум:

- route name/path;
- allowed methods;
- required request fields;
- response keys/types;
- error envelope;
- permissions;
- pagination envelope.

Не обязательно сравнивать весь огромный JSON literal. Лучше явно проверить важные fields и отсутствие секретных/internal fields.

## 33. Что будет дальше

Неделя 12 намеренно не завершает API security:

- неделя 13: authentication, JWT lifecycle и registration/email flow;
- неделя 14: object permissions, roles, ownership и abuse protection;
- недели 15–16: более глубокая test strategy;
- позже: Redis, Celery, Docker и production.

Сейчас задача — качественный transport contract поверх уже защищённого domain/service слоя.

## 34. Типичные ошибки

- `fields = "__all__"` в public serializer;
- обращение к `request.data` без serializer;
- сложная business operation внутри `perform_create()`;
- полный `ModelViewSet` для balance/inventory/history;
- физическое удаление reference row;
- отсутствие `ordering_fields`;
- pagination по нестабильной ordering;
- N+1 во время построения `serializer.data`;
- `except Exception` с ответом 400;
- потеря DRF validation codes;
- Swagger annotation, не соответствующая runtime;
- `force_authenticate()` как единственное доказательство security flow.

## 35. Вопросы для самопроверки

1. Где заканчивается parser и начинается serializer?
2. Чем `validated_data` отличается от `data`?
3. Почему `ModelSerializer` не отменяет database constraint?
4. Как PATCH должен работать с omitted field?
5. Для чего нужен `get_queryset()`?
6. Чем `ReadOnlyModelViewSet` безопаснее полного `ModelViewSet` для каталога?
7. Почему procurement нельзя реализовать обычным serializer `.save()`?
8. Что генерирует router?
9. Чем authentication отличается от permission?
10. Почему DELETE справочника деактивирует row?
11. Чем filter отличается от search?
12. Зачем `ordering_fields` и tie-breaker?
13. Почему pagination может изменить стоимость запроса?
14. В какой момент измерять query count?
15. Чем `406` отличается от `415`?
16. Почему error code полезнее одного текста?
17. Что нельзя показывать при неожиданном exception?
18. Почему валидная OpenAPI schema ещё не доказывает корректность API?

## Официальные источники

- [Django REST Framework: Requests](https://www.django-rest-framework.org/api-guide/requests/)
- [Django REST Framework: Serializers](https://www.django-rest-framework.org/api-guide/serializers/)
- [Django REST Framework: Generic views](https://www.django-rest-framework.org/api-guide/generic-views/)
- [Django REST Framework: ViewSets](https://www.django-rest-framework.org/api-guide/viewsets/)
- [Django REST Framework: Filtering](https://www.django-rest-framework.org/api-guide/filtering/)
- [Django REST Framework: Pagination](https://www.django-rest-framework.org/api-guide/pagination/)
- [Django REST Framework: Exceptions](https://www.django-rest-framework.org/api-guide/exceptions/)
- [django-filter: Integration with DRF](https://django-filter.readthedocs.io/en/stable/guide/rest_framework.html)
- [drf-spectacular: Workflow and customization](https://drf-spectacular.readthedocs.io/en/latest/customization.html)
