"""Неделя 5, день 4: web security и authentication models.

Не начинать до зачёта дня 3.
Никаких внешних запросов и реальных атак.
"""

from typing import TypedDict


class QuoteInput(TypedDict):
    """Проверенные входные данные расчёта."""

    car_id: int
    quantity: int
    discount_percent: int


def validate_quote_input(payload: object) -> QuoteInput:
    """Проверить типы, диапазоны и business constraints."""
    ...


def classify_image_url(url: str) -> tuple[bool, list[str]]:
    """Классифицировать URL без выполнения network request."""
    ...


def cors_headers(
    origin: str | None,
    allowed_origins: set[str],
) -> list[tuple[str, str]]:
    """Вернуть CORS headers для точного allowlist match."""
    ...


# TODO: html.escape() experiment для HTML text context.


# TODO: SQLite in-memory и только parameterized query.


# TODO: CORS/CSRF/auth matrices и самооценка.
