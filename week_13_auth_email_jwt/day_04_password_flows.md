# День 4: password change и reset

Статус: **заблокировано до зачёта дня 3**.

## Flow comparison

| Property | Authenticated change | Reset request/confirm |
|---|---|---|
| Actor/proof | | |
| Required fields | | |
| Email | | |
| Token | | |
| Session effect | | |
| Enumeration policy | | |

## Predictions

1. Что произойдёт при wrong current password?
2. Как validators узнают email/login пользователя?
3. Должен ли unknown reset email дать 404?
4. Какие refresh sessions отзываются после success?
5. Что происходит со старым access?

## Credential before/after

| Scenario | Old password | New password | Old refresh | Old access | Token state | DB atomic |
|---|---|---|---|---|---|---|
| | | | | | | |

## Reset response comparison

| Account state | Status/body fingerprint | Mail count | Token delta | Public difference |
|---|---|---:|---:|---|
| Existing eligible | | | | |
| Unknown | | | | |
| Inactive | | | | |
| Unverified | | | | |

## Сценарии 1–12

Не записывайте passwords/reset links. Сохраняйте только categories, codes, counts и state.

## Самооценка

- Что сделал самостоятельно:
- Что теперь могу объяснить:
- Ошибка дня и причина:
- Непонятные места:
- Вопросы наставнику:
- Время:

