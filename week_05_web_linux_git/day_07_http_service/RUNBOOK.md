# Local runbook

Статус: **не заполнено**.

## Предварительные условия

TODO

## Запуск direct checks

```sh
# TODO
```

## Необязательный локальный server

```sh
# TODO: bind только 127.0.0.1
```

## Health check

```sh
# TODO: только localhost
```

## Остановка и проверка процесса

TODO

## Диагностика занятого порта

TODO: только read-only наблюдение и остановка собственного процесса.

## Ограничения

- Без `sudo`.
- Без публичного bind.
- Без deployment/systemd/firewall изменений.
- `wsgiref` не считается production server.
