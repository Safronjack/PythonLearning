# Теория недели 9: основа Django

## Как работать с конспектом

Неделя 9 — первый контакт с Django. Не пытайся сразу запомнить все настройки и команды. Главная задача — построить точную карту: где начинается запрос, кто выбирает view, кто создаёт response, где хранится конфигурация и почему приложения не должны знать обо всём проекте.

Для каждого дня:

1. прочитай только назначенный раздел;
2. ответь на прогнозы до запуска Django;
3. перепечатай короткие примеры самостоятельно;
4. внеси изменение в учебный project;
5. проверь его командой или HTTP-запросом;
6. объясни результат без конспекта.

Примеры ориентированы на Django 5.2 LTS и Python 3.11. Перед фактическим началом недели patch-версии проверяются заново.

---

# День 1. Django project, application и первый запуск

## 1. Что даёт web framework

На неделе 5 мы вручную собирали WSGI application: разбирали method/path, выбирали handler и формировали status, headers и body. Django выполняет эту инфраструктурную работу и предоставляет согласованные компоненты:

- URL dispatcher;
- request и response objects;
- templates и forms;
- middleware;
- authentication и sessions;
- ORM и migrations;
- admin;
- security controls;
- testing tools.

Framework не отменяет HTTP, SQL и Python. Он предоставляет правила и готовые механизмы поверх них. Если view делает запрос в базу, за ORM всё равно существует SQL; если браузер отправляет форму, за ней всё равно существует HTTP request.

## 2. MVT без мистики

Django часто описывают как MVT:

- **Model** хранит структуру и правила данных;
- **View** принимает request и возвращает response;
- **Template** превращает context в текст, обычно HTML.

В других экосистемах слово controller может описывать часть обязанностей Django view и URL dispatcher. Важнее понимать поток, чем спорить о названии архитектурного шаблона.

На неделе 9 основной объект изучения — web-слой. Полные domain models появятся на неделе 10.

## 3. Project и app

**Django project** — конфигурация всего сайта: settings, корневые URLs, WSGI/ASGI entry points.

**Django app** — Python package с одной предметной или инфраструктурной ответственностью, который подключается в `INSTALLED_APPS`.

Один project может содержать много apps. App не обязан быть отдельным сайтом. Например:

```text
config       project configuration
accounts     пользователи и аккаунты
catalog      марки и модели автомобилей
dealerships  автосалоны и их остатки
```

Плохая граница — делать один app на каждую таблицу. Другая крайность — один app `core`, содержащий всё приложение.

## 4. Что создаёт `startproject`

Типичная структура:

```text
manage.py
config/
    __init__.py
    settings.py
    urls.py
    asgi.py
    wsgi.py
```

- `manage.py` запускает management commands с settings текущего project;
- `settings.py` хранит конфигурацию;
- `urls.py` является корневой таблицей маршрутов;
- `wsgi.py` экспортирует WSGI application;
- `asgi.py` экспортирует ASGI application.

`manage.py` не является web server и не содержит бизнес-логику.

## 5. `django-admin` и `manage.py`

`django-admin` — общий командный интерфейс Django. `manage.py` задаёт settings module конкретного проекта, поэтому внутри project обычно используется именно он.

Полезные команды первой недели:

```text
python manage.py check
python manage.py runserver
python manage.py startapp <name>
python manage.py makemigrations
python manage.py migrate
python manage.py createsuperuser
python manage.py test
python manage.py showmigrations
```

Не запускай команду механически. Перед ней ответь:

- что она читает;
- что она изменяет;
- можно ли её безопасно повторить;
- как проверить результат.

## 6. Development server

`runserver` удобен для обучения и локальной разработки. Он автоматически перезапускается после многих изменений и показывает диагностическую информацию.

Он не предназначен для production. Позже приложение будет запускаться подходящим WSGI/ASGI server за reverse proxy.

## 7. App registry и `AppConfig`

Во время настройки Django загружает installed applications и их конфигурацию. `AppConfig` содержит metadata приложения и hook `ready()`.

В `ready()` нельзя без необходимости:

- обращаться к production database;
- выполнять долгую работу;
- запускать сетевые запросы;
- создавать данные;
- регистрировать receiver так, что он дублируется.

Частое допустимое применение — импорт модуля, который регистрирует signal receivers. Даже в этом случае нужен ответ на вопрос, почему явный вызов функции не лучше.

## Прогноз до запуска

1. Запустится ли `manage.py`, если settings module нельзя импортировать?
2. Создаёт ли `startapp` таблицы в database?
3. Должен ли app `catalog` импортировать корневой `config.urls`?
4. Подходит ли `runserver` для production?

## Самопроверка

1. Чем project отличается от app?
2. Какую обязанность выполняет view?
3. Зачем нужны `asgi.py` и `wsgi.py`?
4. Что делает `INSTALLED_APPS`?

---

# День 2. Settings, environment, PostgreSQL и custom user

## 8. Settings — исполняемая конфигурация

Django settings — Python module. При обращении через `django.conf.settings` Django лениво загружает выбранный settings module.

Настройка должна быть:

- определена однозначно;
- различима между development и production;
- проверяема при старте;
- свободна от секретов в Git.

Не нужно превращать первую конфигурацию в сложную систему из десятка файлов. Сначала важна прозрачность.

## 9. Environment variables

Environment передаёт значения снаружи процесса. Все значения приходят строками.

```python
import os

database_name = os.environ["POSTGRES_DB"]
```

Для обязательного секрета квадратные скобки полезны: приложение сразу падает с понятной причиной, если переменной нет. `get()` подходит, когда безопасный default действительно существует.

### Ловушка логических значений

```python
debug = bool(os.getenv("DJANGO_DEBUG", "False"))
```

Эта запись неверна: непустая строка `"False"` истинна.

Нужен явный parser с заранее выбранными допустимыми значениями, например `true/false` и `1/0`. Неизвестное значение лучше отклонить, чем молча интерпретировать.

## 10. Секреты и `.env.example`

`SECRET_KEY` участвует в криптографической подписи. Production key должен быть длинным, случайным и секретным.

В Git можно хранить `.env.example`:

```text
DJANGO_SECRET_KEY=replace-me
DJANGO_DEBUG=true
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1
POSTGRES_DB=dealership_week9
POSTGRES_USER=student
POSTGRES_PASSWORD=replace-me
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
```

Это не настоящий `.env`. Значения явно показывают, что их нужно заменить.

## 11. PostgreSQL connection

`DATABASES["default"]` описывает backend, database name, user, password, host и port. Пароль не печатается в logs или доказательствах.

Перед `migrate` нужно подтвердить:

- используется PostgreSQL backend;
- имя database учебное;
- пользователь ожидаемый;
- соединение не указывает на рабочую систему.

SQLite нельзя оставлять скрытым fallback: успешный запуск с другой СУБД создаёт ложное доказательство.

## 12. Custom user создаётся сразу

Django предоставляет заменяемую user model. Для нового проекта безопасно создать минимальный класс на основе `AbstractUser` и сразу задать:

```python
AUTH_USER_MODEL = "accounts.User"
```

Это нужно сделать **до** первой команды `migrate` и до migrations других apps, которые ссылаются на пользователя.

Причина: таблицы auth, foreign keys и many-to-many relations связываются с выбранной user model. Смена после создания схемы требует сложной ручной миграции.

Custom user должен появиться в первой migration приложения `accounts`, обычно `0001_initial.py`.

На неделе 9 не нужно сразу менять username на email-login, писать manager или authentication backend. Минимальный наследник `AbstractUser` оставляет пространство для будущего развития.

## 13. Ссылки на user model

В model fields в будущем используется `settings.AUTH_USER_MODEL`, а в исполняемом коде — `get_user_model()` там, где нужен сам класс.

Не импортируй `django.contrib.auth.models.User` напрямую в проекте с custom user.

## 14. Migrations

Migration — версионированное описание изменения schema, а не backup и не произвольный SQL-файл.

Порядок первого запуска:

1. создать `accounts`;
2. определить `User`;
3. задать `AUTH_USER_MODEL`;
4. выполнить `makemigrations accounts`;
5. проверить migration;
6. только затем выполнить `migrate`.

`makemigrations` создаёт migration files. `migrate` применяет их к database. Это разные действия.

## Прогноз до запуска

1. Что вернёт `bool("False")`?
2. Что изменяет `makemigrations`, а что — `migrate`?
3. Почему custom user нельзя спокойно заменить после первых migrations?
4. Можно ли печатать весь `DATABASES` для доказательства подключения?

## Самопроверка

1. Какие settings являются секретными?
2. Почему `.env.example` разрешён в Git?
3. Где должен появиться custom user?
4. Чем `settings.AUTH_USER_MODEL` отличается от `get_user_model()`?

---

# День 3. URL dispatcher, view, request и response

## 15. Путь запроса в Django

Упрощённый синхронный путь:

```text
web server → middleware(request) → URL resolver → view → middleware(response) → web server
```

До view Django создаёт `HttpRequest`. View обязана вернуть `HttpResponse` или совместимый subclass.

## 16. URL pattern

`path()` связывает route, view и необязательное name. Route не начинается со слеша:

```python
path("health/", health_view, name="health")
```

Корневой URLconf может делегировать routes приложению через `include()`. Это позволяет app владеть своим URL-пространством.

## 17. Names и namespaces

Жёстко записанный URL `"/catalog/cars/"` ломается при изменении маршрута. Именованный route можно разрешить через `reverse()` или template tag `url`.

Namespace устраняет коллизии одинаковых имён:

```text
catalog:list
dealerships:list
```

Для app URLconf обычно задаётся `app_name`.

## 18. Path converters

Converter проверяет и преобразует часть URL до view:

```text
cars/<int:car_id>/
```

Если сегмент нельзя преобразовать в `int`, этот pattern не совпадёт. Это не заменяет проверку существования объекта в базе.

## 19. Function-based view

Минимальная view получает request:

```python
def health_view(request):
    ...
```

View может прочитать:

- `request.method`;
- `request.path`;
- `request.GET`;
- `request.POST`;
- `request.headers`;
- `request.user` после AuthenticationMiddleware.

На этой неделе view остаются маленькими. Бизнес-расчёты не должны поселяться внутри HTTP-функции.

## 20. Response classes

- `HttpResponse` — произвольное тело;
- `JsonResponse` — JSON с правильным content type;
- `HttpResponseNotAllowed` — неподдерживаемый method;
- `HttpResponseBadRequest` — некорректный request;
- `HttpResponseRedirect`/`redirect()` — перенаправление;
- `Http404`/`get_object_or_404()` — отсутствие ресурса.

`JsonResponse` по умолчанию ожидает dictionary. Для другого top-level JSON value требуется осознанное решение. API-контракты полноценно появятся с DRF.

## 21. `404` и `405`

- `404 Not Found`: route/resource не найден;
- `405 Method Not Allowed`: путь понятен, method для него не разрешён.

Эти статусы нельзя менять местами ради удобства.

## 22. Redirect и reverse

Redirect сообщает клиенту другой URL; он не вызывает другую view внутри текущей функции. Для вычисления URL по name используется reverse resolution.

## Прогноз до запуска

1. Совпадёт ли `path("cars/<int:id>/", ...)` со строкой `/cars/abc/`?
2. Что должна вернуть обычная Django view?
3. Чем `include()` отличается от импорта всех views в корневой URLconf?
4. Когда нужен `405`, а не `404`?

## Самопроверка

1. Кто выбирает view?
2. Для чего route name?
3. Что делает path converter?
4. Почему response body и HTTP status — разные части контракта?

---

# День 4. Templates, static files, forms и admin

## 23. Template и context

Template хранит представление, а view передаёт ей context:

```python
return render(request, "common/home.html", {"project_name": "Dealership"})
```

Шаблон не должен выполнять тяжёлую бизнес-логику или произвольные вызовы Python. Его задача — представить уже подготовленные данные.

## 24. Template inheritance

Базовый template задаёт общий каркас, а дочерние templates заполняют blocks. Это предотвращает копирование `<html>`, navigation и footer в каждую страницу.

```text
templates/
    base.html
    common/
        home.html
```

Имена с app-префиксом уменьшают вероятность коллизий.

## 25. Autoescaping и XSS

Django templates обычно автоматически экранируют переменные в HTML context. Текст вроде `<script>` отображается как текст, а не выполняется.

Это не универсальная защита для всех контекстов:

- JavaScript;
- CSS;
- URL;
- HTML, намеренно помеченный safe.

Не использовать `safe` или отключение autoescape для непроверенного ввода.

## 26. Static files

CSS, изображения и JavaScript — static assets. В development их может обслуживать Django при подходящей настройке. В production это отдельная задача deployment-слоя.

Template подключает static через соответствующий tag, а не через случайный относительный путь.

## 27. Forms и CSRF

Для state-changing browser form обычно используется POST и CSRF token. CSRF middleware проверяет, что запрос пришёл из ожидаемого контекста браузерной сессии.

CSRF token не является login, authorization или XSS-защитой. Он решает конкретную угрозу подделки запроса.

Глобальное отключение CSRF ради работающей формы — критическая ошибка.

## 28. Admin

Django admin — интерфейс для доверенных сотрудников, а не готовый публичный frontend и не API.

Чтобы войти, пользователь обычно должен иметь `is_staff=True`. Permissions определяют доступные действия.

Custom user на основе `AbstractUser` можно зарегистрировать с `UserAdmin`. После этого admin знает, как отображать и редактировать стандартные user fields.

Admin нельзя открывать всему интернету без deployment controls. На учебном этапе проверяется только корректное локальное поведение.

## 29. Superuser

`createsuperuser` создаёт привилегированного пользователя через management command. Не записывай пароль в README, shell history примеров или fixtures.

## Прогноз до запуска

1. Выполнится ли HTML из обычной template-переменной с `<script>`?
2. Является ли admin заменой пользовательского API?
3. Нужно ли добавлять CSRF token в GET-ссылку?
4. Кто должен готовить вычисленные данные: template или view/service?

## Самопроверка

1. Что такое context?
2. Зачем template inheritance?
3. Чем static file отличается от template?
4. Что защищает CSRF middleware?

---

# День 5. Request lifecycle, middleware и logging

## 30. Middleware как слой вокруг view

Middleware получает callable `get_response` и возвращает callable. Упрощённая форма:

```python
class ExampleMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # действия до view
        response = self.get_response(request)
        # действия после view
        return response
```

Это infrastructure concern: request id, security headers, sessions, authentication, metrics. Основная логика покупки не должна зависеть от скрытого middleware.

## 31. Onion model и порядок

На request-фазе middleware выполняются сверху вниз по `MIDDLEWARE`. На response-фазе — в обратном порядке.

Если middleware возвращает response без `get_response`, внутренние слои и view не выполняются. Это называется short-circuit. Он допустим для понятной задачи, например немедленного отклонения запрещённого host, но должен быть осознанным.

Порядок важен. Например, AuthenticationMiddleware использует session и поэтому располагается после SessionMiddleware на request-пути.

## 32. Request ID

Request ID помогает связать logs одного запроса. Учебное middleware может:

1. принять безопасный существующий ID или создать новый;
2. положить его в request attribute;
3. добавить в response header;
4. включить в структурированный log context.

Не доверяй неограниченной строке заголовка: проверь длину и формат либо всегда создавай UUID на стороне приложения.

## 33. Измерение времени

Для duration используется монотонный clock. Системное календарное время может сдвигаться.

Timing middleware измеряет время полного вызова внутренних слоёв и view. Это не полноценный profiler и не показывает причину задержки.

## 34. Безопасное logging

Полезные поля:

- request ID;
- method;
- нормализованный path;
- status code;
- duration;
- actor ID, если это действительно нужно и допустимо.

Нельзя логировать целиком:

- Authorization header;
- cookies;
- password;
- reset token;
- request body;
- database DSN с паролем.

User-controlled строки могут содержать управляющие символы. Логирование должно использовать нормальный logger и безопасное представление, а не неограниченную ручную склейку.

## 35. Exception boundary

Не каждую ошибку нужно ловить в своей view. Django имеет стандартную обработку 404/403/500. Middleware или custom error handler не должны превращать все ошибки в `200 OK`.

В development подробный traceback помогает разработчику. При `DEBUG=False` клиент не должен получать locals, settings и secret values.

## 36. WSGI и ASGI

Django поддерживает WSGI и ASGI entry points. Наличие `asgi.py` само по себе не делает синхронную view асинхронной и не ускоряет CPU-bound работу.

На этой неделе пишется синхронное middleware. Async Django изучается только при реальном use case после закрепления обычного request lifecycle.

## Прогноз до запуска

1. В каком порядке два middleware увидят response?
2. Выполнится ли view после short-circuit?
3. Можно ли безопасно записать весь request body для отладки login?
4. Делает ли ASGI-файл весь project асинхронным?

## Самопроверка

1. Что обязательно должен вызвать обычный middleware?
2. Почему порядок в `MIDDLEWARE` важен?
3. Какие поля безопасно логировать?
4. Чем error response отличается от скрытия исключения?

---

# День 6. Signals, security checks и smoke tests

## 37. Signals

Signal позволяет sender уведомить receivers о событии. Это полезно, когда отправитель не должен знать обо всех независимых наблюдателях, особенно при интеграции с framework или сторонним app.

Но signal скрывает поток управления. Если отправитель и получатель находятся в одном проекте и выполняют одну критическую операцию, явный service call обычно понятнее.

## 38. Когда signal допустим

Хороший кандидат:

- небольшая telemetry/logging реакция;
- invalidation необязательного cache;
- интеграционная реакция на framework event;
- побочный эффект, отказ которого не должен создавать половинчатую основную операцию.

Плохой кандидат:

- списание денег;
- изменение stock;
- создание обязательной покупки;
- цепочка скрытых записей в несколько models;
- сетевой запрос в `post_save`.

## 39. Регистрация receiver

Receiver часто подключается из `AppConfig.ready()`. Нужно избегать повторной регистрации. Возможны decorator, явный `connect()` и `dispatch_uid`.

Django хранит handlers как weak references по умолчанию. Локальная функция может быть собрана garbage collector; параметр `weak=False` применяется только при понятной причине и жизненном цикле.

В учебном итоговом project допустимо вообще не оставлять custom signal, если таблица решений доказывает, что текущим сценариям он не нужен. Понимание важнее наличия конструкции.

## 40. Встроенная безопасность Django

Django предоставляет важные механизмы, но они работают только при правильном использовании:

- templates autoescape снижают риск XSS в HTML context;
- CSRF middleware защищает state-changing browser requests;
- ORM parameterization снижает риск SQL injection;
- password hashers не хранят пароль открытым текстом;
- session framework управляет session identifiers;
- SecurityMiddleware добавляет и поддерживает часть security controls;
- XFrameOptionsMiddleware помогает против clickjacking;
- host validation использует `ALLOWED_HOSTS`.

Framework не исправляет небезопасный raw SQL, `mark_safe` на пользовательском вводе, раскрытый `SECRET_KEY` или неверные permissions.

## 41. Критические settings

- `DEBUG=False` в production;
- секретный и отдельный production `SECRET_KEY`;
- точный `ALLOWED_HOSTS`;
- HTTPS/cookie/HSTS settings после появления настоящего TLS и proxy;
- правильный `CSRF_TRUSTED_ORIGINS` только для доверенных origins;
- отсутствие секретов в source control.

Нельзя механически включать HSTS с огромным временем на неизвестном домене. Security setting всегда связывается с deployment topology.

## 42. System checks

`manage.py check` выполняет статические проверки project configuration. Многие commands запускают часть checks автоматически.

`manage.py check --deploy` добавляет production-oriented проверки. В development он ожидаемо сообщает warnings. Их задача — сформировать список действий перед deployment, а не заставить ученика поставить небезопасные фиктивные значения или заглушить всё через `SILENCED_SYSTEM_CHECKS`.

System checks не являются penetration test и не доказывают полную безопасность.

## 43. Минимальные Django tests

Django test client вызывает приложение без внешнего HTTP server. На этой неделе достаточно smoke tests:

- route возвращает ожидаемый status;
- response имеет ожидаемый content type/body;
- URL name разрешается;
- template используется;
- custom user является активной user model;
- request-id header присутствует;
- admin route требует authentication.

Тест должен проверять контракт, а не внутреннюю строку реализации. Полная стратегия pytest изучается позже.

## 44. `check`, test и ручная проверка

Три вида доказательства дополняют друг друга:

- system check ищет известные проблемы конфигурации;
- automated test проверяет заданный контракт;
- ручная проверка помогает увидеть страницу и developer feedback.

Один вид не заменяет остальные.

## Прогноз до запуска

1. Подходит ли `post_save` для обязательного списания денег?
2. Означает ли пустой вывод `check` полную безопасность?
3. Нужно ли исправлять development project так, чтобы `check --deploy` не показывал ни одного предупреждения любой ценой?
4. Требует ли Django test client запущенного `runserver`?

## Самопроверка

1. Почему signals усложняют tracing?
2. Где регистрировать receiver?
3. Что проверяет `ALLOWED_HOSTS`?
4. Чем system check отличается от test?

---

# День 7. Архитектура Django-каркаса итогового проекта

## 45. Каркас, а не готовый продукт

Итог недели 9 — foundation. Он должен отвечать на вопросы:

- как project запускается;
- где configuration;
- какая database используется;
- кто является user model;
- как запрос попадает во view;
- где находятся templates/static;
- как работает admin;
- какие middleware оборачивают запрос;
- как проект проверяется.

Он ещё не реализует продажи и закупки.

## 46. Границы приложений

Начальная ответственность:

| App | Ответственность сейчас | Позже |
|---|---|---|
| `accounts` | custom user | регистрация, email, JWT |
| `catalog` | URL/app skeleton | марки, модели, характеристики |
| `dealerships` | URL/app skeleton | салоны, inventory, sales |
| `suppliers` | URL/app skeleton | поставщики, catalog, procurements |
| `trading` | URL/app skeleton | offers и purchases |
| `promotions` | URL/app skeleton | акции и скидки |
| `analytics` | URL/app skeleton | отчёты и metrics |
| `common` | home/health/readiness, middleware | общие web primitives |

`common` не должен становиться свалкой. Если код принадлежит конкретной предметной области, он остаётся в её app.

## 47. Dependency direction

Project configuration подключает apps. Domain app не должна импортировать корневой URLconf или случайно читать внутренности соседней app.

Допустимая связь оформляется явным публичным контрактом. На неделе 9 связи минимальны, потому что domain models ещё не реализованы.

## 48. Health и readiness

Упрощённо:

- **health/liveness** отвечает, что process способен обработать request;
- **readiness** отвечает, готово ли приложение обслуживать полезный трафик, например доступна ли database.

На учебном проекте `/health/` не обязан обращаться в database, а `/ready/` выполняет лёгкую проверку соединения. Response не должен раскрывать DSN, traceback или внутренние credentials.

## 49. Вертикальный срез

Вертикальный срез проходит через все нужные слои и заканчивается проверкой. Для foundation первый срез может быть:

```text
URL name → view → JsonResponse → middleware header → Django test
```

Такой подход лучше, чем создать восемь пустых apps и считать функциональность готовой.

## 50. Definition of done

Project считается готовым к неделе 10, когда:

- запускается из документированного окружения;
- использует PostgreSQL;
- custom user настроен до migrations;
- URLconf и apps имеют понятные границы;
- templates/admin/middleware работают;
- secrets не попали в Git;
- checks и tests имеют фактические результаты;
- ученик способен объяснить request lifecycle.

## Итоговые вопросы

1. Проследи `/health/` от socket/server interface до response.
2. Почему `AUTH_USER_MODEL` — решение начала проекта?
3. Почему `INSTALLED_APPS` — больше, чем список папок?
4. В каком порядке проходит request и response через middleware?
5. Почему signal не подходит для основной покупки автомобиля?
6. Чем template autoescape помогает и где его недостаточно?
7. Что доказывает `check --deploy`, а чего не доказывает?
8. Почему успешный `runserver` ещё не означает production readiness?

## Материал на будущее

Следующие темы намеренно отложены:

- models, relationships, QuerySet и migrations глубже — неделя 10;
- первый полный business vertical slice — неделя 11;
- DRF — неделя 12;
- accounts/JWT/email — неделя 13;
- permissions и security tests — неделя 14;
- pytest и integration testing — недели 15–16;
- Redis/Celery — недели 17–19;
- Docker и production deployment — недели 20–22.

Не добавляй эти инструменты в foundation раньше времени: лишняя технология затрудняет понимание базового Django request lifecycle.
