# День 3: key, TTL и cache-aside — рабочий журнал

## Прогнозы

1. First request cache outcome:
2. Second identical request loader calls:
3. Same filters in another order key:
4. `TTL -1`/`TTL -2`:

## Baseline/cache contract

- Endpoint:
- PostgreSQL source/query count:
- Public schema/order:
- Cache payload/version:
- TTL/staleness:
- Empty/negative policy:

## Key design

- Format:
- Scope inputs:
- Filter canonicalization:
- Untrusted input digest:
- PII/secret audit:

## R21–R32

| ID | Request/input | Expected key/cache/DB/API | Node ID | Actual/query-loader count | Status |
|---|---|---|---|---|---|
| R21 | | | | | |

## Самооценка

- Что получилось:
- Что непонятно:
- Как доказана hit/miss equivalence:
- Моя оценка /10:

