# Практика недели 16: продвинутая стратегия тестирования

## Как сдавать работу

Практика выполняется только после допуска из недели 15. Каждый день:

1. прочитайте соответствующий раздел `THEORY.md` и документацию;
2. заполните прогнозы до запуска примеров;
3. создайте tests/production changes в копии принятого проекта;
4. выполните обязательные команды на isolated test PostgreSQL;
5. внесите в журнал фактические команды, node IDs, результаты и объяснения;
6. попросите наставника проверить работу;
7. самостоятельно исправьте обязательные замечания.

Наставник читает и запускает работу, но не переписывает её во время обычной проверки. Все секреты и реальные персональные данные запрещены.

## Общие обозначения

- `<project_root>` — реальный корень Django-проекта внутри `day_07_quality_gate/` после копирования недели 15;
- `<test_path>` — фактический путь теста, выбранный по структуре проекта;
- `<node_id>` — точный pytest node ID;
- `S01…S60` — стабильные ID итоговой матрицы;
- `PASS`, `FAIL`, `N/A with evidence`, `DEFERRED` — допустимые статусы с пояснением.

Нельзя подменять неизвестный реальный путь придуманным. Сначала выполнить inventory, затем вписать найденный path.

---

## День 1. TDD и characterization test

### Паспорт дня

**Цель:** научиться добавлять одно маленькое бизнес-правило через доказанный цикл red-green-refactor и безопасно менять один существующий path под защитой characterization test.

**Рабочие файлы или каталог:**

- production/tests внутри `week_16_advanced_testing/day_07_quality_gate/<project_root>/`;
- журнал `week_16_advanced_testing/day_01_tdd_contract.md`;
- итоговые записи `day_07_quality_gate/TDD_LOG.md` и `TEST_MATRIX.md`, строки `S01–S10`.

**Результат:** чистое правило `calculate_stock_days()` или согласованный эквивалент, tests его контракта, один characterization/regression test существующего поведения и журнал всех трёх TDD-состояний.

**Порядок выполнения:**

1. Скопировать принятый проект недели 15 и зафиксировать baseline.
2. Найти место для чистого правила, не зависящего от Django ORM.
3. Письменно определить входы, выход и граничную policy.
4. Написать один test, получить полезный red и сохранить причину.
5. Реализовать минимум для green, затем добавить остальные cases.
6. Выполнить refactor без изменения contract.
7. Найти один принятый legacy path и защитить его characterization test.
8. Запустить targeted и весь suite; заполнить `S01–S10`.

**Наблюдаемый результат:** журнал показывает три разные стадии одного изменения; финальный targeted и full suite проходят, а намеренная мутация правила делает нужный test красным.

**Готово, если:**

- red связан с отсутствующим/неверным behavior, а не setup error;
- contract отрицательных значений, нулевого спроса и округления определён явно;
- каждый test имеет понятное имя и независимый oracle;
- refactor не меняет observable behavior;
- characterization test защищает реальный важный path;
- `S01–S10` содержат фактические результаты.

**Пример формата записи, не решение:**

```text
S03 | quantity=11, demand=3 | expected=3 full days | node id: ... | PASS
RED: expected 3, received NotImplemented — expected business failure
```

**Обязательно для зачёта:** все шаги, полезный red, mutation proof, 10 сценариев, targeted и full run.

**Рекомендация:** сохранить маленькие Git commits `red`, `green`, `refactor`, если workflow проекта это позволяет.

### Документация

- [pytest — assertions](https://docs.pytest.org/en/stable/how-to/assert.html) — failure introspection и проверка исключений; обязательно прочитать части про обычный `assert` и `pytest.raises()`.

### Упражнение 1. Baseline и контракт

**Исходные данные:** принятый проект недели 15, его 54 scenario results и текущая структура domain/services.

**Действие:** скопируйте проект в `day_07_quality_gate/`; запишите source commit/ветку, Python/Django/PostgreSQL versions, test database alias и baseline commands. Выберите имя/модуль для правила расчёта полных дней запаса. Если `calculate_stock_days` конфликтует с domain, согласуйте равноценное чистое правило с наставником до реализации.

**Результат:** в `day_01_tdd_contract.md` есть baseline и контракт: types, допустимые значения, возвращаемое значение, exceptions и округление.

**Проверки:** clean full suite; unit/integration/API marker groups; `quantity=0`; `average_daily_sales=0`; отрицательные входы; quantity не делится на demand без остатка.

### Упражнение 2. Первый red и green

**Исходные данные:** один обычный пример из контракта, например `quantity=11`, `average_daily_sales=3`.

**Действие:** до реализации напишите один test. Запустите только его, убедитесь, что причина red соответствует отсутствующему правилу; затем добавьте минимальный production code.

**Результат:** сохранены команда, краткий failure excerpt своими словами и green result с duration.

**Проверки:** test собран; red не является import/fixture/config failure; после green проходит targeted test; старый suite не сломан.

### Упражнение 3. Полный contract и refactor

**Исходные данные:** таблица `S01–S08`: обычное деление, неполный день, нулевой quantity, zero demand policy, оба граничных случая и два отрицательных input cases.

**Действие:** добавьте tests по одному behavior за цикл, затем улучшите имена/структуру функции без изменения результата.

**Результат:** восемь scenarios, чистая функция без database/clock/global mutable state и запись о refactor.

**Проверки:** все строки таблицы; exception type/message проверены только насколько это часть contract; test oracle не вызывает production function повторно для expected value; mutation `//`→`round()` или удаление validation вызывает осмысленное падение.

### Упражнение 4. Characterization и regression

**Исходные данные:** один реально существующий важный path из pricing, stock, Offer status или permissions, у которого ещё нет прямой защиты.

**Действие:** исследуйте фактическое behavior; сравните с принятым требованием; добавьте `S09` characterization test и `S10` regression/boundary test, затем выполните маленький структурный refactor.

**Результат:** journal объясняет, почему behavior принято, что изменилось внутри и почему public result не изменился.

**Проверки:** positive и boundary/negative case; targeted path; full suite; mutation proof; отсутствие необязательного переписывания production area.

### Вопросы защиты дня

1. По какой причине первый test стал красным?
2. Где записан oracle и почему он независим от реализации?
3. Что было минимальным green?
4. Какое behavior сохранил characterization test?
5. Как мутация доказала полезность теста?
6. Что было изменено только на refactor stage?

---

## День 2. PostgreSQL transactions и конкурентные запросы

### Паспорт дня

**Цель:** доказать, что денежные, складские и статусные инварианты сохраняются при rollback и двух одновременных операциях.

**Рабочие файлы или каталог:**

- integration/concurrency tests в `day_07_quality_gate/<project_root>/`;
- `day_02_concurrency_transactions.md`;
- `day_07_quality_gate/CONCURRENCY_MATRIX.md`;
- `TEST_MATRIX.md`, строки `S11–S24`.

**Результат:** transaction-enabled tests на реальной PostgreSQL, два синхронизированных workers с отдельными connections, bounded timeout и assertions итоговых инвариантов.

**Порядок выполнения:**

1. Нарисовать transaction boundary purchase/Offer transition по фактическому service.
2. Проверить database vendor и test database safety.
3. Сначала написать последовательные rollback scenarios.
4. Создать маленький test helper для workers и сбора результатов.
5. Синхронизировать старт через `Barrier`/`Event`, не через `sleep()`.
6. Проверить гонки последнего остатка и/или последних денег.
7. Проверить допустимый concurrent status transition.
8. Выполнить repeat run и заполнить матрицу.

**Наблюдаемый результат:** процессы/потоки всегда завершаются; при одной машине ровно одна покупка успешна, инварианты базы не нарушены и неожиданные exceptions не потеряны.

**Готово, если:**

- database подтверждена как PostgreSQL и isolated test DB;
- transaction tests действительно разрешают commit/rollback между workers;
- workers не делят одно соединение и освобождают resources;
- синхронизация не зависит от случайного `sleep()`;
- есть timeout и диагностика зависших workers;
- `S11–S24` и repeat results заполнены.

**Пример формата поведения, не решение:**

```text
workers: [SUCCESS, OUT_OF_STOCK]
final: stock=0, sales=1, charged_buyers=1
both workers finished before timeout
```

**Обязательно для зачёта:** rollback, реальная конкуренция, final invariants, timeout/cleanup, 14 scenarios.

**Рекомендация:** вынести только инфраструктурный worker helper; бизнес-assertions оставить видимыми в tests.

### Документация

- [pytest-django — transactional database tests](https://pytest-django.readthedocs.io/en/latest/database.html) — обязательно прочитать различие между обычным database test и `transaction=True`/`transactional_db`.
- [Python — barrier objects](https://docs.python.org/3/library/threading.html#barrier-objects) — изучить `wait()`, timeout и broken barrier для явной синхронизации workers.
- [Django — transactions](https://docs.djangoproject.com/en/5.2/topics/db/transactions/) — повторить `atomic`, commit и rollback перед проверкой service boundary.

### Упражнение 1. Карта transaction boundary

**Исходные данные:** фактический purchase/offer service, связанные models, constraints и Week 15 integration tests.

**Действие:** запишите порядок чтения/блокировки/изменения rows и возможные точки исключения. Отметьте, где начинается/заканчивается atomic transaction.

**Результат:** `CONCURRENCY_MATRIX.md` содержит resource, lock/read order, success state, failure state и invariant.

**Проверки:** stock, balance/payment, sale/offer row; exception до первого write, между writes и после planned write; отсутствие внешнего side effect до commit.

### Упражнение 2. Rollback scenarios `S11–S15`

**Исходные данные:** валидные buyer/car/dealership fixtures и controllable failure point фактического service.

**Действие:** создайте tests успешного commit и ошибок до/после ключевого write. Используйте реальную transaction, а не mocked ORM.

**Результат:** пять фактических tests доказывают all-or-nothing состояние.

**Проверки:** success; insufficient stock; insufficient balance; controlled exception after one planned mutation; database constraint/integrity error. Для каждого проверить все связанные rows и forbidden side effects.

### Упражнение 3. Два одновременных покупателя `S16–S20`

**Исходные данные:** одна доступная единица товара/автомобиля и два имеющих право покупателя с достаточными деньгами.

**Действие:** подготовьте данные до старта, затем одновременно вызовите тот же public service из двух workers. Соберите typed outcome/exception каждого.

**Результат:** test доказывает ровно один success и одно согласованное business rejection; final state целостно.

**Проверки:** оба готовы одновременно; separate connections; ровно одна sale; stock=0 и никогда не отрицателен; списание ровно один раз; bounded finish. Повторите минимум 10 раз локально и сохраните aggregate result, но не превращайте это в 10 разных scenario IDs.

### Упражнение 4. Деньги и state transition `S21–S24`

**Исходные данные:** buyer с балансом ровно на одну операцию и Offer в статусе, из которого допустим только один завершающий переход.

**Действие:** выполните два конкурирующих списания/перехода по фактическому API service contract.

**Результат:** финальные assertions доказывают non-negative balance, single terminal transition и отсутствие duplicate records/effects.

**Проверки:** exact balance; на единицу меньше нужного; два разных terminal commands; повтор того же command; unexpected database exception. Если domain не содержит одного сценария, зафиксировать `N/A` с доказательством и заменить равноценным конкурентным инвариантом после согласования.

### Вопросы защиты дня

1. Почему выбран transaction-enabled test?
2. Как доказано, что используется PostgreSQL?
3. Где workers получают отдельные connections?
4. Что завершает test при deadlock/hang?
5. Почему нельзя утверждать конкретного победителя?
6. Какие финальные rows образуют единый инвариант?
7. Чем controlled rejection отличается от unexpected exception?

---

## День 3. Детерминированные границы времени и side effects

### Паспорт дня

**Цель:** устранить зависимость tests от реальных часов, случайности и внешних эффектов, доказав commit/rollback behavior.

**Рабочие файлы или каталог:** tests/минимальные production seams в `day_07_quality_gate/<project_root>/`; `day_03_deterministic_boundaries.md`; `TEST_MATRIX.md`, `S25–S34`.

**Результат:** controllable clock/token/UUID на реально используемых границах, tests полуоткрытого периода акции и side effect, который происходит только после commit.

**Порядок выполнения:**

1. Inventory всех обращений ко времени/random/external providers в выбранном path.
2. Зафиксировать interval policy акции.
3. Добавить минимальный seam или patch in consumer namespace.
4. Проверить четыре временные границы без `sleep()`.
5. Проверить deterministic token/UUID без утверждения implementation detail.
6. Проверить provider call/no-call после commit/rollback.
7. Проверить provider failure и повтор вызова согласно contract.
8. Заполнить `S25–S34` и повторить tests в другой timezone.

**Наблюдаемый результат:** тесты одинаково проходят при двух timezone settings, не ждут реальное время и не выполняют внешних запросов.

**Готово, если:**

- business time передаётся/контролируется в одной ясной точке;
- начало/конец интервала проверены явно;
- no `sleep()` и real network/email;
- commit вызывает ровно ожидаемый эффект, rollback — ни одного;
- fake/mocks соответствуют реальному interface;
- `S25–S34` содержат actual results.

**Пример формата поведения, не решение:**

```text
now=end_at → promotion inactive
transaction rolled back → email adapter calls: 0
```

**Обязательно для зачёта:** time boundaries, two timezone runs, commit/rollback effect, failure path, 10 scenarios.

**Рекомендация:** предпочесть явный `clock`/provider adapter широкому patch стандартной библиотеки.

### Документация

- [Django — transaction management](https://docs.djangoproject.com/en/5.2/topics/db/transactions/) — обязательно прочитать разделы про `atomic()` и `on_commit()`.
- [Django — time zones](https://docs.djangoproject.com/en/5.2/topics/i18n/timezones/) — понять aware datetimes и влияние active/default timezone на границы времени.
- [Python — `unittest.mock`](https://docs.python.org/3/library/unittest.mock.html) — использовать `Mock`/`patch` на внешней границе и проверять вызовы collaborator.

### Упражнение 1. Inventory зависимостей

**Исходные данные:** pricing/promotion, verification/token и purchase/notification paths проекта.

**Действие:** найдите реальные вызовы current time, UUID/random/token generators, email/HTTP/file providers и `on_commit` callbacks. Для каждого укажите consumer module и риск.

**Результат:** таблица в `day_03_deterministic_boundaries.md`: dependency, location, why nondeterministic, chosen control, real integration pair.

**Проверки:** timezone-aware vs naive; implicit ordering; global state; provider call timing; secrets не попадают в report.

### Упражнение 2. Promotion boundaries `S25–S28`

**Исходные данные:** акция с фиксированными aware `start` и `end`, policy `[start, end)`.

**Действие:** вызовите public rule/service с controlled `now` для секунды до старта, точного старта, секунды до конца и точного конца.

**Результат:** четыре tests с явными expected active/inactive values и применённой/неприменённой скидкой.

**Проверки:** все четыре timestamps; один non-default timezone; отсутствие `datetime.now()` в assertions; money invariant из текущего domain.

### Упражнение 3. Token/UUID `S29–S30`

**Исходные данные:** существующая verification/id generation boundary; если её нет — другой реально случайный production identifier.

**Действие:** подставьте deterministic generator через существующую/минимальную dependency boundary; проверьте, что значение передано нужному collaborator и не раскрывается в public response/log.

**Результат:** два tests: deterministic success и collision/rejection path согласно текущему contract.

**Проверки:** patch where looked up; correct arguments; секрет не печатается; no brittle assertion на случайный default. При полном отсутствии границы — `N/A with evidence` и согласованная равноценная замена.

### Упражнение 4. Commit, rollback и provider failure `S31–S34`

**Исходные данные:** один реальный side effect после важной transaction, например verification email или domain notification adapter.

**Действие:** проверьте регистрацию/выполнение callback при commit, отсутствие при rollback, failure provider и повторный application call.

**Результат:** четыре tests показывают call count/arguments и итоговую database; реальные email/HTTP не уходят.

**Проверки:** successful commit exactly once; rollback zero calls; provider raises expected error/outcome; repeat follows documented idempotency policy; database state не частично.

### Вопросы защиты дня

1. Где именно управляется clock?
2. Как определён точный конец акции?
3. Почему patch target расположен в consumer module?
4. Как test доказывает отсутствие side effect после rollback?
5. Какие assertions относятся к contract, а какие были бы implementation details?
6. Почему запуск в другой timezone полезен?

---

## День 4. Решение об async-тестировании

### Паспорт дня

**Цель:** определить по коду, нужен ли async test stack, и проверить реальный execution boundary без искусственного async-кода.

**Рабочие файлы или каталог:** `day_04_async_testing.md`; `day_07_quality_gate/ASYNC_DECISION.md`; при ветке A — реальные tests в проекте; `TEST_MATRIX.md`, `S35–S40`.

**Результат:** воспроизводимый inventory и одна из двух принятых веток: шесть async scenarios для настоящего async path либо шесть строк `N/A with evidence` с проверкой ближайшей sync boundary.

**Порядок выполнения:**

1. Найти async syntax, ASGI/views, async clients и bridges.
2. Проследить один candidate от public entry point до side effect.
3. Выбрать ветку A или B и объяснить решение.
4. Для A проверить совместимость runner/plugin до установки.
5. Реализовать success/error/cancellation/resource scenarios либо sync boundary proof.
6. Проверить отсутствие leaked tasks/connections.
7. Заполнить `S35–S40` правильными статусами.

**Наблюдаемый результат:** `ASYNC_DECISION.md` позволяет другому разработчику повторить inventory; установка plugin обоснована или отсутствует; ни один fake async path не добавлен.

**Готово, если:**

- inventory содержит команды и реальные locations;
- решение основано на execution path, а не только на наличии ASGI settings;
- async test действительно awaits production callable, если он есть;
- исключения/resources/pending tasks проверены;
- при ветке B строки имеют `N/A with evidence`, а не ложный `PASS`;
- `S35–S40` полностью объяснены.

**Пример формата записи, не решение:**

```text
S35 | inventory: no async def under production packages | N/A with evidence
Nearest boundary checked: synchronous verification adapter contract | PASS outside S35
```

**Обязательно для зачёта:** полный inventory, обоснованная ветка, шесть статусов и защита решения.

**Рекомендация:** при ветке A сначала использовать уже поддерживаемый Django/unittest mechanism; не добавлять plugin без нужды.

### Документация

- [Django — testing asynchronous code](https://docs.djangoproject.com/en/5.2/topics/testing/tools/#testing-asynchronous-code) — изучить поддерживаемые async test methods и async client.
- [Python — `IsolatedAsyncioTestCase`](https://docs.python.org/3/library/unittest.html#unittest.IsolatedAsyncioTestCase) — понять lifecycle изолированного event loop и cleanup задач.

### Упражнение 1. Async inventory

**Исходные данные:** все production packages, routing/settings, HTTP/database adapters и current dependency files.

**Действие:** найдите `async def`, `await`, `async for`, `async with`, task creation и sync↔async bridges. Исключите virtualenv, migrations, generated files и tests из первого production count, затем просмотрите tests отдельно.

**Результат:** таблица location → caller → awaited dependency → side effect → branch decision.

**Проверки:** false positives в comments; ASGI config без async views; third-party package не считается собственным async path; фактическая dependency compatibility.

### Упражнение 2A. Если настоящий async path есть — `S35–S40`

**Исходные данные:** один public async callable и его real contract.

**Действие:** напишите tests для success, input boundary, dependency exception, timeout/cancellation, cleanup и sync/async bridge. Используйте async-aware test runner и doubles.

**Результат:** шесть фактических async tests с no leaked pending tasks и закрытыми resources.

**Проверки:** callable awaited; `AsyncMock`/fake interface корректен; expected exception observed; cancellation policy; cleanup in failure; повторный clean run. Не утверждать scheduler order, если contract его не задаёт.

### Упражнение 2B. Если async path отсутствует — `S35–S40`

**Исходные данные:** отрицательный inventory и ближайшая реальная sync external boundary.

**Действие:** запишите для каждого ID конкретную причину `N/A`; не создавайте шесть фиктивных tests. Добавьте один обычный contract test sync boundary, если его ещё нет, и запишите его node ID отдельно.

**Результат:** обоснованный отказ от лишней dependency и доказательство текущего sync contract.

**Проверки:** шесть разных аспектов оценены: async entry point, awaited I/O, task creation, cancellation, async resource cleanup, sync bridge; команды воспроизводимы; plugin не установлен; sync test проходит.

### Вопросы защиты дня

1. Что именно доказало наличие/отсутствие async path?
2. Почему ASGI setting недостаточно?
3. Чем `AsyncMock` отличается от обычного mock?
4. Как обнаруживаются leaked tasks?
5. Что происходит при отмене coroutine?
6. Почему `N/A with evidence` честнее искусственного PASS?

---

## День 5. Live-server E2E flows

### Паспорт дня

**Цель:** доказать два критических пользовательских потока через реальный локальный HTTP server, routing, middleware, auth и test PostgreSQL.

**Рабочие файлы или каталог:** E2E tests в `day_07_quality_gate/<project_root>/`; `day_05_e2e_flows.md`; `day_07_quality_gate/E2E_MATRIX.md`; `TEST_MATRIX.md`, `S41–S50`.

**Результат:** один успешный register→verify→JWT→Offer flow и один security/failure flow с поэтапными assertions и cleanup.

**Порядок выполнения:**

1. Выбрать live-server facility и local HTTP client уже доступный проекту.
2. Проверить test DB, host/port и запрет внешней сети.
3. Описать шаги flows и oracle каждого шага до кода.
4. Реализовать successful flow маленькими checkpoints.
5. Реализовать denied/rollback flow.
6. Проверить database и side effects после flows.
7. Запустить отдельно, вместе и после clean setup.
8. Заполнить `S41–S50`.

**Наблюдаемый результат:** HTTP requests идут на ephemeral local server; успешный пользователь работает только со своими данными, запрещённое действие не меняет database.

**Готово, если:**

- URL получен от live-server fixture, а не захардкожен;
- каждый request имеет timeout и проверку status/contract;
- auth/permissions не отключены для удобства test;
- verification token получен через safe test boundary;
- test не выходит во внешнюю сеть и не использует production data;
- `S41–S50` воспроизводимо проходят.

**Пример формата поведения, не решение:**

```text
POST <live_server>/api/offers/ → 201
GET own offer → 200 and expected id
DELETE/PATCH foreign offer → 403; database unchanged
```

**Обязательно для зачёта:** настоящий local HTTP, success+denied flows, PostgreSQL, step assertions, 10 scenarios.

**Рекомендация:** оставить E2E-набор небольшим; комбинации ролей продолжать проверять быстрыми API tests недели 15.

### Документация

- [Django — `LiveServerTestCase`](https://docs.djangoproject.com/en/5.2/topics/testing/tools/#liveservertestcase) — изучить запуск local test server и его работу с test database.
- [pytest-django — `live_server`](https://pytest-django.readthedocs.io/en/latest/helpers.html#live-server) — проверить pytest fixture, динамический URL и transaction behavior, если используется именно pytest-django.

### Упражнение 1. E2E design и safety

**Исходные данные:** реальные endpoints/OpenAPI, auth flow, test mail/token adapter и database config.

**Действие:** создайте `E2E_MATRIX.md`: шаг, request, expected status/schema, database/side effect, cleanup. Докажите, что base URL local и DB test-only.

**Результат:** до кода описаны десять observable checkpoints `S41–S50`.

**Проверки:** no hardcoded port; no real credentials; unique user data; request timeout; external hosts rejected; token не записывается в public logs/report.

### Упражнение 2. Успешный flow `S41–S46`

**Исходные данные:** новый email, dealership/car fixtures через public/setup boundary и безопасный verification capture.

**Действие:** через HTTP зарегистрируйте buyer, подтвердите email, получите JWT, просмотрите разрешённый catalog, создайте Offer и прочитайте/отмените собственный pending Offer согласно реальному contract.

**Результат:** шесть checkpoints с response и final database assertions.

**Проверки:** registration contract; unverified access denied before verify; verify transition; auth token works; created resource ownership; allowed final action changes exact rows. Если реальный endpoint отличается, сохранить тот же смысл риска и записать mapping.

### Упражнение 3. Security/failure flow `S47–S50`

**Исходные данные:** owner и второй buyer/другая организация, существующий protected resource.

**Действие:** вторым пользователем попытайтесь прочитать/изменить чужой resource, отправьте invalid transition/input и повторите один idempotent-safe request по текущему contract.

**Результат:** четыре checkpoints доказывают correct denial/validation и отсутствие forbidden database/side effects.

**Проверки:** unauthenticated; authenticated foreign owner; invalid status transition/payload; repeated request; response не раскрывает лишние данные; record count/state неизменны после denial.

### Вопросы защиты дня

1. Что доказывает live server сверх APIClient?
2. Где создаётся и удаляется test database?
3. Как исключён внешний HTTP?
4. Почему token capture безопасен только в test environment?
5. Какие assertions локализуют сломанный шаг?
6. Почему все permission combinations не перенесены в E2E?

---

## День 6. Диагностика flaky/order/time-dependent tests

### Паспорт дня

**Цель:** проверить воспроизводимость набора, найти и устранить источники зависимости от порядка, времени, случайности и окружения.

**Рабочие файлы или каталог:** tests/config проекта; `day_06_reliability_audit.md`; `day_07_quality_gate/FLAKY_AUDIT.md`; `TEST_MATRIX.md`, `S51–S60`.

**Результат:** repeat/order/timezone audit, устранённые причины нестабильности, query-count evidence и явная quarantine policy без retry masking.

**Порядок выполнения:**

1. Зафиксировать environment fingerprint и baseline duration.
2. Повторить critical tests отдельно и группами.
3. Запустить ключевые группы в двух явных порядках.
4. Запустить time-sensitive tests в двух timezone.
5. Проверить random/data ordering и shared state.
6. Измерить query growth на малом и увеличенном наборе.
7. Исправить найденные причины и повторить clean runs.
8. Описать quarantine policy и заполнить `S51–S60`.

**Наблюдаемый результат:** одинаковые результаты получаются при повторе, изменении порядка групп и timezone; query count не растёт на каждую строку; retry не включён.

**Готово, если:**

- сохранены команды и environment fingerprint без secrets;
- repeat не ограничен одним случайным прогоном;
- два порядка групп имеют одинаковый итог;
- time-sensitive subset прошёл в двух timezone;
- query-count проверка использует фиксированные datasets;
- каждое найденное падение классифицировано и не скрыто.

**Пример формата записи, не решение:**

```text
S52 | order: integration→unit / unit→integration | same pass set
S56 | 5 rows: 4 queries; 25 rows: 4 queries | budget satisfied
```

**Обязательно для зачёта:** repeat/order/timezone/query audits, failure taxonomy, no retries, 10 scenario IDs.

**Рекомендация:** сохранить failing seed/artifact в CI при первом падении, если текущая инфраструктура это поддерживает.

### Документация

- [pytest — Flaky tests](https://docs.pytest.org/en/stable/explanation/flaky.html) — обязательно прочитать причины thread-unsafe, state- и order-dependent тестов.
- [Django — `assertNumQueries()`](https://docs.djangoproject.com/en/5.2/topics/testing/tools/#django.test.TransactionTestCase.assertNumQueries) — изучить измерение числа запросов вокруг проверяемой операции.

### Упражнение 1. Environment fingerprint `S51`

**Исходные данные:** current interpreter, dependency lock, Django settings, PostgreSQL и CI/local commands.

**Действие:** запишите версии, database vendor, timezone, locale, marker expression, seed/random policy и число workers. Секретные значения замените названиями переменных.

**Результат:** другой разработчик понимает условия запуска без доступа к секретам.

**Проверки:** Python/Django/pytest/pytest-django/PostgreSQL; timezone/locale; settings module; parallelism; commit; no passwords/tokens/DSN credentials.

### Упражнение 2. Repeat и order `S52–S54`

**Исходные данные:** transaction/concurrency, time-boundary и два соседних unit/integration groups.

**Действие:** critical subset повторите минимум 20 раз; затем запустите группы `A→B` и `B→A` отдельными командами без order plugin. Если найдено падение, сохраните первый failure и исследуйте shared state.

**Результат:** aggregate counts, команды, duration range и classification каждого отклонения.

**Проверки:** isolated node; group; reverse group order; full suite after group; caches/global registries/connections cleanup. Повтор — диагностика, а не доказательство отсутствия всех гонок.

### Упражнение 3. Timezone/random/order `S55–S57`

**Исходные данные:** promotion tests, factories с потенциальной случайностью и list endpoints.

**Действие:** прогоните time subset в UTC и одном отличном timezone; задайте deterministic seed там, где random действительно нужен; добавьте explicit ordering только если API contract его требует.

**Результат:** одинаковые contract results и задокументированная ordering policy.

**Проверки:** exact start/end; aware datetimes; reproducible factory data; database list order; отсутствие assertions на случайный UUID/время.

### Упражнение 4. Query budget и bounded completion `S58–S59`

**Исходные данные:** один list/statistics endpoint из Week 15 и concurrency test Day 2.

**Действие:** сравните query count на малом и увеличенном fixed dataset; проверьте, что concurrency test завершается в generous timeout. Не ставьте микросекундный SLA.

**Результат:** query counts, dataset sizes, allowed budget и bounded completion evidence.

**Проверки:** response equivalence; no per-row query growth; count captured around relevant call; timeout не является единственным correctness assertion; no `sleep()`.

### Упражнение 5. Quarantine policy и clean gate `S60`

**Исходные данные:** найденные нестабильности или, если их нет, один гипотетический critical flaky example.

**Действие:** классифицируйте `test defect / product race / environment`; исправьте реальные найденные причины. Опишите временную quarantine только с issue, owner, expiry и сохранением видимости.

**Результат:** clean mandatory subset проходит без automatic retry; unresolved critical failure блокирует gate.

**Проверки:** no silent skip; strict xfail только известному defect; quarantine не применяется к data/security invariant без явного решения; final result сообщает skip/xfail counts.

### Вопросы защиты дня

1. Что именно повторный запуск способен и не способен доказать?
2. Как был проверен order dependence без нового plugin?
3. Почему retry не исправляет flaky test?
4. Как различить test pollution и product race?
5. Почему query count полезнее жёсткого времени?
6. Какие данные нужны для воспроизведения CI failure?

---

## День 7. Итоговый проект `Dealership Quality Gate`

### Паспорт итогового проекта

**Цель:** собрать воспроизводимую многоуровневую систему, которая блокирует нарушение критических инвариантов Dealership API и объясняет каждый осознанный пробел.

**Рабочие файлы или каталог:** `week_16_advanced_testing/day_07_quality_gate/`.

**Результат:** принятый Django project с test suite, едиными local/CI commands, 60 строками test matrix, TDD/concurrency/async/E2E/flaky evidence и regression map.

**Порядок выполнения:**

Работайте по вертикальным срезам:

1. Перенос baseline и быстрый unit/TDD gate.
2. PostgreSQL integration/transaction/concurrency gate.
3. Deterministic time и side-effect gate.
4. Async branch decision и применимые checks.
5. Live-server E2E flows.
6. Reliability/query/coverage audit.
7. Clean run с нуля, документация и защита.

**Наблюдаемый результат:** один документированный quality-gate workflow воспроизводимо проходит с clean test database; отчёт явно показывает passed/failed/skipped/xfail/N/A/deferred, а не только общую зелёную строку.

**Готово, если:**

- все артефакты существуют и ссылаются на реальные paths/node IDs;
- `S01–S60` заполнены фактическими статусами;
- mandatory gate не содержит скрытых retry/skip;
- PostgreSQL/concurrency/E2E выполняются отдельно и вместе;
- clean run повторён минимум два раза с одинаковым набором результатов;
- 48 вопросов защиты отвечены письменно до устной проверки.

**Пример формата quality gate, не готовая команда:**

```text
Stage 1 unit: PASS (… tests)
Stage 2 PostgreSQL integration: PASS (… tests)
Stage 3 concurrency: PASS (… tests, timeout bounded)
Stage 4 E2E: PASS (… flows)
Skipped: 0 mandatory; Async: N/A with evidence
```

**Обязательно для зачёта:** рабочий код/tests, все документы, 60 scenarios, clean gate, защита минимум 36/48 и итог минимум 8/10.

**Рекомендация:** разбить CI на быстрый обязательный job и отдельный PostgreSQL/E2E job, сохранив одинаковые базовые команды.

### Документация

- [coverage.py — branch coverage](https://coverage.readthedocs.io/en/latest/branch.html) — использовать branch report для поиска непроверенных решений, а не как самоцель.
- [pytest — markers](https://docs.pytest.org/en/stable/how-to/mark.html) — проверить selection stages, регистрацию marker names и отчётность quality gate.

### Дерево файлов и обязанности

```text
day_07_quality_gate/
├── <project_root>/           # фактический Django backend и tests
├── README.md                 # запуск с нуля, prerequisites и итоговые команды
├── QUALITY_GATE.md           # этапы gate, pass/fail policy и local/CI mapping
├── TDD_LOG.md                # red-green-refactor и characterization evidence
├── CONCURRENCY_MATRIX.md     # locks, workers, outcomes и invariants
├── ASYNC_DECISION.md         # inventory и обоснованная ветка A/B
├── E2E_MATRIX.md             # HTTP steps, oracles, DB/effects и cleanup
├── FLAKY_AUDIT.md            # repeat/order/timezone/query audit
├── REGRESSION_MAP.md         # critical risks и защищающие tests
└── TEST_MATRIX.md            # S01–S60 с actual results
```

Если проект уже хранит техническую документацию в другом принятом месте, разрешена ссылка вместо дубликата, но перечисленные файлы-индексы остаются и указывают точный source of truth.

### Обязанности документов

- `README.md`: clean setup, safe environment, database check, команды всех stages и troubleshooting.
- `QUALITY_GATE.md`: порядок stages, marker/node selection, timeout policy, что блокирует merge.
- `TDD_LOG.md`: требование, red reason, green change, refactor и mutation proof.
- `CONCURRENCY_MATRIX.md`: initial state, workers, synchronization, allowed outcomes, final invariants, cleanup.
- `ASYNC_DECISION.md`: inventory commands/locations, compatibility and branch decision.
- `E2E_MATRIX.md`: каждый HTTP checkpoint и его database/security oracle.
- `FLAKY_AUDIT.md`: environment, repeated/order/timezone runs, failures, fixes, quarantine rule.
- `REGRESSION_MAP.md`: risk → tests → level → gate; будущий Celery idempotency contract помечен `DEFERRED week 18–19`.
- `TEST_MATRIX.md`: 60 scenarios без двойного подсчёта одного и того же запуска.

### Обязательные сценарии итоговой сдачи

**Положительные:**

- корректный stock-days contract;
- успешная атомарная покупка;
- commit запускает нужный side effect один раз;
- подтверждённый пользователь проходит E2E и управляет своим Offer;
- разрешённый async success path, если применимо;
- list/statistics response укладывается в query budget.

**Граничные:**

- zero quantity/demand policy;
- точное начало и точный конец акции;
- balance/stock ровно на одну операцию;
- два одновременных покупателя последней единицы;
- terminal Offer transition;
- малый и увеличенный dataset для query count.

**Ошибочные и security:**

- отрицательные входы чистого правила;
- insufficient balance/stock без частичных изменений;
- rollback без email/provider call;
- provider exception без скрытого partial success;
- unauthenticated/foreign-owner E2E denial;
- invalid status/payload;
- async exception/cancellation, если применимо;
- worker timeout/deadlock превращается в понятное test failure, а не зависание.

### Ограничения на ещё не изученные инструменты

- не добавлять Redis, Celery, broker или distributed locks;
- не реализовывать Celery retry/idempotency test раньше недель 18–19;
- не добавлять браузерную автоматизацию при отсутствии пользовательского frontend;
- не добавлять property-based/load-testing plugin только ради недели;
- не включать parallel pytest workers, пока tests не доказаны последовательным gate;
- не подключать реальные внешние providers;
- не менять production architecture шире минимального test seam без отдельного согласования.

### Финальный чек-лист сдачи

- [ ] Source week/commit и baseline записаны.
- [ ] Clean test database точно не production/development.
- [ ] Все старые tests продолжают собираться и проходить либо изменение обосновано.
- [ ] TDD red, green, refactor и mutation доказаны.
- [ ] Characterization test защищает реальный behavior.
- [ ] PostgreSQL rollback и concurrency scenarios проходят с timeout.
- [ ] Workers используют отдельные connections и cleanup.
- [ ] Time boundaries не зависят от часов машины.
- [ ] Side effect связан с commit/rollback contract.
- [ ] Async decision подтверждён inventory.
- [ ] E2E использует local live server и safe token capture.
- [ ] Repeat/order/timezone audits выполнены.
- [ ] Query budget проверен на двух dataset sizes.
- [ ] Retry не скрывает flaky failures.
- [ ] Skip/xfail/N/A/deferred перечислены явно.
- [ ] `S01–S60` имеют evidence и статус.
- [ ] Regression map покрывает роли, verification, money, stock, promotions, concurrent last unit, supplier/statistics/N+1.
- [ ] Celery repeat contract помечен будущим, а не ложно реализованным.
- [ ] Local и CI quality gate эквивалентны по обязательным проверкам.
- [ ] Два clean runs дали одинаковый набор результатов.
- [ ] В отчётах нет секретов и персональных данных.
- [ ] Самооценка и ответы на 48 вопросов заполнены.

### Контроль понимания: 48 вопросов

#### TDD и oracle

1. Назовите три состояния TDD и цель каждого.
2. Как отличить полезный red от broken setup?
3. Почему green implementation может быть простой?
4. Что нельзя менять во время refactor?
5. Для чего нужен characterization test?
6. Когда фактическое legacy behavior нельзя закреплять как правильное?
7. Что делает oracle независимым?
8. Как mutation proof выявляет пустой test?

#### Transactions и concurrency

9. Когда обычного database test недостаточно?
10. Почему locking test выполняется на PostgreSQL?
11. Что такое race condition в покупке последней машины?
12. Какие final invariants важнее конкретного winner?
13. Зачем worker отдельное connection?
14. Почему `sleep()` не синхронизирует надёжно?
15. Как barrier помогает поставить операции рядом?
16. Что предотвращает бесконечное зависание test?
17. Чем business rejection отличается от infrastructure exception?
18. Как единый lock order снижает deadlock risk?

#### Determinism и side effects

19. Что делает test deterministic?
20. Как различаются business clock и duration clock?
21. Что означает интервал `[start, end)`?
22. Почему timezone-aware datetime важен?
23. Где patch-ить импортированное имя?
24. Как доказать отсутствие email после rollback?
25. Что должен проверить provider failure scenario?
26. Почему exact random UUID обычно плохой oracle без injected generator?

#### Async

27. Что возвращает вызов `async def`?
28. Что делает `await`?
29. Когда async tests действительно нужны?
30. Почему ASGI settings не являются достаточным основанием?
31. Чем async mock отличается от sync mock?
32. Как проверить cancellation contract?
33. Что такое leaked pending task?
34. Почему `N/A with evidence` является полноценным инженерным решением?

#### E2E

35. Что live-server test проверяет сверх in-process API test?
36. Почему E2E tests мало?
37. Какие границы остаются fake даже в локальном E2E?
38. Как безопасно получить verification token?
39. Что проверить после запрещённого request?
40. Почему hardcoded localhost port опасен?

#### Reliability и gate

41. Что такое flaky test?
42. Почему retry не устраняет причину?
43. Как обнаружить order dependence?
44. Какие environment data сохранить при failure?
45. Чем query budget лучше малого time threshold?
46. Когда quarantine допустима и что обязана содержать?
47. Как branch coverage помогает найти риск, не становясь целью?
48. Почему Celery retry contract сейчас `DEFERRED`, а не `PASS`?

### Критерий защиты

- минимум 36/48 правильных ответов;
- обязательны верные ответы на вопросы 2, 8, 10, 12, 14, 16, 24, 29, 34, 39, 42 и 48;
- ученик демонстрирует запуск одного unit, одного transaction/concurrency и одного E2E test по node ID;
- ученик объясняет один failure без чтения готового ответа из журнала.

---

## Шкала оценки обычного дня

| Критерий | Баллы |
|---|---:|
| Корректность результата | 0–3 |
| Выполнение условий задания | 0–2 |
| Граничные и ошибочные сценарии | 0–2 |
| Читаемость и имена | 0–1 |
| Понимание и самооценка | 0–1 |
| Самостоятельность исправлений | 0–1 |

## Шкала итогового проекта

| Критерий | Баллы |
|---|---:|
| Корректность unit/TDD/characterization слоя | 0–2 |
| Transactions/concurrency и database invariants | 0–2 |
| Deterministic boundaries и side effects | 0–1 |
| Async decision и E2E flows | 0–1 |
| Reliability, regression map и quality gate | 0–2 |
| Документация, объяснение и самостоятельность | 0–2 |

Итоговый проект принят при результате не ниже 8/10, отсутствии критической ошибки и выполнении всех обязательных критериев.

Критическими являются: обращение к production/development DB, реальная отправка внешнего эффекта, зависающий worker, нарушение денежного/складского инварианта, ложный PASS вместо N/A/deferred, скрытый retry/skip обязательного test, неработающий clean gate или невозможность объяснить основной test.
