# Dealership Test Foundation

Статус: заготовка итогового проекта недели 15. Код переносится только после допуска недели 14.

Этот файл заполняет ученик. Не сохраняйте реальные passwords, JWT/action tokens, email пользователей, DSN и private responses.

## Source и версии

- Source week 14 branch/commit:
- Python:
- Django:
- DRF/SimpleJWT:
- PostgreSQL:
- pytest:
- pytest-django:
- coverage:
- Dependency lock:

## Safe test environment

- Django settings module:
- Database vendor/purpose:
- Cache backend/isolation:
- Email backend/isolation:
- Network policy:
- Temp filesystem:
- Secret placeholders:

## Быстрый запуск

Запишите точные команды из project root:

```text
Clean dependency install:
Collection only:
One node ID:
Unit:
Integration:
API:
Smoke:
Regression/full:
Coverage line+branch:
Django checks/migrations/schema:
```

Для каждой команды укажите expected non-zero/zero-tests behavior и пример summary без secrets.

## Test levels

| Level/marker | Проверяемый risk | Real dependencies | Doubles | Typical duration/count |
|---|---|---|---|---|
| Unit | — | — | — | — |
| Integration | — | — | — | — |
| API | — | — | — | — |
| Smoke | — | — | — | — |

## Структура tests

Опишите обязанности `conftest.py`, factories и каждого каталога. Укажите, где остаются legacy Django/unittest tests и почему.

## Fixture/factory principles

- Default scope:
- Root vs domain conftest:
- Server-owned/privilege defaults:
- Deterministic time/random/data:
- Cleanup strategy:
- Order-isolation evidence:

## Mock policy

- Разрешённые external boundaries:
- Запрещённые mock targets:
- Patch-where-looked-up rule:
- Spec/autospec policy:
- Paired integration proofs:

## Coverage interpretation

- Full line coverage context:
- Full branch coverage context:
- Critical modules reviewed:
- Closed gaps:
- Intentional exclusions with reasons:
- Deferred week 16 risks:

## Итоговые проверки

```text
Collection:
Unit:
Integration:
API:
Smoke:
Full suite:
Coverage:
Schema:
Clean replay:
```

## Известные ограничения

Запишите фактические ограничения недели 15 и будущие проверки недели 16.

## Связанные документы

- [TEST_STRATEGY.md](TEST_STRATEGY.md)
- [TEST_INVENTORY.md](TEST_INVENTORY.md)
- [FIXTURE_MAP.md](FIXTURE_MAP.md)
- [MOCK_AUDIT.md](MOCK_AUDIT.md)
- [COVERAGE_AUDIT.md](COVERAGE_AUDIT.md)
- [TEST_MATRIX.md](TEST_MATRIX.md)

