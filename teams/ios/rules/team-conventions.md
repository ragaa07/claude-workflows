# Team Conventions
#
# This file is copied to .claude/rules/ during install.
# Claude reads these rules during ALL work — not just workflows.
#
# Write rules as DO / DON'T pairs with brief rationale.
# Keep it focused on conventions that differ from general best practices.
# ─────────────────────────────────────────────

## Architecture

- DO follow MVVM with SwiftUI
- DON'T use massive view controllers or direct UIKit usage in new code

## Naming

- DO use camelCase for variables and functions, PascalCase for types
- DON'T use abbreviations or Hungarian notation

## Dependencies

- DO use Combine or async/await for asynchronous operations
- DON'T introduce new dependencies without team discussion
