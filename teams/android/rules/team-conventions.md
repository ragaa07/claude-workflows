# Team Conventions
#
# This file is copied to .claude/rules/ during install.
# Claude reads these rules during ALL work — not just workflows.
#
# Write rules as DO / DON'T pairs with brief rationale.
# Keep it focused on conventions that differ from general best practices.
# ─────────────────────────────────────────────

## Architecture

- DO follow MVVM with Clean Architecture
- DON'T put business logic in Activities/Fragments

## Naming

- DO use camelCase for functions, PascalCase for classes
- DON'T use abbreviations or Hungarian notation

## Dependencies

- DO use Hilt for dependency injection
- DON'T introduce new dependencies without team discussion
