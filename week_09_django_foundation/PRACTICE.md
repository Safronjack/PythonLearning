# Практика недели 9: основа Django

Статус: **заблокирована до явного допуска из недели 8**.

## Общие правила

- Все семь дней развивают один проект в `day_07_django_foundation/`.
- Ответы, прогнозы и краткие фактические результаты записываются в отдельный файл текущего дня.
- Ученик самостоятельно создаёт Django-код; заготовки не содержат готового решения.
- До первой миграции обязательно создать `accounts.User` и настроить `AUTH_USER_MODEL`.
- Использовать только отдельную учебную PostgreSQL database.
- Не печатать и не сохранять пароли, настоящий `SECRET_KEY`, cookies или Authorization headers.
- `.env` не добавлять в Git; `.env.example` содержит только фиктивные значения.
- Не использовать SQLite как незаметный fallback.
- Не добавлять DRF, JWT, Celery, Redis, Docker и предметные models раньше соответствующих недель.
- После каждого изменения запускать узкую проверку, а в конце дня — полный набор проверок дня.
- Если runtime-среда недоступна, записать ограничение. Ожидаемый результат не выдавать за фактический.

## Формат журнала эксперимента

Для команд и HTTP-сценариев используй такой блок:

```text
Experiment ID:
Question:
Input/command:
Prediction:
Actual result:
Explanation:
Next correction:
```

Не копируй многостраничный traceback. Сохрани тип ошибки, последнюю значимую строку и своё объяснение причины.

## Самооценка дня

В конце дневного `.md`-файла ответь:

1. Что я сделал самостоятельно?
2. Как проходит request в сегодняшнем коде?
3. Где прогноз отличался от результата?
4. Какую ошибку я теперь могу объяснить?
5. Что осталось непонятным?
6. Сколько времени заняла работа?

## Шкала

| Критерий | Баллы |
|---|---:|
| Корректность результата | 0–3 |
| Выполнение условий | 0–2 |
| Граничные и ошибочные сценарии | 0–2 |
| Читаемость и структура | 0–1 |
| Понимание и самооценка | 0–1 |
| Самостоятельность исправлений | 0–1 |

---

# День 1. Создание project и карта приложений

## Паспорт задания

- **Цель:** создать минимальный Django project, увидеть обязанности сгенерированных файлов и заложить границы восьми apps.
- **Рабочая область:** `day_07_django_foundation/`; журнал — `day_01_project_anatomy.md`.
- **Результат:** Django project `config`, восемь app packages, зафиксированные версии и карта ответственностей без применённых migrations.
- **Порядок:** проверь интерпретатор и зависимости; создай project; исследуй файлы; создай apps; запиши границы; выполни system check.
- **Наблюдаемый результат:** `manage.py check` загружает project без ошибок, а журнал объясняет каждый созданный компонент.
- **Готово, если:** код находится в точной папке; все apps созданы; `migrate` ещё не выполнялся; project не содержит секретов; структура объяснена.
- **Пример:** `accounts — пользователь и будущие аккаунтные процессы; не хранит продажи`.
- **Обязательно:** задания 1–6 и сценарии. **Рекомендация:** сделать отдельный commit после принятия дня, не во время незавершённой работы.

## Теория

Прочитай разделы 1–7 `THEORY.md`.

## До команд

В `day_01_project_anatomy.md` письменно ответь:

1. Чем Django project отличается от Django app?
2. Что изменяют `startproject` и `startapp`?
3. Почему `runserver` не является production server?
4. Где находится корневой URLconf?
5. Какие действия выполняет `manage.py` сам, а какие делегирует Django?

## Задание 1. Проверка среды

**Исходные данные:** текущий Python 3.11 и выбранная при активации поддерживаемая patch-версия Django 5.2 LTS.

**Действие:** активируй согласованное virtual environment, установи только разрешённые зависимости и сохрани:

- `python --version`;
- `python -m django --version`;
- способ фиксации direct dependencies;
- путь интерпретатора без домашнего каталога и секретов, если он нужен для диагностики.

**Результат:** версии совместимы, Django импортируется.

**Проверки:** запуск из корня проекта и из папки недели использует один ожидаемый interpreter; неизвестная версия не записывается «на глаз».

## Задание 2. Создание project

**Действие:** внутри пустого `day_07_django_foundation/` создай project с Python package `config`. Не создавай лишний вложенный одноимённый каталог.

**Результат:** существуют `manage.py`, `config/settings.py`, `config/urls.py`, `config/asgi.py`, `config/wsgi.py`.

**Проверки:** `manage.py help` работает; текущая рабочая папка и место создаваемых файлов подтверждены до команды.

## Задание 3. Анатомия generated files

Для каждого сгенерированного файла запиши:

- кем он импортируется;
- что он экспортирует;
- должен ли содержать business logic;
- какая ошибка возникнет при неверном settings module.

**Результат:** таблица минимум из пяти строк в дневном журнале.

## Задание 4. Создание apps

Создай ровно эти apps в корне Django-проекта:

```text
accounts
catalog
dealerships
suppliers
trading
promotions
analytics
common
```

**Результат:** каждый каталог является корректным Django app package с `apps.py`.

**Проверки:** app labels уникальны; нет вложения app в `config`; apps пока не содержат предметных models.

## Задание 5. Карта ответственности

В журнале создай таблицу:

```text
app | владеет | не владеет | будущие зависимости
```

Для каждого app укажи минимум по одному пункту в каждой колонке. Отдельно объясни, почему `common` не должен стать местом для любого неудобного кода.

## Задание 6. Первый system check

Подключи apps в `INSTALLED_APPS` только после чтения их config. Выполни `manage.py check`.

**Результат:** сохрани финальную строку команды и объясни, что эта проверка доказывает и чего не доказывает.

Не запускай `migrate`: custom user ещё не настроен.

## Обязательные сценарии

1. Django импортируется выбранным Python.
2. Команда запускается из документированного каталога.
3. Все восемь apps находятся в `INSTALLED_APPS`.
4. AppConfig каждого app импортируется.
5. `manage.py check` проходит.
6. Database migrations ещё не применялись.
7. В Git status нет `.env`, database-файла или секрета.

## Контрольные вопросы

1. Зачем `manage.py`, если есть `django-admin`?
2. Что делает `INSTALLED_APPS`?
3. Почему app не равна одной table?
4. Что произойдёт, если import settings падает?

---

# День 2. Environment, PostgreSQL и custom user до migrations

## Паспорт задания

- **Цель:** настроить безопасную конфигурацию и custom user до первого изменения database schema.
- **Рабочая область:** settings/accounts внутри итогового project; журнал — `day_02_settings_custom_user.md`.
- **Результат:** явный environment parser, PostgreSQL configuration, `.env.example`, `accounts.User`, `AUTH_USER_MODEL` и первая применённая migration chain.
- **Порядок:** спроектируй environment contract; настрой settings; докажи connection target; создай user; проверь migration; только затем выполни migrate.
- **Наблюдаемый результат:** Django подключается к ожидаемой PostgreSQL database, а `get_user_model()` возвращает `accounts.User`.
- **Готово, если:** секреты не в Git; false разбирается как False; custom user находится в `accounts/0001_initial.py`; SQLite не используется; migrations применены успешно.
- **Пример:** журнал содержит `vendor=postgresql`, учебное имя database и user, но не password/DSN.
- **Обязательно:** задания 1–8 и сценарии. **Рекомендация:** не делить settings на много файлов до появления реальной необходимости.

## Теория

Прочитай разделы 8–14.

## Задание 1. Environment contract

В дневном журнале создай таблицу для:

```text
DJANGO_SECRET_KEY
DJANGO_DEBUG
DJANGO_ALLOWED_HOSTS
POSTGRES_DB
POSTGRES_USER
POSTGRES_PASSWORD
POSTGRES_HOST
POSTGRES_PORT
```

Колонки: required, type after parsing, development example, secret yes/no, behavior when missing.

**Результат:** для каждого параметра заранее определено поведение; неизвестный boolean не принимается молча.

## Задание 2. `.env.example` и ignore

Создай `.env.example` с фиктивными значениями и убедись, что `.env` игнорируется.

**Проверки:** в example нет настоящего password/key; комментарий объясняет способ передачи variables через PyCharm или shell; приложение не обещает автоматически читать `.env`, если loader не установлен.

## Задание 3. Парсинг settings

Реализуй небольшие функции или один ясный участок settings для:

- обязательной строки;
- boolean только из согласованных вариантов;
- списка hosts из строки через разделитель;
- integer port.

**Результат:** settings получают Python types, а не необработанные строки.

**Сценарии:** `true`, `false`, `1`, `0`; пробелы в hosts; пустой обязательный secret; нечисловой port.

## Задание 4. PostgreSQL settings

Замени default SQLite configuration на PostgreSQL backend. До migration получи безопасное подтверждение:

- engine/vendor;
- database name;
- database user;
- host/port.

Никогда не печатай password.

**Результат:** connection target однозначно является согласованной учебной database.

## Задание 5. Минимальный custom user

В `accounts` создай `User` на основе `AbstractUser` без преждевременной смены login field. Укажи `AUTH_USER_MODEL`.

**Результат:** Django app registry разрешает строку `accounts.User`.

**Проверки:** прямого импорта default `User` в project нет; модель не зависит от будущих domain models.

## Задание 6. Migration до применения

Создай только migration `accounts`. Прочитай файл и найди создание `User`.

Запиши:

- имя migration;
- dependencies;
- создаваемую model;
- почему она должна быть initial.

Если migration не `0001_initial`, остановись и разберись до `migrate`.

## Задание 7. Первое `migrate`

После проверки target database примени migrations. Затем выполни `showmigrations`.

**Результат:** built-in и accounts migrations применены без попытки изменить другую database.

## Задание 8. Runtime proof

Через Django shell получи:

- активный database vendor;
- безопасные current database/current user values;
- label и имя активной user model.

Сохрани только не секретные результаты.

## Обязательные сценарии

1. `DJANGO_DEBUG=false` даёт `False`.
2. Неизвестное boolean значение отклоняется.
3. Пустой обязательный secret останавливает startup.
4. Hosts очищаются от пробелов и пустых элементов.
5. PostgreSQL connection успешен.
6. `accounts.User` создан в initial migration.
7. `migrate` и `showmigrations` успешны.
8. SQLite-файл не появился.
9. `.env` и secrets не отслеживаются Git.

## Контрольные вопросы

1. Почему `bool("False")` — ошибка конфигурации?
2. Чем `makemigrations` отличается от `migrate`?
3. Почему custom user нужно выбрать сейчас?
4. Когда использовать `settings.AUTH_USER_MODEL`, а когда `get_user_model()`?

---

# День 3. URL dispatcher, views и HTTP contract

## Паспорт задания

- **Цель:** провести request через namespaced URLconf во view и вернуть корректный HTTP response.
- **Рабочая область:** `config/urls.py`, URL/view files apps; журнал — `day_03_urls_views.md`.
- **Результат:** именованные routes `/health/`, `/ready/`, `/catalog/status/`, namespaces всех apps и таблица HTTP-контрактов.
- **Порядок:** опиши contracts; создай app URLconfs; подключи include; реализуй health; затем readiness и catalog status; проверь reverse, methods и ошибки.
- **Наблюдаемый результат:** client получает ожидаемые status, Content-Type и JSON без раскрытия внутренних данных.
- **Готово, если:** routes именованы; 404/405 различаются; readiness проверяет database; секреты не возвращаются; reverse не использует hardcoded URL.
- **Пример:** `GET /health/ → 200 application/json`, `POST /health/ → 405`.
- **Обязательно:** задания 1–7 и сценарии. **Рекомендация:** одна view — один маленький HTTP-контракт.

## Теория

Прочитай разделы 15–22.

## Задание 1. Contract table

В журнале до кода заполни:

```text
route | methods | success status | failure status | content type | body fields | route name
```

Строки: home, health, readiness, catalog status.

## Задание 2. App URLconfs

Создай `urls.py` во всех восьми apps. У каждого есть `app_name` и `urlpatterns`.

**Результат:** корневой URLconf делегирует app routes через `include()`; отсутствие endpoint в некоторых apps допускается.

**Проверки:** namespace уникален; route string не начинается с `/`; корневой файл не импортирует все будущие views.

## Задание 3. Health view

Реализуй `GET /health/` в `common`.

Контракт:

- только GET;
- status 200;
- JSON object минимум с `status: "ok"`;
- без database query;
- без version/secret/environment dump.

Для другого method вернуть 405 с корректным Allow behavior.

## Задание 4. Readiness view

Реализуй `GET /ready/`, который выполняет минимальную database connection check.

Контракт:

- при успехе 200 и безопасное `status: "ready"`;
- при предусмотренной database-ошибке 503 и `status: "not_ready"`;
- response не содержит traceback, host, user, password или raw exception.

Не выполняй тяжёлый business query.

## Задание 5. Catalog status

Реализуй `GET /catalog/status/` как временный boundary endpoint без моделей.

Он сообщает только, что app route подключён. Отдельно запиши, почему этот endpoint не является будущим каталогом.

## Задание 6. Reverse resolution

Для каждого созданного route получи URL по его namespaced name. Затем resolve один URL обратно во view.

**Результат:** в журнале есть пары `name → URL → resolved view`.

## Задание 7. Ошибочные пути

Проверь:

- неизвестный route;
- известный route с неверным method;
- route без конечного slash при текущем `APPEND_SLASH`;
- readiness при временно недоступной **учебной** database без изменения production/чужой базы.

Зафиксируй status и объяснение.

## Обязательные сценарии

1. GET health: 200 JSON.
2. POST health: 405.
3. GET ready с database: 200.
4. Предусмотренная ошибка ready: 503 без секрета.
5. GET catalog status: 200.
6. Неизвестный path: 404.
7. Все URL names разрешаются через reverse.
8. Response content type соответствует body.

## Контрольные вопросы

1. Кто выбирает view?
2. Зачем нужны names и namespaces?
3. Чем health отличается от readiness?
4. Почему database error нельзя вернуть вместе с traceback?

---

# День 4. Templates, static, форма и admin

## Паспорт задания

- **Цель:** отобразить server-rendered страницу, безопасно принять простую форму и настроить admin для custom user.
- **Рабочая область:** templates/static/common/accounts/admin; журнал — `day_04_templates_admin.md`.
- **Результат:** base/home templates, CSS, неперсистентная форма preview, зарегистрированный User и проверенный local admin.
- **Порядок:** создай base template; домашнюю страницу; static asset; затем форму с CSRF; зарегистрируй UserAdmin; создай local superuser и проверь permissions.
- **Наблюдаемый результат:** HTML-страница наследует layout и CSS, POST проходит с token, admin открывается только после входа.
- **Готово, если:** autoescape работает; URLs строятся по names; CSRF не отключён; пароль не сохранён; admin не назван публичным интерфейсом.
- **Пример:** главная страница показывает названия восьми apps из context, а не жёстко повторяет разметку в восьми местах.
- **Обязательно:** задания 1–7 и сценарии. **Рекомендация:** держать styling минимальным — оценивается Django flow, не дизайн.

## Теория

Прочитай разделы 23–29.

## Задание 1. Template layout

Создай `templates/base.html` с:

- корректной HTML-структурой;
- title block;
- content block;
- navigation на home/health/admin через именованные URLs;
- загрузкой static tag.

**Результат:** layout используется дочерним template.

## Задание 2. Home view и context

Создай `templates/common/home.html` и view для `/`.

View передаёт:

- название project;
- список apps и их краткие ответственности;
- текущий environment label без секрета.

Template отображает данные циклом и наследует base.

## Задание 3. Autoescape experiment

Передай в context учебную строку с HTML-tag. Сначала предскажи результат, затем открой страницу и сохрани наблюдение.

**Результат:** tag отображается как текст. Не применяй `safe`.

## Задание 4. Static file

Добавь один CSS-файл и подключи через `{% static %}`.

**Проверки:** CSS загружается в development; template не содержит абсолютный filesystem path; page остаётся понятной без CSS.

## Задание 5. Quote preview form

Создай обычную Django Form без database model для:

- model name — непустая строка;
- maximum price — положительное целое число.

GET показывает пустую форму. POST с корректными данными показывает очищенный preview без сохранения. Некорректный POST отображает field errors.

**Результат:** state-changing POST использует CSRF token; validation выполняется form, а не ручным чтением каждой строки.

## Задание 6. Custom user в admin

Зарегистрируй `accounts.User` через подходящий `UserAdmin`.

**Проверки:** admin system check проходит; user list открывается; password отображается/изменяется только штатными admin-механизмами, не как обычный текст.

## Задание 7. Local superuser

Создай superuser интерактивно с фиктивным учебным email. Не сохраняй password.

Проверь:

- анонимный запрос к admin перенаправляется на login;
- неверный пароль не даёт доступ;
- superuser входит;
- logout завершает session.

## Обязательные сценарии

1. Home: 200 и нужный template.
2. Template inheritance работает.
3. Учебный HTML экранируется.
4. Static CSS доступен в development.
5. GET form: 200.
6. POST без CSRF при включённой проверке: 403.
7. Корректный POST показывает preview и ничего не сохраняет.
8. Нулевая/пустая цена даёт validation error.
9. Anonymous admin redirect.
10. Superuser login/logout работает.

## Контрольные вопросы

1. Где готовятся данные, а где отображаются?
2. Что делает autoescape?
3. Что защищает CSRF?
4. Почему admin не заменяет DRF API?

---

# День 5. Request lifecycle и custom middleware

## Паспорт задания

- **Цель:** увидеть порядок request/response-слоёв и добавить безопасный request ID и timing.
- **Рабочая область:** middleware/config/logging; журнал — `day_05_middleware_lifecycle.md`.
- **Результат:** схема lifecycle, временный order experiment и одно итоговое middleware с проверяемым response header/log.
- **Порядок:** нарисуй flow; проведи опыт с двумя layers; реализуй request ID; добавь timing; настрой logging; проверь short-circuit и исключение.
- **Наблюдаемый результат:** response содержит корректный ID, а logs позволяют связать method/path/status/duration одного запроса без секретов.
- **Готово, если:** обычный путь вызывает `get_response()` один раз; response идёт в обратном порядке; данные пользователя ограничены; исключение не превращается в 200.
- **Пример:** одна log-запись: request_id, method, path, status, duration_ms — без body и cookies.
- **Обязательно:** задания 1–7 и сценарии. **Рекомендация:** временные учебные middleware удалить после фиксации порядка.

## Теория

Прочитай разделы 30–36.

## Задание 1. Lifecycle map

Для `GET /health/` нарисуй последовательность:

```text
server interface → middleware layers → URL resolver → view → response layers
```

Отметь, где появляются request, `request.user`, status и финальные headers.

## Задание 2. Порядок middleware

Создай два временных middleware A и B. Каждое добавляет marker до и после `get_response()`.

**Перед запуском:** запиши ожидаемый порядок шести событий с view в середине.

**Результат:** фактический порядок совпадает с onion model либо ошибка прогноза объяснена. После опыта удали A/B из итоговой конфигурации.

## Задание 3. Request ID contract

Определи правила:

- какой входной header допускается;
- допустимый формат/длина;
- когда создаётся новый UUID;
- в какой response header он возвращается;
- как используется в logs.

Не принимай неограниченное пользовательское значение.

## Задание 4. Итоговое middleware

Реализуй одно middleware в `common`, которое:

- назначает request ID;
- сохраняет его в request attribute;
- измеряет duration монотонным clock;
- вызывает inner application ровно один раз;
- добавляет безопасный response header;
- пишет одну структурированную log-запись после response.

## Задание 5. Logging configuration

Настрой console handler для development без дублирования сообщений.

**Проверки:** два запроса дают две итоговые записи; autoreload не порождает неожиданные duplicate handlers; уровень задаётся конфигурацией; secrets отсутствуют.

## Задание 6. Short-circuit experiment

Во временном middleware верни response до `get_response()` для path `/middleware-stop/`.

Докажи, что view не была вызвана и внутренние layers не выполнились. Затем убери эксперимент из итогового project.

## Задание 7. Exception path

Создай временную view, которая вызывает безопасное тестовое исключение.

Проверь при подходящем test configuration:

- status не становится 200;
- client response не содержит `SECRET_KEY`;
- middleware не скрывает исключение;
- log сохраняет request ID без полного request body.

Удали временную view после опыта.

## Обязательные сценарии

1. Новый request без ID получает валидный ID.
2. Допустимый входной ID обрабатывается по заявленному контракту.
3. Слишком длинный/неверный ID не отражается обратно как есть.
4. Header присутствует на 200, 404 и предусмотренной 503.
5. Duration неотрицателен.
6. Один request создаёт одну итоговую log-запись.
7. Body/cookie/auth header не попадают в log.
8. Исключение не маскируется успешным status.

## Контрольные вопросы

1. В каком порядке идут request и response?
2. Когда short-circuit допустим?
3. Почему нужен monotonic clock?
4. Что нельзя логировать?

---

# День 6. Signals, security checks и smoke tests

## Паспорт задания

- **Цель:** принять обоснованное решение по signal, проверить security settings и автоматизировать ключевые контракты foundation.
- **Рабочая область:** accounts/common/config/tests; журнал — `day_06_security_signals.md`.
- **Результат:** signal decision table, один допустимый auth-event receiver, security matrix, результаты checks и smoke test suite.
- **Порядок:** классифицируй signal candidates; зарегистрируй один receiver; проверь единственность вызова; составь security table; запусти checks; затем напиши и запусти tests.
- **Наблюдаемый результат:** login event логируется один раз без PII/secret, `check` проходит, deploy warnings объяснены, tests зелёные.
- **Готово, если:** business logic не в signal; receiver не дублируется; warnings не скрыты; settings разделены по среде; tests проверяют внешние контракты.
- **Пример:** `user_logged_in` создаёт безопасную log-запись с user ID/request ID, но не меняет баланс и stock.
- **Обязательно:** задания 1–9 и сценарии. **Рекомендация:** если signal не даёт реальной пользы, оставить его как изолированный учебный опыт и удалить из final после объяснения.

## Теория

Прочитай разделы 37–44.

## Задание 1. Signal decision table

Для событий ниже выбери `explicit service`, `signal` или `не делать сейчас`:

- уменьшение stock после покупки;
- списание balance;
- запись безопасной telemetry при login;
- отправка email после регистрации;
- invalidation необязательного cache;
- создание обязательного BuyerProfile;
- внешний HTTP-вызов поставщику.

Для каждого укажи: причина, failure semantics, transaction concern, тестируемость.

## Задание 2. Auth signal receiver

Реализуй receiver для framework-события успешного login.

Он может только логировать:

- event name;
- user primary key;
- request ID, если доступен.

Не логируй username/email, cookie, session key или password. Зарегистрируй receiver через AppConfig и защити от duplicate registration.

## Задание 3. Receiver proof

Один login должен вызвать один receiver. Logout и failed login не должны ошибочно считаться successful login.

Сохрани фактическое число событий и способ проверки.

## Задание 4. Security settings matrix

В журнале создай колонки:

```text
setting/control | development | production intent | threat | owner/layer | proof
```

Включи минимум: `DEBUG`, `SECRET_KEY`, `ALLOWED_HOSTS`, CSRF middleware, SecurityMiddleware, session cookie secure, CSRF cookie secure, HTTPS redirect, HSTS, clickjacking header.

Не включай production-only значение без описания TLS/proxy предпосылки.

## Задание 5. `manage.py check`

Запусти обычный check. Исправь ошибки и разберись с warnings. Не добавляй blanket silence.

**Результат:** команда проходит, фактическая финальная строка записана.

## Задание 6. `check --deploy`

Запусти deploy checks с явно выбранным settings environment. Для каждого warning запиши:

- почему он возник;
- исправляется сейчас или позже;
- какая deployment предпосылка нужна;
- почему игнорировать молча нельзя.

Не требуется добиться нуля warnings в development любой ценой.

## Задание 7. Secret audit

Проверь tracked/untracked files и выполни текстовый поиск по ожидаемым secret markers без вывода самих секретов.

**Результат:** `.env`, passwords и реальные keys не входят в commit; `.env.example` безопасен.

## Задание 8. Smoke tests

Через Django test tools напиши проверки:

- health 200/JSON;
- health 405;
- readiness success;
- home template;
- autoescape marker;
- quote form valid/invalid;
- admin anonymous redirect;
- active user model;
- request ID header;
- URL reverse.

Tests не требуют запущенного `runserver`.

## Задание 9. Failure test

Добавь минимум одну проверку ошибки, которая подтверждает одновременно:

- правильный failure status;
- безопасное response body;
- отсутствие секрета;
- наличие request ID.

## Обязательные сценарии

1. Receiver выполняется один раз на successful login.
2. Failed login не создаёт событие success.
3. `manage.py check` успешен.
4. Каждый deploy warning классифицирован.
5. Secret audit не находит committed secrets.
6. Все smoke tests проходят.
7. Test database создаётся/удаляется штатно.
8. Нет signal с балансом, stock или обязательной покупкой.

## Контрольные вопросы

1. Почему signal может затруднить отладку?
2. Чем system check отличается от test?
3. Почему не все deploy warnings исправляются одинаково в local environment?
4. Какие механизмы безопасности Django требуют правильного использования разработчиком?

---

# День 7. Итоговый проект «Django Foundation»

## Паспорт задания

- **Цель:** привести накопленный project к воспроизводимому состоянию, достаточному для проектирования ORM-моделей недели 10.
- **Рабочая область:** `day_07_django_foundation/`; итоговые доказательства и инструкции — в его `README.md`.
- **Результат:** Django project с PostgreSQL, custom user, восемью apps, web endpoints, template/form/admin, middleware, безопасной конфигурацией и tests.
- **Порядок:** проведи structural audit; повтори clean setup; проверь endpoints; admin; middleware/signal; security checks; tests; затем README и защиту.
- **Наблюдаемый результат:** новый разработчик следует README, поднимает foundation и получает те же checks/tests без знания твоей локальной машины.
- **Готово, если:** все 25 сценариев ниже проверены; secrets отсутствуют; migrations воспроизводимы; request lifecycle объясняется; scope недели не расширен.
- **Пример:** `python manage.py check` и `python manage.py test` завершаются успешно, а README перечисляет фактические команды в правильном порядке.
- **Обязательно:** весь итоговый контракт, сценарии, документация и защита. **Рекомендация:** исправлять проект по одному слою — config, routing, presentation, middleware, checks.

## Итоговая структура

```text
day_07_django_foundation/
├── manage.py
├── .env.example
├── README.md
├── config/
│   ├── __init__.py
│   ├── asgi.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── accounts/
├── analytics/
├── catalog/
├── common/
├── dealerships/
├── promotions/
├── suppliers/
├── trading/
├── templates/
└── static/
```

Generated migration files входят в project. Local `.env`, logs, caches, virtual environment и любые database dumps не входят.

## Обязанности результата

### Configuration

- settings получают environment values по явному контракту;
- используется PostgreSQL;
- `AUTH_USER_MODEL` указывает на `accounts.User`;
- secrets отсутствуют в tracked files;
- WSGI и ASGI entry points импортируются.

### Applications

- подключены все восемь apps;
- у каждого есть документированная ответственность;
- нет преждевременных domain models;
- `common` содержит только foundation web/infrastructure concerns.

### HTTP

- `/` — HTML home;
- `/health/` — process health без database query;
- `/ready/` — database readiness;
- `/catalog/status/` — временное доказательство подключения app;
- неизвестные paths и methods возвращают правильные statuses;
- route names и namespaces используются вместо hardcoded internal links.

### Presentation и admin

- template inheritance работает;
- static CSS подключён;
- autoescape доказан;
- quote preview form валидируется и защищена CSRF;
- custom user зарегистрирован в admin;
- anonymous admin access требует login.

### Middleware и signals

- request ID/timing middleware безопасно оборачивает response;
- log не содержит secrets или полный body;
- auth signal — только допустимый побочный эффект;
- duplicate receiver исключён;
- transaction/business state signals не меняют.

### Проверка

- `manage.py check` успешен;
- deploy warnings классифицированы;
- migrations применяются к отдельной учебной database;
- smoke tests запускаются без development server;
- README содержит clean setup и troubleshooting.

## Рекомендуемый порядок финальной сборки

1. Убедись, что working tree не содержит secrets.
2. Сверь структуру apps и settings.
3. Создай чистую дополнительную учебную database или согласуй безопасный reset существующей.
4. Повтори migrations по README.
5. Выполни system checks.
6. Запусти tests.
7. Проверь четыре HTTP routes.
8. Проверь admin login/logout.
9. Сравни logs с privacy-ограничениями.
10. Обнови README только фактическими результатами.

## 25 обязательных сценариев

1. Выбранный Python импортирует выбранный Django.
2. Project запускается из документированного каталога.
3. Все восемь apps загружаются.
4. Обычный system check проходит.
5. `DJANGO_DEBUG=false` даёт False.
6. Неизвестное boolean значение отклоняется.
7. Отсутствующий обязательный secret останавливает startup.
8. Используется PostgreSQL, не SQLite.
9. Database name/user безопасно подтверждены.
10. `accounts.User` находится в initial migration.
11. `get_user_model()` возвращает custom user.
12. GET `/health/` возвращает 200 JSON.
13. POST `/health/` возвращает 405.
14. GET `/ready/` возвращает 200 при доступной database.
15. Предусмотренная database failure даёт безопасный 503.
16. Неизвестный route даёт 404.
17. Namespaced reverse возвращает ожидаемые URLs.
18. Home использует base template и context.
19. Учебный HTML marker экранируется.
20. Valid/invalid quote form ведут себя по контракту; CSRF включён.
21. Anonymous admin access перенаправляет на login; superuser входит и выходит.
22. Request ID есть на success и error responses; invalid inbound ID не отражается как есть.
23. Один successful login создаёт ровно одно безопасное signal event.
24. Secret audit не обнаруживает committed `.env`, keys и passwords.
25. Весь smoke test suite проходит без запущенного `runserver`.

## README итогового проекта

Опиши:

1. назначение foundation;
2. границы недели и отложенные функции;
3. requirements и поддерживаемые версии;
4. создание/активацию environment;
5. environment variables без secrets;
6. создание отдельной PostgreSQL database;
7. migrations и superuser;
8. запуск development server;
9. endpoints и их contracts;
10. system checks и tests;
11. known deployment warnings;
12. troubleshooting пяти типичных ошибок;
13. карту apps;
14. следующий шаг недели 10.

## Ограничения

- без SQLite fallback;
- без DRF и сторонних web frameworks;
- без Docker и production server;
- без Redis/Celery;
- без JWT/email workflow;
- без предметных models, кроме минимального custom user;
- без отключения CSRF/security middleware;
- без hardcoded secrets;
- без signal-driven business logic;
- без изменения файлов ученика наставником при обычной проверке.

## Финальное объяснение без подсказки

Ученик должен объяснить:

1. request lifecycle для `/ready/`;
2. project/app distinction;
3. settings и environment boundary;
4. custom user migration order;
5. URL include/name/namespace;
6. template/context/autoescape;
7. admin trust boundary;
8. middleware onion/order;
9. signal decision;
10. security checks и их пределы;
11. health/readiness distinction;
12. почему этот project готов к ORM-неделе, но ещё не является готовым backend.

## Критерий итогового зачёта

- минимум 8/10;
- все 25 сценариев имеют фактический результат;
- нет критической ошибки из `README.md` недели;
- clean setup воспроизводим;
- минимум 18/24 контрольных вопросов всей недели отвечены уверенно;
- код и документация объясняются учеником;
- в `ASSESSMENT.md` явно открыт или закрыт допуск к неделе 10.

# После каждого ревью

Наставник обновляет `ASSESSMENT.md`, сохраняя первую оценку, причины ошибок, обязательные исправления, результат повторной проверки и один конкретный следующий шаг.
