# OpenAPI authorization audit

Статус: template; actual comparison выполняется после runtime implementation.

## Правила

- Использовать только fake placeholders.
- Сравнивать generated schema с реальными requests/tests.
- Не описывать роль или scope, которых runtime не обеспечивает.
- Privilege/server-owned fields не должны быть writable в public schema.

## Audit table

| Path/method | Runtime action | Auth scheme | Allowed roles/scope documented | Request fields | Response fields | 401 | 403 | 404 | Other statuses | Match/gap |
|---|---|---|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | — | — | — | — |

## Public exceptions

| Path/method | Почему public | Почему read-only | Runtime test | Schema match |
|---|---|---|---|---|
| — | — | — | — | — |

## Server-owned field audit

| Schema/component | Forbidden writable field | Present? | Runtime behavior | Fix/result |
|---|---|---|---|---|
| — | role/owner/organization/... | — | — | — |

## Validation result

- Command/tool:
- Exit/result:
- Warnings:
- Каждое предупреждение разобрано:
- Финальный status:

