# Практика недели 11: первый вертикальный Django-сценарий

Статус: **заблокирована до явного допуска из недели 10**.

## Общие правила

- Все дни развивают один проект в `day_07_vertical_slice/`.
- Переносится только принятый ORM-проект недели 10.
- Код пишет и исправляет ученик; наставник не переписывает решение во время review.
- Дневной `.md` хранит predictions, commands, фактические результаты и объяснения.
- Business operation существует в одном service и не копируется в command/admin/view.
- HTTP использует Django `JsonResponse`; DRF начнётся на неделе 12.
- Tests запускаются штатным Django runner; новые зависимости не устанавливаются.
- Query count измеряется вокруг полного результата, а не ленивого QuerySet.
- Все изменения проверяются на isolated учебной PostgreSQL/test database.

## Формат эксперимента

```text
Experiment ID:
Question:
Initial state:
Input/command/request:
Prediction:
Actual result:
Database changes:
SQL/query count/log event when relevant:
Explanation:
Next correction:
```

Для procurement сохраняйте таблицу `before/after` со supplier stock, dealership stock, обоими balances и количеством Purchase/StockMovement/BalanceMovement.

## Самооценка дня

1. Что я сделал самостоятельно?
2. Какой component владеет главным правилом дня?
3. Где prediction отличался от actual result?
4. Какой observable contract я теперь могу объяснить?
5. Какие queries или database changes произошли?
6. Что осталось непонятным?
7. Сколько времени заняла работа?

## Шкала

| Критерий | Баллы |
|---|---:|
| Корректность результата | 0–3 |
| Выполнение условий | 0–2 |
| Граничные и ошибочные сценарии | 0–2 |
| Читаемость и архитектурные границы | 0–1 |
| Понимание и самооценка | 0–1 |
| Самостоятельность исправлений | 0–1 |

---

# День 1. Контракт вертикального среза и baseline

## Документация

- [Django: Database transactions](https://docs.djangoproject.com/en/5.2/topics/db/transactions/) — границы атомарной бизнес-операции вертикального среза.

## Паспорт задания

- **Цель:** превратить описание недели в однозначный поток данных, не меняя business code наугад.
- **Рабочая область:** перенос проекта в `day_07_vertical_slice/`; `day_07_vertical_slice/VERTICAL_SLICE.md`; журнал — `day_01_slice_contract.md`.
- **Результат:** source/baseline audit, use-case contract, responsibility map, state-transition table и список изменений.
- **Порядок выполнения:** подтвердите допуск; перенесите проект; проверьте database; запустите baseline; опишите flow/contracts/errors; сравните schema с needs; составьте implementation slices.
- **Наблюдаемый результат:** week 10 по-прежнему проходит проверки, а документ показывает component и row каждого шага.
- **Готово, если:** source commit указан; database безопасна; baseline честно записан; happy/error flows описаны; ownership однозначен; нет DRF/Celery; восемь scenarios разобраны.
- **Пример:** `procure_inventory(dealership_id=3, supplier_item_id=8, units=2) -> ProcurementResult(...)`.
- **Обязательно для зачёта:** задания 1–7 и scenarios 1–8. **Рекомендация:** маленькая sequence diagram после текстового contract.

## Теория

Прочитайте разделы 1–3 и 33–34 `THEORY.md`.

## Задание 1. Активация и перенос

- **Исходные данные:** допуск недели 10, accepted project и Git history.
- **Действие:** подтвердите допуск; перенесите project и запишите source branch/commit.
- **Результат:** week 10 неизменна, week 11 имеет самостоятельную рабочую область.
- **Сценарии:** correct source; missing approval; dirty source; `.env` untracked.

## Задание 2. Target database

- **Исходные данные:** environment settings.
- **Действие:** выведите безопасные vendor/host/database/user без password/DSN; подтвердите учебную database и backup/checkpoint.
- **Результат:** manual operations направлены только в разрешённую PostgreSQL database.
- **Сценарии:** expected target; missing variable; SQLite fallback; suspicious shared name — остановка.

## Задание 3. Baseline checks

- **Исходные данные:** проект до изменений недели 11.
- **Действие:** запустите system checks, migration plan, `makemigrations --check --dry-run` и tests недели 10.
- **Результат:** command, exit status, duration и summary записаны; старая failure отделена от новой.
- **Сценарии:** pass; unapplied migration; model without migration; failing test.

## Задание 4. Use-case contract

- **Исходные данные:** dealership, supplier catalog item и units.
- **Действие:** опишите inputs, preconditions, result, expected errors и atomicity `procure_inventory`.
- **Результат:** contract отвечает, что будет при equality, inactivity, missing row, недостатке ресурса и повторном ручном запуске.
- **Сценарии:** stock/balance below/equal/above; units 0/negative; inactive/missing entity.

## Задание 5. Матрица компонентов

- **Исходные данные:** admin, command, service, selector, view, tests, logging.
- **Действие:** заполните `component | input | output | may write | may log | forbidden`.
- **Результат:** rule имеет одного owner; boundary не дублирует его.
- **Сценарии:** price-rule change; new HTTP boundary; future Celery wrapper; selector reuse.

## Задание 6. Таблица состояния

- **Исходные данные:** SupplierCatalogItem, DealershipInventory, balances и history/movements.
- **Действие:** заполните before/after для success и четырёх failures.
- **Результат:** stock/balance changes согласованы с history; failure сохраняет initial state.
- **Сценарии:** inventory exists/absent; exact balance; insufficient stock; forced exception.

## Задание 7. Gap audit

- **Исходные данные:** actual code и target tree.
- **Действие:** перечислите missing admin/service/command/selector/view/tests/logging; schema change получает reason/migration plan.
- **Результат:** ordered slices, каждый заканчивается observable check.
- **Сценарии:** no schema change; missing constraint/snapshot; misplaced responsibility.

## Обязательные сценарии дня

1. Accepted source определён.
2. Database безопасно подтверждена.
3. Baseline имеет фактический status.
4. Happy procurement описан.
5. Exact stock/balance описана.
6. Insufficient resource не оставляет partial state.
7. Inventory-absent path имеет concurrency-safe plan.
8. Каждый component имеет одну ответственность.

## Контрольные вопросы

1. Почему сценарий вертикальный?
2. Где заканчивается responsibility command?
3. Зачем state table до implementation?
4. Что делать с красным baseline?

---

# День 2. Django admin для каталога и поставщика

## Документация

- [Django admin site](https://docs.djangoproject.com/en/5.2/ref/contrib/admin/) — регистрация моделей, list display, filters и поиск.

## Паспорт задания

- **Цель:** создать безопасный staff workflow для reference data без transaction logic в admin.
- **Рабочая область:** `catalog/admin.py`, `suppliers/admin.py`, `dealerships/admin.py`, `trading/admin.py`; журнал — `day_02_admin_catalog.md`.
- **Результат:** ModelAdmin с permission checks, read-only history и измеренным list-query behavior.
- **Порядок выполнения:** определите staff tasks; настройте list/search/filter; relation widgets; защитите history; проверьте roles; создайте data; измерьте N+1; запустите checks/tests.
- **Наблюдаемый результат:** authorized staff создаёт catalog/supplier item; invalid data не сохраняются; history видна, но не редактируется.
- **Готово, если:** anonymous/non-staff закрыты; permissions проверены; forms работают; history защищена; admin list без линейного N+1; десять scenarios записаны.
- **Пример:** отрицательная supplier price даёт form error и не появляется в database.
- **Обязательно для зачёта:** задания 1–8 и scenarios 1–10. **Рекомендация:** autocomplete только для растущих relations.

## Теория

Прочитайте разделы 4–7 и 29 `THEORY.md`.

## Задание 1. Staff workflow table

- **Исходные данные:** models catalog/suppliers/dealerships/history.
- **Действие:** заполните `model | list columns | filters | search | editable | readonly | add/delete policy | reason`.
- **Результат:** ModelAdmin options выбраны по задаче.
- **Сценарии:** new reference; active toggle; history view; forbidden mutation.

## Задание 2. Catalog admin

- **Исходные данные:** valid/invalid make, model, specification.
- **Действие:** зарегистрируйте models; настройте list/search/filter/ordering/readonly timestamps без hidden relation query.
- **Результат:** staff находит model по code/name/make и создаёт valid data.
- **Сценарии:** Latin/Unicode search; duplicate; invalid price/year; active filter.

## Задание 3. Supplier admin

- **Исходные данные:** supplier и catalog item.
- **Действие:** настройте relation widget, search fields и list_select_related по необходимости.
- **Результат:** staff создаёт item и видит supplier/car/price/stock без query per row.
- **Сценарии:** no items; valid/duplicate; negative price/stock; inactive supplier; relation search.

## Задание 4. Dealership admin

- **Исходные данные:** dealership и inventory.
- **Действие:** зарегистрируйте profiles/inventory; запретите случайную ручную правку stock/balance вне отдельно описанного correction workflow.
- **Результат:** state видно, но procurement не подменяется ручной правкой.
- **Сценарии:** view/filter; inactive; attempted edit; documented correction if implemented.

## Задание 5. Read-only history

- **Исходные данные:** Purchase/StockMovement/BalanceMovement.
- **Действие:** добавьте search/filter/readonly и запрет ordinary add/change/delete.
- **Результат:** staff расследует операцию без переписывания history.
- **Сценарии:** list/detail; add; change POST; delete; superuser policy.

## Задание 6. Permission matrix

- **Исходные данные:** anonymous, non-staff, staff no permission, narrow staff, superuser.
- **Действие:** проверьте index/list/add/change access и database effect.
- **Результат:** status/redirect/action matrix записана.
- **Сценарии:** все пять roles; direct URL; logout.

## Задание 7. Data через admin

- **Исходные данные:** empty business dataset.
- **Действие:** создайте make, model, supplier, supplier item, dealership; сохраните IDs/codes без secrets.
- **Результат:** data готовы для дня 3 и воспроизводимы.
- **Сценарии:** valid; invalid corrected; duplicate rejected; inactive toggle.

## Задание 8. Admin query audit

- **Исходные данные:** change list N=2/N=20.
- **Действие:** измерьте queries и устраните relation N+1 через ModelAdmin/QuerySet settings.
- **Результат:** count не растёт линейно; SQL roles объяснены.
- **Сценарии:** N=0/2/20; search; filter; list relation.

## Обязательные сценарии дня

1. Anonymous не получает admin content.
2. Non-staff не входит.
3. Staff без permission не создаёт row.
4. Narrow staff создаёт make/model.
5. Staff создаёт supplier/item.
6. Invalid/duplicate item не сохраняется.
7. Stock/balance не правятся случайно.
8. History mutation запрещена.
9. Unicode search/filter работают.
10. Admin list не имеет линейного N+1.

## Контрольные вопросы

1. Почему superuser-only test недостаточен?
2. Чем readonly admin отличается от database immutability?
3. Зачем `list_select_related`?
4. Почему procurement не живёт в `save_model()`?

---

# День 3. Атомарный service закупки и command

## Документация

- [Django: Database transactions](https://docs.djangoproject.com/en/5.2/topics/db/transactions/) — реализация атомарного сервиса закупки.
- [Django: Custom management commands](https://docs.djangoproject.com/en/5.2/howto/custom-management-commands/) — создание команды для запуска бизнес-сценария.

## Паспорт задания

- **Цель:** провести закупку как одну transaction с locks, snapshot и immutable movements.
- **Рабочая область:** `trading/services.py`, `dealerships/management/commands/procure_inventory.py`; журнал — `day_03_procurement_service.md`.
- **Результат:** `procure_inventory` с domain result/errors и тонкая command.
- **Порядок выполнения:** lock order; input checks; atomic; locks; resource checks; history/movements; current updates; command; rollback tests.
- **Наблюдаемый результат:** success создаёт одну закупку и меняет state согласованно; failure оставляет исходное состояние.
- **Готово, если:** rules только в service; locks внутри atomic; absent inventory защищён constraint; Decimal сохранён; errors конкретны; command testable; 12 scenarios записаны.
- **Пример:** command выводит operation/purchase identifiers и units, но не раскрывает balances.
- **Обязательно для зачёта:** задания 1–8 и scenarios 1–12. **Рекомендация:** immutable dataclass result.

## Теория

Прочитайте разделы 8–13 `THEORY.md`.

## Задание 1. Contract and errors

- **Исходные данные:** contract дня 1.
- **Действие:** определите signature, result type и errors для invalid units, missing/inactive entity, insufficient stock/funds.
- **Результат:** caller различает expected failure без разбора текста.
- **Сценарии:** каждый expected error; unexpected error не маскируется.

## Задание 2. Lock order

- **Исходные данные:** dealership, supplier, item, optional inventory.
- **Действие:** задайте порядок `select_for_update()` и объясните protected rows.
- **Результат:** параллельные services не берут те же locks в противоположном порядке.
- **Сценарии:** inventory exists/absent; two dealerships; two items.

## Задание 3. Checks inside transaction

- **Исходные данные:** units, stock, balance, unit price.
- **Действие:** cheap range check до transaction; mutable state проверить после locks.
- **Результат:** equality succeeds; insufficient gives error before writes.
- **Сценарии:** units 0/negative/1; stock/balance below/equal/above; inactive.

## Задание 4. History and movements

- **Исходные данные:** locked rows and Decimal price.
- **Действие:** создайте Purchase snapshot, stock and debit/credit balance movements с общей operation relation.
- **Результат:** history отвечает кто/у кого/что/сколько/почём.
- **Сценарии:** one/several units; cents; equal balance; exact movement counts.

## Задание 5. Current state

- **Исходные данные:** supplier quantity, inventory existing/missing, balances.
- **Действие:** уменьшите supplier stock/dealership balance, увеличьте dealership stock/supplier balance без lost update.
- **Результат:** totals совпадают с history; no negatives.
- **Сценарии:** existing/new inventory; subsequent procurement; exact depletion.

## Задание 6. Forced rollback

- **Исходные данные:** valid setup.
- **Действие:** test-only patch вызывает exception после части writes; сравните всю before/after table.
- **Результат:** Purchase, movements and state rolled back; next valid transaction works.
- **Сценарии:** failure after Purchase/movements; exception preserved; recovery.

Не оставляйте production flag `fail_after_step`: используйте mock/patch подходящей внутренней границы.

## Задание 7. Management command

- **Исходные данные:** CLI IDs and units.
- **Действие:** parser/handle вызывает service один раз; expected error превращает в `CommandError`; output через `self.stdout`/`stderr`.
- **Результат:** readable success и nonzero failure.
- **Сценарии:** valid; missing/invalid arg; units zero; missing entity; insufficient resource.

## Задание 8. Logging boundary

- **Исходные данные:** operation ID, safe IDs, units, outcome.
- **Действие:** start/success/expected-failure logs; success только после atomic completion.
- **Результат:** operation находится по ID; no false success/secret.
- **Сценарии:** success; expected failure; unexpected exception; forbidden-field scan.

## Обязательные сценарии дня

1. Positive units закупаются.
2. Exact supplier stock leaves zero.
3. Exact dealership balance leaves zero.
4. Insufficient stock changes nothing.
5. Insufficient funds changes nothing.
6. Zero/negative units rejected.
7. Inactive/missing entity rejected.
8. Existing inventory increments.
9. Missing inventory created once safely.
10. Purchase/movement counts exact.
11. Forced exception rolls back every write.
12. Command delegates and reports success/failure.

## Контрольные вопросы

1. Почему mutable checks после lock?
2. Где transaction boundary?
3. Зачем snapshots и movements?
4. Чем новая закупка отличается от duplicate retry?

---

# День 4. Selector каталога и устранение N+1

## Документация

- [Django: Database access optimization](https://docs.djangoproject.com/en/5.2/topics/db/optimization/) — устранение N+1 и проверка числа запросов.

## Паспорт задания

- **Цель:** построить переиспользуемый read query с правильным result и постоянным query budget.
- **Рабочая область:** `catalog/selectors.py`; журнал — `day_04_catalog_selector.md`.
- **Результат:** selector, JSON-ready materialization contract, SQL explanation и N+1 measurements.
- **Порядок выполнения:** dataset; output contract; bad query; measurement; eager loading; materialization; N=2/N=20; ordering/visibility.
- **Наблюдаемый результат:** catalog rows корректны, число queries не растёт с числом inventory rows.
- **Готово, если:** active policy ясна; result typed; full serialization измерена; queries объяснены; no hidden access; десять scenarios записаны.
- **Пример:** boundary получает `car_code`, make/model/dealership/country/price/quantity без SQL внутри presentation loop.
- **Обязательно для зачёта:** задания 1–7 и scenarios 1–10. **Рекомендация:** отделить QuerySet construction от primitive conversion, если так яснее measurement.

## Теория

Прочитайте разделы 14–16 и 27 `THEORY.md`.

## Задание 1. Catalog contract

- **Исходные данные:** endpoint fields из `README.md`.
- **Действие:** задайте result shape/types, active policy, ordering, empty behavior и Decimal boundary.
- **Результат:** selector/view используют одну спецификацию.
- **Сценарии:** empty; one; equal prices; inactive parent; zero stock.

## Задание 2. Неоднозначный dataset

- **Исходные данные:** 3 makes, 6 models, 3 dealerships, active/inactive, zero stock, equal prices.
- **Действие:** создайте isolated test data; вручную составьте expected ordered rows.
- **Результат:** expected result независим от implementation.
- **Сценарии:** same model/two dealerships; inactive relation; zero; tie.

## Задание 3. N+1 baseline

- **Исходные данные:** N=2 and N=20 valid rows.
- **Действие:** материализуйте relations без eager loading и измерьте полный loop.
- **Результат:** count растёт с N; repeated SQL shape сохранена.
- **Сценарии:** N=0/2/20; new QuerySet; cached QuerySet не используется как ложное доказательство.

## Задание 4. Optimized selector

- **Исходные данные:** inventory→dealership, inventory→car model→make и specifications, если входят в response.
- **Действие:** `select_related` для single relations; prefetch только для collections.
- **Результат:** те же rows при fixed small count.
- **Сценарии:** without/with collection; no children; filtered prefetch behavior.

## Задание 5. Materialization

- **Исходные данные:** optimized query/result contract.
- **Действие:** превратите весь result в primitive data внутри measurement; price остаётся decimal string.
- **Результат:** returned records больше не выполняют SQL.
- **Сценарии:** zero/one/many; cents; Unicode; optional value.

## Задание 6. Ordering and visibility

- **Исходные данные:** equal prices and inactive variants.
- **Действие:** stable ordering и explicit active/in-stock filters на всех relations.
- **Результат:** order стабилен; invalid public rows исключены.
- **Сценарии:** tie; inactive make/model/dealership/inventory; zero quantity.

## Задание 7. SQL and budget report

- **Исходные данные:** final selector N=2/N=20.
- **Действие:** сохраните SQL/roles/budget; покажите failing budget при removal eager loading.
- **Результат:** budget не растёт и автоматически ловит regression.
- **Сценарии:** base; prefetch; empty; intentional regression.

## Обязательные сценарии дня

1. Empty catalog даёт empty collection.
2. Active in-stock row included.
3. Zero stock excluded.
4. Inactive relation excluded.
5. Same model/two dealerships gives two rows.
6. Equal prices stable.
7. Decimal price formatted at presentation boundary.
8. Bad count grows N=2→N=20.
9. Optimized data equals baseline data.
10. Optimized budget constant.

## Контрольные вопросы

1. Почему measurement охватывает materialization?
2. Когда select и prefetch?
3. Почему budget не обязательно равен одной query?
4. Какие inactive relations проверяются?

---

# День 5. Read-only JSON endpoint

## Документация

- [Django: `JsonResponse`](https://docs.djangoproject.com/en/5.2/ref/request-response/#jsonresponse-objects) — формирование корректного JSON HTTP-ответа.

## Паспорт задания

- **Цель:** открыть optimized catalog через стабильный HTTP-contract без DRF и утечки данных.
- **Рабочая область:** `catalog/views.py`, `catalog/urls.py`, `config/urls.py`; журнал — `day_05_json_endpoint.md`.
- **Результат:** namespaced `GET /api/v1/catalog/` с JSON envelope, method restrictions и HTTP tests.
- **Порядок выполнения:** schema; URL; thin view; selector; primitives; methods/status; empty/Unicode/security/query budget.
- **Наблюдаемый результат:** GET даёт public JSON; POST=405; empty=200 with empty list.
- **Готово, если:** route через reverse; no duplicated query rules; Decimal not float; no sensitive fields; budget measured; десять scenarios.
- **Пример:** `{"count": 0, "results": []}` для пустого каталога.
- **Обязательно для зачёта:** задания 1–7 и scenarios 1–10. **Рекомендация:** cache headers пока не добавлять без cache contract.

## Теория

Прочитайте разделы 17–21 и 28 `THEORY.md`.

## Задание 1. Response schema

- **Исходные данные:** README example и selector contract.
- **Действие:** запишите item/top-level keys, types, order, visibility, empty behavior.
- **Результат:** одна schema в view/tests.
- **Сценарии:** zero/one/many; Unicode; cents; no accidental null.

## Задание 2. Namespaced URL

- **Исходные данные:** root URLconf and catalog app.
- **Действие:** `app_name`, named route/include дают ровно `/api/v1/catalog/`.
- **Результат:** `reverse()` строит path.
- **Сценарии:** slash; reverse; unknown=404; no duplicate segment.

## Задание 3. Thin view

- **Исходные данные:** request and selector.
- **Действие:** разрешите GET, вызовите selector/materializer, верните `JsonResponse` envelope.
- **Результат:** view не пишет в database и не знает procurement.
- **Сценарии:** GET; empty; rows; unsupported method.

## Задание 4. Serialization

- **Исходные данные:** Decimal, country code, IDs, names.
- **Действие:** JSON-safe primitives; price string two places; не использовать `__dict__`.
- **Результат:** parsed types соответствуют schema.
- **Сценарии:** whole/cents; Unicode; large id; no `_state`.

## Задание 5. Data minimization

- **Исходные данные:** supplier cost, balances, timestamps, internal flags.
- **Действие:** allowlist response; проверьте отсутствие forbidden keys/markers.
- **Результат:** только public catalog fields.
- **Сценарии:** cost differs; nonzero balances; inactive; secret marker.

## Задание 6. HTTP behavior

- **Исходные данные:** GET/POST/PUT/PATCH/DELETE and unknown route.
- **Действие:** test client проверяет status/content type/body/Allow where applicable.
- **Результат:** GET=200, unsupported=405, unknown=404, no traceback.
- **Сценарии:** all methods; empty; DEBUG-safe response.

## Задание 7. Endpoint budget

- **Исходные данные:** N=2/N=20.
- **Действие:** измерьте full client request отдельно от selector; объясните extra queries.
- **Результат:** endpoint budget constant by N.
- **Сценарии:** anonymous; small/large/empty; N+1 regression.

## Обязательные сценарии дня

1. Reverse gives exact path.
2. GET nonempty = 200 JSON.
3. Empty = 200/empty.
4. Count equals length.
5. Price two-place string.
6. Ordering exact.
7. Inactive/zero excluded.
8. Sensitive/internal fields absent.
9. Unsupported methods=405.
10. Endpoint budget constant.

## Контрольные вопросы

1. Почему empty list не 404?
2. Зачем envelope?
3. Почему price string?
4. Чем endpoint budget отличается от selector budget?

---

# День 6. Tests, logging и clean replay

## Документация

- [Django: Testing overview](https://docs.djangoproject.com/en/5.2/topics/testing/overview/) — структура и запуск тестов.
- [Django: Logging](https://docs.djangoproject.com/en/5.2/howto/logging/) — настройка и использование журналирования.
- [Django: Migrations](https://docs.djangoproject.com/en/5.2/topics/migrations/) — проверка воспроизводимости схемы с нуля.

## Паспорт задания

- **Цель:** превратить вертикальный путь в regression suite и доказать clean reproduction.
- **Рабочая область:** app tests, logging config/code, `TEST_MATRIX.md`, project README; журнал — `day_06_tests_logging.md`.
- **Результат:** layered tests, safe log assertions, migration hygiene и clean replay report.
- **Порядок выполнения:** matrix; independent fixtures; constraint/service/selector/HTTP/admin tests; logs; migrations; replay; full suite twice.
- **Наблюдаемый результат:** tests стабильны, logs имеют IDs без secrets, fresh DB воспроизводит slice.
- **Готово, если:** happy/error/rollback/query/admin covered; IntegrityError isolated; no seed dependency; migration check clean; replay documented; 12 scenarios.
- **Пример:** `test_procurement_rolls_back_every_change_when_history_write_fails` называет observable rule.
- **Обязательно для зачёта:** задания 1–8 и scenarios 1–12. **Рекомендация:** `setUpTestData()` для неизменяемых references.

## Теория

Прочитайте разделы 22–33 `THEORY.md`.

## Задание 1. Test matrix

- **Исходные данные:** requirements дней 2–5.
- **Действие:** распределите cases по constraint/admin/service/selector/HTTP/log/replay.
- **Результат:** critical invariant имеет positive и negative evidence.
- **Сценарии:** happy; boundary; failure; rollback; performance; permission.

## Задание 2. Test data helpers

- **Исходные данные:** active/inactive entities, balances/quantities.
- **Действие:** helpers/`setUpTestData` без development seed и test order.
- **Результат:** каждый test запускается отдельно.
- **Сценарии:** single/class/all/shuffle; no mutated leak.

## Задание 3. Constraint tests

- **Исходные данные:** unique/nonnegative constraints.
- **Действие:** expected IntegrityError внутри nested atomic; после проверить no invalid row.
- **Результат:** DB protection proven; outer test usable.
- **Сценарии:** duplicate; negative quantity/price/balance; allowed zero.

## Задание 4. Service tests

- **Исходные данные:** procurement contract.
- **Действие:** success table, exact boundaries, errors, create/update inventory, rollback.
- **Результат:** current/history consistent, no partial state.
- **Сценарии:** минимум cases 1–11 дня 3.

## Задание 5. Selector and HTTP tests

- **Исходные данные:** contracts дней 4–5.
- **Действие:** rows/order/visibility/types/budgets; HTTP path/method/status/body.
- **Результат:** correctness and performance failures диагностируются отдельно.
- **Сценарии:** empty/small/large; inactive/tie; POST; forbidden fields.

## Задание 6. Admin tests

- **Исходные данные:** five roles and registered models.
- **Действие:** auth/permissions/valid-invalid create/read-only history.
- **Результат:** staff workflow проверен не только вручную.
- **Сценарии:** anonymous/non-staff/no-permission/narrow staff/superuser; direct URL.

## Задание 7. Log tests

- **Исходные данные:** success/failure, secret markers, request/operation IDs.
- **Действие:** `assertLogs` проверяет event/outcome/safe IDs; scan excludes password/token/cookie/DSN/email/body.
- **Результат:** useful logs, no false success or sensitive leak.
- **Сценарии:** success; expected refusal; exception; rollback; request.

## Задание 8. Clean replay

- **Исходные данные:** fresh isolated DB/project.
- **Действие:** check, makemigrations check, plan/apply, setup, procurement, GET, full tests.
- **Результат:** README имеет safe exact steps and actual outcomes; no manual SQL.
- **Сценарии:** fresh; repeated migrate; suite twice; no tracked secret; existing DB still works.

## Обязательные сценарии дня

1. Every test runs alone.
2. Suite passes twice.
3. Constraint error keeps test usable.
4. Service success checks full state.
5. Rollback checks full state.
6. Selector result/order tested.
7. Budget N=2/N=20 tested.
8. HTTP schema/methods tested.
9. Admin roles tested.
10. Logs have IDs.
11. Logs lack sensitive markers.
12. Clean replay succeeds.

## Контрольные вопросы

1. Как `TestCase` может скрыть placement lock?
2. Зачем nested atomic?
3. Почему не development seed?
4. Что доказывает makemigrations check?

---

# День 7. Итоговый вертикальный срез

## Документация

- [Django Documentation](https://docs.djangoproject.com/en/5.2/) — справочник по ORM, admin, views, тестам и другим слоям итогового среза.

## Паспорт задания

- **Цель:** выполнить сценарий целиком на чистой database и защитить данные, SQL, transaction, HTTP и tests.
- **Рабочий каталог:** весь `day_07_vertical_slice/`; `VERTICAL_SLICE.md`, `TEST_MATRIX.md`, project README; результаты — `ASSESSMENT.md`.
- **Результат:** воспроизводимый admin→procurement→catalog slice с constraints, migrations, logs и regression suite.
- **Порядок выполнения:** сверить contracts; пройти slices; clean setup; admin data; command; JSON; 32 scenarios; secret/query/migration audits; документы; защита.
- **Наблюдаемый результат:** fresh DB проходит путь, tests доказывают failures/rollback/budget без ручной schema правки.
- **Готово, если:** дни 1–6 зачтены; code соответствует flow; 32 scenarios честны; no critical issue; docs reproducible; защита готова.
- **Пример:** закупка двух единиц меняет оба stock/balance, создаёт history, а GET показывает новую позицию.
- **Обязательно для зачёта:** все срезы, 32 scenarios, audit и защита. **Рекомендация:** clean commit после принятия.

## Теория

Повторите разделы 1–3 и 8–34 `THEORY.md`.

## Обязательное дерево и обязанности

```text
day_07_vertical_slice/
├── manage.py                         # command entry point
├── README.md                         # clean setup and checks
├── config/
│   ├── settings.py                  # safe logging
│   └── urls.py                      # root API include
├── catalog/
│   ├── admin.py                     # staff catalog UI
│   ├── selectors.py                 # optimized read model
│   ├── urls.py                      # namespace/route
│   ├── views.py                     # thin JSON boundary
│   └── tests/                       # or tests.py
├── suppliers/
│   ├── admin.py                     # supplier staff UI
│   └── tests/
├── dealerships/
│   ├── admin.py                     # inventory observation
│   └── management/commands/
│       └── procure_inventory.py     # thin CLI boundary
├── trading/
│   ├── admin.py                     # read-only history
│   ├── services.py                  # transaction owner
│   └── tests/
├── migrations/inside_apps           # versioned changes only
├── VERTICAL_SLICE.md                # flow/locks/state
└── TEST_MATRIX.md                    # requirements/evidence
```

## Вертикальные срезы сборки

### Срез 1. Staff creates supply data

- **Исходные данные:** narrow staff and valid make/model/supplier/item.
- **Действие:** создать через admin и отклонить invalid/duplicate.
- **Результат:** item готов, permissions/constraints работают.
- **Сценарии:** success; no permission; duplicate; invalid money/stock; Unicode search.

### Срез 2. Dealership procures inventory

- **Исходные данные:** dealership/item IDs and units.
- **Действие:** command→service→history/movements/current state.
- **Результат:** balanced state; failure unchanged.
- **Сценарии:** inventory exists/missing; exact/insufficient; rollback; new legitimate operation.

### Срез 3. Catalog read model

- **Исходные данные:** active/inactive, positive/zero stock graph.
- **Действие:** selector builds sorted public rows with eager loading.
- **Результат:** correct list and constant budget.
- **Сценарии:** empty; N small/large; ties; inactive; regression.

### Срез 4. HTTP boundary

- **Исходные данные:** GET and unsupported requests.
- **Действие:** named route/view returns envelope.
- **Результат:** stable safe schema/status/types.
- **Сценарии:** empty/nonempty; 405; 404; Decimal/Unicode; no sensitive keys.

### Срез 5. Evidence and recovery

- **Исходные данные:** fresh DB, runner, logs.
- **Действие:** replay, scenario, suite, audit.
- **Результат:** другой разработчик воспроизводит и диагностирует путь.
- **Сценарии:** clean; isolation; safe logs; no missing migrations; rollback evidence.

## `VERTICAL_SLICE.md`

Документ содержит:

```text
Goal and non-goals
Actors and permissions
Inputs and outputs
Happy path
Expected failures
Component responsibility table
Transaction boundary
Lock order and protected rows
Before/after state table
History/movement mapping
Selector relation graph
HTTP response schema
Logging events and forbidden fields
Known limitations and week-12 handoff
```

## `TEST_MATRIX.md`

Каждая строка:

```text
ID | Requirement | Level | Setup | Action | Expected | Actual | Status | Test/file
```

`Actual` и `Status` заполняются только после запуска. Status: `passed`, `failed`, `blocked`, `not run`.

## Финальные 32 сценария

### Позитивные

1. Fresh DB applies migrations.
2. No missing model migration.
3. Authorized staff creates make/model.
4. Authorized staff creates supplier/item.
5. Procurement creates one Purchase.
6. Procurement creates exact movements.
7. Existing inventory increments.
8. Missing inventory created once.
9. Supplier stock/dealership balance decrease correctly.
10. Dealership stock/supplier balance increase correctly.
11. Selector includes new active in-stock row.
12. Catalog GET returns 200/envelope.
13. Price is two-place string.
14. Unicode survives admin→DB→JSON.

### Граничные

15. Exact supplier stock leaves zero.
16. Exact dealership balance leaves zero.
17. Empty catalog returns 200/count 0/empty list.
18. Same model in two dealerships yields two rows.
19. Equal prices use stable tie-breaker.
20. Inactive make/model/dealership/inventory excluded.
21. Zero-stock excluded.
22. Selector budget constant N=2/N=20.
23. Endpoint budget constant N=2/N=20.
24. Repeated migrate and test suite succeed.

### Ошибочные, security и rollback

25. Anonymous/non-staff cannot use admin workflow.
26. Staff without permission cannot add model.
27. Duplicate/negative constrained data not stored.
28. Units zero/negative create no operation.
29. Insufficient supplier stock leaves no partial state.
30. Insufficient dealership funds leaves no partial state.
31. Forced exception rolls back every write and emits no success.
32. POST catalog=405; response/log scan finds no forbidden data.

## Ограничения

- No DRF/JWT/Celery/broker/Redis.
- No pagination/filter backend/OpenAPI/frontend.
- No new pytest/Faker/Debug Toolbar requirement.
- No signals instead of service.
- No duplicated business logic.
- No generic repository without demonstrated need.
- No raw SQL for the simple catalog contract.

## Финальный чек-лист

- [ ] Дни 1–6 зачтены.
- [ ] Source commit/database target записаны.
- [ ] Checks and migrations clean.
- [ ] Admin role matrix and reference workflow pass.
- [ ] History admin read-only.
- [ ] Command thin; service atomic; lock order explained.
- [ ] Success/history balanced; failures rollback everything.
- [ ] Selector result correct on ambiguous data.
- [ ] Selector/endpoint budgets measured N=2/N=20.
- [ ] GET/405/empty/Decimal/Unicode contracts pass.
- [ ] Logs have IDs and no forbidden data.
- [ ] Suite passes twice independently.
- [ ] All 32 scenarios have honest status.
- [ ] `VERTICAL_SLICE.md` and `TEST_MATRIX.md` match code.
- [ ] No secrets/local DB artifacts tracked.
- [ ] Self-assessment complete.

## Вопросы защиты

1. Проведите happy path admin→JSON.
2. Кто владеет procurement rules?
3. Что делает command?
4. Какие rows блокируются и в каком порядке?
5. Почему mutable checks внутри transaction?
6. Как inventory создаётся без duplicate race?
7. Current state vs history?
8. Зачем snapshot price?
9. Как movements подтверждают изменения?
10. Что откатывается при exception?
11. Где позже нужен `on_commit`?
12. Почему не signal?
13. Какие admin roles проверены?
14. Почему history read-only?
15. Как admin N+1 измерен?
16. Какой shape selector?
17. Где materialization?
18. Counts bad N+1 N=2/N=20?
19. Constant optimized budget?
20. Почему budget может быть больше 1?
21. Какие active relations фильтруются?
22. Почему empty catalog=200?
23. Почему price string?
24. Какие поля не попали в response?
25. Selector test vs endpoint test?
26. TestCase vs TransactionTestCase?
27. Зачем nested atomic?
28. Почему tests не используют dev seed?
29. Какие safe IDs в logs?
30. Что запрещено в logs?
31. Что доказывает clean replay?
32. Что расширит DRF на неделе 12?

## Передача на проверку

После checklist напишите: `Проверь итоговый проект недели 11`. Наставник проверит code, migrations, tests, HTTP, query counts, logs и понимание, но не исправляет student code во время review.
