# Python Code Review Checklist

| Check | Severity | What to Look For |
|-------|----------|------------------|
| Type hints present | Medium | All function signatures have input and return type hints. |
| No bare `except` | High | Catch specific exceptions. Never `except:` or `except Exception:` without re-raise. |
| Exception chaining | Medium | Use `raise NewError(...) from original` to preserve traceback context. |
| Mutable default args | High | No `def f(items=[])`. Use `None` default + initialize inside function body. |
| Context managers | High | Files, connections, locks use `with` statements. No manual `open()`/`close()`. |
| Pathlib usage | Low | Use `pathlib.Path` over `os.path` for file path operations. |
| Async correctness | High | No mixing sync blocking calls inside `async def`. Use `asyncio.to_thread()` for blocking. |
| No `print()` in prod | Medium | Use `logging` module for production code. `print()` only in scripts/CLI. |
| SQL injection safety | Critical | Use parameterized queries. Never f-string or `.format()` SQL with user input. |
| Secret management | Critical | No hardcoded secrets, API keys, or passwords. Use environment variables or vaults. |
| Input validation | High | Validate and sanitize all external inputs (API params, file uploads, form data). |
| Dataclass usage | Medium | Structured data uses `@dataclass` or Pydantic, not raw dicts with string keys. |
| Comprehension depth | Medium | No nested list comprehensions deeper than one level. Use explicit loops. |
| Test parametrization | Medium | Repetitive test cases use `@pytest.mark.parametrize` for table-driven tests. |
| Test isolation | High | Tests don't depend on each other or shared mutable state. Use fixtures. |
| Dependency pinning | Medium | All dependencies pinned to specific versions in `requirements.txt` or `pyproject.toml`. |
| Docstrings | Low | Public functions and classes have docstrings explaining purpose and params. |
| F-string usage | Low | New code uses f-strings over `%` or `.format()`. |
| Enum for constants | Low | Fixed sets of values use `Enum` instead of magic strings or integers. |
