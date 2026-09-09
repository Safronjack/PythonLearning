# Итоговый проект недели 12: DRF API

Статус: **заготовка наставника; реализация заблокирована до зачёта дней 1–6**.

Ученик переносит сюда принятый проект недели 11 только после явного допуска. Готовый код здесь заранее не предоставляется.

## Цель

Собрать API v1 поверх существующих models, selectors и services:

- public read-only catalog list/detail;
- staff-only CRUD `CarMake` и `CarModel`;
- deactivation вместо физического DELETE;
- filtering, search, ordering и bounded pagination;
- единый safe error envelope;
- OpenAPI schema и Swagger UI;
- tests безопасности, database effects, query budget и schema contract.

Полное ТЗ, вертикальные срезы, 36 сценариев и вопросы защиты находятся в `../PRACTICE.md`, день 7.

## Source и environment

- Source week 11 branch/commit:
- Current branch/commit:
- Python version:
- Django version:
- DRF version:
- django-filter version:
- drf-spectacular version:
- Dependency file:
- Settings module:
- Database purpose (без host/password/DSN):

## Быстрый старт

Заполните только фактически проверенными командами:

```text
1. Создание/активация virtual environment:
2. Установка dependencies:
3. Настройка environment без secrets в Git:
4. Запуск PostgreSQL/test prerequisites:
5. Django checks и migrations:
6. Запуск tests:
7. Validation OpenAPI:
8. Запуск development server:
```

## API routes

| Method | Path | Actor | Назначение |
|---|---|---|---|
| GET | `/api/v1/health/` | public | минимальная проверка HTTP process |
| GET | `/api/v1/catalog/` | public | каталог |
| GET | `/api/v1/catalog/{id}/` | public | позиция каталога |
| CRUD | `/api/v1/reference/makes/` | staff | справочник марок |
| CRUD | `/api/v1/reference/car-models/` | staff | справочник моделей |
| GET | `/api/schema/` | по принятой policy | OpenAPI schema |
| GET | `/api/docs/` | по принятой policy | Swagger UI |

Уточните generated route names и фактическую schema в `API_CONTRACT.md`.

## Архитектурные границы

- API view/action orchestrates HTTP flow.
- Serializer владеет external representation и input validation.
- Selector владеет оптимизированным чтением.
- Service владеет business transition и transaction.
- Database constraint остаётся последней защитой integrity.
- Inventory, balances, purchases, movements и supplier price не имеют generic writable API.

## Проверка готовности

- [ ] Setup воспроизводим с чистого checkout.
- [ ] Все routes и actors соответствуют `API_CONTRACT.md`.
- [ ] Все 36 строк `TEST_MATRIX.md` заполнены actual results.
- [ ] `OPENAPI_AUDIT.md` не содержит незакрытых mismatch.
- [ ] Full test suite green.
- [ ] Query budget N=2/N=20 подтверждён.
- [ ] No secrets/internal errors в документах и responses.
- [ ] Ограничения и известные проблемы перечислены ниже.

## Известные ограничения

- Authentication/JWT не реализуется до недели 13.
- Детальные roles/object permissions — неделя 14.
- Background tasks/Redis/Celery — более поздние недели.
-

## Самооценка

- Что реализовано самостоятельно:
- Самая сложная ошибка:
- Почему архитектурные границы сохранены:
- Что нужно усилить перед неделей 13:

