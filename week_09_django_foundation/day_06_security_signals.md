# День 6: signals, security checks и tests

## Signal decision table

| Событие | Решение | Failure semantics | Transaction concern | Тестируемость |
|---|---|---|---|---|
| Уменьшение stock |  |  |  |  |
| Списание balance |  |  |  |  |
| Login telemetry |  |  |  |  |
| Email после регистрации |  |  |  |  |
| Cache invalidation |  |  |  |  |
| Создание BuyerProfile |  |  |  |  |
| Внешний HTTP-вызов |  |  |  |  |

## Security settings matrix

| Setting/control | Development | Production intent | Threat | Owner/layer | Proof |
|---|---|---|---|---|---|
| `DEBUG` |  |  |  |  |  |
| `SECRET_KEY` |  |  |  |  |  |
| `ALLOWED_HOSTS` |  |  |  |  |  |
| CSRF middleware |  |  |  |  |  |
| SecurityMiddleware |  |  |  |  |  |
| Secure cookies |  |  |  |  |  |
| HTTPS redirect |  |  |  |  |  |
| HSTS |  |  |  |  |  |
| Clickjacking header |  |  |  |  |  |

## Deploy warnings

| Warning | Причина | Сейчас/позже | Предусловие | Решение |
|---|---|---|---|---|
|  |  |  |  |  |

## Test results

- Command:
- Tests run:
- Passed:
- Failed:
- Что исправлено:

## Самооценка

1. Что я сделал самостоятельно?
2. Как проходит request в сегодняшнем коде?
3. Где прогноз отличался от результата?
4. Какую ошибку я теперь могу объяснить?
5. Что осталось непонятным?
6. Сколько времени заняла работа?
