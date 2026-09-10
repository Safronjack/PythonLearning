# ADR: authorization architecture

Статус: template; decision заполняется в день 1.

## Контекст

Опишите существующие `User.role`, groups, permissions, organization profiles/memberships, admin flags и JWT claims после недели 13.

## Решение

- Canonical role source:
- Capability source:
- Organization membership source:
- View-level enforcement:
- Visibility/queryset enforcement:
- Object enforcement:
- Service-level enforcement:
- Admin override:
- Superuser behavior:
- 401/403/404 policy:
- Stale JWT policy:
- Role assignment/revocation owner:

## Рассмотренные альтернативы

### Вариант A

- Описание:
- Плюсы:
- Минусы:
- Причина отказа/выбора:

### Вариант B

- Описание:
- Плюсы:
- Минусы:
- Причина отказа/выбора:

## Migration и compatibility

- Необходимые schema/data migrations:
- Drift handling:
- Idempotent provisioning:
- Rollback:
- Existing users:
- Permission cache:
- Old JWT:

## Инварианты

- Неизвестная роль получает deny.
- Client не назначает privilege/ownership fields.
- List scope применяется до filter/order/pagination/aggregate.
- Critical mutation повторяет policy внутри service/transaction.
- Staff не равен platform admin.
- Изменяемый JWT claim не является authoritative.

## Последствия и остаточные риски

- Положительные:
- Отрицательные:
- Не решено на этой неделе:
- Когда решение нужно пересмотреть:

