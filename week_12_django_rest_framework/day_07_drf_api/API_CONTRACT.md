# API contract недели 12

Статус: **заполняет ученик до реализации каждого среза**.

## Общие правила

- Base prefix: `/api/v1/`.
- Request/response media type: JSON, если endpoint не описан иначе.
- Public money representation: decimal string.
- Datetime representation/timezone:
- Trailing slash policy:
- Authentication classes недели:
- Global permission default:
- Public catalog override:
- Staff reference permission:

## Success envelopes

### Один resource

```json
{
  "id": 1
}
```

Дополните только contract fields.

### Paginated collection

```json
{
  "count": 1,
  "next": null,
  "previous": null,
  "results": []
}
```

## Error envelope

```json
{
  "error": {
    "code": "validation_error",
    "message": "Request validation failed.",
    "details": {},
    "request_id": "example-request-id"
  }
}
```

Опишите типы keys, mapping статусов и сохранение nested DRF codes.

## Endpoint contracts

Для каждого endpoint заполните отдельную строку на method:

| Method/path | Route name/action | Actor/permission | Query params | Request fields | Success status/body | Error statuses | DB effect |
|---|---|---|---|---|---|---|---|
| GET `/api/v1/catalog/` | | public | | none | | | none |
| GET `/api/v1/catalog/{id}/` | | public | | none | | | none |
| GET `/api/v1/reference/makes/` | | staff | | none | | | none |
| POST `/api/v1/reference/makes/` | | staff | none | | | | create |
| GET `/api/v1/reference/makes/{id}/` | | staff | none | none | | | none |
| PUT `/api/v1/reference/makes/{id}/` | | staff | none | | | | update |
| PATCH `/api/v1/reference/makes/{id}/` | | staff | none | | | | partial update |
| DELETE `/api/v1/reference/makes/{id}/` | | staff | none | none | | | deactivate |
| CRUD `/api/v1/reference/car-models/...` | | staff | | | | | |

## Catalog query parameters

| Parameter | Type | Lookup | Required | Default | Invalid behavior | Example |
|---|---|---|---|---|---|---|
| `make` | | | no | | | |
| `country` | | | no | | | |
| `dealership` | | | no | | | |
| `min_price` | decimal | gte | no | | | |
| `max_price` | decimal | lte | no | | | |
| `search` | string | | no | | | |
| `ordering` | string | allowlist | no | | | |
| `page` | integer | | no | 1 | | |
| `page_size` | integer | capped | no | | | |

## Explicit serializer fields

| Serializer | Read fields | Writable fields | Read-only | Write-only | Forbidden/internal |
|---|---|---|---|---|---|
| Catalog | | none | | none | |
| Make | | | | | |
| CarModel read/write | | | | | |

## Deactivation contract

- DELETE success status:
- Response body:
- Database row after first DELETE:
- Public visibility after DELETE:
- Staff visibility after DELETE:
- Repeated DELETE behavior:
- Historical relation behavior:

## Query budgets

| Endpoint/shape | N=0 | N=2 | N=20 | Accepted maximum/formula |
|---|---:|---:|---:|---|
| Catalog first page | | | | |
| Catalog filtered page | | | | |
| Catalog detail | | | | |

