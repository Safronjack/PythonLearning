# День 6: изолированная Git-лаборатория

Статус: **не начато**.

Новый Git repository создаётся учеником только в `sandbox_repo/` после проверки точного пути. Эта папка дня не является репозиторием лаборатории сама по себе.

Порядок и ограничения описаны в [../PRACTICE.md](../PRACTICE.md). Запрещены destructive history operations, remote и публикация.

## Чек-лист безопасности

- [ ] Недели 0–4 полностью зачтены.
- [ ] День 5 недели 5 зачтён.
- [ ] `pwd` оканчивается на `day_06_git_lab/sandbox_repo`.
- [ ] `git config --local` использует фиктивный email.
- [ ] Remote отсутствует.
- [ ] `.env`, logs и caches игнорируются.
- [ ] В командах нет `reset --hard`, `clean -fd` или force push.
- [ ] В конце working tree чистый.

## Итог

TODO: кратко описать полученную историю, merge conflict, rebase и revert.
