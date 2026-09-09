# Неделя 12: Django REST Framework

Статус: **подготовлена заранее и заблокирована до полного зачёта недели 11**.

На этой неделе обычный JSON endpoint первого вертикального среза превращается в документированный API на Django REST Framework. Важно не просто заменить `JsonResponse` на `Response`, а понять путь данных: parser → serializer validation → view/action → service или ORM → serializer representation → renderer.

Итог недели — безопасный DRF API: публичный read-only каталог, staff-only CRUD двух справочников, filtering/search/ordering/pagination, единый error envelope, OpenAPI schema и Swagger UI. Business services, selectors и database invariants прошлых недель сохраняются.

## Результат недели

После завершения ученик умеет:

- объяснить обязанности DRF `Request`, parser, serializer, view и renderer;
- отличать serialization от deserialization и validation;
- использовать `Serializer` и `ModelSerializer` осознанно;
- задавать явный список fields, read-only/write-only relations и nested read representation;
- применять field-level, object-level и service-level validation по назначению;
- корректно обрабатывать различие `PUT` и `PATCH`;
- сравнивать `APIView`, `GenericAPIView`, mixins и ViewSet;
- выбирать `ReadOnlyModelViewSet` и `ModelViewSet` по API contract;
- регистрировать ViewSet через router и использовать named routes/reverse;
- применять fail-closed default permission, `AllowAny` для public read и `IsAdminUser` для staff CRUD;
- реализовывать soft delete/deactivation вместо физического удаления reference data;
- задавать `FilterSet`, `SearchFilter` и `OrderingFilter` с allowlist fields;
- ограничивать размер страницы и сохранять deterministic ordering;
- не возвращать N+1 после serialization и pagination;
- нормализовать DRF exceptions в единый error envelope без потери error codes;
- отличать `400`, `401`, `403`, `404`, `405`, `406` и `415`;
- генерировать и валидировать OpenAPI через `drf-spectacular`;
- проверять API через `APIClient` и сравнивать runtime behavior со schema;
- объяснить, что authentication/JWT и полноценная authorization policy появятся на неделях 13–14.

## Предварительные требования

- Недели 0–11 завершены полностью.
- Все дни недели 11 имеют минимум 7/10.
- Итоговый vertical slice недели 11 принят минимум на 8/10.
- Procurement service, catalog selector и query budgets недели 11 приняты.
- `GET /api/v1/catalog/` имеет зафиксированный response contract.
- В `week_11_first_vertical_slice/ASSESSMENT.md` указано: «Допуск к неделе 12: да».

## Версии и зависимости

Проект продолжает использовать Python 3.11, Django 5.2 LTS и PostgreSQL. Перед активацией наставник повторно проверяет актуальные совместимые patch-версии и security advisories.

Минимальные новые direct dependencies недели:

- Django REST Framework из совместимой поддерживаемой ветки 3.16;
- `django-filter`;
- `drf-spectacular`.

Не устанавливать зависимости при одной только подготовке модуля. После допуска:

1. определить фактический dependency format принятого проекта;
2. выбрать совместимые exact versions;
3. установить только в активное virtual environment;
4. зафиксировать direct/transitive distinction;
5. выполнить import/version/system checks;
6. не обновлять Django/PostgreSQL driver одновременно без отдельной причины.

`drf-spectacular-sidecar` можно рассмотреть позднее для локальных Swagger assets, но на этой неделе он не является обязательным.

## Продолжение проекта недели 11

После допуска переносится принятый проект:

```text
week_11_first_vertical_slice/day_07_vertical_slice/
```

в:

```text
week_12_django_rest_framework/day_07_drf_api/
```

Source commit/branch и baseline фиксируются в `day_01_drf_setup.md`. Week 11 не переписывается задним числом.

## API surface недели

### Публичный каталог

```text
GET /api/v1/catalog/
GET /api/v1/catalog/{inventory_id}/
```

Разрешены list/retrieve. В output отсутствуют balances, supplier cost, personal data и internal fields.

### Staff-only CRUD справочников

```text
GET|POST /api/v1/reference/makes/
GET|PUT|PATCH|DELETE /api/v1/reference/makes/{id}/

GET|POST /api/v1/reference/car-models/
GET|PUT|PATCH|DELETE /api/v1/reference/car-models/{id}/
```

`DELETE` означает documented deactivation через `is_active=False`, а не физическое удаление. Inactive object не появляется в обычных list/retrieve. Возврат того же unique business identifier требует отдельной restore policy, а не создания duplicate.

### Schema и документация

```text
GET /api/schema/
GET /api/docs/
```

Schema не содержит secrets/example credentials. Политика доступа к docs для production будет решаться позже; в учебном development environment endpoints доступны по зафиксированному contract.

## Разрешённые filters каталога

- точная марка или её ID/code по выбранному публичному contract;
- country code;
- `min_price`, `max_price`;
- dealership;
- полнотекстоподобный `search` по make/model/code через DRF `SearchFilter`;
- `ordering` только по price, make/model и одному безопасному стабильному identifier;
- `page` и ограниченный `page_size`.

Не разрешать клиенту arbitrary field lookup, raw ORM syntax или ordering по balance/supplier cost.

## Архитектурные границы

| Компонент | Обязанность | Не должен делать |
|---|---|---|
| serializer | преобразование и input validation | длинная multi-model transaction |
| FilterSet | validation/преобразование query parameters | возвращать private rows |
| ViewSet/action | HTTP orchestration, permission, serializer selection | копировать business service |
| router | URL wiring | определять business rules |
| catalog selector/queryset | visibility, joins/prefetch, deterministic read | зависеть от HTTP Response |
| reference service/model method | controlled create/update/deactivate rule | знать о renderer/OpenAPI |
| exception handler | нормализовать ожидаемые DRF errors | скрывать unexpected exception как `200`/`400` |
| schema annotations | уточнять contract, который не вывелся автоматически | документировать поведение, которого нет runtime |

## Validation layers

- **Field-level:** формат и правило одного значения, например non-empty normalized name.
- **Object-level:** согласованность нескольких input fields.
- **Database:** уникальность, checks и foreign key integrity.
- **Service-level:** mutable state, multi-row transaction и permissions/use-case preconditions.

Одно правило иногда существует на нескольких уровнях ради понятной ошибки и сильной целостности. Serializer error не заменяет constraint.

## Permission boundary недели

До JWT используется session-based test/staff authentication из Django/DRF.

- global default — fail closed, то есть authenticated access;
- public catalog явно переопределяет permission на `AllowAny` и остаётся read-only;
- reference CRUD использует `IsAdminUser`;
- balances, inventory, purchases, movements и supplier operational rows не получают обычный ModelViewSet;
- object-level RBAC/ABAC и ownership rules подробно изучаются на неделе 14.

`force_authenticate()` полезен для узкого view test, но хотя бы один integration test должен пройти настоящий authentication/permission path.

## Response contracts

Catalog list использует page envelope:

```json
{
  "count": 2,
  "next": null,
  "previous": null,
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

Общий error envelope:

```json
{
  "error": {
    "code": "validation_error",
    "message": "Request validation failed.",
    "details": {
      "max_price": [
        {"message": "Ensure this value is greater than or equal to 0.", "code": "min_value"}
      ]
    },
    "request_id": "..."
  }
}
```

Точный wording message может меняться/переводиться, поэтому client contract опирается прежде всего на stable code, status и details shape.

## Структура модуля

- [THEORY.md](THEORY.md) — serializers, views, routers, filters, errors и OpenAPI;
- [PRACTICE.md](PRACTICE.md) — семь подробных дней;
- [ASSESSMENT.md](ASSESSMENT.md) — оценки, errors, retries и допуск;
- [notes.md](notes.md) — прогнозы, glossary и вопросы;
- `day_01_drf_setup.md` — dependency/settings/request-response experiments;
- `day_02_serializers.md` — serializer contracts и validation matrix;
- `day_03_views_viewsets.md` — comparison APIView/generics/mixins/ViewSet;
- `day_04_routers_crud.md` — routes, permissions и reference CRUD;
- `day_05_filtering_pagination.md` — filters/search/order/pages/query budgets;
- `day_06_errors_openapi.md` — error envelope, schema validation и tests;
- `day_07_drf_api/` — накопительный project;
- `day_07_drf_api/API_CONTRACT.md` — endpoints, request/response/errors;
- `day_07_drf_api/OPENAPI_AUDIT.md` — runtime↔schema verification;
- `day_07_drf_api/TEST_MATRIX.md` — итоговые scenarios.

## Целевое дерево изменений

```text
day_07_drf_api/
├── manage.py
├── README.md
├── config/
│   ├── settings.py                 # REST_FRAMEWORK and SPECTACULAR_SETTINGS
│   └── urls.py                     # API/router/schema/docs
├── common/
│   └── api/
│       ├── exceptions.py           # one safe error envelope
│       └── pagination.py           # bounded page-number policy
├── catalog/
│   ├── selectors.py                # preserved optimized queryset
│   ├── api/
│   │   ├── filters.py              # explicit catalog FilterSet
│   │   ├── serializers.py          # catalog and reference serializers
│   │   ├── views.py                # catalog + staff reference ViewSets
│   │   └── urls.py                 # router registration
│   └── tests/
├── API_CONTRACT.md
├── OPENAPI_AUDIT.md
└── TEST_MATRIX.md
```

Если reference serializers/views выделены в отдельный module, это допустимо. Не создавать десятки файлов без ясной обязанности.

## Порядок прохождения

1. Получить допуск недели 11.
2. Зафиксировать source/environment/database и green baseline.
3. Согласовать exact dependency versions.
4. Читать только теорию текущего дня.
5. До запроса записывать prediction.
6. Делать маленький API change и узкий test.
7. После каждого дня запускать regression suite недели 11.
8. Заполнять самооценку.
9. Писать: `Проверь день N недели 12`.
10. Самостоятельно исправлять mandatory замечания.

## Безопасность

- Не использовать real credentials/users/data в tests/examples/schema.
- Не добавлять `.env`, tokens, passwords или Authorization headers в Git/logs.
- Не ставить глобально `AllowAny`.
- Не использовать `ModelSerializer(fields="__all__")` для public API.
- Не открывать write actions catalog public ViewSet.
- Не давать reference CRUD non-staff user.
- Не отключать CSRF для SessionAuthentication ради работающего request.
- Не передавать raw exception/traceback/database message клиенту.
- Не разрешать arbitrary ordering/filter fields.
- Ограничить `page_size`; отрицательные/огромные values дают safe behavior.
- Не возвращать QuerySet/model `__dict__` напрямую.
- Не документировать endpoint, которого нет runtime.

## Границы недели

На неделе 12 не требуются:

- registration, email confirmation, password reset и JWT;
- SimpleJWT;
- полная RBAC/ABAC/PBAC policy;
- buyer Offer write API;
- procurement/purchase API;
- balance/inventory direct CRUD;
- writable nested serializers;
- bulk create/update;
- file uploads;
- async DRF views;
- Celery, Redis, broker и caching;
- API version negotiation beyond URL prefix `v1`;
- production CORS/CSRF/deployment tuning;
- custom renderer/media type;
- GraphQL;
- pytest/Faker как новые обязательные tools.

## Оценивание

| Критерий | Баллы |
|---|---:|
| Корректность результата | 0–3 |
| Выполнение условий | 0–2 |
| Граничные и ошибочные scenarios | 0–2 |
| Читаемость и API boundaries | 0–1 |
| Понимание и самооценка | 0–1 |
| Самостоятельность исправлений | 0–1 |

Для следующего дня нужно минимум 7/10 без critical error. Итоговый API — минимум 8/10.

## Критические ошибки

- работа начата без допуска/accepted week 11 baseline;
- dependency versions не проверены либо установлены не в то environment;
- global `AllowAny` открывает write endpoints;
- public ViewSet позволяет изменить/delete operational data;
- serializer exposes balance, supplier price/cost, secret или private field;
- serializer создаёт multi-model transaction вместо service;
- database constraint считается ненужным из-за serializer validation;
- PATCH затирает omitted fields или object validation падает из-за отсутствующего key;
- DELETE физически удаляет reference/history despite `is_active` policy;
- arbitrary filter/order field exposes private data or expensive query;
- pagination имеет unlimited client page size;
- N+1 возвращается после serializer/filter/pagination и не измерен;
- exception handler превращает unexpected errors в misleading `400`/`200`;
- raw database/traceback details возвращаются клиенту;
- runtime response и OpenAPI расходятся по status/type/required fields;
- schema validation warning скрыта без анализа;
- tests используют `force_authenticate` как единственное доказательство security path;
- ожидаемый result записан как фактический.

## Критерий завершения

- все шесть учебных дней имеют минимум 7/10;
- итоговый API имеет минимум 8/10;
- public catalog поддерживает только list/retrieve;
- staff reference CRUD защищён и использует soft deactivation;
- serializer fields явны и не раскрывают private state;
- validation layers объяснимы и покрыты tests;
- router routes/reverse names совпадают с contract;
- filtering/search/ordering имеют allowlists;
- pagination bounded and deterministic;
- selector/endpoint query budgets постоянны для N=2/N=20;
- error envelope одинаков для validation/not-found/method/media/filter errors;
- unexpected error не раскрывает internals;
- generated OpenAPI validation выполнена и warnings разобраны;
- Swagger UI открывает актуальную schema;
- runtime↔OpenAPI audit покрывает methods/status/request/response/filter/page/error;
- full regression suite недели 11 остаётся green;
- clean setup воспроизводится;
- `TEST_MATRIX.md` содержит фактические результаты 36 scenarios;
- минимум 27 из 36 контрольных вопросов отвечены уверенно;
- в `ASSESSMENT.md` указано: «Допуск к неделе 13: да».

## Официальные материалы

- [DRF Requests](https://www.django-rest-framework.org/api-guide/requests/);
- [DRF Responses](https://www.django-rest-framework.org/api-guide/responses/);
- [Serializers](https://www.django-rest-framework.org/api-guide/serializers/);
- [Validators](https://www.django-rest-framework.org/api-guide/validators/);
- [APIView](https://www.django-rest-framework.org/api-guide/views/);
- [Generic views](https://www.django-rest-framework.org/api-guide/generic-views/);
- [ViewSets](https://www.django-rest-framework.org/api-guide/viewsets/);
- [Routers](https://www.django-rest-framework.org/api-guide/routers/);
- [Permissions](https://www.django-rest-framework.org/api-guide/permissions/);
- [Filtering](https://www.django-rest-framework.org/api-guide/filtering/);
- [Pagination](https://www.django-rest-framework.org/api-guide/pagination/);
- [Exceptions](https://www.django-rest-framework.org/api-guide/exceptions/);
- [Testing](https://www.django-rest-framework.org/api-guide/testing/);
- [Content negotiation](https://www.django-rest-framework.org/api-guide/content-negotiation/);
- [django-filter DRF integration](https://django-filter.readthedocs.io/en/stable/guide/rest_framework.html);
- [drf-spectacular installation](https://drf-spectacular.readthedocs.io/en/latest/readme.html#installation);
- [drf-spectacular workflow](https://drf-spectacular.readthedocs.io/en/latest/customization.html);
- [drf-spectacular settings](https://drf-spectacular.readthedocs.io/en/latest/settings.html).

## Текущий статус

Неделя 12 только подготовлена. Текущий активный этап остаётся в `week_00_basics/ASSESSMENT.md`: день 2 недели 0. До допуска из недели 11 не переносить project, не устанавливать DRF dependencies и не запускать migrations.
