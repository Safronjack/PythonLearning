# Auth contract недели 13

Статус: **заполняет ученик до реализации каждого flow**.

Не вставляйте working passwords, tokens, signing keys, cookies или реальные домены/адреса.

## Identity policy

- `USERNAME_FIELD`:
- Stable JWT user ID field:
- Email normalization:
- Login normalization:
- Email/login case-sensitivity:
- Database uniqueness mechanism:
- Registration duplicate policy:
- `is_active` meaning:
- `is_email_verified` meaning:
- Unverified password-reset eligibility:
- Identity change fields/together policy:

## User states

| State | `is_active` | `is_email_verified` | Pending identity | Login | Allowed public actions |
|---|---:|---:|---|---|---|
| New/unverified | | | | | |
| Verified | | | | | |
| Blocked | | | | | |
| Change pending | | | | | |

## State transitions

| Flow | Initial state | Required proof | Success state | Issued/revoked | Email | Failure state |
|---|---|---|---|---|---|---|
| Register | | | | | | |
| Verify | | | | | | |
| Resend | | | | | | |
| Login | | | | | | |
| Refresh | | | | | | |
| Logout | | | | | | |
| Password change | | | | | | |
| Reset request/confirm | | | | | | |
| Identity request/confirm | | | | | | |

## Action-token policy

| Purpose | TTL | Pending payload | Old-token revoke | Consumption locks | Success effect |
|---|---|---|---|---|---|
| Verify email | | | | | |
| Reset password | | none | | | |
| Change identity | | | | | |

- Raw generation primitive:
- Public selector format:
- Digest algorithm:
- Compare method:
- Exact expiry rule:
- Invalid/replayed public error:
- Cleanup/retention policy:

## JWT policy

| Setting/property | Value/shape | Reason | Verified by test |
|---|---|---|---|
| Access lifetime | | | |
| Refresh lifetime | | | |
| Rotation | | | |
| Blacklist after rotation | | | |
| Algorithm | | | |
| Signing key source | environment only | | |
| User ID field/claim | | | |
| Header type | Bearer | | |
| Update last login | | | |
| Password-change access revoke | | | |

## Endpoint contracts

Заполните отдельную строку на method/path:

| Method/path | Actor/auth | Input fields | Success status/body | Safe errors | DB/token effect | Email/throttle |
|---|---|---|---|---|---|---|
| POST `/auth/register/` | anonymous | | | | | |
| POST `/auth/email/verify/` | token | | | | | |
| POST `/auth/email/resend/` | anonymous | | | | | |
| POST `/auth/token/` | anonymous | | | | | |
| POST `/auth/token/refresh/` | refresh | | | | | |
| POST `/auth/token/logout/` | refresh | | | | | |
| GET `/auth/me/` | access | none | | | none | |
| POST `/auth/password/change/` | access | | | | | |
| POST `/auth/password/reset/request/` | anonymous | | | | | |
| POST `/auth/password/reset/confirm/` | token | | | | | |
| POST `/auth/identity/change/request/` | access | | | | | |
| POST `/auth/identity/change/confirm/` | token | | | | | |

## Enumeration fingerprints

| Endpoint | Compared states | Required same status | Required same body/code | Allowed private difference |
|---|---|---:|---|---|
| Login | nonexistent/wrong/unverified | | | none |
| Resend | unknown/verified/ineligible | | | mail/token only |
| Reset request | unknown/ineligible/eligible | | | mail/token only |

## Credential aftermath

| Event | Old password | Old refresh tokens | Old access | New login required | Evidence |
|---|---|---|---|---|---|
| Logout | | | | | |
| Password change | | | | | |
| Password reset | | | | | |
| Identity change | | | | | |

## Email policy

- Development backend:
- Test backend:
- From address shape:
- Trusted frontend URL source:
- Link paths:
- Send timing/on-commit:
- Failure/retry behavior:
- Old-email notification:

## Throttle policy

| Endpoint | Burst | Sustained | Client key | 429 body | Retry-After | Known limitation |
|---|---|---|---|---|---|---|
| | | | | | | |

