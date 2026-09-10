# Threat checklist недели 13

Статус: **заполняется до кода и уточняется по фактическим tests**.

Это учебная структурированная проверка, а не заявление о полном security audit.

## Assets и границы доверия

| Asset | Где появляется | Где хранится | Кто может видеть | Что запрещено |
|---|---|---|---|---|
| Raw password | request memory | нигде | password API | log/email/DB |
| Password hash | User row | DB | auth system/admin policy | API/log |
| Action raw secret | email/request memory | нигде | mailbox/token holder | DB/log/schema |
| Action digest | token row | DB | service/admin policy | public API |
| Access JWT | client/request memory | client | bearer | log/schema example |
| Refresh JWT | client/request/blacklist metadata | client + jti metadata | refresh holder | log |
| Signing key | environment | secret storage | server only | Git/schema/log |
| Pending email/login | change request row | DB | account service | public enumeration |

## Threats, controls и evidence

| Flow/asset | Abuse or failure | Impact | Preventive control | Detection/evidence | Residual limitation | Status |
|---|---|---|---|---|---|---|
| Registration | privilege field injection | staff account | explicit fields/service defaults | API test | | |
| Registration | duplicate race | duplicate identity | DB uniqueness/transaction | conflict test | | |
| Password | raw storage/logging | account compromise | Django hash/redaction | DB/log test | | |
| Verify | token guessing | account takeover | high entropy + TTL | modified-token test | | |
| Verify | token replay | repeated transition | used state + lock | replay/race test | | |
| Action tokens | cross-purpose use | unauthorized action | purpose binding | wrong-purpose test | | |
| Email link | Host poisoning | token theft | trusted base URL | malicious-host test | | |
| Resend/reset | enumeration | privacy leak | generic HTTP contract | fingerprint test | timing remains | |
| Login | brute force | account compromise | generic error + scopes | 429 tests | not full defense | |
| JWT | mutable identity claim | identity confusion | immutable user ID | claim test | | |
| JWT | token theft | unauthorized access | short TTL/refresh revoke | lifecycle tests | client security later | |
| Refresh | replay | session extension | rotation + blacklist | replay test | concurrency nuance | |
| Logout | false access-revoke promise | stale access | explicit contract/short TTL | aftermath test | | |
| Password reset | replay/race | account takeover | token lock/consume | concurrent test | | |
| Identity change | conflict race | wrong identity | recheck + DB unique | conflict test | | |
| Identity change | unauthorized request | account takeover | access + current password | negative test | stolen both factors | |
| Email delivery | send before rollback | invalid live link | on-commit | callback test | post-commit failure | |
| Logs/schema | secret leakage | credential exposure | redaction/placeholders | scan test | external tooling | |
| Throttle | non-atomic cache | extra requests | documented layers | test/docs | built-in fuzziness | |
| Proxy/IP | spoof/misidentification | bypass/false block | deployment config later | documented | topology unknown | |

## Failure/rollback matrix

| Flow | Failure point | DB state expected | Email expected | Token/session expected | Test |
|---|---|---|---|---|---|
| Registration | before commit | | | | |
| Registration | mail after commit | | | | |
| Verify | after user update/before token use | | | | |
| Password reset | after set_password | | | | |
| Identity confirm | after email before login field | | | | |
| Logout/refresh | blacklist failure | | | | |

## Known limitations handed to later weeks

- Full RBAC/object permissions:
- Production mail retries/Celery:
- Redis/shared atomic rate limiting:
- Trusted proxy/WAF/DDoS:
- Browser token storage/cookie/CSRF:
- MFA/social/OIDC:
- JWT key rotation/JWKS:

## Итог

- Незакрытые critical threats:
- Accepted limitations and why:
- Additional tests required:
- Ready for mentor review:

