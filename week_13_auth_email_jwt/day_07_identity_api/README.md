# Итоговый проект недели 13: identity API

Статус: **заготовка наставника; реализация заблокирована до зачёта дней 1–6**.

Ученик переносит сюда только принятый проект недели 12 после явного допуска. Готовая реализация заранее не предоставляется.

## Цель

Добавить к DRF API безопасный account lifecycle:

- registration и email verification/resend;
- JWT login, refresh rotation, blacklist и logout;
- protected `me`;
- authenticated password change;
- password reset request/confirm;
- подтверждаемую смену email/login;
- scoped throttling;
- safe emails, logs, errors и OpenAPI.

Полное ТЗ, девять вертикальных срезов, 42 сценария и вопросы защиты находятся в `../PRACTICE.md`, день 7.

## Source и environment

- Source week 12 branch/commit:
- Current branch/commit:
- Python version:
- Django version:
- DRF version:
- SimpleJWT version:
- Dependency file:
- Settings module:
- Database purpose без DSN/password:
- Test email backend:
- Test cache backend/alias:
- Frontend base URL shape без production domain:
- JWT signing key source без value:

## Compatibility decision

| Component | Version | Official evidence | Compatibility result | Risk/decision |
|---|---|---|---|---|
| Python | | | | |
| Django | | | | |
| DRF | | | | |
| SimpleJWT | | | | |

## Проверенный быстрый старт

Заполняйте только фактически выполненными командами:

```text
1. Создание/активация virtual environment:
2. Установка locked dependencies:
3. Настройка environment без secret values в README:
4. Запуск isolated PostgreSQL prerequisites:
5. Checks/migrations:
6. Tests:
7. OpenAPI validation:
8. Development server с console email backend:
```

## API groups

| Method | Path | Actor | Назначение |
|---|---|---|---|
| POST | `/api/v1/auth/register/` | anonymous | active-unverified account |
| POST | `/api/v1/auth/email/verify/` | token holder | подтвердить текущий email |
| POST | `/api/v1/auth/email/resend/` | anonymous | generic resend request |
| POST | `/api/v1/auth/token/` | anonymous | verified credentials → pair |
| POST | `/api/v1/auth/token/refresh/` | refresh holder | rotated pair |
| POST | `/api/v1/auth/token/logout/` | refresh holder | blacklist refresh |
| GET | `/api/v1/auth/me/` | valid access | safe account summary |
| POST | `/api/v1/auth/password/change/` | valid access | current proof + new password |
| POST | `/api/v1/auth/password/reset/request/` | anonymous | generic reset request |
| POST | `/api/v1/auth/password/reset/confirm/` | token holder | single-use reset |
| POST | `/api/v1/auth/identity/change/request/` | valid access | pending new email/login |
| POST | `/api/v1/auth/identity/change/confirm/` | token holder | atomic identity update |

Точные fields/status/error/session effects — в `AUTH_CONTRACT.md`.

## Security boundaries

- Raw password существует только в request memory и передаётся Django password API.
- Raw action secret существует при issue/consume, но не сохраняется.
- Raw JWT существует у client/test request, но не логируется.
- Service владеет transaction/state transition.
- Email service владеет trusted link/render/send, но не меняет account.
- SimpleJWT владеет JWT parsing/signature/type/expiry/blacklist.
- DRF throttle — basic rate policy, не полная anti-abuse система.

## Проверка готовности

- [ ] `AUTH_CONTRACT.md` заполнен фактическими rules.
- [ ] `THREAT_CHECKLIST.md` содержит controls, evidence и limitations.
- [ ] `OPENAPI_AUDIT.md` не имеет незакрытого mismatch.
- [ ] Все 42 строки `TEST_MATRIX.md` имеют actual result.
- [ ] Clean install/migrations/tests/schema проходят.
- [ ] Email/cache/database полностью isolated в tests.
- [ ] No raw credentials/tokens/signing key/DSN в Git/log/schema.
- [ ] Ограничения честно перечислены ниже.

## Известные ограничения

- DRF throttling не гарантирует точный concurrent limit.
- Logout blacklists refresh; access behavior:
- Email delivery синхронна после commit; retry policy:
- Browser cookie/token storage не реализованы:
- MFA/social login отсутствуют:
- Production SMTP/Redis/proxy/WAF будут позже:
-

## Самооценка

- Что реализовано самостоятельно:
- Самая полезная security-ошибка:
- Как доказана single-use:
- Как доказано отсутствие secret leakage:
- Что нужно усилить перед неделей 14:

