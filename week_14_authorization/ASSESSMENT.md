# Журнал оценки: неделя 14

Статус недели: **заблокирована до полного зачёта недели 13**.

Текущий активный прогресс: `week_00_basics/ASSESSMENT.md`, следующий шаг — день 2 недели 0.

## Условие активации

- [ ] Недели 0–12 завершены полностью.
- [ ] Неделя 13 завершена полностью.
- [ ] Все дни недели 13 имеют минимум 7/10.
- [ ] Итоговый identity API недели 13 имеет минимум 8/10.
- [ ] JWT, action-token, email и password security contracts недели 13 приняты.
- [ ] Контроль понимания недели 13 пройден минимум на 32/42.
- [ ] В журнале недели 13 указано: «Допуск к неделе 14: да».

**Дата активации:** —

## Сводная таблица

| Этап | Основной артефакт | Первая оценка | Итоговая оценка | Статус | Дата |
|---|---|---:|---:|---|---|
| День 1 | authz contract/ADR/matrix/threat model + `day_01_authorization_contract.md` | —/10 | —/10 | Заблокировано | — |
| День 2 | RBAC/action gates + `day_02_rbac_permissions.md` | —/10 | —/10 | Заблокировано | — |
| День 3 | ownership/scoped querysets + `day_03_object_scope.md` | —/10 | —/10 | Заблокировано | — |
| День 4 | ABAC/PBAC/service enforcement + `day_04_policy_services.md` | —/10 | —/10 | Заблокировано | — |
| День 5 | domain matrix + `day_05_domain_permissions.md` | —/10 | —/10 | Заблокировано | — |
| День 6 | adversarial/OpenAPI audit + `day_06_authorization_audit.md` | —/10 | —/10 | Заблокировано | — |
| День 7 | `day_07_authorized_api/` | —/10 | —/10 | Заблокировано | — |
| Контроль понимания | 48 вопросов | —/48 | —/48 | Заблокировано | — |

## Правила проверки

Первая оценка и исходные ошибки сохраняются после исправлений. Наставник фиксирует actor/role/profile/membership, action/resource/state, expected и actual status, visible rows/fields, database before/after, side effects, query evidence, schema result и следующий конкретный шаг.

Успешный admin/superuser path не компенсирует утечку чужих объектов, mass assignment, отсутствующий list scope, service bypass или stale-role доступ. Negative test считается доказательством только при проверке состояния и побочных эффектов, а не одного status.

## Детальные проверки

### День 1. Контракт авторизации

**Первая проверка:** не проводилась.

**Что получилось:** —

**Ошибки и причины:** —

**Что повторить:** —

**Что усилить:** —

**Обязательные исправления:** —

**Проверенные сценарии:** —/10.

**Source/database/baseline:** —

**Actor/route inventory:** —

**Role-source ADR/matrix/threat model:** —

**Повторная проверка:** —

**Следующий шаг:** дождаться полного завершения недели 13.

### День 2. RBAC и action gates

**Первая проверка:** не проводилась.

**Что получилось:** —

**Ошибки и причины:** —

**Что повторить:** —

**Что усилить:** —

**Обязательные исправления:** —

**Проверенные сценарии:** —/12.

**Role/capability/provisioning:** —

**DRF action gates/mass assignment:** —

**Permission cache/revocation/admin semantics:** —

**Повторная проверка:** —

**Следующий шаг:** после зачёта дня 1 выполнить день 2.

### День 3. Object scope

**Первая проверка:** не проводилась.

**Что получилось:** —

**Ошибки и причины:** —

**Что повторить:** —

**Что усилить:** —

**Обязательные исправления:** —

**Проверенные сценарии:** —/12.

**List/detail/create scope:** —

**Ownership/organization/field confidentiality:** —

**Query budget:** —

**Повторная проверка:** —

**Следующий шаг:** после зачёта дня 2 выполнить день 3.

### День 4. ABAC/PBAC и services

**Первая проверка:** не проводилась.

**Что получилось:** —

**Ошибки и причины:** —

**Что повторить:** —

**Что усилить:** —

**Обязательные исправления:** —

**Проверенные сценарии:** —/12.

**Policy contracts/pure tests:** —

**Offer/organization service enforcement:** —

**Transaction/TOCTOU/concurrency:** —

**Повторная проверка:** —

**Следующий шаг:** после зачёта дня 3 выполнить день 4.

### День 5. Доменные permissions

**Первая проверка:** не проводилась.

**Что получилось:** —

**Ошибки и причины:** —

**Что повторить:** —

**Что усилить:** —

**Обязательные исправления:** —

**Проверенные сценарии:** —/14.

**Offer/purchase/dealership/supplier matrix:** —

**Balance/history/statistics boundary:** —

**Public catalog/admin route coverage:** —

**Повторная проверка:** —

**Следующий шаг:** после зачёта дня 4 выполнить день 5.

### День 6. Authorization security audit

**Первая проверка:** не проводилась.

**Что получилось:** —

**Ошибки и причины:** —

**Что повторить:** —

**Что усилить:** —

**Обязательные исправления:** —

**Проверенные сценарии:** —/16.

**Horizontal/vertical/BOLA/mass assignment:** —

**Stale JWT/401-403-404/side effects/logs:** —

**OpenAPI/guard mutation/regressions:** —

**Повторная проверка:** —

**Следующий шаг:** после зачёта дня 5 выполнить день 6.

### День 7. Итоговый Authorized Dealership API

**Первая проверка:** не проводилась.

**Что получилось:** —

**Ошибки и причины:** —

**Что повторить:** —

**Что усилить:** —

**Обязательные исправления:** —

**Проверенные сценарии:** —/48.

**Позитивные:** —/20. **Граничные:** —/14. **Ошибочные/security:** —/14.

**Role source/matrix/route coverage:** —

**Scopes/policies/services/concurrency:** —

**Clean install/migrations/checks/tests/schema:** —

**Незакрытые threat/OpenAPI gaps:** —

**Повторная проверка:** —

**Следующий шаг:** после зачёта дня 6 сдать итоговый проект и защиту.

### Контроль понимания

**Первая попытка:** —/48.

**Обязательные вопросы 1, 2, 3, 6, 7, 9, 12, 13, 18, 19, 20, 21, 22, 23, 24, 27, 28, 30, 31, 32, 34, 35, 37, 38, 39, 41, 43, 44, 46, 48:** —

**Темы, требующие повторения:** —

**Повторная попытка:** —/48.

## Критические ошибки недели

- отсутствующее правило открывает endpoint/action;
- client назначает role/group/permission/owner/organization/staff/superuser;
- role проверяется из независимых противоречивых sources;
- buyer видит/меняет чужой Offer, Purchase или statistics;
- operator видит/меняет resource чужой organization;
- object permission используется вместо list scoping;
- create полагается на object permission и доверяет owner из body;
- service выполняет mutation без actor/policy check;
- state-based policy не повторяется внутри transaction/lock;
- staff автоматически получает platform-admin business rights;
- mutable JWT role claim является authoritative;
- generic API меняет balance, immutable history или privileged state;
- foreign/missing denial раскрывает private fields/existence вопреки contract;
- запрещённый request создаёт database/ledger/stock/email side effect;
- empty/unknown role scope возвращает `.all()`;
- statistics aggregate вычислен до actor scope;
- permission checks создают неконтролируемый N+1 на обязательном endpoint;
- real token/private data попадают в report/log/schema/Git;
- OpenAPI security contract расходится с runtime;
- основной authorization lifecycle не запускается.

## Итог недели

**Итоговая оценка:** —/10.

**Статус:** Заблокировано.

**Сильные стороны:** —

**Основные пробелы:** —

**Что повторить:** —

**Дополнительная практика:** —

**Контроль понимания:** —/48, требуется минимум 36/48 и обязательные вопросы.

**Допуск к неделе 15:** нет.

**Следующий шаг:** продолжить день 2 недели 0; к неделе 14 вернуться только после принятой недели 13.

## История изменений оценки

- 2026-09-10: создан журнал будущей недели; работа ученика не проверялась, оценки и активный прогресс не изменены.
