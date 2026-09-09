# Практика недели 12: Django REST Framework

Статус: **заблокирована до полного зачёта недели 11**.

## Общие правила

- Все дни развивают один проект в `day_07_drf_api/`.
- Переносится только принятый проект недели 11; source commit фиксируется в журнале.
- Код пишет и исправляет ученик. Наставник читает, запускает и оценивает, но не переписывает решение без прямой просьбы.
- Перед началом дня сначала прочитайте указанные разделы `THEORY.md`, затем запишите predictions.
- Каждый experiment записывается в дневной `.md`: вход, prediction, actual response, database effect и объяснение.
- Public serializers используют явный список fields. `fields = "__all__"` запрещён.
- Сложная business operation остаётся в service. HTTP-layer не дублирует транзакционную логику.
- Balances, inventory, procurement history и movements не получают обычный writable `ModelViewSet`.
- DELETE reference resource означает deactivation, а не физическое удаление.
- Tests работают только с test database. Секреты, session cookies и Authorization headers в журналы не копируются.
- Новые зависимости устанавливаются только после допуска и фиксируются принятым dependency mechanism проекта.

## Формат записи API-сценария

```text
Scenario ID:
Purpose:
Initial database state:
Actor/authentication:
Method and URL:
Headers/query/body:
Prediction: status, response shape, database effect, query count when relevant
Actual status:
Actual response shape:
Actual database effect:
Actual query count/log event:
Explanation:
Correction or next check:
```

Не вставляйте реальные secrets. Большой response можно сократить, сохранив keys, types, важные values и error codes.

## Самооценка дня

1. Что я написал самостоятельно?
2. Как запрос проходит от router до response?
3. Где находится validation и почему именно там?
4. Какое поведение подтвердил test, а какое я только предполагаю?
5. Какая ошибка была самой полезной?
6. Что осталось непонятным?
7. Сколько времени заняла работа?

## Шкала обычного дня

| Критерий | Баллы |
|---|---:|
| Корректность результата | 0–3 |
| Выполнение условий | 0–2 |
| Граничные и ошибочные сценарии | 0–2 |
| Читаемость и архитектурные границы | 0–1 |
| Понимание и самооценка | 0–1 |
| Самостоятельность исправлений | 0–1 |

Обычный день принят при 7/10 без критической ошибки. Итоговый API принят при 8/10.

---

# День 1. Подключение DRF и путь запроса

## Паспорт задания

- **Цель:** подключить DRF и на маленьких endpoints увидеть различие Request, parser, Response, renderer и content negotiation.
- **Рабочий файл или каталог:** settings/urls/tests в `day_07_drf_api/`; журнал — `day_01_drf_setup.md`.
- **Результат:** воспроизводимый baseline, dependency record, `/api/v1/health/` и временный `/api/v1/echo/` с tests для JSON и media negotiation.
- **Порядок выполнения:** подтвердить допуск и source; безопасно перенести проект; проверить database; запустить baseline; подключить dependencies/apps/settings; создать health и echo; проверить JSON/content types; сохранить команды и результаты.
- **Наблюдаемый результат:** health отвечает JSON без database writes; echo возвращает разобранные values; неверные `Content-Type`/`Accept` дают контролируемые статусы.
- **Готово, если:** source и versions записаны; baseline зелёный; API routes namespaced; JSON parsing доказан; `415` и `406` проверены; response media type подтверждён; 10 сценариев записаны.
- **Пример:** `POST /api/v1/echo/` с `{"units": 2}` возвращает объект, где `units` — число, а не JSON-строка.
- **Обязательно для зачёта:** задания 1–7 и сценарии 1–10. **Рекомендация:** сохранить маленькую схему request pipeline в журнале.

## Теория

Прочитайте разделы 1–4, 24 и 33–34 `THEORY.md`.

## Задание 1. Активация и перенос

- **Исходные данные:** явный допуск недели 11, accepted project, Git branch/commit и состояние working tree.
- **Действие:** перенесите проект в `day_07_drf_api/`, не меняя week 11; запишите source branch/commit и список перенесённых компонентов.
- **Результат:** отдельная рабочая копия недели 12 с понятным происхождением.
- **Проверить:** допуск есть; нет допуска — остановка; source dirty; `.env`/secrets не попали в копию.

## Задание 2. Database safety и baseline

- **Исходные данные:** настройки проекта и test configuration.
- **Действие:** без password/DSN зафиксируйте vendor/database purpose; запустите Django checks, migration drift check и полный suite недели 11.
- **Результат:** до DRF-изменений известен честный baseline и безопасная database target.
- **Проверить:** green suite; старая failure; unapplied migration; случайный SQLite fallback; подозрительная shared database — остановка.

## Задание 3. Dependencies и настройки

- **Исходные данные:** фактический dependency format проекта и версии Python/Django.
- **Действие:** после допуска добавьте совместимые exact versions DRF, django-filter и drf-spectacular; зарегистрируйте apps и минимальные REST_FRAMEWORK/SPECTACULAR_SETTINGS.
- **Результат:** imports и Django checks проходят, dependency diff объяснён.
- **Проверить:** clean install; missing package; duplicate/conflicting pin; version command; Django check.

## Задание 4. API namespace и health

- **Исходные данные:** project urls и API prefix `/api/v1/`.
- **Действие:** создайте namespaced route `/api/v1/health/`, который через `APIView` возвращает `{"status": "ok"}` без обращения к business database.
- **Результат:** GET даёт 200 JSON, route находится через `reverse()`.
- **Проверить:** GET; HEAD; POST должен быть запрещён; route reverse; trailing slash behavior.

## Задание 5. Echo и `request.data`

- **Исходные данные:** JSON bodies с строкой, числом, boolean, list и вложенным object.
- **Действие:** временно создайте echo endpoint, возвращающий безопасную копию разобранных данных и имена Python types без model writes.
- **Результат:** журнал доказывает, что parser создал Python values; body не разбирается вручную.
- **Проверить:** valid object; empty object; nested list; malformed JSON; scalar JSON — зафиксировать выбранный contract.

## Задание 6. Media type experiments

- **Исходные данные:** одинаковое body с `application/json`, неподдерживаемым `Content-Type`, приемлемым и неприемлемым `Accept`.
- **Действие:** отправьте запросы через APIClient и сохраните status/response `Content-Type`.
- **Результат:** различия `400`, `406`, `415` объяснены через parser/renderer/validation.
- **Проверить:** valid JSON; malformed JSON; `text/plain`; `Accept: application/json`; unsupported Accept.

## Задание 7. Автоматические tests и журнал

- **Исходные данные:** health/echo routes и сценарии дня.
- **Действие:** напишите tests на route names, methods, statuses, response shape и database no-write; заполните самооценку.
- **Результат:** tests воспроизводят manual experiments и не зависят от запуска dev server.
- **Проверить:** isolated run; full regression; deliberately broken expectation; no secret output.

## Обязательные сценарии дня

1. Week 11 baseline green до изменений.
2. GET health — 200 и JSON object.
3. POST health — 405.
4. Reverse имени health даёт нужный path.
5. Echo принимает JSON object с разными types.
6. Empty JSON object обрабатывается по contract.
7. Malformed JSON даёт 400.
8. Unsupported `Content-Type` даёт 415.
9. Unsupported `Accept` даёт 406.
10. Full regression остаётся green.

## Контрольные вопросы

1. Чем DRF Request отличается от обычного Django request?
2. Кто превращает bytes в Python values?
3. Кто превращает response data в JSON?
4. Чем `406` отличается от `415`?
5. Почему health не должен проверять все business tables?

---

# День 2. Serializers и validation

## Паспорт задания

- **Цель:** построить явные read/write contracts для `CarMake` и `CarModel` и разнести validation по правильным уровням.
- **Рабочий файл или каталог:** serializers и serializer tests в `day_07_drf_api/`; журнал — `day_02_serializers.md`.
- **Результат:** summary/read/write serializers с explicit fields, nested read relation, relation ID для записи, field/object validation и корректным PATCH behavior.
- **Порядок выполнения:** описать внешний contract; сделать маленький plain Serializer; создать ModelSerializers; определить read/write fields; нормализовать code; проверить relations/uniqueness; реализовать update semantics; протестировать `.data`, `.validated_data`, `.errors`.
- **Наблюдаемый результат:** valid input создаёт/обновляет reference object, invalid input не пишет database, output не раскрывает internal fields.
- **Готово, если:** explicit fields используются везде; data/validated_data различаются; read/write relation понятна; PATCH сохраняет omitted fields; error codes проверены; database constraint остаётся последней защитой; 12 сценариев записаны.
- **Пример:** write request содержит `make_id: 3`, а read response — `make: {"id": 3, "code": "BMW", "name": "BMW"}`.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–12. **Рекомендация:** отдельные read/write serializers, если один serializer становится условным и запутанным.

## Теория

Прочитайте разделы 5–10, 23 и 30–34 `THEORY.md`.

## Задание 1. Карта полей API

- **Исходные данные:** фактические fields моделей `CarMake` и `CarModel`, включая timestamps/internal flags.
- **Действие:** заполните `field | read | create | PUT | PATCH | source | validation | reason`.
- **Результат:** до кода видно, какие fields public, read-only и writable.
- **Проверить:** id; business code; relation; active flag; timestamps; неожиданное новое model field.

## Задание 2. Plain Serializer lab

- **Исходные данные:** маленький словарь `{"code": " bmw ", "name": "BMW"}` без ORM.
- **Действие:** создайте временный `Serializer`, нормализуйте code и сравните `initial_data`, `validated_data`, `.data`, `.errors` до/после `is_valid()`.
- **Результат:** в журнале есть predictions и фактические types/values; ошибочный порядок вызовов объяснён.
- **Проверить:** valid; blank code; missing name; unknown field; вызов save без valid state.

## Задание 3. Read serializers

- **Исходные данные:** make/model fixtures, включая inactive make.
- **Действие:** создайте компактный make serializer и model read serializer с nested make; укажите fields явно.
- **Результат:** representation имеет только contract fields и JSON-compatible values.
- **Проверить:** active row; inactive relation в historical object; Unicode name; отсутствуют internal/private fields.

## Задание 4. Write serializer и relation

- **Исходные данные:** valid/invalid `make_id`, model code/name и optional fields.
- **Действие:** принимайте relation по primary key, разрешайте только active make, возвращайте nested representation после save.
- **Результат:** valid object создаётся; missing/inactive/nonexistent make даёт field error и не создаёт row.
- **Проверить:** valid; missing relation; unknown ID; inactive ID; wrong type.

## Задание 5. Field-level validation

- **Исходные данные:** code с пробелами, mixed case, пустой строкой, слишком большой длиной и Unicode согласно model contract.
- **Действие:** нормализуйте code в одном предсказуемом месте и сохраните semantic error codes.
- **Результат:** accepted values сохраняются canonically; rejected values имеют field path/message/code.
- **Проверить:** normal; leading/trailing spaces; blank; max length boundary; over max; duplicate after normalization.

## Задание 6. Object-level и database validation

- **Исходные данные:** поля, имеющие совместный invariant, и unique constraints модели.
- **Действие:** добавьте только действительно cross-field serializer rule; отдельно докажите constraint через serializer и прямой ORM/concurrency-relevant scenario.
- **Результат:** обязанности serializer и database не смешаны, invalid data не остаются сохранёнными.
- **Проверить:** valid combination; each boundary equality; invalid order/combo; duplicate; race limitation объяснено.

## Задание 7. PUT и PATCH

- **Исходные данные:** существующая model с минимум тремя writable values.
- **Действие:** выполните полный update и partial update; в cross-field validation учитывайте instance для omitted field.
- **Результат:** PATCH меняет только переданное; PUT следует зафиксированному full-update contract; явный null отличается от omission.
- **Проверить:** PATCH one field; omitted fields; explicit null; empty PATCH; PUT missing required field.

## Задание 8. Serializer tests и negative writes

- **Исходные данные:** все serializers дня и isolated database.
- **Действие:** протестируйте representation, validation codes, number of writes и состояние rows после failure; заполните журнал.
- **Результат:** contract подтверждён автоматически, а не только ручным выводом `.errors`.
- **Проверить:** create/update success; each invalid input; row count unchanged; unexpected model field absent.

## Обязательные сценарии дня

1. Valid make serialization.
2. Valid model serialization с nested make.
3. Explicit fields не содержат internal field.
4. Valid create через `validated_data`.
5. Blank/whitespace code отклонён с code.
6. Boundary max length принят.
7. Over max length отклонён.
8. Duplicate normalized code отклонён или безопасно пойман constraint.
9. Unknown `make_id` отклонён.
10. Inactive `make_id` отклонён.
11. PATCH сохраняет omitted values.
12. Failed validation не меняет database.

## Контрольные вопросы

1. Чем serialization отличается от deserialization?
2. Когда доступны `validated_data` и `.data`?
3. Почему public serializer не использует `__all__`?
4. Зачем разделять nested read relation и ID для write?
5. Что должен делать PATCH с отсутствующим полем?
6. Почему serializer uniqueness check не заменяет constraint?

---

# День 3. APIView, GenericAPIView, mixins и ViewSets

## Паспорт задания

- **Цель:** реализовать один read flow несколькими DRF abstractions и обоснованно выбрать уровень абстракции для итогового API.
- **Рабочий файл или каталог:** временные lab views/urls/tests в `day_07_drf_api/`; журнал — `day_03_views_viewsets.md`.
- **Результат:** работающие варианты APIView, GenericAPIView+mixins и ViewSet, comparison table и принятое решение для catalog/reference endpoints.
- **Порядок выполнения:** зафиксировать одинаковый contract; написать APIView; generic variant; mixin variant; ViewSet variant; связать actions/methods; сравнить duplication/hooks/routes/tests; удалить или изолировать лишние lab routes.
- **Наблюдаемый результат:** одинаковый запрос даёт согласованный response во всех labs, а итоговый выбор объяснён responsibilities, не количеством строк.
- **Готово, если:** четыре abstractions различаются; `get_queryset()` используется корректно; actions/methods названы; pagination limitation APIView замечена; ViewSet router behavior проверен; lab endpoints не попали случайно в public contract; 10 сценариев записаны.
- **Пример:** `GET /lab/viewset/makes/` вызывает action `list`, а `GET /lab/viewset/makes/3/` — `retrieve`.
- **Обязательно для зачёта:** задания 1–7 и сценарии 1–10. **Рекомендация:** diagram `method + path -> route -> action -> queryset -> serializer`.

## Теория

Прочитайте разделы 11–17 и 22 `THEORY.md`.

## Задание 1. Единый lab contract

- **Исходные данные:** три make rows, включая inactive, и read serializer дня 2.
- **Действие:** зафиксируйте list/retrieve fields, ordering, inactive policy, statuses и no-write rule для всех вариантов.
- **Результат:** реализации сравниваются по одному contract.
- **Проверить:** empty list; active list; existing detail; inactive/missing detail; POST forbidden.

## Задание 2. APIView variant

- **Исходные данные:** contract и serializer.
- **Действие:** реализуйте list/retrieve через явные get methods и разберите вручную, где появляются queryset lookup, serialization и exceptions.
- **Результат:** endpoints работают без hidden generic hooks; duplication отмечена.
- **Проверить:** empty/list/detail/missing; method 405; query evaluation.

## Задание 3. GenericAPIView variant

- **Исходные данные:** тот же contract.
- **Действие:** используйте `serializer_class`, `get_queryset()` и `get_object()`; не вычисляйте class-level queryset вручную.
- **Результат:** behavior совпадает с APIView, generic hooks видны и объяснимы.
- **Проверить:** request-specific queryset; inactive exclusion; missing 404; serializer context.

## Задание 4. Mixins variant

- **Исходные данные:** тот же contract и `ListModelMixin`/`RetrieveModelMixin`.
- **Действие:** подключите только нужные mixins и свяжите HTTP methods с их actions.
- **Результат:** list/retrieve reuse generic implementation; create/update/destroy отсутствуют.
- **Проверить:** list/retrieve; POST/PUT/DELETE forbidden; pagination hook при включённой настройке.

## Задание 5. ViewSet variant

- **Исходные данные:** тот же contract и временный router.
- **Действие:** реализуйте `ReadOnlyModelViewSet`, зарегистрируйте basename и сопоставьте generated names/actions/paths.
- **Результат:** router выдаёт list/detail routes, reverse работает, write actions не существуют.
- **Проверить:** route listing; reverse list/detail; GET actions; POST 405; trailing slash.

## Задание 6. Сравнение и выбор

- **Исходные данные:** четыре реализации и требования итогового API.
- **Действие:** заполните `abstraction | gives | still manual | best use | risk`; выберите public catalog и staff CRUD classes.
- **Результат:** решение: read-only ViewSet для catalog и bounded ModelViewSet/mixins для reference CRUD либо равноценно обоснованная альтернатива.
- **Проверить:** custom command endpoint; standard read; standard CRUD; опасный operational model.

## Задание 7. Очистка labs и regression

- **Исходные данные:** временные routes и tests.
- **Действие:** оставьте labs явно namespaced/debug-only либо удалите routes после фиксации evidence; запустите suite.
- **Результат:** public API не содержит дубликатов, знания сохранены в journal/tests.
- **Проверить:** URL resolver; schema не видит lab routes; no dead imports; regression green.

## Обязательные сценарии дня

1. Все variants возвращают одинаковые contract fields.
2. Empty queryset даёт пустой collection, не 404.
3. Existing detail даёт object.
4. Missing detail даёт 404.
5. Inactive row скрыта.
6. Forbidden POST даёт 405.
7. `get_queryset()` использован request-safe способом.
8. Router создаёт ожидаемые names.
9. Method/path сопоставлены actions.
10. В public URL/schema не осталось случайных labs.

## Контрольные вопросы

1. Что добавляет APIView?
2. Что добавляет GenericAPIView?
3. Для чего нужны mixins?
4. Чем ViewSet отличается от обычной view?
5. Почему catalog использует read-only класс?
6. Когда APIView лучше ViewSet?

---

# День 4. Routers, CRUD и permissions

## Паспорт задания

- **Цель:** собрать стабильные routes для публичного каталога и staff-only reference CRUD, не открыв опасные business models.
- **Рабочий файл или каталог:** API urls, permissions, ViewSets и tests в `day_07_drf_api/`; журнал — `day_04_routers_crud.md`.
- **Результат:** versioned router, public catalog list/retrieve, CRUD `CarMake`/`CarModel` для staff и deactivation через DELETE.
- **Порядок выполнения:** записать route/permission matrix; создать routers; подключить catalog; подключить reference ViewSets; выставить permissions; переопределить destroy; исключить inactive rows; проверить actors/methods/reverse/database effects.
- **Наблюдаемый результат:** любой читает каталог; только staff меняет справочники; DELETE сохраняет row и скрывает её из active API.
- **Готово, если:** все routes versioned/named; public endpoint read-only; staff CRUD закрыт; 401/403 зафиксированы по конфигурации; no physical delete; operational models не зарегистрированы; 12 сценариев записаны.
- **Пример:** `DELETE /api/v1/reference/makes/3/` возвращает 204, row `id=3` остаётся, но `is_active=False`.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–12. **Рекомендация:** отдельные routers/modules для public и staff surface при росте проекта.

## Теория

Прочитайте разделы 15–18, 24, 30–32 и 34 `THEORY.md`.

## Задание 1. Route/permission matrix

- **Исходные данные:** catalog, make/model reference resources и actors anonymous, authenticated non-staff, staff.
- **Действие:** заполните `method | path | action | route name | actor | status | database effect`.
- **Результат:** до implementation перечислен весь разрешённый API surface.
- **Проверить:** collection/detail; each method; anonymous; non-staff; staff; inactive resource.

## Задание 2. Versioned routers

- **Исходные данные:** prefix `/api/v1/`, public и reference route groups.
- **Действие:** зарегистрируйте ViewSets с явными basename; включите URLs под versioned namespace; используйте `reverse()` в tests.
- **Результат:** generated list/detail paths/names совпадают с matrix.
- **Проверить:** list/detail reverse; duplicate basename; trailing slash; unknown route 404.

## Задание 3. Public catalog ViewSet

- **Исходные данные:** selector/queryset недели 11 и catalog serializer.
- **Действие:** реализуйте только list/retrieve, явно задайте `AllowAny`, исключите inactive data и сохраните оптимизированный queryset.
- **Результат:** anonymous получает безопасный catalog contract, write methods дают 405.
- **Проверить:** empty/non-empty; detail; inactive/missing; POST/PATCH/DELETE; query count.

## Задание 4. Make CRUD

- **Исходные данные:** make serializer, active/inactive rows и staff user.
- **Действие:** реализуйте list/retrieve/create/update/partial_update с `IsAdminUser` и явным queryset/order.
- **Результат:** staff управляет valid resource, другие actors не читают и не изменяют staff surface.
- **Проверить:** CRUD success; invalid payload; anonymous; non-staff; duplicate.

## Задание 5. CarModel CRUD

- **Исходные данные:** model read/write representation и active make relation.
- **Действие:** реализуйте staff CRUD с nested read make и `make_id` для write; не допускайте привязку к inactive make.
- **Результат:** response и relation validation соответствуют contract дня 2.
- **Проверить:** create; retrieve; PUT; PATCH; bad/inactive make; Unicode values.

## Задание 6. Deactivation semantics

- **Исходные данные:** используемые и неиспользуемые reference rows.
- **Действие:** переопределите destroy так, чтобы выставлять `is_active=False`; выберите и протестируйте поведение повторного DELETE.
- **Результат:** historical foreign keys сохранены, active querysets больше не показывают resource.
- **Проверить:** unused row; referenced row; retrieve after delete; second delete; row count unchanged.

## Задание 7. Permission tests

- **Исходные данные:** anonymous, authenticated non-staff, staff и фактические authentication classes.
- **Действие:** проверьте list/detail/write для каждой роли; хотя бы один scenario проведите через реальный login/session path, а не только `force_authenticate()`.
- **Результат:** ожидаемые 401/403/2xx зафиксированы и объяснены настройкой authenticator.
- **Проверить:** no credentials; invalid/unusable session; non-staff; staff; CSRF-relevant unsafe method.

## Задание 8. Surface audit и regression

- **Исходные данные:** router registry/url patterns и модели проекта.
- **Действие:** убедитесь, что balance, inventory, purchase, movements и supplier price не получили generic writable routes; запустите tests недели 11/12.
- **Результат:** API не обходит service/invariants, старый vertical slice не сломан.
- **Проверить:** route resolve/listing; guessed dangerous URL; direct write attempt; full suite.

## Обязательные сценарии дня

1. Anonymous catalog list — 200.
2. Anonymous catalog detail — 200 для active row.
3. Catalog POST — 405.
4. Anonymous reference list запрещён.
5. Authenticated non-staff reference CRUD запрещён.
6. Staff create make — 201.
7. Staff invalid create — 400 без row.
8. Staff PUT/PATCH следуют contract.
9. Staff delete — 204 и deactivation.
10. Deactivated resource не виден active API.
11. Historical relation после deactivation существует.
12. Опасные operational CRUD routes отсутствуют.

## Контрольные вопросы

1. Что именно генерирует router?
2. Почему global permissions должны быть fail-closed?
3. Почему catalog явно получает `AllowAny`?
4. От чего зависит ответ 401 или 403?
5. Почему DELETE не удаляет row физически?
6. Почему inventory нельзя открыть полным ModelViewSet?

---

# День 5. Filtering, search, ordering и pagination

## Паспорт задания

- **Цель:** дать клиенту ограниченное управление catalog queryset без нестабильных страниц, утечки полей и N+1.
- **Рабочий файл или каталог:** filters, pagination, catalog ViewSet и tests в `day_07_drf_api/`; журнал — `day_05_filtering_pagination.md`.
- **Результат:** typed FilterSet, Unicode search, allowlisted ordering, bounded page size и constant query budget N=2/N=20.
- **Порядок выполнения:** создать dataset; зафиксировать query contract; подключить FilterSet; добавить search; allowlist ordering; настроить pagination; добавить deterministic tie-breaker; измерить full response queries; протестировать combinations/errors.
- **Наблюдаемый результат:** query parameters предсказуемо меняют `results`, metadata корректна, равные значения не дублируются между страницами, query count не растёт линейно.
- **Готово, если:** filters typed; invalid range/input контролируется; search fields явные; ordering fields явные; page size capped; ordering deterministic; N=2/N=20 budget принят; 12 сценариев записаны.
- **Пример:** `/api/v1/catalog/?make=BMW&min_price=10000&ordering=price&page=2&page_size=5` возвращает envelope `count/next/previous/results`.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–12. **Рекомендация:** explain/query plan только для замеченной дорогой query, а не для каждой проверки.

## Теория

Прочитайте разделы 19–23 и 29–34 `THEORY.md`.

## Задание 1. Dataset и query contract

- **Исходные данные:** не менее 20 catalog rows, несколько makes/models/dealerships, равные цены, Unicode names и inactive rows.
- **Действие:** создайте deterministic fixture/factory data; опишите каждый public parameter, type, lookup и default.
- **Результат:** scenarios воспроизводимы, expected result можно вычислить заранее.
- **Проверить:** N=0/1/2/20; equal prices; price boundaries; inactive; Unicode.

## Задание 2. Exact и relation filters

- **Исходные данные:** `make`, `country`, `dealership` query parameters.
- **Действие:** создайте `FilterSet` с явными fields/lookups и подключите DRF backend.
- **Результат:** каждый parameter ограничивает queryset по contract; неизвестные/невалидные значения имеют выбранное документированное поведение.
- **Проверить:** each filter; no matches; duplicate relation names; unknown ID/code; combined filters.

## Задание 3. Price range

- **Исходные данные:** `min_price`, `max_price`, цены ниже/равно/выше границы.
- **Действие:** реализуйте typed gte/lte filters и cross-parameter rule `min_price <= max_price` в подходящем месте.
- **Результат:** inclusive boundaries работают, impossible range даёт controlled 400.
- **Проверить:** only min; only max; equality; valid range; reversed range; non-number/negative по domain contract.

## Задание 4. Search

- **Исходные данные:** make/model/code fields с Latin, Cyrillic/Unicode, несколькими словами и пустой строкой.
- **Действие:** подключите `SearchFilter` только к публичным текстовым fields.
- **Результат:** `search` находит expected rows и не ищет по internal/private fields.
- **Проверить:** exact/partial; Unicode; case; multi-term; empty; secret/internal value.

## Задание 5. Ordering allowlist

- **Исходные данные:** `price`, make/model name и минимум одно internal field.
- **Действие:** задайте `ordering_fields`, default ordering и tie-breaker; определите ascending/descending behavior.
- **Результат:** разрешённая сортировка стабильна, запрещённое поле не меняет query непредсказуемо и не раскрывает данные.
- **Проверить:** default; `price`; `-price`; equal prices; multiple fields; forbidden field.

## Задание 6. Bounded pagination

- **Исходные данные:** default page, page size, max page size и dataset 20+ rows.
- **Действие:** создайте pagination class с `page_size_query_param` и `max_page_size`; подтвердите envelope.
- **Результат:** клиент не запрашивает неограниченный response, links/count/results корректны.
- **Проверить:** first/middle/last; size 1; max; above max; invalid page; empty dataset.

## Задание 7. Combinations и retrieve filtering

- **Исходные данные:** фильтр + search + ordering + pagination и detail URL с query params.
- **Действие:** проверьте composition и явно решите, применяются ли filters к retrieve; запишите rationale.
- **Результат:** combined query имеет предсказуемое пересечение и стабильные pages; detail behavior не является сюрпризом.
- **Проверить:** no filters; two filters; filter+search; filter+ordering+page; matching/nonmatching detail filter.

## Задание 8. Query budget

- **Исходные данные:** N=0, N=2 и N=20 response rows с nested relations и pagination metadata.
- **Действие:** измерьте queries вокруг полного request/`response.data`; устраните N+1 через selector/queryset optimization, не скрывая fields.
- **Результат:** budget постоянен или отличается только на заранее объяснённое фиксированное число queries.
- **Проверить:** empty; N=2; N=20; filter; search; second page; detail.

## Обязательные сценарии дня

1. Catalog без params имеет stable default order.
2. Exact make filter.
3. Country/dealership relation filter.
4. Inclusive min/max price boundaries.
5. `min_price == max_price`.
6. Reversed/invalid range даёт 400.
7. Unicode search.
8. Allowed ascending/descending ordering.
9. Forbidden ordering field не становится public capability.
10. Page size 1 и max cap.
11. Equal-order rows не теряются/не повторяются между pages.
12. N=2/N=20 не создают relation N+1.

## Контрольные вопросы

1. Чем exact filter отличается от search?
2. Почему price boundary должна быть inclusive или явно описана иначе?
3. Зачем ограничивать ordering fields?
4. Для чего нужен tie-breaker?
5. Какие дополнительные queries создаёт pagination?
6. Почему query count измеряется после rendering/serialization?

---

# День 6. Ошибки, OpenAPI и contract tests

## Паспорт задания

- **Цель:** сделать ошибки машиночитаемыми и доказать соответствие OpenAPI фактическому API.
- **Рабочий файл или каталог:** exception handler, schema config/annotations и tests в `day_07_drf_api/`; журналы — `day_06_errors_openapi.md` и `day_07_drf_api/OPENAPI_AUDIT.md`.
- **Результат:** единый safe error envelope, schema endpoint, Swagger UI, schema validation без необъяснённых warnings и runtime↔schema audit.
- **Порядок выполнения:** инвентаризировать errors; определить envelope/codes; написать handler; проверить expected/unexpected failures; подключить spectacular; сгенерировать/валидировать schema; добавить минимальные annotations; сравнить schema с runtime; запустить regression.
- **Наблюдаемый результат:** ошибки имеют одну форму и request ID; schema/doc UI открываются; methods/parameters/statuses/permissions/representations совпадают с tests.
- **Готово, если:** validation codes сохранены; 404/405/406/415 нормализованы; unexpected exception не раскрыт; schema генерируется; warnings классифицированы; Swagger использует актуальную schema; audit заполнен; 12 сценариев записаны.
- **Пример:** ошибка `code` возвращает machine code `unique`, а не только строку «уже существует».
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–12. **Рекомендация:** generated schema artifact хранить только если это соответствует принятому workflow проекта.

## Теория

Прочитайте разделы 24–32 и 34 `THEORY.md`.

## Задание 1. Error inventory

- **Исходные данные:** validation, permission, not found, method, parser, renderer, filter и unexpected exceptions.
- **Действие:** заполните `source exception | HTTP status | public code | message | details | log level | database effect`.
- **Результат:** expected client errors отделены от server defects.
- **Проверить:** field/non-field validation; 403/404/405; malformed JSON; 406/415; forced unexpected error.

## Задание 2. Error envelope contract

- **Исходные данные:** inventory и target JSON из README.
- **Действие:** определите стабильные keys/types, top-level code mapping и recursive representation field errors с DRF codes.
- **Результат:** frontend может ветвиться по code и field path, не анализируя human text.
- **Проверить:** one field; several fields; nested/list errors; non-field error; detail-only exception.

## Задание 3. Exception handler

- **Исходные данные:** стандартный DRF handler и request/correlation ID mechanism проекта.
- **Действие:** для ожидаемых ошибок используйте стандартный DRF handler и нормализуйте его response; для unexpected зафиксируйте non-debug policy `500 + generic envelope + server log`; не превращайте их в 400 и не раскрывайте internals.
- **Результат:** expected errors имеют envelope; unexpected error в non-debug режиме безопасно логируется с ID и возвращает только generic 500 details.
- **Проверить:** ValidationError; NotFound; PermissionDenied; MethodNotAllowed; ParseError; forced RuntimeError.

## Задание 4. Error contract tests

- **Исходные данные:** endpoints и error inventory.
- **Действие:** протестируйте exact statuses, required envelope keys, machine codes, database no-write и отсутствие forbidden strings.
- **Результат:** единая форма доказана для разных sources.
- **Проверить:** 400/403(or 401)/404/405/406/415/500 policy; SQL/path/traceback absent.

## Задание 5. Schema и Swagger setup

- **Исходные данные:** drf-spectacular dependency и paths `/api/schema/`, `/api/docs/`.
- **Действие:** настройте default schema class, schema view и Swagger UI; задайте title/version/description без секретов.
- **Результат:** schema endpoint отдаёт OpenAPI, UI загружает именно её.
- **Проверить:** anonymous access policy; content type; broken schema URL; title/version; no debug-only routes.

## Задание 6. Generation и warning triage

- **Исходные данные:** management command schema generation и текущие serializers/ViewSets.
- **Действие:** сгенерируйте и валидируйте schema; для каждого warning запишите cause/fix/accepted reason; сначала исправляйте declarations, затем используйте `extend_schema`.
- **Результат:** нет необъяснённых warnings, annotations минимальны и правдивы.
- **Проверить:** missing serializer/queryset; custom response; filter params; pagination; duplicate operation ID.

## Задание 7. Runtime↔OpenAPI audit

- **Исходные данные:** `API_CONTRACT.md`, generated schema и API tests.
- **Действие:** заполните `path | method | auth | params | request | success | errors | runtime evidence | mismatch/fix`.
- **Результат:** catalog/reference methods, PUT/PATCH, soft delete, filters, pagination и error response сопоставлены.
- **Проверить:** list/detail/create/update/delete; 400; permissions; schema/docs paths.

## Задание 8. Full regression и clean generation

- **Исходные данные:** week 11/12 suites и clean environment instructions.
- **Действие:** выполните checks, migration drift check, all tests, schema validation и повторную генерацию; сохраните commands/status/duration.
- **Результат:** API change не сломало service/selector, schema воспроизводима.
- **Проверить:** clean pass; stale schema; intentional mismatch caught; no migrations created accidentally.

## Обязательные сценарии дня

1. Field validation error содержит field path и machine code.
2. Non-field validation имеет стабильное место в details.
3. Permission error использует общий envelope.
4. Not found использует общий envelope.
5. Method not allowed использует общий envelope.
6. Malformed JSON использует общий envelope.
7. Unsupported media/Accept дают 415/406.
8. Unexpected error не раскрывает traceback/SQL/path.
9. Schema endpoint возвращает valid OpenAPI.
10. Swagger UI использует актуальную schema.
11. Все schema warnings объяснены/устранены.
12. Runtime audit не содержит незакрытых mismatch.

## Контрольные вопросы

1. Почему нельзя возвращать все exceptions как 400?
2. Зачем сохранять DRF error codes?
3. Что можно показать клиенту при server error?
4. Чем OpenAPI schema отличается от Swagger UI?
5. Когда нужен `extend_schema`?
6. Почему schema validation не заменяет runtime tests?

---

# День 7. Итоговый DRF API

## Паспорт проекта

- **Цель:** самостоятельно собрать и защитить production-shaped HTTP contract поверх принятого service/selector слоя.
- **Рабочий файл или каталог:** `day_07_drf_api/`; документы — `README.md`, `API_CONTRACT.md`, `OPENAPI_AUDIT.md`, `TEST_MATRIX.md`; итог фиксируется в `ASSESSMENT.md`.
- **Результат:** public read-only catalog, staff-only make/model CRUD с deactivation, filters/search/ordering/pagination, safe error envelope, OpenAPI/Swagger и regression tests.
- **Порядок выполнения:** зафиксировать baseline; собрать вертикальный срез public list; public detail; make CRUD; model CRUD; query features; errors; schema; полный test/security/performance audit; clean replay; защита.
- **Наблюдаемый результат:** новый разработчик поднимает проект по README, видит docs, выполняет разрешённые запросы и получает предсказуемые success/error responses без обхода business invariants.
- **Готово, если:** все обязательные endpoints работают; actors/methods закрыты; inactive data скрыты; 36 сценариев заполнены; query budgets соблюдены; schema valid и совпадает с runtime; week 11 regressions green; нет critical errors; защита минимум 27/36.
- **Пример:** anonymous `GET /api/v1/catalog/?ordering=price&page_size=5` получает 200 paginated JSON, но `POST` на тот же collection получает 405.
- **Обязательно для зачёта:** все артефакты, срезы 1–8, сценарии 1–36, clean replay и защита. **Рекомендация:** сохранить небольшую архитектурную diagram в README проекта.

## Целевое дерево

Названия Django apps адаптируйте к принятому проекту, но обязанности не смешивайте:

```text
day_07_drf_api/
├── manage.py
├── README.md
├── API_CONTRACT.md
├── OPENAPI_AUDIT.md
├── TEST_MATRIX.md
├── requirements... / pyproject.toml
├── config/
│   ├── settings/
│   ├── urls.py
│   └── api_urls.py
├── common/
│   ├── api/
│   │   ├── exceptions.py
│   │   └── pagination.py
│   └── tests/
├── catalog/
│   ├── models.py
│   ├── selectors.py
│   ├── services.py
│   ├── api/
│   │   ├── filters.py
│   │   ├── serializers.py
│   │   ├── views.py
│   │   └── urls.py
│   └── tests/
│       ├── test_api_catalog.py
│       ├── test_api_reference.py
│       ├── test_api_errors.py
│       ├── test_api_queries.py
│       └── test_api_schema.py
└── другие принятые apps недели 11/
```

## Обязанности файлов

- `config/api_urls.py` — versioned top-level API routes, schema и docs.
- `common/api/exceptions.py` — единое преобразование ожидаемых DRF exceptions; не business rules.
- `common/api/pagination.py` — bounded pagination contract.
- `catalog/api/serializers.py` — public representations и input validation HTTP-слоя.
- `catalog/api/filters.py` — allowlisted typed catalog parameters.
- `catalog/api/views.py` — orchestration, permissions и actions; не transaction logic.
- `catalog/api/urls.py` — routers и basenames.
- `catalog/selectors.py` — оптимизированное чтение; сохраняется из недели 11.
- `*/services.py` — business transitions; не переносятся в serializers/ViewSets.
- `test_api_*.py` — behavior, security, database effects, performance и schema evidence.
- `API_CONTRACT.md` — обещанный внешний интерфейс.
- `OPENAPI_AUDIT.md` — сопоставление contract/runtime/schema.
- `TEST_MATRIX.md` — фактические результаты обязательных сценариев.

## Срез 1. Baseline и API skeleton

- **Исходные данные:** accepted week 11 и допуск.
- **Действие:** перенесите source, зафиксируйте versions/database/baseline, подключите DRF stack и versioned URL namespace.
- **Результат:** checks/tests проходят, `/api/v1/health/`, schema и docs routes разрешаются.
- **Проверить:** clean environment; safe database; reverse names; no accidental migrations; old tests.

## Срез 2. Public catalog list

- **Исходные данные:** selector недели 11 и explicit read serializer.
- **Действие:** реализуйте anonymous list через read-only ViewSet, затем pagination и query budget.
- **Результат:** stable page envelope без internal fields и N+1.
- **Проверить:** empty/one/many; inactive exclusion; page boundaries; N=2/N=20.

## Срез 3. Public catalog detail

- **Исходные данные:** active/inactive/missing inventory IDs.
- **Действие:** добавьте retrieve на том же contract и определите влияние filters на detail.
- **Результат:** active resource виден, invisible/missing resource даёт safe 404.
- **Проверить:** active; inactive; missing; filter matches/does not match; POST/PATCH/DELETE 405.

## Срез 4. Staff make CRUD

- **Исходные данные:** actors и make serializers.
- **Действие:** подключите permission-protected ViewSet с create/read/update/partial/deactivate.
- **Результат:** staff управляет справочником, другие actors запрещены, delete сохраняет history.
- **Проверить:** full CRUD; normalized duplicate; permission matrix; repeated delete; row remains.

## Срез 5. Staff model CRUD

- **Исходные данные:** model serializer и make relation.
- **Действие:** добавьте nested read/ID write, active relation validation и update semantics.
- **Результат:** valid models управляются через API, invalid relation/fields не меняют database.
- **Проверить:** create/read/PUT/PATCH/deactivate; inactive make; omitted/null; Unicode.

## Срез 6. Query capabilities

- **Исходные данные:** 20+ reproducible rows.
- **Действие:** подключите filters, search, ordering и pagination, затем измерьте full-response query budgets.
- **Результат:** query surface allowlisted, bounded, deterministic и без N+1.
- **Проверить:** каждый parameter; invalid/reversed range; combinations; equal ordering; max size; N=2/N=20.

## Срез 7. Errors и OpenAPI

- **Исходные данные:** работающие endpoints и error inventory.
- **Действие:** примените exception handler, сохраните error codes, сгенерируйте/валидируйте schema и заполните audit.
- **Результат:** client получает единый safe envelope, schema точно описывает runtime.
- **Проверить:** 400/permission/404/405/406/415/unexpected; warnings; methods; request/response schemas.

## Срез 8. Regression, clean replay и защита

- **Исходные данные:** полный проект и fresh checkout/setup instructions.
- **Действие:** выполните clean setup, checks, migration checks, all tests, schema validation и 36 сценариев; ответьте на вопросы без чтения готового кода.
- **Результат:** проект воспроизводим и объясним, week 11 invariants не нарушены.
- **Проверить:** fresh database; deterministic fixtures; docs; no secrets; no dangerous routes; intentional failing test detected.

## Обязательные итоговые сценарии

### Позитивные: 1–16

1. Clean install/import/checks проходят на зафиксированных versions.
2. Week 11 regression suite green до и после DRF change.
3. Health, schema и docs routes разрешаются по именам.
4. Anonymous catalog list возвращает 200 и pagination envelope.
5. Anonymous catalog detail возвращает contract fields.
6. Staff создаёт valid make и получает 201.
7. Staff читает/обновляет make.
8. Staff создаёт valid model по `make_id` и получает nested make в response.
9. Staff выполняет valid PUT по принятому contract.
10. Staff PATCH меняет одно поле и сохраняет omitted fields.
11. Staff DELETE деактивирует resource и возвращает выбранный success status.
12. Exact make/country/dealership filters возвращают ожидаемые rows.
13. Unicode search находит make/model/code.
14. Allowed ascending/descending ordering работает.
15. Pagination links/count/results согласованы.
16. OpenAPI schema генерируется и валидируется без необъяснённых warnings.

### Граничные: 17–26

17. Empty catalog возвращает 200, `count=0`, `results=[]`.
18. Catalog из одной row корректно формирует first/last page.
19. Price row на `min_price` включена.
20. Price row на `max_price` включена.
21. `min_price == max_price` возвращает только точную границу.
22. Equal-price rows имеют stable tie-breaker и не повторяются между pages.
23. `page_size=1` работает, значение выше maximum ограничено или отклонено по contract.
24. Last page и out-of-range page имеют зафиксированное поведение.
25. Inactive catalog row не видна в list/detail.
26. Empty search и combined filter+search+ordering дают предсказуемый результат.

### Ошибочные, security и performance: 27–36

27. Anonymous не получает staff reference API.
28. Authenticated non-staff не получает staff reference API.
29. Реальный staff session path разрешает write и учитывает CSRF policy.
30. POST/PATCH/DELETE public catalog дают 405 и не меняют database.
31. Invalid/duplicate create даёт 400 с field path/code и не создаёт row.
32. Unknown/inactive `make_id` отклонён без partial write.
33. Reversed/non-numeric price range даёт controlled 400.
34. Malformed JSON, unsupported `Content-Type` и unacceptable `Accept` дают 400/415/406 в общем envelope.
35. Full list response N=2 и N=20 укладывается в принятый constant query budget.
36. Forced unexpected exception не раскрывает traceback/SQL/path; runtime↔OpenAPI audit не имеет незакрытого mismatch.

## Ограничения итогового проекта

На неделе 12 нельзя:

- добавлять JWT, social login, email confirmation или собственную account model без плана следующих недель;
- открывать writable CRUD для inventory, balances, purchases, movements и supplier prices;
- переносить atomic business operation в serializer/view;
- использовать writable nested serializers;
- добавлять bulk create/update/delete;
- добавлять file uploads, Celery, Redis, GraphQL и WebSocket;
- маскировать unexpected exceptions под `400`;
- подменять runtime tests красивой OpenAPI annotation;
- выполнять проверку на production/shared database;
- сохранять credentials, cookies, tokens, raw DSN или traceback с secrets в repository.

## Финальный чек-лист сдачи

- [ ] Source week 11 и baseline зафиксированы.
- [ ] Dependencies и setup воспроизводимы.
- [ ] Database target безопасно подтверждена.
- [ ] Public catalog использует read-only ViewSet и `AllowAny`.
- [ ] Reference CRUD доступен только staff.
- [ ] Serializers имеют explicit fields.
- [ ] Read/write relation contracts понятны.
- [ ] PUT/PATCH различаются и протестированы.
- [ ] DELETE деактивирует, не удаляет.
- [ ] Operational models не имеют generic writable routes.
- [ ] Filters/search/ordering allowlisted.
- [ ] Pagination имеет maximum size и stable ordering.
- [ ] Query budget N=2/N=20 принят.
- [ ] Error envelope сохраняет machine codes.
- [ ] Unexpected exceptions не раскрывают internals.
- [ ] OpenAPI валидна, warnings разобраны.
- [ ] Swagger UI использует актуальную schema.
- [ ] Runtime↔schema audit заполнен.
- [ ] Week 11 regression suite green.
- [ ] Все 36 scenarios имеют actual result.
- [ ] README не содержит secrets и позволяет повторить setup.
- [ ] Самооценка и вопросы для наставника заполнены.

## Вопросы для защиты: 36

1. Покажите полный путь JSON request до JSON response.
2. Чем `request.data` отличается от `request.query_params`?
3. Что вызывает 415, а что 406?
4. Чем serializer `.data` отличается от `.validated_data`?
5. Почему нельзя сохранять `initial_data` напрямую?
6. Когда выбрать plain Serializer вместо ModelSerializer?
7. Почему public serializer использует explicit fields?
8. Как устроено nested read и ID write relation?
9. Где находится field-level validation?
10. Где находится object-level validation?
11. Почему database constraint всё ещё нужен?
12. Как PATCH обрабатывает omitted field?
13. Чем PUT contract отличается от PATCH?
14. Почему procurement остаётся в service?
15. Что даёт APIView?
16. Что даёт GenericAPIView?
17. Что делают mixins?
18. Как router связывает method с ViewSet action?
19. Зачем нужен basename?
20. Почему catalog — `ReadOnlyModelViewSet`?
21. Чем authentication отличается от permission?
22. Почему global default должен быть fail-closed?
23. Что на самом деле проверяет `IsAdminUser`?
24. Почему `force_authenticate()` недостаточно для полного auth test?
25. Почему DELETE реализован как deactivation?
26. Чем typed filter отличается от search?
27. Почему ordering fields ограничены?
28. Зачем ordering tie-breaker?
29. Что означают `count`, `next`, `previous`, `results`?
30. Где появляется N+1 при nested serialization?
31. Почему query count измеряется вокруг полного response?
32. Чем 401 отличается от 403 в вашей конфигурации?
33. Зачем клиенту machine-readable error code?
34. Как обрабатывается unexpected exception?
35. Чем OpenAPI отличается от Swagger UI?
36. Как вы доказали, что schema соответствует runtime?

Минимум для защиты — **27 уверенных ответов из 36**, включая обязательные вопросы 4, 11, 12, 14, 20, 22, 25, 30, 34 и 36.

## Что передать наставнику

1. Ссылку/путь на `day_07_drf_api/`.
2. Source branch/commit недели 11 и commit текущей попытки.
3. `API_CONTRACT.md`.
4. `OPENAPI_AUDIT.md`.
5. Заполненный `TEST_MATRIX.md`.
6. Команды и результаты checks/tests/schema validation.
7. Фактические query counts N=2/N=20.
8. Список известных ограничений.
9. Самооценку и темы, которые нужно разобрать.
