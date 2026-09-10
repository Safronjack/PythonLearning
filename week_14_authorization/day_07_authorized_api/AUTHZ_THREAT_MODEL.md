# Authorization threat model

Статус: template; заполняется до реализации.

## Assets

- private Offer/Purchase data;
- balances and immutable ledger;
- dealership/supplier business data;
- promotions and prices;
- role/group/permission state;
- statistics and aggregate confidentiality;
- account/JWT identity from week 13.

## Actors

- anonymous attacker;
- authenticated buyer;
- operator of another organization;
- staff without business permission;
- compromised account;
- accidental developer/configuration mistake.

## Trust boundaries

```text
client input
  -> authentication
  -> DRF permissions
  -> queryset/object lookup
  -> domain service/transaction
  -> PostgreSQL
  -> response/log/OpenAPI
```

## Threat table

| ID | Asset | Actor | Entry point | Abuse path | Impact | Preventive control | Detective test/log | Residual risk |
|---|---|---|---|---|---|---|---|---|
| T-01 | Private object | Auth user | Path ID | BOLA/IDOR | Confidentiality breach | Scoped queryset | Foreign/missing tests | — |
| T-02 | Role state | Buyer | PATCH body | Mass assignment | Vertical escalation | Explicit fields/server ownership | Privilege-field tests | — |
| T-03 | Organization data | Other operator | URL/filter/body | Membership bypass | Cross-org breach | DB membership policy | A/B org matrix | — |
| T-04 | Business state | Wrong actor | Direct service call | View bypass | Unauthorized mutation | Service policy | Direct-call tests | — |
| T-05 | Revoked rights | Old JWT | Protected endpoint | Stale role claim | Continued privilege | Current DB policy | Old-token revoke test | — |
| T-06 | Aggregates | Limited actor | Stats filters | Scope after aggregate | Information leak | Scope before aggregate | Mixed dataset tests | — |
| T-07 | Side effects | Denied actor | Mutation action | Check after write | Integrity breach | Check before mutation/transaction | Before/after tests | — |

## Abuse questions

- Что произойдёт, если identifier известен точно?
- Можно ли заменить owner/organization в body или query?
- Есть ли route/action без matrix row?
- Может ли staff пройти business check без capability?
- Что происходит после role/membership revoke?
- Может ли empty scope превратиться в `.all()`?
- Создаёт ли deny запись, письмо, ledger или stock movement?
- Раскрывает ли response/log существование или private fields?

