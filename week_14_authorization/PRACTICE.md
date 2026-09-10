# Практика недели 14: авторизация, роли и права на объекты

Статус: **заблокирована до полного зачёта недели 13**.

## Общие правила

- Все дни развивают один принятый проект в `day_07_authorized_api/`.
- Код пишет и исправляет ученик. Наставник не переписывает решение во время обычной проверки.
- До первого изменения создаются `PERMISSION_MATRIX.md`, `AUTHORIZATION_ADR.md` и `AUTHZ_THREAT_MODEL.md`.
- Каждое разрешение формулируется как `subject + action + resource + context -> allow/deny`.
- Если разрешающее правило не найдено, решение — deny.
- Role, group, permission, owner, organization, balance, status и audit fields не принимаются на доверии из public JSON.
- List/retrieve/update используют scoped QuerySet; object permission не считается list filter.
- Create получает owner/organization из authenticated actor и trusted database relations.
- Critical mutation повторно проверяет policy внутри service и transaction.
- JWT подтверждает identity; текущая mutable role/membership берётся из database.
- Negative test проверяет не только status, но и отсутствие database/email/ledger/прочих side effects.
- Не использовать real accounts, JWT и private data в документации или evidence.
- После каждого дня запускать узкий набор tests и regressions недель 11–13.
- Новые authorization-библиотеки не устанавливать.

## Формат authorization-сценария

```text
Scenario ID:
Subject: anonymous/user ID placeholder/role/organization/state
Action and endpoint:
Resource: own/foreign/missing/type/state
Context/preconditions:
Expected decision and status:
Expected visible response shape:
Expected database/side effects:
Actual decision and status:
Actual response shape:
Actual database/side effects:
Queries/log evidence without secrets:
Explanation:
Correction or next check:
```

## Самооценка дня

1. Какое правило я реализовал и на каком слое?
2. Почему здесь недостаточно одной role check?
3. Что произойдёт с чужим или несуществующим identifier?
4. Какие server-owned fields защищены?
5. Как я доказал отсутствие side effect после deny?
6. Какой test сломается, если убрать scope или policy?
7. Что осталось непонятным?
8. Сколько времени заняла работа?

## Шкала обычного дня

| Критерий | Баллы |
|---|---:|
| Корректность результата | 0–3 |
| Выполнение условий | 0–2 |
| Граничные, отрицательные и abuse-сценарии | 0–2 |
| Читаемость и authorization boundaries | 0–1 |
| Понимание и самооценка | 0–1 |
| Самостоятельность исправлений | 0–1 |

Обычный день принят при 7/10 без критической ошибки. Итоговый проект принят при 8/10.

---

# День 1. Контракт авторизации, матрица прав и threat model

## Документация

