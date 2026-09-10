# Теория недели 15: фундамент тестирования

Статус: **читать после допуска из недели 14**.

Тест — это код, который выполняет систему в контролируемом состоянии и сравнивает наблюдаемое поведение с ожидаемым contract. Зелёный test полезен только тогда, когда он действительно мог стать красным при нарушении проверяемого правила.

## 1. Зачем нужны автоматические тесты

Тесты помогают:

- быстро обнаружить regression;
- зафиксировать ожидаемое поведение;
- безопаснее менять архитектуру;
- проверить отрицательные и редкие ветви;
- воспроизвести ошибку;
- дать другому разработчику выполняемый пример contract.

Тесты не доказывают отсутствие всех ошибок. Они уменьшают известный риск в выбранных сценариях.

## 2. Test case, suite и runner

- **Test case** — один проверяемый сценарий.
- **Test suite** — набор тестов.
- **Runner** — инструмент, который собирает и запускает tests, например pytest.
- **Assertion** — проверка ожидаемого факта.
- **Failure** — assertion показал неправильное поведение.
- **Error** — test не смог нормально выполнить сценарий из-за неожиданной проблемы setup/runtime.

## 3. Unit test

Unit test проверяет одно правило с минимальными dependencies:

```python
def test_discount_is_zero_before_promotion_starts():
    result = calculate_discount(
        price=Decimal("100.00"),
        percent=Decimal("10.00"),
        is_active=False,
    )

    assert result == Decimal("0.00")
```

Если функция не требует Django/database, unit test тоже не должен подключать их без причины.

## 4. Integration test

Integration test проверяет совместную работу компонентов:

- Django ORM и PostgreSQL constraint;
- service и transaction;
- serializer и model validation;
- email service и Django locmem backend.

Такой test медленнее unit, но доказывает реальные свойства интеграции, которые mock не воспроизводит.

## 5. API test

API test отправляет HTTP-like request через DRF/Django test client и проверяет:

- route;
- authentication;
- permission;
- serializer;
- status/body/headers;
- database transition;
- side effects.

Он не обязан запускать реальный TCP server, поэтому это ещё не полный E2E.

## 6. End-to-end test

E2E выполняет пользовательский flow через развернутые границы системы. Он ценен для критического happy path, но медленнее, сложнее и хуже локализует причину ошибки.

Полноценный E2E и live-server practice будут в неделе 16.

## 7. Smoke и regression — не уровни

Smoke отвечает: «живы ли ключевые функции после сборки?» Regression отвечает: «не вернулась ли старая ошибка?»

Один API test может быть и smoke, и regression. Эти слова описывают назначение/набор запуска, а unit/integration/API — техническую глубину.

## 8. Пирамида и risk-based выбор

Обычно дешёвых unit tests больше, integration/API — меньше, E2E — совсем немного. Это не обязательные проценты.

Выбор начинается с риска:

```text
формула скидки ошибочна -> unit examples/boundaries
transaction частично записывает rows -> PostgreSQL integration
permission выдаёт чужой объект -> API test
весь flow не работает после deploy -> E2E
```

## 9. Тестируем поведение, а не строки реализации

Хрупкий test утверждает точный порядок private helper calls, хотя public result правильный. Полезный test проверяет contract и важный side effect.

Private call стоит проверять только если сам вызов является требованием: например, письмо действительно должно быть отправлено внешнему adapter один раз.

## 10. Arrange–Act–Assert

Один тест удобно читать в трёх блоках:

```python
def test_completed_offer_cannot_be_cancelled():
    # Arrange
    offer = make_offer(status=OfferStatus.COMPLETED)

    # Act
    decision = can_cancel_offer(actor=offer.buyer.user, offer=offer)

    # Assert
    assert decision is False
```

Один главный Act уменьшает неоднозначность failure.

## 11. Given–When–Then

Это тот же принцип языком поведения:

- Given — исходное состояние;
- When — действие;
- Then — наблюдаемый результат.

Он особенно полезен в scenario matrix и именах tests.

## 12. Test oracle

Oracle — откуда берётся expected result. Плохой вариант:

```python
expected = price - price * percent / 100
assert calculate_price(price, percent) == expected
```

Если production использует ту же ошибочную формулу, test повторит ошибку. Лучше взять вручную проверенный пример `100.00`, `10%` → `90.00` и отдельно boundaries.

## 13. Детерминизм

При одинаковом code/state test должен давать одинаковый результат. Источники nondeterminism:

- текущее время;
- случайные числа;
- порядок QuerySet без ordering;
- shared cache/database;
- сеть;
- real email;
- locale/timezone;
- зависимость от порядка tests.

Их контролируют dependency injection, fixed data, explicit ordering и isolated fakes/backends.

## 14. Isolation

Test не должен оставлять состояние, влияющее на следующий test. Проверка isolation:

1. каждый test отдельно;
2. файл целиком;
3. suite в другом порядке;
4. повторный run.

Если test проходит только после другого test, setup неполон.

## 15. Pytest discovery

Pytest автоматически ищет файлы/functions/classes по соглашениям, обычно:

- `test_*.py` и `*_test.py`;
- функции `test_*`;
- классы `Test*` без собственного `__init__`.

Фактические patterns могут быть изменены config. Перед migration нужно выполнить collection-only и убедиться, что старые tests не исчезли.

## 16. Node ID и точечный запуск

Node ID однозначно указывает test:

```text
tests/unit/test_prices.py::test_expired_promotion_is_ignored
```

Рабочий цикл: сначала один node ID, затем файл/marker, затем полный regression suite.

## 17. Обычный `assert`

Pytest переписывает assertions и показывает значения выражений:

```python
assert response.status_code == 201
assert response.data["status"] == "pending"
```

Не объединяйте десять разных фактов одним сложным boolean. Падение должно указывать, какой contract нарушен.

## 18. Проверка исключений

```python
with pytest.raises(InsufficientBalanceError):
    purchase_car(...)
```

Если message/code является public contract, его тоже можно проверить. Не делайте слишком широкий `pytest.raises(Exception)`: неожиданная ошибка тогда будет считаться ожидаемой.

## 19. Float и `pytest.approx`

Для вычислений с `float` используется tolerance:

```python
assert 0.1 + 0.2 == pytest.approx(0.3)
```

Но деньги проекта остаются `Decimal`; `approx` не является причиной заменить правильный денежный тип на `float`.

## 20. Failure должен быть информативным

Хорошее имя и простые assertions обычно достаточны. Дополнительное message полезно, если без него неясен бизнес-контекст:

```python
assert movement_count == 0, "denied purchase created ledger movement"
```

Не скрывайте полезную pytest introspection самодельными try/except.

## 21. Pytest и `unittest`

Pytest умеет собирать существующие `unittest.TestCase` и Django `TestCase`. Переход может быть постепенным:

- сначала обеспечить общую collection и green baseline;
- новые tests писать в выбранном стиле;
- старые переписывать только при пользе;
- не смешивать pytest fixtures внутри `unittest.TestCase` без понимания ограничений.

## 22. Конфигурация

Один config определяет:

- Django settings module;
- test paths/patterns;
- registered markers;
- strict marker/config behavior;
- полезные default options;
- warnings policy.

Не копируйте одновременно противоречащие `pytest.ini`, `setup.cfg` и `pyproject.toml` настройки.

Формат pytest-настроек в `pyproject.toml` зависит от major version, поэтому activation gate проверяет актуальную документацию.

## 23. Plugins и совместимость

Plugin расширяет runner и может зависеть от конкретных pytest/Django/Python versions. `pytest-django` предоставляет database marks/fixtures и настройку Django.

Успешный `pip install` ещё не доказывает совместимость. Нужны collection, simple DB test и полный старый suite.

## 24. Database access явный

Pytest-django по умолчанию не разрешает database произвольному test. Это полезно: unit test случайно обратившийся к ORM должен упасть.

Database test помечается:

```python
@pytest.mark.django_db
def test_offer_is_saved():
    ...
```

или получает fixture `db`.

## 25. `django_db` и `transactional_db`

Обычный `django_db` подходит большинству ORM tests. Реальное commit/rollback visibility, row locks и multi-connection behavior требуют transaction-aware setup, например `transactional_db`.

