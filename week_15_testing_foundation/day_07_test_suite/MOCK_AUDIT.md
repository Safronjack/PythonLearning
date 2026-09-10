# Mock and test-double audit

Статус: template.

## Правило

Mock применяется только к объяснимой границе. Для каждой замены записывается риск, который перестал проверяться, и соседний integration proof при необходимости.

## Audit table

| Test/node | Mocked symbol | Import/lookup in consumer | Patch target | Double type | Spec/autospec | What is proven | What is not proven | Paired integration test | Decision |
|---|---|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | — | — | — |

## Suspect mocks

| Target | Why risky | Replace with | Status |
|---|---|---|---|
| ORM QuerySet/manager | может тестировать только chain setup | real PostgreSQL integration | — |
| DRF authentication/permissions | скрывает security path | APIClient real path | — |
| Business policy under service test | разрешает service забыть policy | real policy or explicit contract spy | — |

## Call/no-call evidence

| Boundary | Success call contract | Deny no-call contract | Failure behavior | Test nodes |
|---|---|---|---|---|
| — | — | — | — | — |

