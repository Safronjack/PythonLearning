# Authorized Dealership API

Статус: заготовка итогового проекта недели 14. Код переносится только после допуска недели 13.

Этот файл заполняет ученик. Не вставляйте реальные JWT, пароли, email пользователей, DSN и другие secrets.

## Source и окружение

- Source week 13 branch/commit:
- Python:
- Django:
- DRF:
- SimpleJWT:
- PostgreSQL:
- Database purpose:
- Dependency lock:

## Назначение

Кратко опишите actors, защищённые resources и главные authorization invariants.

## Быстрый запуск

Запишите воспроизводимые шаги:

1. безопасная настройка environment через placeholders;
2. создание isolated PostgreSQL database;
3. установка exact dependencies;
4. migrations;
5. idempotent role/permission provisioning;
6. test data без private значений;
7. Django checks;
8. tests;
9. schema validation;
10. local server.

## Архитектурный поток решения

```text
authentication
  -> request/action permission
  -> scoped queryset/selector
  -> object policy
  -> service policy inside transaction
  -> mutation
  -> safe response/audit event
```

Для каждого слоя укажите реальный модуль проекта.

## Роли и source of truth

- Canonical role source:
- Почему выбран:
- Как роль назначается/отзывается:
- Что означают staff/platform admin/superuser:
- Как решён existing role/group drift:
- Как старый JWT получает актуальную policy:

## API surface

| Path/method | Resource/action | Allowed actor/scope | Response | Denials |
|---|---|---|---|---|
| — | — | — | — | — |

## Server-owned fields

Перечислите role, owner, organization, status, balance и другие поля, которые клиент не может назначить напрямую.

## Query/performance evidence

| Endpoint/actor | N=2 queries | N=20 queries | Budget | Optimization |
|---|---:|---:|---:|---|
| — | — | — | — | — |

## Security evidence

- Horizontal escalation:
- Vertical escalation:
- BOLA/guessed IDs:
- Mass assignment:
- Stale JWT role/membership:
- Denial side effects:
- Secret/log scan:
- OpenAPI match:

## Проверки

```text
Django checks:
Migration drift:
Tests:
Schema validation:
Clean replay:
```

## Известные ограничения

Укажите реальные ограничения, не называя их «безопасными по умолчанию».

## Связанные документы

- [PERMISSION_MATRIX.md](PERMISSION_MATRIX.md)
- [AUTHORIZATION_ADR.md](AUTHORIZATION_ADR.md)
- [AUTHZ_THREAT_MODEL.md](AUTHZ_THREAT_MODEL.md)
- [OPENAPI_AUDIT.md](OPENAPI_AUDIT.md)
- [TEST_MATRIX.md](TEST_MATRIX.md)

