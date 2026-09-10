# День 6: throttling, enumeration и OpenAPI

Статус: **заблокировано до зачёта дня 5**.

## Scope/rate policy

| Endpoint | Burst scope/rate | Sustained scope/rate | Client key | Reason | Limitation |
|---|---|---|---|---|---|
| | | | | | |

## Predictions

1. Точно ли built-in throttle соблюдает limit при concurrency?
2. Что происходит при достижении limit до view logic?
3. Что может содержать `Retry-After`?
4. Почему `X-Forwarded-For` нельзя доверять без proxy policy?
5. Какие reset/resend/login responses нужно сравнить?

## 429 evidence

| Scope/actor | Allowed requests | First denied | Retry-After | DB delta | Mail delta | Cache isolation |
|---|---:|---:|---|---:|---:|---|
| | | | | | | |

## Enumeration comparison

| Endpoint/state | Status | Body keys/code | Headers | Mail private effect | Public mismatch |
|---|---:|---|---|---|---|
| | | | | | |

## Secret scan

| Location/pattern | Checked command/test | Finding | Fix | Clean |
|---|---|---|---|---|
| | | | | |

## Сценарии 1–14

Запишите actual 429, cache behavior и schema/log evidence без credentials.

## Самооценка

- Что сделал самостоятельно:
- Что теперь могу объяснить:
- Ошибка дня и причина:
- Непонятные места:
- Вопросы наставнику:
- Время:
