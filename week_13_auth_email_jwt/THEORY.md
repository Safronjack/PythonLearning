# Теория недели 13: пользователи, email-процессы и JWT

Статус: **читать после допуска из недели 12**.

Главная тема недели — жизненный цикл identity. Мы связываем уже изученные serializers, views, services, transactions, PostgreSQL и OpenAPI, но теперь цена ошибки выше: утечка пароля или token может дать доступ к чужому аккаунту.

## 1. Identity, authentication и authorization

- **Identity** — данные, описывающие учётную запись: ID, email, login, статус.
- **Authentication** — доказательство, кто выполняет запрос: password + JWT, session и т. п.
- **Authorization** — проверка, что этому пользователю разрешено сделать.

Неделя 13 занимается identity и authentication. Полная ролевая/object authorization — неделя 14.

## 2. Почему сначала нужна state machine

Endpoint нельзя проектировать отдельно от состояния пользователя. Например, правильный пароль ещё не означает право получить token: account может быть заблокирован или email не подтверждён.

```text
registered_unverified -> verified -> identity_change_pending -> verified_with_new_identity
             |              |
             v              v
          blocked <------ blocked
```

Для каждого перехода записываются:

- кто может начать действие;
- какие preconditions проверяются;
- какой token выдаётся;
- каков TTL;
- что меняется при success;
- что происходит при expiry/replay/concurrency;
- какие sessions остаются действительными.

## 3. `is_active` и `is_email_verified`

Это разные признаки:

- `is_active=False` означает, что account отключён и не должен authenticate;
- `is_email_verified=False` означает, что адрес ещё не доказан;
- unverified account может быть active как database record, но custom login policy всё равно запрещает выдачу JWT.

Если использовать один `is_active` для двух смыслов, становится трудно отличить нового пользователя от заблокированного администратором.

## 4. Custom user model

Custom user был выбран до первых migrations. Прикладной код получает класс через `get_user_model()`:

```python
from django.contrib.auth import get_user_model

User = get_user_model()
```

В model relations используется `settings.AUTH_USER_MODEL`. Нельзя внезапно менять user model в середине проекта без сложного migration plan.

Проверьте до реализации:

- какое поле является `USERNAME_FIELD`;
- уникален ли нормализованный email/login на database уровне;
- что делает manager `create_user()`;
- есть ли `is_email_verified`;
- какие roles/flags уже существуют;
- какие старые rows получат значение при migration.

## 5. Нормализация email и login

Нормализация должна иметь один owner. Trim пробелов обязателен. Domain email обычно case-insensitive, local part по стандартам сложнее; продукт должен выбрать и последовательно применять policy.

Если проект считает весь email case-insensitive, это нужно закрепить:

- одинаковой normalization в manager/serializer;
- database uniqueness, способной защитить тот же смысл;
- tests для `User@Example.com` и `user@example.com`.

Одна Python-проверка `exists()` не защищает от двух concurrent registrations.

## 6. Как Django хранит пароль

Django хранит salted password hash, а не исходный пароль. Нельзя делать:

```python
user.password = raw_password
user.save()
```

Нужно использовать:

```python
user.set_password(raw_password)
user.save(update_fields=("password",))
```

или корректный `create_user()`. Проверять пароль нужно через `check_password()`/`authenticate()`, а не сравнивать database strings.

## 7. Password validators в API

`create_user()` хеширует пароль, но сам по себе не обязан запускать configured password validators. API должен вызвать:

```python
from django.contrib.auth.password_validation import validate_password

validate_password(raw_password, user=candidate_user)
```

Аргумент `user` важен для validators, сравнивающих password с email/login. Django `ValidationError` нужно преобразовать в DRF field errors, сохранив понятные codes/messages.

Validation применяется в трёх flows:

- registration;
- authenticated password change;
- password reset confirmation.

## 8. Password change и password reset

**Change** выполняет уже authenticated пользователь и должен доказать знание текущего password.

**Reset** предназначен для потерянного password: текущий password не нужен, но нужен одноразовый token из email.

Оба flow:

- проверяют новый пароль validators;
- используют `set_password()`;
- не возвращают raw password;
- определяют policy отзыва refresh sessions;
- требуют повторного login после success по contract недели.

## 9. Почему action token — не access JWT

Verification/reset/change token даёт право выполнить ровно одно действие. Access JWT даёт доступ к множеству protected endpoints до expiry.

Если использовать access JWT для email verification:

- неподтверждённый пользователь уже получает authentication credential;
- purpose становится неясным;
- revoke/single-use сложнее;
- claims и lifetime могут не подходить.

Используйте отдельный protocol и namespace для каждого purpose.

## 10. Entropy и raw token

Raw token должен быть непредсказуемым:

```python
import secrets

raw_secret = secrets.token_urlsafe(32)
```

Не подходят incremental ID, timestamp, email hash или `random.random()`.

Token обычно состоит из public selector и secret:

```text
<public_uuid>.<raw_secret>
```

По public UUID находится candidate row. Secret проверяется по сохранённому digest. Это позволяет не сканировать всю таблицу и не хранить secret.

## 11. Digest action token

Простой вариант для высокоэнтропийного secret:

```python
from hashlib import sha256

digest = sha256(raw_secret.encode("utf-8")).hexdigest()
```

При проверке после выборки row используйте `hmac.compare_digest()`. SHA-256 здесь не заменяет password hasher: token уже имеет высокую entropy и короткий TTL, а human password — обычно нет.

Более защищённый вариант использует keyed HMAC с отдельным server secret. Он требует безопасного управления ключом. На этой неделе достаточно SHA-256 при криптографически случайном secret и строгом no-log policy; отличие нужно понимать.

## 12. Что хранит `AccountActionToken`

Минимальные fields:

- public UUID;
- user foreign key;
- `purpose`;
- `token_digest`;
- `expires_at`;
- `used_at`;
- `revoked_at`;
- timestamps;
- pending payload только для change-email/login.

Не храните raw secret. Не помещайте password в payload. Если payload — JSON, перечислите разрешённые keys и validate их; отдельные typed columns обычно понятнее.

## 13. Purpose separation

Token для `verify_email` не должен подходить к `reset_password`, даже если структура одинакова.

Проверка включает:

```text
public ID exists
AND digest matches
AND purpose matches endpoint
AND used_at is null
AND revoked_at is null
AND expires_at > now
AND user state permits transition
```

Ошибки наружу можно объединить в `invalid_or_expired_token`, чтобы не раскрывать внутреннее состояние.

## 14. TTL и время

Используйте timezone-aware `timezone.now()`. Срок жизни задаётся settings, а не magic number в service.

Граница должна быть выбрана явно: если `expires_at <= now`, token уже недействителен.

В tests не нужно ждать настоящие часы. Передавайте/замораживайте controlled time или создавайте row с нужным `expires_at`.

## 15. Single-use и transaction

Наивная последовательность `if unused: mark used` допускает race: два запроса могут одновременно увидеть unused token.

Корректный flow:

```text
transaction.atomic
  -> select_for_update token row
  -> validate digest/purpose/expiry/state
  -> select_for_update user when state changes
  -> apply transition
  -> set used_at
  -> revoke sibling tokens when required
  -> commit
```

Только один concurrent consumer должен завершиться успехом.

## 16. Resend и несколько tokens

Resend не должен оставлять несколько активных verification links. Service блокирует user, отзывает старые unused tokens данного purpose и создаёт новый.

Старое письмо после resend должно перестать работать. Token другого purpose не отзывается без причины.

## 17. `transaction.on_commit()` и email

Письмо — внешний side effect. Если отправить его внутри database transaction, email нельзя «откатить» после последующей database ошибки.

Практичный учебный flow:

1. в transaction создать/обновить user и token;
2. зарегистрировать send callback через `transaction.on_commit()`;
3. commit database state;
4. отправить email;

Если отправка после commit не удалась, account/token остаются и пользователь может запросить resend. Надёжные async retries через Celery будут позже.

В Django `TestCase` on-commit callbacks требуют специального захвата/выполнения; иначе test может ошибочно решить, что email не отправляется.

## 18. Email backends

- console backend подходит только для local development;
- locmem backend хранит письма в `django.core.mail.outbox` и используется tests;
- production SMTP/provider требует secrets, timeouts, TLS и monitoring — позже.

Test проверяет recipient, subject, безопасный body и число писем. Raw token разрешено извлечь из in-memory письма внутри test process, но нельзя записывать его в journal/snapshot/log.

## 19. Доверенная confirmation URL

Нельзя строить security link из непроверенного request Host. Иначе атакующий может добиться письма со ссылкой на свой домен.

Используйте configured frontend base URL:

```text
FRONTEND_BASE_URL=https://app.example.test
```

К нему добавляется allowlisted path и URL-encoded token. Production требует HTTPS. Тема trusted proxies/allowed hosts не заменяет явный trusted frontend URL.

## 20. Registration flow

Registration serializer принимает только разрешённые поля. Service:

1. нормализует identity;
2. создаёт candidate user для context password validators;
3. вызывает `validate_password()`;
4. в transaction проверяет/защищает uniqueness;
5. создаёт active, unverified user через manager;
6. создаёт verification token;
7. после commit отправляет письмо.

Response не содержит password, raw verification token или JWT. Выдача JWT до подтверждения запрещена.

## 21. Verification flow

Verification endpoint принимает public token string и вызывает service. При success:

- `is_email_verified=True`;
- `used_at` установлен;
- sibling verify tokens отозваны;
- повторный request не повторяет transition;
- token не возвращается.

Уже verified user и replay получают заранее выбранный безопасный response. Важно отличать идемпотентный внешний UX от настоящего повторного использования token: внутри второй consumption не должна считаться успешной.

## 22. Enumeration

Account enumeration — возможность узнать, зарегистрирован ли email/login.

Особенно чувствительны:

- login;
- password reset request;
- verification resend;
- identity change conflict.

Для reset/resend возвращайте одинаковый status и body независимо от существования eligible account. Login error также не должен различать nonexistent user, wrong password и unverified state.

Registration часто сообщает duplicate как продуктовый conflict. Это осознанный trade-off, а не полная защита enumeration. Его нужно записать в threat checklist и ограничить throttle.

## 23. Что такое JWT

JWT обычно состоит из трёх base64url частей:

```text
header.payload.signature
```

Payload **подписан, но обычно не зашифрован**. Клиент может прочитать claims. Поэтому JWT не место для password, secret, balance, адреса или лишних персональных данных.

Signature позволяет обнаружить изменение header/payload при правильной проверке ключа и algorithm. Проверку выполняет библиотека; собственную JWT crypto реализацию писать нельзя.

## 24. Access и refresh tokens

Access token:

- короткий TTL;
- передаётся в Authorization header;
- часто проверяется без database записи о каждой сессии;
- даёт доступ к protected API.

Refresh token:

- более длинный TTL;
- используется только для выпуска новой пары/нового access;
- должен храниться осторожнее;
- может быть tracked/blacklisted по `jti`.

Refresh token нельзя использовать как Bearer access, если token classes настроены корректно.

## 25. Claims

Типичные claims:

- `exp` — expiry;
- `iat` — issued at;
- `jti` — unique token identifier;
- `token_type` — access/refresh;
- `user_id` — стабильный идентификатор.

Email/login могут меняться, поэтому не используйте их как `USER_ID_FIELD`. Custom role claim быстро устаревает и не заменяет database permission check.

## 26. JWT signing key и algorithm

SimpleJWT/PyJWT должны проверять заранее configured algorithm. Не принимайте algorithm из token как доверенное решение application.

При HMAC signing отдельный сильный secret удобнее Django `SECRET_KEY`: его можно вращать независимо. Key находится только в environment/secret manager, не в Git, OpenAPI, logs или examples.

Asymmetric keys, JWKS и полноценная rotation strategy изучаются позже. На этой неделе важно зафиксировать выбранный algorithm и источник ключа.

## 27. Login serializer

Стандартный TokenObtainPair flow нужно адаптировать к custom identity policy. Login проверяет:

- credentials через Django authentication backend;
- `is_active`;
- `is_email_verified`;
- общую безопасную ошибку;
- throttle;
- отсутствие password/token в log.

Если tokens создаются вручную через `RefreshToken.for_user()`, сначала явно проверяются active/verified: этот helper не обязан проверить всю project policy.

## 28. Lifetime, rotation и blacklist

Настройки должны быть осознанными:

- `ACCESS_TOKEN_LIFETIME`;
- `REFRESH_TOKEN_LIFETIME`;
- `ROTATE_REFRESH_TOKENS`;
- `BLACKLIST_AFTER_ROTATION`;
- blacklist app migrations.

При rotation успешный refresh возвращает новый refresh. Старый добавляется в blacklist и при последовательном replay отклоняется.

Встроенные механизмы и database operations могут иметь concurrency nuances. Два почти одновременных refresh requests требуют отдельного test/документированного ограничения; нельзя обещать абсолютную reuse detection без доказательства.

## 29. Logout

Stateless JWT нельзя «стереть» из уже выданного клиента. Logout endpoint принимает refresh token и blacklists его.

После logout:

- этот refresh не выдаёт новый access;
- повторный logout имеет выбранный contract;
- уже выданный access может работать до expiry;
- client должен удалить свои tokens.

Если нужен мгновенный revoke access, требуется дополнительная state/version/denylist policy с runtime lookup. Это не включается автоматически.

## 30. Password change и JWT revocation

После password change/reset нужно отозвать outstanding refresh tokens пользователя. Иначе украденный refresh продолжит выдавать access.

Уже выданный access:

- либо живёт до короткого expiry;
- либо инвалидируется через поддерживаемый `CHECK_REVOKE_TOKEN`/credential-version mechanism.

Выберите один contract и протестируйте. Не заявляйте мгновенный revoke, если проверили только refresh blacklist.

## 31. Password reset request

Request endpoint всегда возвращает одинаковый `202` и generic body. Только eligible active account с usable password получает письмо.

Синхронная email отправка всё равно может дать timing side-channel. На этой неделе фиксируются одинаковый HTTP contract, throttling и известное ограничение; async email появится с Celery.

Resend/new reset request отзывает предыдущий unused reset token по выбранной policy.

## 32. Password reset confirm

Confirm service atomically:

1. блокирует action token/user;
2. проверяет digest/purpose/expiry/state;
3. валидирует новый password с user context;
4. вызывает `set_password()`;
5. помечает token used;
6. отзывает sibling reset tokens и refresh sessions;
7. commit;
8. не выдаёт JWT автоматически.

Replay, expiry, malformed token и weak password не меняют account.

## 33. Authenticated password change

Endpoint требует valid access и поля current/new password. Сначала `user.check_password(current_password)`, затем `validate_password(new, user=user)`.

Сравнение current/new можно сделать product rule, но основное требование — validators и безопасное обновление. Response не повторяет password.

## 34. Смена email и login

Request на изменение identity требует:

- authenticated user;
- current password;
- нормализованный `new_email`;
- `new_login`, если он отдельный;
- проверку формата/предварительной uniqueness;
- creation change token с pending values;
- письмо именно на новый email.

До confirmation user продолжает иметь старый email/login. На confirm uniqueness проверяется снова внутри transaction: другой account мог занять значение между request и confirm.

После success:

- email/login меняются атомарно;
- `is_email_verified` относится уже к новому адресу и остаётся/становится true только в рамках подтверждённого transition;
- token становится used;
- refresh sessions отзываются;
- старый email получает notification без sensitive link — рекомендация;
- re-login использует новый identity.

## 35. Throttling в DRF

DRF throttle проверяется до body view logic и при отказе вызывает `Throttled`, обычно `429 Too Many Requests`. Если `.wait()` известен, response содержит `Retry-After`.

Scopes разделяют policies:

```text
login_burst: короткое окно
login_sustained: длинное окно
password_reset: email/IP policy
verify_resend: email/IP policy
identity_change: authenticated user policy
```

Не используйте email целиком как raw cache key/log label. Нормализуйте и при необходимости хешируйте identifier.

## 36. Ограничения DRF throttling

Встроенные throttles:

- используют Django cache;
- выполняют non-atomic operations;
- могут допустить несколько лишних запросов при concurrency;
- IP identification зависит от proxy settings;
- не защищают от distributed DoS или всех brute-force strategies.

Это basic abuse control и product rate policy. Позже нужны shared Redis, trusted proxy configuration, monitoring, WAF/provider controls и, возможно, custom atomic limiter.

## 37. Тестирование throttling

Test должен использовать отдельный cache namespace/clear и deterministic low rate. Проверяются:

- requests до лимита;
- следующий request — 429;
- `Retry-After`, если доступен;
- разные scopes не загрязняют друг друга;
- разные users/identifiers по contract;
- никакой user/token не создаётся при throttled request.

Не запускайте throttle tests параллельно с общим process cache без isolation.

## 38. OpenAPI для auth endpoints

Schema должна различать:

- registration request/response;
- action-token confirmation input;
- access/refresh pair;
- refresh input/output при rotation;
- logout input;
- password change/reset;
- identity change;
- error envelope и 429.

Examples используют только явно фальшивые placeholders: `example.invalid`, `<access-token>`. Никогда не вставляйте реальный JWT или confirmation link из test output.

## 39. Логирование и audit

Можно логировать:

- event name;
- request/correlation ID;
- internal user ID после безопасной identification;
- purpose;
- outcome category;
- latency;
- throttle scope.

Нельзя логировать:

- raw password;
- Authorization header;
- raw access/refresh/action token;
- полный reset/verification URL;
- SMTP credentials;
- database DSN;
- подробную причину login failure наружу.

Email можно маскировать или заменить internal user ID в зависимости от logging policy.

## 40. Status codes и общий error envelope

Рекомендуемый contract:

- `201` registration resource created;
- `202` reset/resend/change request принят независимо от наличия eligible account;
- `200` login/refresh/me;
- `204` verify/logout/password change/reset confirm/identity confirm;
- `400` malformed/validation/invalid action token по принятой policy;
- `401` invalid/expired access или login credentials;
- `403` authenticated actor без разрешения;
- `409` только если conflict намеренно public;
- `429` throttle.

Ошибки продолжают envelope недели 12. Security endpoint не должен случайно вернуть HTML traceback.

## 41. Типичные ошибки

- `user.password = password`;
- password validators используются только в HTML forms;
- raw tokens лежат в database или debug log;
- verification token является обычным JWT access;
- один token подходит разным purposes;
- expiry сравнивается naive datetime;
- check и consume происходят вне одной transaction;
- resend не отзывает старую ссылку;
- email отправляется до commit без понимания side effects;
- security link строится через request Host;
- JWT payload считается зашифрованным;
- email используется как stable user claim;
- refresh token принимается как Bearer access;
- logout обещает отозвать access мгновенно;
- reset response раскрывает существование email;
- new email присваивается до confirmation;
- uniqueness проверяется только при request, не при confirm;
- throttle считается точным security barrier;
- tests печатают реальные tokens;
- OpenAPI example содержит рабочий credential.

## 42. Вопросы для самопроверки

1. Чем identity отличается от authentication?
2. Почему `is_active` и `is_email_verified` разделены?
3. Почему password нельзя присвоить напрямую?
4. Почему `validate_password()` получает user?
5. Чем change password отличается от reset?
6. Почему action token не является access JWT?
7. Что хранится в database вместо raw action secret?
8. Зачем token purpose?
9. Где проверяется expiry boundary?
10. Почему consume требует `select_for_update()`?
11. Что происходит со старой ссылкой после resend?
12. Зачем `transaction.on_commit()` для email?
13. Почему confirmation URL не строится из request Host?
14. Что такое account enumeration?
15. Почему JWT payload нельзя считать secret?
16. Чем access отличается от refresh?
17. Зачем `jti`?
18. Почему user ID claim не должен быть email?
19. Что делает refresh rotation?
20. Что делает blacklist?
21. Что реально отзывает logout?
22. Что происходит с access после logout?
23. Что нужно отозвать после password reset?
24. Почему identity uniqueness проверяется повторно при confirm?
25. Почему throttling не защищает полностью от brute force?
26. Какие данные запрещены в logs/schema?

## Официальные источники

- [Django: Password management](https://docs.djangoproject.com/en/5.2/topics/auth/passwords/)
- [Django: Authentication and password reset](https://docs.djangoproject.com/en/5.2/topics/auth/default/)
- [Django: Sending email](https://docs.djangoproject.com/en/5.2/topics/email/)
- [Django: Cryptographic signing](https://docs.djangoproject.com/en/5.2/topics/signing/)
- [DRF: Authentication](https://www.django-rest-framework.org/api-guide/authentication/)
- [DRF: Throttling](https://www.django-rest-framework.org/api-guide/throttling/)
- [SimpleJWT: Getting started](https://django-rest-framework-simplejwt.readthedocs.io/en/stable/getting_started.html)
- [SimpleJWT: Settings](https://django-rest-framework-simplejwt.readthedocs.io/en/stable/settings.html)
- [SimpleJWT: Blacklist app](https://django-rest-framework-simplejwt.readthedocs.io/en/stable/blacklist_app.html)
- [SimpleJWT: Manual token creation warning](https://django-rest-framework-simplejwt.readthedocs.io/en/stable/creating_tokens_manually.html)
