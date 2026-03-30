# Team Conventions
#
# This file is copied to .claude/rules/ during install.
# Claude reads these rules during ALL work — not just workflows.
#
# Write rules as DO / DON'T pairs with brief rationale.
# Keep it focused on conventions that differ from general best practices.
# ─────────────────────────────────────────────

## Architecture

- DO follow layered architecture (routes, services, repositories)
- DON'T put business logic in route handlers

## Naming

- DO use snake_case for functions and variables, PascalCase for classes
- DON'T use abbreviations or inconsistent casing

## Dependencies

- DO use SQLAlchemy or similar ORM for database access
- DON'T introduce new dependencies without team discussion

## Python Backend Conventions

- DO use Pydantic for request/response validation
- DO use dependency injection via FastAPI's Depends() or similar
- DON'T use synchronous I/O in async endpoints
- DO use structured logging (JSON) with correlation IDs
