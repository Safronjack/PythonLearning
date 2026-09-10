# Dealership Quality Gate

Статус: шаблон. После допуска сюда копируется **принятый** проект недели 15; исходник недели 15 не изменяется.

## Source и environment

- Source path:
- Branch/commit:
- Python/Django/PostgreSQL:
- Dependency lock:
- Settings module:
- Test database safety proof:

## Clean setup

Опишите команды от чистого окружения до готовой test database. Не записывайте пароли, токены и полные DSN.

```text
TODO
```

## Quality-gate commands

| Stage | Purpose | Local command | CI command/job | Expected exit/status |
|---|---|---|---|---|
| Configuration/collection | | | | |
| Unit/TDD | | | | |
| Integration/API | | | | |
| Transaction/concurrency | | | | |
| E2E | | | | |
| Coverage/report | | | | |

## Итоговые результаты

- Clean run 1:
- Clean run 2:
- Passed:
- Failed:
- Skipped:
- Xfail/xpass:
- N/A with evidence:
- Deferred:
- Duration:

## Troubleshooting

- Как распознать неправильную database:
- Как завершить зависший worker:
- Где искать первый E2E failure:
- Какие artifacts сохраняет CI:

## Ограничения

- Только isolated PostgreSQL и local HTTP.
- Никаких настоящих provider calls.
- Никакого retry для сокрытия flaky tests.
- Async dependency только при доказанном async production path.
- Redis/Celery не входят в эту неделю.

