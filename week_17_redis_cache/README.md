# Неделя 17: Redis и безопасное кэширование Django API

Статус: **подготовлена заранее и заблокирована до полного зачёта недели 16**.

На этой неделе Redis добавляется в Dealership API как ускоряющий, но необязательный источник копий данных. PostgreSQL остаётся источником истины. Ученик изучит устройство Redis, основные структуры, TTL, cache-aside, проектирование ключей, инвалидирование после commit, защиту от cache stampede, graceful degradation, persistence, eviction, безопасность и наблюдаемость.

Неделя 17 не вводит Celery. Redis как broker и result backend сравнивается архитектурно, а реализация очередей начинается на неделе 18.

## Результат недели

После завершения ученик умеет:

- объяснять client-server и in-memory модель Redis;
- отличать keyspace, key, value, type, TTL и logical database;
- подключаться через `redis-py` с connection/command timeouts;
- выбирать string, hash, set, sorted set и понимать назначение stream;
- отличать атомарную команду, pipeline и transaction;
- проектировать versioned keys без PII и конфликтов окружений;
- использовать встроенный Django `RedisCache` через общий cache API;
- реализовывать cache-aside: miss → PostgreSQL → cache, hit → cache;
- выбирать TTL по допустимой устарелости и проверять expiration;
- разделять отсутствующий ключ и закэшированный пустой результат;
- включать в cache key все параметры, влияющие на response;
- не допускать утечки данных между пользователями, ролями и организациями;
- инвалидировать зависимые ключи только после успешного database commit;
- объяснять trade-off delete-on-write и version/generation keys;
- защищать hot key от stampede через bounded single-flight lock;
- освобождать lock только его владельцем и использовать lock TTL;
- выбирать fail-open behavior, когда Redis является только кэшем;
- измерять hit/miss, loader calls, latency, errors, evictions и memory;
- различать RDB snapshots и AOF log;
- выбирать `maxmemory`/eviction policy по роли Redis;
- объяснять, почему cache, broker и result backend не следует смешивать бездумно;
- защищать Redis сетью, ACL, TLS и секретами окружения;
- тестировать cache behavior на настоящем отдельном Redis без опасной глобальной очистки.

## Предварительные требования

- Недели 0–16 завершены полностью.
- Каждый день недели 16 оценён минимум на 7/10.
- `Dealership Quality Gate` принят минимум на 8/10.
- Матрица `S01–S60` недели 16 имеет фактические результаты.
- Контроль понимания недели 16 пройден минимум на 36/48.
- В `week_16_advanced_testing/ASSESSMENT.md` записано: «Допуск к неделе 17: да».

Текущий фактический прогресс курса не меняется: он по-прежнему определяется `week_00_basics/ASSESSMENT.md`.

## Продолжение проекта недели 16

После допуска копируется только принятая версия:

```text
week_16_advanced_testing/day_07_quality_gate/
```

в:

```text
week_17_redis_cache/day_07_cached_statistics/
```

Неделя 16 после копирования не изменяется. Source commit, исходный test baseline, PostgreSQL target и новый Redis target фиксируются в `day_01_redis_architecture.md`.

## Зависимости и activation gate

Новая Python dependency: `redis` (`redis-py`). Django использует встроенный backend `django.core.cache.backends.redis.RedisCache`; `django-redis` не добавляется без отдельной доказанной необходимости.

Нужен отдельный доступный Redis server и `redis-cli` для лабораторных команд. При подготовке недели ничего не устанавливается и никакая служба не запускается.

При фактической активации проверить:

1. совместимость текущих Python, Django и `redis-py`;
2. способ запуска Redis, допустимый для текущего окружения;
3. явную переменную `TEST_REDIS_URL`, не совпадающую с production/development URL;
4. connection и socket timeouts;
5. уникальный test prefix вида `test:pythonlearning:<run_id>:`;
6. отсутствие `FLUSHALL`, `FLUSHDB` и `KEYS *` в коде/tests;
7. clean connection smoke через `PING`;
8. полную test suite недели 16 до добавления cache.

Logical database number не является надёжной границей безопасности. Для tests нужен отдельный Redis или явно выделенный test endpoint плюс уникальный namespace и точечная cleanup только своих keys.

## Структура недели

| День | Тема | Основной результат |
|---|---|---|
| 1 | Архитектура и безопасное подключение | bounded connection и карта ответственности Redis |
| 2 | Strings, hashes, sets, sorted sets, streams | изолированная лаборатория структур и команд |
| 3 | Keys, TTL и cache-aside | cached statistics endpoint с hit/miss evidence |
| 4 | Invalidation и freshness | invalidation после commit и versioned keys |
| 5 | Stampede и отказ Redis | single-flight, TTL jitter и fail-open policy |
| 6 | Persistence, eviction, security, metrics | operational decision record и runbook |
| 7 | Cached Dealership Statistics API | итоговый модуль с 56 проверенными сценариями |

## Обязательные артефакты

```text
week_17_redis_cache/
├── README.md
├── THEORY.md
├── PRACTICE.md
├── ASSESSMENT.md
├── notes.md
├── day_01_redis_architecture.md
├── day_02_data_types.md
├── day_03_cache_aside.md
├── day_04_invalidation.md
├── day_05_stampede_failures.md
├── day_06_operations.md
└── day_07_cached_statistics/
    ├── <project_root>/
    ├── README.md
    ├── KEYSPACE.md
    ├── DATA_TYPE_LAB.md
    ├── CACHE_CONTRACT.md
    ├── INVALIDATION_MAP.md
    ├── STAMPEDE_PLAN.md
    ├── FAILURE_POLICY.md
    ├── OPERATIONS_RUNBOOK.md
    ├── METRICS.md
    └── SCENARIO_MATRIX.md
```

## Матрица 56 сценариев

| Диапазон | Область | Количество |
|---|---|---:|
| R01–R08 | architecture, connection, isolation | 8 |
| R09–R20 | Redis data types | 12 |
| R21–R32 | key design, TTL, cache-aside | 12 |
| R33–R42 | invalidation и freshness | 10 |
| R43–R50 | stampede и failure behavior | 8 |
| R51–R56 | persistence, eviction, security, metrics | 6 |

Каждая строка содержит risk, initial state, operation, expected Redis/PostgreSQL/API state, exact command/node ID, actual result и cleanup evidence.

## Неподвижные правила

- PostgreSQL — source of truth; Redis cache можно удалить и построить заново.
- Ошибка Redis не должна делать корректные данные PostgreSQL неверными.
- Cache hit и miss возвращают одинаковый публичный contract.
- Авторизация выполняется до выдачи чувствительного cached response либо scope полностью включён в key.
- Каждый cache key имеет владельца, формат, TTL/freshness contract и invalidation trigger.
- Нельзя класть пароль, access/verification token, email или другую PII в открытый key.
- Нельзя использовать `pickle` для данных из недоверенного Redis.
- Нельзя очищать общий server командами `FLUSHALL`/`FLUSHDB`.
- Нельзя искать рабочие keys через `KEYS *`; для ограниченной диагностики используется `SCAN` с prefix.
- Нельзя полагаться только на TTL там, где запись должна немедленно изменить response.
- Нельзя удалять чужой lock; lock имеет owner token и TTL.
- Нельзя использовать Redis lock вместо PostgreSQL transaction для денежных/складских инвариантов.
- Нельзя добавлять Celery, Beat или background refresh на этой неделе.

## Критерий завершения

Неделя принята, если:

- каждый день оценён минимум на 7/10;
- итоговый `Cached Dealership Statistics API` оценён минимум на 8/10;
- `R01–R56` имеют воспроизводимые actual results;
- cache miss/hit дают одинаковый response, а hit не выполняет дорогой loader/query path;
- key учитывает environment, version, resource scope и normalized parameters;
- invalidation происходит после commit, а rollback сохраняет старый корректный cache;
- при доступном Redis committed write переключает generation немедленно; ошибка invalidation наблюдаема и ограничивает возможную устарелость конечным TTL согласно failure policy;
- конкурирующие misses вызывают loader в пределах принятого single-flight contract;
- Redis unavailable path следует документированной fail-open policy;
- tests используют отдельный Redis/prefix и безопасную cleanup;
- operational report различает cache, broker и result backend;
- ученик набрал минимум 36/48 за контроль понимания;
- в `ASSESSMENT.md` записано: «Допуск к неделе 18: да».

## Официальная документация

- [Redis data types](https://redis.io/docs/latest/develop/data-types/) — обзор встроенных структур и их назначения.
- [Redis `EXPIRE`](https://redis.io/docs/latest/commands/expire/) — TTL и условия изменения срока жизни key.
- [Redis cache-aside](https://redis.io/docs/latest/develop/use-cases/cache-aside/) — miss/hit/invalidation и stampede risk.
- [Django cache framework](https://docs.djangoproject.com/en/5.2/topics/cache/) — `RedisCache`, cache API, timeout и key prefix/version.
- [Redis persistence](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/) — RDB, AOF и trade-offs сохранности.
- [Redis key eviction](https://redis.io/docs/latest/develop/reference/eviction/) — `maxmemory` и eviction policies.
- [redis-py production usage](https://redis.io/docs/latest/develop/clients/redis-py/produsage/) — timeouts, retries, health checks и errors.
- [Redis security](https://redis.io/docs/latest/operate/oss_and_stack/management/security/) — network isolation, ACL и TLS.
