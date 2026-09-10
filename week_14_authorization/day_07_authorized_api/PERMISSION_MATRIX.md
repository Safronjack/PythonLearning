# Permission matrix

Статус: шаблон. Это канонический authorization contract недели 14.

## Правила заполнения

- Одна строка описывает один resource/action.
- `Scope`: public, own, organization, all или none.
- Для deny укажите ожидаемый `401`, `403`, `404` или `405` по фактическому contract.
- Любой runtime route/action должен иметь строку.
- Любое изменение сначала вносится сюда и в tests.

## Матрица

| Resource/path | Action | Anonymous | Buyer | Dealership operator | Supplier operator | Staff without capability | Platform admin | Superuser | Policy layers | Test IDs |
|---|---|---|---|---|---|---|---|---|---|---|
| Public catalog | list/retrieve | allow: public | allow: public | allow: public | allow: public | allow: public | allow: public | per ADR | view/queryset | — |
| Offer | create | deny | allow: own | deny | deny | deny | explicit admin contract | per ADR | view/service | — |
| Offer | list/retrieve | deny | allow: own | deny | deny | deny | allow: all | per ADR | view/queryset/object | — |
| Offer | cancel | deny | allow: own pending | deny | deny | deny | explicit admin contract | per ADR | view/queryset/object/service | — |
| Purchase | list/retrieve | deny | allow: own | deny | deny | deny | allow: all | per ADR | view/queryset | — |
| Dealership inventory | read | deny | per product contract | allow: own org | deny | deny | allow: all | per ADR | view/queryset | — |
| Dealership preference | change | deny | deny | allow: own org | deny | deny | allow: all | per ADR | view/queryset/service | — |
| Supplier catalog | change | deny | deny | deny | allow: own org | deny | allow: all | per ADR | view/queryset/service | — |
| Promotion | manage | deny | deny | fill contract | allow: own org | deny | allow: all | per ADR | view/queryset/service | — |
| Balance | adjust | deny | deny | deny | deny | deny | allow with capability | per ADR | view/service/ledger | — |
| Statistics | read | deny | allow: own | allow: own org | allow: own org | deny | allow: all | per ADR | view/queryset/serializer | — |
| Role/permission | assign/revoke | deny | deny | deny | deny | deny | trusted flow only | per ADR | view/service/audit | — |

## Route coverage

| Actual path/method/action | Matrix row above | Covered test IDs | Gap/action |
|---|---|---|---|
| — | — | — | — |

