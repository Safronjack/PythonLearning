# Практика недели 10: Django ORM

Статус: **заблокирована до явного допуска из недели 9**.

## Общие правила

- Все изменения развивают один проект в `day_07_django_orm/`.
- В начале недели переносится только принятый Django Foundation недели 9.
- Код пишет и исправляет ученик; наставник при проверке читает и запускает, но не переписывает решение.
- Прогнозы, команды, результаты и объяснения записываются в дневной `.md`-файл.
- Каждый QuerySet проверяется на заранее созданном неоднозначном dataset, а не на одной удобной row.
- Все schema changes создаются migrations. Не править database вручную, чтобы «подогнать» результат.
- Не удалять и не переписывать уже применённые migration files.
- Использовать только отдельную учебную PostgreSQL database.
- Перед destructive действием остановиться и запросить отдельное согласование.
- SQLAlchemy и Alembic не устанавливать: для них предусмотрено только сравнение в итоговом документе.

## Формат эксперимента

```text
Experiment ID:
Question:
Data setup:
Command or action:
Prediction:
Actual result:
SQL/query count when relevant:
Explanation:
Next correction:
```

Фактический результат нельзя заменять ожидаемым. Не вставляйте полный traceback: сохраните exception type, короткое сообщение, значимую последнюю строку и своё объяснение.

## Самооценка дня

В конце каждого дневного журнала ответьте:

1. Что я сделал самостоятельно?
2. Какое бизнес-правило теперь защищает Python, а какое database?
3. Где мой прогноз разошёлся с результатом?
4. Какой SQL я ожидаю от главного QuerySet дня?
5. Какую ошибку я теперь могу объяснить?
6. Что осталось непонятным?
7. Сколько времени заняла работа?

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

# День 1. Models, fields и правила данных

## Паспорт задания

- **Цель:** перевести основные сущности автосалона в Django models и выбрать типы fields по смыслу данных.
- **Рабочая область:** `day_07_django_orm/common/models.py`, `accounts/models.py`, `catalog/models.py`; журнал — `day_01_models_fields.md`.
- **Результат:** abstract base model, `BuyerProfile`, `CarMake`, `CarModel`, `CarSpecification`, карта полей, план безопасного добавления timestamps в существующий `User` и первая schema migration новых models.
- **Порядок выполнения:** перенесите принятый foundation; опишите данные; создайте базовую model; реализуйте catalog/account models; добавьте constraints; создайте и прочитайте migration; примените её; проверьте обычные и неверные данные.
- **Наблюдаемый результат:** `manage.py check` проходит, migrations применяются, корректные objects сохраняются, а нарушающие database constraints — отклоняются.
- **Готово, если:** все поля имеют объяснимый тип; деньги не во `float`; общие поля не дублируются; `BuyerProfile` связан с custom user; preferences заданы relations; migration прочитана до применения; минимум десять сценариев записаны.
- **Пример:** `CarModel.base_price=Decimal("25000.00")` сохраняется; отрицательная цена отклоняется constraint.
- **Обязательно для зачёта:** задания 1–7 и сценарии 1–8. **Рекомендация:** добавить `verbose_name`, если он помогает admin, но не маскировать непонятные Python identifiers.

## Теория

Прочитайте разделы 1–4, 7 и 27 `THEORY.md`.

## Задание 1. Безопасное начало и карта переноса

- **Исходные данные:** принятый `week_09_django_foundation/day_07_django_foundation/` и его версия в Git.
- **Действие:** создайте рабочий проект недели 10 согласованным способом. В журнале запишите source commit/branch, database host/name/user без password и результат backup/checkpoint.
- **Результат:** проект недели 10 запускается независимо, а foundation недели 9 сохранён.
- **Сценарии:** верный рабочий каталог; `.env` не отслеживается; target database не production; `manage.py check` проходит до model changes.

## Задание 2. Таблица проектирования fields

- **Исходные данные:** существующий custom `User`, сущности `BuyerProfile`, `CarMake`, `CarModel`, `CarSpecification` и исходное требование об общих полях.
- **Действие:** в журнале создайте таблицу `model | field | Python type | DB meaning | null | blank | default | constraint | reason`.
- **Результат:** перечислены все fields до написания model code.
- **Сценарии:** пустое и неизвестное значение различены; максимальная цена помещается в `DecimalField`; одинаковые названия марок рассмотрены; country field не получает выдуманный default.

Минимальные данные:

- `User`: унаследованный `is_active`, требуемые timestamps и существующие auth fields;
- `BuyerProfile`: user, country, balance, preferred car models/specifications;
- `CarMake`: name, country;
- `CarModel`: make, name, production year, base price;
- `CarSpecification`: car model, normalized key, value and optional unit;
- каждая concrete model: `is_active`, `created_at`, `updated_at`.

Country fields выполняются через согласованную версию `django-countries`. Все денежные fields этой предметной области имеют documented currency USD. PostGIS не подключается: на текущем этапе нет distance/radius/spatial query; условие его пересмотра запишите в журнале.

## Задание 3. Абстрактная base model

- **Исходные данные:** три общих технических field.
- **Действие:** создайте `TimeStampedActiveModel` в `common/models.py` и наследуйте от неё новые concrete models. Для `User`, который уже наследует `is_active` от `AbstractUser`, пока запишите staged plan добавления timestamps без общего случайного default и без конфликта fields; реализация backfill выполняется в день 3.
- **Результат:** общей table не появляется, а fields присутствуют в concrete models.
- **Сценарии:** новое значение активно; timestamps заполняются; изменение через instance `save()` меняет `updated_at`; объяснено, почему bulk `update()` ведёт себя иначе.

## Задание 4. Catalog models и характеристики

- **Исходные данные:** две марки и не менее трёх models, включая одинаковое имя model у разных марок.
- **Действие:** реализуйте `CarMake`, `CarModel`, `CarSpecification`, стабильные `__str__`, ordering и uniqueness по бизнес-смыслу. Характеристика должна быть queryable relation, а не неструктурированной строкой/JSON без контракта.
- **Результат:** допустимы, например, `Ford Focus` и другая марка с model name `Focus`, но duplicate одной и той же пары запрещён; одна model имеет несколько нормализованных характеристик.
- **Сценарии:** обычное имя; Unicode name; одинаковая pair; одинаковое model name у разных makes; duplicate specification key для одной model; same key у разных models; нижняя и верхняя граница production year по вашему явно записанному правилу.

Не пытайтесь сделать production year вечным hard-coded диапазоном без объяснения. Validation текущего года и database-expressible границы разделяются.

## Задание 5. Buyer profile, баланс и предпочтения

- **Исходные данные:** custom user недели 9; user с profile и user без profile.
- **Действие:** добавьте one-to-one `BuyerProfile`, не создавая второго auth user. Добавьте неотрицательный USD balance и явные M2M relations к preferred models/specifications.
- **Результат:** у одного user не больше одного profile; предпочтения запрашиваются через relations; отсутствие reverse profile обработано как ожидаемая ситуация.
- **Сценарии:** create profile; duplicate profile; доступ с обеих сторон; отсутствие profile; zero/positive/negative balance; no preferences; several preferences; duplicate relation; удаление user согласно выбранному `on_delete`.

## Задание 6. Constraints и checks

- **Исходные данные:** отрицательная, нулевая и положительная цена/баланс; валидный и невалидный year; duplicate specification.
- **Действие:** добавьте database constraints для правил, которые database способна гарантировать. Выполните `manage.py check` и проверку constraint через ORM.
- **Результат:** invalid row не сохраняется даже без form validation.
- **Сценарии:** price `-0.01`, `0.00`, обычная price; duplicate key; valid boundary year; invalid boundary.

## Задание 7. Первая migration

- **Исходные данные:** изменённые models и пустая очередь новых migrations.
- **Действие:** выполните `makemigrations --dry-run --verbosity 3`, затем создайте migration. Прочитайте operations, dependency и `sqlmigrate`; только после этого примените.
- **Результат:** migration соответствует ожидаемым tables/columns/constraints и появляется в `showmigrations` как applied.
- **Сценарии:** `check`; dry run; SQL review; forward apply; повторный `migrate` ничего не меняет.

## Обязательные сценарии дня

1. Abstract base не создаёт отдельную table.
2. Каждая concrete model имеет три общих field.
3. Для `User` записан безопасный staged plan timestamps без конфликта с `AbstractUser.is_active`.
4. One-to-one profile уникален по user.
5. Две марки с одинаковым model name допустимы, если так записано правило.
6. Duplicate make+model и duplicate specification key запрещены.
7. Negative price и balance запрещены database constraint.
8. Preferred models/specifications доступны через relations.
9. `__str__` не выполняет неожиданный relation query в типовом использовании.
10. Migration проходит на учебной PostgreSQL database.

## Контрольные вопросы

1. Чем `blank` отличается от `null`?
2. Почему `DecimalField` имеет два числовых параметра?
3. Почему `is_active` не является готовой системой soft delete?
4. Что доказывает constraint сверх Python validation?

---

# День 2. Связи и промежуточные models

## Паспорт задания

- **Цель:** спроектировать прямые и обратные связи без потери данных самой связи.
- **Рабочая область:** models приложений `dealerships`, `suppliers`, `trading`, `promotions`; журнал — `day_02_relationships.md`.
- **Результат:** профили компаний, preferences, explicit through-relations, promotions, best-supplier choice и неизменяемая история сделок/движений.
- **Порядок выполнения:** составьте матрицу связей; выберите `on_delete`; реализуйте справочники; добавьте through-models; добавьте исторические events; создайте migration; проверьте related access и delete behavior.
- **Наблюдаемый результат:** relations доступны с обеих сторон, duplicates невозможны, история защищена, а неправильное удаление отклоняется предсказуемо.
- **Готово, если:** у каждой relation объяснены cardinality и ownership; reverse names уникальны; through-models содержат данные связи; balances защищены; исторические movements не переписываются; delete scenarios проверены; минимум четырнадцать сценариев записаны.
- **Пример:** `dealership.inventory_rows.select_related("car_model")` возвращает строки остатков; `dealership.car_models` возвращает связанные модели автомобилей.
- **Обязательно для зачёта:** задания 1–7 и сценарии 1–10. **Рекомендация:** нарисовать ERD вручную; красивый diagram не заменяет `SCHEMA_MAP.md`.

## Теория

Прочитайте разделы 5–8 `THEORY.md`.

## Задание 1. Матрица связей

- **Исходные данные:** минимальные models из `README.md`.
- **Действие:** заполните таблицу `source | relation | target | cardinality | related_name | on_delete | owns history | reason`.
- **Результат:** для каждой связи есть решение до кода.
- **Сценарии:** parent без children; parent с одним child; parent с несколькими children; physical deletion; deactivation.

## Задание 2. Dealership profile, preferences и inventory

- **Исходные данные:** два dealerships, три car models, разные prices/quantities.
- **Действие:** создайте `DealershipProfile`, `DealershipPreference` и `DealershipInventory`; включите name, country/address и nonnegative USD balance. Предпочтения свяжите с models/specifications. Откройте M2M от dealership к car models через inventory `through`.
- **Результат:** профиль хранит настройки салона, preference queryable, inventory хранит `quantity` и `sale_price`, пара dealership+car_model уникальна.
- **Сценарии:** zero/positive/negative balance; no preferences; multiple preferences; zero/positive/negative stock; duplicate inventory pair; same model in two dealerships; inactive row.

## Задание 3. Supplier profile, catalog, loyalty и best choice

- **Исходные данные:** два suppliers разного founding year, общая car model, разные prices/stock, loyalty discount для одного dealership и выбранный лучший supplier.
- **Действие:** создайте `SupplierProfile`, `SupplierCatalogItem`, `SupplierLoyaltyDiscount`, `BestSupplierChoice`. Профиль содержит name, country/address, founded year и balance; catalog item — price/available quantity; loyalty — percent для пары supplier+dealership; best choice — unique dealership+car model, chosen supplier, calculated price, reason и calculated time.
- **Результат:** одна model доступна у нескольких suppliers; duplicate pairs не создаются; сохранённый выбор можно пересчитать позднее, не меняя catalog source.
- **Сценарии:** supplier без items; два suppliers одной model; zero/negative balance; valid/invalid founded year; zero availability; negative price/quantity; duplicate catalog pair; loyalty 0/100/outside range; duplicate best-choice pair; selected supplier без active catalog item отклоняется validation/service contract.

## Задание 4. Offer покупателя

- **Исходные данные:** buyer, dealership, car model, offered price и status.
- **Действие:** создайте `Offer` с `TextChoices`; обязательны buyer, desired car model, maximum price и lifecycle timestamps/status. Выберите snapshot fields, которые сохраняют смысл предложения.
- **Результат:** offer имеет валидный status, неотрицательную price и понятную историю.
- **Сценарии:** pending offer; valid transition пока только вручную; неизвестный status через `full_clean`; price zero; negative price; protected related object.

На этой неделе не строится полноценная state machine. Запишите, какие status transitions будут внедрены позднее в service layer.

## Задание 5. Purchase, Sale и movements

- **Исходные данные:** dealership inventory, accepted offer, supplier catalog item, positive units и balances участников.
- **Действие:** в `trading` создайте `Purchase` (закупка салона у поставщика), `Sale` (продажа покупателю), `StockMovement` и `BalanceMovement`. Исторические rows содержат snapshot price/units/reason и не редактируются обычным workflow.
- **Результат:** изменение текущей price не меняет прошлую сумму; stock/balance changes имеют audit trail и владельца/ссылку на операцию.
- **Сценарии:** one/several units; zero/negative units; debit/credit amount; invalid zero/negative movement по выбранному sign contract; изменение history запрещено service contract; physical delete referenced historical entity отклоняется.

## Задание 6. Promotions

- **Исходные данные:** dealership promotion и supplier promotion с периодом и percent.
- **Действие:** используйте отдельные concrete models `DealershipPromotion` и `SupplierPromotion`, чтобы не вводить generic foreign key. Свяжите с применимыми car models по ясно выбранному правилу.
- **Результат:** owner type однозначен, percent и time interval защищены constraints.
- **Сценарии:** 0%, 100%, below 0, above 100; open/closed interval по выбранному контракту; end before start; inactive promotion.

## Задание 7. Migration и related access

- **Исходные данные:** все новые relations и deterministic demo dataset.
- **Действие:** создайте/read/apply migration. В shell выполните прямые, обратные и M2M queries и запишите types результатов.
- **Результат:** каждый related name работает и возвращает ожидаемый instance/manager/QuerySet.
- **Сценарии:** relation пустая; одна row; несколько rows; отсутствующий one-to-one; protected delete; allowed cascade только там, где обоснован.

## Обязательные сценарии дня

1. Same car model присутствует в двух dealerships.
2. One dealership содержит несколько models и preferences.
3. Dealership/supplier balances не уходят ниже zero.
4. Duplicate inventory pair запрещён database.
5. Same supplier catalog pair не дублируется.
6. Zero stock/availability допустимы, отрицательные — нет.
7. Loyalty percent outside 0–100 отклоняется.
8. Best choice unique per dealership+car model.
9. Price snapshots истории не меняются после изменения текущей price.
10. Stock и balance movements имеют ясный immutable contract.
11. Promotion below 0 и above 100 отклоняется.
12. End before start отклоняется.
13. Каждый reverse name проходит shell query.
14. Защищённое physical delete действительно отклоняется.

## Контрольные вопросы

1. Почему inventory — это model, а не автоматическая M2M table?
2. Когда `CASCADE` допустим, а когда опасен?
3. Чем прямая relation отличается от reverse manager?
4. Зачем исторической операции snapshot price и отдельные movement rows?

---

# День 3. Schema migrations и data migrations

## Паспорт задания

- **Цель:** безопасно развивать заполненную schema и воспроизводить историю с нуля.
- **Рабочая область:** migration files приложений, `catalog/models.py`, `accounts/models.py`; журнал — `day_03_migrations.md`.
- **Результат:** staged добавление обязательного уникального `code` для `CarModel`, backfill `User.created_at`/`updated_at`, обратимые data migrations и clean replay.
- **Порядок выполнения:** создайте исходные rows; зафиксируйте plan; добавьте временный field; заполните historical models; проверьте данные; ужесточите field; выполните reverse/forward; разверните чистую database.
- **Наблюдаемый результат:** существующие rows получают deterministic unique codes, вся chain применяется с нуля и откатывается до оговорённой точки.
- **Готово, если:** migration разделена на безопасные stages; текущая model не импортируется в `RunPython`; cross-app dependencies явны; reverse path проверен; clean replay записан.
- **Пример:** `Skoda Octavia` получает стабильный code формата `skoda-octavia-<id>`; точный algorithm выбирает ученик и документирует.
- **Обязательно для зачёта:** задания 1–7 и сценарии 1–9. **Рекомендация:** проверить migration на snapshot/backup старого учебного dataset, а не только на пустой schema.

## Теория

Прочитайте разделы 9–11 `THEORY.md`.

## Задание 1. Исходное состояние

- **Исходные данные:** минимум пять `CarModel`, включая Unicode, пробелы и одинаковые names у разных makes.
- **Действие:** сохраните row count, ids/names и текущий migration plan до изменения.
- **Результат:** есть доказательство, какие данные должна сохранить migration.
- **Сценарии:** Latin name; Unicode name; punctuation; duplicate model name across makes; inactive row.

## Задание 2. Первая schema stage

- **Исходные данные:** заполненная `catalog_carmodel` без `code`.
- **Действие:** добавьте временно допустимый `code` так, чтобы migration могла примениться без фиктивного общего unique default.
- **Результат:** column существует, старые rows сохранены, schema и model state согласованы на этой стадии.
- **Сценарии:** plan review; SQL review; apply with existing rows; repeated migrate no-op.

## Задание 3. Forward data migrations

- **Исходные данные:** historical `CarModel`, `CarMake` и существующие `User` rows из migration state.
- **Действие:** через `apps.get_model()` заполните deterministic unique codes. Разрешите collisions предсказуемо, например стабильным id suffix. Отдельной migration/backfill заполните `User.created_at` из historical `date_joined`, а `updated_at` — по явно описанному безопасному правилу; затем отдельным state change сделайте fields обязательными.
- **Результат:** ни одной пустой/duplicate code и ни одного `NULL` в обязательных user timestamps после финальной стадии.
- **Сценарии:** Unicode transliteration/slug behavior; collision; inactive row; user with known date_joined; rollback/forward; clean database with no users before seed.

## Задание 4. Reverse data migration

- **Исходные данные:** заполненные codes.
- **Действие:** напишите reverse callable, который возвращает field в допустимое состояние предыдущего stage.
- **Результат:** reverse migration не падает и не затрагивает несвязанные columns.
- **Сценарии:** backward migrate; inspect data; forward again; row counts одинаковы.

Если полное восстановление значения логически невозможно, нужно до реализации согласовать необратимую migration и объяснить почему. Для учебного `code` ожидается обратимый вариант.

## Задание 5. Финальное ужесточение

- **Исходные данные:** заполненные уникальные codes.
- **Действие:** следующей migration сделайте field обязательным и unique по принятому контракту.
- **Результат:** новые rows без code либо получают корректный application-level value, либо отклоняются ясным способом; duplicates запрещает database.
- **Сценарии:** new unique; missing code; duplicate code; code maximum length.

## Задание 6. Cross-app dependency audit

- **Исходные данные:** migration graph всех apps.
- **Действие:** проверьте dependencies каждой migration и запишите, какие historical models доступны на её стадии.
- **Результат:** `migrate --plan` детерминирован, нет неявной надежды на порядок alphabetical apps.
- **Сценарии:** clean plan; backward target; forward plan; отсутствующая dependency описана как прогноз, но не оставлена в коде.

## Задание 7. Clean replay

- **Исходные данные:** полный migration chain и отдельная пустая учебная database/schema, согласованная наставником.
- **Действие:** примените всю chain с нуля, запустите checks и seed; затем сравните constraints и ожидаемые row counts.
- **Результат:** новый разработчик может воспроизвести schema без ручной правки SQL.
- **Сценарии:** empty database; full forward; selected backward/forward; seed once; seed repeated согласно его контракту.

## Обязательные сценарии дня

1. Existing rows переживают первое schema change.
2. Data migration использует historical models.
3. Unicode/collision codes разрешаются deterministic.
4. Все rows получают непустой code, а существующие users — timestamps по documented backfill rule.
5. Duplicate code запрещён финальной schema.
6. Reverse callable фактически запущен.
7. Повторный forward даёт корректное состояние.
8. Cross-app dependencies объяснены.
9. Clean database проходит всю chain.

## Контрольные вопросы

1. Почему одинаковый default опасен для нового unique field?
2. Почему нельзя импортировать текущий `CarModel` в старую migration?
3. Чем migration state отличается от текущей database schema?
4. Что именно доказывает clean replay?

---

# День 4. QuerySet и managers

## Паспорт задания

- **Цель:** писать предсказуемые цепочечные запросы и создать предметный custom QuerySet без скрытия rows.
- **Рабочая область:** QuerySet/manager code рядом с соответствующими models; журнал — `day_04_querysets_managers.md`.
- **Результат:** методы `active()`, `in_stock()`, `for_dealership()`, `within_price()` и набор доказанных QuerySet experiments.
- **Порядок выполнения:** создайте deterministic dataset; спрогнозируйте evaluation; проверьте базовые methods; создайте custom QuerySet; подключите manager; проверьте composition и manager visibility.
- **Наблюдаемый результат:** методы комбинируются в любом разумном порядке, возвращают QuerySet, а неактивные rows доступны через нефильтрующий manager.
- **Готово, если:** ленивость показана измерением queries; `get` exceptions проверены; custom methods не печатают и не вычисляют QuerySet преждевременно; manager behavior объяснён; минимум десять experiments записаны.
- **Пример:** `Inventory.objects.active().in_stock().within_price(Decimal("30000"))` остаётся QuerySet до evaluation.
- **Обязательно для зачёта:** задания 1–7 и сценарии 1–10. **Рекомендация:** использовать shell_plus нельзя требовать; стандартного Django shell достаточно.

## Теория

Прочитайте разделы 12–13 и 17 `THEORY.md`.

## Задание 1. Deterministic dataset

- **Исходные данные:** минимум 3 makes, 6 car models, 3 dealerships и 10 inventory rows; есть equal prices, zero stock и inactive rows.
- **Действие:** создайте idempotent management command `seed_orm_demo` или другой согласованный deterministic seed.
- **Результат:** первый запуск создаёт dataset; повторный не плодит duplicates и сообщает counts.
- **Сценарии:** empty database; repeated seed; partially existing reference data; invalid dependency выдаёт понятную ошибку.

## Задание 2. Ленивость и evaluation

- **Исходные данные:** QuerySet active inventory.
- **Действие:** измерьте query count после построения, после первого iteration и после второго iteration того же QuerySet; сравните с отдельно построенным QuerySet.
- **Результат:** журнал показывает фактический момент SQL и result cache behavior.
- **Сценарии:** unevaluated; first evaluation; repeated same instance; new equivalent QuerySet; `.iterator()`.

## Задание 3. Базовые contracts

- **Исходные данные:** existing pk, missing pk и неуникальный filter.
- **Действие:** сравните `get`, `filter`, `first`, `exists`, `count`, `len`, `values`, `values_list`.
- **Результат:** для каждого method записаны result type, number of queries и exception/empty behavior.
- **Сценарии:** zero rows; one row; several rows; already evaluated QuerySet.

## Задание 4. Custom QuerySet

- **Исходные данные:** `DealershipInventory` fields.
- **Действие:** реализуйте chainable methods `active()`, `in_stock()`, `for_dealership(dealership_or_id)`, `within_price(max_price)`.
- **Результат:** каждый method возвращает QuerySet и не вызывает `list`, `print` или hidden evaluation.
- **Сценарии:** zero price; exact boundary; above boundary; no matches; composed filters; invalid type обрабатывается согласно documented contract.

## Задание 5. Manager strategy

- **Исходные данные:** active и inactive rows.
- **Действие:** подключите custom QuerySet через manager. Сохраните нефильтрующий default/base path; если выбрано иначе, докажите admin/reverse/dump behavior.
- **Результат:** `objects.all()` и `.active()` имеют прозрачный смысл.
- **Сценарии:** inactive direct lookup; reverse relation; admin queryset; seed/update existing inactive row.

## Задание 6. Stable ordering и slicing

- **Исходные данные:** несколько rows с одинаковой price.
- **Действие:** добавьте stable ordering с tie-breaker и проверьте slicing/pagination-like ranges.
- **Результат:** одинаковый dataset возвращает детерминированный порядок.
- **Сценарии:** equal price; empty slice; first page; next page; no ordering — только как демонстрация риска.

## Задание 7. SQL explanation

- **Исходные данные:** главный composed QuerySet дня.
- **Действие:** сохраните его SQL representation без secrets и объясните SELECT/FROM/JOIN/WHERE/ORDER BY.
- **Результат:** каждая ORM-chain часть сопоставлена с SQL fragment.
- **Сценарии:** simple filter; related lookup; empty result; stable ordering.

## Обязательные сценарии дня

1. QuerySet creation не выполняет SQL.
2. First evaluation выполняет ожидаемый query.
3. Reuse evaluated QuerySet демонстрирует cache.
4. Missing `get` даёт specific exception.
5. Nonunique `get` даёт specific exception.
6. Empty filter остаётся пустым QuerySet.
7. Custom methods chainable.
8. Exact max price включается по контракту.
9. Inactive rows не исчезают из administrative access.
10. Equal prices имеют stable ordering.

## Контрольные вопросы

1. Когда QuerySet вычисляется?
2. Почему `len(queryset)` и `count()` не всегда взаимозаменяемы?
3. Почему manager не должен молча скрывать историю?
4. Что делает custom QuerySet хорошим предметным API?

---

# День 5. `Q`, `F`, annotations и aggregates

## Паспорт задания

- **Цель:** перенести фильтрацию, относительные updates и сводные вычисления в database без искажения результата.
- **Рабочая область:** `analytics/queries.py`, models/querysets и журнал `day_05_expressions_aggregates.md`.
- **Результат:** пять именованных аналитических queries, безопасный conditional decrement и проверка aggregate edge cases.
- **Порядок выполнения:** расширьте dataset; сформулируйте вопросы словами; реализуйте `Q`; примените `F`; создайте annotations/aggregates; сравните ожидаемые ручные итоги; исследуйте duplicates JOIN.
- **Наблюдаемый результат:** queries возвращают точные значения на обычных, пустых и неоднозначных данных; decrement не уходит ниже нуля.
- **Готово, если:** сложная логика имеет скобки; `F` result обновлён из database; `annotate` и `aggregate` различаются; пустая сумма обработана; JOIN multiplication проверен.
- **Пример:** отчёт содержит `dealership_id, active_models_count, total_units, inventory_value`, а dealership без inventory имеет осознанные zero/NULL values.
- **Обязательно для зачёта:** задания 1–7 и сценарии 1–11. **Рекомендация:** дать каждому сложному query отдельную function с говорящим именем и документированным result contract.

## Теория

Прочитайте разделы 14–17 `THEORY.md`.

## Задание 1. Контрольный dataset

- **Исходные данные:** dealership без inventory; dealership с zero stock; active/inactive rows; две rows одинаковой price; несколько promotions; sales в разные периоды.
- **Действие:** дополните idempotent seed и вручную рассчитайте ожидаемые итоги в журнале.
- **Результат:** есть таблица expected values, независимая от ORM implementation.
- **Сценарии:** empty group; zero; normal; duplicate joins; inactive relation.

## Задание 2. Complex filter с `Q`

- **Исходные данные:** budget, список стран/марок и условие «в наличии И (цена не выше budget ИЛИ активная акция)».
- **Действие:** выразите условие через `Q` со скобками; реализуйте противоположный filter через `~Q` только если его смысл записан.
- **Результат:** возвращаются ровно строки из expected table.
- **Сценарии:** below/equal/above budget; active/inactive promotion; zero stock; no filter values.

## Задание 3. Conditional decrement через `F`

- **Исходные данные:** inventory quantity и requested units.
- **Действие:** одним conditional update уменьшите stock, только если units положительны и stock достаточен. Result contract — число updated rows или domain result.
- **Результат:** успешное списание меняет ровно одну row, неуспешное — ни одной; final value читается заново.
- **Сценарии:** units 1; units exactly all stock; units above stock; units 0; units negative; missing inventory id.

## Задание 4. Inventory annotations

- **Исходные данные:** dealerships и inventory rows.
- **Действие:** верните для каждого dealership `active_models_count`, `total_units`, `inventory_value`. Если expression types неоднозначны, задайте output field.
- **Результат:** значения совпадают с ручной expected table.
- **Сценарии:** no inventory; zero quantity; inactive row; equal prices; multiple rows.

## Задание 5. Global aggregates

- **Исходные данные:** filtered sales period и период без sales.
- **Действие:** через `aggregate()` получите units, revenue и average unit price; явно обработайте пустой набор.
- **Результат:** dictionary contract документирован, типы (`Decimal`, integer, `None`/zero) предсказуемы.
- **Сценарии:** normal period; empty period; one sale; boundary timestamps.

## Задание 6. JOIN multiplication experiment

- **Исходные данные:** dealership с минимум двумя inventory rows и двумя promotions.
- **Действие:** намеренно создайте aggregate через оба one-to-many joins, сравните ошибочный и корректный result, исследуйте SQL.
- **Результат:** журнал объясняет, почему rows multiplied и где `distinct` помогает, а где нужен subquery/другая decomposition.
- **Сценарии:** 2×2 children; one side empty; `Count(distinct=True)`; `Sum` с проверкой, где distinct может менять смысл неверно.

## Задание 7. Query module contracts

- **Исходные данные:** пять итоговых queries.
- **Действие:** разместите их в `analytics/queries.py` или обоснованном QuerySet module; укажите inputs, return shape и empty behavior.
- **Результат:** query functions ничего не печатают и могут вызываться из shell/test/view.
- **Сценарии:** valid input; empty result; invalid date range; inactive entity.

## Обязательные сценарии дня

1. AND/OR precedence даёт ожидаемый список.
2. Exact budget boundary проверена.
3. Decrement one unit успешен.
4. Decrement all stock оставляет zero.
5. Insufficient stock не меняет row.
6. Zero/negative units отклонены.
7. Annotation включает dealership без inventory по контракту.
8. Empty aggregate имеет явный result.
9. Revenue использует Decimal-compatible expression.
10. JOIN multiplication воспроизведён.
11. Corrected aggregate совпадает с ручным расчётом.

## Контрольные вопросы

1. Зачем `Q`, если у `filter()` уже есть keyword arguments?
2. Что остаётся в instance после update через `F`?
3. Чем result `aggregate()` отличается от `annotate()`?
4. Почему `distinct=True` не универсальное лекарство от неверной суммы?

---

# День 6. N+1, индексы и транзакционная конкурентность

## Паспорт задания

- **Цель:** измерить стоимость ORM-запросов и защитить составную операцию продажи от гонки.
- **Рабочая область:** `analytics/queries.py`, `trading/services.py`, relevant `Meta`; журнал — `day_06_performance_transactions.md`.
- **Результат:** доказанный fix N+1, один обоснованный index и atomic service продажи с locks, ledger и stock movements.
- **Порядок выполнения:** воспроизведите N+1; измерьте queries; примените eager loading; зафиксируйте budget; выберите query для index; сравните plan; реализуйте короткую transaction; запустите two-connection race.
- **Наблюдаемый результат:** query count не растёт с числом rows, explain plan зафиксирован, а две конкурентные попытки не продают больше доступного stock.
- **Готово, если:** есть before/after counts; выбран правильный eager-loading method; index привязан к query; transaction имеет ясную границу; `select_for_update` выполняется внутри `atomic`; race проверена на PostgreSQL.
- **Пример:** при 2 и 20 inventory rows каталог использует один и тот же небольшой query budget; точное число определяется фактическим result contract.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–12. **Рекомендация:** добавить штатный Django test с `assertNumQueries`, если тестовая база уже настроена.

## Теория

Прочитайте разделы 18–22 `THEORY.md`.

## Задание 1. Плохой N+1 scenario

- **Исходные данные:** 2 и затем не менее 20 inventory rows, связанные с dealership, car model и make.
- **Действие:** сформируйте catalog rows и внутри iteration обратитесь к relations без eager loading. Измерьте queries через разрешённый Django mechanism.
- **Результат:** query count растёт вместе с N; сохранены count и повторяющийся SQL pattern.
- **Сценарии:** N=0; N=2; N=20; повторное вычисление нового QuerySet.

## Задание 2. `select_related`

- **Исходные данные:** тот же catalog contract с одиночными FK relations.
- **Действие:** загрузите dealership, car model и make через `select_related`.
- **Результат:** те же catalog values, но query count не растёт с N.
- **Сценарии:** N=0/2/20; nullable relation, если такая реально есть; ordering unchanged.

## Задание 3. `prefetch_related`

- **Исходные данные:** dealerships и их коллекции inventory/promotions.
- **Действие:** используйте `prefetch_related`/`Prefetch` для reverse/M2M collections; при custom filter задайте отдельный result contract.
- **Результат:** fixed small number of queries, корректный набор active related rows.
- **Сценарии:** parent без children; 1 child; many children; subsequent different filter, который не должен ошибочно считаться cached.

## Задание 4. Query budget

- **Исходные данные:** optimized catalog и dealership summary.
- **Действие:** зафиксируйте максимально допустимое число queries для каждого observable result и объясните каждую query.
- **Результат:** budget нарушается при возврате к N+1 implementation.
- **Сценарии:** small/large N; empty result; optional relation; repeated access.

## Задание 5. Index hypothesis

- **Исходные данные:** реальный query `dealership + is_active + sale_price ordering/filter` и достаточно большой synthetic dataset.
- **Действие:** получите SQL и `explain()` до index; сформулируйте hypothesis; добавьте named index migration; получите plan после.
- **Результат:** документ объясняет column order, write cost и фактический plan choice.
- **Сценарии:** selective query; broad query; tiny dataset caveat; index migration forward/backward.

Не обещайте `Index Scan`: PostgreSQL может выбрать другой корректный plan. Оценивается объяснение на данных, а не заранее желаемая строка.

## Задание 6. Atomic sale service

- **Исходные данные:** inventory id, buyer profile, positive units, agreed unit price; stock и buyer balance больше, равны или меньше требуемых значений.
- **Действие:** в `trading/services.py` реализуйте use case `register_sale`: validate cheap input, открыть `atomic`, в стабильном порядке получить inventory/buyer/dealership balances с `select_for_update`, повторно проверить stock/balance, создать `Sale`, `StockMovement` и две `BalanceMovement`, изменить stock и оба balances, вернуть domain result.
- **Результат:** либо созданы согласованные history rows и все balance/stock changes, либо не изменилось ничего.
- **Сценарии:** enough stock/balance; exact stock/balance; insufficient stock; insufficient money; zero/negative units; missing/inactive inventory; unconfirmed email пока проверяется как documented precondition; forced exception после создания Sale доказывает rollback всех изменений.

## Задание 7. Two-connection race

- **Исходные данные:** stock=1 и две независимые попытки купить по 1 unit.
- **Действие:** с двумя независимыми database connections/processes воспроизведите concurrent start, дождитесь обеих попыток и зафиксируйте results. Не используйте один connection как доказательство конкуренции.
- **Результат:** одна операция успешна, другая получает ожидаемый business failure; stock=0, sales count и ledger/movement counts увеличились ровно на одну сделку.
- **Сценарии:** competing sale; first transaction rollback; deterministic lock order discussion; timeout/cleanup.

## Задание 8. ORM comparison

- **Исходные данные:** разделы 23–26 теории и официальная документация.
- **Действие:** начните `day_07_django_orm/ORM_COMPARISON.md`; ответьте на вопросы: purpose ORM, Django vs SQLAlchemy, Core vs ORM, M2M association, Session, flush vs commit, result methods, migration tools, Alembic pros/limitations.
- **Результат:** таблица/объяснение на 1–3 страницы без установки SQLAlchemy и без кода второй реализации.
- **Сценарии:** отдельные contracts `scalar_one`/`scalar_one_or_none`; flush followed by rollback; Alembic autogenerate rename risk; выбор Django migrations для текущего проекта.

## Обязательные сценарии дня

1. N+1 измерен при N=2 и N=20.
2. `select_related` применён только к подходящим relations.
3. Reverse/M2M загружены через prefetch.
4. Optimized result совпадает с исходным.
5. Query budget не растёт с N.
6. Index имеет конкретную query hypothesis.
7. Plan до/после сохранён и объяснён.
8. Успешная sale атомарно меняет две части состояния.
9. Искусственная ошибка откатывает всё.
10. Insufficient stock ничего не меняет.
11. Two-connection race не создаёт oversell.
12. ORM comparison покрывает все обзорные темы.

## Контрольные вопросы

1. Почему query time на пяти rows плохо доказывает устранение N+1?
2. Почему `prefetch_related` не заменяется всегда JOIN?
3. Что гарантирует `atomic`, но не гарантирует без lock?
4. Чем conditional `F` update отличается от workflow с `select_for_update`?

---

# День 7. Итоговый ORM-прототип автосалона

## Паспорт задания

- **Цель:** собрать models, migrations и queries в воспроизводимый вертикальный ORM-срез и защитить проект устно.
- **Рабочий каталог:** весь `day_07_django_orm/`; документы — `SCHEMA_MAP.md`, `ORM_COMPARISON.md` и раздел дня 7 в журнале оценки.
- **Результат:** clean-installable Django ORM project с deterministic seed, schema map, constraints, query budgets и atomic sale scenario.
- **Порядок выполнения:** сверить дерево; собрать вертикальные slices; очистить расхождения; развернуть clean database; запустить 30 сценариев; проверить secrets/migrations; подготовить ответы; передать на review.
- **Наблюдаемый результат:** новый учебный database target проходит migrations+seed, domain queries дают ожидаемые данные, N+1 budget стабилен, concurrent sale не oversells.
- **Готово, если:** code/project docs согласованы; migrations не требуют ручного SQL; constraints и indexes видны в schema; 30 сценариев отмечены фактическими результатами; comparison завершён; self-assessment заполнена.
- **Пример:** `seed -> catalog query -> dealership inventory summary -> register_sale -> stock/revenue query` выполняется как один связный учебный путь.
- **Обязательно для зачёта:** все разделы, 30 сценариев и защита. **Рекомендация:** один clean commit после принятия; premature DRF endpoints баллов не добавляют.

## Теория

Повторите разделы 1, 7, 9–13, 16, 18, 20–27 `THEORY.md`.

## Обязательное дерево и обязанности

```text
day_07_django_orm/
├── manage.py                         # Django command entry point
├── README.md                         # clean setup и команды проверки
├── config/                           # settings и root routing из недели 9
├── common/models.py                  # только abstract common model
├── accounts/models.py                # User + BuyerProfile
├── catalog/models.py                 # CarMake, CarModel, CarSpecification
├── dealerships/
│   ├── models.py                     # DealershipProfile, Preference, Inventory
│   └── management/commands/
│       └── seed_orm_demo.py          # deterministic idempotent seed
├── suppliers/models.py               # SupplierProfile, CatalogItem, loyalty, best choice
├── trading/
│   ├── models.py                     # Offer, Purchase, Sale and movements
│   └── services.py                   # atomic register_sale workflow
├── promotions/models.py              # separate seller promotion models
├── analytics/queries.py              # read-only named ORM reports
├── */migrations/                     # complete versioned schema/data history
├── SCHEMA_MAP.md                      # schema, cardinality, constraints, indexes
└── ORM_COMPARISON.md                  # Django/SQLAlchemy/Alembic overview
```

Если actual layout отличается, в `README.md` нужно объяснить обязанности каждого дополнительного module.

## Вертикальные срезы сборки

### Срез 1. Catalog

- **Исходные данные:** make, model, country, year и base price.
- **Действие:** создать и получить catalog objects по unique code.
- **Результат:** duplicates/invalid money отклоняются, list ordering стабилен.
- **Сценарии:** ordinary, duplicate pair, duplicate code, negative price, inactive object.

### Срез 2. Supply

- **Исходные данные:** supplier, car model, price и availability.
- **Действие:** связать supplier с catalog через `SupplierCatalogItem`, затем создать `Purchase` snapshot и соответствующие movements.
- **Результат:** текущая supplier price и historical purchase amount различаются корректно.
- **Сценарии:** multiple suppliers, duplicate pair, zero stock, unavailable amount, changed current price.

### Срез 3. Dealership inventory

- **Исходные данные:** dealership, car model, stock и sale price.
- **Действие:** создать inventory through-row и вывести catalog card с related make/dealership.
- **Результат:** exact one row per pair и optimized query budget.
- **Сценарии:** two dealerships, zero stock, negative stock, inactive row, N=20.

### Срез 4. Buyer offer and sale

- **Исходные данные:** buyer, dealership inventory, offer price/status и units.
- **Действие:** создать offer; для допустимого случая провести atomic sale service.
- **Результат:** sale snapshot и movements созданы, stock/buyer balance изменены согласованно, failed operation ничего не меняет.
- **Сценарии:** enough/exact/insufficient stock, enough/exact/insufficient balance, invalid units, inactive inventory, forced rollback, concurrency.

### Срез 5. Promotions and analytics

