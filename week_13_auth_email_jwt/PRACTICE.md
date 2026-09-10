# Практика недели 13: пользователи, email-процессы и JWT

Статус: **заблокирована до полного зачёта недели 12**.

## Общие правила

- Все дни развивают один проект в `day_07_identity_api/`.
- Переносится только принятый проект недели 12; source commit фиксируется до изменений.
- Код пишет и исправляет ученик. Наставник не переписывает решение во время обычной проверки.
- Перед реализацией каждого security flow сначала записываются state transition и abuse cases.
- Raw passwords и любые raw tokens не копируются в journals, logs, snapshots, OpenAPI examples или Git.
- Token в test можно использовать только в памяти процесса; evidence содержит placeholder, digest prefix запрещён тоже без необходимости.
- Password сохраняется только через Django manager/`set_password()` и всегда проходит configured validators.
- Action tokens имеют purpose, TTL, digest и single-use consumption.
- JWT не используется как verification/reset/email-change token.
- Email в tests отправляется только через locmem backend; реальная почта не используется.
- Все database tests выполняются на isolated test PostgreSQL/database configuration.
- Throttling tests изолируют/очищают test cache.
- OpenAPI наследует единый error envelope недели 12 и не содержит рабочих credentials.
- Новая dependency устанавливается только после допуска и compatibility gate.

## Формат security-сценария

```text
Scenario ID:
Purpose/asset:
Initial user/token/session state:
Actor and credentials (только placeholders):
Method/path/input shape:
Prediction: status, public body/code, email count, DB transition, token/session effect
Actual status/body shape:
Actual email count/recipient:
Actual DB transition:
Actual old/new token behavior:
Log/throttle evidence without secrets:
Explanation:
Correction or next check:
```

## Самооценка дня

1. Какое состояние существовало до запроса и какое получилось после?
2. Какой компонент владеет переходом?
3. Какие secrets могли утечь и как я это проверил?
4. Какой positive, boundary, replay и abuse scenario я запустил?
5. Что test доказал, а что осталось предположением?
6. Какая ошибка была самой полезной?
7. Что осталось непонятным?
8. Сколько времени заняла работа?

## Шкала обычного дня

| Критерий | Баллы |
|---|---:|
| Корректность результата | 0–3 |
| Выполнение условий | 0–2 |
| Граничные, replay и ошибочные сценарии | 0–2 |
| Читаемость и security boundaries | 0–1 |
| Понимание и самооценка | 0–1 |
| Самостоятельность исправлений | 0–1 |

Обычный день принят при 7/10 без критической ошибки. Итоговый проект принят при 8/10.

---

# День 1. Контракт identity и безопасные action tokens

## Документация

- [Django: Cryptographic signing](https://docs.djangoproject.com/en/5.2/topics/signing/) — подпись, срок жизни и проверка action tokens.
- [Модуль `secrets`](https://docs.python.org/3/library/secrets.html) — криптографически стойкие случайные значения.

## Паспорт задания

- **Цель:** построить state/threat contract и database foundation для одноразовых account actions до создания публичных endpoints.
- **Рабочий файл или каталог:** models/services/migrations/tests в `day_07_identity_api/`; документы — `day_07_identity_api/AUTH_CONTRACT.md`, `day_07_identity_api/THREAT_CHECKLIST.md`; журнал — `day_01_identity_contract.md`.
- **Результат:** source/version/baseline audit, карта существующего User, state machine, action-token model с purpose/digest/TTL/use/revoke и clean migration.
- **Порядок выполнения:** подтвердить допуск; перенести проект; проверить database; запустить baseline; сверить dependency compatibility без установки наугад; проаудировать User; описать states/transitions/threats; спроектировать token model; создать migration; проверить generation/digest/expiry/constraints.
- **Наблюдаемый результат:** schema хранит только token digest, migrations воспроизводимы, а документы однозначно показывают разрешённые переходы и запрещённые утечки.
- **Готово, если:** source/baseline честны; compatibility decision записан; `is_active`/`is_email_verified` разделены; каждый flow имеет state transition; threat checklist заполнен; raw token отсутствует в DB/log; migration replay green; 10 сценариев записаны.
- **Пример:** `registered_unverified + valid verify token -> verified`, а `blocked + valid verify token -> no state change`.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–10. **Рекомендация:** небольшая state diagram после текстовой таблицы.

## Теория

Прочитайте разделы 1–5 и 9–16, 39–41 `THEORY.md`.

## Задание 1. Активация и безопасный перенос

- **Исходные данные:** явный допуск недели 12, accepted branch/commit, dependency file и working tree.
- **Действие:** перенесите проект в `day_07_identity_api/`, запишите source и убедитесь, что `.env`, database dump, tokens и mail files не копируются.
- **Результат:** week 12 остаётся неизменной, week 13 имеет известное происхождение.
- **Проверить:** accepted source; dirty source; missing approval; secret-like files; повторный перенос.

## Задание 2. Database и baseline

- **Исходные данные:** settings/test settings и suite недель 11–12.
- **Действие:** зафиксируйте безопасные vendor/database-purpose values без DSN/password; запустите checks, migration plan/drift и полный regression suite.
- **Результат:** до auth-изменений известен фактический green/red baseline.
- **Проверить:** green; старая failure; unapplied migration; accidental SQLite; shared/production-like target — остановка.

## Задание 3. Compatibility gate SimpleJWT

- **Исходные данные:** фактические Python/Django/DRF versions, stable SimpleJWT docs/release metadata и dependency resolver.
- **Действие:** заполните `package | installed | candidate | officially supported evidence | risk | decision`; устанавливайте exact version только после допуска и принятого решения.
- **Результат:** выбранная combination обоснована, imports/checks/minimal smoke проходят либо работа остановлена до совместимого решения.
- **Проверить:** supported combination; docs/master mismatch; resolver conflict; blacklist migrations; clean reinstall.

## Задание 4. Audit User model

- **Исходные данные:** custom User, manager, migrations, admin и existing test rows.
- **Действие:** заполните `field | meaning | mutable | unique | normalized by | public | JWT claim`; проверьте `USERNAME_FIELD`, `create_user()` и `get_user_model()` usage.
- **Результат:** необходимые изменения schema перечислены до migration; email/login semantics не противоречат старым данным.
- **Проверить:** new/verified/blocked users; case variants; empty email; duplicate; direct concrete User import.

## Задание 5. State-transition table

- **Исходные данные:** register, verify, resend, login, refresh, logout, password change/reset и identity change flows.
- **Действие:** заполните `initial state | actor | input proof | transition | tokens revoked/issued | email | errors`.
- **Результат:** запрещённые переходы видны до implementation.
- **Проверить:** unverified; verified; blocked; pending change; expired/replayed token; two concurrent confirms.

## Задание 6. Threat checklist

- **Исходные данные:** assets user/password/email/tokens, actors anonymous/user/staff и entry points.
- **Действие:** для каждого flow запишите abuse case, observable impact, control и test; не называйте throttle единственной защитой.
- **Результат:** есть testable threats: enumeration, token theft/replay, host poisoning, brute force, race и log leakage.
- **Проверить:** each asset; compromised email; guessed token; malicious Host; concurrent consume; debug logs.

## Задание 7. Action-token model и migration

- **Исходные данные:** target fields purpose/public UUID/digest/expires/used/revoked/user/pending identity.
- **Действие:** создайте минимальную model/constraints/indexes, migration и migration rationale; raw secret field запрещён.
- **Результат:** database поддерживает lookup/state/history и не хранит usable secret.
- **Проверить:** each purpose; duplicate public UUID; invalid purpose; nullable timestamps; deletion policy; migration forward/replay.

## Задание 8. Token primitive tests

- **Исходные данные:** controlled time, random raw secrets и token rows.
- **Действие:** реализуйте generation, SHA-256 digest, safe assembly/parsing public-id+secret и compare; пока не меняйте User state.
- **Результат:** valid secret matches, modified/malformed/expired data отклоняются без secret logging.
- **Проверить:** normal; one-character mutation; missing separator; invalid UUID; empty secret; exact expiry boundary; no raw value in DB/repr/log.

## Обязательные сценарии дня

1. Week 12 baseline green до изменений.
2. Database target безопасно подтверждена.
3. Version compatibility имеет официальное evidence и решение.
4. New user state описано отдельно от blocked state.
5. Каждый account flow имеет owner и transition.
6. Action row хранит digest, не raw secret.
7. Token purposes различаются constraint/enum.
8. Modified/malformed secret не проходит compare.
9. `expires_at == now` считается expired по contract.
10. Clean migration replay и regressions green.

## Контрольные вопросы

1. Чем identity отличается от authentication?
2. Почему `is_active` не заменяет `is_email_verified`?
3. Почему raw action token нельзя хранить в database?
4. Зачем public selector отделён от secret?
5. Зачем token purpose?
6. Почему single-use требует transaction/lock?

---

# День 2. Регистрация, письмо и подтверждение email

## Документация

- [Django: Sending email](https://docs.djangoproject.com/en/5.2/topics/email/) — формирование и отправка писем через email backend.
- [Django: Password management](https://docs.djangoproject.com/en/5.2/topics/auth/passwords/) — безопасное хеширование и проверка паролей.

## Паспорт задания

- **Цель:** реализовать регистрацию и single-use подтверждение email без выдачи JWT до verification.
- **Рабочий файл или каталог:** accounts services/emails/templates/API/tests в `day_07_identity_api/`; журнал — `day_02_registration_verification.md`.
- **Результат:** `/register/`, `/email/verify/`, `/email/resend/`, password validation, trusted confirmation URL и locmem mail tests.
- **Порядок выполнения:** зафиксировать contracts; настроить safe email backends/base URL; сделать registration serializer/service; вызвать password validators; создать verify token; отправить on-commit email; реализовать atomic confirm; реализовать generic resend; проверить uniqueness/replay/expiry/concurrency/mail/logs.
- **Наблюдаемый результат:** valid registration создаёт active-unverified user и одно письмо; JWT ещё нет; valid link подтверждает один раз; resend отзывает старую ссылку.
- **Готово, если:** password hashed/validated; response не содержит secrets; mail URL trusted; verification atomic/single-use; resend generic; blocked/expired/replay не меняют state; email tests изолированы; 12 сценариев записаны.
- **Пример:** `POST /api/v1/auth/register/` возвращает 201 с безопасным user summary, а token существует только внутри тестового письма.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–12. **Рекомендация:** уведомление security event в структурированном log без email/token.

## Теория

Прочитайте разделы 6–7, 17–22 и 39–41 `THEORY.md`.

## Задание 1. Endpoint и response contracts

- **Исходные данные:** target paths и error envelope недели 12.
- **Действие:** заполните registration/verify/resend rows в `AUTH_CONTRACT.md`: fields, status, email effect, DB transition и safe errors.
- **Результат:** client contract не раскрывает password/token и не обещает JWT.
- **Проверить:** valid/invalid register; duplicate; valid/invalid verify; resend known/unknown/already verified.

## Задание 2. Email settings и template

- **Исходные данные:** console development backend, locmem tests, `DEFAULT_FROM_EMAIL` и trusted `FRONTEND_BASE_URL`.
- **Действие:** настройте environment-specific email backend; создайте plain-text subject/body template и link builder, игнорирующий request Host.
- **Результат:** test outbox получает одно безопасное письмо на нужный адрес; host injection не меняет link domain.
- **Проверить:** normal URL; frontend base with trailing slash; malicious Host/X-Forwarded-Host; subject newline; example.invalid test address.

## Задание 3. Registration serializer

- **Исходные данные:** email/login, password/password confirmation и разрешённые profile fields.
- **Действие:** задайте explicit write-only password fields, normalization и matching validation; не принимайте role/is_staff/is_active/is_verified от клиента.
- **Результат:** valid input даёт `validated_data`, privilege/internal fields игнорируются или отклоняются по contract.
- **Проверить:** valid; mismatch; missing; malformed email; whitespace/case; attempted `is_staff=true`; unknown field.

## Задание 4. Registration service

- **Исходные данные:** validated input, User manager и configured password validators.
- **Действие:** валидируйте password с candidate user context; atomically создайте active-unverified user через manager и verify token; mail назначьте через on-commit.
- **Результат:** password hash проверяется `check_password()`, raw отсутствует; после commit отправлено одно письмо.
- **Проверить:** valid; weak/common/numeric/similar password; normalized duplicate; database conflict; mail callback registration.

## Задание 5. Registration API/tests

- **Исходные данные:** serializer/service и anonymous APIClient.
- **Действие:** создайте public throttled endpoint с 201 contract; протестируйте body, row/token/email counts и отсутствие JWT/secrets.
- **Результат:** успешная регистрация наблюдаема через safe response/database/outbox.
- **Проверить:** success; validation error; duplicate conflict policy; no partial user/token; no access/refresh keys.

## Задание 6. Atomic email verification

- **Исходные данные:** unverified/verified/blocked users и valid/invalid/expired/used token.
- **Действие:** service разбирает token, блокирует token/user, проверяет purpose/digest/expiry/state, выставляет verified и used, отзывает siblings.
- **Результат:** только один valid consumption меняет state; внешний error не раскрывает внутреннюю причину.
- **Проверить:** valid; malformed; wrong secret; wrong purpose; expiry; replay; blocked user; concurrent double submit.

## Задание 7. Resend flow

- **Исходные данные:** unknown email, unverified user с active old token, verified user и blocked user.
- **Действие:** endpoint всегда возвращает одинаковый 202 contract; eligible user получает новый token/email после отзыва старого.
- **Результат:** HTTP body/status не перечисляет account state; старый link не работает.
- **Проверить:** each user state; normalized email; old/new link; email counts; throttle hook.

## Задание 8. Mail/security regression

- **Исходные данные:** registration/verify/resend suite и log capture.
- **Действие:** выполните on-commit callbacks в test, проверьте outbox/templates/recipient/domain, просканируйте captured logs/response/schema на forbidden values и запустите regressions.
- **Результат:** mail tests не отправляют сетью, security material не записан, week 12 API не сломан.
- **Проверить:** callbacks executed/not executed on rollback; send failure policy; zero/one mail; no raw password/token; full suite.

## Обязательные сценарии дня

1. Valid registration — 201, active-unverified user.
2. Password сохранён как hash и проходит `check_password()`.
3. Weak/mismatched password отклонён без partial rows.
4. Client не может назначить себе staff/verified/role.
5. Response не содержит password, verify token или JWT.
6. Test outbox содержит одно письмо с trusted domain.
7. Malicious Host не меняет confirmation URL.
8. Valid token подтверждает email один раз.
9. Wrong-purpose/expired token не меняет user.
10. Replay и concurrent double submit не дают второй transition.
11. Resend отзывает старую ссылку.
12. Resend unknown/verified email имеет тот же внешний contract.

## Контрольные вопросы

1. Почему registration не выдаёт JWT?
2. Почему `create_user()` не заменяет `validate_password()`?
3. Зачем `transaction.on_commit()`?
4. Почему link не строится из request Host?
5. Что происходит со старым token после resend?
6. Почему resend response одинаков для разных состояний?

---

# День 3. JWT login, access, refresh и logout

## Документация

- [Simple JWT: Getting started](https://django-rest-framework-simplejwt.readthedocs.io/en/latest/getting_started.html) — подключение JWT, получение и обновление токенов.
- [Simple JWT: Blacklist app](https://django-rest-framework-simplejwt.readthedocs.io/en/latest/blacklist_app.html) — отзыв refresh-токенов при logout.

## Паспорт задания

- **Цель:** реализовать и объяснить полный JWT lifecycle с verified-user gate, rotation и blacklist.
- **Рабочий файл или каталог:** settings, auth serializers/views/urls и JWT tests в `day_07_identity_api/`; журнал — `day_03_jwt_lifecycle.md`.
- **Результат:** `/token/`, `/token/refresh/`, `/token/logout/`, protected `/me/`, explicit lifetimes/claims/signing source и blacklist migrations.
- **Порядок выполнения:** пройти compatibility gate; подключить authentication/blacklist; зафиксировать settings; разобрать claims без сохранения token; адаптировать login policy; создать me; проверить access/refresh type/expiry; включить rotation/blacklist; реализовать logout; протестировать invalid/inactive/unverified/replay.
- **Наблюдаемый результат:** verified active user получает пару и входит в `/me/`; unverified/blocked не получают tokens; refresh rotates; старый refresh и logout refresh отклоняются.
- **Готово, если:** versions/migrations приняты; claims минимальны; immutable ID используется; signing key вне Git; login error generic; access/refresh не взаимозаменяемы; rotation/blacklist/logout доказаны; access-after-logout contract честен; 12 сценариев записаны.
- **Пример:** второй последовательный вызов refresh со старым token после rotation получает 401, а новый refresh работает.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–12. **Рекомендация:** измерить database queries login/refresh и объяснить blacklist lookups.

## Теория

Прочитайте разделы 23–30 и 39–41 `THEORY.md`.

## Задание 1. JWT contract и settings table

- **Исходные данные:** SimpleJWT settings, project threat checklist и target endpoints.
- **Действие:** заполните `setting | value | reason | risk | test`: lifetimes, rotation, blacklist, header type, user ID field/claim, algorithm, signing-key source, last-login policy.
- **Результат:** defaults не принимаются молча, реальные secret values не записаны.
- **Проверить:** access shorter than refresh; immutable ID; key missing; debug fallback; `UPDATE_LAST_LOGIN`; unsupported option in selected version.

## Задание 2. Dependency/app/migration setup

- **Исходные данные:** accepted candidate version и blacklist app documentation.
- **Действие:** добавьте exact dependency, authentication class и blacklist app; выполните import/check/migration plan/apply/replay в учебной/test environment.
- **Результат:** outstanding/blacklist tables существуют, migration chain воспроизводима.
- **Проверить:** clean install; missing app; unapplied migration; multi-database routing if relevant; full regression.

## Задание 3. Claims inspection

- **Исходные данные:** test-only issued access/refresh pair.
- **Действие:** decode через library test API без отключения verification; запишите только claim names/types/relative expiry, не values tokens/secrets.
- **Результат:** `token_type`, `exp`, `iat`, `jti`, stable user ID объяснены; sensitive/mutable claims отсутствуют.
- **Проверить:** access/refresh types; expiry order; unique jti; email/login not identifier; no password/balance/permissions snapshot.

## Задание 4. Login policy

- **Исходные данные:** verified active, unverified active, blocked verified, wrong password и nonexistent identity.
- **Действие:** адаптируйте token obtain serializer/view так, чтобы tokens выдавались только verified active user и ошибки не раскрывали конкретную причину.
- **Результат:** valid login — 200 pair; все invalid states — единый safe 401 contract без token rows для failure.
- **Проверить:** each state; case-normalized login; unusable password; attempted extra fields; throttle classes attached.

## Задание 5. Protected `me`

- **Исходные данные:** valid/expired/malformed access, refresh token и disabled/unverified-after-issue states.
- **Действие:** создайте `GET /auth/me/` с JWT authentication и safe account serializer.
- **Результат:** valid access возвращает только ID/email/login/verification/allowed profile fields; остальные credentials отклоняются.
- **Проверить:** no header; valid access; `Bearer` case/format; refresh-as-access; expired; malformed; inactive user.

## Задание 6. Refresh rotation

- **Исходные данные:** valid pair, expired/modified refresh и rotation/blacklist settings.
- **Действие:** выполните refresh, сохраните только поведение старого/нового tokens; проверьте outstanding/blacklist counts и response schema.
- **Результат:** новый access/refresh выданы, старый refresh blacklisted и sequential replay отклонён.
- **Проверить:** valid; replay; modified; expired; access-as-refresh; unverified/blocked state after issue; concurrency limitation documented.

## Задание 7. Logout

- **Исходные данные:** current refresh, already blacklisted token, malformed token и valid access.
- **Действие:** реализуйте logout как blacklist переданного refresh; выберите contract повторного logout; не обещайте revoke access без механизма.
- **Результат:** logout refresh больше не обновляется; access behavior до expiry записано честно.
- **Проверить:** valid logout; replay logout; malformed; access passed instead; refresh after logout; me with pre-logout access.

## Задание 8. JWT security/OpenAPI tests

- **Исходные данные:** все endpoints дня, log capture и schema.
- **Действие:** протестируйте statuses/body/DB token state/headers; убедитесь, что schema использует placeholders и logs не содержат credentials; выполните regressions.
- **Результат:** JWT lifecycle воспроизводим и документирован без secret leakage.
- **Проверить:** Authorization header absent from logs; fake schema examples; 401 envelope; migrations; week 11–12 tests.

## Обязательные сценарии дня

1. Verified active user получает access+refresh.
2. Wrong password/nonexistent identity имеют одинаковый safe error.
3. Unverified user не получает tokens.
4. Inactive user не получает tokens.
5. Claims используют stable user ID и не содержат secrets.
6. Valid access открывает `/me/`.
7. Missing/expired/malformed access даёт 401.
8. Refresh token не работает как access.
9. Valid refresh возвращает rotated pair.
10. Старый refresh после rotation не работает.
11. Logout blacklists current refresh.
12. Access-after-logout поведение соответствует честно записанному contract.

## Контрольные вопросы

1. Почему JWT payload не является secret?
2. Чем access отличается от refresh?
3. Почему user claim использует ID, а не email?
4. Что делают rotation и blacklist?
5. Что именно отзывает logout?
6. Почему access может жить после logout?

---

# День 4. Смена и сброс пароля

## Документация

- [Django: Password management](https://docs.djangoproject.com/en/5.2/topics/auth/passwords/) — проверка, смена и безопасное хранение паролей.
- [Django authentication views](https://docs.djangoproject.com/en/5.2/topics/auth/default/#module-django.contrib.auth.views) — стандартный flow сброса пароля как эталон контракта.

## Паспорт задания

- **Цель:** реализовать два разных password flow с validators, одноразовым reset token и проверяемым session revocation.
- **Рабочий файл или каталог:** password serializers/services/emails/views/tests в `day_07_identity_api/`; журнал — `day_04_password_flows.md`.
- **Результат:** `/password/change/`, `/password/reset/request/`, `/password/reset/confirm/`, generic reset response и документированная JWT revoke policy.
- **Порядок выполнения:** записать contracts; реализовать authenticated change; проверить current password; вызвать validators; отозвать sessions; реализовать generic reset request/email; atomic reset confirmation; проверить expiry/replay/concurrency; проверить старые passwords/tokens; обновить schema.
- **Наблюдаемый результат:** change требует valid access и current password; reset не раскрывает account; после success старый password и refresh не работают согласно contract.
- **Готово, если:** raw passwords нигде не сохраняются; validators работают в обоих flows; reset request generic; token purpose/TTL/single-use соблюдены; password state меняется атомарно; refresh revocation доказана; access policy честна; 12 сценариев записаны.
- **Пример:** reset request для существующего и неизвестного email возвращает одинаковые 202/body, но письмо появляется только для eligible account.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–12. **Рекомендация:** security notification после успешной смены пароля без reset link.

## Теория

Прочитайте разделы 6–8, 12–18 и 30–33, 39–41 `THEORY.md`.

## Задание 1. Password contracts

- **Исходные данные:** authenticated change и anonymous reset requirements.
- **Действие:** заполните paths, fields, statuses, errors, token/session effects и mail behavior в `AUTH_CONTRACT.md`.
- **Результат:** change/reset не смешаны, post-success authentication policy явна.
- **Проверить:** valid/invalid current password; weak new; reset known/unknown; replay; old access/refresh.

## Задание 2. Password validation adapter

- **Исходные данные:** Django `validate_password()` errors и DRF error envelope.
- **Действие:** создайте единый adapter, вызывающий validators с user context и сохраняющий field messages/codes без password value.
- **Результат:** registration/change/reset используют одну validation policy без копирования.
- **Проверить:** minimum length; common; numeric; similarity; several errors; custom validator order.

## Задание 3. Authenticated change service

- **Исходные данные:** authenticated user, current password и new password/confirmation.
- **Действие:** проверьте current password, new confirmation/validators; atomically `set_password()`, save и revoke outstanding refresh tokens по принятой policy.
- **Результат:** success меняет hash один раз; failure не меняет password/token state.
- **Проверить:** valid; wrong current; same/mismatched new; weak; blocked user; forced exception rollback.

## Задание 4. Change API и token aftermath

- **Исходные данные:** old access/refresh, endpoint serializer/service и test client.
- **Действие:** реализуйте protected change endpoint; после success проверьте old login, new login, refresh и access behavior.
- **Результат:** status/envelope и revoke semantics совпадают с contract; raw inputs отсутствуют в response/log.
- **Проверить:** missing access; valid; repeated old current; old refresh; access with/without credential-version check; new credentials.

## Задание 5. Generic reset request

- **Исходные данные:** existing active/verified, unknown, inactive, unverified и unusable-password accounts.
- **Действие:** endpoint нормализует email и всегда возвращает одинаковый 202; только eligible account получает new reset token/mail, старый reset token отзывается.
- **Результат:** status/body не подтверждают account existence; mail/token effects различаются только внутри tests.
- **Проверить:** each state; repeat request; case variation; email backend failure; throttle hook.

## Задание 6. Reset email

- **Исходные данные:** reset token, trusted frontend base URL и locmem outbox.
- **Действие:** создайте отдельные subject/body templates и purpose-specific path; отправьте after commit.
- **Результат:** письмо уходит зарегистрированному адресу, link не зависит от request Host и не содержит лишних PII.
- **Проверить:** trusted domain; malicious Host; one recipient; subject single line; no password; rollback callback not sent.

## Задание 7. Atomic reset confirmation

- **Исходные данные:** valid/modified/expired/used/wrong-purpose tokens и new password.
- **Действие:** блокируйте token/user, validate token и password, вызывайте `set_password()`, consume/revoke siblings и refresh sessions в одной transaction.
- **Результат:** только valid first request меняет credentials; failure/replay/race оставляет state целым.
- **Проверить:** success; malformed; expiry boundary; weak new; replay; concurrent double confirm; forced rollback.

## Задание 8. Password regression/audit

- **Исходные данные:** обоих flows, outbox, SimpleJWT tables, captured logs и schema.
- **Действие:** проверьте old/new password, all outstanding refresh behavior, access contract, email counts, no secrets и OpenAPI; запустите полный suite.
- **Результат:** password lifecycle доказан end-to-end и не ломает registration/JWT/catalog.
- **Проверить:** old password fails; new succeeds only after verified state; old refresh fails; tokens absent logs/schema; regressions green.

## Обязательные сценарии дня

1. Authenticated change с правильным current password успешен.
2. Wrong current password не меняет state.
3. Weak/mismatched new password отклонён.
4. Password хранится только как новый hash.
5. Old password после change не работает.
6. Old refresh после change отозван.
7. Reset known и unknown email имеют одинаковый HTTP contract.
8. Ineligible account не получает reset mail.
9. Reset link использует trusted frontend domain.
10. Valid reset token меняет password ровно один раз.
11. Expired/wrong-purpose/replayed token не меняет state.
12. После reset старые refresh и password не работают согласно contract.

## Контрольные вопросы

1. Чем password change отличается от reset?
2. Почему validators не запускаются автоматически manager-ом?
3. Почему reset request не сообщает, найден ли email?
4. Что должно произойти со всеми refresh tokens после смены пароля?
5. Как обеспечить single-use при двух одновременных confirm?
6. Что может происходить со старым access и почему?

---

# День 5. Подтверждаемая смена email и логина

## Документация

- [Django: Cryptographic signing](https://docs.djangoproject.com/en/5.2/topics/signing/) — защита подтверждающих ссылок от подделки и повторного применения.
- [Django: Customizing authentication](https://docs.djangoproject.com/en/5.2/topics/auth/customizing/) — свойства custom user и идентификатора входа.

## Паспорт задания

- **Цель:** изменить email/login только после доказательства владения новым адресом, сохранив старую identity до confirmation.
- **Рабочий файл или каталог:** identity-change serializers/services/emails/views/tests в `day_07_identity_api/`; журнал — `day_05_identity_change.md`.
- **Результат:** `/identity/change/request/` и `/identity/change/confirm/`, pending typed values, new-email message, atomic uniqueness recheck и refresh-session revocation.
- **Порядок выполнения:** зафиксировать identity policy; описать pending state; создать request serializer/service; проверить current password; нормализовать/reserve candidate; отозвать старый change token; отправить new-email link; реализовать atomic confirm; повторно проверить uniqueness; изменить fields вместе; отозвать refresh; проверить old/new login/replay/race.
- **Наблюдаемый результат:** request не меняет текущую identity; письмо получает новый адрес; только valid confirmation меняет email/login; conflict/replay/expiry не оставляет partial state.
- **Готово, если:** current password обязателен; old identity остаётся до confirm; pending token не хранит raw secret/password; mail идёт только new email; uniqueness проверяется дважды и окончательно в DB; confirm atomic/single-use; sessions отозваны; 12 сценариев записаны.
- **Пример:** после request `/me/` всё ещё показывает старый email; после valid confirm новый email становится текущим и старый refresh не работает.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–12. **Рекомендация:** отдельное уведомление на старый email после success.

## Теория

Прочитайте разделы 12–19, 22, 25, 29–30 и 34, 39–41 `THEORY.md`.

## Задание 1. Identity policy и contract

- **Исходные данные:** текущие email/login normalization/uniqueness rules и account states.
- **Действие:** определите, меняются ли email и login вместе, какие fields обязательны, statuses/errors и что происходит с old/new sessions.
- **Результат:** `AUTH_CONTRACT.md` отвечает на same value, duplicate, pending request, blocked user и access-after-change.
- **Проверить:** only email; email+login; same current values; case-only change; reserved/duplicate candidate; blocked state.

## Задание 2. Pending representation

- **Исходные данные:** action-token model и новые identity values.
- **Действие:** выберите typed columns или строго allowlisted payload; запретите password/raw token и зафиксируйте retention/cleanup.
- **Результат:** pending state содержит только необходимое для atomic confirmation.
- **Проверить:** valid Unicode login; malformed email; unexpected payload key; over length; old used/revoked row.

## Задание 3. Request serializer и proof

- **Исходные данные:** authenticated user, current password, new email/login.
- **Действие:** normalize input, verify current password и preliminary uniqueness; используйте один generic conflict code без раскрытия чужого account.
- **Результат:** valid input поступает service; failure не создаёт token/mail и не меняет user.
- **Проверить:** correct/wrong password; missing field; malformed; same value; duplicate/reserved; privilege field injection.

## Задание 4. Request service и new-email message

- **Исходные данные:** validated pending identity и старый active change token.
- **Действие:** atomically lock user, recheck current eligibility, revoke prior change token, create new token; after commit отправьте link на `new_email` из trusted base URL.
- **Результат:** user identity не изменена; old link отозван; письмо отправлено только new address.
- **Проверить:** no old token; one old token; second request; blocked during transaction; send failure; malicious Host.

## Задание 5. Atomic confirmation

- **Исходные данные:** valid/invalid/expired/used change token и pending values.
- **Действие:** lock token/user, validate purpose/digest/expiry/state, повторно проверить normalization/uniqueness и atomically update email/login + mark used.
- **Результат:** success меняет оба поля вместе; conflict/failure оставляет прежнюю identity.
- **Проверить:** valid; wrong purpose; replay; expiry boundary; database conflict created after request; forced exception; concurrent confirm.

## Задание 6. Session/JWT aftermath

- **Исходные данные:** access/refresh issued до change и credentials old/new.
- **Действие:** после confirm отзовите outstanding refresh tokens; проверьте login/refresh/me согласно выбранной access policy.
- **Результат:** old refresh не работает, re-login использует new identity; поведение old access явно документировано.
- **Проверить:** old/new login; old refresh; pre-change access; blocked after issue; new token pair claims stable user ID.

## Задание 7. Notifications и privacy audit

- **Исходные данные:** outbox для new/old email и captured logs/schema.
- **Действие:** проверьте recipient/body/domain; если реализовано old-email notification, в нём нет confirmation secret; убедитесь, что pending identity/token не раскрыты в public errors.
- **Результат:** письма идут правильным адресатам, security evidence не содержит секретов.
- **Проверить:** request mail new only; success notification old optional; failed confirm no success mail; log redaction; schema placeholders.

## Задание 8. Identity regression

- **Исходные данные:** registration/JWT/password/identity suites и migrations.
- **Действие:** запустите tests всех account states, concurrent/conflict paths, full regressions и schema audit; заполните state before/after table.
- **Результат:** change flow не обходит verification, не ломает stable JWT user ID и не оставляет partial values.
- **Проверить:** old unverified registration; verified; blocked; pending; duplicate race; clean migration/test replay.

## Обязательные сценарии дня

1. Request требует valid access и правильный current password.
2. Wrong password не создаёт token/mail.
3. Current email/login не меняются при request.
4. Письмо отправляется на новый, не старый адрес.
5. Старый change token после нового request отозван.
6. Malicious Host не меняет domain ссылки.
7. Valid confirm атомарно меняет email/login.
8. Wrong-purpose/expired/replayed token не меняет identity.
9. Candidate uniqueness повторно проверена при confirm.
10. Conflict/forced error не оставляет partial update.
11. Old refresh после success отозван, new login работает.
12. Pre-change access behavior соответствует записанному contract.

## Контрольные вопросы

1. Почему email нельзя изменить сразу при request?
2. Зачем current password, если уже есть access token?
3. Почему uniqueness проверяется повторно при confirm?
4. Почему письмо идёт на новый адрес?
5. Что происходит со старым refresh после success?
6. Почему stable JWT user ID не меняется вместе с email?

---

# День 6. Throttling, enumeration, logging и OpenAPI

## Документация

- [Django REST framework: Throttling](https://www.django-rest-framework.org/api-guide/throttling/) — ограничения частоты запросов и их границы безопасности.
- [OWASP Forgot Password Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Forgot_Password_Cheat_Sheet.html) — защита от enumeration и безопасный password reset.
- [drf-spectacular: Workflow and schema customization](https://drf-spectacular.readthedocs.io/en/latest/customization.html) — документирование нестандартных identity endpoints.

## Паспорт задания

- **Цель:** закрыть abuse/leakage gaps sensitive endpoints и доказать, что runtime security contract отражён в tests и OpenAPI.
- **Рабочий файл или каталог:** throttles/settings/error handler/logging/schema/tests в `day_07_identity_api/`; документы — `THREAT_CHECKLIST.md`, `OPENAPI_AUDIT.md`; журнал — `day_06_throttling_security.md`.
- **Результат:** scoped burst/sustained policies, isolated 429 tests, enumeration comparison, safe structured logs, schema validation и runtime↔OpenAPI audit.
- **Порядок выполнения:** составить rate table; определить client keys; подключить scopes; изолировать cache; проверить limit/Retry-After/no-side-effect; сравнить enumeration responses; проверить proxy assumptions; провести secret scan logs/schema; документировать endpoints/errors/429; validate schema; запустить full suite.
- **Наблюдаемый результат:** после лимита endpoint возвращает общий 429 envelope без DB/email effect; sensitive responses не раскрывают state; schema и logs не содержат credentials.
- **Готово, если:** каждый sensitive flow имеет scope; burst/sustained различаются; cache isolated; 429 доказан; built-in race limitation записано; enumeration body/status сравнены; logs redacted; OpenAPI совпадает с runtime; regressions green; 14 сценариев записаны.
- **Пример:** третий test request при rate `2/min` получает 429 и не создаёт новый reset token или письмо.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–14. **Рекомендация:** latency comparison как наблюдение, но без ложной гарантии constant-time.

## Теория

Прочитайте разделы 22, 35–41 `THEORY.md`.

## Задание 1. Rate/scope table

- **Исходные данные:** register, login, resend, reset, identity-change endpoints и actors.
- **Действие:** заполните `endpoint | burst scope/rate | sustained scope/rate | client key | product reason | limitation`; используйте низкие test rates отдельно от runtime policy.
- **Результат:** scopes не конфликтуют по именам и имеют обоснованные, testable values.
- **Проверить:** anonymous IP; authenticated user ID; normalized/hashed identity key if custom; NAT/proxy limitation; missing cache rate.

## Задание 2. Throttle implementation

- **Исходные данные:** DRF scoped/user/anon throttles и Django cache.
- **Действие:** подключите minimal built-in или узкий custom throttle там, где стандартного scope недостаточно; не храните raw email/token в cache key.
- **Результат:** sensitive views проверяют нужные scopes до side effects.
- **Проверить:** each endpoint; wrong scope; authenticated/anonymous; custom key collision; cache outage policy documented.

## Задание 3. Isolated throttle tests

- **Исходные данные:** dedicated test cache, low limits и deterministic client identities.
- **Действие:** очистите namespace, отправьте requests до/после лимита, проверьте 429/Retry-After и отсутствие user/token/email changes.
- **Результат:** tests не зависят от порядка suite и не загрязняют чужие scopes.
- **Проверить:** allowed count; first denied; window reset via controlled time/cache; another scope; another actor; no side effect.

## Задание 4. Concurrency/proxy limitations

- **Исходные данные:** официальные ограничения DRF throttle и deployment assumptions.
- **Действие:** добавьте в threat checklist non-atomic cache race, spoof/proxy/NAT risks и будущие controls; не настраивайте `NUM_PROXIES` наугад.
- **Результат:** документация не называет throttle anti-DoS/brute-force guarantee.
- **Проверить:** concurrent overrun explanation; single-process locmem; multiple workers; forwarded header; shared NAT.

## Задание 5. Enumeration comparison

- **Исходные данные:** login wrong/nonexistent/unverified и reset/resend known/unknown/ineligible scenarios.
- **Действие:** сравните status, body keys/codes, headers, email side effects и грубую latency; исправьте публичные различия, которые не являются осознанным contract.
- **Результат:** reset/resend contracts одинаковы снаружи; login не сообщает точную причину.
- **Проверить:** case variants; blocked; unusable password; duplicate registration documented trade-off; throttled responses.

## Задание 6. Secret/log audit

- **Исходные данные:** captured application logs, exception responses, mail templates, schema/examples и repository search patterns.
- **Действие:** ищите raw password fields, `Authorization`, JWT-like strings, confirmation URLs, signing keys и DSN; маскируйте/убирайте, сохранив event/request/user IDs.
- **Результат:** audit table содержит locations checked и нулевые утечки либо исправления.
- **Проверить:** success/failure login; malformed token exception; email send error; DEBUG false; OpenAPI; Git diff.

## Задание 7. OpenAPI auth contracts

- **Исходные данные:** actual serializers/views, error envelope и schema generator недели 12.
- **Действие:** документируйте request/response/status/auth/throttle для всех auth endpoints; используйте fake placeholders; проверьте security scheme Bearer.
- **Результат:** schema различает access/refresh/action tokens, 202/204/401/429 и не обещает несуществующий revoke.
- **Проверить:** every path/method; required/write-only fields; no password response; fake tokens; 429; logout/access caveat in description.

## Задание 8. Security regression и clean replay

- **Исходные данные:** all week 13 suites, week 11–12 regressions, migrations и dependency lock.
- **Действие:** выполните checks, drift, tests, schema validation, clean migration replay и review threat/openapi gaps; сохраните exit/duration summary.
- **Результат:** auth controls воспроизводимы, старые public/staff API boundaries не сломаны.
- **Проверить:** fresh database; isolated cache/outbox; warning triage; intentionally broken security assertion caught; no production network.

## Обязательные сценарии дня

1. Register scope достигает 429 на test limit.
2. Login имеет burst и sustained policy.
3. Reset scope достигает 429 без нового token/email.
4. Resend scope достигает 429 без нового token/email.
5. Identity-change scope ограничивает authenticated user.
6. `Retry-After` проверен, если throttle его предоставляет.
7. Другой scope не наследует чужой counter.
8. Другой actor/identifier следует выбранной key policy.
9. Cache очищен/изолирован между tests.
10. Reset known/unknown responses совпадают публично.
11. Resend known/unknown/already-verified responses совпадают публично.
12. Login failure не различает nonexistent/wrong/unverified подробностями.
13. Logs/repository/schema не содержат passwords, raw tokens, signing key и DSN.
14. OpenAPI valid и не имеет незакрытых runtime mismatch.

## Контрольные вопросы

1. Почему DRF throttle не является полной brute-force защитой?
2. Почему разные flows требуют разных scopes?
3. Чем burst limit отличается от sustained limit?
4. Почему proxy settings нельзя угадывать?
5. Какие responses сравниваются для enumeration?
6. Какие поля можно оставить в security log?

---

# День 7. Итоговый identity API

## Документация

- [Django authentication system](https://docs.djangoproject.com/en/5.2/topics/auth/) — базовые механизмы пользователей, паролей и сессий для итогового identity API.
- [Simple JWT Documentation](https://django-rest-framework-simplejwt.readthedocs.io/en/latest/) — полный справочник по JWT-аутентификации проекта.

## Паспорт проекта

- **Цель:** самостоятельно собрать и защитить полный account lifecycle поверх DRF API недели 12.
- **Рабочий файл или каталог:** `day_07_identity_api/`; документы — `README.md`, `AUTH_CONTRACT.md`, `THREAT_CHECKLIST.md`, `OPENAPI_AUDIT.md`, `TEST_MATRIX.md`; итог — `ASSESSMENT.md`.
- **Результат:** регистрация/verification, JWT login-refresh-logout, me, password change/reset, подтверждаемая identity change, scoped throttling, safe email/log/error/OpenAPI contracts.
- **Порядок выполнения:** перенести accepted baseline; собрать token foundation; registration; verify/resend; JWT; password change; password reset; identity change; throttling/security/schema; 42 scenarios; clean replay; защита.
- **Наблюдаемый результат:** новый разработчик поднимает проект по README и воспроизводит весь lifecycle без real email/secrets; invalid/replay/expired/concurrent requests не нарушают state.
- **Готово, если:** все endpoints/states приняты; passwords/tokens защищены; email tests isolated; rotation/revocation доказаны; identity меняется только после confirmation; throttles и enumeration checked; OpenAPI совпадает; regressions green; 42 actual scenarios; защита минимум 32/42.
- **Пример:** пользователь регистрируется, подтверждает email, входит, обновляет token, меняет пароль, теряет старый refresh и входит новым паролем; ни один response/log не показывает raw secret.
- **Обязательно для зачёта:** артефакты, срезы 1–9, сценарии 1–42, clean replay и защита. **Рекомендация:** компактная state/sequence diagram в README проекта.

## Целевое дерево

Названия адаптируйте к принятому проекту, сохраняя обязанности:

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
└── остальные принятые apps/
```

## Обязанности файлов

- `accounts/models.py` — persistent account/action-token state и constraints.
- `accounts/managers.py` — корректное создание user и normalization, не HTTP.
- `accounts/tokens.py` — generation/parse/digest/compare primitives, не state transition.
- `accounts/services.py` — atomic register/consume/change/revoke transitions.
- `accounts/emails.py` — trusted URL, render и send; не меняет database state.
- `accounts/api/serializers.py` — explicit input/output contracts и field validation.
- `accounts/api/views.py` — permissions/throttles/HTTP orchestration.
- `accounts/api/urls.py` — versioned names/routes.
- `common/api/throttles.py` — reusable scopes/client-key policy без raw identifiers.
- `common/api/exceptions.py` — error envelope недели 12, включая 429.
- tests — HTTP, DB, mail, token/session, concurrency, schema и leakage evidence.
- `AUTH_CONTRACT.md` — state/endpoints/token policies.
- `THREAT_CHECKLIST.md` — assets, abuse cases, controls, evidence, limitations.
- `OPENAPI_AUDIT.md` — runtime↔schema comparison.
- `TEST_MATRIX.md` — только фактически запущенные 42 scenarios.

## Срез 1. Baseline, state и token foundation

- **Исходные данные:** accepted week 12, compatibility evidence и custom User.
- **Действие:** перенесите source, зафиксируйте baseline, добавьте/мигрируйте state fields и action-token model, реализуйте safe primitives.
- **Результат:** migrations clean, raw token не хранится, state/threat contracts заполнены.
- **Проверить:** fresh database; old rows; purpose/TTL/digest; modified token; no secret; regressions.

## Срез 2. Registration

- **Исходные данные:** anonymous input и password policy.
- **Действие:** реализуйте serializer/service/API: create active-unverified user + verify token + on-commit mail.
- **Результат:** 201 safe summary, password hash, one test email, no JWT.
- **Проверить:** valid; password validators; duplicate/case; privilege injection; rollback/on-commit.

## Срез 3. Verify и resend

- **Исходные данные:** account states и action tokens.
- **Действие:** реализуйте atomic confirmation и generic resend с sibling revocation.
- **Результат:** valid first token verifies; replay/expiry/wrong purpose fail; old resend link revoked.
- **Проверить:** unverified/verified/blocked/unknown; malicious Host; concurrency; mail counts.

## Срез 4. JWT и me

- **Исходные данные:** verified/unverified/blocked users и SimpleJWT blacklist.
- **Действие:** реализуйте login, refresh rotation, logout blacklist и protected me.
- **Результат:** only verified active user authenticates, token types/lifetimes/revocation match contract.
- **Проверить:** credentials states; access/refresh misuse; replay; expiry; logout aftermath; claims/logs.

## Срез 5. Authenticated password change

- **Исходные данные:** valid access, current/new password и outstanding tokens.
- **Действие:** validate proof/new password, atomically set hash и apply revoke policy.
- **Результат:** old password/refresh fail, new password login succeeds, access behavior documented.
- **Проверить:** wrong current; weak/mismatch; rollback; multiple refresh sessions; log/schema safety.

## Срез 6. Password reset

- **Исходные данные:** known/unknown/ineligible email states.
- **Действие:** реализуйте generic request, trusted email link и atomic single-use confirmation.
- **Результат:** account existence не раскрывается HTTP contract; valid token changes password once and revokes sessions.
- **Проверить:** known/unknown; inactive/unverified policy; expiry/replay/race; new request revokes old.

## Срез 7. Identity change

- **Исходные данные:** authenticated user, current proof и new email/login.
- **Действие:** создайте pending token/mail и atomic confirmation с repeated uniqueness check.
- **Результат:** old identity остаётся до confirm, new identity применяется вместе, refresh sessions revoked.
- **Проверить:** duplicate between request/confirm; old/new login; replay; partial rollback; recipients.

## Срез 8. Throttling, enumeration, logs и schema

- **Исходные данные:** все sensitive endpoints, test cache, error handler и OpenAPI.
- **Действие:** примените scopes, выполните 429/no-side-effect tests, сравните enumeration, проведите secret scan и runtime↔schema audit.
- **Результат:** abuse controls testable, ограничения честно записаны, errors/schema/logs безопасны.
- **Проверить:** burst/sustained; actors/scopes; Retry-After; cache isolation; placeholders; warnings.

## Срез 9. Clean replay и защита

- **Исходные данные:** complete project, fresh environment instructions и 42 scenarios.
- **Действие:** выполните clean install/migrations/checks/tests/schema; заполните matrices фактическими результатами; ответьте на вопросы без чтения реализации.
- **Результат:** account lifecycle воспроизводим, объясним и не ломает domain/API недель 11–12.
- **Проверить:** no network email; no production DB/cache; dependency lock; intentional negative test; no secrets in Git diff.

## Обязательные итоговые сценарии

### Позитивные: 1–18

1. Clean dependency install/checks/migration replay на принятой version combination.
2. Regression suites недель 11–12 green.
3. Valid registration создаёт active-unverified user и verify action row.
4. Registration password хеширован и проходит `check_password()`.
5. Registration отправляет одно locmem письмо после commit.
6. Valid verification atomically делает user verified и token used.
7. Resend создаёт новую ссылку и отзывает старую.
8. Verified active user получает access+refresh.
9. Valid access открывает `/auth/me/` с safe fields.
10. Valid refresh возвращает rotated access+refresh.
11. Logout blacklists current refresh.
12. Authenticated password change принимает current proof и новый valid password.
13. Password change отзывает outstanding refresh sessions.
14. Existing eligible account получает password-reset email.
15. Valid reset token меняет password и отзывается/consumes.
16. Identity-change request отправляет confirmation на новый email, не меняя current identity.
17. Valid identity confirmation меняет email/login вместе и отзывает refresh sessions.
18. OpenAPI schema валидируется и Swagger показывает актуальные auth contracts.

### Граничные и replay: 19–30

19. Email/login normalization обрабатывает пробелы/case по записанной policy.
20. Password ровно на минимальной разрешённой границе принимается, более слабый отклоняется.
21. Token при `expires_at == now` считается expired.
22. One-character modified token не проходит digest compare.
23. Verification replay не выполняет второй transition.
24. Два concurrent verify requests дают ровно один successful consumption.
25. Resend old link после новой ссылки не работает.
26. Old refresh после rotation не работает при последовательном replay.
27. Repeated logout соответствует выбранному idempotency/error contract.
28. Empty/invalid/missing action-token parts дают общий safe error.
29. Duplicate identity, возникшая между request и confirm, не оставляет partial update.
30. Pre-change/pre-logout access живёт или отзывается строго по документированной policy.

### Ошибочные, security и abuse: 31–42

31. Client не может зарегистрировать себе `is_staff`, role, active или verified status.
32. Weak/common/numeric/similar password отклоняется registration/change/reset flows.
33. Login nonexistent/wrong/unverified не различается sensitive public detail.
34. Inactive user не получает login, refresh или protected access.
35. Refresh token не принимается как Bearer access; access не принимается как refresh/logout.
36. Reset/resend known, unknown и ineligible accounts имеют одинаковый public HTTP contract.
37. Wrong-purpose/expired/used/revoked action token не меняет state.
38. Malicious Host/X-Forwarded-Host не влияет на emailed frontend link.
39. Request после throttle limit получает 429/Retry-After без user/token/email side effect.
40. Разные throttle scopes/actors изолированы по принятой key policy.
41. Responses/logs/repository/schema не содержат raw passwords, JWT/action tokens, signing key или DSN.
42. Forced database/email/server failure следует rollback/on-commit/error policy без partial credential state и без internal leakage.

## Ограничения итогового проекта

На неделе 13 нельзя:

- реализовывать JWT crypto самостоятельно;
- использовать JWT access как verification/reset/change token;
- добавлять social login, OAuth или OIDC;
- добавлять MFA/TOTP/WebAuthn;
- реализовывать полную role/object permission систему недели 14;
- хранить tokens/passwords в local repository или test artifacts;
- подключать real SMTP/provider credentials;
- добавлять Celery/Redis ради email/throttle;
- обещать exact concurrent throttle enforcement;
- настраивать trusted proxy count без deployment topology;
- обещать мгновенный access revoke без проверяемого механизма;
- добавлять browser cookie transport без CSRF/CORS design;
- добавлять CAPTCHA/WAF/DDoS provider;
- хранить pending password;
- менять email/login до подтверждения;
- запускать tests на shared/production services.

## Финальный чек-лист сдачи

- [ ] Source week 12 и green baseline зафиксированы.
- [ ] SimpleJWT compatibility/release evidence сохранено без blind pin.
- [ ] Clean dependencies и blacklist migrations воспроизводимы.
- [ ] User state machine и threat checklist заполнены.
- [ ] `is_active`/`is_email_verified` имеют разные смыслы.
- [ ] Passwords создаются через manager/`set_password()`.
- [ ] Password validators работают во всех трёх flows.
- [ ] Action tokens имеют random secret, digest, purpose, TTL и single-use.
- [ ] Raw tokens/passwords отсутствуют в DB/log/schema/Git.
- [ ] Confirmation links используют trusted frontend base URL.
- [ ] Email tests используют locmem outbox и on-commit behavior.
- [ ] Registration не выдаёт JWT до verification.
- [ ] Verify/resend/replay/expiry/concurrency проверены.
- [ ] JWT claims минимальны и используют stable user ID.
- [ ] Access/refresh lifetimes и types различаются.
- [ ] Rotation/blacklist/logout проверены.
- [ ] Access-after-logout/change policy записана честно.
- [ ] Password change требует current password.
- [ ] Reset request не раскрывает account existence.
- [ ] Password reset token single-use и отзывает sessions.
- [ ] Identity request не меняет current email/login.
- [ ] Identity confirm повторно проверяет uniqueness и атомарен.
- [ ] Sensitive endpoints имеют scoped throttles и isolated 429 tests.
- [ ] Ограничения throttle/proxy/concurrency записаны.
- [ ] Security errors используют envelope недели 12.
- [ ] OpenAPI использует только fake placeholders.
- [ ] Runtime↔OpenAPI audit не имеет незакрытых mismatch.
- [ ] Regressions недель 11–12 green.
- [ ] Все 42 scenarios имеют actual evidence.
- [ ] README позволяет повторить setup без real services/secrets.
- [ ] Самооценка и известные ограничения заполнены.

## Вопросы для защиты: 42

1. Чем identity отличается от authentication и authorization?
2. Почему `is_active` отделён от `is_email_verified`?
3. Какой state создаёт registration?
4. Почему JWT не выдаётся до verification?
5. Почему нельзя присваивать `user.password` напрямую?
6. Зачем `validate_password()` передаётся user?
7. Где окончательно защищается unique email/login?
8. Из каких частей состоит action token?
9. Почему в database хранится digest?
10. Почему для token подходит SHA-256, а для password нужен slow password hasher?
11. Зачем action token имеет purpose?
12. Как определяется expiry boundary?
13. Почему consumption выполняется в transaction?
14. Какие rows и в каком порядке блокируются?
15. Почему два concurrent confirms не должны оба пройти?
16. Что происходит со старой ссылкой после resend?
17. Зачем отправлять email через `on_commit()`?
18. Что происходит, если mail send падает после commit?
19. Почему security link строится из configured frontend URL?
20. Что такое account enumeration?
21. Какие public ответы reset/resend должны совпадать?
22. Почему JWT payload можно прочитать?
23. Что защищает JWT signature?
24. Чем access token отличается от refresh token?
25. Для чего нужны `exp`, `jti` и `token_type`?
26. Почему user claim использует immutable ID?
27. Что проверяется при login кроме password?
28. Что делает refresh rotation?
29. Что делает blacklist app?
30. Что происходит при replay старого refresh?
31. Что именно делает logout?
32. Почему access может работать после logout?
33. Что отзывается после password change/reset?
34. Чем authenticated change отличается от reset confirm?
35. Почему reset request возвращает generic 202?
36. Почему email/login не меняются на этапе change request?
37. Почему uniqueness снова проверяется на confirm?
38. Почему refresh sessions отзываются после identity change?
39. Чем burst throttle отличается от sustained?
40. Почему DRF throttling не является полноценной brute-force/DoS защитой?
41. Какие security values запрещены в logs/OpenAPI/tests?
42. Как вы доказали соответствие runtime, state machine и OpenAPI?

Минимум для защиты — **32 уверенных ответа из 42**, включая обязательные вопросы 2, 5, 9, 11, 13, 15, 17, 19, 24, 26, 28, 31, 32, 33, 37, 40, 41 и 42.

## Что передать наставнику

1. Путь на `day_07_identity_api/`.
2. Source branch/commit недели 12 и commit текущей попытки.
3. `AUTH_CONTRACT.md` со states/endpoints/token policies.
4. `THREAT_CHECKLIST.md`.
5. `OPENAPI_AUDIT.md`.
6. Заполненный `TEST_MATRIX.md`.
7. Commands/status/duration checks, migrations, tests и schema validation.
8. Mail outbox evidence без raw links/tokens.
9. JWT rotation/blacklist/revocation evidence без token values.
10. Throttle scope/rate/cache-isolation evidence.
11. Список известных security limitations.
12. Самооценку и темы для разбора.
