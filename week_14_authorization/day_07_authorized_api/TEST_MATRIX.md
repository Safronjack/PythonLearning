# Test matrix: 48 authorization scenarios

Статус: template. `Actual` заполняется только после реального запуска.

## Среда

- Source commit:
- Database vendor/purpose:
- Test command:
- Date:
- Duration/result:
- Cache/email isolation:

## Сценарии

| ID | Category | Subject/action/resource | Prediction | Actual status/result | Visible data | DB/side effects | Evidence/test | Explanation |
|---:|---|---|---|---|---|---|---|---|
| 1 | Positive | Anonymous public catalog list | — | — | — | — | — | — |
| 2 | Positive | Anonymous public catalog detail | — | — | — | — | — | — |
| 3 | Positive | Verified buyer creates own Offer | — | — | — | — | — | — |
| 4 | Positive | Buyer lists own Offers | — | — | — | — | — | — |
| 5 | Positive | Buyer retrieves own Offer | — | — | — | — | — | — |
| 6 | Positive | Buyer cancels own pending Offer | — | — | — | — | — | — |
| 7 | Positive | Buyer reads own Purchases | — | — | — | — | — | — |
| 8 | Positive | Buyer reads own statistics | — | — | — | — | — | — |
| 9 | Positive | Dealership operator reads own inventory | — | — | — | — | — | — |
| 10 | Positive | Dealership operator changes own preference | — | — | — | — | — | — |
| 11 | Positive | Dealership operator reads own statistics | — | — | — | — | — | — |
| 12 | Positive | Supplier operator reads own catalog | — | — | — | — | — | — |
| 13 | Positive | Supplier operator creates own catalog item | — | — | — | — | — | — |
| 14 | Positive | Supplier operator changes own catalog item | — | — | — | — | — | — |
| 15 | Positive | Supplier operator deactivates own item | — | — | — | — | — | — |
| 16 | Positive | Supplier operator manages own promotion | — | — | — | — | — | — |
| 17 | Positive | Supplier operator reads own statistics | — | — | — | — | — | — |
| 18 | Positive | Platform admin reads global statistics | — | — | — | — | — | — |
| 19 | Positive | Platform admin adjusts balance with reason | — | — | — | — | — | — |
| 20 | Positive | Superuser follows explicit ADR override | — | — | — | — | — | — |
| 21 | Boundary | Buyer empty scope | — | — | — | — | — | — |
| 22 | Boundary | User missing profile | — | — | — | — | — | — |
| 23 | Boundary | Operator missing membership | — | — | — | — | — | — |
| 24 | Boundary | Inactive organization mutation | — | — | — | — | — | — |
| 25 | Boundary | Own non-pending Offer cancel | — | — | — | — | — | — |
| 26 | Boundary | Repeated cancel | — | — | — | — | — | — |
| 27 | Boundary | Foreign versus missing ID contract | — | — | — | — | — | — |
| 28 | Boundary | Page beyond own scope | — | — | — | — | — | — |
| 29 | Boundary | Foreign filter cannot widen scope | — | — | — | — | — | — |
| 30 | Boundary | Unknown role/action | — | — | — | — | — | — |
| 31 | Boundary | Staff without capability | — | — | — | — | — | — |
| 32 | Boundary | Role revoked after access issued | — | — | — | — | — | — |
| 33 | Boundary | Membership revoked after access issued | — | — | — | — | — | — |
| 34 | Boundary | Permission cache uses fresh user instance | — | — | — | — | — | — |
| 35 | Abuse | Anonymous protected endpoint | — | — | — | — | — | — |
| 36 | Abuse | Buyer A reads Offer B | — | — | — | — | — | — |
| 37 | Abuse | Buyer A reads Purchase B | — | — | — | — | — | — |
| 38 | Abuse | Buyer substitutes `buyer_id` | — | — | — | — | — | — |
| 39 | Abuse | Buyer changes role/group/admin flags | — | — | — | — | — | — |
| 40 | Abuse | Non-admin changes balance | — | — | — | — | — | — |
| 41 | Abuse | Dealership A accesses dealership B | — | — | — | — | — | — |
| 42 | Abuse | Supplier A accesses supplier B | — | — | — | — | — | — |
| 43 | Abuse | Supplier reassigns resource to other org | — | — | — | — | — | — |
| 44 | Abuse | Method/legacy route bypass | — | — | — | — | — | — |
| 45 | Abuse | Direct service call with wrong actor | — | — | — | — | — | — |
| 46 | Abuse | Concurrent Offer transition | — | — | — | — | — | — |
| 47 | Abuse | Denial side effect/log leak | — | — | — | — | — | — |
| 48 | Abuse | OpenAPI privilege/runtime mismatch | — | — | — | — | — | — |

## Итог

- Positive: —/20.
- Boundary: —/14.
- Abuse/security: —/14.
- Всего: —/48.
- Незакрытые gaps:
- Regression result:
- Clean replay:
