# День 6: authorization security audit

Статус: заблокировано до зачёта дня 5.

## Attack matrix

| Attack | Entry point | Expected control | Test ID | Actual | Остаточный риск |
|---|---|---|---|---|---|
| Horizontal/BOLA | — | — | — | — | — |
| Vertical escalation | — | — | — | — | — |
| Mass assignment | — | — | — | — | — |
| Stale JWT role | — | — | — | — | — |

## `401`/`403`/`404` audit

| Case | Status | Headers | Error shape | Existence leaked? | Rationale |
|---|---:|---|---|---|---|
| No token | — | — | — | — | — |
| Invalid/expired token | — | — | — | — | — |
| Wrong role | — | — | — | — | — |
| Foreign object | — | — | — | — | — |
| Missing object | — | — | — | — | — |

## Stale JWT evidence

| Database change after token issue | Authentication result | Authorization result | Side effects | Explanation |
|---|---|---|---|---|
| Role revoked | — | — | — | — |
| Membership revoked | — | — | — | — |
| User inactive | — | — | — | — |

## Log/secret/side-effect audit

- Locations searched:
- Forbidden patterns:
- Denied operations checked:
- DB/ledger/stock/mail before/after:
- Findings and fixes:

## OpenAPI audit

| Path/method | Runtime security | Schema security | Roles/scope stated | Input/output fields | Statuses | Match |
|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — |

## Guard mutation evidence

| Temporarily removed guard | Test that failed | Why this proves value | Restored/green |
|---|---|---|---|
| — | — | — | — |

## Сценарии 1–16

| ID | Attack/case | Prediction | Actual | State/side effects | Evidence |
|---|---|---|---|---|---|
| 1 | — | — | — | — | — |

## Самооценка

1. Какая attack path была самой опасной?
2. Что произошло со старым JWT после revoke?
3. Как доказано отсутствие side effect?
4. Какой guard mutation пойман test?
5. Где runtime и schema расходились?
6. Что осталось риском:
7. Вопрос наставнику:
8. Время:
