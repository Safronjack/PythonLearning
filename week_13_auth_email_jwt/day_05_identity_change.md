# День 5: подтверждаемая смена email/login

Статус: **заблокировано до зачёта дня 4**.

## Identity policy

| Question | Decision | Reason | Test |
|---|---|---|---|
| Email/login change together? | | | |
| Case-only change? | | | |
| Duplicate public error? | | | |
| Old access behavior? | | | |
| Old-email notification? | | | |

## Predictions

1. Какой email показывает `/me/` сразу после change request?
2. Куда приходит confirmation message?
3. Когда повторно проверяется uniqueness?
4. Что происходит при conflict на confirm?
5. Какой user ID будет в новых JWT?

## State before/after

| Scenario | Current identity | Pending identity | Token | After confirm | Refresh/access effect |
|---|---|---|---|---|---|
| | | | | | |

## Recipient/security evidence

| Scenario | New-email mail | Old-email mail | Trusted domain | Secret absent logs/schema |
|---|---:|---:|---|---|
| | | | | |

## Сценарии 1–12

Actual email/login допустимы только в форме `example.invalid`; token/password всегда `<redacted>`.

## Самооценка

- Что сделал самостоятельно:
- Что теперь могу объяснить:
- Ошибка дня и причина:
- Непонятные места:
- Вопросы наставнику:
- Время:

