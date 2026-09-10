# Неделя 13: пользователи, email-процессы и JWT

Статус: **подготовлена заранее и заблокирована до полного зачёта недели 12**.

На этой неделе DRF API получает жизненный цикл учётной записи: регистрация, подтверждение email, вход по JWT, обновление и отзыв refresh token, смена и сброс пароля, а также изменение email/логина только после подтверждения нового адреса.

Это security-sensitive модуль. Цель — не просто получить два JWT, а уметь объяснить состояния пользователя, срок жизни и одноразовость ссылок, защиту паролей, отзыв сессий, одинаковые ответы против enumeration и ограничения встроенного throttling.

## Результат недели

После завершения ученик умеет:

- отличать identity, authentication и authorization;
- объяснить назначение `is_active` и отдельного `is_email_verified`;
- использовать `get_user_model()` и не импортировать concrete user model в прикладном коде;
- создавать пользователя только через manager/`set_password()`, не сохраняя raw password;
- вызывать Django password validators из API;
- проектировать account state machine до написания endpoints;
- отправлять письма через Django email backend и проверять test outbox;
- строить ссылки из доверенного frontend base URL, а не из произвольного `Host` request;
- генерировать криптографически случайный action token;
- хранить только digest verification/reset/change token;
- разделять verification, password-reset и email-change tokens по purpose;
- проверять expiry, used/revoked state и single-use atomically;
- не использовать email action token как JWT access token;
- подключать SimpleJWT только после проверки version compatibility;
- отличать access token от refresh token;
- использовать неизменяемый user ID в claim вместо изменяемого email/login;
- выбирать короткий access lifetime и ограниченный refresh lifetime;
- включать refresh rotation и blacklist с понятной семантикой;
- запрещать login/refresh для inactive и неподтверждённого пользователя;
- реализовывать logout как отзыв переданного refresh token;
- объяснить, почему уже выданный stateless access token обычно живёт до expiry;
- делать password reset request без раскрытия существования email;
- требовать текущий пароль для authenticated password/email change;
- менять email/login только при успешном подтверждении нового адреса;
- отзывать refresh sessions после чувствительного изменения credentials/identity;
- задавать scoped throttles для login/register/resend/reset/change flows;
- понимать, что DRF throttling не является точной защитой от brute force/DoS;
- документировать auth endpoints в OpenAPI без реальных tokens/passwords;
- тестировать happy path, replay, expiry, race, enumeration, mail и JWT lifecycle.

## Предварительные требования

- Недели 0–12 завершены полностью.
- Все дни недели 12 имеют минимум 7/10.
- Итоговый DRF API недели 12 принят минимум на 8/10.
- Public/staff permission boundary и единый error envelope приняты.
- OpenAPI совпадает с runtime.
- В `week_12_django_rest_framework/ASSESSMENT.md` указано: «Допуск к неделе 13: да».

## Версии и activation gate

Проект продолжает использовать принятые Python, Django, DRF и PostgreSQL. Новая direct dependency — `djangorestframework-simplejwt`.

Точную версию заранее не фиксировать. Перед активацией нужно проверить одновременно:

1. последний stable release SimpleJWT;
2. его заявленную поддержку фактических Django/DRF/Python;
3. release notes и security fixes;
4. совместимость blacklist migrations;
5. clean dependency resolution;
6. imports, Django checks, migrations и минимальный JWT smoke test.

Причина особой проверки: stable documentation и master metadata проекта могут обновляться не синхронно. «У меня импортируется» недостаточно для заявления о поддерживаемой комбинации.

Зависимости не устанавливаются при подготовке этого модуля. Не обновлять Django, DRF и SimpleJWT одновременно без отдельного compatibility plan.

## Продолжение проекта недели 12

После допуска переносится принятый проект:

```text
week_12_django_rest_framework/day_07_drf_api/
```

в:

```text
week_13_auth_email_jwt/day_07_identity_api/
```

Source branch/commit, database target и green baseline фиксируются в `day_01_identity_contract.md`. Неделя 12 не переписывается задним числом.

## Модель состояния пользователя

`is_active` и `is_email_verified` означают разные вещи:

| Состояние | `is_active` | `is_email_verified` | Login/refresh | Действия |
|---|---:|---:|---|---|
| Новый | Да | Нет | Запрещены | подтвердить/resend |
| Подтверждён | Да | Да | Разрешены | обычная работа |
| Заблокирован | Нет | любое | Запрещены | только admin policy |
| Ожидает новый email | Да | Да | по выбранной policy | старый email остаётся текущим |

Регистрация не должна превращать `is_active` в неоднозначный флаг. Пока новый email не подтверждён, текущий email/login не изменяются.

## Модель action token

На неделе используется одна таблица или несколько узких моделей с одинаковыми свойствами:

```text
AccountActionToken
├── id/public selector
├── user_id
├── purpose: verify_email | reset_password | change_email
├── token_digest
├── payload: только минимально необходимые pending values
├── expires_at
├── used_at
├── revoked_at
├── created_at
└── request metadata: только если обосновано и безопасно
```

В письмо попадает raw random token. В database хранится только digest. В логах, exception details, analytics и Git token отсутствует.

Обязательные свойства:

- purpose separation;
- короткий TTL по настройке;
- одноразовость;
- предыдущие активные tokens того же purpose отзываются при resend/new request;
- consumption выполняется в `transaction.atomic()` с блокировкой нужных rows;
- user state проверяется повторно внутри transaction;
- invalid/expired/used/revoked token не меняет state;
- response не объясняет атакующему, какая именно часть token неверна.

Для password reset допустимо обоснованно использовать встроенный `PasswordResetTokenGenerator`. Но ученик всё равно должен объяснить, чем его state-bound token отличается от database-backed digest token. Итоговый проект выбирает один подход и не смешивает два reset protocol.

## API surface недели

Точные names/statuses фиксируются в `day_07_identity_api/AUTH_CONTRACT.md`.

```text
POST /api/v1/auth/register/
POST /api/v1/auth/email/verify/
POST /api/v1/auth/email/resend/

POST /api/v1/auth/token/
POST /api/v1/auth/token/refresh/
POST /api/v1/auth/token/logout/

POST /api/v1/auth/password/change/
POST /api/v1/auth/password/reset/request/
POST /api/v1/auth/password/reset/confirm/

POST /api/v1/auth/identity/change/request/
POST /api/v1/auth/identity/change/confirm/

GET  /api/v1/auth/me/
```

`me` требует valid access token и возвращает только безопасные public-account fields.

## Жизненные циклы

### Регистрация и подтверждение

```text
register
  -> user(active, unverified)
  -> create hashed verify token
  -> send link to current email
  -> verify once before expiry
  -> user(active, verified)
  -> login allowed
```

### JWT

```text
verified credentials
  -> access + refresh
  -> access proves authentication briefly
  -> refresh rotates to new refresh + access
  -> old refresh blacklisted
  -> logout blacklists current refresh
```

### Password reset

```text
generic reset request response
  -> existing eligible account receives email
  -> confirm token + new password
  -> password validators
  -> atomic single-use consumption
  -> refresh sessions revoked
  -> re-login required
```

### Email/login change

```text
authenticated user + current password + new identity
  -> pending request; current identity unchanged
  -> link sent to new email
  -> atomic confirmation
  -> uniqueness rechecked
  -> email/login changed together
  -> refresh sessions revoked; re-login required
```

## JWT policy недели

- Access и refresh — разные token types.
- Access передаётся как `Authorization: Bearer <token>`.
- Refresh используется только на refresh/logout boundary.
- `USER_ID_FIELD` — стабильный immutable ID, не email/login.
- Claims минимальны: не включать password hash, secret, balance, supplier data и mutable permissions snapshot без причины.
- Access lifetime короткий; refresh lifetime длиннее, но конечный.
- `ROTATE_REFRESH_TOKENS=True` и `BLACKLIST_AFTER_ROTATION=True`, если выбранная совместимая версия/blacklist app это поддерживает.
- `UPDATE_LAST_LOGIN=False` по умолчанию; если включается, нужны причина и throttle/load test.
- JWT signing key приходит из environment и отделён от Django `SECRET_KEY`, если конфигурация это позволяет.
- Token values никогда не печатаются целиком в test report/log.
- Logout отзывает refresh, но не обещает мгновенно отозвать уже выданный stateless access token.

В учебном API refresh передаётся JSON body. Для браузерного production-клиента отдельно сравниваются in-memory/local storage и `HttpOnly Secure SameSite` cookie с CSRF-политикой; реализация cookie transport не обязательна на этой неделе.

## Password policy

- Пароль никогда не сохраняется прямым присваиванием `user.password = raw`.
- Используются `create_user()`/`set_password()`.
- Перед регистрацией/change/reset вызывается `validate_password(password, user=...)`.
- Полный raw password не попадает в logs, email, errors, fixtures и snapshots.
- Change password требует authenticated user и правильный current password.
- Reset password не требует старый пароль, но требует valid одноразовый token.
- После change/reset старый пароль не проходит login.
- Политика отзыва refresh sessions после изменения пароля явно проверяется.

## Email policy

- Development: console backend, если вывод token контролируется локально.
- Tests: locmem backend и `mail.outbox`.
- Production SMTP/provider не подключается на этой неделе.
- `DEFAULT_FROM_EMAIL` и frontend base URL задаются settings/environment.
- Confirmation URL строится из доверенного frontend base URL, не из request `Host`/`X-Forwarded-Host`.
- В subject нет newline; email text не раскрывает пароль или другую private информацию.
- Ошибка отправки и rollback/ retry policy явно выбраны. Celery появится позже, поэтому синхронная отправка является учебным ограничением.

## Enumeration и ответы

Для login ответ не различает «нет пользователя», «неверный пароль» и «email не подтверждён» подробностями, полезными атакующему. Для reset/resend внешний response одинаков для существующего и неизвестного email.

Это не гарантирует одинаковое время до наносекунды. Фактический timing, доставка почты, throttling и инфраструктура рассматриваются как отдельные слои защиты.

## Throttling

Чувствительные endpoints получают отдельные scopes, например:

- `register`;
- `login_burst` и `login_sustained`;
- `verify_resend`;
- `password_reset`;
- `identity_change`.

Точные rates не объявляются «безопасными навсегда»: они являются testable product policy. Built-in DRF throttle использует Django cache, допускает race/fuzziness и не является полноценной защитой от brute force или DoS.

До Redis используется test/locmem cache. Production shared-cache/proxy policy появится позже. `NUM_PROXIES`/trusted proxy handling нельзя угадывать без deployment topology.

## Архитектурные границы

| Компонент | Обязанность | Не должен делать |
|---|---|---|
| serializer | shape и validation HTTP input | отправлять письмо и управлять transaction |
| API view | auth/throttle/orchestration | хранить raw token или business state machine |
| account service | atomic state transition, token issue/consume | формировать DRF Response |
| token utility/model | generation, digest, purpose, TTL, state | решать permissions других доменов |
| email service/template | render/send message | менять user state |
| SimpleJWT | access/refresh authentication lifecycle | заменять email verification/reset token |
| database | uniqueness, FK и final concurrency integrity | сообщать наружу sensitive conflict details |
| throttle | ограничивать частоту по policy | считаться точной anti-brute-force/DoS защитой |

## Структура модуля

- [THEORY.md](THEORY.md) — identity states, passwords, action tokens, email, JWT и throttling;
- [PRACTICE.md](PRACTICE.md) — семь подробных дней;
- [ASSESSMENT.md](ASSESSMENT.md) — оценки, ошибки, пересдачи и допуск;
- [notes.md](notes.md) — личные объяснения и вопросы;
- `day_01_identity_contract.md` — state/threat/version/baseline audit;
- `day_02_registration_verification.md` — registration и verify/resend;
- `day_03_jwt_lifecycle.md` — login/access/refresh/logout;
- `day_04_password_flows.md` — change/reset/revocation;
- `day_05_identity_change.md` — подтверждаемая смена email/login;
- `day_06_throttling_security.md` — throttles, enumeration, OpenAPI и security tests;
- `day_07_identity_api/` — накопительный итоговый проект;
- `day_07_identity_api/AUTH_CONTRACT.md` — endpoints/states/errors;
- `day_07_identity_api/THREAT_CHECKLIST.md` — assets/abuse/controls;
- `day_07_identity_api/OPENAPI_AUDIT.md` — runtime↔schema;
- `day_07_identity_api/TEST_MATRIX.md` — 42 итоговых сценария.

## Целевое дерево изменений

```text
day_07_identity_api/
├── manage.py
├── README.md
├── AUTH_CONTRACT.md
├── THREAT_CHECKLIST.md
├── OPENAPI_AUDIT.md
├── TEST_MATRIX.md
├── config/
│   ├── settings/
│   └── api_urls.py
├── common/
│   └── api/
│       ├── exceptions.py
│       └── throttles.py
├── accounts/
│   ├── models.py
│   ├── managers.py
│   ├── services.py
│   ├── tokens.py
│   ├── emails.py
│   ├── migrations/
│   ├── templates/accounts/email/
│   ├── api/
│   │   ├── serializers.py
│   │   ├── views.py
│   │   └── urls.py
│   └── tests/
│       ├── test_registration.py
│       ├── test_email_verification.py
│       ├── test_jwt.py
│       ├── test_passwords.py
│       ├── test_identity_change.py
│       ├── test_throttling.py
│       └── test_auth_schema.py
└── остальные принятые apps недели 12/
```

Структуру можно адаптировать к принятому проекту. Не создавать абстракцию ради одного вызова, но не смешивать API, token storage, email rendering и state transition.

## Порядок прохождения

1. Получить допуск недели 12.
2. Зафиксировать source, database и green baseline.
3. Проверить совместимость SimpleJWT до установки.
4. Прочитать теорию только текущего дня.
5. Записать predictions до запуска.
6. Реализовать один маленький vertical slice и tests.
7. После каждого дня запускать regressions недель 11–12.
8. Заполнить журнал и самооценку.
9. Написать: `Проверь день N недели 13`.
10. Самостоятельно исправить обязательные замечания.

## Границы недели

На неделе 13 не требуются:

- social/OAuth/OIDC login;
- MFA/TOTP/WebAuthn;
- full RBAC/ABAC/PBAC и object permissions недели 14;
- frontend UI;
- production SMTP provider;
- Celery email delivery/retries;
- Redis distributed throttling;
- device/session management UI;
- refresh token cookie transport;
- asymmetric JWT/JWKS/key rotation implementation;
- password history/custom breached-password provider;
- CAPTCHA/WAF/CDN/DDoS platform integration;
- invitation flow;
- account deletion/export;
- magic-link passwordless login;
- implementation собственного JWT algorithm.

Эти темы не отвергаются — они вынесены за границу текущего блока.

## Критические ошибки

- raw password сохраняется или логируется;
- password validators не вызываются из API flow;
- raw action token хранится в database/log/assessment;
- один purpose token принимается другим endpoint;
- expired/used/revoked token меняет account state;
- два concurrent confirm успешно используют один token;
- email/login меняется до подтверждения нового адреса;
- confirmation URL строится из недоверенного request Host;
- login/refresh доступен inactive или unverified user;
- JWT user claim основан на изменяемом email/login;
- JWT signing secret находится в Git/schema/log;
- refresh rotation не отзывает старый refresh по заявленному contract;
- logout обещает мгновенный отзыв stateless access без реализации;
- password reset раскрывает существование email через body/status;
- password change/reset не отзывает refresh sessions по принятой policy;
- sensitive endpoint не имеет throttle tests;
- throttle объявляется полной security-защитой;
- tests отправляют real email или используют shared/production database;
- OpenAPI содержит реальные token/password examples;
- expected result записан как actual без выполнения.

## Критерий завершения

- дни 1–6 приняты минимум на 7/10;
- итоговый проект принят минимум на 8/10;
- state machine и threat checklist объяснимы;
- registration использует password validation и hashing;
- verify/resend tokens purpose-bound, expiring, hashed и single-use;
- verified active user получает JWT pair;
- inactive/unverified/invalid login имеет безопасный отказ;
- refresh rotates, old token blacklisted, logout отзывает refresh;
- protected `me` endpoint работает только с valid access;
- password change/reset корректны и отзывают refresh sessions;
- reset request не раскрывает наличие account;
- email/login изменяются только после new-email confirmation;
- sensitive endpoints имеют scoped throttles и 429/Retry-After tests;
- emails проверены через locmem outbox;
- security logs не содержат secrets;
- OpenAPI совпадает с runtime;
- regressions недель 11–12 green;
- clean migrations/setup воспроизводимы;
- `TEST_MATRIX.md` содержит actual results 42 сценариев;
- минимум 32 из 42 вопросов защиты отвечены уверенно;
- в `ASSESSMENT.md` указано: «Допуск к неделе 14: да».

## Официальные материалы

- [Django: Password management](https://docs.djangoproject.com/en/5.2/topics/auth/passwords/)
- [Django: Authentication system and password reset](https://docs.djangoproject.com/en/5.2/topics/auth/default/)
- [Django: Sending email](https://docs.djangoproject.com/en/5.2/topics/email/)
- [Django: Cryptographic signing](https://docs.djangoproject.com/en/5.2/topics/signing/)
- [DRF: Authentication](https://www.django-rest-framework.org/api-guide/authentication/)
- [DRF: Throttling](https://www.django-rest-framework.org/api-guide/throttling/)
- [SimpleJWT: Getting started](https://django-rest-framework-simplejwt.readthedocs.io/en/stable/getting_started.html)
- [SimpleJWT: Settings](https://django-rest-framework-simplejwt.readthedocs.io/en/stable/settings.html)
- [SimpleJWT: Blacklist app](https://django-rest-framework-simplejwt.readthedocs.io/en/stable/blacklist_app.html)
- [SimpleJWT: Creating tokens manually](https://django-rest-framework-simplejwt.readthedocs.io/en/stable/creating_tokens_manually.html)
- [SimpleJWT releases](https://github.com/jazzband/djangorestframework-simplejwt/releases)

## Текущий статус

Неделя 13 подготовлена заранее. Текущий активный этап остаётся в `week_00_basics/ASSESSMENT.md`: день 2 недели 0. До допуска из недели 12 не переносить проект, не устанавливать SimpleJWT, не создавать migrations и не отправлять письма.
