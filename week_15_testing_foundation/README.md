# Неделя 15: фундамент тестирования Python/Django API

Статус: **подготовлена заранее и заблокирована до полного зачёта недели 14**.

На этой неделе накопленный backend превращается из проекта с отдельными проверками в управляемую test suite. Цель — не «добить 100% coverage», а научиться выбирать правильный уровень теста, строить воспроизводимые данные, получать полезное сообщение при падении и доказывать критические бизнес-инварианты положительными и отрицательными сценариями.

Неделя 15 является фундаментом блока тестирования. Неделя 16 продолжит его через TDD, сложные транзакционные и конкурентные сценарии, async/E2E-тесты, flaky-test диагностику и финальную стратегию регрессии.

## Результат недели

После завершения ученик умеет:

- объяснять назначение test suite и цену ложной уверенности;
- различать unit, integration, API и end-to-end тесты;
- понимать, что smoke и regression — назначение набора, а не отдельный технический уровень;
- выбирать минимальный уровень, который реально доказывает требование;
- формулировать проверяемое поведение через Given/When/Then или Arrange/Act/Assert;
- писать маленькие pytest-тесты с обычным `assert`;
- проверять исключения через `pytest.raises()`;
- понимать pytest discovery и node ID;
- запускать старые `unittest`/Django `TestCase` тесты через pytest без немедленного переписывания;
- конфигурировать `pytest`/`pytest-django` в одном явном месте;
- различать тест без database, `django_db` и `transactional_db`;
- использовать fixtures с минимально достаточным scope;
- понимать setup, yield/teardown и зависимость fixtures;
- не превращать корневой `conftest.py` в скрытую магию;
- строить deterministic factories/builders для пользователей, автомобилей, Offer и организаций;
- отделять factory default от важного для конкретного теста значения;
- применять parametrization для одной формы поведения с разными данными;
- регистрировать markers и собирать smoke/unit/integration/API наборы;
- использовать skip только для недоступного условия, а xfail — для известного дефекта с причиной;
- создавать unit-тесты чистых policies/calculations без Django database;
- использовать mock только на внешней или дорогой недетерминированной границе;
- патчить имя там, где его использует тестируемый модуль;
- не mock-ать ORM так сильно, что integration behavior исчезает;
- проверять database constraints, transactions и rollback реальной test PostgreSQL;
- тестировать DRF endpoints через настоящий authentication/permission path;
- проверять response contract, database transition и отсутствие side effects;
- использовать query-count assertions для защиты от N+1;
- измерять branch/line coverage как карту пробелов, а не целевой KPI;
- анализировать uncovered critical branch и consciously excluded code;
- запускать test groups воспроизводимо и сохранять краткий отчёт без secrets.

## Предварительные требования

- Недели 0–14 завершены полностью.
- Все дни недели 14 имеют минимум 7/10.
- Итоговый Authorized Dealership API недели 14 принят минимум на 8/10.
- Permission matrix, ownership scopes и service-level authorization приняты.
- 48 authorization scenarios имеют фактические результаты.
- OpenAPI совпадает с runtime.
- В `week_14_authorization/ASSESSMENT.md` указано: «Допуск к неделе 15: да».

## Продолжение проекта недели 14

После допуска переносится только принятый проект:

```text
week_14_authorization/day_07_authorized_api/
```

в:

```text
week_15_testing_foundation/day_07_test_suite/
```

Source branch/commit, database target и результаты исходных test commands фиксируются в `day_01_test_strategy.md`. Неделя 14 остаётся неизменной.

## Зависимости и activation gate

Новые development dependencies:

- `pytest`;
- `pytest-django`;
- `coverage`.

Точные версии заранее не фиксируются. При фактической активации нужно проверить:

1. поддерживаемые версии Python;
2. совместимость `pytest-django` с фактическими pytest и Django;
3. changelog и breaking changes конфигурации;
4. один выбранный формат настройки `pyproject.toml` или `pytest.ini`;
5. clean dependency resolution;
6. collection старых `unittest`/Django tests;
7. database smoke test на isolated PostgreSQL;
8. coverage command поверх того же test run.

Зависимости относятся к development/test group и не должны случайно становиться обязательными runtime-пакетами production image. Ничего не устанавливается при подготовке недели.

## Карта уровней тестирования

| Уровень | Что проверяет | Реальные зависимости | Типичный пример |
|---|---|---|---|
| Unit | одно правило/функцию в памяти | минимум | `can_cancel_offer()` отклоняет completed Offer |
| Integration | совместную работу кода с PostgreSQL/Django | database, ORM | sale service откатывает все rows при ошибке |
| API | HTTP/DRF contract целиком | routing, auth, DB | buyer не видит чужой Offer |
| End-to-end | систему снаружи как клиент | сервер и инфраструктура | полный register→offer flow |

На неделе 15 обязательны unit, integration и API. Полноценный E2E через live environment переносится в неделю 16.

## Smoke и regression

- **Smoke** — короткий набор, показывающий, что основные части вообще запускаются.
- **Regression** — набор, предотвращающий возврат уже исправленной ошибки или нарушение принятого behavior.

Один API test может одновременно быть integration, smoke и regression в разных классификациях. Marker должен отражать полезный способ запуска, а не создавать спор о терминах.

## Правило выбора теста

Используйте самый дешёвый уровень, который действительно доказывает риск:

```text
чистая формула -> unit
constraint/transaction/query -> integration with PostgreSQL
status/serializer/auth/permission -> API
весь пользовательский поток и инфраструктура -> E2E, неделя 16
```

Mock не способен доказать поведение реальной database transaction, SQL constraint или DRF router.

## Анатомия теста

```text
Arrange/Given: минимальное исходное состояние
Act/When: одно наблюдаемое действие
Assert/Then: результат + важные side effects
```

Имя теста описывает поведение:

```text
test_buyer_cannot_cancel_foreign_pending_offer
```

а не техническую деталь:

```text
test_method_3
```

## Test oracle

**Oracle** — источник ожидаемого результата. Он не должен слепо повторять реализацию. Если test вычисляет скидку той же формулой, что production function, обе могут содержать одинаковую ошибку.

Лучше использовать:

- вручную проверенные небольшие значения;
- таблицу бизнес-примеров;
- известный инвариант;
- независимый способ вычисления;
- database constraint или публичный contract.

## Структура pytest

Рекомендуемая структура адаптируется к проекту:

```text
tests/
├── conftest.py
├── factories/
│   ├── accounts.py
│   ├── catalog.py
│   └── trading.py
├── unit/
├── integration/
├── api/
└── regression/
```

Допустима app-local структура `app/tests/`. Важно выбрать один понятный принцип, исключить duplicate collection и документировать команды.

## Fixtures и scope

Fixture создаёт test dependency. Scope выбирается по времени жизни:

- `function` — новый объект для каждого теста; безопасный default;
- `class` — общий в пределах test class;
- `module` — общий для файла;
- `package` — общий для package;
- `session` — один на весь run.

Mutable database entities обычно function-scoped. Session-scoped mutable object делает тесты зависимыми от порядка.

## Factories и builders

Factory создаёт валидный объект с безопасными defaults, но позволяет явно переопределить важное:

```python
offer = make_offer(buyer=buyer, status=OfferStatus.PENDING)
```

Не скрывайте в factory:

- автоматическую выдачу superuser;
- случайный role;
- неожиданную отправку email;
- создание десятков unrelated rows;
- real-time/random values, влияющие на assertion.

Faker не обязателен на этой неделе. Если он уже выбран после compatibility gate, используйте seeded/deterministic данные и не поручайте ему бизнес-значимые границы.

## Parametrization, markers, skip и xfail

Parametrization подходит, когда меняются данные, а Arrange/Act/Assert остаются теми же. Не упаковывайте в одну таблицу совершенно разные use cases.

Markers регистрируются в config, например:

- `unit`;
- `integration`;
- `api`;
- `smoke`;
- `slow`.

Unknown marker должен быть ошибкой configuration, а не молчаливым warning.

`skip` означает, что test невозможно/неуместно запустить в текущем условии. `xfail(strict=True)` фиксирует известный ожидаемый дефект и неожиданно прошедший test тоже требует внимания. Нельзя использовать их для сокрытия обычного падения.

## Mock boundaries

Mock полезен для контролируемой замены:

- внешнего email/provider adapter;
- HTTP client к сторонней системе;
- clock/random UUID/token generator, если dependency введена явно;
- дорогостоящего внешнего side effect.

Не следует mock-ать:

- собственную policy, когда тестируется service, который обязан её вызвать без проверки результата;
- ORM chain вместо integration test;
- serializer/router/authentication в API test;
- всё подряд ради зелёного результата.

Патч применяется к имени в модуле-потребителе, а `spec`/`autospec` помогает обнаружить неправильный интерфейс.

## Database isolation

- Test database всегда отдельна от development/production.
- Тест без `django_db` не получает database случайно.
- Обычный ORM test использует `django_db`/`db`.
- Реальные transaction boundaries, `select_for_update()` и commit behavior требуют `transactional_db` и отдельного сценария; подробно — неделя 16.
- PostgreSQL-specific constraints проверяются PostgreSQL, а не SQLite substitute.
- Test не зависит от auto-increment ID, если contract этого не требует.
- Порядок выполнения тестов не должен менять результат.

## API tests

API test проверяет одновременно:

- authentication path;
- permissions и object scope;
- serializer input/output;
- status и error envelope;
- database transition;
- отсутствие запрещённых side effects;
- content type/headers, если они входят в contract.

`force_authenticate()` допустим для узкого view unit/integration test, но не является единственным доказательством JWT/security path.

## Coverage

Coverage отвечает «какие строки/ветви выполнялись», а не «правильны ли assertions». Поэтому:

- измеряются line и branch coverage;
- сначала анализируются critical services/policies, а не общий процент;
- исключения из отчёта имеют причину;
- generated migrations/settings/boilerplate не маскируют отсутствие test бизнес-ветвей;
- повышение процента без нового meaningful assertion не считается прогрессом.

## Набор итоговых инвариантов недели

- raw passwords/tokens не сохраняются и не возвращаются;
- active+verified gates работают;
- purpose/expiry/replay action tokens защищены;
- role/object permissions не пропускают чужие данные;
- Offer создаётся/отменяется только по policy;
- balance/stock не становятся отрицательными;
- transaction rollback не оставляет partial movements;
- promotion boundaries и price calculation корректны;
- statistics scoped по роли;
- critical list query budgets защищены;
- OpenAPI/error envelopes не расходятся с runtime;
- clean test run воспроизводим.

## Архитектурные границы test suite

| Компонент | Обязанность | Не должен делать |
|---|---|---|
| Unit test | быстро проверять одно правило | поднимать DB без причины |
| Integration test | проверять ORM/DB/service cooperation | mock-ать саму database semantics |
| API test | проверять HTTP contract | утверждать private implementation calls без необходимости |
| Fixture | предоставлять dependency/state | содержать скрытый Act/assertion |
| Factory | создавать понятный valid object | случайно выдавать privilege/side effect |
| Mock/fake | заменять внешнюю границу | повторять весь production implementation |
| Marker | давать способ выбрать набор | быть заменой test level documentation |
| Coverage report | показывать исполненные ветви | считаться доказательством корректности |

## Структура модуля

- [THEORY.md](THEORY.md) — уровни, pytest, fixtures, factories, mocks, Django/DRF и coverage;
- [PRACTICE.md](PRACTICE.md) — семь подробных дней;
- [ASSESSMENT.md](ASSESSMENT.md) — оценки, ошибки и допуск;
- [notes.md](notes.md) — личные объяснения ученика;
- `day_01_test_strategy.md` — baseline, dependency gate и test inventory;
- `day_02_pytest_basics.md` — discovery, assertions и migration старых tests;
- `day_03_fixtures_database.md` — fixtures, scopes и database isolation;
- `day_04_parametrize_factories.md` — cases, markers и test data builders;
- `day_05_unit_mocking.md` — unit contracts и mock audit;
- `day_06_api_coverage.md` — API/integration/regression и coverage gaps;
- `day_07_test_suite/` — итоговый накопительный проект;
- `day_07_test_suite/TEST_STRATEGY.md` — levels, risks и commands;
- `day_07_test_suite/TEST_INVENTORY.md` — behavior-to-test map;
- `day_07_test_suite/FIXTURE_MAP.md` — ownership и scope fixtures;
- `day_07_test_suite/MOCK_AUDIT.md` — внешние границы и patch targets;
- `day_07_test_suite/COVERAGE_AUDIT.md` — meaningful gaps;
- `day_07_test_suite/TEST_MATRIX.md` — 54 итоговых сценария.

## Целевое дерево изменений

```text
day_07_test_suite/
├── manage.py
├── pyproject.toml или pytest.ini
├── README.md
├── TEST_STRATEGY.md
├── TEST_INVENTORY.md
├── FIXTURE_MAP.md
├── MOCK_AUDIT.md
├── COVERAGE_AUDIT.md
├── TEST_MATRIX.md
├── tests/
│   ├── conftest.py
│   ├── factories/
│   ├── unit/
│   ├── integration/
│   ├── api/
│   └── regression/
└── принятые apps/config/migrations недели 14/
```

## Порядок прохождения

1. Получить явный допуск недели 14.
2. Зафиксировать source, database, dependencies и исходные команды tests.
3. Проверить compatibility pytest stack до установки.
4. Читать только теорию текущего дня и связанную документацию.
5. До запуска записать prediction и risk, который доказывает test.
6. Выполнить маленький test slice.
7. Запустить узкий node ID, затем соответствующий marker, затем regressions.
8. Заполнить journal и самооценку.
9. Написать: `Проверь день N недели 15`.
10. Самостоятельно исправить обязательные замечания.

## Границы недели

На неделе 15 не требуются:

- полноценный TDD red-green-refactor workflow — неделя 16;
- сложные конкурентные race/deadlock tests — неделя 16;
- async test stack и event-loop fixtures — неделя 16 при наличии async-кода;
- live-server/browser E2E — неделя 16;
- property-based testing/Hypothesis;
- mutation-testing framework;
- parallel execution/pytest-xdist;
- flaky-test rerun plugins;
- snapshot/golden-master framework;
- external test-management system;
- production load testing;
- CI/CD configuration — недели 20–22;
- реальный SMTP, payment или сторонний HTTP service;
- Faker/factory library без отдельного compatibility decision.

## Критические ошибки

- tests подключаются к development/production/shared database;
- expected value вычисляется копией production algorithm и не является независимым oracle;
- test проходит без meaningful assertion;
- negative test проверяет только status и пропускает database side effect;
- test зависит от порядка или состояния предыдущего test;
- session/module fixture разделяет mutable business row между tests без доказанной необходимости;
- root `conftest.py` автоматически создаёт privileged user для всех tests;
- integration/API test mock-ает ORM/auth/router так, что главный риск не выполняется;
- external mock патчится не там, где symbol используется, и test проходит случайно;
- `except Exception`/mock скрывает unexpected production failure;
- skip/xfail используется для сокрытия обычного failing behavior;
- unknown markers игнорируются;
- старые tests перестают собираться без migration decision;
- только `force_authenticate()` используется как доказательство JWT/permission path;
- SQLite используется как единственное доказательство PostgreSQL constraint/transaction;
- coverage процент объявляется доказательством качества;
- critical uncovered branch оставлен без решения/объяснения;
- test logs/report содержат password, JWT, action token или DSN;
- основной suite нельзя воспроизвести одной документированной командой.

## Критерий завершения

- дни 1–6 приняты минимум на 7/10;
- итоговый test foundation принят минимум на 8/10;
- pytest/pytest-django/coverage versions и config обоснованы;
- старые unittest/Django tests продолжают собираться или имеют явный migration plan;
- unit/integration/API уровни различены и имеют команды;
- smoke/regression markers зарегистрированы;
- database access разрешён только нужным tests;
- fixtures имеют минимальный scope и понятный teardown;
- factories deterministic и не скрывают privilege/side effects;
- parametrization сохраняет читаемые case IDs;
- skip/xfail имеют причины и не скрывают обязательные failures;
- mocks ограничены внешними границами и имеют interface checks;
- critical policies/calculations имеют positive/boundary/negative unit tests;
- database constraints/rollback проверены на PostgreSQL;
- DRF/JWT/permission paths имеют API tests;
- query budgets защищены;
- branch coverage измерен и critical gaps разобраны;
- suite воспроизводима из clean state;
- `TEST_MATRIX.md` содержит actual results 54 сценариев;
- минимум 36 из 48 вопросов защиты отвечены уверенно;
- в `ASSESSMENT.md` указано: «Допуск к неделе 16: да».

## Официальные материалы

- [pytest documentation](https://docs.pytest.org/en/stable/)
- [pytest assertions](https://docs.pytest.org/en/stable/how-to/assert.html)
- [pytest fixtures](https://docs.pytest.org/en/stable/how-to/fixtures.html)
- [pytest parametrization](https://docs.pytest.org/en/stable/how-to/parametrize.html)
- [pytest markers](https://docs.pytest.org/en/stable/how-to/mark.html)
- [pytest-django documentation](https://pytest-django.readthedocs.io/en/latest/)
- [pytest-django database access](https://pytest-django.readthedocs.io/en/latest/database.html)
- [Django testing overview](https://docs.djangoproject.com/en/5.2/topics/testing/overview/)
- [Django testing tools](https://docs.djangoproject.com/en/5.2/topics/testing/tools/)
- [DRF testing](https://www.django-rest-framework.org/api-guide/testing/)
- [Python `unittest.mock`](https://docs.python.org/3/library/unittest.mock.html)
- [Coverage.py documentation](https://coverage.readthedocs.io/en/latest/)

## Текущий статус

Неделя 15 только подготовлена. Текущий активный этап остаётся в `week_00_basics/ASSESSMENT.md`: день 2 недели 0. До допуска недели 14 не переносить проект и не устанавливать test dependencies.
