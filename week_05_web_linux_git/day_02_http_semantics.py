"""Неделя 5, день 2: HTTP semantics.

Не начинать до зачёта дня 1.
Требования и сценарии находятся в PRACTICE.md.
"""

from typing import NamedTuple


class MethodSemantics(NamedTuple):
    """Свойства HTTP method, изучаемые на этой неделе."""

    safe: bool
    idempotent: bool


def method_semantics(method: str) -> MethodSemantics:
    """Вернуть safe/idempotent для поддержанного HTTP method."""
    ...


def choose_status(event: str) -> int:
    """Сопоставить учебное событие с HTTP status code."""
    ...


def normalize_headers(headers: list[tuple[str, str]]) -> dict[str, str]:
    """Нормализовать учебный набор headers."""
    ...


def get_media_type(content_type: str) -> str:
    """Извлечь media type без параметров."""
    ...


def accepts_json(accept: str | None) -> bool:
    """Проверить упрощённое согласование JSON response."""
    ...


def json_response(
    payload: object,
    status: int = 200,
) -> tuple[str, list[tuple[str, str]], bytes]:
    """Собрать учебный WSGI-compatible JSON response."""
    ...


def conditional_response(
    payload: object,
    current_etag: str,
    if_none_match: str | None,
) -> tuple[int, list[tuple[str, str]], bytes]:
    """Вернуть обычный или условный cache response."""
    ...


# TODO: Set-Cookie example и письменные объяснения.


# TODO: обязательные сценарии и самооценка.
