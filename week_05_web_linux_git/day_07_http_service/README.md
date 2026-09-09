# Итоговый HTTP service недели 5

Статус: **не начато**.

## Назначение

TODO

## API contract

| Method | Path | Success | Ошибки | Cache policy |
|---|---|---:|---|---|
| GET | `/health` | TODO | TODO | TODO |
| GET | `/cars` | TODO | TODO | TODO |
| GET | `/cars/{car_id}` | TODO | TODO | TODO |
| POST | `/quotes` | TODO | TODO | TODO |

## Архитектура

TODO: описать обязанности всех Python-модулей и направление зависимостей.

## Status/error policy

TODO

## Security decisions

TODO: body limit, media types, output encoding, safe errors, request id, logs и причина отсутствия CORS «на всякий случай».

## Ограничения

TODO: объяснить, почему WSGI reference server и in-memory data не являются production solution.

## Что позднее даст Django

TODO

## Что останется ответственностью разработчика

TODO

## Самооценка

1. Что получилось:
2. Где было трудно:
3. Какие сценарии пришлось исправлять:
4. Что могу объяснить без кода:
