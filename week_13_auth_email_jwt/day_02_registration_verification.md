# День 2: registration и email verification

Статус: **заблокировано до зачёта дня 1**.

## Endpoint contracts

| Method/path | Input fields | Status/body | DB transition | Email effect | Safe errors |
|---|---|---|---|---|---|
| | | | | | |

## Predictions

1. Хеширует ли `create_user()` password?
2. Запускает ли он автоматически password validators?
3. Когда выполняется callback `on_commit()`?
4. Из какого значения строится domain confirmation link?
5. Работает ли старая ссылка после resend?

## Password validation evidence

| Input category | Expected code | Actual code | User/token rows | Raw value absent |
|---|---|---|---:|---|
| | | | | |

## Email evidence без token

| Scenario | Outbox count | Recipient | Subject safe | Trusted domain | Callback timing |
|---|---:|---|---|---|---|
| | | | | | |

## State before/after

| Scenario | User before | Token before | User after | Token after | Result |
|---|---|---|---|---|---|
| | | | | | |

## Сценарии 1–12

Запишите statuses, shapes, row/mail counts и state transitions. Raw links/tokens замените на `<redacted>`.

## Самооценка

- Что сделал самостоятельно:
- Что теперь могу объяснить:
- Ошибка дня и причина:
- Непонятные места:
- Вопросы наставнику:
- Время:

