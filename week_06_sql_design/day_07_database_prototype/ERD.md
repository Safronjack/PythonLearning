# ERD итогового PostgreSQL-прототипа

Статус: **не начато**.

## Diagram

```mermaid
erDiagram
    %% TODO: diagram must match schema_postgresql.sql exactly
```

## Entity grain

| Entity | Одна row представляет | Primary key | Business unique key | Lifecycle |
|---|---|---|---|---|
| TODO | TODO | TODO | TODO | TODO |

## Relationship audit

| Parent | Child/bridge | Cardinality | FK | Optionality | `ON DELETE` |
|---|---|---|---|---|---|
| TODO | TODO | TODO | TODO | TODO | TODO |

## State, history and derived data

| Data | Category | Source of truth | Consistency/refresh rule |
|---|---|---|---|
| Current stock | TODO | TODO | TODO |
| Stock movement | TODO | TODO | TODO |
| Current balance | TODO | TODO | TODO |
| Balance entry | TODO | TODO | TODO |
| Best supplier | TODO | TODO | TODO |

## ERD ↔ DDL verification

- [ ] Every ERD entity has a table/view.
- [ ] Every DDL table appears in the ERD or is documented as technical.
- [ ] PK and FK names match.
- [ ] Optionality matches `NULL`/`NOT NULL`.
- [ ] One-to-one uniqueness exists in DDL.
- [ ] Many-to-many uses bridge entities.
