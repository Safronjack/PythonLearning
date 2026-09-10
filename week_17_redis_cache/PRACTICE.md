# Практика недели 17: Redis и кэширование

## Как сдавать неделю

Начинать только после допуска недели 16. Каждый день:

1. прочитайте тему в `THEORY.md` и обязательные части документации;
2. заполните прогнозы в рабочем журнале до запуска;
3. реализуйте изменения в копии принятого Django-проекта;
4. выполните unit и real Redis/PostgreSQL integration scenarios;
5. запишите exact commands, node IDs, actual results и cleanup evidence;
6. попросите наставника провести проверку;
7. исправьте обязательные замечания самостоятельно.

## Общая безопасность

- `TEST_REDIS_URL` задаётся явно и не совпадает с development/production URL.
- Каждый run использует prefix `test:pythonlearning:<run_id>:`.
- Запрещены `FLUSHALL`, `FLUSHDB`, `KEYS *` и очистка неопределённого pattern.
- Cleanup удаляет только keys, созданные текущим run, через tracked list или bounded `SCAN` по точному prefix.
- Пароли, tokens, email, DSN и cached payload не копируются в journals.
- Реальный Redis обязателен для integration behavior; fake допускается только в unit test интерфейса и не заменяет integration.
- Cache failure не должен повреждать PostgreSQL.

`<project_root>` означает фактический Django root после копирования проекта. Сначала найдите настоящий path, затем впишите его в journal; не создавайте параллельную выдуманную структуру.

---

## День 1. Архитектура и безопасное подключение

### Паспорт дня

**Цель:** научиться безопасно подключать Django/Python к отдельному Redis и наблюдать базовое client-server behavior с bounded failures.

**Рабочий файл или каталог:** production/test configuration внутри `week_17_redis_cache/day_07_cached_statistics/<project_root>/`; журнал `week_17_redis_cache/day_01_redis_architecture.md`; итоговые `KEYSPACE.md` и `SCENARIO_MATRIX.md`, `R01–R08`.

**Результат:** compatibility record, test-only connection config, successful `PING`, connection pool/timeouts, namespace guard и восемь фактических scenarios без глобальной очистки.

**Порядок выполнения:**

1. Перенести принятый Week 16 project и зафиксировать baseline.
2. Проверить версии Redis server/CLI, Python, Django и `redis-py`.
3. Настроить URL через environment и конечные timeouts.
4. Добавить guard для test endpoint/prefix.
5. Выполнить `PING`, `SET/GET`, missing key и wrong type.
6. Проверить controlled connection failure.
7. Очистить только свои keys и заполнить `R01–R08`.

**Наблюдаемый результат:** Redis отвечает на `PING`; value читается с ожидаемым bytes/string contract; неправильный type и unavailable server дают понятные bounded errors; чужие keys не удалены.

**Готово, если:**

- URL/credentials отсутствуют в Git и отчётах;
- connect/socket timeout заданы явно;
- prefix уникален для run;
- подтверждены Redis version и clean Week 16 baseline;
- cleanup ограничена своим prefix;
- `R01–R08` заполнены actual results.

**Пример ожидаемого формата, не решение:**

```text
R02 | PING test Redis | expected PONG | actual PONG | PASS
cleanup: scanned prefix test:pythonlearning:run-...:, deleted 2 owned keys
```

**Обязательно для зачёта:** safe config, 8 scenarios, failure timeout и cleanup evidence.

**Рекомендация:** использовать один application-level client/backend с pool вместо создания connection на каждый request.

### Документация

- [redis-py connection guide](https://redis.io/docs/latest/develop/clients/redis-py/connect/) — обязательно прочитать basic connection, decoded responses и TLS options.
- [redis-py production usage](https://redis.io/docs/latest/develop/clients/redis-py/produsage/) — изучить timeouts, retries, health checks и exception classes.

### Упражнение 1. Baseline и compatibility

**Исходные данные:** принятый Week 16 project, dependency files и доступный test Redis.

**Действие:** запишите source commit, старый test count, versions и официальный compatibility evidence; добавьте `redis` только в правильную dependency group после активации.

**Результат:** воспроизводимый baseline и clean dependency resolution.

**Проверки:** старый full suite; Python/Django/redis-py; Redis server/CLI; import клиента; dependency не продублирована; ничего не устанавливается при подготовке недели.

### Упражнение 2. Safety guard `R01–R02`

**Исходные данные:** `TEST_REDIS_URL` и generated `run_id`.

**Действие:** реализуйте/настройте отказ test suite при отсутствующем test URL или недопустимом prefix; затем выполните `PING`.

**Результат:** опасная конфигурация останавливает tests до write, безопасная даёт PONG.

**Проверки:** env missing; prefix без `test:pythonlearning:`; URL equals known non-test URL; valid config; secret redaction.

### Упражнение 3. Connection и type behavior `R03–R07`

**Исходные данные:** два собственных keys: string и hash, плюс заведомо несуществующий key.

**Действие:** проверьте `SET/GET`, missing result, выбранный decode policy, TTL absence marker и `WRONGTYPE` при несовместимой команде.

**Результат:** пять tests/commands с ожидаемыми values/exceptions.

**Проверки:** Unicode string; integer-like string; missing key; bytes или decoded string по contract; wrong command over existing type.

### Упражнение 4. Bounded outage и cleanup `R08`

**Исходные данные:** заведомо недоступный local endpoint/port и keys текущего prefix.

**Действие:** вызовите `PING/GET` с короткими разумными timeouts; затем выполните точечную cleanup на рабочем endpoint.

**Результат:** expected connection/timeout exception появляется до общего deadline, все owned keys удалены, sentinel вне prefix сохранился.

**Проверки:** connection refused/timeout; exception class; duration bound; client close; external sentinel unchanged; no flush/global scan.

### Вопросы защиты дня

1. Почему Redis — сетевой dependency даже на localhost?
2. Что значит атомарность одной команды?
3. Почему logical DB не является security boundary?
4. Как test guard предотвращает опасную очистку?
5. Какие timeout заданы и зачем оба?
6. Где PostgreSQL остаётся source of truth?

---

## День 2. Redis data types

### Паспорт дня

**Цель:** выбирать Redis structure по требуемым операциям и доказать ее поведение на dealership dataset.

**Рабочий файл или каталог:** Redis lab/test code внутри `day_07_cached_statistics/<project_root>/`; `day_02_data_types.md`; `day_07_cached_statistics/DATA_TYPE_LAB.md`; `SCENARIO_MATRIX.md`, `R09–R20`.

**Результат:** двенадцать изолированных scenarios со string/counter, hash, set, sorted set и обзорным stream, а также сравнение pipeline и transaction.

**Порядок выполнения:**

1. Описать операции, ради которых выбирается каждый type.
2. Создать deterministic dealership dataset под run prefix.
3. Выполнить string/counter scenarios.
4. Выполнить hash и set scenarios.
5. Выполнить sorted set с равными score.
6. Добавить и прочитать stream events без consumer group.
7. Сравнить pipeline modes, выполнить cleanup и заполнить `R09–R20`.

**Наблюдаемый результат:** commands возвращают предсказанные types/values; set не проверяется по случайному порядку; ranking tie имеет зафиксированный contract; stream IDs монотонно упорядочены.

**Готово, если:**

- каждый type выбран по операции, а не по сходству названия;
- используется только run prefix;
- counter increment не реализован через `GET`+`SET`;
- set assertions не зависят от порядка;
- stream не объявлен production queue;
- `R09–R20` и cleanup заполнены.

**Пример ожидаемого формата, не решение:**

```text
R16 | brands add Volvo twice | expected cardinality 1 | actual 1 | PASS
R18 | equal supplier scores | expected documented tie order | actual ...
```

**Обязательно для зачёта:** все пять structures, 12 scenarios, pipeline explanation, безопасная cleanup.

**Рекомендация:** рядом с каждым command записать complexity из official command page для используемого диапазона.

### Документация

- [Redis data types](https://redis.io/docs/latest/develop/data-types/) — обязательно прочитать разделы Strings, Hashes, Sets, Sorted sets и Streams.
- [redis-py pipelines and transactions](https://redis.io/docs/latest/develop/clients/redis-py/transpipe/) — различить batching, transaction и optimistic locking.

### Упражнение 1. Strings и counter `R09–R11`

**Исходные данные:** car display name, serialized small payload и hit counter=0.

**Действие:** сохраните/read string, overwrite value и выполните несколько atomic `INCR`.

**Результат:** три scenarios показывают last write, exact counter и chosen decode types.

**Проверки:** Unicode; overwrite; increment from 0; invalid integer string; missing counter initialization behavior.

### Упражнение 2. Hash `R12–R14`

**Исходные данные:** car fields `brand`, `model`, `stock`, `price`; все значения приведены к documented serialization.

**Действие:** создайте hash, прочитайте field/full map, atomically измените numeric stock подходящей hash-командой.

**Результат:** три scenarios с field-level behavior и final state.

**Проверки:** existing field; missing field; partial update не удаляет другие fields; numeric conversion; wrong type.

### Упражнение 3. Set и sorted set `R15–R18`

**Исходные данные:** dealership brands с duplicate и suppliers с ratings, включая equal score.

**Действие:** проверьте uniqueness/membership, затем ranking/range и tie behavior sorted set.

**Результат:** четыре scenarios с order-independent set oracle и explicit ranking policy.

**Проверки:** duplicate; present/absent member; score update existing member; equal score; ascending/descending direction.

### Упражнение 4. Stream и pipeline `R19–R20`

**Исходные данные:** три test events `stock_checked`, `offer_created`, `offer_cancelled` без PII.

**Действие:** добавьте entries с generated IDs, прочитайте range; затем batch несколько independent reads/writes pipeline и объясните transaction flag.

**Результат:** ordered event list и pipeline result list с соответствием command order.

**Проверки:** unique increasing IDs; bounded range/count; missing field handling; pipeline `execute()` result order; no consumer group/Celery claim.

### Вопросы защиты дня

1. Почему `INCR` безопаснее `GET`+`SET` для counter?
2. Что Redis hash не проверяет за Django model?
3. Почему set нельзя сравнивать как ordered list?
4. Как обновляется score existing sorted-set member?
5. Чем stream отличается от Celery task queue?
6. Чем pipeline отличается от transaction guarantee?

---

## День 3. Key design, TTL и cache-aside

### Паспорт дня

**Цель:** реализовать cache-aside для дорогого endpoint статистики без изменения его API/security contract.

**Рабочий файл или каталог:** statistics/cache code and tests внутри `day_07_cached_statistics/<project_root>/`; `day_03_cache_aside.md`; `KEYSPACE.md`; `CACHE_CONTRACT.md`; `SCENARIO_MATRIX.md`, `R21–R32`.

**Результат:** canonical key builder, explicit TTL, safe serialization, miss/hit path, optional short negative cache и 12 scenarios с query/loader evidence.

**Порядок выполнения:**

1. Зафиксировать исходный endpoint contract и query count.
2. Выписать все inputs/scope, влияющие на response.
3. Реализовать pure canonical key builder и unit tests.
4. Настроить Django `RedisCache` через environment.
5. Реализовать miss→loader→set и hit path.
6. Проверить TTL/expiration и negative-result policy.
7. Сравнить response/query count и заполнить `R21–R32`.

**Наблюдаемый результат:** первый request загружает PostgreSQL и создаёт key с TTL; второй identical request возвращает идентичный response без дорогого loader; другой scope/filter не получает чужой result.

**Готово, если:**

- key содержит env/service/version/resource/scope/normalized filters;
- key не содержит PII/token и имеет bounded length;
- hit/miss API responses эквивалентны;
- TTL конечен и проверен диапазоном;
- authorization isolation доказана;
- `R21–R32` имеют actual/query/loader results.

**Пример ожидаемого формата, не решение:**

```text
request 1: cache=MISS, loader_calls=1, queries=7
request 2: cache=HIT, loader_calls=0, response_equal=true
```

**Обязательно для зачёта:** safe keys, cache-aside, TTL, authorization/filter isolation и 12 scenarios.

**Рекомендация:** кэшировать готовую stable primitive payload, а не ORM object/QuerySet.

### Документация

- [Django cache framework](https://docs.djangoproject.com/en/5.2/topics/cache/) — обязательно прочитать Redis backend, low-level cache API, timeout, prefix и version.
- [Redis `EXPIRE`](https://redis.io/docs/latest/commands/expire/) — изучить positive TTL, no-expiry и missing-key states.

### Упражнение 1. Baseline и cache contract `R21–R22`

**Исходные данные:** принятый statistics endpoint, два authorized actors/scopes и фиксированный dataset.

**Действие:** сохраните uncached response, schema, ordering, query count и loader duration; определите freshness/negative-cache policy.

**Результат:** `CACHE_CONTRACT.md` описывает source of truth, payload, TTL, allowed staleness, miss/error behavior.

**Проверки:** positive response; empty stats; forbidden actor; stable ordering; money/decimal representation; no cache yet baseline.

### Упражнение 2. Canonical key builder `R23–R26`

**Исходные данные:** environment, dealership id, role/organization scope, filters in two different orders и schema version.

**Действие:** реализуйте pure builder, нормализующий semantically equal parameters и ограничивающий untrusted portions digest.

**Результат:** четыре unit scenarios на equality/difference/safety/version.

**Проверки:** reordered params same key; changed dealership/filter/scope different key; version changes key; Unicode/long input bounded; no email/token/raw secret.

### Упражнение 3. Miss и hit `R27–R29`

**Исходные данные:** empty cache и fixed PostgreSQL statistics dataset.

**Действие:** первый call получает cache miss и invokes loader; второй identical call читает cache; сравните response, loader calls и query count.

**Результат:** exact API equality, one loader across sequential calls и key with finite TTL.

**Проверки:** first miss; second hit; payload deserialization/types; response headers/body contract; database mutation without invalidation пока используется только для controlled observation, не как final behavior.

### Упражнение 4. TTL, expiry и empty result `R30–R32`

**Исходные данные:** short integration TTL, normal production-like TTL config и несуществующий/empty scope.

**Действие:** проверьте immediate TTL range, bounded expiry polling/reload и chosen negative-cache sentinel.

**Результат:** expiration запускает loader заново; empty cached result отличается от miss; TTL=0/None semantics не используются случайно.

**Проверки:** positive TTL range; expired/missing marker; no-expiry detection fails contract; sentinel short TTL; newly created resource eventually visible per policy; polling has deadline.

### Вопросы защиты дня

1. Какие части входят в key и почему?
2. Как доказано отсутствие cross-user/organization leak?
3. Почему exact TTL assertion хрупок?
4. Чем empty cached result отличается от miss?
5. Как доказано, что hit не запускает loader?
6. Почему TTL не решает немедленную freshness после write?

---

## День 4. Invalidation после commit

### Паспорт дня

**Цель:** связать каждый write, влияющий на statistics, с безопасной invalidation после successful PostgreSQL commit.

**Рабочий файл или каталог:** write services/cache invalidation/tests в `day_07_cached_statistics/<project_root>/`; `day_04_invalidation.md`; `INVALIDATION_MAP.md`; `SCENARIO_MATRIX.md`, `R33–R42`.

**Результат:** dependency map, explicit/versioned invalidation, commit/rollback tests и защита от stale reader/write race.

**Порядок выполнения:**

1. Выписать source tables и все write entry points статистики.
2. Выбрать exact-delete или generation strategy и обосновать.
3. Встроить invalidation в service/другую явную boundary.
4. Запускать её через `transaction.on_commit()`.
5. Проверить create/update/delete и bulk path.
6. Проверить rollback и delayed old reader.
7. Заполнить `R33–R42` и выполнить full suite.

**Наблюдаемый результат:** при доступном Redis после commit следующий read возвращает новые stats; после rollback cache остаётся согласован с неизменившейся PostgreSQL; old reader не делает stale value текущим; invalidation outage даёт видимый bounded-staleness outcome.

**Готово, если:**

- каждый dependency/write path имеет owner/trigger;
- invalidation не выполняется до commit;
- rollback no-invalidation доказан; ошибка invalidation после commit не объявляется мгновенной свежестью и ограничена TTL/failure policy;
- filters не требуют небезопасного wildcard delete;
- bulk/update bypass risk рассмотрен;
- `R33–R42` заполнены.

**Пример ожидаемого формата, не решение:**

```text
sale committed → generation 4→5 → next read MISS → new totals
sale rolled back → generation remains 5 → cached totals still valid
```

**Обязательно для зачёта:** dependency map, commit/rollback, create/update/delete, race reasoning и 10 scenarios.

**Рекомендация:** для множества filter keys использовать generation, позволяя старым keys истечь по TTL.

### Документация

- [Django `on_commit()`](https://docs.djangoproject.com/en/5.2/topics/db/transactions/#performing-actions-after-commit) — обязательно прочитать callback ordering, rollback и test behavior.
- [Redis `INCR`](https://redis.io/docs/latest/commands/incr/) — атомарное увеличение generation counter.

### Упражнение 1. Dependency/write map `R33–R34`

**Исходные данные:** фактический statistics query/service и models из Dealership API.

**Действие:** проследите fields/tables до response и найдите create/update/delete/bulk write paths. Назначьте invalidation trigger.

**Результат:** `INVALIDATION_MAP.md` связывает dependency → writer → transaction boundary → cache scope.

**Проверки:** sale/stock/offer/promotion/supplier/org state по фактическим зависимостям; admin path; serializer update; bulk/raw SQL risk; no imaginary dependency.

### Упражнение 2. Generation contract `R35–R37`

**Исходные данные:** dealership id, current generation missing/known и два filter combinations.

**Действие:** реализуйте initial generation behavior, включите generation в key и atomically advance it after commit.

**Результат:** новые reads переключаются на new namespace; старые keys имеют finite TTL.

**Проверки:** missing generation; increment existing; two filters switch together; concurrent increments monotonic; no wildcard delete.

### Упражнение 3. Commit/rollback `R38–R40`

**Исходные данные:** warm cache и write service с controllable success/failure.

**Действие:** выполните successful commit, rollback before commit и nested transaction/outer rollback по фактической структуре.

**Результат:** callback вызывается только после окончательного commit; response freshness соответствует database.

**Проверки:** callback call count; generation; database state; cached state; cache failure after DB commit по failure policy; metric/log и максимальное stale window.

### Упражнение 4. Delete/bulk/race `R41–R42`

**Исходные данные:** delete или bulk writer и controlled old reader, начавший load до write commit.

**Действие:** проверьте реальный delete/bulk path; затем смоделируйте, что старый reader завершает fill после generation change.

**Результат:** актуальные requests читают new generation; устаревшее значение остаётся только в старом finite-TTL key.

**Проверки:** delete; one bulk path or documented forbidden path; old reader key; new reader key; TTL old key; no cross-namespace deletion.

### Вопросы защиты дня

1. Почему callback расположен после commit?
2. Как generation охватывает множество filters?
3. Почему старые keys не удаляются немедленно и когда это приемлемо?
4. Как signal/bulk operation может создать пробел?
5. Что происходит, если Redis недоступен после DB commit?
6. Как old reader перестаёт быть источником current result?

---

## День 5. Stampede protection и graceful degradation

### Паспорт дня

**Цель:** ограничить число одновременных expensive loaders на hot miss и сохранить корректный endpoint при ожидаемом отказе Redis.

**Рабочий файл или каталог:** cache coordination/failure adapter/tests в `day_07_cached_statistics/<project_root>/`; `day_05_stampede_failures.md`; `STAMPEDE_PLAN.md`; `FAILURE_POLICY.md`; `SCENARIO_MATRIX.md`, `R43–R50`.

**Результат:** bounded owner-safe single-flight, controlled TTL jitter, expected Redis-error fallback и восемь concurrency/failure scenarios.

**Порядок выполнения:**

1. Зафиксировать loader, lock key, TTL и wait budget.
2. Реализовать lock через поддерживаемый redis-py primitive.
3. Добавить double-check и `finally` release.
4. Одновременно запустить несколько cold readers.
5. Проверить owner loss/loader exception/wait timeout.
6. Добавить controlled TTL jitter.
7. Проверить Redis read/write outage policy.
8. Заполнить `R43–R50` и метрики.

**Наблюдаемый результат:** concurrent cold requests возвращают корректный contract, loader calls ограничены; lock не остаётся навсегда; Redis outage приводит к documented PostgreSQL fallback, а не повреждению данных.

**Готово, если:**

- lock имеет TTL, token/ownership и bounded wait;
- после acquisition выполняется cache double-check;
- exception path освобождает owned lock;
- нет безусловного удаления чужого lock;
- обрабатываются только ожидаемые Redis exceptions;
- `R43–R50` и call-count evidence заполнены.

**Пример ожидаемого формата, не решение:**

```text
8 simultaneous cold reads → 8 valid responses, loader_calls=1, lock_key absent
Redis GET timeout → DB response 200, cache_error metric +1
```

**Обязательно для зачёта:** real concurrency, safe lock lifecycle, failure policy и 8 scenarios.

**Рекомендация:** ограничить single-flight одним hot statistics key; не строить универсальную distributed-lock библиотеку.

### Документация

- [Redis cache-aside with redis-py](https://redis.io/docs/latest/develop/use-cases/cache-aside/redis-py/) — обязательно прочитать stampede protection, lock token, TTL и invalidation guidance.
- [redis-py Lock](https://redis.readthedocs.io/en/stable/lock.html) — изучить `timeout`, `blocking_timeout`, ownership и release.
- [redis-py production usage](https://redis.io/docs/latest/develop/clients/redis-py/produsage/) — проверить текущие defaults retry/timeouts, не полагаясь на память.

### Упражнение 1. Single-flight contract `R43–R44`

**Исходные данные:** один empty hot key, fixed DB dataset и 8 synchronized callers.

**Действие:** запустите calls через barrier; owner performs double-check/load/set, остальные bounded wait/read/fallback.

**Результат:** все responses contract-equal, loader call count соответствует принятому bound, workers завершаются.

**Проверки:** simultaneous start; separate execution contexts; one owner; wait deadline; no hanging threads; final TTL/value; cleanup.

### Упражнение 2. Lock lifecycle `R45–R46`

**Исходные данные:** controllable loader exception и ситуация истечения/reacquisition lock другим owner.

**Действие:** вызовите exception inside owner; отдельно докажите, что старый owner не удаляет lock нового owner.

**Результат:** owned lock released or expires; foreign lock remains; failure returns/logs documented outcome.

**Проверки:** `finally`; ownership token; lock TTL; release error; second request recovery; no unconditional `DEL`.

### Упражнение 3. TTL jitter `R47`

**Исходные данные:** base TTL и controlled random values at minimum/maximum bound.

**Действие:** реализуйте pure TTL policy и unit tests для границ jitter.

**Результат:** TTL всегда положителен и внутри documented range; deterministic random source используется в tests.

**Проверки:** min/max random; small base TTL; zero/negative config rejected; no huge stale window.

### Упражнение 4. Redis unavailable `R48–R50`

**Исходные данные:** read connection error, write error after successful loader и unexpected programming exception.

**Действие:** примените `FAILURE_POLICY.md`: expected cache errors fail-open к DB, write error не ломает correct response, unexpected exception не скрывается broad catch.

**Результат:** три tests с response/DB/log/metric assertions и bounded duration.

**Проверки:** GET failure; SET failure; lock failure; correct DB output; no partial DB mutation; secret-safe log; exact exception classes; no unbounded retry.

### Вопросы защиты дня

1. Какой invariant защищает single-flight?
2. Зачем double-check cache после lock?
3. Как ownership защищает новый lock?
4. Что произойдёт, если loader дольше lock TTL?
5. Какие Redis errors fail-open и почему?
6. Почему Redis lock не участвует в покупке последней машины?

---

## День 6. Persistence, eviction, security и observability

### Паспорт дня

**Цель:** принять и доказательно оформить operational policy Redis по его роли, памяти, сохранности, безопасности и метрикам.

**Рабочий файл или каталог:** safe configuration/metrics/tests в `day_07_cached_statistics/<project_root>/`; `day_06_operations.md`; `OPERATIONS_RUNBOOK.md`; `METRICS.md`; `SCENARIO_MATRIX.md`, `R51–R56`.

**Результат:** read-only inspection, role matrix cache/broker/result backend, persistence/eviction decision, ACL/network requirements, metrics и шесть scenarios/checks.

**Порядок выполнения:**

1. Прочитать current Redis config/INFO только разрешёнными commands.
2. Сравнить RDB, AOF и no-persistence для cache.
3. Выбрать maxmemory/eviction policy как proposal.
4. Разделить будущие cache/broker/result backend roles.
5. Описать network/ACL/TLS/secret requirements.
6. Добавить application cache metrics и secret-safe logs.
7. Проверить degraded health/readiness policy.
8. Заполнить `R51–R56` и runbook.

**Наблюдаемый результат:** отчёт объясняет фактическую test config и production recommendation; metrics различают hit/miss/error/invalidation/stampede; cache outage отображается как degraded согласно contract.

**Готово, если:**

- фактическая config не изменяется на общем server;
- persistence/eviction decision связан с допустимой потерей;
- три роли не смешаны одной общей policy;
- Redis не предполагается публично доступным;
- logs/metrics не содержат high-cardinality secrets/PII;
- `R51–R56` заполнены actual evidence.

**Пример ожидаемого формата, не решение:**

```text
role=cache | loss=rebuildable | persistence=optional | eviction=allkeys-lru proposal
cache_get_total{outcome="hit"}=...; no user_id/key label
```

**Обязательно для зачёта:** operational decision, role separation, security checklist, metrics и 6 scenarios.

**Рекомендация:** сохранять read-only `INFO` summary, но не весь output с лишними environment details.

### Документация

- [Redis persistence](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/) — обязательно сравнить RDB, AOF и combined/no-persistence варианты.
- [Redis key eviction](https://redis.io/docs/latest/develop/reference/eviction/) — изучить `maxmemory`, policies и hit/miss/eviction metrics.
- [Redis security](https://redis.io/docs/latest/operate/oss_and_stack/management/security/) — изучить trusted network, ACL, TLS и protected mode.

### Упражнение 1. Read-only inspection `R51`

**Исходные данные:** выделенный test Redis и разрешённые `INFO`/`CONFIG GET` commands.

**Действие:** запишите version, persistence flags/status, maxmemory/policy, memory и stats summary; не меняйте config.

**Результат:** sanitized actual-state table с источником каждой строки.

**Проверки:** server version; `appendonly`/save policy; loading/aof/rdb status; maxmemory/policy; used memory; hits/misses/evicted/expired; no credentials/full client list.

### Упражнение 2. Role/persistence/eviction decision `R52–R53`

**Исходные данные:** три роли из roadmap и допустимость потери каждой.

**Действие:** предложите отдельную policy cache, future broker, future result backend; выберите persistence/eviction and isolation form.

**Результат:** decision table с trade-offs, а не одна config для всех.

**Проверки:** cache rebuildability; pending task loss; result retention; `maxmemory`; eviction effect; separate instance/deployment recommendation; Redis DB number limitation.

### Упражнение 3. Security `R54`

**Исходные данные:** hypothetical dev/CI/production network diagram и application command needs.

**Действие:** составьте минимальный ACL/network/TLS/secret checklist; не применяйте production config.

**Результат:** application identity получает только нужные data commands, не admin/flush/config; port не открыт internet.

**Проверки:** private network/firewall; ACL username; TLS need; secret rotation/source; log redaction; unprivileged process; forbidden commands.

### Упражнение 4. Metrics и degradation `R55–R56`

**Исходные данные:** hit, miss, invalidation, stampede wait и unavailable paths дней 3–5.

**Действие:** добавьте/зафиксируйте counters/timing и health/readiness semantics; вызовите success and cache failure.

**Результат:** metrics change ожидаемо; readiness остается/не остаётся согласно explicit source-of-truth policy; logs structured и safe.

**Проверки:** hit/miss; loader duration; cache errors; invalidation; lock outcome; no user/key/payload labels; Redis down; PostgreSQL down contrast.

### Вопросы защиты дня

1. Какую потерю допускает cache?
2. Чем RDB отличается от AOF?
3. Почему broker нельзя помещать под cache eviction policy?
4. Какие metrics объясняют низкий hit ratio?
5. Какие команды запрещены application ACL?
6. Как health/readiness показывает cache degradation?

---

## День 7. Итоговый проект `Cached Dealership Statistics API`

### Паспорт итогового проекта

**Цель:** собрать безопасный Redis cache вокруг дорогой статистики, сохранив PostgreSQL contract, authorization, freshness и работоспособность при отказе cache.

**Рабочий файл или каталог:** `week_17_redis_cache/day_07_cached_statistics/`.

**Результат:** рабочий Django API с unit/integration/API/concurrency tests, 56 scenario results, key/cache/invalidation/failure/operations contracts и clean reproducible run.

**Порядок выполнения:**

1. Перенести принятый Week 16 quality gate и доказать baseline.
2. Подключить отдельный test Redis и safety guard.
3. Собрать data-type lab и canonical key builder.
4. Добавить cache-aside vertical slice к одному statistics endpoint.
5. Подключить on-commit generation invalidation ко всем writers.
6. Добавить single-flight и fail-open behavior.
7. Добавить metrics/security/operations documents.
8. Выполнить `R01–R56`, два clean runs и защиту.

**Наблюдаемый результат:** cold request читает PostgreSQL и заполняет cache, warm request не вызывает loader, committed write меняет generation, concurrent miss ограничивает loader burst, Redis outage возвращает корректный DB response по failure policy.

**Готово, если:**

- все артефакты ссылаются на реальные paths/commands/node IDs;
- `R01–R56` имеют actual status и cleanup evidence;
- два clean runs дают одинаковый result set;
- ни одна test cleanup не затрагивает чужие keys;
- старый quality gate недели 16 продолжает проходить;
- 48 ответов заполнены до защиты.

**Пример ожидаемого формата, не решение:**

```text
Cold: MISS → DB loader 1 → cache TTL 55..65
Warm: HIT → DB loader 0 → identical 200 payload
Commit + Redis available: generation +1 → next request MISS/new payload
Redis down: DEGRADED → DB payload → cache_error metric
```

**Обязательно для зачёта:** работающий проект, 56 scenarios, все документы, real isolated Redis/PostgreSQL, два clean runs, минимум 36/48 и итог минимум 8/10.

**Рекомендация:** сохранить cache integration за небольшим interface, чтобы Week 18 мог использовать отдельный Redis broker без смешивания ролей.

### Документация

- [Redis cache-aside](https://redis.io/docs/latest/develop/use-cases/cache-aside/) — сверить итоговый read/write/stampede flow.
- [Django cache framework](https://docs.djangoproject.com/en/5.2/topics/cache/) — сверить runtime API, key prefix/version и timeout behavior.
- [Redis security](https://redis.io/docs/latest/operate/oss_and_stack/management/security/) — проверить финальный security checklist.

### Дерево и обязанности файлов

```text
day_07_cached_statistics/
├── <project_root>/          # Django production code, configuration и tests
├── README.md                # clean setup, safe URLs, commands и результаты
├── KEYSPACE.md              # форматы keys, owners, TTL, scope и examples
├── DATA_TYPE_LAB.md         # R09–R20 commands/results/cleanup
├── CACHE_CONTRACT.md        # source, payload, hit/miss/TTL/staleness
├── INVALIDATION_MAP.md      # dependencies, writers, commit callbacks
├── STAMPEDE_PLAN.md         # lock lifecycle, budgets, concurrency evidence
├── FAILURE_POLICY.md        # expected failures, fallback, logs/metrics
├── OPERATIONS_RUNBOOK.md    # persistence, eviction, security и recovery
├── METRICS.md               # metric names, labels и observed changes
└── SCENARIO_MATRIX.md       # R01–R56 actual results
```

- Production code хранит key builder, cache adapter, loader/serializer, invalidation и metrics в фактической архитектуре проекта.
- `README.md` не содержит secrets и проверяет safety до destructive cleanup.
- Каждый document является индексом evidence, а не копией кода.

### Рабочие вертикальные срезы

1. Safe connection: `PING → own SET/GET → cleanup`.
2. Statistics miss/hit: public request → key → Redis → DB loader → response.
3. Fresh write: service transaction → commit → generation → next request.
4. Hot miss: concurrent requests → owner-safe lock → bounded responses.
5. Degraded mode: Redis error → DB source → safe log/metric.
6. Operations: read-only facts → role decisions → clean run.

### Обязательные позитивные сценарии

- PING и namespaced SET/GET;
- каждая основная structure;
- cache miss/warm hit с одинаковым API response;
- valid finite TTL;
- committed sale/stock update changes stats;
- concurrent hot miss returns valid responses;
- metrics for hit/miss/invalidation.

### Обязательные граничные сценарии

- missing key и wrong type;
- duplicate set member и equal sorted-set score;
- filters in different order;
- different authorization/organization scope;
- TTL expiry and negative sentinel;
- missing generation key/concurrent increments;
- lock timeout/expiry;
- minimum/maximum jitter;
- zero hits+misses ratio handling.

### Обязательные ошибочные сценарии

- unsafe/missing test configuration blocks before write;
- Redis connection/read/write error;
- PostgreSQL loader exception;
- transaction rollback without invalidation;
- old reader after committed writer;
- stale lock owner cannot release new lock;
- unexpected programming exception is not swallowed;
- test cleanup leaves sentinel outside prefix.

### Ограничения на ещё не изученное

- не добавлять Celery/Beat/tasks;
- не использовать stream как самодельную production queue;
- не вводить Redis Cluster/Sentinel/replication implementation — только отметить дальнейшее развитие;
- не добавлять Lua, если поддерживаемый client lock решает учебную задачу;
- не использовать Redis для денежных/складских source-of-truth locks;
- не добавлять Docker/Compose раньше недели 20;
- не оптимизировать все endpoints: один доказанный statistics vertical slice обязателен.

### Финальный чек-лист

- [ ] Source commit и Week 16 baseline записаны.
- [ ] `redis-py`/Django/Redis compatibility проверена при активации.
- [ ] Test Redis отделён и имеет unique run prefix.
- [ ] Нет `FLUSHALL`, `FLUSHDB`, `KEYS *`.
- [ ] Cleanup сохраняет external sentinel.
- [ ] Connection/command timeouts конечны.
- [ ] Data-type lab покрывает five structures.
- [ ] Key format versioned, scoped, canonical и без PII.
- [ ] Hit/miss responses полностью эквивалентны.
- [ ] Warm hit не вызывает DB loader.
- [ ] TTL и negative-cache policies доказаны.
- [ ] Все statistics dependencies/writers mapped.
- [ ] При доступном Redis commit invalidates; rollback does not.
- [ ] Invalidation failure после commit имеет metric/log и конечный stale-window contract.
- [ ] Old reader cannot publish current-generation stale value.
- [ ] Single-flight lock owner-safe и bounded.
- [ ] Redis outage следует fail-open contract.
- [ ] PostgreSQL errors не маскируются cache fallback.
- [ ] Metrics/logs safe и различают outcomes.
- [ ] Persistence/eviction/role decisions обоснованы.
- [ ] Redis security checklist заполнен.
- [ ] `R01–R56` имеют evidence.
- [ ] Два clean runs одинаковы.
- [ ] 48 ответов и самооценка заполнены.

### Контроль понимания: 48 вопросов

#### Архитектура и commands

1. Почему Redis считается network dependency?
2. Что такое keyspace и Redis type?
3. Что гарантирует атомарность одной команды?
4. Почему `GET → Python → SET` не атомарен?
5. Зачем connection pool?
6. Почему нужны connect и socket timeouts?
7. Чем unique prefix дополняет отдельный test endpoint?
8. Почему запрещены `FLUSHALL` и `KEYS *`?

#### Data types

9. Когда выбрать string?
10. Почему `INCR` подходит counter?
11. Когда выбрать hash?
12. Чем set отличается от list?
13. Как sorted set формирует ranking?
14. Что важно определить при equal score?
15. Для чего предназначен stream?
16. Почему stream lab не равен Celery implementation?

#### Keys, TTL и cache-aside

17. Назовите этапы cache-aside read.
18. Какие элементы входят в statistics key?
19. Почему query params нормализуют?
20. Как scope предотвращает утечку?
21. Что означают `TTL -1` и `TTL -2`?
22. Почему TTL проверяют диапазоном?
23. Чем cached empty sentinel отличается от miss?
24. Почему hit и miss обязаны иметь одинаковый contract?

#### Invalidation

25. Почему TTL не заменяет invalidation?
26. Почему invalidation выполняют после commit?
27. Что происходит после rollback?
28. Когда generation лучше exact deletion?
29. Как ограничивается память старых generation keys?
30. Как bulk update обходит signals?
31. В чём race old reader/new writer?
32. Как generation делает stale fill невидимым новым requests?

#### Stampede и failures

33. Что такое cache stampede?
34. Что гарантирует single-flight?
35. Зачем lock TTL?
36. Зачем owner token?
37. Почему нужен cache double-check после acquisition?
38. Что делать non-owner после bounded wait?
39. Что означает fail-open в этом endpoint?
40. Какие exceptions нельзя скрывать общим `except Exception`?

#### Operations и роли

41. Чем RDB отличается от AOF?
42. Что делает eviction policy?
43. Чем `allkeys-*` отличается от `volatile-*`?
44. Почему cache и broker лучше изолировать?
45. Какие metrics нужны для hit ratio?
46. Почему user ID/key нельзя делать metric label?
47. Какие сетевые и ACL меры нужны Redis?
48. Почему Redis lock не заменяет PostgreSQL transaction в покупке?

### Критерий защиты

- минимум 36/48 правильных ответов;
- обязательны правильные ответы 3, 4, 8, 16, 20, 24, 26, 27, 31, 36, 39, 40, 44 и 48;
- ученик демонстрирует один Redis command scenario, один cache hit/miss API test, один rollback invalidation test и один degraded test;
- ученик объясняет key одной строки, не читая готовый текст.

---

## Оценка обычного дня

| Критерий | Баллы |
|---|---:|
| Корректность результата | 0–3 |
| Выполнение условий | 0–2 |
| Граничные/ошибочные сценарии | 0–2 |
| Читаемость и имена | 0–1 |
| Понимание и самооценка | 0–1 |
| Самостоятельность исправлений | 0–1 |

## Оценка итогового проекта

| Критерий | Баллы |
|---|---:|
| Connection/key/TTL/cache-aside contract | 0–2 |
| Invalidation/freshness и PostgreSQL consistency | 0–2 |
| Stampede/failure behavior | 0–2 |
| Tests/scenario evidence и safety cleanup | 0–2 |
| Operations/security/metrics/защита | 0–2 |

Итог принят при 8/10, отсутствии критической ошибки и выполнении обязательных требований.

Критические ошибки: обращение к production/development Redis, глобальная очистка, утечка чужого cached response, Redis как источник истины для денег/stock, invalidation до commit с нарушением consistency, вечный lock/hang, скрытый broad exception, real secret в Git/log или неработающий clean run.
