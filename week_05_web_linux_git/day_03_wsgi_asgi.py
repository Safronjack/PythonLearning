"""Неделя 5, день 3: API styles, WSGI и ASGI.

Не начинать до зачёта дня 2.
Требования и сценарии находятся в PRACTICE.md.
"""

from collections.abc import Callable
from typing import Any, TypeAlias

Handler: TypeAlias = Callable[[], tuple[int, object]]


def resolve_route(method: str, path: str) -> tuple[Handler | None, set[str]]:
    """Найти handler и множество разрешённых methods для path."""
    ...


def wsgi_app(environ: dict[str, Any], start_response: Callable[..., Any]):
    """Минимальное WSGI application."""
    ...


def call_wsgi_app(method: str, path: str) -> tuple[str, list[tuple[str, str]], bytes]:
    """Вызвать WSGI application напрямую без TCP server."""
    ...


async def asgi_app(scope: dict[str, Any], receive: Callable[..., Any], send: Callable[..., Any]) -> None:
    """Минимальное ASGI application."""
    ...


async def read_asgi_body(receive: Callable[..., Any], max_bytes: int) -> bytes:
    """Собрать ASGI body из событий с общим лимитом."""
    ...


# TODO: REST/RPC/GraphQL comparison.


# TODO: direct WSGI/ASGI scenarios и самооценка.
