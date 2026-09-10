# День 2: RBAC и permissions

Статус: заблокировано до зачёта дня 1.

## Role/capability mapping

| Role | Capability/codename | Назначение | Provisioning source | Проверка runtime |
|---|---|---|---|---|
| — | — | — | — | — |

## Action map

| ViewSet/action | Allowed roles/capabilities | Active/verified gate | Default при отсутствии правила | Test IDs |
|---|---|---|---|---|
| — | — | — | deny | — |

## Protected input fields

| Serializer/endpoint | Запрещённое поле | Server owner/source | Фактический результат попытки |
|---|---|---|---|
| — | role/group/owner/... | — | — |

## Provisioning evidence

- Migration/command:
- Первый запуск:
- Повторный запуск:
- Clean replay:
- Missing/renamed permission behavior:

## Permission cache и JWT freshness

- Результат на reused user instance:
- Результат на fresh instance:
- Старый JWT до revoke:
- Старый JWT после revoke:
- Почему:

## Сценарии 1–12

| ID | Actor/action | Prediction | Actual status | State/side effects | Объяснение |
|---|---|---|---|---|---|
| 1 | — | — | — | — | — |

## Самооценка

1. Каков canonical role source?
2. Чем роль отличается от capability?
3. Где fail-closed default?
4. Какие privilege fields закрыты?
5. Что доказал revoke test?
6. Самая полезная ошибка:
7. Вопрос наставнику:
8. Время:

