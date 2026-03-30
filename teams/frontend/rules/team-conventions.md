# Team Conventions
#
# This file is copied to .claude/rules/ during install.
# Claude reads these rules during ALL work — not just workflows.
#
# Write rules as DO / DON'T pairs with brief rationale.
# Keep it focused on conventions that differ from general best practices.
# ─────────────────────────────────────────────

## Architecture

- DO follow component-based architecture with hooks
- DON'T use class components or direct DOM manipulation

## Naming

- DO use camelCase for variables, PascalCase for components
- DON'T use abbreviations or inconsistent casing

## Dependencies

- DO use React Query or SWR for data fetching
- DON'T introduce new dependencies without team discussion

## React-Specific Conventions

- DO use TanStack Query (React Query) for server state management
- DO use CSS Modules or Tailwind for styling — avoid CSS-in-JS runtime libraries
- DON'T use `any` type — prefer `unknown` with type narrowing
- DO use barrel exports (index.ts) for public module APIs
