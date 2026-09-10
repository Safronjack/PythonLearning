# Итоговая матрица проверки: неделя 13

Статус: **заполняется только фактическими результатами**.

Полные условия находятся в `../PRACTICE.md`, день 7. Raw passwords/tokens/links заменяются на `<redacted>`; evidence содержит states/counts/codes, а не credentials.

| ID | Сценарий | Test/command | Expected | Actual | DB/mail/token/cache evidence | Статус |
|---:|---|---|---|---|---|---|
| 1 | Clean install/migration compatibility | | | | | Не проверено |
| 2 | Week 11–12 regressions | | | | | Не проверено |
| 3 | Valid registration state | | | | | Не проверено |
| 4 | Password hash/check | | | | | Не проверено |
| 5 | Registration mail after commit | | | | | Не проверено |
| 6 | Valid email verification | | | | | Не проверено |
| 7 | Resend revokes old link | | | | | Не проверено |
| 8 | Verified login pair | | | | | Не проверено |
| 9 | Access opens me | | | | | Не проверено |
| 10 | Refresh rotates pair | | | | | Не проверено |
| 11 | Logout blacklists refresh | | | | | Не проверено |
| 12 | Authenticated password change | | | | | Не проверено |
| 13 | Password change revokes refreshes | | | | | Не проверено |
| 14 | Reset email for eligible account | | | | | Не проверено |
| 15 | Reset confirmation | | | | | Не проверено |
| 16 | Identity request/new-email mail | | | | | Не проверено |
| 17 | Identity confirmation | | | | | Не проверено |
| 18 | OpenAPI/Swagger auth contracts | | | | | Не проверено |
| 19 | Identity normalization | | | | | Не проверено |
| 20 | Password minimum boundary | | | | | Не проверено |
| 21 | Exact token expiry boundary | | | | | Не проверено |
| 22 | Modified token | | | | | Не проверено |
| 23 | Verification replay | | | | | Не проверено |
| 24 | Concurrent verify consume | | | | | Не проверено |
| 25 | Old link after resend | | | | | Не проверено |
| 26 | Old refresh after rotation | | | | | Не проверено |
| 27 | Repeated logout | | | | | Не проверено |
| 28 | Malformed action token | | | | | Не проверено |
| 29 | Identity conflict at confirm | | | | | Не проверено |
| 30 | Old access policy | | | | | Не проверено |
| 31 | Registration privilege injection | | | | | Не проверено |
| 32 | Weak passwords all flows | | | | | Не проверено |
| 33 | Login enumeration states | | | | | Не проверено |
| 34 | Inactive user denied | | | | | Не проверено |
| 35 | Access/refresh type separation | | | | | Не проверено |
| 36 | Reset/resend enumeration contract | | | | | Не проверено |
| 37 | Wrong/expired/used/revoked purpose | | | | | Не проверено |
| 38 | Malicious Host link | | | | | Не проверено |
| 39 | 429 has no side effect | | | | | Не проверено |
| 40 | Throttle scope/actor isolation | | | | | Не проверено |
| 41 | Secret leakage scan | | | | | Не проверено |
| 42 | Failure rollback/on-commit safety | | | | | Не проверено |

## Общие проверки

| Проверка | Команда | Exit | Duration | Summary |
|---|---|---:|---:|---|
| Dependency clean install | | | | |
| Django checks | | | | |
| Migration drift/replay | | | | |
| Full tests | | | | |
| OpenAPI validation | | | | |
| Secret scan | | | | |

## Итог

- Positive: —/18.
- Boundary/replay: —/12.
- Error/security/abuse: —/12.
- Всего: —/42.
- Critical errors: —.
- Known limitations: —.
- Mandatory corrections: —.