- **Исходные данные:** valid/invalid periods, discount percent, sales periods.
- **Действие:** создать promotions и получить dealership inventory/revenue summaries.
- **Результат:** constraints отклоняют invalid rules, aggregates совпадают с ручным расчётом.
- **Сценарии:** 0/100/out-of-range percent, empty aggregate, join multiplication, inactive promotion.

## `SCHEMA_MAP.md`

Для каждой concrete model укажите:

```text
Purpose:
Table:
Primary key:
Fields and nullability:
Relations and cardinality:
on_delete reason:
Unique constraints:
Check constraints:
Indexes and supported query:
Historical/snapshot fields:
Active/inactive visibility:
```

Добавьте matrix бизнес-правил:

```text
Rule | Python validation | DB constraint | transaction/lock | required scenario
```

## `ORM_COMPARISON.md`

Документ обязан кратко и своими словами покрыть:

1. назначение ORM и цену абстракции;
2. Django ORM vs SQLAlchemy;
3. SQLAlchemy Core vs ORM;
4. M2M association table/object;
5. `Session` и unit of work;
6. `flush` vs `commit`;
7. `scalar`, `scalar_one`, `scalar_one_or_none`, `scalars`;
8. `fetchone`, `fetchall`, `first`, `one`;
9. migration tools Python;
10. Alembic strengths, limitations и autogenerate review;
11. почему текущая schema управляется Django migrations.

## Финальные 30 сценариев

### Позитивные

1. Clean database получает всю migration chain.
2. Seed на empty database создаёт expected counts.
3. Repeated seed не создаёт duplicates.
4. User получает один buyer profile.
5. Catalog содержит несколько makes/models/specifications и queryable preferences.
6. Same model name у разных makes работает по contract.
7. Supplier catalog содержит одну model от двух suppliers.
8. Dealerships содержат same model с разными price/stock.
9. Loyalty/best-supplier choice и promotions 0%/100% обрабатываются по contract.
10. Catalog query возвращает related names.
11. Inventory annotation совпадает с manual total.
12. Sales aggregate совпадает с manual total.
13. Successful sale создаёт history/movements и согласованно меняет stock и оба balance.
14. Exact-stock/exact-balance sale оставляет zero без отрицательных значений.

### Граничные

15. Dealership без inventory попадает/не попадает в отчёт согласно documented contract.
16. Empty sales period возвращает documented zero/NULL shape.
17. Equal prices сортируются стабильно.
18. Unicode and punctuation code migration deterministic.
19. Inactive rows доступны administrative manager и скрываются только explicit `.active()`.
20. Catalog query budget одинаков по порядку величины для N=2 и N=20.
21. Reverse then forward data migration сохраняет expected row counts.
22. Broad query plan может выбрать sequential scan и объяснён.

### Ошибочные и конкурентные

23. Duplicate inventory pair отклоняется database.
24. Duplicate supplier pair отклоняется database.
25. Negative money/stock/units отклоняются.
26. Promotion percent или period вне правил отклоняется.
27. Protected historical relation нельзя физически удалить.
28. Forced exception внутри sale откатывает Sale, movements, stock и balances.
29. Insufficient stock или buyer balance не создаёт Sale и movements.
30. Two concurrent attempts при stock=1 дают одну sale, корректный ledger и final stock=0.

Для каждого сценария сохранить: setup, command/test, prediction, actual result и explanation. Если сценарий не запускался, статус `не проверено`, а не `passed`.

## Ограничения на ещё не изученные инструменты

- Не создавать DRF serializer/view/router.
- Не добавлять JWT и permissions.
- Не запускать sale через Celery.
- Не использовать Redis lock вместо database transaction.
- Не прятать N+1 за cache.
- Не внедрять repository/unit-of-work abstractions поверх Django ORM.
- Не подключать SQLAlchemy/Alembic к текущей database.
- Не использовать raw SQL, пока тот же contract ясно выражается ORM; исключение согласуется и документируется.
- Не делать frontend.

## Финальный чек-лист сдачи

- [ ] Все предыдущие дни зачтены.
- [ ] `manage.py check` проходит.
- [ ] Нет незакоммиченных model changes без migration.
- [ ] Migration plan прочитан.
- [ ] Clean replay доказан.
- [ ] Data migration использует historical models.
- [ ] Constraints проверены invalid writes.
- [ ] Index связан с конкретным query и plan.
- [ ] Seed deterministic и idempotent.
- [ ] Custom QuerySet chainable.
- [ ] Default/base manager не скрывает данные неожиданно.
- [ ] N+1 имеет before/after measurement и budget.
- [ ] `register_sale` atomic и не oversells.
- [ ] Все 30 сценариев имеют честный статус.
- [ ] `SCHEMA_MAP.md` совпадает с code.
- [ ] `ORM_COMPARISON.md` завершён.
- [ ] Secrets и production data отсутствуют.
- [ ] Самооценка заполнена.

## Вопросы защиты

1. Покажите путь от model field до SQL column и migration operation.
2. Почему inventory реализован through-model?
3. Какие relations защищены `PROTECT` и почему?
4. Какой invariant обеспечен одновременно validation и constraint?
5. Проведите migration code от forward к reverse.
6. Когда вычисляется ваш главный QuerySet?
7. Почему custom manager не скрывает inactive history?
8. Объясните SQL одного `Q` query.
9. Объясните один `F` update и его результат count.
10. Покажите разницу result shapes `annotate`/`aggregate`.
11. Где JOIN multiplication и как она исправлена?
12. Покажите N+1 counts до и после.
13. Почему выбран `select_related`, а не prefetch, в одном месте?
14. Почему выбран prefetch, а не `select_related`, в другом?
15. Какой query поддерживает ваш index?
16. Почему PostgreSQL может не выбрать index?
17. Где начинается и завершается transaction продажи?
18. Как row lock предотвращает oversell?
19. Что будет при исключении после создания Sale?
20. Чем `flush` SQLAlchemy отличается от commit?
21. Почему Alembic не используется в этом Django-проекте?
22. Что вы сознательно отложили до недели 11?

## Передача на проверку

После заполнения checklist напишите: `Проверь итоговый проект недели 10`. Наставник проверит files, migration history, runtime scenarios и понимание, но не будет исправлять код ученика во время review.