- [OWASP Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html) — least privilege, deny by default и проверка прав на каждом запросе.
- [Django: permissions and authorization](https://docs.djangoproject.com/en/5.2/topics/auth/default/#permissions-and-authorization) — встроенные users, groups и permissions.

## Паспорт задания

- **Цель:** до кода определить actors, resources, actions, policy source и все разрешённые/запрещённые клетки недели.
- **Рабочий файл или каталог:** `day_07_authorized_api/`; документы — `PERMISSION_MATRIX.md`, `AUTHORIZATION_ADR.md`, `AUTHZ_THREAT_MODEL.md`; журнал — `day_01_authorization_contract.md`.
- **Результат:** проверенный baseline недели 13, inventory текущих authz-механизмов, ADR источника роли, полная permission matrix и threat model с testable controls.
- **Порядок выполнения:** подтвердить допуск; перенести accepted project; записать source/database/versions; запустить baseline; проаудировать User/groups/permissions/profiles/endpoints; выбрать role source; заполнить матрицу; построить threat model; записать 10 predictions.
- **Наблюдаемый результат:** по любому endpoint можно до реализации назвать actor, action, scope, policy layer, expected status и side effects; противоречия старых `role`/groups выявлены.
- **Готово, если:** source и baseline честны; один role source выбран; `is_staff` не равен business admin; matrix содержит allow и deny; list/create/object/service layers указаны; horizontal/vertical escalation описаны; 10 сценариев записаны.
- **Пример:** `buyer A + retrieve + offer buyer B -> deny, 404 внутри buyer scope, DB без изменений`.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–10. **Рекомендация:** небольшая diagram потока решения после таблицы.

## Теория

Прочитайте разделы 1–15, 24 и 41–42 `THEORY.md`.

## Задание 1. Допуск и безопасный перенос

- **Исходные данные:** явный допуск недели 13, accepted branch/commit, working tree и dependency file.
- **Действие:** перенесите проект недели 13 в `day_07_authorized_api/`; запишите source; не копируйте `.env`, database dumps, logs, emails или tokens.
- **Результат:** новая неделя имеет известное происхождение, а week 13 остаётся неизменной.
- **Проверить:** accepted source; dirty source; missing approval; secret-like files; повторный перенос.

## Задание 2. Database и regression baseline

- **Исходные данные:** settings/test settings, migrations, suites недель 11–13.
- **Действие:** зафиксируйте безопасное имя vendor/database purpose без DSN; запустите Django checks, migration drift/plan, auth/DRF regressions и schema validation.
- **Результат:** известен фактический green/red baseline до authorization changes.
- **Проверить:** green run; старая failure; unapplied migration; случайный SQLite; shared/production-like target — остановка.

## Задание 3. Inventory actors и identity attributes

- **Исходные данные:** custom User, profiles, groups, permissions, `is_staff`, `is_superuser`, active/verified flags и JWT claims.
- **Действие:** заполните таблицу `attribute | source | mutable | who changes | authoritative for | risk`; перечислите anonymous, buyer, dealership/supplier operator, staff, platform admin и superuser.
- **Результат:** видно, какие данные уже существуют и где возможны два источника истины.
- **Проверить:** user без profile; role без group; group без role; staff без business permission; blocked/unverified; mutable JWT role claim.

## Задание 4. Inventory resources/actions/endpoints

- **Исходные данные:** routes и models Offer, Purchase, Promotion, supplier catalog, dealership preferences/inventory, balances и statistics.
- **Действие:** заполните `path/action | resource | read/write | current permission | current queryset | owner/organization relation | sensitive fields`.
- **Результат:** нет «забытых» endpoints и custom actions вне будущей матрицы.
- **Проверить:** list/detail/create/update/delete; custom actions; filters; admin endpoints; schema/docs; legacy URL.

## Задание 5. Authorization ADR

- **Исходные данные:** существующие `User.role`, Django groups/permissions и organization membership.
- **Действие:** выберите canonical role source; опишите альтернативы, причины отказа, migration/sync plan и admin/superuser semantics.
- **Результат:** runtime не сможет случайно считать роль из двух независимых мест.
- **Проверить:** role assignment; revocation; permission cache; old JWT; missing profile; multi-organization future.

## Задание 6. Permission matrix

- **Исходные данные:** actors и endpoints из заданий 3–4, базовая матрица `README.md`.
- **Действие:** для каждой клетки запишите `allow/deny`, scope (`own`, organization, all), required state, policy layer и expected 401/403/404.
- **Результат:** каждый allow объяснён рабочей задачей; неизвестная роль получает deny.
- **Проверить:** anonymous; wrong role; own/foreign; missing object; unverified/blocked; staff; admin; superuser.

## Задание 7. Threat model

- **Исходные данные:** user/organization/private records/balances/roles как assets и все identifiers/filters/body fields как entry points.
- **Действие:** заполните `asset | attacker | abuse path | impact | control | test`; включите BOLA, horizontal/vertical escalation, mass assignment, stale role, missing scope и side effects before denial.
- **Результат:** каждая high-risk угроза связана с конкретным test и owner слоя.
- **Проверить:** guessed UUID; modified organization ID; role in PATCH; staff misuse; direct service call; list/count leak; log leak.

## Задание 8. Predictions и protection order

- **Исходные данные:** десять обязательных сценариев ниже.
- **Действие:** до изменений предскажите status, response shape, rows returned, queries и side effects; затем укажите будущий порядок `authentication -> action gate -> scope -> object policy -> service policy -> mutation`.
- **Результат:** prediction не выдан за actual result; архитектурный порядок согласован.
- **Проверить:** allow; deny; missing; own/foreign; role revoked; invalid JWT; service bypass.

## Обязательные сценарии дня

1. Baseline недели 13 green до изменений.
2. Database target безопасно подтверждена.
3. Anonymous обращается к protected Offer list.
4. Buyer A запрашивает Offer buyer B.
5. Buyer пытается передать `buyer_id` другого пользователя при create.
6. Supplier operator меняет catalog item чужого supplier.
7. Staff без business capability меняет balance.
8. Platform admin выполняет явно разрешённое действие.
9. Unknown/new role обращается к endpoint без matching rule.
10. Role пользователя отозвана после выпуска access JWT.

## Контрольные вопросы

1. Чем authorization отличается от authentication?
2. Что означает deny by default?
3. Почему `is_staff` не равен platform admin?
4. Чем горизонтальное повышение прав отличается от вертикального?
5. Почему permission matrix пишется до кода?
6. Что произойдёт при двух источниках истины для роли?

---

# День 2. RBAC, Django groups/permissions и DRF action gates

## Документация

- [Django authentication reference: `Group` and `Permission`](https://docs.djangoproject.com/en/5.2/ref/contrib/auth/) — модели ролей/capabilities и методы проверки прав.
- [DRF: custom permissions](https://www.django-rest-framework.org/api-guide/permissions/#custom-permissions) — `has_permission()` и композиция request-level правил.

## Паспорт задания

- **Цель:** реализовать coarse-grained RBAC и безопасное сопоставление ViewSet actions с ролями/capabilities.
- **Рабочий файл или каталог:** accounts/common authorization modules и tests в `day_07_authorized_api/`; документы — `AUTHORIZATION_ADR.md`, `PERMISSION_MATRIX.md`; журнал — `day_02_rbac_permissions.md`.
- **Результат:** canonical role helpers, воспроизводимое назначение Django permissions при выбранной архитектуре, DRF action gates и закрытый role-assignment surface.
- **Порядок выполнения:** реализовать role predicates; при необходимости создать custom permissions/migration; сделать idempotent role provisioning; построить action map; подключить fail-closed permission classes; закрыть sensitive fields; проверить cache/revocation/admin distinctions.
- **Наблюдаемый результат:** разрешённая роль проходит только указанные actions; неизвестная роль и staff без capability получают отказ; public client не может изменить роль.
- **Готово, если:** role source соответствует ADR; provisioning повторяем; permission map явный; no matching action означает deny; `is_staff`/admin/superuser различены; role fields отсутствуют в public input; 12 сценариев записаны.
- **Пример:** `supplier_operator + partial_update own catalog item` проходит общий action gate, но объектная принадлежность будет проверена в день 3.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–12. **Рекомендация:** helpers возвращают bool/decision и не знают о DRF Response.

## Теория

Прочитайте разделы 8–14, 18 и 32–35 `THEORY.md`.

## Задание 1. Canonical role helpers

- **Исходные данные:** ADR дня 1 и фактический User/group schema.
- **Действие:** создайте небольшие predicates для buyer/dealership/supplier/platform-admin и active+verified gate; не читайте роль из raw JWT payload.
- **Результат:** одна точка интерпретации role source с deny для missing/unknown value.
- **Проверить:** each role; unknown; null/missing profile; inactive; unverified; superuser policy.

## Задание 2. Custom model permissions

- **Исходные данные:** capabilities, которые не выражаются стандартным CRUD, например `manage_balances` и `view_global_statistics`.
- **Действие:** добавьте только действительно нужные custom permissions через model `Meta`/migration; объясните app label/codename.
- **Результат:** permissions появляются после clean migrate и не создаются request-time кодом.
- **Проверить:** fresh database; repeated migrate; exact codename; missing permission; stale content type.

## Задание 3. Воспроизводимое назначение ролей

- **Исходные данные:** выбранный source, groups/capabilities и trusted setup path.
- **Действие:** реализуйте idempotent data migration или management command для permission/group provisioning; не назначайте реальных пользователей автоматически.
- **Результат:** два запуска дают тот же набор roles/permissions без duplicates.
- **Проверить:** first run; second run; missing permission; renamed codename; rollback/clean replay.

## Задание 4. DRF request-level permissions

- **Исходные данные:** permission matrix для create/list/admin actions.
- **Действие:** реализуйте короткие `BasePermission` classes либо один ясный action-policy adapter; unknown action запрещается.
- **Результат:** `has_permission()` решает только actor/action gate и не притворяется object scope.
- **Проверить:** list/create/custom action; wrong role; anonymous; inactive/unverified; unlisted action.

## Задание 5. ViewSet action map

- **Исходные данные:** `list`, `retrieve`, `create`, `partial_update`, `destroy`, `cancel` и admin actions.
- **Действие:** задайте явное сопоставление action -> permissions/serializers; не используйте method-only rule, если два POST action имеют разные права.
- **Результат:** route/action contract можно сравнить с matrix и OpenAPI.
- **Проверить:** router routes; custom action; `OPTIONS`; unsupported method; renamed action.

## Задание 6. Закрытие mass assignment

- **Исходные данные:** registration, me/profile, Offer, supplier catalog и admin serializers.
- **Действие:** удалите из public writable fields role/group/permissions/owner/organization/staff/superuser/status/balance; добавьте explicit readonly/unknown-field policy.
- **Результат:** privilege fields невозможно изменить через обычный POST/PATCH.
- **Проверить:** each forbidden field alone; nested payload; partial update; alternative casing; unknown field behavior.

## Задание 7. Staff, platform admin и superuser

- **Исходные данные:** три отдельных test users.
- **Действие:** проверьте их возможности на business endpoints и Django permissions; не используйте только superuser.
- **Результат:** staff без capability получает deny, platform admin — разрешённую матрицу, superuser — явно описанный override.
- **Проверить:** admin site access; business balance action; global stats; role assignment; blocked admin.

## Задание 8. Permission cache и revocation tests

- **Исходные данные:** user до/после назначения/отзыва group или permission.
- **Действие:** продемонстрируйте cache behavior; после изменения получите fresh user; проверьте API со старым JWT и текущим database role state.
- **Результат:** tests не дают ложный результат из-за reused user object, а revoked role перестаёт разрешать действие.
- **Проверить:** grant; revoke; same instance; fresh instance; old access token; inactive after token issue.

## Обязательные сценарии дня

1. Buyer проходит buyer-only action gate.
2. Dealership operator не создаёт Offer.
3. Supplier operator проходит catalog-management action gate.
4. Unknown role получает deny.
5. Anonymous получает фактический 401 contract protected endpoint.
6. Unverified buyer не создаёт Offer.
7. Inactive admin не проходит protected business action.
8. Staff без `manage_balances` не меняет balance.
9. Platform admin с capability проходит balance action.
10. Public PATCH не меняет role/group/permission.
11. Idempotent provisioning дважды даёт один результат.
12. Отозванная роль перестаёт действовать при старом access JWT.

## Контрольные вопросы

1. Что RBAC описывает хорошо, а что плохо?
2. Чем Group отличается от Permission?
3. Когда нужен custom permission?
4. Почему action map должен быть fail closed?
5. Почему нельзя проверять только `is_staff`?
6. Как permission cache влияет на tests?

---

# День 3. Ownership, scoped QuerySet и object-level permissions

## Документация

- [DRF: object-level permissions and limitations](https://www.django-rest-framework.org/api-guide/permissions/#object-level-permissions) — когда вызывается `has_object_permission()` и почему list/create требуют других мер.
- [DRF: filtering against the current user](https://www.django-rest-framework.org/api-guide/filtering/#filtering-against-the-current-user) — ограничение QuerySet по текущему пользователю.

## Паспорт задания

- **Цель:** закрыть горизонтальный доступ через ownership и organization scope для list, detail и create.
- **Рабочий файл или каталог:** selectors/querysets, DRF permissions/views/serializers и tests в `day_07_authorized_api/`; журнал — `day_03_object_scope.md`.
- **Результат:** buyer видит только свои Offer/purchases, operators — ресурсы своей организации, detail ищется в scope, create назначает owner server-side.
- **Порядок выполнения:** создать controlled dataset; написать visibility selectors; подключить их до filters/pagination; реализовать object policy; защитить create; определить 404/403; проверить direct/custom lookup; измерить queries.
- **Наблюдаемый результат:** list/count/pagination не содержат чужих данных; guessed foreign identifier не раскрывает объект; body не меняет owner; object check остаётся defense-in-depth.
- **Готово, если:** selectors fail closed; scope применяется до pagination; detail использует scoped QuerySet; custom get_object вызывает check; create server-owned; own/foreign/missing contracts различимы только там, где задумано; 12 сценариев записаны.
- **Пример:** buyer A получает `[offer_A1, offer_A2]`, хотя в database также есть `offer_B1`; `GET offer_B1` даёт 404 в его scope.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–12. **Рекомендация:** один selector повторно используется API и будущей analytics policy там, где contract совпадает.

## Теория

Прочитайте разделы 7, 19–27, 31 и 37–38 `THEORY.md`.

## Задание 1. Controlled ownership dataset

- **Исходные данные:** buyers A/B, dealership A/B, supplier A/B, own/foreign Offer, Purchase, catalog item и Promotion.
- **Действие:** создайте минимальные factories/helpers стандартными средствами текущего проекта и таблицу ownership relations.
- **Результат:** каждый test однозначно знает own, foreign и missing identifier.
- **Проверить:** two rows each scope; inactive relation; user without profile; same model different organization.

## Задание 2. Buyer visibility selectors

- **Исходные данные:** authenticated buyer/admin/unknown actors и Offer/Purchase QuerySets.
- **Действие:** реализуйте `offers_visible_to()` и `purchases_visible_to()` с `.none()` default и explicit admin branch.
- **Результат:** buyer получает только rows, связанные с его profile; admin — scope по matrix.
- **Проверить:** buyer A/B; admin; supplier; no profile; anonymous; inactive/unverified according read policy.

## Задание 3. Organization visibility selectors

- **Исходные данные:** operators и resources двух dealerships/suppliers.
- **Действие:** scope inventory/preferences/catalog/promotions по trusted membership relation, не по одному URL parameter.
- **Результат:** operator не видит resource другой organization даже при guessed ID/filter.
- **Проверить:** own; foreign; missing membership; inactive organization; URL mismatch; admin.

## Задание 4. List/filter/pagination order

- **Исходные данные:** mixed dataset, filters и bounded pagination недели 12.
- **Действие:** примените authorization scope до client filters, ordering и pagination; сравните count/results.
- **Результат:** metadata считает только видимые rows, пустой scope не переключается на `.all()`.
- **Проверить:** page 1/2; foreign matching filter; invalid filter; ordering; empty scope; page beyond end.

## Задание 5. Scoped detail и object permission

- **Исходные данные:** own/foreign/missing IDs и ViewSet retrieve/update/custom actions.
- **Действие:** detail lookup выполняйте через `get_queryset()`; добавьте `has_object_permission()` для action/state rules; в custom lookup вызовите `check_object_permissions()`.
- **Результат:** foreign/missing contract не раскрывает object, own object проходит только разрешённое action.
- **Проверить:** generic retrieve; overridden get_object; custom action; foreign; missing; visible-but-readonly.

## Задание 6. Server-owned create

- **Исходные данные:** Offer create input и supplier/dealership create/update inputs.
- **Действие:** назначьте buyer/organization из actor relation в service; запретите или сделайте readonly client owner fields.
- **Результат:** подмена ID в body не создаёт object для другого owner.
- **Проверить:** no owner field; foreign owner field; own owner field; missing profile; admin explicit use case; duplicate input.

## Задание 7. Field-level representations

- **Исходные данные:** public, owner/operator и admin views одного resource.
- **Действие:** сравните explicit serializers; удалите private cost/balance/audit/internal relation fields из неподходящих responses.
- **Результат:** visibility объекта не раскрывает поля другого privilege level.
- **Проверить:** public catalog; supplier owner; dealership viewer; buyer; admin; schema fields.

## Задание 8. Query-budget audit

- **Исходные данные:** list N=2 и N=20 с ownership/membership relations.
- **Действие:** измерьте queries и устраните permission N+1 через joins/prefetch/scoped filters; запишите SQL roles, не секреты.
- **Результат:** query count постоянен либо обоснован; удаление eager loading ломает budget test.
- **Проверить:** N=2; N=20; empty; paginated; admin; serializer relation.

## Обязательные сценарии дня

1. Buyer A list не содержит Offer buyer B.
2. Buyer A purchase list не содержит покупку buyer B.
3. Foreign Offer ID даёт выбранный 404 contract.
4. Missing Offer ID имеет тот же public shape, если existence скрывается.
5. Own Offer retrieve работает.
6. Buyer body не меняет `buyer_id` при create.
7. Supplier A не видит catalog item supplier B.
8. Dealership A не видит preferences dealership B.
9. Foreign matching filter не влияет на count/pagination.
10. Empty membership возвращает empty/deny по matrix, не `.all()`.
11. Custom `get_object()` выполняет object permission.
12. Query budget N=2/N=20 не растёт линейно.

## Контрольные вопросы

1. Почему `has_object_permission()` не защищает list?
2. Почему он не защищает create автоматически?
3. Зачем одновременно scope и object check?
4. Почему фильтрация выполняется до pagination?
5. Почему UUID не является permission check?
6. Какие fields должны быть server-owned?

---

# День 4. ABAC/PBAC и авторизация внутри сервисов

## Документация

- [OWASP Authorization Cheat Sheet: relationship and attribute-based access control](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html#prefer-attribute-and-relationship-based-access-control-over-rbac) — правила по атрибутам и отношениям, дополняющие роли.
- [Django: database transactions](https://docs.djangoproject.com/en/5.2/topics/db/transactions/) — атомарная повторная проверка состояния перед изменением.

## Паспорт задания

- **Цель:** вынести контекстные правила в тестируемые policies и обеспечить их выполнение внутри изменяющих состояние services.
- **Рабочий файл или каталог:** domain policies/services/tests в `day_07_authorized_api/`; документы — `PERMISSION_MATRIX.md`, `AUTHORIZATION_ADR.md`; журнал — `day_04_policy_services.md`.
- **Результат:** policies для Offer create/cancel и organization mutations, service принимает actor, блокирует rows и не меняет state после deny/race.
- **Порядок выполнения:** определить policy inputs/decisions; написать pure tests; подключить Offer creation; сделать atomic cancel; добавить operator policy; определить exception mapping; проверить direct service call и concurrency.
- **Наблюдаемый результат:** правильная роль всё равно получает deny для чужого/неподходящего state; обход HTTP не обходит policy; concurrent transition завершается один раз.
- **Готово, если:** policies не зависят от Response; actor обязателен для service; state recheck внутри transaction; direct call защищён; denial без side effect; admin override явный; 12 сценариев записаны.
- **Пример:** buyer владеет Offer, но `completed` state делает `cancel` запрещённым даже при правильной роли.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–12. **Рекомендация:** internal decision code отдельно от безопасного public error code.

## Теория

Прочитайте разделы 15–17, 27–35 и 39 `THEORY.md`.

## Задание 1. Policy contracts

- **Исходные данные:** matrix rows `create_offer`, `cancel_offer`, `change_supplier_item`, `change_dealership_preference`.
- **Действие:** для каждой policy запишите required subject/resource/context attributes и possible internal deny categories.
- **Результат:** policy signature не получает request/serializer/Response.
- **Проверить:** allow; wrong role; wrong owner/org; blocked/unverified; invalid state; admin override.

## Задание 2. Pure policy tests

- **Исходные данные:** минимальные actors/resources без HTTP.
- **Действие:** протестируйте decision table отдельно от database mutation; используйте понятные names и parametrization только если она уже введена/разрешена текущим stack.
- **Результат:** удаление каждого precondition ломает соответствующий negative test.
- **Проверить:** every branch; unknown role; missing relation; boundary state.

## Задание 3. Offer creation service

- **Исходные данные:** actor, validated car/price input, actor-derived BuyerProfile и domain preconditions.
- **Действие:** service проверяет active/verified/buyer policy, получает buyer из actor и создаёт Offer в transaction; body owner игнорировать нельзя — поле отсутствует/запрещено.
- **Результат:** только допустимый actor создаёт собственный Offer.
- **Проверить:** valid buyer; unverified; inactive; wrong role; no profile; attempted foreign buyer; admin explicit flow.

## Задание 4. Atomic Offer cancellation

- **Исходные данные:** actor, offer ID и statuses pending/processing/completed/rejected/cancelled.
- **Действие:** внутри `transaction.atomic()` загрузите/заблокируйте Offer с owner relation, повторно вызовите policy и выполните один допустимый transition.
- **Результат:** own pending Offer отменяется один раз; остальные cases не меняют state.
- **Проверить:** own pending; foreign pending; each terminal status; two sequential calls; two concurrent calls.

## Задание 5. Organization mutation service

- **Исходные данные:** supplier catalog или promotion и operator membership.
- **Действие:** service получает actor/resource ID, блокирует mutable row при необходимости и проверяет актуальную membership/role перед изменением.
- **Результат:** URL/body organization не заменяет database relation.
- **Проверить:** own org; foreign org; revoked membership; inactive org; admin; direct call.

## Задание 6. Exception boundary

- **Исходные данные:** internal `AuthorizationDenied`, invalid state, missing scoped object и validation errors.
- **Действие:** сопоставьте их с error envelope/status; не возвращайте internal ownership/role details там, где они раскрывают существование.
- **Результат:** HTTP contract стабилен, а service не импортирует DRF exceptions/Response.
- **Проверить:** 401; 403; 404; 409/400 state conflict по contract; unexpected exception remains server error.

## Задание 7. Direct service bypass tests

- **Исходные данные:** service functions без view/serializer.
- **Действие:** вызовите их напрямую wrong actor; проверьте denial и неизменность rows/ledger/stock/email.
- **Результат:** management command/Celery/admin future caller не обходит policy.
- **Проверить:** wrong buyer; supplier from other org; staff no capability; missing actor; fake object ID.

## Задание 8. TOCTOU/concurrency evidence

- **Исходные данные:** два database connections/threads по уже принятой методике PostgreSQL недель 7/10.
- **Действие:** воспроизведите competing cancel/complete либо membership revoke/mutation; зафиксируйте lock order и final state.
- **Результат:** policy, зависящая от mutable state, проверяется после lock; допустим только один final transition.
- **Проверить:** cancel vs cancel; cancel vs complete; revoked membership before lock; rollback; deadlock avoidance.

## Обязательные сценарии дня

1. Active verified buyer создаёт свой Offer.
2. Unverified buyer не создаёт Offer.
3. Buyer без profile не создаёт Offer.
4. Wrong role не создаёт Offer.
5. Own pending Offer отменяется.
6. Foreign pending Offer не меняется.
7. Completed Offer не отменяется.
8. Повторная отмена не создаёт второй transition/side effect.
9. Supplier operator меняет только resource своего supplier.
10. Revoked membership запрещает direct service call.
11. Staff без capability не получает admin override.
12. Concurrent operation сохраняет один допустимый final state.

## Контрольные вопросы

1. Что ABAC добавляет к RBAC?
2. Что PBAC означает без внешнего engine?
3. Почему service принимает actor?
4. Зачем повторять check после row lock?
5. Почему service не возвращает DRF Response?
6. Что доказывает direct service test?

---

# День 5. Доменные права: Offers, организации, балансы и статистика

## Документация

- [DRF: overview of access restriction methods](https://www.django-rest-framework.org/api-guide/permissions/#overview-of-access-restriction-methods) — выбор между QuerySet, permissions и serializers для разных actions.
- [DRF: ViewSets and extra actions](https://www.django-rest-framework.org/api-guide/viewsets/#marking-extra-actions-for-routing) — безопасное оформление отдельных бизнес-действий.

## Паспорт задания

- **Цель:** применить единую permission matrix ко всем обязательным доменам и не оставить обходной endpoint.
- **Рабочий файл или каталог:** trading/dealerships/suppliers/promotions/analytics API, selectors, policies, services и tests в `day_07_authorized_api/`; журнал — `day_05_domain_permissions.md`.
- **Результат:** защищённые Offer/purchase endpoints, organization-scoped operations, admin-only balances, role-specific statistics и public catalog без regression.
- **Порядок выполнения:** сверить route inventory; завершить Offer/purchase surface; ограничить dealership/supplier resources; реализовать promotion policy; закрыть balances/history; сделать stats scopes; проверить serializers/filters; провести matrix sweep.
- **Наблюдаемый результат:** каждая роль получает только свои действия/данные; admin override явный; незнакомый route/action запрещён; public catalog остаётся read-only.
- **Готово, если:** все route rows покрыты; generic sensitive CRUD отсутствует; own/org/all scopes работают; stats считаются после scope; filters не меняют границу; admin и staff различены; 14 сценариев записаны.
- **Пример:** supplier operator меняет цену своего catalog item, но не баланс, не чужой item и не immutable purchase history.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–14. **Рекомендация:** matrix tests группируются по resource, чтобы failure сразу указывал на нарушенную клетку.

## Теория

Прочитайте разделы 21–23, 25–28, 31–32 и 36–40 `THEORY.md`.

## Задание 1. Route-to-matrix reconciliation

- **Исходные данные:** фактический router/OpenAPI path list и `PERMISSION_MATRIX.md`.
- **Действие:** сопоставьте каждый path/method/action со строкой matrix; удалите/закройте legacy route, у которого нет решения.
- **Результат:** route coverage 100%, public exceptions явно перечислены.
- **Проверить:** router-generated paths; custom actions; alternate trailing slash; deprecated version; schema/docs/health exceptions.

## Задание 2. Offer и purchase API

- **Исходные данные:** buyer/admin roles, own/foreign Offers/Purchases и Offer state machine.
- **Действие:** разрешите buyer create/list/retrieve/cancel в пределах own policy; purchase — read-only own; admin actions только по явному contract.
- **Результат:** generic update/delete не обходят state services.
- **Проверить:** own/foreign; pending/terminal; guessed ID; attempted PATCH status/owner; admin; wrong role.

## Задание 3. Dealership scope

- **Исходные данные:** dealership operators A/B, preferences, inventory и statistics.
- **Действие:** разрешите только actions своего dealership из matrix; запретите direct balance/history mutation.
- **Результат:** operator A не читает/изменяет B через path, filter или body.
- **Проверить:** own list/detail; foreign ID; filter by foreign dealership; inactive dealership; no membership; admin.

## Задание 4. Supplier scope и promotions

- **Исходные данные:** supplier operators A/B, catalog items, discounts/promotions и lifecycle states.
- **Действие:** ограничьте create/update/deactivate собственным supplier и разрешёнными fields; promotion rules учитывают organization ownership и status.
- **Результат:** supplier ID назначается server-side; чужая акция недоступна; historical rows не удаляются.
- **Проверить:** own/foreign create/update; deactivate; expired promotion; attempted supplier reassignment; admin.

## Задание 5. Balance и immutable history

- **Исходные данные:** buyers/organizations balances, BalanceMovement, StockMovement, Purchase/Sale history.
- **Действие:** удалите generic writable endpoints; если есть admin adjustment, оформите узкий service/action с capability, reason и ledger entry.
- **Результат:** никто не PATCH-ит balance напрямую; history остаётся read-only.
- **Проверить:** buyer; operator; staff; platform admin; missing reason; negative result; direct model endpoint absent.

## Задание 6. Role-specific statistics

- **Исходные данные:** mixed sales/offers/purchases двух buyers, dealerships и suppliers.
- **Действие:** scope source QuerySet по actor до aggregation; используйте разные selectors/serializers для buyer/org/admin contract.
- **Результат:** каждый actor получает только свой aggregate и разрешённые dimensions.
- **Проверить:** buyer A/B; dealership A/B; supplier A/B; admin global; empty scope; foreign filters.

## Задание 7. Public catalog regression

- **Исходные данные:** public list/retrieve catalog недели 12 и новые global defaults.
- **Действие:** подтвердите explicit `AllowAny` только на read-only catalog actions; методы записи и private fields остаются закрыты.
- **Результат:** anonymous GET работает, POST/PATCH/DELETE не открылись.
- **Проверить:** GET list/retrieve; HEAD/OPTIONS contract; POST/PATCH/DELETE; private cost; inactive visibility.

## Задание 8. Full matrix sweep

- **Исходные данные:** все actors/resources/actions этой недели.
- **Действие:** запустите table-driven API tests; для denies сравните before/after rows, status, response keys и side effects.
- **Результат:** каждая клетка matrix имеет actual evidence; failures указывают scenario ID.
- **Проверить:** allow; deny; missing; wrong state; role revoked; no profile/membership; admin; superuser separately.

## Обязательные сценарии дня

1. Buyer создаёт Offer только от своего имени.
2. Buyer видит только свои Offers.
3. Buyer видит только свои Purchases.
4. Buyer отменяет только own pending Offer.
5. Dealership operator видит статистику только своего салона.
6. Dealership operator не меняет balance.
7. Supplier operator меняет только свой catalog item.
8. Supplier operator не переназначает item другому supplier.
9. Promotion изменяет только разрешённый organization actor.
10. Immutable history не имеет generic write route.
11. Platform admin выполняет только явно перечисленные admin actions.
12. Staff без capability не наследует platform-admin доступ.
13. Anonymous catalog GET остаётся доступен, write закрыт.
14. Unknown route/action не получает permissive fallback.

## Контрольные вопросы

1. Почему Offer лучше отменять command action, а не generic PATCH?
2. Почему supplier ID является server-owned?
3. Где scope применяется к aggregate?
4. Почему balance нельзя менять обычным ModelViewSet?
5. Как проверить, что filter не расширяет scope?
6. Чем platform admin отличается от superuser в tests?

---

# День 6. Adversarial audit, JWT freshness, OpenAPI и regressions

## Документация

- [DRF: testing](https://www.django-rest-framework.org/api-guide/testing/) — APIClient/APIRequestFactory и проверка фактического permission path.
- [OWASP Authorization Cheat Sheet: authorization testing](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html#create-unit-and-integration-test-cases-for-authorization-logic) — систематические позитивные и отрицательные тесты прав.
- [Simple JWT settings](https://django-rest-framework-simplejwt.readthedocs.io/en/stable/settings.html) — claims, user identification и параметры token lifecycle, влияющие на freshness assumptions.

## Паспорт задания

- **Цель:** доказать устойчивость авторизации против обходов и привести OpenAPI/logging/runtime к одному contract.
- **Рабочий файл или каталог:** authorization/security/schema tests и документы в `day_07_authorized_api/`; журнал — `day_06_authorization_audit.md`.
- **Результат:** adversarial suite для BOLA/escalation/mass assignment/stale JWT, 401/403/404 audit, query/side-effect checks, valid OpenAPI и clean replay.
- **Порядок выполнения:** сформировать attack matrix; проверить alternate identifiers/filters/methods; проверить role revocation со старым JWT; сравнить denial contracts; проаудировать logs; проверить schema; mutation-test ключевые guards; запустить regressions/clean replay.
- **Наблюдаемый результат:** обходные запросы не читают/не меняют данные; удаление scope/role/service check ловится test; OpenAPI и runtime совпадают.
- **Готово, если:** horizontal/vertical attacks закрыты; stale claim не авторитетен; denial без side effect; statuses consistent; logs безопасны; schema valid; query budgets сохранены; regressions green; 16 сценариев записаны.
- **Пример:** старый JWT пользователя, переведённого из supplier operator в buyer, остаётся синтаксически valid, но catalog mutation получает deny по текущему database state.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–16. **Рекомендация:** сохранить compact route×role coverage report без tokens.

## Теория

Повторите разделы 6–7, 13, 20, 24, 30, 34 и 36–42 `THEORY.md`.

## Задание 1. Horizontal escalation attacks

- **Исходные данные:** actor A/B каждого domain role и foreign resource IDs.
- **Действие:** заменяйте path ID, nested organization ID, query filter, body relation и custom action ID.
- **Результат:** ни один путь не раскрывает/не меняет foreign resource.
- **Проверить:** list/detail/update/cancel/stats; UUID known/unknown; pagination count; response timing только грубо.

## Задание 2. Vertical escalation и mass assignment

- **Исходные данные:** buyer/operator/staff и privileged fields/actions.
- **Действие:** отправьте role/group/permissions/is_staff/is_superuser/balance/status/owner fields и вызовите admin routes напрямую.
- **Результат:** privilege state неизменен; error contract не раскрывает internals.
- **Проверить:** POST/PATCH; nested object; form/query equivalent; alternate field casing; bulk-like payload.

## Задание 3. Method/action bypass

- **Исходные данные:** router routes, custom actions и allowed methods.
- **Действие:** проверяйте GET/POST/PUT/PATCH/DELETE/OPTIONS и trailing-slash/alternate lookup combinations.
- **Результат:** permission не зависит от случайного method fallback; unsupported methods безопасно отклоняются.
- **Проверить:** custom action; partial update; direct detail; legacy route; format suffix, если включён.

## Задание 4. Stale JWT и mutable roles

- **Исходные данные:** valid access token, затем role/membership/active state меняется в database.
- **Действие:** повторите старым token разрешённый ранее request; сравните authentication и authorization decisions.
- **Результат:** token может идентифицировать user до expiry, но текущая database policy запрещает отозванное право.
- **Проверить:** role change; membership revoke; inactive; verified flag policy; permission grant/revoke; refreshed token.

## Задание 5. `401`/`403`/`404` audit

- **Исходные данные:** missing/invalid/expired token, wrong role, foreign object и missing object.
- **Действие:** сравните status, error envelope, headers и body keys; зафиксируйте rationale.
- **Результат:** contract consistent и не раскрывает private object existence.
- **Проверить:** `WWW-Authenticate`; foreign vs missing; staff vs anonymous; invalid signature; expired access.

## Задание 6. Side-effect и log audit

- **Исходные данные:** denied create/cancel/catalog/balance requests, application logs и audit events.
- **Действие:** сравните DB/ledger/stock/mail/cache before/after; ищите Authorization/JWT/private response fields и sensitive denial reasons.
- **Результат:** deny не создаёт business side effect; log хранит только безопасные IDs/event/decision.
- **Проверить:** service exception; transaction rollback; logging formatter; debug false; test failure output.

## Задание 7. OpenAPI authorization audit

- **Исходные данные:** generated schema и runtime matrix.
- **Действие:** для каждого path/method сравните security scheme, roles/scope description, request fields, statuses и response fields.
- **Результат:** schema не показывает server-owned privilege fields и не объявляет private route public.
- **Проверить:** public catalog; protected list/detail; custom cancel; admin balance; role stats; 401/403/404.

## Задание 8. Guard mutation, regressions и clean replay

- **Исходные данные:** ключевые role/scope/object/service checks, dependency lock и migrations.
- **Действие:** временно сломайте по одному guard и подтвердите падение test; восстановите; выполните full suite, schema validation и clean migration/setup.
- **Результат:** tests действительно ловят bypass, а не только фиксируют happy path.
- **Проверить:** remove role gate; replace scoped queryset with `.all()`; skip service policy; remove readonly field; clean DB; full regressions.

## Обязательные сценарии дня

1. Foreign path ID не раскрывает object.
2. Foreign query filter не расширяет list.
3. Foreign organization ID в body не меняет owner.
4. Buyer не назначает себе role/permission.
5. Staff не вызывает platform-admin action.
6. Unsupported method не обходит action map.
7. Custom action применяет scope и object policy.
8. Old JWT после role revoke получает deny.
9. Old JWT после membership revoke получает deny.
10. Inactive user со старым token не проходит protected action.
11. Missing/invalid/expired auth имеют зафиксированный contract.
12. Foreign/missing object responses не раскрывают existence.
13. Denied request не меняет DB/ledger/stock/mail.
14. Logs/schema не содержат JWT, Authorization и private fields.
15. Удаление каждого ключевого guard ломает test.
16. Full regressions, schema и clean replay green.

## Контрольные вопросы

1. Почему старый JWT может быть valid после role revoke?
2. Где берётся актуальное authorization decision?
3. Что кроме status проверяет negative test?
4. Как test доказал необходимость scope?
5. Когда foreign resource получает 404, а когда 403?
6. Что OpenAPI не способен доказать?

---

# День 7. Итоговый проект «Authorized Dealership API»

## Документация

- [DRF: Permissions](https://www.django-rest-framework.org/api-guide/permissions/) — общий справочник по view-level, object-level и QuerySet-ограничениям.
- [Django: permissions and authorization](https://docs.djangoproject.com/en/5.2/topics/auth/default/#permissions-and-authorization) — встроенная модель прав Django.
- [OWASP Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html) — финальный security checklist для системы прав.

## Паспорт проекта

- **Цель:** самостоятельно собрать, проверить и защитить полную authorization boundary поверх identity/DRF API.
- **Рабочий файл или каталог:** `day_07_authorized_api/`; документы — `README.md`, `PERMISSION_MATRIX.md`, `AUTHORIZATION_ADR.md`, `AUTHZ_THREAT_MODEL.md`, `OPENAPI_AUDIT.md`, `TEST_MATRIX.md`; итог — `ASSESSMENT.md`.
- **Результат:** fail-closed RBAC+ABAC/PBAC policies, scoped resources, service enforcement, защищённые Offers/organizations/balances/statistics, adversarial tests и актуальная OpenAPI.
- **Порядок выполнения:** перенести accepted baseline; собрать contract slice; RBAC; ownership scope; Offer services; organization policies; balance/stats boundaries; adversarial audit; schema; 48 scenarios; clean replay; защита.
- **Наблюдаемый результат:** четыре основные роли получают только разрешённые данные/действия; foreign/privileged attempts не дают side effects; новый разработчик воспроизводит доказательства по README.
- **Готово, если:** source/ADR/matrix согласованы; all routes covered; deny-default; role fields protected; list/detail/create/service layers корректны; old JWT uses current policy; performance сохранена; OpenAPI совпадает; regressions green; 48 actual scenarios; защита минимум 36/48.
- **Пример:** buyer создаёт и отменяет только свой pending Offer; supplier operator меняет только свой catalog; staff без capability не меняет balance; admin выполняет явный override с audit event.
- **Обязательно для зачёта:** артефакты, срезы 1–9, сценарии 1–48, clean replay и защита. **Рекомендация:** sequence diagram одного allow и одного deny flow.

## Целевое дерево

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
├── common/api/permissions.py
├── accounts/
│   ├── roles.py
│   ├── permissions.py
│   ├── policies.py
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
└── остальные принятые apps/tests недели 13/
```

## Обязанности файлов

| Файл/модуль | Обязанность |
|---|---|
| `PERMISSION_MATRIX.md` | canonical actor/action/resource/scope/status table |
| `AUTHORIZATION_ADR.md` | role source, admin semantics, 401/403/404 и alternatives |
| `AUTHZ_THREAT_MODEL.md` | assets, attackers, abuse paths, controls и tests |
| `OPENAPI_AUDIT.md` | runtime↔schema security comparison |
| `TEST_MATRIX.md` | predictions, actual results и evidence 48 сценариев |
| `roles.py` | canonical role constants/helpers без HTTP |
| `permissions.py` | DRF request/object gates и capability adapters |
| `selectors.py` | fail-closed visibility scopes и efficient reads |
| `policies.py` | context-aware decisions по actor/resource/state |
| `services.py` | authoritative policy check и atomic mutation |

## Рекомендуемый порядок сборки по вертикальным срезам

### Срез 1. Baseline и authorization contract

- **Исходные данные:** accepted week 13 project и все routes/models.
- **Действие:** зафиксировать source/database/tests, ADR, permission matrix, threat model и route inventory.
- **Результат:** implementation начинается только после согласованного contract.
- **Проверить:** dirty source; unknown endpoints; duplicate role source; matrix gaps.

### Срез 2. Canonical RBAC

- **Исходные данные:** actors и capabilities.
- **Действие:** реализовать role helpers, custom permissions/provisioning при необходимости и fail-closed action gates.
- **Результат:** роль разрешает только coarse actions; privilege fields закрыты.
- **Проверить:** each role; unknown; staff; admin; superuser; revoked role.

### Срез 3. Buyer Offer/Purchase boundary

- **Исходные данные:** two buyers, own/foreign offers/purchases.
- **Действие:** scope list/detail, server-owned create и atomic cancel policy.
- **Результат:** buyer работает только со своими данными и pending transition.
- **Проверить:** own/foreign/missing; state; body owner; direct service; concurrency.

### Срез 4. Dealership boundary

- **Исходные данные:** operators и resources двух dealerships.
- **Действие:** scope preferences/inventory/statistics по membership; закрыть balance/history writes.
- **Результат:** dealership operator ограничен своим салоном.
- **Проверить:** path/filter/body foreign IDs; missing membership; inactive org; admin.

### Срез 5. Supplier/promotion boundary

- **Исходные данные:** operators, catalog и promotions двух suppliers.
- **Действие:** разрешить только own create/update/deactivate и допустимые promotion actions.
- **Результат:** supplier relation server-owned, чужие resources недоступны.
- **Проверить:** foreign; reassign; expired; delete/history; admin.

### Срез 6. Balance и history

- **Исходные данные:** balance/stock movements и admin capability.
- **Действие:** убрать generic mutation; сделать узкий admin adjustment только при наличии contract.
- **Результат:** ledger сохраняет причину; отрицательные balances/stock запрещены прежними invariants.
- **Проверить:** buyer/operator/staff/admin; missing reason; rollback; concurrency.

### Срез 7. Role-specific statistics

- **Исходные данные:** mixed domain dataset.
- **Действие:** применить scope до aggregate и role-specific serializer.
- **Результат:** buyer/org/admin получают только разрешённые показатели.
- **Проверить:** own/foreign; empty; filters; pagination if present; private fields; query budget.

### Срез 8. Adversarial и OpenAPI audit

- **Исходные данные:** complete runtime surface и attack matrix.
- **Действие:** проверить horizontal/vertical escalation, BOLA, mass assignment, stale JWT, methods, logs и schema.
- **Результат:** каждый guard имеет negative test; schema совпадает с runtime.
- **Проверить:** known/missing ID; alternate routes; old token; no side effects; safe logs.

### Срез 9. Clean replay и защита

- **Исходные данные:** clean environment, dependency lock, migrations, docs и 48 scenarios.
- **Действие:** выполнить setup from README, migrations, checks, full tests, schema validation и устную защиту.
- **Результат:** другой разработчик воспроизводит систему без secret/manual hidden step.
- **Проверить:** empty database; idempotent provisioning; deterministic data; no real service; regressions.

## Обязательные позитивные сценарии

1. Anonymous читает public catalog list.
2. Anonymous читает public catalog detail.
3. Active verified buyer создаёт свой Offer.
4. Buyer читает список своих Offers.
5. Buyer читает свой Offer detail.
6. Buyer отменяет свой pending Offer.
7. Buyer читает свои Purchases.
8. Buyer читает собственную статистику.
9. Dealership operator читает собственный inventory.
10. Dealership operator меняет разрешённую preference своего салона.
11. Dealership operator читает статистику своего салона.
12. Supplier operator читает свой catalog.
13. Supplier operator создаёт item своего supplier.
14. Supplier operator меняет разрешённые поля своего item.
15. Supplier operator деактивирует свой item по contract.
16. Supplier operator управляет собственной promotion по matrix.
17. Supplier operator читает статистику своего supplier.
18. Platform admin читает global statistics.
19. Platform admin выполняет явное balance adjustment с reason.
20. Superuser override соответствует ADR и проверен отдельно.

## Обязательные граничные сценарии

21. Buyer с пустым списком получает empty result без чужих rows.
22. User без требуемого profile получает safe deny/empty по contract.
23. Operator без organization membership получает safe deny/empty.
24. Inactive organization запрещает mutation по policy.
25. Own Offer уже processing/completed/rejected/cancelled не отменяется.
26. Повторный cancel не создаёт второй transition.
27. Foreign и missing identifier имеют выбранный безопасный public contract.
28. Page за пределами own scope не раскрывает global count.
29. Filter по foreign owner/organization не расширяет scope.
30. Unknown role/action получает deny.
31. Staff без capability не считается platform admin.
32. Отозванная role перестаёт действовать со старым access JWT.
33. Отозванная organization membership перестаёт действовать со старым access JWT.
34. Permission grant/revoke test использует fresh user instance.

## Обязательные ошибочные и abuse-сценарии

35. Anonymous не читает protected Offer/Purchase/statistics endpoint.
36. Buyer A не читает Offer buyer B.
37. Buyer A не читает Purchase buyer B.
38. Buyer не подменяет `buyer_id` при create.
39. Buyer не меняет role/group/is_staff/is_superuser.
40. Buyer/operator не меняют balance напрямую.
41. Dealership A не читает/меняет resources dealership B.
42. Supplier A не читает/меняет resources supplier B.
43. Supplier не переназначает item/promotion другой organization.
44. Unsupported method/legacy route не обходит action map.
45. Direct service call wrong actor получает deny без mutation.
46. Concurrent Offer transition завершается одним допустимым state.
47. Denial не создаёт DB/ledger/stock/email side effect и не логирует secret/private body.
48. OpenAPI не раскрывает privilege fields и совпадает с runtime statuses/security.

## Ограничения на ещё не изученные инструменты

- Не устанавливать `django-guardian`, OPA, Casbin или access-policy package.
- Не внедрять PostgreSQL RLS.
- Не создавать Redis authorization cache.
- Не делать production IAM/SSO/OAuth/OIDC.
- Не строить frontend role guards как security control.
- Не добавлять Celery только ради permission propagation.
- Не реализовывать собственную cryptographic authorization scheme.
- Не менять JWT algorithm/keys без отдельной задачи недели 13.

## Финальный чек-лист сдачи

- [ ] Допуск недели 13 и source commit записаны.
- [ ] Database/test target безопасны.
- [ ] Baseline до изменений сохранён.
- [ ] `PERMISSION_MATRIX.md` покрывает каждый route/action.
- [ ] `AUTHORIZATION_ADR.md` определяет один role source.
- [ ] `AUTHZ_THREAT_MODEL.md` связывает threats с controls/tests.
- [ ] Global default fail closed.
- [ ] Public exceptions явны и read-only.
- [ ] Role/group/permission/owner/org/balance/status fields защищены.
- [ ] List/detail/create/custom action используют правильные слои.
- [ ] Services получают actor и повторяют authoritative policy.
- [ ] Own/organization/global statistics scoped до aggregate.
- [ ] Staff/platform admin/superuser различены.
- [ ] Old JWT использует актуальную database role/membership policy.
- [ ] 401/403/404 contract согласован.
- [ ] Denials не создают side effects.
- [ ] Permission queries не создают N+1.
- [ ] OpenAPI совпадает с runtime.
- [ ] Все 48 scenarios имеют actual evidence.
- [ ] Полный regression suite green.
- [ ] Clean migrations/setup воспроизводимы.
- [ ] В Git/log/schema нет secrets и private test data.
- [ ] Самооценка заполнена.

## Вопросы для защиты решения

Ответьте на все 48 вопросов из `THEORY.md`. Обязательные: 1, 2, 3, 6, 7, 9, 12, 13, 18, 19, 20, 21, 22, 23, 24, 27, 28, 30, 31, 32, 34, 35, 37, 38, 39, 41, 43, 44, 46 и 48.

Дополнительно на живой защите наставник выбирает два изменения условия:

- новая роль без правил;
- operator получает вторую organization membership;
- Offer получает новый terminal status;
- platform admin теряет одну capability;
- route получает новый custom action;
- role меняется после выдачи access token.

Ученик должен показать, какие matrix rows, policies, selectors, tests и OpenAPI sections изменятся, не переписывая проект на месте вслепую.
