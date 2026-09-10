# Теория недели 14: авторизация, роли и права на объекты

Статус: **читать после допуска из недели 13**.

Неделя 13 ответила на вопрос «кто делает запрос?». Неделя 14 отвечает на следующий вопрос: «что именно этому actor разрешено сделать с этим ресурсом прямо сейчас?»

## 1. Authentication и authorization

**Authentication** подтверждает identity пользователя. Например, валидный access JWT позволяет DRF получить `request.user`.

**Authorization** принимает решение о действии:

```text
authenticated user + POST /offers/ != автоматическое право создать Offer
```

Нужно дополнительно проверить роль, active/verified state, владение профилем и условия use case.

## 2. Модель subject–action–resource–context

Любое правило удобно разбирать на четыре части:

- **subject** — actor: buyer, supplier operator, admin;
- **action** — действие: list, retrieve, create, cancel;
- **resource** — объект или тип объектов: Offer, Promotion, Balance;
- **context** — состояние и отношения: owner, organization membership, status, время.

Пример:

```text
subject: buyer #17
action: cancel
resource: offer #42, buyer_id=17
context: offer.status == pending
decision: allow
```

Если тот же Offer принадлежит buyer #18 или уже `completed`, решение становится deny.

## 3. Deny by default

Без явно подходящего разрешающего правила доступ запрещён. Это важнее длинного списка `if`:

```python
def can_cancel_offer(*, actor, offer) -> bool:
    if not actor.is_authenticated:
        return False
    if actor.role != UserRole.BUYER:
        return False
    if offer.buyer.user_id != actor.id:
        return False
    return offer.status == OfferStatus.PENDING
```

Функция начинает с отказов и разрешает только доказанный случай.

## 4. Least privilege

Роль получает минимальные права, необходимые для работы. Сотруднику поставщика не нужен доступ к балансам покупателей только потому, что он «сотрудник».

Полезный вопрос для каждой клетки матрицы: «Какую конкретную рабочую задачу невозможно выполнить без этого права?» Если ответа нет, право не выдаётся.

## 5. Почему интерфейс не защищает API

Скрытая кнопка, disabled input и route guard во frontend улучшают UX, но клиент может отправить HTTP-запрос вручную. Решение всегда принимает backend на каждом запросе.

## 6. Горизонтальное и вертикальное повышение прав

**Горизонтальное** — пользователь получает данные другого пользователя того же уровня:

```text
buyer #17 меняет /offers/42/, принадлежащий buyer #18
```

**Вертикальное** — пользователь получает действие более привилегированной роли:

```text
buyer отправляет PATCH /users/17/ {"role": "platform_admin"}
```

Оба типа должны иметь отрицательные tests.

## 7. IDOR и BOLA

IDOR/BOLA возникает, когда сервер получает identifier объекта, находит объект и не проверяет право actor на него. UUID не решает проблему: сложный ID труднее угадать, но leaked URL всё равно даст доступ.

Защита начинается со scope:

```python
Offer.objects.filter(buyer__user=request.user)
```

Detail lookup выполняется внутри этого QuerySet, а не во всей таблице.

## 8. RBAC

**Role-Based Access Control** связывает permissions с ролями, а пользователей — с ролями.

```text
buyer role -> create_own_offer, view_own_purchase
supplier_operator role -> change_own_catalog, manage_own_promotion
platform_admin role -> manage_balance, view_all_statistics
```

RBAC удобен для грубого разделения обязанностей, но слово `own` уже требует отношения к объекту — одного role check недостаточно.

## 9. Django permissions

Django создаёт стандартные model permissions:

- `add_model`;
- `change_model`;
- `delete_model`;
- `view_model`.

Проверка выглядит так:

```python
user.has_perm("promotions.change_promotion")
```

Можно добавить custom permission в `Meta.permissions`, например `manage_balances`. Permission codename обозначает capability, а не случайное имя endpoint.

## 10. Django groups

`Group` объединяет набор permissions. Пользователь наследует permissions всех своих groups.

Group может представлять роль, но нельзя одновременно считать независимый `User.role` и group двумя равноправными источниками. Иначе один слой увидит buyer, другой — supplier operator.

## 11. Один источник истины

Перед кодом выбирается source of truth:

- domain enum в `User.role`;
- Django group membership;
- отдельная membership model для сложной организационной роли.

Если старый проект уже использует `User.role`, не нужно молча добавлять group с тем же смыслом. Сначала требуется ADR и migration/synchronization decision.

## 12. `is_staff`, `is_superuser` и business role

- `is_staff` обычно разрешает вход в Django admin;
- `is_superuser` позволяет проходить Django permission checks без обычного назначения permissions;
- business role описывает работу пользователя в продукте.

`is_staff=True` не означает «может управлять балансами». Для обычного platform admin лучше явная роль/capability. Superuser проверяется отдельно как аварийный полный доступ.

## 13. Permission cache Django

После первого `has_perm()` Django может кешировать permissions на экземпляре user. Если test сначала проверил отказ, затем добавил permission и снова использовал тот же объект, результат может остаться старым.

Для честной проверки после изменения permissions получите новый экземпляр пользователя из database. `refresh_from_db()` сам по себе не всегда очищает внутренний permission cache.

## 14. Custom permissions

Custom permissions создаются для действий, не совпадающих с CRUD:

```python
class Meta:
    permissions = [
        ("manage_balances", "Can manage account balances"),
    ]
```

Изменение `Meta.permissions` требует migration/post-migrate behavior и воспроизводимого назначения роли. Не создавайте permissions вручную при каждом request.

## 15. RBAC не описывает всё

Правило «buyer может отменить Offer» слишком широкое. Нужны дополнительные attributes:

- Offer принадлежит actor;
- Offer имеет статус `pending`;
- actor active и verified;
- операция ещё допустима по времени/состоянию.

Так появляется ABAC.

## 16. ABAC

**Attribute-Based Access Control** принимает решение по атрибутам subject, resource и context.

```python
def can_cancel_offer(*, actor, offer) -> bool:
    return (
        actor.is_active
        and actor.is_email_verified
        and actor.role == UserRole.BUYER
        and offer.buyer.user_id == actor.id
        and offer.status == OfferStatus.PENDING
    )
```

Функция должна быть понятной и тестируемой. Если для решения нужен QuerySet, лучше передать уже загруженную relation или поместить запрос в selector/service.

## 17. PBAC

**Policy-Based Access Control** означает, что правила оформлены как явные policies, а не разбросаны по views, serializers и signals.

На этой неделе PBAC — архитектурный подход, а не внешний engine. Обычная Python-функция или небольшой policy object достаточны, если:

- входы явные;
- решение deterministic для заданных входов;
- правило покрыто tests;
- причина deny не раскрывает private details клиенту;
- service использует policy перед mutation.

## 18. View-level permission в DRF

`has_permission()` отвечает, может ли actor обращаться к action/view вообще:

```python
class IsBuyer(BasePermission):
    def has_permission(self, request, view):
        return (
            request.user.is_authenticated
            and request.user.role == UserRole.BUYER
        )
```

Это подходящий слой для «только buyer может вызвать create Offer». Он ещё не знает конкретный Offer.

## 19. Object-level permission в DRF

`has_object_permission()` работает с уже найденным объектом:

```python
class IsOfferOwner(BasePermission):
    def has_object_permission(self, request, view, obj):
        return obj.buyer.user_id == request.user.id
```

Generic views вызывают object check при `get_object()`. В custom `get_object()` необходимо явно вызвать `check_object_permissions()`.

## 20. Ограничения object permissions

DRF не запускает `has_object_permission()` для каждой строки list endpoint: это было бы дорого и неудобно для pagination. List обязан получить уже scoped QuerySet.

Object permission также не проверяет ещё не созданный object при create. Право create проверяется view-level policy, а server-owned owner назначается внутри orchestration/service.

## 21. QuerySet как граница видимости

Для buyer:

```python
def offers_visible_to(*, actor):
    if actor.is_superuser:
        return Offer.objects.all()
    if actor.role == UserRole.BUYER:
        return Offer.objects.filter(buyer__user=actor)
    return Offer.objects.none()
```

`.none()` — безопасный default. Такой selector используется list и detail lookup. Он должен сохранять ordering/prefetch/query-budget contract.

## 22. Фильтрация выполняется до pagination

Нельзя взять общую страницу объектов и затем убрать чужие строки в Python. Это даёт неполные страницы, неверный count и риск утечки через metadata.

Правильный порядок:

```text
authorization scope -> allowed filters -> deterministic ordering -> pagination -> serialization
```

## 23. Безопасный detail lookup

Вместо:

```python
Offer.objects.get(pk=offer_id)
```

используется lookup в scoped QuerySet. Тогда чужой и несуществующий identifier могут иметь одинаковый `404` contract без предварительного раскрытия объекта.

Object permission остаётся дополнительной защитой, особенно для разных actions над видимым объектом.

## 24. `401`, `403` и `404`

- `401` — request не прошёл authentication;
- `403` — actor известен, но action запрещён;
- `404` — object отсутствует в разрешённом visibility scope.

Конкретный `401`/`403` также зависит от authentication class и `WWW-Authenticate`. Tests должны фиксировать фактический contract.

## 25. Create и server-owned fields

Клиент buyer не выбирает `buyer_id`:

```python
offer = create_offer(
    actor=request.user,
    car_model=serializer.validated_data["car_model"],
    maximum_price=serializer.validated_data["maximum_price"],
)
```

Если request содержит `buyer`, поле должно быть неизвестным/readonly по contract. Игнорировать опасное поле молча менее понятно, чем явно запретить его.

## 26. Mass assignment

`fields = "__all__"` или слепой `Model.objects.create(**request.data)` позволяют клиенту попытаться записать:

- owner;
- role;
- `is_staff`/`is_superuser`;
- organization;
- balance;
- status;
- audit timestamps.

Используйте явные serializer fields и server-owned assignment.

## 27. Update и смена владельца

Даже если пользователь владеет объектом, это не значит, что он может менять все fields. Для Offer buyer может иметь отдельное действие `cancel`, но не generic PATCH для `buyer`, `status=completed` или `sale_id`.

Чем чувствительнее state machine, тем полезнее узкие commands/actions вместо широкого CRUD.

## 28. Custom ViewSet actions

Для `cancel` можно использовать `@action(detail=True, methods=["post"])`. Но custom action обязан иметь:

- view-level permission;
- scoped `get_object()`;
- object/policy check;
- service-level state transition;
- явный serializer/response/error contract;
- OpenAPI и negative tests.

Наличие декоратора не добавляет безопасность автоматически.

## 29. Service-level authorization

View нельзя считать единственным входом в business operation. Тот же service позже вызовет Celery task, management command или admin action.

```python
@transaction.atomic
def cancel_offer(*, actor, offer_id):
    offer = Offer.objects.select_for_update().select_related("buyer__user").get(
        pk=offer_id
    )
    if not can_cancel_offer(actor=actor, offer=offer):
        raise AuthorizationDenied
    offer.cancel()
    offer.save(update_fields=("status", "updated_at"))
    return offer
```

Service получает actor явно и повторяет authoritative policy после загрузки/lock.

## 30. TOCTOU и изменяемое состояние

TOCTOU — состояние изменилось между check и use. Например, view увидел `pending`, а параллельный worker завершил Offer до service mutation.

Критическая state-based policy проверяется внутри transaction после `select_for_update()`. Старое решение, принятое до lock, недостаточно.

## 31. Organization membership

URL `/suppliers/9/promotions/` не доказывает, что actor связан с supplier #9. Membership берётся из database relation:

```text
actor -> supplier membership -> supplier resource
```

Если один operator может работать с несколькими организациями, нужна явная membership model. Если только с одной — это всё равно database relation, а не доверенный request parameter.

## 32. Административный override

Администратор не должен появляться как `or actor.is_staff` в десятках мест. Override оформляется единообразно:

- конкретная platform role/capability;
- список разрешённых actions;
- audit event для чувствительной mutation;
- tests обычного admin, staff без capability и superuser отдельно.

Superuser happy path не доказывает правильность обычной модели ролей.

## 33. Управление ролями

Public registration/profile update не принимает role/group/permission fields. Назначение роли — отдельный trusted use case:

- authenticated privileged actor;
- явная target user и новая роль;
- запрет self-escalation;
- допустимые transitions;
- audit reason;
- session/JWT последствия;
- tests старых и новых прав.

Сам UI управления ролями не обязателен на неделе 14.

## 34. Устаревшие JWT claims

JWT access token может жить после смены роли. Если role записана в claim и backend полностью доверяет ей, отозванное право сохранится до expiry.

Без отдельной token-version/session инфраструктуры безопасный учебный вариант:

- JWT содержит stable user ID;
- authentication загружает актуального user;
- authorization читает текущую role/membership из database;
- claim роли, если он есть для UI, не является authoritative.

## 35. Active и verified остаются policy inputs

Role не отменяет требования недели 13. Заблокированный platform admin или unverified buyer не должен проходить protected business flow вопреки contract.

Лучше иметь общий precondition, но не создавать класс с названием вроде `IsAuthenticatedActiveVerifiedAndCorrectRoleAndOwnerAndPending`: сложное state rule читается лучше как domain policy.

## 36. Field-level confidentiality

Право видеть объект не всегда означает право видеть все поля. Публичный supplier catalog может содержать sale-facing данные, но не внутреннюю закупочную стоимость, баланс или служебные причины выбора.

Используйте разные serializers/selectors для public, owner и admin representations. Не возвращайте model `__dict__`.

## 37. Statistics scope

Агрегат тоже может утечь. Даже если response не содержит rows, глобальная сумма или count раскрывает чужой бизнес.

Scope применяется к исходному QuerySet до `aggregate()`/`annotate()`. Нельзя сначала посчитать глобальный показатель и затем подписать его именем текущего пользователя.

## 38. Permission performance

Проверка membership внутри цикла serializers создаёт N+1. Загружайте необходимые relations заранее или стройте scoped QuerySet одним запросом.

Измеряйте count для N=2 и N=20. Авторизация не должна делать число запросов линейным без причины.

## 39. Ошибки и внешнее сообщение

Внутренняя policy может знать `wrong_owner`, `wrong_role` или `invalid_state`. Клиенту не всегда безопасно раскрывать точную причину.

Лог может содержать:

- event/action;
- actor internal ID;
- resource type и безопасный internal ID;
- decision category;
- request ID.

Не логируйте JWT, Authorization header, private fields или полный request body.

## 40. OpenAPI и authorization

Для каждого endpoint документация фиксирует:

- security scheme;
- разрешённые actor roles;
- ownership/organization scope простыми словами;
- доступные actions и methods;
- `401`, `403`, `404` и validation errors;
- отсутствующие server-owned fields во входной schema;
- role-specific response fields, если contracts различаются.

OpenAPI не заменяет runtime tests.

## 41. Как тестировать матрицу

Минимальный data set:

- anonymous;
- unverified buyer;
- active buyer A и buyer B;
- dealership operator A и B;
- supplier operator A и B;
- staff без business permission;
- platform admin;
- superuser отдельно;
- own/foreign resources в нескольких states.

Для каждой значимой клетки проверяются status, response shape, QuerySet visibility, database before/after и side effects.

## 42. Типичные ошибки

- global `AllowAny` и забытая override policy;
- `if request.user.is_authenticated` вместо authorization;
- `is_staff` как универсальный admin;
- доверие `buyer_id`/`supplier_id` из body;
- list защищён только object permission;
- create «защищён» `has_object_permission()`;
- общий QuerySet загружает чужой object до проверки;
- owner может изменить owner/status/balance через PATCH;
- service не принимает actor;
- role только в JWT claim;
- permission cache делает test ложно красным/зелёным;
- admin/superuser — единственный test actor;
- пустой scope случайно переключается на `.all()`;
- aggregate строится до scope;
- unauthorized request успевает создать row/send email;
- OpenAPI обещает несуществующий role restriction.

## 43. Вопросы для самопроверки

1. Чем authentication отличается от authorization?
2. Что такое subject, action, resource и context?
3. Что означает deny by default?
4. Как least privilege влияет на permission matrix?
5. Почему скрытая кнопка не защищает API?
6. Чем horizontal escalation отличается от vertical?
7. Почему UUID не устраняет BOLA?
8. Что хорошо описывает RBAC?
9. Почему `own resource` не выражается только role check?
10. Какие default permissions создаёт Django?
11. Для чего нужен Group?
12. Почему два независимых источника роли опасны?
13. Чем `is_staff` отличается от platform-admin role?
14. Что делает `is_superuser`?
15. Почему после назначения permission в test иногда нужен новый user instance?
16. Когда нужен custom model permission?
17. Что добавляет ABAC?
18. Что PBAC означает в рамках этой недели?
19. Что проверяет `has_permission()`?
20. Что проверяет `has_object_permission()`?
21. Почему object permission не фильтрует list?
22. Почему object permission не защищает create автоматически?
23. Зачем нужен scoped QuerySet?
24. Почему scope применяется до pagination?
25. Когда чужой object возвращает 404?
26. Когда ожидается 403?
27. Почему owner нельзя принимать из request body?
28. Что такое mass assignment?
29. Почему owner не обязан иметь право на любой PATCH?
30. Какие слои нужны custom action `cancel`?
31. Почему service снова проверяет authorization?
32. Что такое TOCTOU?
33. Где повторно проверить status перед mutation?
34. Почему organization ID в URL не доказывает membership?
35. Как оформить admin override?
36. Почему public API не меняет role?
37. Что произойдёт со старым access token после role change?
38. Почему role claim нельзя считать authoritative?
39. Где применить scope для статистики?
40. Как field-level confidentiality связана с serializers?
41. Как обнаружить N+1 в permission checks?
42. Какие данные допустимы в denial log?
43. Что OpenAPI должен сказать об authorization?
44. Почему OpenAPI не доказывает enforcement?
45. Какие actors нужны в test dataset?
46. Что проверить кроме HTTP status у запрещённого запроса?
47. Почему `.none()` является полезным default?
48. Как доказать, что новое действие не открылось неизвестной роли?

## Официальные источники

- [Django: permissions and authorization](https://docs.djangoproject.com/en/5.2/topics/auth/default/#permissions-and-authorization)
- [Django: custom permissions](https://docs.djangoproject.com/en/5.2/topics/auth/customizing/#custom-permissions)
- [Django authentication reference](https://docs.djangoproject.com/en/5.2/ref/contrib/auth/)
- [Django: database transactions](https://docs.djangoproject.com/en/5.2/topics/db/transactions/)
- [DRF: permissions](https://www.django-rest-framework.org/api-guide/permissions/)
- [DRF: filtering](https://www.django-rest-framework.org/api-guide/filtering/)
- [DRF: viewsets](https://www.django-rest-framework.org/api-guide/viewsets/)
- [DRF: testing](https://www.django-rest-framework.org/api-guide/testing/)
- [OWASP Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html)
- [OWASP API Security: Broken Object Level Authorization](https://owasp.org/API-Security/editions/2023/en/0xa1-broken-object-level-authorization/)
