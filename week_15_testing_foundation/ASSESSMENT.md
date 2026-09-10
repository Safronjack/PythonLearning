# Журнал оценки: неделя 15

Статус недели: **заблокирована до полного зачёта недели 14**.

Текущий активный прогресс: `week_00_basics/ASSESSMENT.md`, следующий шаг — день 2 недели 0.

## Условие активации

- [ ] Недели 0–13 завершены полностью.
- [ ] Неделя 14 завершена полностью.
- [ ] Все дни недели 14 имеют минимум 7/10.
- [ ] Итоговый Authorized Dealership API недели 14 имеет минимум 8/10.
- [ ] Permission matrix, scopes, service policies и OpenAPI недели 14 приняты.
- [ ] Контроль понимания недели 14 пройден минимум на 36/48.
- [ ] В журнале недели 14 указано: «Допуск к неделе 15: да».

**Дата активации:** —

## Сводная таблица

| Этап | Основной артефакт | Первая оценка | Итоговая оценка | Статус | Дата |
|---|---|---:|---:|---|---|
| День 1 | strategy/inventory/pytest config + `day_01_test_strategy.md` | —/10 | —/10 | Заблокировано | — |
| День 2 | pytest unit/assertions + `day_02_pytest_basics.md` | —/10 | —/10 | Заблокировано | — |
| День 3 | fixtures/database isolation + `day_03_fixtures_database.md` | —/10 | —/10 | Заблокировано | — |
| День 4 | parametrize/factories/markers + `day_04_parametrize_factories.md` | —/10 | —/10 | Заблокировано | — |
| День 5 | unit rules/mock boundaries + `day_05_unit_mocking.md` | —/10 | —/10 | Заблокировано | — |
| День 6 | integration/API/coverage + `day_06_api_coverage.md` | —/10 | —/10 | Заблокировано | — |
| День 7 | `day_07_test_suite/` | —/10 | —/10 | Заблокировано | — |
| Контроль понимания | 48 вопросов | —/48 | —/48 | Заблокировано | — |

## Правила проверки

Первая оценка и исходные ошибки сохраняются после исправлений. Наставник фиксирует risk/behavior, test level, node ID/marker, Arrange–Act–Assert, oracle, real/fake dependencies, red mutation, actual result/duration, database/side effects, coverage gap и следующий шаг.

Большое число tests или высокий coverage не компенсируют отсутствие meaningful assertions, shared production database, скрытые side effects, неверный mock target или green test, который не становится red при нарушении правила.

## Детальные проверки

### День 1. Test strategy и pytest setup

**Первая проверка:** не проводилась.

**Что получилось:** —

**Ошибки и причины:** —

**Что повторить:** —

**Что усилить:** —

**Обязательные исправления:** —

**Проверенные сценарии:** —/10.

**Source/database/old baseline:** —

**Compatibility/config/collection:** —

**Inventory/risk-level map:** —

**Повторная проверка:** —

**Следующий шаг:** дождаться полного завершения недели 14.

### День 2. Pytest basics

**Первая проверка:** не проводилась.

**Что получилось:** —

**Ошибки и причины:** —

**Что повторить:** —

**Что усилить:** —

**Обязательные исправления:** —

**Проверенные сценарии:** —/12.

**AAA/names/assertions/oracles:** —

**Exceptions/failure diagnostics:** —

**Legacy migration/mutation proof:** —

**Повторная проверка:** —

**Следующий шаг:** после зачёта дня 1 выполнить день 2.

### День 3. Fixtures и database isolation

**Первая проверка:** не проводилась.

**Что получилось:** —

**Ошибки и причины:** —

**Что повторить:** —

**Что усилить:** —

**Обязательные исправления:** —

**Проверенные сценарии:** —/12.

**Fixture map/scopes/factories:** —

**DB access/target/isolation:** —

**Cleanup/order independence:** —

**Повторная проверка:** —

**Следующий шаг:** после зачёта дня 2 выполнить день 3.

### День 4. Parametrize, factories и markers

**Первая проверка:** не проводилась.

**Что получилось:** —

**Ошибки и причины:** —

**Что повторить:** —

**Что усилить:** —

**Обязательные исправления:** —

**Проверенные сценарии:** —/12.

**Deterministic factories/case IDs:** —

**Marker selection/strictness:** —

**Skip/xfail/mutation evidence:** —

**Повторная проверка:** —

**Следующий шаг:** после зачёта дня 3 выполнить день 4.

### День 5. Unit rules и mocks

**Первая проверка:** не проводилась.

**Что получилось:** —

**Ошибки и причины:** —

**Что повторить:** —

**Что усилить:** —

**Обязательные исправления:** —

**Проверенные сценарии:** —/12.

**Pure-rule coverage/oracles:** —

**Mock audit/patch target/spec:** —

**Call/no-call/integration pair:** —

**Повторная проверка:** —

**Следующий шаг:** после зачёта дня 4 выполнить день 5.

### День 6. Integration/API и coverage

**Первая проверка:** не проводилась.

**Что получилось:** —

**Ошибки и причины:** —

**Что повторить:** —

**Что усилить:** —

**Обязательные исправления:** —

**Проверенные сценарии:** —/14.

**PostgreSQL constraints/rollback:** —

**DRF/real auth/negative side effects/query budget:** —

**Smoke/regression/branch coverage audit:** —

**Повторная проверка:** —

**Следующий шаг:** после зачёта дня 5 выполнить день 6.

### День 7. Итоговый Dealership Test Foundation

**Первая проверка:** не проводилась.

**Что получилось:** —

**Ошибки и причины:** —

**Что повторить:** —

**Что усилить:** —

**Обязательные исправления:** —

**Проверенные сценарии:** —/54.

**Unit:** —/14. **Integration:** —/14. **API:** —/16. **Tooling/regression:** —/10.

**Dependencies/config/collection/markers:** —

**Fixtures/factories/mocks/isolation:** —

**PostgreSQL/API/query/coverage:** —

**Clean install/migrations/checks/tests/schema:** —

**Незакрытые risk/coverage gaps:** —

**Повторная проверка:** —

**Следующий шаг:** после зачёта дня 6 сдать итоговый suite и защиту.

### Контроль понимания

**Первая попытка:** —/48.

**Обязательные вопросы 3, 4, 5, 7, 8, 10, 12, 13, 14, 15, 18, 19, 21, 22, 24, 25, 26, 27, 29, 31, 32, 33, 35, 38, 39, 40, 41, 43, 45, 46, 47, 48:** —

**Темы, требующие повторения:** —

**Повторная попытка:** —/48.

## Критические ошибки недели

- test использует development/production/shared database;
- test проходит без meaningful assertion;
- expected копирует production algorithm;
- negative test не замечает database/ledger/mail side effect;
- test зависит от порядка или shared mutable fixture;
- broad fixture/autouse скрывает privilege или обязательный setup;
- unit test случайно зависит от database;
- integration test mock-ает PostgreSQL/ORM behavior, которое должен доказать;
- API security test не проходит real auth/permission path нигде в suite;
- mock patch target неверен, а test всё равно объявлен доказательством;
- mock без interface control разрешает несуществующий call;
- skip/xfail скрывает обязательное failing behavior;
- unknown markers/zero collection дают ложный green run;
- old tests пропали из collection без объяснения;
- SQLite выдан за доказательство PostgreSQL constraint/transaction;
- coverage считается доказательством assertions/quality;
- critical branch uncovered и не имеет решения/обоснования;
- reports/logs содержат password/token/DSN/private data;
- suite нельзя воспроизвести clean documented command.

## Итог недели

**Итоговая оценка:** —/10.

**Статус:** Заблокировано.

**Сильные стороны:** —

**Основные пробелы:** —

**Что повторить:** —

**Дополнительная практика:** —

**Контроль понимания:** —/48, требуется минимум 36/48 и обязательные вопросы.

**Допуск к неделе 16:** нет.

**Следующий шаг:** продолжить день 2 недели 0; к неделе 15 вернуться только после принятой недели 14.

## История изменений оценки

- 2026-09-10: создан журнал будущей недели; работа ученика не проверялась, оценки и активный прогресс не изменены.