Не выдавайте `transactional_db` всем tests: он дороже и меняет isolation semantics. Сложные concurrency tests — неделя 16.

## 26. Django `TestCase` и transaction illusion

Django `TestCase` ускоряет tests, оборачивая каждый test в transaction. Из-за этого `on_commit()` и реальные transaction boundaries могут вести себя иначе, чем production.

Выбирайте test base/fixture по проверяемому риску и используйте специальные helpers для on-commit callbacks, когда это contract.

## 27. Fixture как dependency

```python
@pytest.fixture
def buyer():
    return make_user(role=UserRole.BUYER)

def test_buyer_role(buyer):
    assert buyer.role == UserRole.BUYER
```

Имя fixture должно объяснять, что предоставляется. Fixture выполняет setup, но assertion остаётся в test.

## 28. Граф fixtures

Fixture может зависеть от другой fixture:

```text
buyer_offer -> buyer_profile -> buyer_user -> db
```

Граф должен оставаться небольшим и видимым. Слишком глубокая цепочка затрудняет понимание исходного состояния.

## 29. Scope fixtures

- `function` — безопасный default;
- `class/module/package/session` — оптимизация для дорогого неизменяемого ресурса.

Более широкий scope не может свободно зависеть от более узкого. Главное правило: mutable business data не должна неожиданно разделяться между tests.

## 30. Yield и teardown

```python
@pytest.fixture
def configured_adapter():
    adapter = FakeAdapter()
    adapter.start()
    yield adapter
    adapter.stop()
```

Teardown должен выполниться и при failure. Для нескольких ресурсов полезны context managers/finalizers. Не оставляйте процессы, файлы или patched environment.

## 31. `conftest.py`

Fixtures из `conftest.py` доступны tests в его directory tree без import. Это удобно, но скрыто.

В root оставляйте общие безопасные fixtures. Domain-specific factories/fixtures храните ближе к domain tests. Не импортируйте fixtures из `conftest.py` как обычный production module.

## 32. Autouse fixtures

Autouse запускается без явного параметра test. Допустимые примеры:

- запрет real network;
- очистка test cache по принятой policy;
- безопасная общая timezone.

Опасный autouse создаёт superuser/organization или меняет settings так, что test не показывает dependencies.

## 33. Factory и builder

Factory создаёт valid test object с defaults и overrides. Builder может собирать domain object без database.

```python
buyer = make_buyer(email="buyer@example.invalid")
offer = make_offer(buyer=buyer, status=OfferStatus.PENDING)
```

Test явно задаёт каждое значение, влияющее на смысл assertion.

## 34. Random/Faker данные

Random data полезны для разнообразия, но мешают воспроизведению. Для core scenarios используйте фиксированные значения. Если Faker выбран:

- seed фиксируется;
- failing value попадает в безопасный report;
- бизнес-boundary задаётся явно;
- uniqueness не зависит от случайной удачи.

Faker не нужен для доказательства `balance == 0` boundary.

## 35. Parametrization

```python
@pytest.mark.parametrize(
    ("status", "allowed"),
    [
        pytest.param(OfferStatus.PENDING, True, id="pending"),
        pytest.param(OfferStatus.COMPLETED, False, id="completed"),
    ],
)
def test_offer_cancel_policy(status, allowed):
    ...
```

Parametrize одну форму поведения. Если setup/action/assert различаются, отдельные tests читаются лучше.

## 36. Case IDs

Хороший ID показывает business case: `balance-exactly-equals-price`, `promotion-expired-one-second`. ID `case-7` ничего не объясняет.

Failure report должен позволить понять упавшую границу без открытия таблицы данных.

## 37. Markers

Markers позволяют запускать группы:

```text
pytest -m unit
pytest -m "api and smoke"
pytest -m "not slow"
```

Каждый custom marker регистрируется. Strict markers помогают ловить опечатки вроде `integraiton`, которые иначе молча исключат test из CI selection.

## 38. Skip и xfail

- `skip` — test не может быть выполнен в текущем условии;
- `xfail` — известный defect/ограничение, test ожидаемо падает.

Указывайте reason/issue и узкое условие. `xfail(strict=True)` делает неожиданный pass заметным. Нельзя пометить xfail весь обязательный suite ради зелёного отчёта.

## 39. Что такое mock

Mock записывает взаимодействия и возвращает настроенные значения. Он полезен, если важно проверить call к внешней границе без реального side effect.

Но mock выполняет только то, что вы ему сказали. Неправильно настроенный mock может подтвердить выдуманный interface.

## 40. Patch where looked up

Если `accounts.services` сделал:

```python
from accounts.emails import send_verification_email
```

то patch обычно направляется на `accounts.services.send_verification_email`, потому что именно там имя используется. Patch исходного `accounts.emails.send_verification_email` может не затронуть уже импортированную ссылку.

## 41. `spec` и `autospec`

Spec ограничивает mock реальным interface, autospec учитывает signature. Это снижает шанс вызвать несуществующий method или неправильные arguments.

Spec не доказывает business behavior; integration test настоящего adapter всё равно может быть нужен.

## 42. Fake, stub и spy

- **Stub** возвращает заранее заданный ответ.
- **Spy** записывает вызовы реального/обёрнутого объекта.
- **Mock** обычно настраивает ожидания взаимодействий.
- **Fake** имеет упрощённую рабочую реализацию, например locmem email backend.

Термины часто используются нестрого. Важнее описать, какую границу заменили и какой риск больше не проверяется.

## 43. Что не следует mock-ать

Не заменяйте mock-ом главный объект риска:

- PostgreSQL constraint;
- `transaction.atomic()`/rollback;
- DRF authentication/permission path в security integration test;
- router/serializer contract в API test;
- собственную formula, если тестируется formula.

Mock ORM chain часто проверяет настройку mock, а не запрос.

## 44. Django и DRF clients

Django Client подходит обычным Django views. DRF предоставляет `APIClient`, `APIRequestFactory` и `APITestCase`.

APIClient удобен для router/auth/content negotiation. APIRequestFactory полезен для узкого вызова view. Выбор зависит от того, какую часть stack нужно доказать.

## 45. Authentication в API tests

Нужно различать:

- настоящий JWT endpoint и Bearer header;
- `force_authenticate()` для узкой проверки view logic;
- session login для Django admin/SessionAuthentication.

Хотя бы один test каждого critical protected flow проходит настоящий configured authentication path. Иначе signature/expiry/header/backend могут остаться непроверенными.

## 46. Assertions состояния и side effects

После mutation test проверяет не только response:

- нужные rows созданы/изменены;
- forbidden rows не изменены;
- balance/stock/ledger согласованы;
- mail count/recipient правильны;
- token state changed once;
- rollback удалил partial writes;
- logs не содержат secret.

Для deny особенно важно сравнить before/after.

## 47. Query-count tests

`django_assert_num_queries`/Django helpers фиксируют budget. Сравнивайте N=2 и N=20, чтобы обнаружить линейный рост.

Не привязывайтесь к случайному числу без объяснения SQL roles. Обновлять budget после regression можно только вместе с причиной.

## 48. Coverage

Line coverage показывает выполненные строки. Branch coverage показывает выбранные ветви `if`/условий.

100% execution не гарантирует полезных assertions:

```python
def test_service_runs():
    purchase_car(...)
```

Строки выполнены, но результат не проверен.

Анализируйте в первую очередь critical modules:

- prices/promotion selection;
- authorization policies;
- account token services;
- balance/stock transactions;
- Offer state transitions;
- error boundaries.

## 49. Coverage exclusions

Исключение должно иметь причину. Обычно отдельно рассматриваются:

- generated migrations;
- `manage.py`/ASGI/WSGI boilerplate;
- debug-only unreachable branches;
- settings variants.

Нельзя исключить сложную business ветвь только потому, что её трудно тестировать.

## 50. Типичные ошибки

- test без assertion;
- assertion проверяет реализацию, а не behavior;
- expected formula копирует production;
- слишком большой Arrange скрывает смысл;
- shared mutable fixture создаёт order dependency;
- каждый test использует database «на всякий случай»;
- unit test случайно ходит в ORM;
- integration test mock-ает ORM;
- `pytest.raises(Exception)` принимает любую ошибку;
- parametrize объединяет разные use cases;
- random data делают failure невоспроизводимым;
- autouse fixture скрывает superuser;
- patch направлен не в module lookup;
- mock не имеет spec и принимает любой call;
- `force_authenticate` подменяет весь auth proof;
- negative test не проверяет side effect;
- coverage percent становится целью;
- skip/xfail скрывает обычное падение;
- command работает только из IDE автора.

## 51. Вопросы для самопроверки

1. Что автоматический test способен доказать и чего не способен?
2. Чем test case отличается от suite и runner?
3. Что делает тест unit-тестом?
4. Какой риск требует integration test с PostgreSQL?
5. Что проверяет API test?
6. Чем API test без live server отличается от E2E?
7. Почему smoke и regression не являются техническими уровнями?
8. Как risk определяет уровень теста?
9. Почему проверка private calls делает test хрупким?
10. Что входит в Arrange, Act и Assert?
11. Почему в test желательно одно главное действие?
12. Что такое test oracle?
13. Почему нельзя копировать production formula в expected?
14. Какие источники nondeterminism есть в проекте?
15. Как обнаружить зависимость tests от порядка?
16. Как pytest находит tests?
17. Что такое node ID?
18. Почему обычный `assert` удобен в pytest?
19. Почему `pytest.raises(Exception)` слишком широк?
20. Когда нужен `pytest.approx`, а когда остаётся `Decimal`?
21. Как pytest запускает старые unittest/Django tests?
22. Почему нельзя держать противоречащие pytest configs?
23. Что проверяет activation gate plugin?
24. Почему database access должен быть явным?
25. Чем `django_db` отличается от `transactional_db` по назначению?
26. Почему Django `TestCase` может скрыть on-commit behavior?
27. Что fixture предоставляет test?
28. Чем опасен глубокий fixture graph?
29. Почему function scope является безопасным default?
30. Что должен гарантировать teardown?
31. Где должны жить общие и domain fixtures?
32. Когда autouse оправдан, а когда опасен?
33. Чем factory отличается от случайной пачки setup-кода?
34. Какие factory values test обязан задать явно?
35. Почему Faker не подходит для бизнес-boundary по умолчанию?
36. Когда parametrization улучшает test?
37. Каким должен быть case ID?
38. Зачем регистрировать markers и включать strict mode?
39. Чем skip отличается от xfail?
40. Что реально делает mock?
41. Почему patch делают where looked up?
42. Что дают spec/autospec?
43. Почему mock ORM не доказывает constraint/transaction?
44. Когда использовать APIClient и APIRequestFactory?
45. Почему `force_authenticate()` не является полным auth test?
46. Что проверить после запрещённой mutation кроме status?
47. Как query-count test обнаруживает N+1?
48. Почему 100% coverage не гарантирует качество?

## Официальные источники

- [pytest documentation](https://docs.pytest.org/en/stable/)
- [pytest assertions](https://docs.pytest.org/en/stable/how-to/assert.html)
- [pytest fixtures](https://docs.pytest.org/en/stable/how-to/fixtures.html)
- [pytest parametrization](https://docs.pytest.org/en/stable/how-to/parametrize.html)
- [pytest markers](https://docs.pytest.org/en/stable/how-to/mark.html)
- [pytest skip/xfail](https://docs.pytest.org/en/stable/how-to/skipping.html)
- [pytest monkeypatch](https://docs.pytest.org/en/stable/how-to/monkeypatch.html)
- [pytest with unittest](https://docs.pytest.org/en/stable/how-to/unittest.html)
- [pytest-django database access](https://pytest-django.readthedocs.io/en/latest/database.html)
- [pytest-django helpers](https://pytest-django.readthedocs.io/en/latest/helpers.html)
- [Django testing overview](https://docs.djangoproject.com/en/5.2/topics/testing/overview/)
- [Django testing tools](https://docs.djangoproject.com/en/5.2/topics/testing/tools/)
- [DRF testing](https://www.django-rest-framework.org/api-guide/testing/)
- [Python `unittest.mock`](https://docs.python.org/3/library/unittest.mock.html)
- [Coverage.py](https://coverage.readthedocs.io/en/latest/)
