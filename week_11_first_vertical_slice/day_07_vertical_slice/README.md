# Итоговый проект недели 11

Статус: **заготовка; не начинать до допуска из недели 10**.

После активации сюда переносится принятый ORM-проект недели 10. Все дни недели 11 развивают эту копию. Полное ТЗ, дерево и 32 сценария находятся в `../PRACTICE.md`.

## Clean setup

После реализации ученик описывает:

1. supported Python/Django/PostgreSQL versions;
2. safe environment setup;
3. isolated database creation;
4. migrations;
5. staff/reference setup;
6. procurement command;
7. catalog GET;
8. tests and query budgets.

## Главный сценарий

```text
admin creates catalog and supplier item
-> procurement command calls service
-> service commits state and history
-> selector reads available inventory
-> JSON endpoint returns public catalog
```

## Фактическая структура

Заполняется учеником.

## Проверочные команды

Заполняется фактическими командами и результатами. Secrets не вставляются.

## Ограничения

DRF, JWT, Celery, brokers, Redis, frontend и deployment в этом срезе не добавляются.
