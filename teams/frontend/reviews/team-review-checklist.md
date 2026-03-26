# Team Review Checklist
#
# This file is copied to .claude/reviews/ during install.
# Used by /review for team-specific quality gates.
#
# Format: Markdown table with Check, Severity, and What to Look For.
# ─────────────────────────────────────────────

| Check | Severity | What to Look For |
|-------|----------|------------------|
| Component architecture | High | No direct DOM manipulation, components are composable and reusable |
| Type safety | High | No `any` types, proper TypeScript interfaces for props and state |
| Error handling | High | API calls handle loading/error states with user feedback |
| Hook usage | Medium | Custom hooks extract shared logic, no hooks inside conditionals or loops |
| Test coverage | Medium | New components have unit tests, user interactions are tested |
