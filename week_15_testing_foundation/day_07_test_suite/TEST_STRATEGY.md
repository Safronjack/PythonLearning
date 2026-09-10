# Test strategy

Статус: template; фактические данные заполняются учеником.

## Цели и риски

| Priority | Requirement/risk | Failure impact | Cheapest sufficient level | Main proof | Owner/command |
|---|---|---|---|---|---|
| Critical | — | — | — | — | — |

## Levels и boundaries

| Level | Includes | Excludes | Real dependencies | Expected feedback |
|---|---|---|---|---|
| Unit | — | — | — | — |
| Integration | — | — | — | — |
| API | — | — | — | — |
| E2E/week 16 | — | — | — | — |

## Test groups

| Marker/command | Purpose | Required components | Selection count | Zero-test policy |
|---|---|---|---:|---|
| unit | — | — | — | fail |
| integration | — | — | — | fail |
| api | — | — | — | fail |
| smoke | — | — | — | fail |

## Environment policy

- Database:
- Cache:
- Email:
- Filesystem:
- Network:
- Clock/randomness:
- Secrets/private data:

## Definition of Done для test

- risk и level названы;
- Arrange/Act/Assert читаются;
- oracle независим;
- positive/boundary/negative выбраны по риску;
- database/side effects проверены;
- failure mutation доказана для critical rule;
- test independent/deterministic;
- node ID/marker documented.

## Week 16 handoff

- TDD candidates:
- Concurrency/transaction gaps:
- Async gaps:
- E2E flows:
- Flaky/performance risks:

