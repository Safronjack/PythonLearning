# Теория недели 5: Web, Linux и Git

Этот модуль связывает Python-код с окружением backend-разработчика. Он не делает тебя сетевым инженером, системным администратором или security-специалистом за одну неделю. Цель — построить правильную модель и безопасно выполнить базовые операции.

## 1. Путь запроса: общая картина

Для обычного HTTPS-запроса по HTTP/1.1 или HTTP/2 упрощённая последовательность выглядит так:

```text
URL
  ↓ разбор адреса
DNS: имя → один или несколько IP
  ↓ выбор адреса и соединение
TCP: надёжный упорядоченный поток байтов
  ↓ защита канала
TLS: сертификат, шифрование, целостность
  ↓ протокол приложения
HTTP request
  ↓ web server / reverse proxy
WSGI или ASGI
  ↓
Python-приложение
  ↓
HTTP response по обратному пути
```

Это модель, а не единственный вариант. HTTP/3 использует QUIC поверх UDP и не проходит через обычное TCP-соединение. DNS может быть уже закэширован. Прокси, CDN и load balancer могут добавить промежуточные узлы.

Не смешивай уровни:

- DNS находит адрес;
- TCP переносит поток байтов;
- TLS защищает транспортный канал;
- HTTP задаёт смысл request/response;
- WSGI/ASGI связывает сервер и Python-приложение;
- приложение выполняет бизнес-логику.

## 2. URL и его части

Пример:

```text
https://api.example.com:8443/cars/42?currency=USD#details
```

Части:

- scheme: `https`;
- hostname: `api.example.com`;
- port: `8443`;
- path: `/cars/42`;
- query: `currency=USD`;
- fragment: `details`.

Fragment обычно обрабатывается клиентом и не отправляется серверу в HTTP request.

```python
from urllib.parse import parse_qs, urlsplit

parts = urlsplit("https://api.example.com:8443/cars/42?currency=USD")
query = parse_qs(parts.query)

print(parts.scheme)
print(parts.hostname)
print(parts.port)
print(parts.path)
print(query)
```

Не разбирай URL цепочкой `.split(":")` и `.split("/")`: IPv6, percent-encoding, userinfo, пустые части и специальные символы делают такой код неверным.

`urlsplit()` разбирает структуру, но не доказывает, что адрес безопасен, принадлежит доверенному владельцу или доступен. Parsing не равен validation.

### Percent-encoding

Пробел и зарезервированные символы кодируются в URL. Для query используй `urlencode`, для отдельных компонентов — подходящие функции `quote`/`unquote`.

```python
from urllib.parse import urlencode

query = urlencode({"model": "Land Cruiser", "currency": "USD"})
print(query)
```

Не кодируй весь готовый URL как один query-компонент.

## 3. DNS

DNS переводит доменное имя в данные, среди которых могут быть IP-адреса:

- A — IPv4;
- AAAA — IPv6;
- CNAME — alias;
- MX — почтовые серверы;
- TXT — текстовые записи разного назначения.

Один hostname может вернуть несколько адресов. Один IP может обслуживать много доменов. DNS имеет TTL и кэшируется на нескольких уровнях.

```python
import socket

addresses = socket.getaddrinfo("localhost", 8000)
for address in addresses:
    print(address)
```

DNS не выбирает HTTP path и не знает бизнес endpoint. Номер порта передаётся resolver API для формирования socket address, но не является частью DNS-имени.

Не делай сетевой запрос к случайному внешнему hostname в учебной практике. `localhost` достаточно для наблюдения API.

## 4. IP, порт и socket

IP определяет сетевой узел/интерфейс в маршрутизации. Port помогает операционной системе доставить данные нужному процессу.

Socket — программная конечная точка связи. Для TCP соединение различается комбинацией адресов и портов клиента/сервера.

`127.0.0.1` — IPv4 loopback: соединение остаётся на текущей машине. `0.0.0.0` при bind означает слушать на всех IPv4-интерфейсах, что расширяет доступность. Для учебного сервера используй `127.0.0.1`.

Порт сам по себе не гарантирует протокол: договорённость «443 обычно HTTPS» не мешает программе слушать другой протокол на этом порту.

## 5. TCP

TCP предоставляет приложению:

- соединение;
- надёжную доставку или ошибку соединения;
- упорядоченный поток байтов;
- контроль потока и перегрузки.

TCP не сохраняет границы сообщений. Два вызова `send()` не обязаны соответствовать двум вызовам `recv()`. Протокол приложения должен уметь определять длину или границы сообщений. HTTP решает framing своими правилами.

TCP handshake устанавливает соединение до обмена прикладными данными. Закрытие соединения и timeout также являются частью корректной работы клиента/сервера.

## 6. TLS и HTTPS

TLS поверх транспорта даёт:

- конфиденциальность канала;
- целостность данных;
- аутентификацию сервера через certificate chain и проверку hostname;
- при отдельной настройке — аутентификацию клиента сертификатом.

TLS не решает authorization: корректный сертификат сервера не означает, что пользователь имеет право купить автомобиль.

Нельзя «чинить» ошибку сертификата отключением проверки. В production нужны доверенная цепочка, совпадающий hostname и актуальная конфигурация.

HTTPS означает HTTP внутри защищённого TLS-канала для HTTP/1.1/2. Содержимое запроса защищено в пути, но конечный сервер его расшифровывает. URL hostname и часть метаданных соединения могут оставаться наблюдаемыми в зависимости от протокола и конфигурации.

## 7. Текст, байты и кодировка

Сеть передаёт bytes. Приложение часто работает со `str`.

```python
message = "Автомобиль"
payload = message.encode("utf-8")
restored = payload.decode("utf-8")

assert restored == message
```

Кодировка должна совпадать у отправителя и получателя. JSON по современным правилам обычно передаётся в UTF-8. WSGI application возвращает iterable из bytes, а не str.

Не исправляй неизвестную кодировку бездумным `errors="ignore"`: данные могут тихо потеряться.

## 8. HTTP request и response

HTTP — stateless application-level request/response protocol. Stateless означает, что каждый request имеет собственный смысл; состояние пользователя добавляют cookies, sessions, tokens и серверное хранилище.

Упрощённый request:

```http
GET /cars/42?currency=USD HTTP/1.1
Host: api.example.test
Accept: application/json

```

Упрощённый response:

```http
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 43
Cache-Control: no-store

{"id":42,"model":"Camry","available":true}
```

Request содержит method, target, protocol version, headers и иногда body. Response содержит status, headers и иногда body.

HTTP не требует нового TCP-соединения для каждого request: соединения могут переиспользоваться. В HTTP/2 несколько потоков запросов могут идти по одному соединению.

## 9. Методы: смысл важнее CRUD-таблицы

### GET

Получить representation ресурса. GET должен иметь safe semantics: клиент не просит изменить состояние.

Логирование GET допустимо как побочный эффект инфраструктуры, но endpoint `GET /delete-car?id=1` нарушает смысл метода.

### HEAD

Как GET по смыслу, но без response body. Полезен для метаданных.

### POST

Передать данные для обработки или создать подресурс. По умолчанию не считается idempotent.

### PUT

Создать или полностью заменить состояние ресурса по известному URI. Idempotent по intended effect.

### PATCH

Частично изменить ресурс. Не гарантированно idempotent: это зависит от формата и операции.

### DELETE

Удалить связь/ресурс. Idempotent по intended effect: повторный response может отличаться (`204`, затем `404`), но требуемое конечное состояние то же.

### OPTIONS

Узнать доступные возможности. Браузер может использовать OPTIONS для CORS preflight.

## 10. Safe и idempotent — разные свойства

Safe: клиент просит только чтение. GET, HEAD, OPTIONS и TRACE определены как safe, хотя TRACE часто отключают из соображений безопасности.

Idempotent: несколько одинаковых запросов имеют тот же intended effect, что один. Safe methods, PUT и DELETE определены как idempotent.

```text
safe ⇒ idempotent
idempotent ⇏ safe
```

DELETE меняет состояние, поэтому не safe, но idempotent. POST может быть сделан идемпотентным на уровне конкретного API, например через idempotency key, однако это дополнительный контракт.

Идемпотентность не означает одинаковый status/body при каждом повторе и не запрещает отдельную запись в access log.

## 11. Классы status codes

- 1xx — промежуточная информация;
- 2xx — request успешно принят/обработан;
- 3xx — перенаправление или использование cache;
- 4xx — request клиента нельзя выполнить по заявленным условиям;
- 5xx — сервер не смог выполнить внешне допустимый request.

Практические статусы:

| Статус | Смысл |
|---:|---|
| 200 | успешный ответ с representation |
| 201 | ресурс создан; часто добавляется `Location` |
| 204 | успех без body |
| 304 | использовать cache representation; body отсутствует |
| 400 | request синтаксически/структурно некорректен |
| 401 | не предоставлена или не принята аутентификация; обычно нужен `WWW-Authenticate` |
| 403 | личность может быть известна, но действие запрещено |
| 404 | ресурс не найден или намеренно скрыт |
| 405 | метод для известного ресурса не поддерживается; нужен `Allow` |
| 409 | конфликт с текущим состоянием ресурса |
| 413 | body слишком большой |
| 415 | media type не поддерживается |
| 422 | структура распознана, но значения семантически недопустимы |
| 429 | слишком много запросов; может использоваться `Retry-After` |
| 500 | неожиданная внутренняя ошибка |
| 502 | upstream вернул плохой ответ |
| 503 | сервис временно недоступен |

Не отвечай `200` с `{"success": false}` на каждую ошибку. Status является частью контракта.

Не возвращай traceback в 500 response: клиенту нужен безопасный общий текст и request id, подробности — в защищённом server log.

## 12. Headers

Header names регистронезависимы. Headers передают метаданные и управление:

- `Content-Type` — тип отправленного body;
- `Accept` — какие response media types клиент готов принять;
- `Content-Length` — длина body в bytes;
- `Authorization` — credentials для выбранной схемы;
- `Cache-Control`, `ETag`, `If-None-Match` — caching;
- `Cookie`, `Set-Cookie` — cookies;
- `Location` — адрес созданного или перенаправленного ресурса;
- `Allow` — методы ресурса после 405;
- `Vary` — какие request headers влияют на cache representation.

`Content-Type` и `Accept` не взаимозаменяемы. Первый описывает фактический body, второй — предпочтения получателя ответа.

Нельзя доверять header только потому, что он существует. Authorization проверяется криптографически/по session storage, Content-Length сопоставляется с лимитом и реально прочитанными bytes.

## 13. JSON на HTTP-границе

JSON поддерживает object, array, string, number, boolean и null. Он не знает `Decimal`, datetime, tuple или Enum.

```python
import json

body = json.dumps(
    {"model": "Camry", "price": "31000.00"},
    ensure_ascii=False,
).encode("utf-8")
```

Практический порядок для входящего JSON:

1. ограничить размер body;
2. проверить ожидаемый `Content-Type`;
3. прочитать ровно доступное тело по интерфейсу сервера;
4. декодировать bytes;
5. разобрать JSON;
6. проверить верхний тип: object/array;
7. проверить поля, типы и бизнес-правила;
8. преобразовать строковую цену в Decimal.

Ошибка JSON-синтаксиса и корректный JSON неверной бизнес-структуры — разные случаи.

## 14. Cookies и server sessions

Cookie — небольшая пара name/value с атрибутами, которую браузер сохраняет и отправляет подходящему origin/path.

Важные атрибуты:

- `Secure` — отправлять только по защищённому соединению;
- `HttpOnly` — запретить обычный доступ из JavaScript;
- `SameSite` — ограничить cross-site отправку;
- `Path`, `Domain` — область действия;
- `Max-Age`/`Expires` — срок.

Session auth часто хранит на клиенте случайный непрозрачный session id в cookie, а состояние сессии — на сервере. Cookie не обязана содержать данные пользователя.

Session id должен быть непредсказуемым, защищённым и заменяться после важных переходов аутентификации. Logout должен инвалидировать серверную сессию.

`HttpOnly` уменьшает кражу cookie через JavaScript, но не устраняет XSS целиком. `SameSite` — важный слой, но не универсальная замена CSRF-защите.

## 15. HTTP caching

Cache уменьшает задержку и нагрузку, но способен раскрыть персональные данные при неверной политике.

Частые директивы:

- `Cache-Control: no-store` — не хранить response;
- `private` — response предназначен для private cache пользователя;
- `public` — разрешить shared caches при прочих условиях;
- `max-age=N` — свежесть в секундах;
- `no-cache` — можно хранить, но перед использованием требуется revalidation; это не синоним no-store.

ETag идентифицирует версию representation:

```text
Response: ETag: "cars-v3"
Next request: If-None-Match: "cars-v3"
Response: 304 Not Modified
```

304 не содержит новое representation body. `Vary: Accept-Encoding` сообщает cache, что representation зависит от header.

Не кэшируй чувствительный response публично без явного анализа.

## 16. REST

REST — архитектурный стиль, а не синоним «JSON по HTTP». Прикладные ориентиры:

- URLs называют ресурсы: `/cars/42`;
- method выражает операцию;
- representations отделены от внутренней модели;
- запрос содержит достаточно контекста для обработки;
- используются стандартные semantics и cache;
- links могут описывать переходы.

Примеры:

```text
GET    /cars
GET    /cars/42
POST   /quotes
PUT    /cars/42
PATCH  /cars/42
DELETE /cars/42
```

Не прячь действие изменения в `GET /cars/42/sell`. Для доменной команды иногда нормален endpoint вроде `POST /cars/42/reservations`, если создаётся reservation resource.

REST API не обязано отражать таблицы базы один к одному.

## 17. RPC и GraphQL

RPC моделирует вызов операции:

```text
POST /rpc
{"method": "calculateQuote", "params": {...}}
```

Это удобно для команд и явных процедур, но можно потерять часть стандартной HTTP-семантики, если всё возвращает 200.

GraphQL обычно предоставляет schema и позволяет клиенту выбрать поля запроса. Часто используется один HTTP endpoint, но внутри остаются типы, resolvers, authorization и ограничения сложности.

Риски/компромиссы GraphQL:

- гибкий выбор данных;
- меньше over-fetching для некоторых клиентов;
- сложнее HTTP caching;
- нужны ограничения глубины/стоимости;
- N+1 не исчезает автоматически;
- authorization проверяется на правильном уровне.

Выбор REST/RPC/GraphQL зависит от клиентов и домена, а не от моды.

## 18. WSGI

WSGI — синхронный интерфейс между Python web server и приложением.

```python
import json


def application(environ, start_response):
    payload = json.dumps({"status": "ok"}).encode("utf-8")
    start_response(
        "200 OK",
        [
            ("Content-Type", "application/json"),
            ("Content-Length", str(len(payload))),
        ],
    )
    return [payload]
```

`environ` содержит request/CGI данные, включая:

- `REQUEST_METHOD`;
- `PATH_INFO`;
- `QUERY_STRING`;
- `CONTENT_TYPE`;
- `CONTENT_LENGTH`;
- `wsgi.input` — stream body.

`start_response(status, headers)` начинает response. Application возвращает iterable из bytes. Ошибки до старта response обрабатываются на границе приложения/server middleware.

WSGI рассчитан на синхронную модель request/response. Он не предоставляет естественный долгоживущий двусторонний WebSocket interface.

`wsgiref.simple_server` — reference server для обучения, не production deployment.

## 19. ASGI

ASGI application — async callable:

```python
async def application(scope, receive, send):
    assert scope["type"] == "http"

    await send(
        {
            "type": "http.response.start",
            "status": 200,
            "headers": [(b"content-type", b"application/json")],
        }
    )
    await send(
        {
            "type": "http.response.body",
            "body": b'{"status":"ok"}',
        }
    )
```

- `scope` — данные соединения/request;
- `receive` — awaitable callable входящих events;
- `send` — awaitable callable исходящих events.

ASGI поддерживает несколько протоколов и долгоживущие соединения, включая WebSocket. Для HTTP body может приходить несколькими events; production-код обязан корректно собирать их и соблюдать лимит.

`async def` не делает синхронную ORM/файловую операцию неблокирующей. Выбор сервера interface и библиотек должен быть согласован.

## 20. WSGI и ASGI — граница, не бизнес-логика

```text
server-specific socket handling
        ↓
WSGI environ/start_response
или ASGI scope/receive/send
        ↓
router / middleware
        ↓
handler
        ↓
service/domain
```

Domain service не должен знать `PATH_INFO` или ASGI event. Web-слой преобразует transport input в типизированные значения и преобразует domain result/error в HTTP response.

Django позднее предоставит request objects, routing, middleware, security protections и response classes. Но смысл методов, статусов и trust boundaries остаётся ответственностью разработчика.

## 21. Trust boundary и defense in depth

Любые данные вне текущей доверенной границы считаются untrusted:

- URL/query/body;
- headers и cookies;
- файл поставщика;
- ответ внешнего API;
- сообщение очереди;
- данные собственной БД, если их мог записать другой путь.

Input validation включает:

- syntactic: JSON корректен, id — integer;
- semantic: quantity положительна, VIN существует;
- authorization: текущий пользователь имеет право на конкретный объект.

Validation не заменяет parameterized SQL, output encoding или authorization. Defense in depth использует несколько независимых контролей.

## 22. Authentication и authorization

Authentication отвечает «кто это?». Authorization — «что этому субъекту разрешено?».

Успешный login не даёт права читать чужую сделку. Проверка роли без object-level authorization тоже недостаточна.

Обычно порядок:

1. получить credentials;
2. аутентифицировать;
3. загрузить actor/context;
4. проверить право на действие и объект;
5. выполнить операцию;
6. безопасно записать audit event.

CORS не выполняет ни authentication, ни authorization.

## 23. Same-origin policy и CORS

Origin определяется сочетанием scheme, host и port. Браузер ограничивает чтение cross-origin response скриптом.

CORS — набор HTTP headers, позволяющий серверу ослабить browser same-origin policy для выбранных origins, методов и headers.

Preflight OPTIONS спрашивает разрешение перед некоторыми cross-origin запросами.

Важные правила:

- allowlist конкретных доверенных origins;
- не отражать любой `Origin` без проверки;
- `Access-Control-Allow-Origin: *` нельзя сочетать с credentialed browser access;
- CORS не защищает от curl, backend-клиента или прямого запроса;
- endpoint всё равно проверяет authentication и authorization;
- CORS не заменяет CSRF controls.

Если cross-origin доступ не нужен, не добавляй CORS headers «на всякий случай».

## 24. CSRF

CSRF заставляет браузер аутентифицированного пользователя отправить нежелательное изменение. Особенно важен cookie-based auth, потому что браузер прикрепляет подходящие cookies автоматически.

Защита:

- safe methods не изменяют состояние;
- framework CSRF middleware/tokens для state-changing requests;
- проверка Origin/Referer как дополнительный слой;
- `SameSite`, `Secure`, `HttpOnly` cookie attributes;
- ограниченные content types/custom headers вместе с строгим CORS для API;
- повторная аутентификация для особо опасных действий.

XSS может обойти многие CSRF-защиты в том же origin, поэтому обе категории исправляются независимо.

## 25. XSS

XSS возникает, когда недоверенные данные интерпретируются браузером как активный HTML/JavaScript вместо текста.

Главная защита — context-aware output encoding и безопасные APIs/templates. Для HTML-текста стандартная библиотека показывает принцип:

```python
from html import escape

safe_text = escape(user_text, quote=True)
```

Кодирование зависит от контекста: HTML body, attribute, URL, JavaScript и CSS требуют разных правил. Нельзя написать одну функцию `sanitize_everything()`.

JSON API должен отдавать корректный `Content-Type: application/json` и не вставлять пользовательский текст в HTML. Клиентское приложение также обязано безопасно отображать данные.

CSP — дополнительный слой, не замена output encoding.

## 26. SQL injection

Опасно:

```python
query = "SELECT * FROM cars WHERE model = '" + model + "'"
```

Безопасный принцип — parameterized query:

```python
cursor.execute(
    "SELECT id, model FROM cars WHERE model = ?",
    (model,),
)
```

Placeholder зависит от драйвера. Значения передаются отдельно от SQL-кода.

Параметры обычно не заменяют имена таблиц, колонок и направление сортировки. Динамические identifiers выбирай из allowlist, а не из прямого ввода.

Экранирование строк вручную и input validation не являются основной заменой параметризации.

## 27. SSRF

SSRF возникает, когда сервер по недоверенным данным выполняет запрос к адресу, выбранному атакующим. Опасны webhook, import by URL, preview и загрузка изображения.

Риски включают доступ к:

- localhost;
- private/link-local адресам;
- metadata service;
- внутренним административным сервисам;
- не-HTTP schemes;
- адресу после redirect или изменения DNS resolution.

Если набор назначений известен, применяй allowlist конкретных hosts/services. Parsing URL и запрет строки `127.0.0.1` недостаточны: существуют IPv6, другие представления адреса, redirects и DNS rebinding.

Надёжная защита включает архитектурное ограничение egress, проверку scheme/host/port, resolution, всех адресов и redirects, timeout и лимит response. На этой неделе произвольные outgoing requests просто запрещены.

## 28. Session, JWT и OAuth 2.0

### Server session

Клиент хранит непрозрачный session id, сервер — session state. Плюсы: простая ревокация и небольшой cookie. Минусы: нужно общее server-side хранилище при масштабировании.

### JWT

JWT — формат компактных claims, которые могут быть подписаны и/или зашифрованы в разных режимах. Частый signed JWT не зашифрован: payload можно прочитать, поэтому туда нельзя помещать секреты.

Проверять нужно не только signature, но и разрешённый algorithm, issuer, audience, expiration и назначение token. Revocation сложнее, если server не хранит состояние.

Не реализуй JWT самостоятельно. Используй поддерживаемую библиотеку и короткие сроки жизни согласно threat model.

### OAuth 2.0

OAuth 2.0 — framework делегированной authorization: resource owner разрешает client получить ограниченный доступ к resource server. Access token не обязан быть JWT.

OAuth 2.0 сам по себе не является протоколом login. Для identity поверх OAuth обычно применяют OpenID Connect.

Не передавай access token в URL query и не логируй его.

## 29. Secrets, ошибки и логи

Секреты:

- не записываются в код;
- не добавляются в Git даже «на минуту»;
- не печатаются;
- передаются через environment или secret manager;
- имеют минимальные права и ротацию.

Логи должны помогать связать событие через request id, но не содержать:

- пароли;
- session ids;
- access/refresh tokens;
- полный Authorization header;
- лишние персональные данные.

Клиентская ошибка содержит стабильный code/message. Внутренняя ошибка логируется подробно на сервере, но response не раскрывает traceback, filesystem path или SQL.

## 30. Shell и terminal

Terminal показывает интерфейс к shell. Shell разбирает командную строку, выполняет expansion и запускает программы.

```sh
command --option argument
```

Shell built-ins (`cd`, `export`) выполняются самим shell. Другие команды обычно являются отдельными программами.

Полезная привычка перед изменяющей командой:

1. `pwd` — где я;
2. `ls` — что здесь;
3. проверить точный target;
4. выполнить узкую операцию;
5. проверить результат.

В учебной неделе нельзя применять рекурсивное удаление и системные изменения.

## 31. Пути и файлы

- absolute path начинается от корня filesystem;
- relative path вычисляется от текущей директории;
- `.` — текущая директория;
- `..` — родительская;
- скрытые Unix-файлы начинаются с `.`.

Базовые команды:

```sh
pwd
ls -la
cd week_05_web_linux_git
mkdir -p sandbox/logs
cp source.txt sandbox/copy.txt
mv sandbox/copy.txt sandbox/renamed.txt
```

Всегда заключай путь с пробелами в кавычки. Не выполняй команды с неразрешённой переменной target.

`rm` удаляет без корзины во многих средах. В этой неделе он не нужен: временные файлы можно оставить до проверки.

## 32. stdin, stdout, stderr и exit code

У процесса обычно есть три потока:

- stdin — вход;
- stdout — обычный результат;
- stderr — диагностика.

```sh
python3 program.py > output.txt
python3 program.py 2> errors.txt
producer | consumer
```

Pipe передаёт stdout первой программы в stdin второй. Это не передача Python-объектов, а поток bytes/text.

Exit code `0` означает успех по Unix-соглашению, ненулевой — ошибку. Проверить последний код можно через `$?`, но следующая команда сразу его заменит.

Хороший CLI:

- полезные данные пишет в stdout;
- диагностику — в stderr;
- возвращает ненулевой код при ошибке;
- не скрывает failure успешным `0`.

## 33. Shell variables, environment и quoting

```sh
app_env="development"
export APP_ENV="development"
python3 -c 'import os; print(os.environ.get("APP_ENV"))'
```

Shell variable живёт в текущем shell. Exported environment variable передаётся дочерним процессам.

Используй кавычки:

```sh
log_file="sandbox/logs/app log.txt"
wc -l "$log_file"
```

Без кавычек whitespace разделит значение на несколько аргументов, а wildcard может развернуться в имена файлов.

Не используй `eval` для пользовательского текста. Не выводи секретную environment variable в журнал ради проверки.

Конструкция `${APP_ENV:-development}` задаёт безопасное значение по умолчанию, не изменяя переменную.

## 34. Права доступа

Три базовых права:

- `r` — read;
- `w` — write;
- `x` — execute для файла или search/traverse для директории.

Группы прав:

- user/owner;
- group;
- others.

```sh
ls -l day_05_linux_cli.sh
chmod u+x day_05_linux_cli.sh
```

Symbolic mode обычно понятнее на старте. В octal `755` означает `rwxr-xr-x`, `644` — `rw-r--r--`.

`chmod 777` почти никогда не является правильным «исправлением permission denied». Сначала выясни владельца, нужную операцию и минимальное право.

Execute на shell script также требует корректный interpreter/shebang или явный запуск `sh script.sh`.

## 35. Процессы и сигналы

Процесс имеет PID, состояние, environment, открытые файлы и родительский процесс.

```sh
ps -p "$worker_pid"
kill -TERM "$worker_pid"
wait "$worker_pid"
```

`SIGTERM` просит процесс корректно завершиться и даёт шанс выполнить cleanup. `SIGKILL` нельзя обработать; это крайняя мера, не первый выбор.

Фоновый запуск через `&` возвращает управление shell. `$!` содержит PID последнего фонового процесса. Учебный сценарий обязан завершить и `wait` созданный процесс даже при ошибке; для этого полезен `trap`.

Не отправляй сигнал PID, который не был создан твоим учебным сценарием.

Linux предоставляет `/proc` для наблюдения процессов и системы. На macOS такой filesystem обычно отсутствует, поэтому Linux-специфичные эксперименты будут повторены позже в контейнере.

## 36. Логи и текстовые инструменты

Базовое чтение:

```sh
head -n 5 sandbox/logs/app.log
tail -n 5 sandbox/logs/app.log
grep 'ERROR' sandbox/logs/app.log
```

`grep` выбирает строки. `sed` преобразует поток. `awk` удобно работает с полями.

```sh
grep 'ERROR' sandbox/logs/app.log | sed 's/ERROR/error/'
awk '{print $1, $2}' sandbox/logs/app.log
```

Не редактируй production log in-place. Для учебной обработки выводи преобразование в stdout или новый файл.

При поиске по проекту разработчик часто использует `rg`, если он установлен: он быстрее и учитывает удобные правила обхода.

Structured logging позднее позволит обрабатывать JSON fields вместо ненадёжного разрезания текста по пробелам.

## 37. Swap — только обзор

Swap использует disk как поддержку виртуальной памяти, когда RAM недостаточно или kernel решает переместить страницы. Он намного медленнее RAM.

Наличие swap не исправляет memory leak и не заменяет лимиты контейнера. Thrashing возникает, когда система постоянно переносит страницы и почти не выполняет полезную работу.

В этом модуле запрещено создавать, включать или менять swap. Достаточно знать признаки давления памяти и позже читать системные метрики.

## 38. Git: три области

Git хранит snapshots проекта и историю переходов.

Полезная модель:

```text
working tree --git add--> index/staging --git commit--> repository history
```

- working tree — текущие файлы;
- index — точный набор следующего commit;
- repository — сохранённые commits и refs.

`git status` показывает отношения между областями. `git diff` обычно показывает unstaged changes. `git diff --staged` — staged changes.

Commit — snapshot с parent, author/committer metadata и message. Это не просто «сохранённый diff».

## 39. Первый безопасный workflow

```sh
git status
git diff
git add path/to/file
git diff --staged
git commit -m "Add quote validation"
git log --oneline --decorate --graph
```

Добавляй точные пути, чтобы не захватить секрет или временный файл. Перед commit всегда смотри staged diff.

Хороший commit:

- решает одну понятную задачу;
- проходит доступные проверки;
- не содержит секретов и мусора;
- имеет сообщение в повелительном стиле;
- достаточно мал для ревью.

## 40. Branch и merge

Branch — изменяемая ссылка на commit. Создание branch почти не копирует файлы.

```sh
git switch -c feature/catalog-filter
```

Новые commits двигают текущую branch. Merge объединяет истории и может создать merge commit.

Fast-forward возможен, когда целевая branch не расходилась. Тогда ссылка просто перемещается вперёд.

Перед switch проверь `git status`. Git часто откажется переключать branch, если это уничтожит локальные изменения, но не стоит полагаться на отказ как на стратегию хранения.

## 41. Merge conflict

Conflict означает, что Git не может автоматически выбрать итоговое содержимое.

В файле появляются markers:

```text
<<<<<<< HEAD
текущий вариант
=======
входящий вариант
>>>>>>> feature
```

Правильный процесс:

1. прочитать обе версии и требования;
2. вручную создать корректный итог;
3. удалить все markers;
4. запустить проверки;
5. `git add` исправленного файла;
6. завершить merge commit;
7. проверить log и содержимое.

Нельзя выбрать `ours`/`theirs`, не понимая смысл. Успешная команда merge не гарантирует корректную бизнес-логику.

## 42. Rebase

Rebase переносит последовательность commits на новую base и создаёт commits с новыми hashes.

```text
до:    A---B---C  main
        \
         D---E    feature

после: A---B---C---D'---E' feature
```

Rebase делает локальную историю линейнее, но переписывает identity commits. Не rebase общую опубликованную branch без согласованного workflow.

При conflict rebase останавливается. После исправления и `git add` используется `git rebase --continue`. Для безопасного отказа — `git rebase --abort`.

В лаборатории rebase выполняется только на личной непубличной branch.

## 43. Безопасная отмена

- `git revert <commit>` создаёт новый commit, отменяющий effect старого; подходит для общей истории.
- `git restore path` восстанавливает working tree из выбранного источника и может уничтожить незаписанные изменения — сначала смотри diff.
- `git restore --staged path` убирает файл из index, обычно сохраняя working tree.
- `git reset` двигает branch/index в зависимости от режима; на старте нужен редко.
- `git reset --hard` уничтожает незаписанные изменения и в учебном процессе запрещён.

Не используй случайные команды отмены из интернета. Сначала назови, что хочешь изменить: working tree, index или history.

Если секрет попал в commit, обычное удаление новым commit не стирает его из истории. Секрет нужно немедленно отозвать/ротировать, затем отдельно очищать историю по согласованной процедуре.

## 44. Pull request и review

Pull request — предложение объединить branch, место обсуждения и автоматических проверок. Он не является командой Git и относится к hosting platform.

Хорошее описание содержит:

- цель;
- контекст;
- список изменений;
- способ проверки;
- риски и ограничения;
- screenshots/API examples при необходимости;
- связанные задачи.

В этой неделе реальный PR не публикуется. Ты создашь `PULL_REQUEST.md`, имитирующий качественное описание изменения.

## 45. Gitflow и более простой workflow

Классический Gitflow использует долгоживущие `main`, `develop`, feature, release и hotfix branches. Он может быть полезен для релизного процесса, но тяжёл для небольшого проекта.

Для учебного backend достаточно:

```text
main
  └── короткая feature branch
          ├── маленькие commits
          ├── проверки
          └── pull request → merge
```

Trunk-based development использует короткоживущие branches и частую интеграцию. Выбор зависит от команды, частоты релизов и CI, а не от универсального правила.

## 45.1. Agile, Scrum и Kanban

**Agile** — семейство ценностей и принципов разработки с короткой обратной связью, поставкой небольшими частями и готовностью менять план по мере получения знаний. Это не название одной конкретной методологии и не отсутствие планирования.

**Scrum** — framework с ограниченными по времени sprint, определёнными ролями, событиями и artefacts. Он помогает регулярно выбирать цель, проверять результат и улучшать процесс. Daily Scrum — синхронизация движения к sprint goal, а не отчёт начальнику.

**Kanban** визуализирует поток работы и ограничивает work in progress. Базовая доска может иметь колонки `Backlog → In progress → Review → Done`, но ценность появляется из явных правил перехода, WIP limits и измерения потока, а не из самих колонок.

Подходы не отменяют инженерную дисциплину. Маленький commit, code review, automated checks и понятный Definition of Done помогают любому выбранному процессу.

## 45.2. CI и CD

**Continuous Integration (CI)** — частое объединение небольших изменений с автоматическими проверками. Типичная последовательность:

```text
format/lint → type check → tests → security checks → build
```

**Continuous Delivery** означает, что прошедшее проверки изменение готово к выпуску, но production release может подтверждаться человеком. **Continuous Deployment** автоматически выпускает каждое прошедшее изменение. Аббревиатура CD используется для обоих понятий, поэтому значение нужно уточнять.

Pipeline не доказывает отсутствие ошибок: он только быстро и одинаково выполняет заданные проверки. Слабые tests дают слабую уверенность даже при зелёном CI.

## 45.3. TDD, BDD и DDD

**TDD** использует короткий цикл:

```text
red: тест фиксирует требуемое поведение и падает
green: минимальная реализация делает тест зелёным
refactor: структура улучшается при зелёных тестах
```

TDD — способ проектирования и получения быстрой обратной связи, а не цель покрыть тестами каждую строку. Он особенно полезен для чистых правил и контрактов, но не обязан быть единственным способом работы.

**BDD** формулирует наблюдаемое поведение на языке предметной области. Форма `Given / When / Then` помогает выразить контекст, действие и ожидаемый результат. BDD — не просто переименование test functions и не замена общения с заказчиком.

**DDD** фокусируется на сложной предметной области, общей терминологии и границах моделей. Ubiquitous language означает, что бизнес и разработчики одинаково используют значимые термины, например различают `quote`, `order` и `payment`. DDD не равно «создать много классов» и может быть избыточен для простой CRUD-задачи.

На этой неделе эти подходы изучаются обзорно. TDD/BDD углубляются в тестовом этапе, DDD — при моделировании итогового проекта, CI/CD — при автоматизации поставки.

## 46. Архитектура итогового HTTP-сервиса

```text
server.py
  локально связывает wsgiref и application
        |
application.py
  method/path routing, request parsing, error → HTTP mapping
        |
catalog.py
  данные и чистые операции каталога/quote

responses.py
  JSON body, status и headers

security.py
  body limit, media type, безопасные headers, request id

checks.py
  вызывает WSGI application напрямую без реальной сети
```

Endpoints:

```text
GET  /health
GET  /cars
GET  /cars/{id}
POST /quotes
```

Сервис не хранит покупку и не меняет склад. `/quotes` вычисляет representation предложения; поэтому повторный одинаковый request не списывает деньги.

## 47. Типичные ошибки недели

1. URL разбирают через split.
2. DNS называют HTTP redirect.
3. TCP считают протоколом сообщений.
4. TLS принимают за authorization.
5. Fragment ожидают на сервере.
6. Safe и idempotent считают синонимами.
7. DELETE называют safe.
8. Любой success возвращает 201.
9. 401 и 403 смешивают.
10. `Content-Type` и `Accept` меняют местами.
11. `no-cache` считают полным запретом хранения.
12. JSON number автоматически считают Decimal.
13. WSGI возвращает str вместо bytes.
14. ASGI body читают как единственное обязательное событие.
15. CORS считают firewall/auth.
16. Cookie auth используют без анализа CSRF.
17. Validation считают полной защитой от XSS/SQLi.
18. SQL строят f-string.
19. SSRF «защищают» одной regex.
20. Signed JWT считают зашифрованным.
21. OAuth называют форматом token или готовым login.
22. Секрет печатают для диагностики.
23. Shell variable используют без кавычек.
24. `chmod 777` применяют без анализа.
25. Фоновый процесс оставляют запущенным.
26. Git commit делают без просмотра staged diff.
27. Rebase общей branch выполняют без согласования.
28. Conflict markers удаляют без смыслового объединения.
29. `reset --hard` используют как обычную отмену.
30. Учебный WSGI server называют production-ready.

## 48. Контрольные прогнозы

Сначала запиши ответ, затем запускай безопасный пример.

### Прогноз 1. Fragment

Для URL `https://example.test/cars?limit=5#top` какие части попадут в HTTP request target?

### Прогноз 2. TCP reads

Клиент сделал два `send()`. Обязан ли сервер получить ровно два отдельных блока через два `recv()`?

### Прогноз 3. DELETE

Первый DELETE вернул 204, повторный — 404. Может ли method оставаться idempotent?

### Прогноз 4. Content headers

Клиент отправляет JSON и хочет JSON. Какую роль имеют `Content-Type` и `Accept`?

### Прогноз 5. Cache-Control

Одинаковы ли `no-cache` и `no-store`?

### Прогноз 6. WSGI body

```python
def application(environ, start_response):
    start_response("200 OK", [])
    return ["hello"]
```

Что нарушено?

### Прогноз 7. CORS

Если endpoint разрешил `Access-Control-Allow-Origin`, может ли curl отправить request без authentication?

### Прогноз 8. CSRF

Почему cookie-based session может сопровождать forged request без явного чтения cookie атакующим сайтом?

### Прогноз 9. SQL

Можно ли безопасно передать имя column обычным value placeholder? Что делать вместо прямой подстановки?

### Прогноз 10. Shell quoting

```sh
log_file="app log.txt"
wc -l $log_file
```

Сколько path arguments может увидеть команда и как исправить?

### Прогноз 11. Git staged state

Файл изменён и добавлен в index, затем изменён ещё раз. Что покажут `git diff` и `git diff --staged`?

### Прогноз 12. Rebase

Сохранятся ли hashes перенесённых commits после rebase?

## 49. Вопросы самопроверки

1. Какие этапы проходит обычный HTTPS request?
2. Чем URL hostname отличается от IP и port?
3. Что гарантирует TCP и чего не гарантирует?
4. Что защищает TLS и что остаётся задачей приложения?
5. Из каких частей состоят HTTP request и response?
6. Чем safe method отличается от idempotent?
7. Когда использовать 200, 201 и 204?
8. Чем 400, 401, 403, 404, 405, 409, 415 и 422 отличаются?
9. Чем `Content-Type` отличается от `Accept`?
10. Чем `no-cache` отличается от `no-store`?
11. Как связаны cookie и server session?
12. Какие идеи отличают REST, RPC и GraphQL?
13. Как вызывается WSGI application?
14. Что означают scope, receive и send в ASGI?
15. Чем authentication отличается от authorization?
16. Почему CORS не является защитой API от всех клиентов?
17. Когда возникает CSRF и как его снижает framework?
18. Почему XSS требует context-aware output encoding?
19. Почему parameterized query защищает от SQL injection?
20. Почему безопасная SSRF-защита сложнее проверки URL-строки?
21. Чем session, JWT и OAuth 2.0 отличаются?
22. Что означают stdin, stdout, stderr и exit code?
23. Как working tree, index и repository связаны?
24. Чем merge, rebase и revert отличаются?

## 50. Что будет позже

- SQL и PostgreSQL — недели 6–8;
- Django request/response, routing и middleware — недели 9–11;
- DRF и production authentication/authorization — недели 12–14;
- полноценные security tests — недели 15–16;
- Docker/Linux networking — недели 20–22;
- CI/CD и реальный pull request workflow — неделя 22 и проектные спринты;
- reverse proxy, TLS termination, production server и observability — production-этапы.

## 51. Официальные источники

- [RFC 3986: URI](https://www.rfc-editor.org/rfc/rfc3986.html);
- [RFC 9110: HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110.html);
- [RFC 9111: HTTP Caching](https://www.rfc-editor.org/rfc/rfc9111.html);
- [RFC 6265: HTTP State Management](https://www.rfc-editor.org/rfc/rfc6265.html);
- [Python urllib.parse](https://docs.python.org/3.11/library/urllib.parse.html);
- [Python socket](https://docs.python.org/3.11/library/socket.html);
- [Python ssl](https://docs.python.org/3.11/library/ssl.html);
- [PEP 3333 — WSGI](https://peps.python.org/pep-3333/);
- [Python wsgiref](https://docs.python.org/3.11/library/wsgiref.html);
- [ASGI specification](https://asgi.readthedocs.io/en/stable/specs/main.html);
- [OWASP Input Validation](https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html);
- [OWASP XSS Prevention](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html);
- [OWASP CSRF Prevention](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html);
- [OWASP SQL Injection Prevention](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html);
- [OWASP SSRF Prevention](https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html);
- [OAuth 2.0 — RFC 6749](https://www.rfc-editor.org/rfc/rfc6749.html);
- [JWT — RFC 7519](https://www.rfc-editor.org/rfc/rfc7519.html);
- [Git documentation](https://git-scm.com/docs);
- [Linux man-pages](https://www.kernel.org/doc/man-pages/);
- [Principles behind the Agile Manifesto](https://agilemanifesto.org/principles.html);
- [The Scrum Guide](https://scrumguides.org/scrum-guide.html);
- [The Official Guide to the Kanban Method](https://kanban.university/kanban-guide/);
- [Martin Fowler: Continuous Integration](https://martinfowler.com/articles/continuousIntegration.html).
