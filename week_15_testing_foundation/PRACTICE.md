# Практика недели 15: фундамент тестирования

Статус: **заблокирована до полного зачёта недели 14**.

## Общие правила

- Все дни развивают один проект в `day_07_test_suite/`.
- Переносится только принятый проект недели 14; source commit фиксируется до изменений.
- Код и tests пишет ученик. Наставник не переписывает решение при обычной проверке.
- До нового test записываются риск, level, prediction и независимый oracle.
- Test без meaningful assertion не засчитывается.
- Negative test проверяет status/exception и состояние/side effects после отказа.
- Unit test не получает database/network/settings без необходимости.
- Integration test не mock-ает PostgreSQL/ORM behavior, которое должен доказать.
- Critical API test проходит настоящий router/serializer/authentication/permission path.
- `force_authenticate()` используется только там, где явно исключён full authentication risk.
- Fixtures имеют минимальный scope; mutable domain rows по умолчанию function-scoped.
- Factories deterministic и не выдают скрытые privileges/side effects.
- Markers зарегистрированы; unknown markers являются ошибкой.
- Skip/xfail имеют точную причину и не скрывают обязательное падение.
- Mocks применяются только к понятной границе и patch target объясняется.
- Test database/cache/email/filesystem изолированы; real services не вызываются.
- Coverage анализирует critical ветви; процент не является самостоятельной целью.
- В evidence нет passwords, JWT, action tokens, DSN и private data.

## Формат тестового сценария

```text
Scenario ID and test node ID:
Risk/requirement:
Level: unit | integration | API | smoke | regression
Given/Arrange:
When/Act:
Then/Assert:
Independent oracle:
Prediction before run:
Actual result and duration:
Database/side effects:
Why this level and doubles were chosen:
Failure mutation tried:
Correction/next check:
```

## Самооценка дня

1. Какой риск доказывает test?
2. Почему выбран этот уровень?
3. Откуда взялся expected result?
4. Какие dependencies реальны, а какие заменены?
5. Как test становится красным при нарушении правила?
6. Есть ли hidden setup или shared mutable state?
7. Что осталось непонятным?
8. Сколько времени заняла работа?

## Шкала обычного дня

| Критерий | Баллы |
|---|---:|
| Корректность тестов и выводов | 0–3 |
| Выполнение условий | 0–2 |
| Граничные/negative и failure-mutation scenarios | 0–2 |
| Читаемость и test boundaries | 0–1 |
| Понимание и самооценка | 0–1 |
| Самостоятельность исправлений | 0–1 |

Обычный день принят при 7/10 без критической ошибки. Итоговый suite принят при 8/10.

---

# День 1. Стратегия тестирования, inventory и подключение pytest

## Документация

- [pytest: Good Integration Practices](https://docs.pytest.org/en/stable/explanation/goodpractices.html) — структура проекта, discovery и безопасная интеграция pytest.
- [Django: Writing and running tests](https://docs.djangoproject.com/en/5.2/topics/testing/overview/) — test database и базовый цикл Django tests.

## Паспорт задания

- **Цель:** построить risk-based test strategy, безопасно подключить pytest stack и доказать, что старые tests не потерялись.
- **Рабочий файл или каталог:** config/dependency/tests в `day_07_test_suite/`; документы — `TEST_STRATEGY.md`, `TEST_INVENTORY.md`; журнал — `day_01_test_strategy.md`.
- **Результат:** source/version/baseline audit, compatibility decision для pytest/pytest-django/coverage, единый config, collection comparison и карта critical behaviors по уровням.
- **Порядок выполнения:** подтвердить допуск; перенести project; проверить database; записать старые commands/counts; собрать behavior inventory; выбрать levels; проверить версии; установить dev dependencies; создать config/markers; выполнить collection и smoke; намеренно сломать один учебный assertion.
- **Наблюдаемый результат:** pytest собирает старые и новые tests; test DB точно не production; один node ID проходит, намеренно неверный assertion даёт понятный failure; inventory показывает, чего не хватает.
- **Готово, если:** source/database безопасны; old baseline зафиксирован; compatibility имеет evidence; один config; collection не потеряла tests; markers зарегистрированы; test strategy связывает risks с levels; 10 сценариев записаны.
- **Пример:** `balance cannot become negative -> PostgreSQL integration`, а не «покрыть balances тестами».
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–10. **Рекомендация:** добавить короткую схему test pyramid без процентов.

## Теория

Прочитайте разделы 1–16 и 21–24 `THEORY.md`.

## Задание 1. Активация и перенос

- **Исходные данные:** явный допуск недели 14, accepted branch/commit, dependency files и working tree.
- **Действие:** перенесите project в `day_07_test_suite/`; запишите source; исключите `.env`, databases, coverage artifacts, caches, tokens и reports с secrets.
- **Результат:** week 14 неизменна, source нового suite воспроизводим.
- **Проверить:** accepted/dirty source; missing approval; secret-like files; duplicate copied cache; повторный перенос.

## Задание 2. Safe database baseline

- **Исходные данные:** settings/test settings, actual database vendor/name purpose и старые test commands.
- **Действие:** подтвердите isolated PostgreSQL; зафиксируйте Django checks, migrations, old test count/pass/fail/skip/duration и OpenAPI validation.
- **Результат:** известен baseline до изменения runner.
- **Проверить:** normal test DB; accidental SQLite; shared/dev/prod-like DB — остановка; stale migration; pre-existing failure.

## Задание 3. Behavior inventory

- **Исходные данные:** requirements и tests недель 10–14: auth, authorization, Offer, balances, stock, promotions, statistics, queries и schema.
- **Действие:** в `TEST_INVENTORY.md` заполните `behavior/risk | current test/node | level | positive | boundary | negative | gap | priority`.
- **Результат:** каждый critical invariant имеет текущий proof или явный gap.
- **Проверить:** happy path only; no negative; assertionless smoke; duplicate tests; critical untested branch.

## Задание 4. Выбор test levels

- **Исходные данные:** inventory gaps.
- **Действие:** для каждого gap выберите cheapest sufficient level и объясните, почему mock/unit/API не подходит лучше/хуже.
- **Результат:** формулы уходят в unit, constraints/transactions в DB integration, HTTP contract в API.
- **Проверить:** pure policy; database constraint; JWT header; query count; email rendering; full flow.

## Задание 5. Compatibility gate

- **Исходные данные:** фактические Python/Django versions и official pytest/pytest-django/coverage docs/changelogs.
- **Действие:** заполните `package | installed | candidate | Python/Django/pytest support | config change | risk | decision`; только после допуска установите exact dev versions.
- **Результат:** clean resolver/import/version output и recorded decision.
- **Проверить:** incompatible pytest major; plugin mismatch; runtime group pollution; clean install; lock update.

## Задание 6. Единый pytest config

- **Исходные данные:** существующие configs/settings и выбранная pytest major.
- **Действие:** настройте один `pyproject.toml` или `pytest.ini`: Django settings, testpaths/patterns, strict config/markers, registered markers и concise output.
- **Результат:** одинаковая команда работает из project root и IDE/terminal при том же environment.
- **Проверить:** duplicate config; typo marker; wrong settings; missing project root; collection warning.

## Задание 7. Collection и unittest compatibility

- **Исходные данные:** old Django `TestCase`/`unittest` tests и новые empty/one pytest test.
- **Действие:** выполните collection-only; сравните старый и новый count/node list; запустите минимум один legacy и один pytest-style test.
- **Результат:** migration runner не делает старые tests невидимыми.
- **Проверить:** same test twice; missing directory; class naming; import error; old suite pass.

## Задание 8. First red/green assertion

- **Исходные данные:** простая чистая accepted function/policy.
- **Действие:** напишите test с independent expected value; сначала временно поставьте неверное ожидание и сохраните failure summary, затем исправьте только expected/production defect по факту.
- **Результат:** test демонстрирует полезную pytest assertion introspection и green node ID.
- **Проверить:** test red; readable failure; correct green; test without DB; no secret output.

## Обязательные сценарии дня

1. Old suite baseline записан до pytest migration.
2. Test database подтверждена как isolated PostgreSQL.
3. Compatibility decision имеет official evidence.
4. Clean install/import pytest stack работает.
5. Collection не теряет legacy tests.
6. Один legacy unittest/Django test запускается pytest.
7. Один pytest-style unit test запускается по node ID.
8. Unknown marker вызывает controlled configuration failure.
9. Намеренно неверный assertion даёт понятный red result.
10. Critical behavior inventory содержит positive/boundary/negative gaps.

## Контрольные вопросы

1. Чем unit отличается от integration?
2. Почему smoke не является отдельным уровнем?
3. Что такое test oracle?
4. Зачем сравнивать collection до и после?
5. Почему test database нужно подтвердить до запуска?
6. Почему успешной установки plugin недостаточно?

---

# День 2. Pytest assertions, exceptions, discovery и migration tests

## Документация

- [pytest: assertions](https://docs.pytest.org/en/stable/how-to/assert.html) — обычный `assert`, `pytest.raises()` и диагностика падений.
- [pytest: unittest support](https://docs.pytest.org/en/stable/how-to/unittest.html) — совместный запуск pytest-style и существующих unittest tests.

## Паспорт задания

- **Цель:** научиться писать маленькие читаемые pytest-тесты и постепенно переносить подходящие legacy tests без изменения behavior.
- **Рабочий файл или каталог:** `tests/unit/` и выбранный legacy test module в `day_07_test_suite/`; журнал — `day_02_pytest_basics.md`.
- **Результат:** unit tests с AAA, независимыми oracles, точными exceptions, понятными node IDs и comparison legacy-before/after.
- **Порядок выполнения:** выбрать pure functions/policies; сформулировать behaviors; написать positive/boundary/negative tests; проверить exceptions; улучшить names/assertions; мигрировать один небольшой legacy class; запустить отдельно/файлом/marker; mutation-check guards.
- **Наблюдаемый результат:** failure сообщает конкретный behavior/case; удаление ключевой строки production или замена expected ломает нужный test; suite не обращается к database.
- **Готово, если:** AAA видим; один основной Act; exceptions точны; expected независим; no DB unit marker; legacy migration не меняет contract; 12 сценариев записаны.
- **Пример:** `test_expired_promotion_returns_base_price`, expected `100.00` задан вручную, а не вычислен production formula.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–12. **Рекомендация:** комментарии AAA оставлять только там, где блоки не очевидны по коду.

## Теория

Прочитайте разделы 9–21 и 50 `THEORY.md`.

## Задание 1. Выбор pure behaviors

- **Исходные данные:** price/promotion calculations, Offer state policy и authorization predicates.
- **Действие:** выберите минимум три behaviors без ORM; запишите входы, expected и причину уровня unit.
- **Результат:** каждый test может выполняться без `django_db`.
- **Проверить:** positive; exact boundary; invalid/deny; accidental ORM access.

## Задание 2. AAA и имена

- **Исходные данные:** выбранные behaviors.
- **Действие:** создайте отдельные `test_<expected>_when_<condition>` tests с одним Act; уберите непонятные `test_1` и общие names.
- **Результат:** node ID сам описывает failure.
- **Проверить:** long name remains precise; no multiple unrelated Acts; minimal Arrange; assertions after Act.

## Задание 3. Независимые oracles

- **Исходные данные:** цены `100.00`, проценты `0/10/100`, known state decisions.
- **Действие:** задайте expected вручную/из matrix; не вызывайте вторую production function с той же формулой.
- **Результат:** wrong production formula/state branch обнаруживается.
- **Проверить:** no discount; 10%; exact start/end; invalid percentage if contract; ownership allow/deny.

## Задание 4. Assertions результата и структуры

- **Исходные данные:** Decimal, Enum/state decision, dictionaries/value objects.
- **Действие:** используйте несколько простых assertions только для meaningful contract; не сравнивайте огромный object dump без причины.
- **Результат:** failure показывает точное несовпадение.
- **Проверить:** value; type only if contract; no forbidden keys; original input not mutated; deterministic order where required.

## Задание 5. Exceptions

- **Исходные данные:** invalid percentage/state/price cases с конкретными domain exceptions.
- **Действие:** используйте `pytest.raises(SpecificError)`; проверяйте code/message только если contract; временно замените production exception и убедитесь, что test падает.
- **Результат:** unexpected `TypeError`/generic error не считается success.
- **Проверить:** exact type/subclass decision; no exception; wrong exception; message/code; state unchanged.

## Задание 6. Legacy test migration

- **Исходные данные:** один небольшой `unittest.TestCase`/Django SimpleTestCase без сложной DB fixture.
- **Действие:** сначала сохраните green node; перепишите в pytest-style только если это делает test яснее; сравните assertions и behavior.
- **Результат:** исходный proof не потерян; новый test показывает то же требование.
- **Проверить:** before/after node; failure mutation; setup preserved; no duplicate active test unless intentional.

## Задание 7. Запуски и failure reading

- **Исходные данные:** один node, file и unit marker.
- **Действие:** выполните три уровня запуска; для двух намеренных failures запишите left/right values, location и cause.
- **Результат:** ученик умеет читать traceback от первой полезной project frame.
- **Проверить:** assertion failure; setup/import error; unexpected exception; quiet vs verbose IDs.

## Задание 8. Unit mutation check

- **Исходные данные:** ключевые conditions чистых functions.
- **Действие:** временно удалите/инвертируйте по одному guard, запустите узкий test, восстановите production code и подтвердите green.
- **Результат:** positive, boundary и negative tests действительно чувствительны к defect.
- **Проверить:** discount boundary; Offer terminal state; wrong owner; no residual change.

## Обязательные сценарии дня

1. Base price без promotion.
2. Active promotion с вручную проверенной ценой.
3. Exact time boundary по принятому contract.
4. Invalid discount/price вызывает specific exception.
5. Pending own Offer policy разрешает действие.
6. Terminal Offer policy запрещает действие.
7. Foreign owner policy запрещает действие.
8. Input object/collection не мутирует неожиданно.
9. Unit tests не получают database access.
10. Legacy test работает до migration.
11. Migrated test доказывает то же behavior.
12. Инверсия critical guard делает test красным.

## Контрольные вопросы

1. Почему один Act помогает диагностике?
2. Что делает expected независимым?
3. Почему `pytest.raises(Exception)` опасен?
4. Когда проверять exception message?
5. Что доказывает mutation check?
6. Нужно ли переписывать все unittest tests сразу?

---

# День 3. Fixtures, scopes, database isolation и cleanup

## Документация

- [pytest: fixtures](https://docs.pytest.org/en/stable/how-to/fixtures.html) — зависимости tests, scopes и teardown.
- [pytest-django: database access](https://pytest-django.readthedocs.io/en/latest/database.html) — `django_db`, `db`, `transactional_db` и test database.

## Паспорт задания

- **Цель:** построить понятный fixture graph и доказать изоляцию Django/PostgreSQL tests.
- **Рабочий файл или каталог:** `tests/conftest.py`, domain conftest/factories и `FIXTURE_MAP.md` в `day_07_test_suite/`; журнал — `day_03_fixtures_database.md`.
- **Результат:** function-scoped domain fixtures, явный DB access, безопасный teardown для settings/cache/mail/temp files и tests независимости от порядка.
- **Порядок выполнения:** проаудировать setup duplication; нарисовать fixture graph; создать low-level factories; добавить domain fixtures; выбрать scopes; проверить DB markers; реализовать yield cleanup; проверить isolation/order; сравнить `django_db`/transactional needs.
- **Наблюдаемый результат:** test объявляет dependencies параметрами; unit случайно обратившийся к ORM падает; два tests не делят mutable Offer; cleanup выполняется после failure.
- **Готово, если:** fixture graph объясним; root conftest минимален; mutable rows function-scoped; DB access явный; no production target; teardown доказан; order independence есть; 12 сценариев записаны.
- **Пример:** `buyer` зависит от `db` и factory, а `buyer_offer` явно зависит от `buyer`; никакой autouse-superuser не появляется.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–12. **Рекомендация:** fixtures называют роль/state, если это главное условие теста.

## Теория

Прочитайте разделы 13–14 и 23–34 `THEORY.md`.

## Задание 1. Setup duplication audit

- **Исходные данные:** tests недель 11–14 и повторяющиеся user/profile/car/organization creation blocks.
- **Действие:** отметьте повторение, semantic importance и кандидата factory/fixture; не переносите assertion/Act в fixture.
- **Результат:** известны общие primitives и scenario-specific values.
- **Проверить:** repeated user; hidden admin; email side effect; model save signal; overly large setup.

## Задание 2. Fixture map

- **Исходные данные:** db, settings, API client, users/profiles/organizations/resources.
- **Действие:** заполните `fixture | owner file | scope | dependencies | creates/mutates | teardown | consumers`.
- **Результат:** cycles/deep chains/shared mutable state обнаружены до реализации.
- **Проверить:** function/module/session; autouse; database fixture; external resource; duplicate name shadowing.

## Задание 3. Factories vs fixtures

- **Исходные данные:** low-level creation helpers и reusable named scenario state.
- **Действие:** factory принимает overrides и создаёт объект; fixture вызывает factory для часто используемого scenario. Important value задаётся в test/fixture явно.
- **Результат:** tests могут создавать two buyers/two organizations без copy-paste.
- **Проверить:** override role/status/email; uniqueness; no hidden superuser; no unexpected mail; deterministic values.

## Задание 4. Explicit database access

- **Исходные данные:** pure unit test, ORM integration test и API test.
- **Действие:** unit оставьте без DB; ORM/API tests пометьте/обеспечьте `db`; покажите controlled failure при accidental ORM access из unit.
- **Результат:** marker/fixture отражает фактический level.
- **Проверить:** no DB; `django_db`; indirect fixture requiring DB; missing mark; session fixture conflict.

## Задание 5. Scope experiment

- **Исходные данные:** function-scoped Offer и безопасный immutable config-like fixture.
- **Действие:** зафиксируйте IDs/state в двух tests; продемонстрируйте, почему mutable Offer нельзя расширять до module/session; выберите минимальный scope.
- **Результат:** второй test получает clean state независимо от первого.
- **Проверить:** mutate status; delete row; order reversed; repeated run; broad scope failure evidence.

## Задание 6. Yield cleanup

- **Исходные данные:** overridden settings/environment, temp path, cache/mail outbox или fake adapter.
- **Действие:** создайте fixture с yield/context helper и cleanup; вызовите intentional failure inside consumer и проверьте cleanup отдельным test/check.
- **Результат:** environment/cache/file state не остаётся после failed test.
- **Проверить:** normal pass; assertion failure; setup failure handling; teardown error visibility; temp artifact removed.

## Задание 7. `conftest.py` boundaries

- **Исходные данные:** root и domain fixtures.
- **Действие:** оставьте root только действительно общие safe fixtures; domain data перенесите ближе; исключите duplicate names/imports и privilege autouse.
- **Результат:** по дереву понятно, откуда test получает fixture.
- **Проверить:** fixture visibility; name collision; test outside subtree; IDE/CLI collection; root magic.

## Задание 8. Order/isolation suite

- **Исходные данные:** минимум четыре tests, меняющие user/Offer/cache/settings.
- **Действие:** запустите отдельно, вместе, повторно и в изменённом порядке доступным способом; сравните состояние.
- **Результат:** results одинаковы; shared failure исправлен через setup/teardown, не sleep/retry.
- **Проверить:** A then B; B then A; repeat; failed test between; cache/mail reset.

## Обязательные сценарии дня

1. Pure unit test не может случайно обратиться к DB.
2. ORM test с явным DB access проходит.
3. Indirect DB fixture имеет понятную зависимость.
4. Buyer factory принимает role/email override.
5. Offer factory принимает owner/status override.
6. Factory не создаёт superuser/письмо скрыто.
7. Два tests получают независимые mutable Offers.
8. Reversed order не меняет результат.
9. Settings/environment возвращаются после pass.
10. Cleanup выполняется после assertion failure.
11. Cache/mail outbox изолированы.
12. Test database остаётся isolated PostgreSQL.

## Контрольные вопросы

1. Чем fixture отличается от factory?
2. Почему function scope — default?
3. Чем опасен autouse-superuser?
4. Что делает yield fixture?
5. Почему unit должен падать при accidental ORM access?
6. Как обнаружить order dependency?

---

# День 4. Parametrization, factories, markers, skip и xfail

## Документация

- [pytest: parametrization](https://docs.pytest.org/en/stable/how-to/parametrize.html) — таблицы cases и parameter IDs.
- [pytest: markers](https://docs.pytest.org/en/stable/how-to/mark.html) — регистрация и выбор test groups.
- [pytest: skip and xfail](https://docs.pytest.org/en/stable/how-to/skipping.html) — условия пропуска и ожидаемого падения.

## Паспорт задания

- **Цель:** сократить честное повторение тестов, сохранив читаемые business cases и управляемые наборы запуска.
- **Рабочий файл или каталог:** tests/factories, pytest config и `TEST_INVENTORY.md` в `day_07_test_suite/`; журнал — `day_04_parametrize_factories.md`.
- **Результат:** deterministic builders, parametric boundary tables с IDs, зарегистрированные markers и обоснованный skip/xfail audit.
- **Порядок выполнения:** улучшить factories; выбрать повторяющийся behavior; составить case table; добавить readable IDs; зарегистрировать markers; проверить selection; создать один учебный conditional skip/strict xfail; убрать злоупотребления; mutation-check table.
- **Наблюдаемый результат:** failure report называет конкретную бизнес-границу; `-m` выбирает ожидаемые node IDs; typo marker падает; XPASS strict заметен.
- **Готово, если:** business values explicit; factories deterministic; parametrize не объединяет разные Acts; IDs понятны; markers strict; skip/xfail имеют reasons; required failure не скрыт; 12 сценариев записаны.
- **Пример:** cases `before-start`, `at-start`, `at-end`, `after-end`, а не `case-1`…`case-4`.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–12. **Рекомендация:** держать boundary table рядом с test, если она не используется повторно.

## Теория

Прочитайте разделы 33–38 и 50 `THEORY.md`.

## Задание 1. Deterministic factory defaults

- **Исходные данные:** user/profile/car/Offer/promotion factories дня 3.
- **Действие:** сделайте defaults валидными, простыми и воспроизводимыми; значения, влияющие на assertion, переопределяйте в scenario.
- **Результат:** повторный run создаёт семантически тот же case без random flake.
- **Проверить:** unique email; Decimal; aware datetime; role/status; relations; no side effects.

## Задание 2. Promotion boundaries parametrization

- **Исходные данные:** fixed `now`, promotion start/end и contract включительности границ.
- **Действие:** создайте table before/start/inside/end/after с вручную проверенными expected price/active values и IDs.
- **Результат:** одна форма test покрывает пять временных случаев.
- **Проверить:** exact start; exact end; one unit before/after; inactive flag; timezone-aware.

## Задание 3. Authorization decision table

- **Исходные данные:** roles, ownership и Offer states недели 14.
- **Действие:** parametrization примените только к pure policy cases с одинаковым Act/Assert; отдельный API flow не втискивайте в таблицу.
- **Результат:** каждый deny/allow case виден по ID.
- **Проверить:** own pending; foreign pending; terminal; wrong role; inactive/unverified; admin contract.

## Задание 4. Validation/error cases

- **Исходные данные:** invalid prices/quantities/statuses/input shapes.
- **Действие:** параметризуйте expected exception/error code там, где pipeline одинаков; exact database constraint оставьте integration test.
- **Результат:** таблица не смешивает pure validation и DB transaction.
- **Проверить:** zero boundary; negative; missing; wrong type; max boundary; unknown enum.

## Задание 5. Marker registration

- **Исходные данные:** unit/integration/api/smoke/slow classification.
- **Действие:** зарегистрируйте markers с описаниями; включите strict marker behavior; промаркируйте tests на подходящем уровне.
- **Результат:** `pytest -m unit`, `-m api`, `-m smoke` собирают ожидаемые nodes.
- **Проверить:** combined expression; no marker; wrong spelling; legacy tests; collection count.

## Задание 6. Selection report

- **Исходные данные:** full collection.
- **Действие:** запишите для каждого marker selected/deselected counts и representative node IDs; убедитесь, что smoke не пуст.
- **Результат:** documented commands не создают ложный green run с zero tests.
- **Проверить:** unit; integration; api; smoke; not slow; nonexistent marker expression.

## Задание 7. Skip/xfail laboratory

- **Исходные данные:** безопасное недоступное условие и демонстрационный known defect/non-required scenario.
- **Действие:** добавьте узкий conditional skip с reason и `xfail(strict=True)`; затем смоделируйте XPASS и объясните результат. Не оставляйте фиктивный xfail после упражнения без реальной причины.
- **Результат:** различия skip/XFAIL/XPASS понятны, обязательные tests green/fail normally.
- **Проверить:** condition true/false; strict XPASS; expired reason/issue; broad decorator; removed demo marker.

## Задание 8. Parametric mutation check

- **Исходные данные:** boundary conditions таблиц.
- **Действие:** временно поменяйте `<` на `<=` или удалите role/state guard; убедитесь, что конкретный named case падает; восстановите код.
- **Результат:** case IDs локализуют off-by-one/permission defect.
- **Проверить:** at-start/end; negative value; foreign owner; no residual mutation.

## Обязательные сценарии дня

1. Promotion before start.
2. Promotion exactly at start.
3. Promotion exactly at end по contract.
4. Promotion after end.
5. Inactive promotion внутри времени.
6. Own/foreign Offer policy cases имеют readable IDs.
7. Invalid price/quantity table использует точные expected outcomes.
8. Unit marker выбирает только intended unit nodes.
9. API/smoke selection не пуст и count записан.
10. Typo marker вызывает error.
11. Conditional skip имеет точную reason/condition.
12. Strict xfail показывает unexpected pass и не скрывает обязательный defect.

## Контрольные вопросы

1. Когда parametrize ухудшает test?
2. Почему case IDs важны?
3. Какие values нельзя прятать в factory defaults?
4. Зачем strict markers?
5. Чем XFAIL отличается от XPASS?
6. Почему skip не является исправлением failure?

---

# День 5. Unit-тесты бизнес-правил и mock только на границах

## Документация

- [Python: `unittest.mock`](https://docs.python.org/3/library/unittest.mock.html) — Mock, patch, spec и autospec.
- [pytest: monkeypatch](https://docs.pytest.org/en/stable/how-to/monkeypatch.html) — безопасная временная замена attributes, environment и функций.

## Паспорт задания

- **Цель:** покрыть критические чистые правила быстрыми unit tests и научиться заменять только реальные внешние границы.
- **Рабочий файл или каталог:** `tests/unit/`, domain builders и `MOCK_AUDIT.md` в `day_07_test_suite/`; журнал — `day_05_unit_mocking.md`.
- **Результат:** unit tests prices/supplier choice/policies/state transitions, mock audit и проверенные patch targets для внешнего email/clock/token/HTTP adapter.
- **Порядок выполнения:** выбрать critical pure rules; создать behavior tables; отделить dependencies; написать unit tests; составить mock inventory; выбрать один внешний adapter; patch where looked up со spec; проверить calls/не-вызовы; удалить over-mocking.
- **Наблюдаемый результат:** unit suite не требует DB и выполняется быстро; внешний side effect не происходит; wrong patch target или interface change делает test красным.
- **Готово, если:** oracles независимы; positive/boundary/negative есть; DB не используется; mock boundary обоснована; patch target объяснён; spec/autospec применён уместно; no-call проверен для deny; 12 сценариев записаны.
- **Пример:** verification service unit test подменяет `send_verification_email` в module-потребителе, но отдельный integration test locmem backend остаётся реальным.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–12. **Рекомендация:** fake предпочитать длинной цепочке настроек mock, если простой fake лучше выражает protocol.

## Теория

Прочитайте разделы 3, 8–13 и 39–43 `THEORY.md`.

## Задание 1. Critical pure-rule inventory

- **Исходные данные:** price/discount/supplier selection, Offer transitions и authorization policies.
- **Действие:** выберите не менее четырёх rules; для каждого укажите contract, boundaries, oracle и forbidden dependencies.
- **Результат:** unit scope отделён от ORM/API concerns.
- **Проверить:** money Decimal; tie-break; inactive/expired promotion; terminal state; own/foreign.

## Задание 2. Price/promotion unit tests

- **Исходные данные:** base price, percentage/fixed discount, active interval и precedence contract проекта.
- **Действие:** напишите table tests с вручную проверенными expected `Decimal`; не копируйте algorithm.
- **Результат:** неправильный rounding/boundary/expired promotion обнаруживается.
- **Проверить:** no promo; start/end; zero/maximum; result nonnegative; quantization policy.

## Задание 3. Supplier-selection unit tests

- **Исходные данные:** candidates с base price, promotion, loyalty и deterministic tie-break fields.
- **Действие:** проверьте минимальную итоговую цену и tie-break независимо от QuerySet.
- **Результат:** input order не меняет winner, если contract задаёт tie-break.
- **Проверить:** one candidate; different prices; equal final price; inactive supplier; no stock; empty candidates.

## Задание 4. State/policy unit tests

- **Исходные данные:** Offer status graph и authorization matrix.
- **Действие:** проверяйте разрешённые/запрещённые transitions как pure decision; не сохраняйте models.
- **Результат:** каждый terminal/wrong actor condition имеет test.
- **Проверить:** pending; processing; completed; rejected; cancelled; own/foreign; role/state.

## Задание 5. Mock audit

- **Исходные данные:** все текущие mock/patch/monkeypatch usage.
- **Действие:** заполните `test | real risk | mocked symbol | boundary | what is no longer tested | replacement integration test | decision`.
- **Результат:** mocks ORM/router/permission/business rule выявлены и удалены/перенесены.
- **Проверить:** email; time; UUID/token; HTTP; ORM manager; serializer; policy.

## Задание 6. Patch where looked up

- **Исходные данные:** один service, импортирующий внешний adapter/function.
- **Действие:** сначала покажите, какой module symbol реально вызывает; patch его; продемонстрируйте, что patch исходного module может не сработать после direct import.
- **Результат:** target записан в `MOCK_AUDIT.md` и test ловит реальный call.
- **Проверить:** correct target; wrong target; alias import; refactor path; restoration after test.

## Задание 7. Spec/calls/no-calls

- **Исходные данные:** adapter interface и success/deny/failure paths.
- **Действие:** используйте spec/autospec, проверьте значимые arguments/count; при deny проверьте not called. Не утверждайте каждый private call.
- **Результат:** wrong method/signature ломает test, prohibited side effect отсутствует.
- **Проверить:** called once; not called; wrong args; adapter raises expected error; unexpected error propagates.

## Задание 8. Mock vs integration pair

- **Исходные данные:** email/adapter boundary с unit mock и существующим locmem/Django integration path.
- **Действие:** запустите оба tests и запишите, какой риск доказывает каждый; не дублируйте все assertions.
- **Результат:** unit доказывает orchestration, integration — real framework adapter/format/recipient.
- **Проверить:** correct call; actual outbox; recipient/subject/body; no secret; failure policy.

## Обязательные сценарии дня

1. Price без скидки.
2. Active promotion boundary/rounding.
3. Expired/inactive promotion игнорируется.
4. Supplier с минимальной final price выбран.
5. Equal price использует deterministic tie-break.
6. Empty/unavailable candidates имеют explicit outcome.
7. Offer allowed transition.
8. Offer forbidden terminal transition.
9. Foreign/wrong role policy denied.
10. Correct patch target ловит call, wrong target продемонстрирован.
11. Denied flow не вызывает external adapter.
12. Unit mock и real integration test описывают разные risks.

## Контрольные вопросы

1. Что делает test unit-тестом?
2. Почему mock database не доказывает transaction?
3. Что значит patch where looked up?
4. Что дают spec/autospec?
5. Когда важен `assert_not_called()`?
6. Чем fake может быть лучше сложного mock?

---

# День 6. Django/DRF integration, API tests и coverage audit

## Документация

- [DRF: Testing](https://www.django-rest-framework.org/api-guide/testing/) — APIClient, APIRequestFactory и authentication helpers.
- [pytest-django helpers](https://pytest-django.readthedocs.io/en/latest/helpers.html) — Django fixtures, mailoutbox и query assertions.
- [Coverage.py](https://coverage.readthedocs.io/en/latest/) — измерение line/branch coverage и отчёты.

## Паспорт задания

- **Цель:** построить реальные PostgreSQL/DRF проверки ключевых contracts и превратить coverage report в список осмысленных пробелов.
- **Рабочий файл или каталог:** `tests/integration/`, `tests/api/`, `tests/regression/`, config и `COVERAGE_AUDIT.md` в `day_07_test_suite/`; журнал — `day_06_api_coverage.md`.
- **Результат:** constraint/rollback tests, authentic JWT/API permission tests, query budgets, smoke/regression markers и branch coverage audit critical modules.
- **Порядок выполнения:** выбрать DB risks; написать constraint/rollback tests; создать API matrix; пройти real JWT path; проверить deny side effects; измерить queries; собрать smoke/regression; запустить coverage branch; классифицировать gaps; mutation-check critical uncovered/fixed branch.
- **Наблюдаемый результат:** tests падают при удалении constraint/scope/rollback/assertion; coverage показывает конкретные critical branches; общий процент не скрывает gaps.
- **Готово, если:** PostgreSQL real; DB access explicit; rollback доказан; real auth path есть; status/body/state/side effects проверены; query budgets объяснены; smoke не пуст; coverage branch включён; critical gaps имеют action; 14 сценариев записаны.
- **Пример:** API возвращает 403/404 недостаточно — test также подтверждает, что Offer/ledger/mail count не изменились.
- **Обязательно для зачёта:** задания 1–8 и сценарии 1–14. **Рекомендация:** coverage thresholds вводить только после стабильного baseline и отдельно для critical modules.

## Теория

Прочитайте разделы 4–8, 24–26 и 44–50 `THEORY.md`.

## Задание 1. PostgreSQL constraint tests

- **Исходные данные:** balance/stock nonnegative, unique inventory/catalog pair, valid statuses и FK/protection constraints.
- **Действие:** создайте integration tests, которые пытаются нарушить каждое critical DB rule и ожидают точную database/domain boundary.
- **Результат:** constraint реально существует в PostgreSQL, test очищается после failure.
- **Проверить:** valid row; exact zero; negative; duplicate; protected relation; transaction state after IntegrityError.

## Задание 2. Service rollback tests

- **Исходные данные:** sale/purchase/Offer/account service с несколькими writes и controlled failure point.
- **Действие:** выполните real transaction; вызовите failure после первой потенциальной записи; проверьте отсутствие partial rows/balance/stock movements.
- **Результат:** rollback доказан через database state, не mock calls.
- **Проверить:** success; insufficient balance; insufficient stock; injected expected boundary failure; no partial ledger; original state preserved.

## Задание 3. Real authentication API path

- **Исходные данные:** register/verify/JWT или accepted verified users, access/refresh и protected endpoint.
- **Действие:** минимум один critical flow выполните через настоящий token endpoint/Bearer header; сравните с узким `force_authenticate` test и документируйте difference.
- **Результат:** configured authentication/header/expiry/user lookup работают.
- **Проверить:** valid access; missing; malformed; expired; refresh used as access; inactive/revoked role according contract.

## Задание 4. API contract assertions

- **Исходные данные:** Offer create/list/cancel, supplier/dealership scope, stats и errors.
- **Действие:** проверяйте status, content type, body keys/types/codes, visible rows, DB transition и forbidden fields.
- **Результат:** API tests не привязаны к лишнему ordering/private representation.
- **Проверить:** success; validation; unauthorized; foreign/missing; wrong method; no secret/private field.

## Задание 5. Negative side effects

- **Исходные данные:** denied Offer/balance/catalog/auth requests.
- **Действие:** зафиксируйте before/after row counts/state, ledger, stock, mailoutbox и logs; выполните request.
- **Результат:** отказ не выполняет бизнес-действие до permission/validation decision.
- **Проверить:** 401; 403; 404; 400 invalid state; 429 where existing; unexpected server error separately.

## Задание 6. Query budgets

- **Исходные данные:** catalog/Offer/statistics lists N=2/N=20 и django query assertion helper.
- **Действие:** измерьте queries, подпишите SQL roles и создайте regression assertion; временно удалите eager loading/scope optimization.
- **Результат:** N+1 defect делает test красным; budget обновляется только с rationale.
- **Проверить:** empty; N=2; N=20; page; role scopes; serializer relations.

## Задание 7. Smoke/regression suite

- **Исходные данные:** critical startup/auth/catalog/Offer paths и известные bugs прошлых недель.
- **Действие:** выберите короткий smoke marker и именованные regression tests; запишите selected count/duration и обязательные components.
- **Результат:** smoke не заменяет full suite и не может пройти с zero collected tests.
- **Проверить:** checks; public catalog; auth; protected action; DB; regression for prior bug; deselected count.

## Задание 8. Branch coverage audit

- **Исходные данные:** full suite и critical modules list.
- **Действие:** запустите line+branch coverage; в `COVERAGE_AUDIT.md` классифицируйте each critical gap: add test, unreachable/refactor, intentional exclusion with reason, deferred week16.
- **Результат:** хотя бы три meaningful gaps закрыты assertions; общий процент записан только как context.
- **Проверить:** policy deny branch; transaction failure; token expiry/replay; error handler; generated migrations excluded by rationale; no test files in product metric.

## Обязательные сценарии дня

1. Valid DB row/transaction success.
2. Negative balance constraint rejects write.
3. Negative stock constraint rejects write.
4. Duplicate unique pair rejects write.
5. Service failure rolls back all partial rows.
6. Valid JWT access reaches protected endpoint.
7. Missing/invalid/expired credential follows contract.
8. Authorization deny leaves state/side effects unchanged.
9. Validation error shape and fields match contract.
10. API response excludes secret/private fields.
11. Query budget N=2/N=20 catches N+1 mutation.
12. Smoke selection is non-empty and covers declared components.
13. Known regression test fails when old bug is restored.
14. Branch coverage audit closes/explains every critical gap.

## Контрольные вопросы

1. Почему constraint проверяется PostgreSQL integration test?
2. Как доказать rollback?
3. Зачем нужен настоящий JWT path?
4. Что проверять у negative API response кроме status?
5. Как query budget доказывает отсутствие N+1?
6. Почему coverage percentage не является целью?

---

# День 7. Итоговый проект «Dealership Test Foundation»

## Документация

- [pytest documentation](https://docs.pytest.org/en/stable/) — runner, assertions, fixtures и организация suite.
- [pytest-django documentation](https://pytest-django.readthedocs.io/en/latest/) — интеграция pytest с Django и test database.
- [Django testing tools](https://docs.djangoproject.com/en/5.2/topics/testing/tools/) — Django clients, assertions и test cases.
- [DRF testing](https://www.django-rest-framework.org/api-guide/testing/) — API testing utilities и authentication modes.

## Паспорт проекта

- **Цель:** собрать воспроизводимый многоуровневый test foundation, который доказывает критические contracts backend и готов к углублению в неделю 16.
- **Рабочий файл или каталог:** `day_07_test_suite/`; документы — `README.md`, `TEST_STRATEGY.md`, `TEST_INVENTORY.md`, `FIXTURE_MAP.md`, `MOCK_AUDIT.md`, `COVERAGE_AUDIT.md`, `TEST_MATRIX.md`; итог — `ASSESSMENT.md`.
- **Результат:** pytest configuration, unit/integration/API/regression directories, deterministic factories/fixtures, strict markers, mock boundaries, PostgreSQL/DRF proof и 54 actual scenarios.
- **Порядок выполнения:** перенести baseline; dependency/config gate; inventory; unit slice; fixture/factory slice; DB slice; API/authz slice; mock audit; query/coverage audit; smoke/regression commands; 54 scenarios; clean replay; защита.
- **Наблюдаемый результат:** новый разработчик одной документированной командой собирает и запускает suite; узкие commands локализуют failure; test mutations ловят defects; real services изолированы.
- **Готово, если:** all artifacts filled; old/new tests collected; levels/markers honest; factories deterministic; DB safe; real auth/permissions tested; rollback/query budgets proven; mocks justified; branch gaps resolved; clean run; 54 actual scenarios; защита минимум 36/48.
- **Пример:** pure price rule выполняется как unit без DB, rollback — как PostgreSQL integration, buyer scope — через DRF APIClient с real JWT.
- **Обязательно для зачёта:** артефакты, срезы 1–9, сценарии 1–54, clean replay и защита. **Рекомендация:** выводить короткую таблицу времени по markers без превращения скорости в оценку ученика.

## Целевое дерево

```text
day_07_test_suite/
├── manage.py
├── pyproject.toml или pytest.ini
├── README.md
├── TEST_STRATEGY.md
├── TEST_INVENTORY.md
├── FIXTURE_MAP.md
├── MOCK_AUDIT.md
├── COVERAGE_AUDIT.md
├── TEST_MATRIX.md
├── tests/
│   ├── conftest.py
│   ├── factories/
│   │   ├── accounts.py
│   │   ├── catalog.py
│   │   ├── organizations.py
│   │   └── trading.py
│   ├── unit/
│   ├── integration/
│   ├── api/
│   └── regression/
└── принятые apps/config/migrations недели 14/
```

## Обязанности файлов

| Файл/каталог | Обязанность |
|---|---|
| pytest config | discovery, Django settings, strict markers/config и warning policy |
| `TEST_STRATEGY.md` | risks, levels, commands и boundaries |
| `TEST_INVENTORY.md` | requirement→test→gap mapping |
| `FIXTURE_MAP.md` | fixtures, scopes, dependencies и cleanup |
| `MOCK_AUDIT.md` | patch target, boundary и потерянный integration risk |
| `COVERAGE_AUDIT.md` | line/branch context и meaningful critical gaps |
| `TEST_MATRIX.md` | predictions/actual results 54 сценариев |
| `tests/unit/` | pure policies/calculations без DB |
| `tests/integration/` | ORM/PostgreSQL/services/transactions |
| `tests/api/` | DRF routes/auth/permissions/contracts |
| `tests/regression/` | named previous-defect proofs, если отделение полезно |

## Рекомендуемый порядок сборки по вертикальным срезам

### Срез 1. Baseline и strategy

- **Исходные данные:** accepted week 14 project и old tests.
- **Действие:** source/database/version baseline, inventory, risk/level mapping.
- **Результат:** ни один old test не потерян, gaps приоритизированы.
- **Проверить:** collection counts; old failures; DB target; secrets.

### Срез 2. Pytest configuration

- **Исходные данные:** compatible exact dependencies.
- **Действие:** единый config, strict registered markers, root commands.
- **Результат:** collection/run одинаковы в clean environment.
- **Проверить:** typo marker; duplicate config; wrong settings; zero collected.

### Срез 3. Pure unit tests

- **Исходные данные:** price/promotion/supplier/state/authz rules.
- **Действие:** positive/boundary/negative tests с independent oracles.
- **Результат:** fast no-DB suite ловит guard/formula mutations.
- **Проверить:** Decimal; time boundary; tie-break; terminal state; foreign actor.

### Срез 4. Fixtures и factories

- **Исходные данные:** domain objects двух actors/organizations.
- **Действие:** deterministic factories, function fixtures, documented graph/cleanup.
- **Результат:** setup readable и isolated.
- **Проверить:** overrides; uniqueness; no hidden privilege; reversed order; failure cleanup.

### Срез 5. PostgreSQL integration

- **Исходные данные:** constraints и multi-write services.
- **Действие:** real DB valid/invalid/rollback tests.
- **Результат:** integrity/atomicity доказаны actual rows.
- **Проверить:** zero/negative/duplicate; partial write; expected exception; clean transaction.

### Срез 6. DRF API

- **Исходные данные:** public/auth/authz/Offer/organization/stats endpoints.
- **Действие:** APIClient, real JWT critical path, response/state/side-effect assertions.
- **Результат:** HTTP contract and permission scopes proven.
- **Проверить:** 2xx/4xx; own/foreign; missing; validation; fields; headers.

### Срез 7. Mock/external boundary audit

- **Исходные данные:** email/time/token/HTTP adapter and current patches.
- **Действие:** justify/remove mocks, patch where looked up, spec calls/no-calls, paired integration proof.
- **Результат:** unit isolation не создаёт ложную integration confidence.
- **Проверить:** wrong target; wrong signature; failure; no call on deny; real fake/backend.

### Срез 8. Query, smoke, regression и coverage

- **Исходные данные:** critical lists/modules/known bugs.
- **Действие:** query budgets, non-empty markers, branch report, gap actions.
- **Результат:** performance regressions и uncovered critical branches видны.
- **Проверить:** N=2/N=20; old bug mutation; branch deny/failure; exclusions.

### Срез 9. Clean replay и защита

- **Исходные данные:** empty test DB/environment, dependency lock, docs и matrix.
- **Действие:** clean install, collection, migrations/checks, each marker, full suite, coverage и устная защита.
- **Результат:** test foundation воспроизводим без IDE/manual hidden setup.
- **Проверить:** root commands; no real services; no secrets; same counts; actual report.

## Обязательные unit-сценарии

1. Base price без promotion.
2. Active percentage promotion даёт вручную проверенную цену.
3. Promotion before start не применяется.
4. Exact start boundary соответствует contract.
5. Exact end boundary соответствует contract.
6. Expired/inactive promotion не применяется.
7. Result price не становится отрицательной.
8. Supplier с минимальной final price выбран.
9. Equal final price использует deterministic tie-break.
10. Empty/unavailable supplier candidates имеют explicit result/error.
11. Own pending Offer policy разрешает cancel.
12. Foreign Offer policy запрещает cancel.
13. Terminal Offer policy запрещает transition.
14. Unknown/inactive/unverified actor policy даёт expected deny.

## Обязательные integration-сценарии

15. Valid inventory/balance rows сохраняются PostgreSQL.
16. Exact zero balance/stock boundary допустима по contract.
17. Negative balance constraint отклоняет запись.
18. Negative stock constraint отклоняет запись.
19. Duplicate dealership inventory pair отклоняется.
20. Duplicate supplier catalog pair отклоняется.
21. Protected historical relation не удаляется бесследно.
22. Successful multi-write service создаёт согласованные movements.
23. Insufficient balance откатывает все partial writes.
24. Insufficient stock откатывает все partial writes.
25. Invalid Offer state не создаёт Sale/ledger movement.
26. Verification/action token invalid/expired/replayed state не меняет user.
27. Locmem email integration проверяет recipient/subject/body без secrets.
28. On-commit/email behavior соответствует принятому contract.

## Обязательные API-сценарии

29. Public catalog list доступен anonymous и read-only.
30. Registration/verification happy path сохраняет password безопасно.
31. Real JWT login/access reaches protected endpoint.
32. Missing/invalid/expired access отклоняется по contract.
33. Refresh token не принимается как access.
34. Buyer создаёт Offer только от своего actor-derived profile.
35. Buyer видит только свои Offers.
36. Buyer не видит чужой Offer/Purchase.
37. Buyer отменяет только own pending Offer.
38. Supplier operator меняет только resource своей organization.
39. Dealership operator видит statistics только своей organization.
40. Staff без capability не получает platform-admin действие.
41. Role/membership revoke действует со старым access token.
42. Validation error соответствует error envelope.
43. Denied request не меняет rows/ledger/stock/mail.
44. Response/OpenAPI не содержат private/privilege/secret fields.

## Обязательные tooling/regression-сценарии

45. Pytest собирает legacy unittest/Django tests.
46. Unit test accidental DB access fails.
47. Mutable fixtures изолированы при reversed order.
48. Yield cleanup работает после failed assertion.
49. Strict marker ловит typo.
50. Parametrized boundary failure имеет readable case ID.
51. Correct mock target/spec ловит interface/call defect.
52. Query budget N=2/N=20 ловит N+1 mutation.
53. Smoke и regression selections не пусты и документированы.
54. Branch coverage audit закрывает/объясняет critical gaps и clean full run green.

## Ограничения на ещё не изученные инструменты

- Не добавлять pytest-xdist/rerun/flaky plugins.
- Не внедрять Hypothesis/property-based testing.
- Не добавлять mutation-testing framework.
- Не писать live-server/browser E2E.
- Не добавлять async fixtures без фактического async code и недели 16.
- Не строить сложные race/deadlock tests до недели 16.
- Не менять production code только ради удобства mock без архитектурной причины.
- Не использовать external real network/email/payment.
- Не добавлять Faker/factory package без compatibility decision.
- Не устанавливать coverage threshold наугад.

## Финальный чек-лист сдачи

- [ ] Допуск недели 14 и source commit записаны.
- [ ] Isolated PostgreSQL test database подтверждена.
- [ ] Dependency compatibility и exact dev versions зафиксированы.
- [ ] Один pytest config используется в root.
- [ ] Legacy и pytest-style collection сравнили.
- [ ] Strict markers зарегистрированы.
- [ ] `TEST_STRATEGY.md` связывает risks с levels.
- [ ] `TEST_INVENTORY.md` не имеет необъяснённых critical gaps.
- [ ] Unit tests не используют DB.
- [ ] Fixtures/factories deterministic и documented.
- [ ] Mutable state function-scoped по умолчанию.
- [ ] Cleanup/order isolation доказаны.
- [ ] Parametrized cases имеют readable IDs.
- [ ] Skip/xfail не скрывают mandatory failures.
- [ ] `MOCK_AUDIT.md` объясняет каждый важный double.
- [ ] PostgreSQL constraints/rollback имеют integration tests.
- [ ] Critical API flow проходит real authentication.
- [ ] Negative tests проверяют state/side effects.
- [ ] Query budgets ловят N+1 mutation.
- [ ] Smoke/regression selections не пусты.
- [ ] Branch coverage critical gaps закрыты/объяснены.
- [ ] Все 54 scenarios имеют actual evidence.
- [ ] Full suite/coverage/clean replay green.
- [ ] Logs/reports/Git не содержат secrets.
- [ ] Самооценка заполнена.

## Вопросы для защиты решения

Ответьте на все 48 вопросов из `THEORY.md`. Обязательные: 3, 4, 5, 7, 8, 10, 12, 13, 14, 15, 18, 19, 21, 22, 24, 25, 26, 27, 29, 31, 32, 33, 35, 38, 39, 40, 41, 43, 45, 46, 47 и 48.

На живой защите наставник выбирает два изменения:

- новый critical branch без test;
- fixture случайно расширена до session scope;
- API test заменяет real auth на `force_authenticate`;
- production symbol импортирован другим способом и patch target изменился;
- новый marker добавлен с опечаткой;
- coverage вырос, но meaningful assertion удалён.

Ученик должен объяснить, какой level/test/config/report изменится и какой red failure докажет исправление.
