# Неделя 14: авторизация, роли и права на объекты

Статус: **подготовлена заранее и заблокирована до полного зачёта недели 13**.

На этой неделе identity API получает полноценную авторизацию. Пользователь уже умеет подтвердить email и получить JWT, но сам факт входа ещё не отвечает на вопросы: может ли он читать конкретную покупку, менять акцию своего поставщика, видеть чужую статистику или управлять балансом.

Главная цель — построить проверяемую систему прав для покупателей, сотрудников автосалонов, сотрудников поставщиков и администраторов. Авторизация должна работать не только на HTTP-уровне, но и внутри изменяющих состояние use cases, чтобы обход view не превращался в обход бизнес-правил.

## Результат недели

После завершения ученик умеет:

- различать identity, authentication и authorization;
- объяснять subject, resource, action, context и policy decision;
- применять deny by default и least privilege;
- строить явную permission matrix до реализации;
- использовать RBAC для грубого разделения обязанностей;
- понимать роль Django `Group`, `Permission`, `has_perm()` и custom model permissions;
- не путать `is_staff`, `is_superuser`, domain role и владение объектом;
- выбирать один источник истины для ролей и не допускать drift между `User.role` и groups;
- использовать DRF `has_permission()` и `has_object_permission()` по назначению;
- объяснять, почему object permission не фильтрует list endpoint автоматически;
- ограничивать видимость через `get_queryset()`/selectors;
- назначать owner из authenticated actor, а не из входного JSON;
- применять ABAC к состоянию пользователя, объекта и связи с организацией;
- понимать PBAC как вынесенную и тестируемую policy, не добавляя новый policy engine без необходимости;
- повторять критические проверки внутри service/use case;
- защищать Offer, purchases, promotions, balances и role-specific statistics;
- различать горизонтальное и вертикальное повышение привилегий;
- проверять IDOR/BOLA, mass assignment и guessed identifiers;
- выбирать безопасные `401`, `403` и `404` без случайной утечки существования объекта;
- учитывать permission cache и устаревшие JWT claims;
- документировать права в OpenAPI и проверять runtime contract;
- писать позитивные и отрицательные тесты для каждой значимой клетки матрицы.

## Предварительные требования

- Недели 0–13 завершены полностью.
- Все дни недели 13 имеют минимум 7/10.
- Итоговый identity API недели 13 принят минимум на 8/10.
- JWT login/refresh/logout, verification и password flows работают по принятому contract.
- Active/verified gates и secret-handling audit недели 13 приняты.
- OpenAPI совпадает с runtime.
- В `week_13_auth_email_jwt/ASSESSMENT.md` указано: «Допуск к неделе 14: да».

## Продолжение проекта недели 13

После допуска переносится только принятый проект:

```text
week_13_auth_email_jwt/day_07_identity_api/
```

в:

```text
week_14_authorization/day_07_authorized_api/
```

В `day_01_authorization_contract.md` фиксируются source branch/commit, фактическая database, версия зависимостей и green baseline. Неделя 13 не переписывается задним числом.

## Новые зависимости

Новых обязательных библиотек нет. Используются встроенные возможности Django и DRF:

- custom user и его domain role, если он уже является принятым источником истины;
- `django.contrib.auth` groups и permissions для изучения и узких capabilities;
- DRF `BasePermission`;
- scoped QuerySet/selectors;
- явные policy-функции и service-level проверки.

`django-guardian`, DRF Access Policy, OPA/Casbin и PostgreSQL Row-Level Security рассматриваются только как дальнейшие варианты. Их нельзя устанавливать для обхода непонимания базовой модели прав.

## Словарь недели

| Термин | Простой смысл | Пример |
|---|---|---|
| Subject | кто просит доступ | подтверждённый buyer |
| Resource | над чем выполняется действие | Offer №42 |
| Action | что хотят сделать | cancel |
| Context | дополнительные условия | offer всё ещё `pending` |
| Policy | правило принятия решения | buyer может отменить только свой pending offer |
| Decision | итог проверки | allow или deny |

Авторизация недели описывается функцией:

```text
decision = policy(subject, action, resource, context)
```

## Базовые принципы

1. **Deny by default.** Если разрешающее правило не найдено, действие запрещено.
2. **Least privilege.** Роль получает только необходимые действия.
3. **Every request.** Клиент, frontend и скрытая кнопка не являются контролем доступа.
4. **Server-owned identity.** `owner`, `buyer`, `supplier` и `dealership` выводятся из actor и его связей, а не принимаются на доверии из JSON.
5. **Scoped visibility.** Списки и detail lookup начинают с разрешённого QuerySet.
6. **Defense in depth.** View-level check не заменяет object-level и service-level правила.
7. **Fresh mutable policy.** Изменяемая роль/владение проверяются по текущему database state, а не только по старому JWT claim.
8. **Explicit admin override.** Административный доступ записан в матрице и тестах, а не спрятан в случайном `if is_staff`.
9. **No secret leakage.** Permission denial не раскрывает private fields, query existence или токены.
10. **Test every cell.** Разрешённые и запрещённые клетки матрицы имеют runtime tests.

## Роли проекта

Рабочая модель различает:

- `BUYER` — покупатель, работающий только со своими Offer, покупками и статистикой;
- `DEALERSHIP_OPERATOR` — сотрудник конкретного автосалона, видящий данные своего автосалона;
- `SUPPLIER_OPERATOR` — сотрудник конкретного поставщика, управляющий разрешённой частью своего каталога/акций;
- `PLATFORM_ADMIN` — доверенная platform-role с явно перечисленными полномочиями;
- `SUPERUSER` — аварийный полный доступ Django; он не заменяет тестирование обычного администратора.

Если принятая модель недели 13 использует другие названия, можно сохранить их, но смысл и матрица должны оставаться однозначными.

### Источник истины для роли

До реализации нужно выбрать и зафиксировать один вариант:

1. `User.role` — основной domain role, а Django permissions дают отдельные capabilities;
2. Django groups — основной RBAC source, а старое `User.role` удаляется или становится производным через явную migration;
3. другой уже принятый вариант с теми же инвариантами.

Нельзя независимо изменять `User.role` и `Group`, а затем проверять то одно, то другое. Если в проекте временно существуют оба механизма, в ADR должны быть owner синхронизации, migration plan и тест на drift.

## Базовая матрица прав

Это отправная точка. Точные paths/actions фиксируются в `PERMISSION_MATRIX.md`.

| Действие | Buyer | Dealership operator | Supplier operator | Platform admin |
|---|---:|---:|---:|---:|
| Читать публичный каталог | Да | Да | Да | Да |
| Создать Offer | Только от своего имени | Нет | Нет | Да по явному admin use case |
| Читать Offer | Только свои | Нет | Нет | Все |
| Отменить Offer | Только свой `pending` | Нет | Нет | По admin policy |
| Читать покупки покупателя | Только свои | Нет | Нет | Все |
| Читать остатки автосалона | Нет | Только связанного салона | Нет | Все |
| Менять предпочтения автосалона | Нет | Только связанного салона | Нет | Все |
| Читать каталог поставщика | Публичную часть | По business contract | Только своего | Все |
| Менять каталог поставщика | Нет | Нет | Только своего | Все |
| Управлять акциями | Нет | Только если явно разрешено матрицей | Только своего поставщика | Все |
| Управлять балансами | Нет | Нет | Нет | Да |
| Читать статистику | Только свою | Только своего салона | Только своего поставщика | Всю |
| Назначать роли/permissions | Нет | Нет | Нет | Только отдельный trusted admin flow |

Любое расширение матрицы сначала меняет документ и tests, затем runtime.

## Слои проверки

| Слой | Что проверяет | Что не заменяет |
|---|---|---|
| Authentication | кто выполняет запрос | право на действие |
| View permission | допустимы ли actor/action в целом | владение конкретным объектом |
| Scoped queryset/selector | какие rows actor вообще видит | правила create и сложной мутации |
| Object permission | допустимо ли действие над найденным объектом | list filtering и transaction rule |
| Serializer | разрешённые input/output fields | authoritative ownership и бизнес-policy |
| Service policy | actor/resource/state перед изменением | database constraint и locking |
| Database | integrity и concurrency | понятный HTTP denial contract |

## Политики основных use cases

### Создание Offer

Разрешено, если:

- actor authenticated, active и email verified;
- actor имеет роль buyer либо явный platform-admin override;
- buyer profile существует и принадлежит actor;
- баланс/прочие domain preconditions соблюдаются по принятому service contract;
- `buyer_id` не берётся из request body;
- создаваемый Offer всегда связывается с actor-derived buyer.

### Просмотр и отмена Offer

- buyer list/retrieve ограничивается своими rows;
- guessed UUID другого buyer не подтверждает существование Offer;
- buyer отменяет только собственный `pending` Offer;
- completed/rejected/cancelled Offer не меняется повторно;
- admin override является отдельным rule и audit event.

### Supplier/dealership operations

- operator связан ровно с разрешённой организацией или явным набором организаций;
- organization ID из URL не считается доказательством membership;
- список ограничен membership до pagination;
- create/update получают organization из server-side relation;
- balance и immutable history нельзя менять через generic CRUD.

### Статистика

- buyer получает только собственные агрегаты;
- dealership operator — агрегаты своего салона;
- supplier operator — агрегаты своего поставщика;
- platform admin — глобальные агрегаты;
- serializer не содержит private breakdown, даже если QuerySet его вычислил;
- пустой scope возвращает безопасный пустой результат, а не чужие данные.

## `401`, `403` и `404`

- `401 Unauthorized` — authentication отсутствует или credential непригоден для protected endpoint;
- `403 Forbidden` — actor известен, но действие запрещено;
- `404 Not Found` — resource не найден внутри уже ограниченного видимого scope либо existence намеренно скрывается consistent contract.

Нельзя возвращать `404` вместо любого запрета без анализа. Нельзя сначала получить чужой объект из global QuerySet, раскрыть его fields, а потом решить скрыть его существование.

## JWT и изменяемые права

JWT доказывает authentication, но role/permission может измениться раньше expiry access token. На этой неделе:

- stable user ID остаётся identity claim;
- текущая role/membership/ownership читается из database для authorization;
- изменяемый role claim не становится единственным источником решения;
- blocked/inactive gate продолжает действовать;
- после смены роли тестируется старый access token: он authenticate пользователя, но получает уже новую database policy;
- мгновенный отзыв stateless access не обещается без отдельной инфраструктуры.

## Архитектурные границы

| Компонент | Обязанность | Не должен делать |
|---|---|---|
| `permissions.py` | дешёвый request/action/object gate | строить большой отчёт или проводить сделку |
| selector/QuerySet | ограничивать visibility и эффективно читать rows | доверять client-supplied owner |
| serializer | shape, field validation и safe representation | самостоятельно назначать роль/owner из JSON |
| view/ViewSet | authentication, permission orchestration, HTTP | дублировать domain transaction |
| policy | чистое объяснимое решение по subject/action/resource/context | возвращать DRF Response |
| service | повторно проверить policy и атомарно изменить state | полагаться только на view permission |
| database | FK, uniqueness, checks, locks | знать HTTP status и error envelope |
| OpenAPI | документировать фактическую security contract | обещать недоступное runtime поведение |

## Структура модуля

- [THEORY.md](THEORY.md) — модели доступа, Django/DRF permissions, scoping и security;
- [PRACTICE.md](PRACTICE.md) — семь подробных учебных дней;
- [ASSESSMENT.md](ASSESSMENT.md) — оценки, ошибки, пересдачи и допуск;
- [notes.md](notes.md) — личные объяснения и вопросы;
- `day_01_authorization_contract.md` — baseline, ADR, matrix и threat model;
- `day_02_rbac_permissions.md` — RBAC, role source и permission mapping;
- `day_03_object_scope.md` — ownership, queryset и object checks;
- `day_04_policy_services.md` — ABAC/PBAC и service-level enforcement;
- `day_05_domain_permissions.md` — permissions доменных endpoints;
- `day_06_authorization_audit.md` — adversarial tests и OpenAPI audit;
- `day_07_authorized_api/` — накопительный итоговый проект;
- `day_07_authorized_api/PERMISSION_MATRIX.md` — каноническая таблица actor/action/resource;
- `day_07_authorized_api/AUTHORIZATION_ADR.md` — источник истины и архитектурные решения;
- `day_07_authorized_api/AUTHZ_THREAT_MODEL.md` — assets, abuse paths и controls;
- `day_07_authorized_api/OPENAPI_AUDIT.md` — runtime↔schema;
- `day_07_authorized_api/TEST_MATRIX.md` — 48 итоговых сценариев.

## Целевое дерево изменений

```text
day_07_authorized_api/
├── manage.py
├── README.md
├── PERMISSION_MATRIX.md
├── AUTHORIZATION_ADR.md
├── AUTHZ_THREAT_MODEL.md
├── OPENAPI_AUDIT.md
├── TEST_MATRIX.md
├── config/
│   ├── settings/
│   └── api_urls.py
├── common/
│   └── api/
│       ├── exceptions.py
│       └── permissions.py
├── accounts/
│   ├── roles.py
│   ├── permissions.py
│   ├── policies.py
│   ├── services.py
│   └── tests/
├── trading/
│   ├── selectors.py
│   ├── policies.py
│   ├── services.py
│   ├── api/
│   └── tests/
├── dealerships/
│   ├── selectors.py
│   ├── policies.py
│   └── tests/
├── suppliers/
│   ├── selectors.py
│   ├── policies.py
│   └── tests/
├── promotions/
│   ├── policies.py
│   └── tests/
├── analytics/
│   ├── selectors.py
│   ├── api/
│   └── tests/
└── остальные принятые файлы недели 13/
```

Названия адаптируются к фактическому проекту. Не создавать по файлу на каждое однострочное правило, но и не складывать всю policy в один огромный ViewSet.

## Порядок прохождения

1. Получить явный допуск недели 13.
2. Зафиксировать source, database и green baseline.
3. Прочитать только теорию текущего дня и связанную документацию.
4. До реализации заполнить prediction для разрешённых и запрещённых случаев.
5. Выполнить один небольшой authorization slice.
6. Запустить узкие tests, затем regressions недель 11–13.
7. Заполнить дневной журнал и самооценку.
8. Написать: `Проверь день N недели 14`.
9. Самостоятельно исправить обязательные замечания.

## Границы недели

На неделе 14 не требуются:

- OAuth2/OIDC и social login;
- MFA/WebAuthn;
- tenant-isolated database/schema;
- PostgreSQL Row-Level Security;
- `django-guardian` и новый object-permission backend;
- внешний policy engine OPA/Casbin;
- production IAM/SSO;
- admin delegation UI;
- fine-grained field masking framework;
- Redis-based distributed authorization cache;
- audit-log storage с compliance retention;
- Celery permission propagation;
- frontend route guards;
- криптографическая capability-based authorization.

Они могут появиться после освоения основной модели и при реальной необходимости.

## Критические ошибки

- endpoint разрешён по умолчанию из-за отсутствующей permission policy;
- роль, owner, `is_staff`, `is_superuser` или organization принимаются из public request body;
- обычный пользователь может назначить себе роль, group или permission;
- buyer видит или меняет чужой Offer/purchase/statistics;
- operator получает данные чужой организации через URL/filter/body identifier;
- list endpoint полагается только на `has_object_permission()` и возвращает чужие rows;
- create endpoint ожидает, что object permission сработает автоматически;
- permission проверяется только во frontend или serializer representation;
- service выполняет критическую mutation без actor/policy check;
- `is_staff` ошибочно считается platform-admin правом;
- JWT role claim является единственным источником изменяемой роли;
- generic CRUD позволяет менять balance, immutable history или внутренние role fields;
- denial response раскрывает private object fields или sensitive reason;
- unauthorized request изменяет database, отправляет письмо или запускает другой side effect;
- permission/query cache даёт старое право после role revocation в проверяемом flow;
- тестируется только superuser happy path;
- OpenAPI объявляет публичным защищённый endpoint или наоборот;
- expected результат записан как actual без запуска.

## Критерий завершения

- дни 1–6 приняты минимум на 7/10;
- итоговый проект принят минимум на 8/10;
- source-of-truth для ролей и migration decision зафиксированы;
- permission matrix содержит все actor/action/resource combinations недели;
- глобальная policy deny-by-default явно настроена;
- public catalog остаётся только read-only;
- role assignment недоступен через public API;
- buyer Offer и purchase scopes защищены;
- dealership/supplier operations ограничены membership;
- balance/history protected от generic writes;
- stats разделены по actor scope;
- list/detail/create/update/custom actions используют подходящий слой проверки;
- service-level checks закрывают обход HTTP;
- старый JWT после role change получает свежую database policy;
- 401/403/404 contract однозначен и протестирован;
- horizontal/vertical escalation и BOLA/IDOR tests проходят;
- отрицательные запросы не создают side effects;
- query count не растёт линейно из-за permission checks;
- OpenAPI совпадает с runtime security contract;
- regressions недель 11–13 green;
- clean setup/migrations воспроизводимы;
- `TEST_MATRIX.md` содержит фактические результаты 48 сценариев;
- минимум 36 из 48 вопросов защиты отвечены уверенно;
- в `ASSESSMENT.md` указано: «Допуск к неделе 15: да».

## Официальные материалы

- [Django: permissions and authorization](https://docs.djangoproject.com/en/5.2/topics/auth/default/#permissions-and-authorization)
- [Django: custom permissions](https://docs.djangoproject.com/en/5.2/topics/auth/customizing/#custom-permissions)
- [Django authentication reference](https://docs.djangoproject.com/en/5.2/ref/contrib/auth/)
- [DRF: permissions](https://www.django-rest-framework.org/api-guide/permissions/)
- [DRF: filtering](https://www.django-rest-framework.org/api-guide/filtering/)
- [DRF: testing](https://www.django-rest-framework.org/api-guide/testing/)
- [OWASP Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html)
- [OWASP API Security Top 10: Broken Object Level Authorization](https://owasp.org/API-Security/editions/2023/en/0xa1-broken-object-level-authorization/)

## Текущий статус

Неделя 14 только подготовлена. Текущий активный этап остаётся в `week_00_basics/ASSESSMENT.md`: день 2 недели 0. До допуска из недели 13 не переносить проект и не менять authorization runtime.
