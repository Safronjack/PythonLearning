# Теория недели 10: Django ORM

Читайте этот файл по разделам, указанным в конкретном дне `PRACTICE.md`. Не нужно проглатывать всю теорию до первой практики.

## 1. Что делает ORM

ORM — слой, который сопоставляет объекты Python со строками таблиц и превращает операции над ними в SQL. Django model описывает не только Python-класс: её поля и `Meta` участвуют в создании schema, проверках, admin, forms и ORM-запросах.

```python
car = CarModel.objects.get(pk=7)
car.name = "Octavia"
car.save(update_fields=["name"])
```

За этим удобством стоят SQL-запросы. ORM не отменяет знания SQL, constraints, транзакций и планов выполнения. Она позволяет выражать типовые операции единообразно и безопаснее собирать параметры запроса.

ORM особенно полезна, когда:

- схема и объекты приложения тесно связаны;
- нужны composable filters и типовые CRUD-операции;
- migrations должны жить рядом с кодом;
- важна интеграция с остальным Django.

Raw SQL уместен для запроса, который ORM выражает неясно или заметно хуже. Но сначала нужно измерить проблему, а затем изолировать SQL и проверить параметры.

### Прогноз

1. Выполняется ли SQL сразу после `CarModel.objects.filter(is_active=True)`?
2. Гарантирует ли `model.clean()` целостность при прямом SQL insert?
3. Может ли удобная строка ORM-кода породить сотню SQL-запросов?

## 2. Model, field и column

Обычно concrete Django model соответствует таблице, field — столбцу, instance — строке. Это полезная модель мышления, но не абсолютное равенство: relation fields создают foreign key columns, M2M создаёт отдельную таблицу, а annotations вообще могут не существовать в schema.

```python
class CarMake(models.Model):
    name = models.CharField(max_length=120, unique=True)
```

У каждого field есть несколько разных обязанностей:

- Python-значение;
- database type;
- допустимость пустого значения;
- validation;
- отображение в form/admin;
- migration state.

### `null` и `blank`

- `null=True` разрешает SQL `NULL` в database.
- `blank=True` разрешает пустое значение при validation формы/model field.

Для строк обычно не создают два значения «нет текста»: `NULL` и `""`. Поэтому у необязательной строки часто `blank=True`, но `null=False`. Исключение требует отдельного объяснения.

### `default`

Значение default либо неизменяемое, либо callable:

```python
created_code = models.CharField(default=create_code, max_length=32)
```

Нужно передать функцию `create_code`, а не результат `create_code()`. Изменяемый объект вроде `{}` или `[]` нельзя использовать как общий literal default.

### `choices`

`TextChoices` делает допустимые значения явными в Python и интерфейсах:

```python
class OfferStatus(models.TextChoices):
    PENDING = "pending", "Ожидает"
    ACCEPTED = "accepted", "Принято"
    REJECTED = "rejected", "Отклонено"
```

Choices помогают validation, но для критического бизнес-правила стоит проверить, нужна ли также database constraint.

### Money

`float` хранит двоичное приближение и не подходит для точных денежных расчётов. В model используется `DecimalField`, а в Python — `Decimal`.

```python
price = models.DecimalField(max_digits=14, decimal_places=2)
```

`max_digits` — общее число цифр, `decimal_places` — число цифр после точки. Нужно заранее проверить максимальное допустимое значение.

### Время

- `auto_now_add=True` удобно для времени создания;
- `auto_now=True` — для времени обновления через `save()`;
- bulk `QuerySet.update()` не вызывает `save()` и не обновляет `auto_now` автоматически.

Это важно: техническое поле `updated_at` не доказывает, что изменение всегда прошло через instance `save()`.

### Баланс, предпочтения и характеристики

Баланс — денежное значение, поэтому хранится через `DecimalField` и защищается constraint `>= 0`. Но одно поле balance не объясняет, откуда взялись деньги. Для проверяемой истории нужна immutable запись движения с amount, direction/reason и связью с операцией. Изменение balance и добавление ledger row выполняются в одной transaction.

Предпочтения покупателя и автосалона нельзя хранить строкой вроде `"SUV, diesel, Skoda"`: такую строку трудно валидировать, связывать и запрашивать. Предпочтительные car models и specifications задаются relations. `CarSpecification` хранит нормализованную характеристику и значение либо другой заранее объяснённый typed contract; произвольный JSON без query contract на этой стадии не используется.

`accounts.User` уже содержит `is_active` через `AbstractUser`. Повторно объявлять одноимённый field через дополнительное model inheritance нельзя. Требуемые `created_at`/`updated_at` добавляются явно с migration, а различие между новым `created_at` и унаследованным `date_joined` документируется.

## 3. Абстрактная model

Если каждое требуемое model содержит `is_active`, `created_at`, `updated_at`, их можно задать один раз:

```python
class TimeStampedActiveModel(models.Model):
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True
```

Абстрактная model не создаёт собственную таблицу. Поля копируются в concrete subclasses.

Не помещайте туда случайную бизнес-логику. Общая база должна содержать только действительно общие свойства. Если constraints объявляются в abstract base, их имена должны быть уникальными для каждой concrete model; у Django для этого есть placeholders в имени.

### Soft delete — не бесплатная функция

`is_active=False` — деактивация, а не полная реализация soft delete. Нужно определить:

- какие queries скрывают неактивные записи;
- видит ли их admin;
- доступны ли они через reverse relations;
- можно ли повторно использовать уникальный code;
- что происходит с историческими продажами;
- какой manager является `_default_manager` и `_base_manager`.

На этой неделе не строится универсальная библиотека soft delete. Мы используем явный `.active()` там, где бизнес-сценарию нужны только активные строки.

## 4. `Meta`, порядок и строковое представление

Внутренний `Meta` хранит model-level настройки: table ordering, indexes, constraints и другие параметры.

```python
class Meta:
    ordering = ("name", "pk")
```

Стабильная сортировка содержит tie-breaker, например `pk`; иначе две одинаковые цены могут менять относительный порядок.

`__str__()` возвращает короткое понятное представление для admin и shell. В нём нельзя выполнять тяжёлые запросы или обращаться к relation, которая обычно не загружена: это скрытый источник N+1.

## 5. Связи и владение

### Many-to-one: `ForeignKey`

Много моделей автомобилей принадлежат одной марке:

```python
class CarModel(models.Model):
    make = models.ForeignKey(
        CarMake,
        on_delete=models.PROTECT,
        related_name="models",
    )
```

Прямой доступ: `car_model.make`. Обратный: `make.models.all()`.

### One-to-one

Профиль покупателя расширяет существующего user, но не заменяет auth model:

```python
class BuyerProfile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="buyer_profile",
    )
```

Отсутствие обратного one-to-one relation вызывает отдельное related-object исключение, а не возвращает `None` автоматически.

### Many-to-many

Автосалон содержит много моделей автомобилей, а одна модель присутствует во многих автосалонах. Но связь имеет `quantity` и `sale_price`. Значит нужна явная through-model:

```python
class DealershipInventory(models.Model):
    dealership = models.ForeignKey(DealershipProfile, on_delete=models.CASCADE)
    car_model = models.ForeignKey(CarModel, on_delete=models.PROTECT)
    quantity = models.PositiveIntegerField()
    sale_price = models.DecimalField(max_digits=14, decimal_places=2)
```

После начала работы с `ManyToManyField` переход от автоматической join table к `through` может быть сложной migration. Поэтому промежуточную model проектируют заранее, если связь несёт данные.

### `related_name`

Хорошее имя описывает коллекцию со стороны связанного объекта:

- `make.models`;
- `dealership.inventory_rows`;
- `car_model.supplier_offers`.

Имя `items` или `things` заставляет каждый раз угадывать смысл. Одинаковые reverse names у двух fields приводят к system check error.

## 6. `on_delete` — бизнес-решение

`on_delete` управляет поведением ORM/database relation при физическом удалении referenced object.

- `CASCADE` — удалить зависимые строки;
- `PROTECT` — запретить удаление, если зависимые строки существуют;
- `RESTRICT` — ограничить удаление с учётом набора удаляемых объектов;
- `SET_NULL` — сохранить зависимую строку, записав `NULL`; field обязан разрешать `null`;
- `SET_DEFAULT` — установить default;
- `DO_NOTHING` — ORM не предпринимает действие; целостность остаётся на database constraint и может завершиться ошибкой.

Выбор нельзя делать по привычке. Историческая `Sale` не должна исчезнуть из-за удаления автосалона или пользователя. Для операционной промежуточной строки каскад иногда допустим, но физические удаления в системе с историей обычно ограничивают.

### Прогноз

1. Что случится с продажей при удалении `CarModel`, если relation использует `PROTECT`?
2. Можно ли применить `SET_NULL` к field с `null=False`?
3. Почему `CASCADE` в исторической таблице опаснее, чем в одноразовом draft?

## 7. Constraints: последнее слово базы

Python validation полезна для хорошего сообщения пользователю, но конкурирующая транзакция или прямой SQL могут её обойти. Инвариант данных должен иметь database constraint, если PostgreSQL способен его выразить.

```python
class Meta:
    constraints = [
        models.CheckConstraint(
            condition=models.Q(quantity__gte=0),
            name="inventory_quantity_gte_0",
        ),
        models.UniqueConstraint(
            fields=("dealership", "car_model"),
            name="uniq_dealership_car_model_inventory",
        ),
    ]
```

Обязательные кандидаты недели:

- уникальная пара автосалон + модель автомобиля;
- уникальная пара поставщик + модель автомобиля;
- неотрицательные price, quantity и units;
- discount percent от 0 до 100;
- end time не раньше start time;
- уникальные нормализованные business identifiers там, где это действительно правило.

Constraint нужно проверить не только через form, но и попыткой создать неверную строку внутри ожидаемо обработанного `IntegrityError`.

## 8. Индексы

Индекс ускоряет определённые reads, но занимает место и удорожает writes. Индекс выбирают под query pattern:

```python
class Meta:
    indexes = [
        models.Index(
            fields=("dealership", "is_active", "sale_price"),
            name="inventory_active_price_idx",
        )
    ]
```

Порядок полей важен. Нельзя добавлять индекс «на всякий случай» на каждое поле. Сначала фиксируются filter, ordering, объём данных и план; затем создаётся migration; после — план проверяется повторно.

На маленькой таблице PostgreSQL может честно выбрать sequential scan. Это не означает, что индекс сломан. Для учебной проверки нужен достаточный объём данных и анализируемый запрос.

## 9. Что такое migration

Migration — versioned описание изменения состояния models и операций со schema/data. Django сравнивает состояние model files с migration state, а не непосредственно с текущей schema database.

Основные команды:

- `makemigrations` создаёт migration files;
- `showmigrations` показывает историю и состояние применения;
- `migrate --plan` показывает предстоящий порядок;
- `sqlmigrate app_label number` показывает SQL конкретной schema migration;
- `migrate` применяет или откатывает migration chain.

Migration file является кодом проекта. Его читают до применения и хранят в Git.

### Почему нельзя менять применённую migration

У разных разработчиков и окружений эта migration уже могла выполниться. Изменение старого файла делает историю неодинаковой. Новое изменение — новая migration.

### Зависимости между apps

Если data migration читает model из другого app, dependency на нужную migration этого app должна быть явной. Иначе историческая model может отсутствовать в состоянии.

## 10. Безопасное изменение обязательного поля

Представим, что в существующий `CarModel` нужен уникальный `code`, а строки уже есть. Опасно сразу добавить уникальный non-null default, одинаковый для всех строк.

Безопасный staged путь:

1. добавить field временно nullable или без uniqueness;
2. schema migration;
3. data migration заполняет уникальные значения;
4. проверить отсутствие `NULL` и duplicates;
5. следующая schema migration делает field non-null и unique;
6. проверить forward и reverse path на копии учебной database.

Конкретная стратегия зависит от объёма таблицы и допустимых locks. В production некоторые изменения нужно делить ещё мельче.

## 11. Data migrations и historical models

В `RunPython` нельзя импортировать текущую model обычным способом: через месяц class уже изменится, а старая migration обязана воспроизводиться.

```python
def forwards(apps, schema_editor):
    CarModel = apps.get_model("catalog", "CarModel")
    for car_model in CarModel.objects.all().iterator():
        car_model.code = build_code(car_model)
        car_model.save(update_fields=["code"])
```

Reverse callable должен вернуть данные в предыдущее осмысленное состояние, если это возможно. Если операция действительно необратима, это указывают явно и объясняют риск.

Historical model не содержит произвольных современных instance methods. Логику migration держат самодостаточной и детерминированной.

Для больших данных следует избегать загрузки всех rows в память, продумывать batching и время locks. Учебный набор маленький, но объяснение масштабирования обязательно.

## 12. QuerySet — описание запроса

```python
queryset = CarModel.objects.filter(is_active=True).order_by("make__name", "name")
```

Обычно это ленивое описание. SQL выполняется, когда результат нужен: при iteration, `list()`, `len()`, boolean evaluation, indexing с некоторыми вариантами, serialization и других evaluation operations.

QuerySet можно уточнять цепочкой. Каждый вызов возвращает новый QuerySet; исходный обычно не изменяется.

```python
active = CarModel.objects.filter(is_active=True)
skoda = active.filter(make__name="Skoda")
```

### Кэш QuerySet

Вычисленный QuerySet обычно хранит result cache в своём instance. Два отдельно построенных одинаковых QuerySet — два запроса. `iterator()` работает иначе и полезен для потоковой обработки большого результата.

### `get` и `filter`

- `get()` ожидает ровно одну строку и возвращает model instance;
- отсутствие вызывает `DoesNotExist`;
- несколько строк вызывают `MultipleObjectsReturned`;
- `filter()` всегда возвращает QuerySet, возможно пустой.

Не ловите общий `Exception`, когда ожидается конкретная ситуация.

### `exists`, `count`, `len`

- `exists()` эффективен, если нужен только ответ «есть ли строка?»;
- `count()` считает в database;
- `len(queryset)` загружает result set, если он ещё не загружен.

Если позже всё равно нужно пройти по уже вычисленному QuerySet, дополнительный `exists()` может стать лишним запросом. Оптимизация зависит от дальнейшего использования.

### `values` и `values_list`

Они возвращают dictionaries/tuples вместо model instances и полезны, когда действительно нужны только выбранные данные. Это меняет контракт результата, поэтому их не вставляют случайно глубоко в переиспользуемый слой.

## 13. Manager и custom QuerySet

Manager — вход в table-level operations: `CarModel.objects`. Custom QuerySet хранит цепочечные операции предметного языка:

```python
class InventoryQuerySet(models.QuerySet):
    def active(self):
        return self.filter(is_active=True)

    def in_stock(self):
        return self.filter(quantity__gt=0)
```

Тогда методы комбинируются:

```python
DealershipInventory.objects.active().in_stock()
```

`as_manager()` или `Manager.from_queryset()` позволяют открыть методы через manager.

### Опасность скрытого фильтра default manager

Если `objects.get_queryset()` всегда исключает неактивные rows, admin, dumps и некоторые связанные операции могут «терять» данные. Безопаснее иметь нефильтрующий base/default manager и явный `active()` либо очень точно настроить `Meta.base_manager_name`/`default_manager_name` и покрыть поведение тестами.

Manager не должен превращаться в свалку transaction workflows. Операция, изменяющая несколько aggregates и проверяющая бизнес-права, обычно яснее в service function с `atomic()`.

## 14. `Q`: сложная логика фильтра

Keyword arguments внутри одного `filter()` объединяются через AND. `Q` позволяет OR, NOT и динамическую композицию:

```python
from django.db.models import Q

available = DealershipInventory.objects.filter(
    Q(quantity__gt=0),
    Q(sale_price__lte=budget) | Q(dealership__promotions__discount_percent__gt=0),
)
```

Операторы:

- `&` — AND;
- `|` — OR;
- `~` — NOT.

Скобки обязательны для читаемости и верного precedence. Relations могут размножить rows из-за JOIN; `distinct()` добавляют только после понимания причины duplicates.

## 15. `F`: выражение на стороне database

`F` ссылается на значение столбца, не загружая его сначала в Python:

```python
updated = DealershipInventory.objects.filter(
    pk=inventory_id,
    quantity__gte=units,
).update(quantity=F("quantity") - units)
```

Такой одиночный `UPDATE ... WHERE quantity >= units` защищает простой decrement от lost update и сообщает количеством changed rows, удалось ли списание.

После присваивания `F()` instance field может всё ещё содержать expression; instance нужно `refresh_from_db()` перед использованием значения.

`F` решает не все transaction workflows. Если решение зависит от нескольких строк или последующих inserts, нужен продуманный transaction boundary и иногда row lock.

## 16. `annotate` и `aggregate`

`aggregate()` сворачивает весь QuerySet в один итоговый dictionary:

```python
totals = Sale.objects.aggregate(total_units=Sum("units"))
```

`annotate()` добавляет вычисленное значение каждой строке результата:

```python
dealerships = DealershipProfile.objects.annotate(
    models_in_stock=Count(
        "inventory_rows",
        filter=Q(inventory_rows__quantity__gt=0),
        distinct=True,
    )
)
```

Порядок `filter()` и `annotate()` способен изменить смысл SQL. Сначала сформулируйте вопрос естественным языком:

- «посчитать только активные остатки»;
- или «выбрать автосалоны с активным остатком, но посчитать все их остатки».

JOIN нескольких one-to-many relations может умножить строки и исказить `Count`/`Sum`. Проверяйте SQL и маленький dataset, где у одного объекта по две строки в обеих связях.

### `Coalesce`

Сумма по пустому набору часто даёт `NULL`. Если контракт требует ноль, это выражается явно, например через `Coalesce`, с совместимым output type.

## 17. Bulk operations и signals

- `QuerySet.update()` выполняет SQL update и не вызывает model `save()`;
- `bulk_create()` создаёт много rows эффективно, но имеет отличия от последовательного `save()`;
- signals и custom save logic нельзя считать универсальной гарантией для bulk paths.

Критический инвариант держится в database constraint. Побочный эффект, который обязан произойти, проектируется с учётом всех write paths, а не только одного signal.

## 18. N+1

N+1 возникает, когда один запрос получает N основных строк, а затем доступ к relation вызывает ещё по запросу на каждую строку.

```python
for row in DealershipInventory.objects.all():
    print(row.car_model.make.name)
```

Без eager loading это может быть 1 запрос к inventory, N к car model и ещё N к make.

### `select_related`

Использует SQL JOIN и подходит для одиночных relations: `ForeignKey`, `OneToOneField`.

```python
rows = DealershipInventory.objects.select_related("car_model__make", "dealership")
```

### `prefetch_related`

Выполняет отдельные запросы и связывает результаты в Python. Подходит для many-to-many и reverse one-to-many.

```python
dealerships = DealershipProfile.objects.prefetch_related("inventory_rows__car_model__make")
```

`Prefetch` позволяет задать custom QuerySet и `to_attr`. Нельзя после prefetch незаметно применить другой filter к related manager и ожидать использования старого cache.

### Правильное доказательство

1. Создать минимум несколько parents и children.
2. Измерить query count плохого сценария.
3. Записать SQL pattern.
4. Добавить правильную загрузку.
5. Повторить тот же observable сценарий.
6. Зафиксировать query budget, который не растёт при увеличении N.

Время на маленьких данных менее надёжно, чем число queries. В дальнейшем это закрепляется test assertion.

## 19. `explain`, `only` и `defer`

`QuerySet.explain()` показывает план database. План читают вместе с SQL, статистикой и объёмом таблицы. `analyze=True` действительно выполняет запрос; для write query это может быть опасно, поэтому на этой неделе analyze используется только с безопасным SELECT на учебных данных.

`only()` и `defer()` загружают не все columns. Последующий доступ к deferred field создаст дополнительный запрос. Это точечный инструмент после измерения ширины rows, а не стандартная настройка каждого QuerySet.

## 20. Транзакционная граница

`transaction.atomic()` гарантирует: блок либо фиксируется целиком, либо при исключении откатывается до соответствующего savepoint/transaction boundary.

```python
from django.db import transaction

@transaction.atomic
def register_sale(...):
    ...
```

Внутренний `atomic()` обычно создаёт savepoint. Пойманное database exception внутри того же atomic block может оставить transaction в broken state до rollback. Ошибку ловят вокруг atomic boundary, если после неё нужно продолжить database operations.

`atomic()` не заменяет проверку гонок. Два процесса могут оба прочитать старое значение до записи.

## 21. `select_for_update`

`select_for_update()` блокирует выбранные rows до конца transaction:

```python
with transaction.atomic():
    inventory = (
        DealershipInventory.objects
        .select_for_update()
        .get(pk=inventory_id)
    )
    if inventory.quantity < units:
        raise InsufficientStock
    inventory.quantity -= units
    inventory.save(update_fields=["quantity", "updated_at"])
```

Правила:

- query должен быть вычислен внутри active transaction;
- lock живёт до commit/rollback;
- одинаковый порядок блокировок уменьшает риск deadlock;
- transaction должна быть короткой;
- внутри lock не выполняют network call или ожидание пользователя;
- `nowait` и `skip_locked` меняют контракт и вводятся только осознанно;
- проверка должна выполняться на PostgreSQL с двумя независимыми connections/processes.

Для простого decrement иногда достаточно conditional `F` update. Для сценария «проверить остаток → создать Sale → уменьшить остаток» row lock даёт более ясную целостную границу.

## 22. Ошибки database и доменные ошибки

`IntegrityError` сообщает о нарушении database constraint. Не показывайте пользователю сырой текст PostgreSQL. На границе service/API exception преобразуется в понятную доменную ошибку, при этом unexpected exceptions не скрываются.

Отдельная domain exception, например `InsufficientStock`, позволяет отличить ожидаемый отказ от поломки инфраструктуры.

Логи не должны содержать пароли, DSN и чувствительные данные. Полезны operation id, entity id, units, exception type и результат.

## 23. Django ORM и SQLAlchemy

Обе технологии отображают данные database в Python и позволяют строить запросы, но философия отличается.

| Тема | Django ORM | SQLAlchemy |
|---|---|---|
| Экосистема | часть Django | самостоятельный database toolkit |
| Основной стиль | active-record-like models + managers | Data Mapper ORM и отдельный Session |
| Unit of work | скрыт за обычными operations/transactions | явно сосредоточен в `Session` |
| Schema migrations | Django migrations | обычно Alembic |
| SQL-конструктор | ORM expressions | мощный SQLAlchemy Core |
| Выбор для проекта | естественный для Django/DRF | удобен вне Django и при более явном mapping/control |

Это сравнение не означает, что один инструмент «лучше всегда». Для текущего Django-проекта второй ORM добавит сложность без пользы.

## 24. SQLAlchemy Core и ORM — обзор

SQLAlchemy Core предоставляет SQL expression language, schema objects и работу через connections. SQLAlchemy ORM добавляет mapped classes, relationships, identity map и Session.

M2M в SQLAlchemy обычно моделируется через association table. Если связь имеет собственные поля, используют association object mapped class — идея та же, что у explicit through-model Django.

`Session` хранит unit of work:

- `flush()` отправляет накопленные SQL changes в текущую transaction, чтобы database назначила ids и проверила часть constraints; это не финальный commit;
- `commit()` сначала flushes изменения и затем фиксирует transaction;
- rollback после flush всё ещё возможен, пока commit не завершён.

## 25. SQLAlchemy result methods — обзор

Названия похожи, но contracts различаются:

- `scalar()` возвращает первый column первой row или `None`; дополнительные rows обычно не требуют строго одного результата;
- `scalar_one()` требует ровно одну row и возвращает её первый column;
- `scalar_one_or_none()` разрешает ноль или одну row;
- `scalars()` создаёт поток scalar values из первого column;
- `fetchone()` возвращает следующую row или `None`;
- `fetchall()` возвращает все оставшиеся rows;
- `first()` возвращает первую row или `None`;
- `one()` требует ровно одну row.

Точные contracts сверяются с документацией используемой версии. В практическом Django-коде эти методы не применяются.

## 26. Alembic — обзор

Alembic — migration tool экосистемы SQLAlchemy. Его сильные стороны:

- гибкие Python migration scripts;
- интеграция с SQLAlchemy metadata;
- autogenerate как отправная точка;
- явное управление upgrade/downgrade branches.

Ограничения:

- autogenerate не понимает весь бизнес-смысл и требует ручного review;
- переименование может выглядеть как drop + add;
- data migrations и сложные vendor-specific операции пишутся вручную;
- branches/merges migration history требуют дисциплины;
- Alembic не заменяет rollout plan, backup и наблюдение locks.

В Django-проекте канонической migration history остаются Django migrations. Две системы не должны одновременно владеть одной schema.

## 27. `django-countries` и PostGIS

Исходное задание требует `django-countries` для местоположения и просит изучить PostGIS. Это разные уровни задачи:

- `django-countries` хранит стандартизированный country code и подходит для фильтра «страна равна ...»;
- PostGIS расширяет PostgreSQL географическими типами и spatial operations: расстояние, радиус, пересечение, ближайшие объекты;
- простой адрес или страна не требуют PostGIS;
- PostGIS становится обоснованным, если продукту нужен запрос вроде «найти автосалоны в радиусе 25 км» и есть корректные coordinates/indexes.

Решение этой недели: хранить country через `django-countries`, обычные address fields — как явно описанный текст, а PostGIS не подключать. Условие пересмотра — появление distance/radius/spatial query. Само архитектурное исследование PostGIS уже выполняется на неделе 8.

## 28. Вопросы самопроверки

1. Как ORM помогает и что она не отменяет?
2. Чем `null` отличается от `blank`?
3. Почему деньги нельзя хранить во `float`?
4. Что не обновится автоматически при `QuerySet.update()`?
5. Почему `is_active` ещё не полноценный soft delete?
6. Когда нужна explicit through-model?
7. Чем `PROTECT` отличается от `CASCADE`?
8. Почему Python validation недостаточно для критического invariant?
9. Зачем composite index связывать с конкретным query?
10. Почему применённую migration нельзя переписывать?
11. Как безопасно добавить обязательный уникальный field в заполненную table?
12. Почему data migration использует `apps.get_model()`?
13. Когда QuerySet обычно выполняет SQL?
14. Чем `get()` отличается от `filter()`?
15. Когда `exists()` полезен, а когда добавляет лишний query?
16. Почему hidden filtering в default manager опасен?
17. Для чего нужны `Q` и скобки?
18. Как `F` защищает простой counter update?
19. Чем `annotate()` отличается от `aggregate()`?
20. Почему JOIN может исказить aggregate?
21. В чём N+1 и как его доказать?
22. Для каких связей используется `select_related()`?
23. Для каких связей используется `prefetch_related()`?
24. Почему sequential scan на маленькой table не доказывает бесполезность index?
25. Что гарантирует и чего не гарантирует `atomic()`?
26. Где должен вычисляться QuerySet с `select_for_update()`?
27. Чем SQLAlchemy `flush()` отличается от `commit()`?
28. Почему Alembic autogenerate нельзя применять без review?
29. Чем country code отличается от spatial coordinate?
30. При каком требовании PostGIS станет обоснованным?
