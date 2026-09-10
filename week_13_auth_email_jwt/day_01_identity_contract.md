# День 1: identity contract и action tokens

Статус: **заблокировано до зачёта недели 12**.

## Активация и baseline

- Дата:
- Допуск недели 12:
- Source branch/commit:
- Current branch/commit:
- Database purpose без secrets:

| Проверка | Команда | Exit | Длительность | Результат |
|---|---|---:|---:|---|
| Django checks | | | | |
| Migration drift/plan | | | | |
| Week 11–12 tests | | | | |

## Compatibility gate

| Package | Current | Candidate | Official support evidence | Risk | Decision |
|---|---|---|---|---|---|
| Python | | | | | |
| Django | | | | | |
| DRF | | | | | |
| SimpleJWT | | | | | |

## User audit

| Field | Meaning | Mutable | Unique | Normalized by | Public | JWT claim |
|---|---|---|---|---|---|---|
| | | | | | | |

## State transitions

| Initial state | Actor/proof | Action | New state | Tokens/email | Failure state |
|---|---|---|---|---|---|
| | | | | | |

## Predictions

1. Может ли raw token находиться в model field?
2. Что произойдёт при `expires_at == now`?
3. Можно ли verify token передать reset endpoint?
4. Что будет при двух одновременных consumption без lock?
5. Почему user public ID и token secret разделены?

## Сценарии 1–10

Используйте security-формат `PRACTICE.md`. Не записывайте actual token values.

## Самооценка

- Что сделал самостоятельно:
- Что теперь могу объяснить:
- Ошибка дня и причина:
- Непонятные места:
- Вопросы наставнику:
- Время:

