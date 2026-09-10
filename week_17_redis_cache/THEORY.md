# Теория недели 17: Redis и кэширование

## Как изучать материал

Для каждого дня сначала прочитайте объяснение, письменно ответьте на вопросы самопроверки и предскажите результаты маленьких команд. Затем переходите к `PRACTICE.md`. Redis-команды выполняются только в выделенном учебном namespace.

---

## День 1. Что такое Redis и где его граница

Redis — отдельный server process, который принимает команды клиентов и хранит значения по keys преимущественно в памяти. Приложение обращается к нему по сети или Unix socket, поэтому даже локальный вызов способен завершиться timeout, connection error или частичным отказом инфраструктуры.

### Базовая модель

```text
Django process → redis-py / Django cache backend → Redis server → RAM
                                                ↘ optional RDB/AOF disk files
```

Key — последовательность bytes. Value имеет Redis type: string, hash, set и т. д. Один key в конкретный момент имеет один type. Попытка выполнить hash-команду над string приводит к `WRONGTYPE`.

Redis выполняет отдельные команды атомарно: другая команда не вклинится внутрь `INCR` или `HSET`. Это не означает, что последовательность `GET → вычисление в Python → SET` атомарна. Для нескольких действий нужны подходящая атомарная команда, transaction/WATCH, script или другой корректный primitive.

### Redis не заменяет PostgreSQL

В Dealership API PostgreSQL хранит пользователей, деньги, автомобили, Offer и продажи. Redis на этой неделе хранит только восстанавливаемые copies/coordination keys. Если удалить cache, система должна вычислить ответ из PostgreSQL.

Redis lock не заменяет `transaction.atomic()` и row locks для денежных и складских данных. Он может уменьшить дублирование дорогого cache loader, но source-of-truth invariant остаётся в PostgreSQL.

### Logical databases и namespace

Redis может выбирать logical database number, но это не отдельный security boundary, пользователь или процесс. Команды `FLUSHDB` очищают выбранную logical DB. Поэтому tests используют отдельный endpoint/instance и уникальный prefix:

```text
test:pythonlearning:run-42:stats:dealership:17
```

Production, development и test URLs хранятся в environment, не в Git. Password/token нельзя включать в отчёт.

### Connection behavior

Client должен иметь bounded connect/socket timeouts. Connection pool переиспользует connections; открывать новый TCP connection на каждый request неэффективно. Retry допустим только для выбранных transient errors и идемпотентных операций. Повтор `GET` обычно безопасен, а бездумный retry составной write может повторить эффект.

### Самопроверка

1. Почему Redis-вызов может упасть, даже если Python-код корректен?
2. Что означает атомарность одной Redis-команды?
3. Почему database number не заменяет test isolation?
4. Какие данные должны остаться в PostgreSQL?

Документация: [redis-py: connect to the server](https://redis.io/docs/latest/develop/clients/redis-py/connect/) — соединение, bytes/decoded responses и TLS options.

---

## День 2. Основные типы Redis

Тип выбирается по операциям, а не потому, что структура знакома из Python.

### String

Redis string — bytes value. Подходит для JSON/короткого cached payload, counters и флагов.

```text
SET learning:car:1:name "Volvo XC60"
GET learning:car:1:name
INCR learning:stats:hits
```

`INCR` атомарен, хотя значение хранится как string representation integer.

### Hash

Hash хранит field-value pairs одного небольшого объекта:

```text
HSET learning:car:1 brand Volvo model XC60 stock 4
HGET learning:car:1 stock
HGETALL learning:car:1
```

Hash удобен для частичного обновления fields, но Redis не проверяет Django schema/types и не создаёт relations.

### Set

Set — неупорядоченное множество уникальных members. Оно подходит для membership/tags:

```text
SADD learning:dealership:7:brands Volvo BMW Volvo
SISMEMBER learning:dealership:7:brands Volvo
SMEMBERS learning:dealership:7:brands
```

Нельзя обещать порядок `SMEMBERS`.

### Sorted set

Sorted set хранит уникальный member и числовой score. Подходит для ranking:

```text
ZADD learning:supplier:rating 91 supplier-4 84 supplier-8
ZRANGE learning:supplier:rating 0 -1 WITHSCORES
```

При равном score порядок определяется lexicographical rules Redis, но business tie-break лучше задавать явно, если он важен.

### Stream

Stream — append-only log entries с IDs и fields. `XADD` добавляет событие, `XRANGE` читает диапазон. Consumer groups, delivery и pending entries относятся к более глубокой обработке событий и не заменяют Celery автоматически.

На этой неделе stream изучается обзорно: записать несколько безопасных учебных событий и прочитать их порядок. Он не используется для production queue.

### Lists и прочие типы

Lists существуют, но не входят в обязательную лабораторию: будущую очередь Celery нельзя собирать вручную из `LPUSH/BRPOP`. Bitmaps, HyperLogLog, geospatial, JSON/modules и vector types остаются расширением после core roadmap.

### Pipeline и transaction

Pipeline группирует команды, уменьшая сетевые round trips. По умолчанию поведение redis-py pipeline может включать transaction; это нужно задавать/понимать явно. Redis transaction выполняет очередь команд без interleaving, но не даёт PostgreSQL-style rollback уже выполненных команд из-за runtime error. `WATCH` позволяет optimistic check-and-retry.

### Самопроверка

1. Почему counter лучше увеличивать `INCR`, а не `GET` + Python + `SET`?
2. Когда hash удобнее string JSON?
3. Почему нельзя утверждать порядок set?
4. Чем score sorted set отличается от позиции list?

Документация: [Redis data types](https://redis.io/docs/latest/develop/data-types/) — прямые руководства по strings, hashes, sets, sorted sets и streams.

---

## День 3. Key design, TTL и cache-aside

### Cache-aside

```text
request
  → build canonical key
  → GET cache
      hit  → return cached payload
      miss → load from PostgreSQL → serialize → SET with TTL → return
```

Cache hit и miss обязаны возвращать один public response contract. Cache не должен менять типы, порядок, permissions или rounding.

### Хороший key

```text
<env>:dealership-api:v2:stats:dealership:<id>:scope:<scope>:filters:<digest>
```

Key включает всё, что меняет результат:

- environment/service;
- schema/key version;
- resource/organization identifier;
- role/permission/user scope, если response различается;
- canonical query parameters;
- generation/version для invalidation.

Параметры нормализуются: одинаковые filters в разном порядке дают один key. Нельзя включать raw token/email и бесконечную пользовательскую строку; допустим bounded digest от canonical representation.

### TTL

TTL ограничивает срок жизни key и верхнюю границу stale window, но не гарантирует свежесть до истечения. `TTL` обычно возвращает:

- положительное число — оставшиеся секунды;
- `-1` — key существует без expiration;
- `-2` — key отсутствует.

Не утверждайте точное значение TTL после сетевого round trip; проверяйте допустимый диапазон. Для expiry integration test используйте короткий срок и bounded polling deadline, а не длинный безусловный sleep.

В Django timeout `None` означает бессрочно, `0` — не кэшировать, обычное число — seconds. Для business cache нужен явный конечный TTL.

### Cache penetration и пустой результат

Если несуществующий dealership постоянно запрашивают, каждый miss идёт в PostgreSQL. Можно cache-ировать специальный `NOT_FOUND` sentinel на короткий TTL. Он должен отличаться от настоящего `None`/пустого списка и инвалидироваться при создании ресурса.

### Serialization

Кэшируйте стабильные primitive/JSON-compatible data, а не lazy QuerySet или active model instance. Формат получает version. Не десериализуйте unsafe pickle из недоверенного Redis.

### Самопроверка

1. Какие параметры обязательно входят в key статистики?
2. Почему TTL не заменяет invalidation?
3. Чем cache miss отличается от закэшированного `NOT_FOUND`?
4. Почему hit и miss сравниваются по полному response contract?

Документация: [Django cache framework](https://docs.djangoproject.com/en/5.2/topics/cache/) — Redis backend, low-level API, timeouts, prefixes и versions.

---

## День 4. Invalidation и согласованность

**Invalidation** удаляет или делает недоступной cached copy после изменения source data. Это одна из самых сложных частей caching, потому что статистика зависит не от одной table.

### Dependency map

Для dealership statistics источниками могут быть:

- dealership/organization status;
- cars и stock;
- sales/transactions;
- offers;
- promotions;
- supplier choices;
- permissions/scope.

Каждый write use case должен иметь owner и trigger invalidation.

### Почему после commit

Если cache удалить внутри transaction, а PostgreSQL затем откатится, другой request загрузит старую database state и снова заполнит cache. Поэтому invalidation связывается с successful commit через `transaction.on_commit()`.

```text
BEGIN → update PostgreSQL → register invalidation → COMMIT → invalidate
BEGIN → update PostgreSQL → register invalidation → ROLLBACK → no invalidation
```

### Delete-on-write

В cache-aside обычно сначала обновляют source of truth, затем удаляют cached copy. Следующий read заполняет её заново. Попытка вручную «синхронно обновлять» все варианты cache увеличивает количество ordering bugs.

### Version/generation key

Если endpoint имеет много комбинаций filters, перечислить все keys трудно. Можно хранить generation:

```text
stats-generation:dealership:17 = 8
stats:dealership:17:g:8:filters:<digest>
```

После commit generation атомарно увеличивается. Новые reads используют новую generation, а старые keys доживают короткий TTL. Нужно обработать отсутствующий generation key и не допустить вечных orphan keys.

### Если invalidation сломалась после commit

Database commit уже нельзя «отменить» ошибкой Redis callback. При доступном Redis generation переключается сразу. Если Redis недоступен, ошибка должна быть видна в metric/log, а contract обязан честно выбрать поведение: например, допустить stale response только до конечного TTL. Гарантировать мгновенную invalidation при длительном outage без долговечного outbox/retry нельзя. Такой механизм относится к будущим Celery-неделям; сейчас его фиксируют как gap, а не изображают надёжным.

### Signals, services и bulk operations

Signal удобен для общего model event, но скрывает behavior и может не сработать для `QuerySet.update()`, raw SQL или bulk operations. Explicit service-level invalidation виднее, но все write paths должны его использовать. Выбор фиксируется в карте и тестируется на реальных paths.

### Race read/write

Окно возможно даже при delete-on-write: reader загрузил старое значение, writer committed и удалил key, затем reader записал старое значение обратно. Versioned generation снижает риск: reader пишет в key старой generation, который новые requests больше не читают.

### Самопроверка

1. Почему invalidation выполняется после commit?
2. Когда generation удобнее списка keys?
3. Как bulk update может обойти signal?
4. Как version key защищает от старого reader после write?

Документация: [Django transactions: `on_commit()`](https://docs.djangoproject.com/en/5.2/topics/db/transactions/#performing-actions-after-commit) — безопасный запуск cache invalidation после успешной транзакции.

---

## День 5. Cache stampede и отказ Redis

### Stampede

Если hot key истёк, множество requests одновременно видят miss и запускают дорогой PostgreSQL loader. Это cache stampede.

**Single-flight** разрешает одному caller загрузить значение, остальные коротко ждут его результат или используют документированный fallback.

```text
miss → try lock
  owner     → double-check → load → cache → safe release
  non-owner → bounded wait/poll → cached value or fallback
```

### Требования к lock

- acquisition атомарна;
- lock имеет короткий TTL против вечной блокировки;
- каждый owner имеет уникальный token;
- release проверяет ownership;
- wait ограничен deadline;
- loader exception освобождает lock в `finally`;
- после acquisition выполняется второй cache check;
- lock не объявляется защитой PostgreSQL business transaction.

На практике можно использовать поддерживаемый `redis-py Lock`, а не писать собственный небезопасный `SET NX` + безусловный `DEL`.

### TTL jitter

Если тысяча keys получила одинаковый TTL одновременно, они могут истечь вместе. Небольшой bounded random jitter разносит expirations. В tests random source контролируется, а итоговый TTL остаётся в разрешённом диапазоне.

### Fail-open для cache

Так как Redis здесь accelerator, при ожидаемом connection/timeout error statistics endpoint может вычислить корректный ответ из PostgreSQL:

- не возвращать stale/повреждённые данные;
- записать structured error/metric без secret;
- ограничить ожидание Redis;
- не ловить все `Exception` и не скрывать programming bug;
- определить, пытаемся ли записать cache после read error;
- отличить degraded-ready от полностью unhealthy.

### Retry

Современное поведение `redis-py` зависит от версии/config. Retry проверяется при activation. Повтор разрешён только для transient errors и безопасных операций; количество, backoff и общий time budget ограничены.

### Самопроверка

1. Что вызывает cache stampede?
2. Зачем второй cache check после lock acquisition?
3. Почему безусловный `DEL lock-key` опасен?
4. Какие errors можно обработать fail-open, не скрывая баг кода?

Документация: [Redis cache-aside with redis-py](https://redis.io/docs/latest/develop/use-cases/cache-aside/redis-py/) — TTL, invalidation и owner-safe single-flight pattern.

---

## День 6. Persistence, eviction, роли, безопасность и metrics

### RDB и AOF

- **RDB** создаёт point-in-time snapshots. Файлы компактны и удобны для backup/startup, но между snapshots возможна потеря последних writes.
- **AOF** записывает changing operations и может синхронизироваться с разной частотой. Обычно даёт меньший potential loss, но требует больше disk I/O и rewrite.
- Можно использовать оба механизма, один или ни одного — решение зависит от роли и допустимой потери.

Для чистого cache persistence часто не обязательна: значения восстановимы. Для broker/result backend последствия потери другие, поэтому их конфигурация проектируется отдельно на следующих неделях.

### maxmemory и eviction

Redis хранит данные в ограниченной RAM. `maxmemory` задаёт limit, `maxmemory-policy` — что делать при заполнении. Cache обычно допускает eviction; broker не должен случайно терять pending message из-за cache LRU.

Популярные варианты:

- `allkeys-lru` — приблизительно вытеснять давно не использованные keys;
- `allkeys-lfu` — приблизительно вытеснять редко используемые;
- `volatile-*` — выбирать только keys с TTL;
- `noeviction` — не удалять автоматически, а отклонять новые memory-growing writes.

Выбор зависит от workload. При смешении persistent и cache keys eviction становится трудно объяснить — лучше отдельные instances/deployments/configurations.

### Три роли

| Роль | Потеря данных | TTL/eviction | Persistence | Главный риск |
|---|---|---|---|---|
| Cache | обычно допустима | обязательная стратегия | часто optional | stale/stampede/memory |
| Broker | pending messages важны | arbitrary eviction опасна | по delivery contract | потеря/duplicate delivery |
| Result backend | зависит от необходимости результата | result TTL обычно нужен | по contract | рост памяти/потеря результата |

Logical DB numbers/prefixes уменьшают collisions, но не дают разные `maxmemory-policy` одной instance. Для разных ролей предпочтительны отдельные Redis deployments/instances.

### Безопасность

Redis не публикуется в интернет. Доступ ограничивают private network/firewall, ACL least privilege и TLS при недоверенной сети. Credentials приходят из environment/secret storage. Application user не должен иметь административные команды вроде `CONFIG`/`FLUSHALL`.

### Наблюдаемость

Минимум приложения:

- cache hits/misses и hit ratio;
- loader calls/duration;
- cache read/write errors;
- stampede lock acquired/wait/fallback;
- invalidation count/failures;
- payload size.

Минимум Redis:

- memory/maxmemory;
- connected clients;
- evicted/expired keys;
- keyspace hits/misses;
- command latency/errors;
- persistence status, если включена.

Логи не содержат cached payload, token, email или credentials. High-cardinality user/key labels не отправляются в metrics.

### Самопроверка

1. Чем RDB отличается от AOF?
2. Почему cache и broker требуют разных eviction policies?
3. Какие Redis metrics помогают объяснить низкий hit ratio?
4. Почему Redis port нельзя открывать интернету?

Документация: [Redis persistence](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/) и [key eviction](https://redis.io/docs/latest/develop/reference/eviction/) — выбрать RDB/AOF и memory policy по роли.

---

## День 7. Cached Dealership Statistics API

Итоговый модуль соединяет все части:

```text
authorized request
→ canonical/versioned key
→ bounded cache read
→ hit: deserialize + return
→ miss: single-flight
    → PostgreSQL statistics loader
    → cache with TTL+jitter
→ writes commit in PostgreSQL
→ generation invalidation after commit
→ metrics/logs describe outcome
```

### Проверяемые инварианты

- permissions и response contract одинаковы на hit/miss;
- PostgreSQL остаётся источником истины;
- cached result имеет ограниченную freshness;
- все inputs, влияющие на response, входят в key;
- write commit делает старую generation недоступной;
- invalidation failure после commit имеет явный bounded-staleness contract;
- rollback не вызывает invalidation;
- concurrent cold reads не создают неограниченный loader burst;
- Redis outage не повреждает database и следует failure policy;
- cleanup удаляет только test namespace;
- cache/broker/result-backend decisions не смешаны.

### Coverage и tests

Unit tests проверяют key builder, serialization, TTL/jitter policy и decision branches. Integration tests используют реальные PostgreSQL и отдельный Redis. API tests сравнивают hit/miss/invalidated/degraded responses. Concurrency test проверяет bounded loader calls и final cache value.

### Самопроверка

1. Как доказать, что hit не вызывает loader?
2. Какой write должен инвалидировать statistics?
3. Что произойдёт при Redis timeout?
4. Почему Redis lock не защищает списание денег?

Документация: [Redis cache-aside](https://redis.io/docs/latest/develop/use-cases/cache-aside/) и [Django cache framework](https://docs.djangoproject.com/en/5.2/topics/cache/) — сопоставить архитектурный pattern с framework API.

---

## Словарь недели

- **Keyspace** — совокупность keys Redis.
- **TTL** — оставшийся срок жизни key.
- **Cache hit** — требуемое значение найдено в cache.
- **Cache miss** — значение отсутствует/истекло и требуется loader.
- **Cache-aside** — приложение само читает cache, загружает source и заполняет cache.
- **Invalidation** — удаление или смена generation устаревшей copy.
- **Stampede** — множество одновременных loaders после общего miss.
- **Single-flight** — один loader на key, остальные bounded ждут/fallback.
- **Eviction** — удаление key Redis из-за memory policy.
- **RDB** — snapshot persistence Redis.
- **AOF** — журнал changing Redis operations.
- **Source of truth** — система, чьи данные считаются авторитетными.
- **Graceful degradation** — сохранение корректной ограниченной работы при отказе dependency.
