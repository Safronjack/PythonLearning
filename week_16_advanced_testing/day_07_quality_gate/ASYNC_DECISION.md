# Async testing decision

## Inventory scope

- Production roots:
- Exclusions:
- Search commands:
- Dependency/config inspection:

| Location | Async construct/bridge | Caller → side effect | Actual production path? | Evidence |
|---|---|---|---|---|
| | | | | |

## Decision

- Ветка: A / B
- Почему:
- Runner/plugin and compatibility:
- Dependency change or reason none:

## S35–S40

| ID | Aspect | Node ID or N/A evidence | Result/status |
|---|---|---|---|
| S35 | entry point | | |
| S36 | awaited I/O | | |
| S37 | error propagation | | |
| S38 | cancellation/timeout | | |
| S39 | cleanup/pending tasks | | |
| S40 | sync↔async boundary | | |

## Повторная проверка

- Clean command/result:
- Leaked resource check:
- Когда решение нужно пересмотреть:

