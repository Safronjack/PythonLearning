# День 2: serializers и validation

Статус: **заблокировано до зачёта дня 1**.

## Карта полей

| Resource/field | Read | Create | PUT | PATCH | Source | Validation | Причина |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

## Predictions

1. Когда можно читать `validated_data`?
2. Что находится в `.data` у serializer с instance?
3. Сохранит ли PATCH отсутствующее поле?
4. Достаточно ли serializer uniqueness check при двух одновременных requests?
5. Что произойдёт с неизвестным input field?

## Validation ownership

| Правило | Field serializer | Object serializer | Database | Service | Почему |
|---|---|---|---|---|---|
| | | | | | |

## Сценарии 1–12

Для каждого сохраните input, prediction, `.is_valid()`, `.errors`/codes, `.validated_data`, output representation и database effect.

## PUT/PATCH сравнение

| Initial state | Request | `partial` | Expected | Actual |
|---|---|---|---|---|
| | | | | |

## Самооценка

- Что сделал самостоятельно:
- Что теперь могу объяснить:
- Ошибка дня и её причина:
- Что осталось непонятным:
- Вопросы наставнику:
- Время:

