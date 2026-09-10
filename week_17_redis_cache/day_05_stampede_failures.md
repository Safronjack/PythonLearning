# День 5: stampede и failures — рабочий журнал

## Прогнозы

1. Loader calls without protection:
2. Зачем double-check:
3. Кто может release lock:
4. Redis unavailable API result:

## Single-flight contract

- Hot key/loader:
- Lock key/token:
- Lock TTL:
- Blocking/wait budget:
- Non-owner fallback:
- Exception cleanup:
- TTL jitter range/source:

## R43–R50

| ID | Concurrent/failure input | Expected responses/loader/lock/metric | Node ID | Actual/duration | Status |
|---|---|---|---|---|---|
| R43 | | | | | |

## Failure policy

| Error | Caught? | API fallback | Cache write? | Log/metric | Retry budget |
|---|---|---|---|---|---|
| | | | | | |

## Самооценка

- Что получилось:
- Что непонятно:
- Как исключено удаление чужого lock:
- Моя оценка /10:

