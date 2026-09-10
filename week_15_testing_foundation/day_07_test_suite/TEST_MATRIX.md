# Test matrix: 54 scenarios

Статус: template. `Actual` заполняется только после запуска.

## Среда

- Source commit:
- Python/Django/DRF/PostgreSQL:
- pytest/pytest-django/coverage:
- Database purpose:
- Test command:
- Date/duration:
- Cache/email/network isolation:

## Сценарии

| ID | Level | Behavior | Prediction | Actual | Oracle/assertions | State/side effects | Node/evidence |
|---:|---|---|---|---|---|---|---|
| 1 | Unit | Base price without promotion | — | — | — | — | — |
| 2 | Unit | Active promotion known price | — | — | — | — | — |
| 3 | Unit | Promotion before start | — | — | — | — | — |
| 4 | Unit | Exact start boundary | — | — | — | — | — |
| 5 | Unit | Exact end boundary | — | — | — | — | — |
| 6 | Unit | Expired/inactive promotion | — | — | — | — | — |
| 7 | Unit | Result price nonnegative | — | — | — | — | — |
| 8 | Unit | Minimum final supplier price | — | — | — | — | — |
| 9 | Unit | Deterministic supplier tie-break | — | — | — | — | — |
| 10 | Unit | Empty/unavailable candidates | — | — | — | — | — |
| 11 | Unit | Own pending Offer policy | — | — | — | — | — |
| 12 | Unit | Foreign Offer policy | — | — | — | — | — |
| 13 | Unit | Terminal Offer policy | — | — | — | — | — |
| 14 | Unit | Unknown/inactive/unverified actor | — | — | — | — | — |
| 15 | Integration | Valid inventory/balance rows | — | — | — | — | — |
| 16 | Integration | Exact zero balance/stock | — | — | — | — | — |
| 17 | Integration | Negative balance constraint | — | — | — | — | — |
| 18 | Integration | Negative stock constraint | — | — | — | — | — |
| 19 | Integration | Duplicate dealership inventory | — | — | — | — | — |
| 20 | Integration | Duplicate supplier catalog pair | — | — | — | — | — |
| 21 | Integration | Protected historical relation | — | — | — | — | — |
| 22 | Integration | Successful multi-write service | — | — | — | — | — |
| 23 | Integration | Insufficient balance rollback | — | — | — | — | — |
| 24 | Integration | Insufficient stock rollback | — | — | — | — | — |
| 25 | Integration | Invalid Offer state no Sale/movement | — | — | — | — | — |
| 26 | Integration | Invalid/expired/replayed action token | — | — | — | — | — |
| 27 | Integration | Locmem email recipient/content | — | — | — | — | — |
| 28 | Integration | On-commit email behavior | — | — | — | — | — |
| 29 | API | Anonymous public catalog read-only | — | — | — | — | — |
| 30 | API | Registration/verification password safety | — | — | — | — | — |
| 31 | API | Real JWT protected access | — | — | — | — | — |
| 32 | API | Missing/invalid/expired access | — | — | — | — | — |
| 33 | API | Refresh rejected as access | — | — | — | — | — |
| 34 | API | Buyer creates actor-owned Offer | — | — | — | — | — |
| 35 | API | Buyer lists own Offers | — | — | — | — | — |
| 36 | API | Foreign Offer/Purchase hidden | — | — | — | — | — |
| 37 | API | Own pending cancel only | — | — | — | — | — |
| 38 | API | Supplier own-organization mutation | — | — | — | — | — |
| 39 | API | Dealership scoped statistics | — | — | — | — | — |
| 40 | API | Staff without capability denied | — | — | — | — | — |
| 41 | API | Role/membership revoke with old access | — | — | — | — | — |
| 42 | API | Validation error envelope | — | — | — | — | — |
| 43 | API | Denial has no side effects | — | — | — | — | — |
| 44 | API | Response/OpenAPI no private/secret fields | — | — | — | — | — |
| 45 | Tooling | Legacy unittest/Django collection | — | — | — | — | — |
| 46 | Tooling | Unit accidental DB access fails | — | — | — | — | — |
| 47 | Tooling | Reversed-order mutable fixture isolation | — | — | — | — | — |
| 48 | Tooling | Yield cleanup after failed assertion | — | — | — | — | — |
| 49 | Tooling | Strict marker typo | — | — | — | — | — |
| 50 | Tooling | Readable parametrized case failure | — | — | — | — | — |
| 51 | Tooling | Mock target/spec detects defect | — | — | — | — | — |
| 52 | Regression | N=2/N=20 query budget catches N+1 | — | — | — | — | — |
| 53 | Regression | Smoke/regression selection non-empty | — | — | — | — | — |
| 54 | Regression | Branch gaps resolved and clean run green | — | — | — | — | — |

## Итог

- Unit: —/14.
- Integration: —/14.
- API: —/16.
- Tooling/regression: —/10.
- Всего: —/54.
- Незакрытые gaps:
- Full suite:
- Coverage:
- Clean replay:
