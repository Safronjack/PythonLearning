# Неделя 16: продвинутая стратегия тестирования

Статус: **подготовлена заранее и заблокирована до полного зачёта недели 15**.

Неделя завершает этап тестирования. Мы перестаём проверять только отдельные примеры и учимся доказывать поведение системы в сложных условиях: при одновременных запросах, на границах времени, с внешними эффектами, через настоящий HTTP-сервер и при нестабильных тестах. Финальный результат — воспроизводимый quality gate для Dealership API.

## Результат недели

После завершения ученик умеет:

- проходить цикл TDD `red → green → refactor` и сохранять доказательства каждого шага;
- отличать полезный красный тест от ошибки импорта, настройки или самого теста;
- закреплять существующее поведение characterization-тестом перед рискованным рефакторингом;
- проверять транзакции и блокировки на реальной изолированной PostgreSQL;
- моделировать конкуренцию через отдельные соединения и явную синхронизацию без `sleep()`;
- утверждать конечные инварианты, не привязываясь к случайному победителю гонки;
- делать время, UUID, токены и внешние эффекты управляемыми в тестах;
- проверять действие после commit и отсутствие действия после rollback;
- принимать обоснованное решение, нужны ли проекту async-тесты;
- тестировать реальный async-код, исключения, отмену и завершение задач, если он существует;
- выполнять несколько ценных E2E-потоков через локальный live server;
- диагностировать flaky-, order- и time-dependent тесты вместо маскировки retry;
- применять query budgets и разумные performance-ограничения без хрупких секундных порогов;
- собирать unit, integration, API, E2E, smoke и regression проверки в понятный quality gate;
- объяснять, какой риск доказывает каждый критический тест и чего он не доказывает.

## Предварительные требования

- Недели 0–15 завершены полностью.
- Каждый день недели 15 оценён минимум на 7/10.
- Итоговый `Dealership Test Foundation` принят минимум на 8/10.
- Фактически пройдены 54 сценария недели 15.
- Контроль понимания недели 15 пройден минимум на 36/48.
- В `week_15_testing_foundation/ASSESSMENT.md` записано: «Допуск к неделе 16: да».

Текущий реальный прогресс курса не меняется: активным остаётся этап, указанный в `week_00_basics/ASSESSMENT.md`.

## Продолжение проекта недели 15

После допуска копируется только принятая версия:

```text
week_15_testing_foundation/day_07_test_suite/
```

в рабочий каталог:

```text
week_16_advanced_testing/day_07_quality_gate/
```

Неделя 15 после переноса не изменяется. В `day_01_tdd_contract.md` фиксируются исходный commit/ветка, команды baseline, версия PostgreSQL и количество прошедших, пропущенных и ожидаемо падающих тестов.

## Зависимости и activation gate

Обязательные новые зависимости отсутствуют: продолжаем использовать `pytest`, `pytest-django` и `coverage`, принятые на неделе 15.

`pytest-asyncio` разрешён только если inventory обнаружил настоящий async production path и после проверки совместимости с текущими Python/pytest/Django. Если async-кода нет, зависимость не устанавливается, искусственный async-код не создаётся, а решение `не применимо` фиксируется в `ASYNC_DECISION.md`.

Перед началом проверить:

1. clean install test/development dependencies;
2. полную collection старых тестов без ошибок;
3. отдельную test PostgreSQL, не development/production database;
4. baseline всего набора и всех marker-групп;
5. отсутствие реальных email, HTTP и других внешних side effects;
6. что CI способен запускать PostgreSQL и live-server tests;
7. актуальную документацию применяемых версий.

## Структура недели

| День | Тема | Основной результат |
|---|---|---|
| 1 | TDD и characterization | доказанный red-green-refactor нового правила |
| 2 | Транзакции и конкуренция | PostgreSQL tests последних денег/остатка и переходов состояния |
| 3 | Время и side effects | deterministic clock/token/UUID и commit/rollback эффекты |
| 4 | Async testing decision | обоснованная async-ветка или доказанное `не применимо` |
| 5 | Live-server E2E | важные пользовательские потоки через настоящий локальный HTTP |
| 6 | Flaky/order/performance | отчёт о воспроизводимости и устранённых источниках нестабильности |
| 7 | Dealership Quality Gate | итоговая система из 60 проверенных сценариев |

## Обязательные артефакты

```text
week_16_advanced_testing/
├── README.md
├── THEORY.md
├── PRACTICE.md
├── ASSESSMENT.md
├── notes.md
├── day_01_tdd_contract.md
├── day_02_concurrency_transactions.md
├── day_03_deterministic_boundaries.md
├── day_04_async_testing.md
├── day_05_e2e_flows.md
├── day_06_reliability_audit.md
└── day_07_quality_gate/
    ├── README.md
    ├── QUALITY_GATE.md
    ├── TDD_LOG.md
    ├── CONCURRENCY_MATRIX.md
    ├── ASYNC_DECISION.md
    ├── E2E_MATRIX.md
    ├── FLAKY_AUDIT.md
    ├── REGRESSION_MAP.md
    └── TEST_MATRIX.md
```

Production-код и тесты продолжают структуру фактического Django-проекта. Пути нельзя придумывать заранее: в отчётах нужно указать реальные paths и node IDs.

## Матрица 60 сценариев

| Диапазон | Область | Количество |
|---|---|---:|
| 01–10 | TDD и characterization | 10 |
| 11–24 | транзакции и конкуренция | 14 |
| 25–34 | время и side effects | 10 |
| 35–40 | async decision / async behavior | 6 |
| 41–50 | live-server E2E | 10 |
| 51–60 | воспроизводимость и quality gate | 10 |

Каждая строка `TEST_MATRIX.md` содержит: ID, риск, уровень, предусловие, действие, oracle, итоговое состояние/side effects, node ID или команду, фактический результат и статус.

## Ограничение текущего этапа

- Redis начинается на неделе 17.
- Celery изучается на неделях 18–19.
- Сценарий повторного запуска Celery-задачи пока фиксируется в `REGRESSION_MAP.md` как будущий контракт, но не реализуется поддельной task или новой зависимостью.
- Нельзя заменять PostgreSQL на SQLite в проверках блокировок и транзакций.
- Нельзя обращаться к production/development database.
- Нельзя отправлять реальные письма или HTTP-запросы наружу.
- Нельзя использовать длительный `sleep()` как способ синхронизации.
- Нельзя делать retry способом «исправить» flaky test.
- Нельзя повышать coverage бессодержательными assertions.
- Нельзя создавать async production code только ради async-теста.

## Критерий завершения

Неделя принята, если:

- каждый день имеет итоговую оценку не ниже 7/10;
- итоговый проект оценён минимум на 8/10;
- 60 сценариев имеют фактический воспроизводимый результат;
- TDD log доказывает корректные red, green и refactor;
- конкурентные проверки выполняются на PostgreSQL, завершаются за ограниченное время и доказывают инварианты;
- тесты времени и side effects не зависят от часов машины и внешней сети;
- async decision подтверждён inventory проекта;
- E2E проходит через настоящий local HTTP path;
- flaky/order audit не скрывает падения retry-механизмом;
- критические риски имеют положительные и отрицательные regression-тесты либо явно обоснованный будущий контракт;
- clean quality gate проходит с нуля;
- ученик набрал минимум 36/48 за контроль понимания;
- в `ASSESSMENT.md` записано: «Допуск к неделе 17: да».

## Официальная документация

- [pytest: Flaky tests](https://docs.pytest.org/en/stable/explanation/flaky.html) — причины нестабильных тестов и способы их диагностики.
- [pytest-django: Database access](https://pytest-django.readthedocs.io/en/latest/database.html) — database markers, transaction tests и live server.
- [Django: Testing tools](https://docs.djangoproject.com/en/5.2/topics/testing/tools/) — client, async test client и live server facilities.
- [Django: Transactions](https://docs.djangoproject.com/en/5.2/topics/db/transactions/) — atomic blocks, rollback и `on_commit()`.
- [Python: `threading.Barrier`](https://docs.python.org/3/library/threading.html#barrier-objects) — явная синхронизация конкурентных workers.
- [Python: `IsolatedAsyncioTestCase`](https://docs.python.org/3/library/unittest.html#unittest.IsolatedAsyncioTestCase) — изолированный event loop для async tests.
- [coverage.py: Branch coverage](https://coverage.readthedocs.io/en/latest/branch.html) — анализ непроверенных ветвей вместо охоты за одной цифрой.
