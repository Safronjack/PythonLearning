# Concurrency matrix

## Environment и механизм

- PostgreSQL/test DB proof:
- Transaction marker/fixture:
- Worker model:
- Separate connection lifecycle:
- Barrier/event point:
- Timeout/join policy:
- Exception collection:

## Lock/transaction order

| Operation | Rows/resources | Lock/read order | Writes | Commit side effect | Failure rollback |
|---|---|---|---|---|---|
| | | | | | |

## Сценарии

| ID | Initial state | Concurrent actions | Allowed worker outcomes | Required final invariants | Repeat result |
|---|---|---|---|---|---|
| S16 | | | | | |

## Hang/deadlock diagnostics

- Как test завершается:
- Что печатается/сохраняется:
- Как освобождаются connections:
- Какой lock order принят:

