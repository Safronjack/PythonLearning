"""Неделя 5, день 1: путь web-запроса.

Не начинать до полного зачёта недель 0–4.
Требования и сценарии находятся в PRACTICE.md.
"""

from typing import TypedDict


class UrlParts(TypedDict):
    """Структура разобранного URL."""

    scheme: str
    hostname: str
    port: int
    path: str
    query: dict[str, list[str]]
    fragment: str


def parse_url(url: str) -> UrlParts:
    """Разобрать и проверить учебный HTTP/HTTPS URL."""
    ...


def describe_request_path(url: str) -> list[str]:
    """Вернуть смысловые этапы прохождения запроса."""
    ...


def encode_utf8(text: str) -> bytes:
    """Закодировать строку в UTF-8."""
    ...


def decode_utf8(data: bytes) -> str:
    """Декодировать UTF-8 согласно выбранной стратегии ошибок."""
    ...


# TODO: безопасный getaddrinfo() только для localhost.


# TODO: socketpair(), чтение chunks и framing по символу новой строки.


# TODO: обязательные сценарии и самооценка.
