# Quality gate

## Политика

- Что блокирует принятие изменения:
- Как трактуются skipped/xfail/xpass:
- Максимальное время transaction/concurrency stage:
- Максимальное время E2E stage:
- Кто и когда может объявить quarantine:
- Как сравниваются local и CI runs:

## Этапы

| № | Stage | Risks covered | Selection/command | Prerequisites | Artifact | Blocking? |
|---:|---|---|---|---|---|---|
| 1 | collection/config | | | | | да |
| 2 | unit/TDD | | | | | да |
| 3 | integration/API | | | PostgreSQL | | да |
| 4 | transaction/concurrency | | | PostgreSQL | | да |
| 5 | E2E | | | local live server | | да |
| 6 | coverage/report | | | previous stages | | да |

## Clean-run evidence

| Run | Commit | Environment | Passed/failed/skipped/xfail | Duration | Result |
|---|---|---|---|---|---|
| 1 | | | | | |
| 2 | | | | | |

## Failure examples

- Один ожидаемый assertion failure и его диагностика:
- Один timeout/hang failure и его диагностика:
- Один configuration/database safety failure:

