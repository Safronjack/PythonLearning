# Матрица итоговой проверки: неделя 12

Статус: **заполняется фактическими результатами, не ожиданиями**.

Для каждой строки укажите test name/manual command, status, ключевой response/database effect и evidence. Полное описание сценариев находится в `../PRACTICE.md`, день 7.

| ID | Сценарий | Test/command | Expected | Actual | DB/query evidence | Статус |
|---:|---|---|---|---|---|---|
| 1 | Clean install/import/checks | | | | | Не проверено |
| 2 | Week 11 regression | | | | | Не проверено |
| 3 | Health/schema/docs routes | | | | | Не проверено |
| 4 | Anonymous catalog list | | | | | Не проверено |
| 5 | Anonymous catalog detail | | | | | Не проверено |
| 6 | Staff create make | | | | | Не проверено |
| 7 | Staff read/update make | | | | | Не проверено |
| 8 | Staff create model/relation output | | | | | Не проверено |
| 9 | Valid PUT | | | | | Не проверено |
| 10 | PATCH preserves omitted | | | | | Не проверено |
| 11 | DELETE deactivates | | | | | Не проверено |
| 12 | Exact filters | | | | | Не проверено |
| 13 | Unicode search | | | | | Не проверено |
| 14 | Allowed ordering | | | | | Не проверено |
| 15 | Pagination metadata | | | | | Не проверено |
| 16 | OpenAPI validates | | | | | Не проверено |
| 17 | Empty catalog | | | | | Не проверено |
| 18 | One-row catalog | | | | | Не проверено |
| 19 | Inclusive min price | | | | | Не проверено |
| 20 | Inclusive max price | | | | | Не проверено |
| 21 | Equal price bounds | | | | | Не проверено |
| 22 | Stable equal-price pages | | | | | Не проверено |
| 23 | Page size one/max cap | | | | | Не проверено |
| 24 | Last/out-of-range page | | | | | Не проверено |
| 25 | Inactive excluded | | | | | Не проверено |
| 26 | Empty/combined query | | | | | Не проверено |
| 27 | Anonymous staff API denied | | | | | Не проверено |
| 28 | Non-staff denied | | | | | Не проверено |
| 29 | Real staff session/CSRF policy | | | | | Не проверено |
| 30 | Public writes are 405 | | | | | Не проверено |
| 31 | Invalid/duplicate create | | | | | Не проверено |
| 32 | Invalid/inactive make relation | | | | | Не проверено |
| 33 | Invalid price range | | | | | Не проверено |
| 34 | JSON/media negotiation errors | | | | | Не проверено |
| 35 | N=2/N=20 query budget | | | | | Не проверено |
| 36 | Unexpected error safety/schema match | | | | | Не проверено |

## Команды общей проверки

| Проверка | Команда | Exit | Duration | Summary |
|---|---|---:|---:|---|
| Django checks | | | | |
| Migration drift | | | | |
| Full tests | | | | |
| OpenAPI validation | | | | |
| Clean replay | | | | |

## Итог

- Positive: —/16.
- Boundary: —/10.
- Error/security/performance: —/10.
- Всего: —/36.
- Критические ошибки: —.
- Незакрытые исправления: —.
