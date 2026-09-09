# Неделя 9: основа Django

Статус: **подготовлена заранее и заблокирована до полного зачёта недель 0–8**.

Эта неделя переводит уже изученные Python, HTTP, SQL и PostgreSQL в первый настоящий Django-проект. Здесь важно не просто запустить стартовую страницу, а понять, какие обязанности выполняют project, application, settings, URL dispatcher, view, template, middleware и admin.

Итог недели — воспроизводимый Django-каркас будущей системы автосалонов. Предметные модели и сложные ORM-запросы появятся на неделе 10; DRF, JWT, email-процессы, Celery, Redis и Docker — позже по roadmap.

## Результат недели

После завершения модуля ученик умеет:

- создать Django project и несколько Django apps без смешивания их обязанностей;
- объяснить назначение `manage.py`, project package и `AppConfig`;
- читать основные settings и получать конфигурацию из environment;
- подключить отдельную учебную PostgreSQL database;
- создать custom user на основе `AbstractUser` **до первой миграции**;
- построить namespaced URL configuration и простые function-based views;
- вернуть HTML и JSON через штатные response-классы;
- использовать templates, context, static files и CSRF-защиту;
- зарегистрировать custom user в admin и создать superuser;
- объяснить полный request/response lifecycle;
- написать небольшое middleware и проверить порядок его выполнения;
- отличать явный вызов service от подходящего и неподходящего signal;
- использовать Django system checks, `check --deploy` и минимальные smoke tests;
- объяснить, какие security-настройки относятся к development, а какие к production.

## Предварительные требования

- Недели 0–8 завершены полностью.
- Итоговый PostgreSQL readiness audit недели 8 принят минимум на 8/10.
- В `week_08_postgresql_internals_scaling/ASSESSMENT.md` указано: «Допуск к неделе 9: да».
- Ученик уверенно использует функции, классы, исключения, модули, typing, Git, HTTP и SQL.
- Доступна отдельная учебная PostgreSQL database; её имя и пользователь подтверждены до применения миграций.

## Версии и зависимости

Текущая локальная версия Python — 3.11. Для неё учебные примеры ориентированы на поддерживаемую ветку **Django 5.2 LTS**. Перед фактическим началом недели наставник обязан повторно проверить:

1. актуальную поддерживаемую patch-версию Django 5.2;
2. совместимость Django с установленным Python;
3. актуальную поддерживаемую версию PostgreSQL driver;
4. отсутствие известных security advisories для выбранных версий.

Не устанавливать зависимости заранее при одной только подготовке модуля. Установка выполняется после допуска и фиксации выбранных версий. Минимальный набор недели:

- Django;
- Psycopg 3 для PostgreSQL.

`django-countries`, Django REST Framework, `django-filter`, SimpleJWT, `drf-spectacular`, Redis и Celery пока не нужны.

## Связь с итоговым проектом

На этой неделе создаётся каркас из исходного задания:

- `accounts` — custom user и дальнейшие аккаунтные сценарии;
- `catalog` — марки, модели и характеристики автомобилей;
- `dealerships` — автосалоны, остатки и продажи;
- `suppliers` — поставщики, цены и закупки;
- `trading` — предложения покупателей и сделки;
- `promotions` — акции и скидки;
- `analytics` — будущая статистика;
- `common` — действительно общие web-компоненты и инфраструктурные утилиты.

В неделю 9 приложения получают только каркас и понятные границы. Не создавать преждевременно все предметные models: их связи, constraints и migrations проектируются на неделе 10 на основе SQL-решений недель 6–8.

## Структура модуля

- [THEORY.md](THEORY.md) — теория, прогнозы, примеры и вопросы самопроверки;
- [PRACTICE.md](PRACTICE.md) — семь подробных практических дней;
- [ASSESSMENT.md](ASSESSMENT.md) — оценки, ошибки, пересдачи и допуск;
- [notes.md](notes.md) — словарь терминов, прогнозы и вопросы ученика;
- `day_01_project_anatomy.md` — карта проекта и журнал первого запуска;
- `day_02_settings_custom_user.md` — решения по settings, environment, database и custom user;
- `day_03_urls_views.md` — таблица URL-контрактов и результаты проверок;
- `day_04_templates_admin.md` — карта templates/static/admin и наблюдения;
- `day_05_middleware_lifecycle.md` — трасса request/response и middleware;
- `day_06_security_signals.md` — threat/settings table, signal decisions и checks;
- `day_07_django_foundation/` — накапливаемый Django-проект недели.

## Ожидаемая структура Django-проекта

Она создаётся учеником постепенно, а не выдаётся готовой:

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

Допускается обоснованный settings package вместо одного `settings.py`, если ученик способен объяснить импорт и выбор окружения. На первой Django-неделе простой понятный вариант предпочтительнее сложного шаблона.

## Порядок прохождения

1. Получить допуск из недели 8.
2. Проверить Python, PostgreSQL и выбранные версии зависимостей.
3. Создать отдельную feature branch для недели 9.
4. Прочитать только разделы теории текущего дня.
5. До запуска ответить на вопросы-прогнозы в назначенном `.md`-файле.
6. Выполнить изменения в накапливаемом Django-проекте.
7. Запустить обязательные команды и сохранить краткий фактический результат.
8. Заполнить самооценку.
9. Написать: `Проверь день N недели 9`.
10. Самостоятельно исправить обязательные замечания и получить зачёт.

## Безопасная рабочая среда

- Работать только внутри `week_09_django_foundation/day_07_django_foundation/`.
- Использовать только отдельную учебную PostgreSQL database.
- До `migrate` вывести и проверить database host/name/user без пароля.
- Не использовать production credentials, реальные email и персональные данные.
- Не добавлять `.env`, секретный `SECRET_KEY` или пароль базы в Git.
- В репозитории хранить только `.env.example` с безопасными фиктивными значениями.
- `runserver` считать development server, не production server.
- Не запускать `check --deploy` с реальными production-секретами в учебном окружении.
- Не отключать CSRF и security middleware ради прохождения задания.
- Не создавать и не применять миграции до настройки custom user.

## Границы недели

На этой неделе не требуются:

- полная предметная модель автосалона;
- сложные QuerySet, `select_related`, `prefetch_related`, `F`, `Q`, annotations и transactions через ORM;
- Django REST Framework, serializers, ViewSet и routers DRF;
- JWT, регистрация, подтверждение email и восстановление пароля;
- Celery, Redis и scheduled tasks;
- Docker, Gunicorn и Nginx;
- полноценный frontend;
- production deployment;
- кастомный authentication backend;
- signals для основной бизнес-логики;
- async views ради самого факта использования async.

## Оценивание

| Критерий | Баллы |
|---|---:|
| Корректность результата | 0–3 |
| Выполнение условий задания | 0–2 |
| Граничные и ошибочные сценарии | 0–2 |
| Читаемость и структура | 0–1 |
| Понимание и самооценка | 0–1 |
| Самостоятельность исправлений | 0–1 |

Для следующего дня требуется минимум 7/10 без критической ошибки. Для итогового Django-каркаса — минимум 8/10.

## Критические ошибки

- первая миграция применена до настройки `AUTH_USER_MODEL`;
- SQLite незаметно используется вместо требуемой PostgreSQL;
- `.env`, пароль базы или настоящий `SECRET_KEY` добавлен в Git;
- `DEBUG` читается как `bool(os.getenv(...))`, из-за чего строка `"False"` становится `True`;
- `ALLOWED_HOSTS = ["*"]` выдаётся за безопасную production-настройку;
- view возвращает секреты, traceback или содержимое settings;
- CSRF отключён глобально ради работающей формы;
- custom middleware не вызывает `get_response()` без явно описанного short-circuit;
- middleware логирует cookie, Authorization header, password или request body целиком;
- signal содержит основную транзакционную бизнес-логику;
- signal receiver регистрируется несколько раз из-за неверного импорта;
- `runserver` описан как production-ready server;
- фактический результат команды подменён ожидаемым.

## Критерий завершения

- все дни имеют минимум 7/10;
- итоговый проект имеет минимум 8/10;
- custom user создан в `accounts/0001_initial.py` до первой миграции;
- все восемь apps присутствуют в `INSTALLED_APPS` и имеют объяснимую ответственность;
- PostgreSQL connection и migrations проверены;
- `/`, `/health/`, `/ready/` и admin работают по заявленному контракту;
- URL names и namespaces используются последовательно;
- template наследование и static file работают в development;
- middleware order и request/response trace объяснены;
- signal используется только для допустимого побочного эффекта либо обоснованно не добавлен в итоговый код;
- `manage.py check` проходит;
- результаты `check --deploy` разобраны, а не бездумно скрыты;
- smoke tests проходят;
- минимум 18 из 24 контрольных вопросов отвечены уверенно;
- в `ASSESSMENT.md` указано: «Допуск к неделе 10: да».

## Официальные материалы

- [Django 5.2 tutorial](https://docs.djangoproject.com/en/5.2/intro/tutorial01/);
- [Applications](https://docs.djangoproject.com/en/5.2/ref/applications/);
- [Settings](https://docs.djangoproject.com/en/5.2/topics/settings/);
- [URL dispatcher](https://docs.djangoproject.com/en/5.2/topics/http/urls/);
- [Request and response objects](https://docs.djangoproject.com/en/5.2/ref/request-response/);
- [Templates](https://docs.djangoproject.com/en/5.2/topics/templates/);
- [Admin site](https://docs.djangoproject.com/en/5.2/ref/contrib/admin/);
- [Custom user model](https://docs.djangoproject.com/en/5.2/topics/auth/customizing/);
- [Middleware](https://docs.djangoproject.com/en/5.2/topics/http/middleware/);
- [Signals](https://docs.djangoproject.com/en/5.2/topics/signals/);
- [Security](https://docs.djangoproject.com/en/5.2/topics/security/);
- [Deployment checklist](https://docs.djangoproject.com/en/5.2/howto/deployment/checklist/);
- [System checks](https://docs.djangoproject.com/en/5.2/topics/checks/).

## Текущий статус

Неделя 9 только подготовлена. Текущий активный этап остаётся в `week_00_basics/ASSESSMENT.md`. Не устанавливать Django, не создавать project и не применять migrations до полного допуска из недели 8.
