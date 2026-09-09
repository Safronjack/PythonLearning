# День 4: security-модель и схемы auth

Статус: **не начато**.

## Threat table

| Asset | Untrusted input | Threat | Impact | Preventive control | Detection/logging | Residual risk |
|---|---|---|---|---|---|---|
| TODO | TODO | TODO | TODO | TODO | TODO | TODO |

## Sequence diagram: регистрация

До диаграммы зафиксируй решения: password hashing выполняет проверенная библиотека; password не логируется; пользователь не считается подтверждённым до выбранного шага verification.

```mermaid
sequenceDiagram
    %% TODO: Browser, Application, User store, Mail service
    %% TODO: validation, duplicate email, password hash, verification, safe response
```

## Sequence diagram: вход

Укажи успешный и неуспешный paths, rate limiting, проверку credentials, создание session и безопасный cookie. Не раскрывай в публичной ошибке, существует ли email, если выбран такой security contract.

```mermaid
sequenceDiagram
    %% TODO: Browser, Application, User store, Session store
    %% TODO: credentials check, generic failure, session rotation, Set-Cookie
```

## Authentication и authorization

TODO: на обеих схемах отметить, где подтверждается личность, а где проверяется право выполнить действие.

## CORS и CSRF

TODO: объяснить, какие browser boundaries относятся к CORS, а какие к CSRF.

## Session, JWT, OAuth 2.0 и OIDC

| Вопрос | Server session | JWT access token | OAuth 2.0 | OIDC |
|---|---|---|---|---|
| Назначение | TODO | TODO | TODO | TODO |
| Где хранится состояние | TODO | TODO | TODO | TODO |
| Отзыв/завершение | TODO | TODO | TODO | TODO |
| Главный риск | TODO | TODO | TODO | TODO |

## Самооценка

1. Что получилось:
2. Что было трудно:
3. Какие риски пока путаю:
4. Что повторить:
