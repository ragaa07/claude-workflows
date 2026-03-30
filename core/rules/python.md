# Python Rules

## Type Hints
- DO add type hints to all function signatures: `def fetch(url: str) -> Response:`
- DO use `from __future__ import annotations` for forward references (Python 3.7+)
- DO use `typing` module types: `Optional`, `Union`, `list[str]` (3.9+), `dict[str, int]`
- DO use `TypeAlias` for complex types: `UserId: TypeAlias = int`
- DO use `Protocol` for structural subtyping instead of ABC when possible

## Data Classes
- DO use `@dataclass` for structured data with auto-generated methods
- DO use `frozen=True` for immutable data: `@dataclass(frozen=True)`
- DO use `field(default_factory=list)` for mutable defaults — never `= []`
- DO consider `pydantic.BaseModel` when validation is needed

## Async / Await
- DO use `async def` and `await` for I/O-bound operations
- DO use `asyncio.gather()` for concurrent independent tasks
- DON'T mix sync and async — use `asyncio.to_thread()` for blocking calls
- DO use `async with` for async context managers

## Context Managers
- DO use `with` for resource management (files, connections, locks)
- DO write custom context managers with `@contextmanager` or `__enter__`/`__exit__`
- DON'T manually open/close resources without `with`

## Path Handling
- DO use `pathlib.Path` over `os.path`: `Path("data") / "file.txt"`
- DON'T use string concatenation for paths
- DO use `Path.exists()`, `Path.read_text()`, `Path.mkdir(parents=True, exist_ok=True)`

## Collections
- DO use list comprehensions for simple transforms: `[x.id for x in users]`
- DO use generator expressions for large datasets: `sum(x.price for x in items)`
- DON'T nest comprehensions more than one level deep — use a loop
- DO use `collections.defaultdict`, `Counter`, `deque` where appropriate
- DO use `dict.get(key, default)` over `key in dict` + access

## Error Handling
- DO catch specific exceptions, never bare `except:` or `except Exception:`
- DO use `raise ... from e` to chain exceptions
- DO define custom exceptions inheriting from domain-specific base
- DON'T use exceptions for flow control — check conditions first

## Testing (pytest)
- DO use `pytest` fixtures with appropriate scope
- DO use parametrize for table-driven tests: `@pytest.mark.parametrize("input,expected", [...])`
- DO use `tmp_path` fixture for filesystem tests
- DO name tests descriptively: `test_user_creation_fails_with_duplicate_email`
- DO use `pytest.raises(ExactException)` to assert exceptions

## General
- DO use `logging` module over `print()` for production code
- DO use `functools.lru_cache` or `@cache` for expensive pure functions
- DON'T use mutable default arguments: `def f(items=None):` then `items = items or []`
- DO pin dependencies in `requirements.txt` or `pyproject.toml`
