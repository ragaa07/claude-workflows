# Team Review Checklist
#
# This file is copied to .claude/reviews/ during install.
# Used by /review for team-specific quality gates.
#
# Format: Markdown table with Check, Severity, and What to Look For.
# ─────────────────────────────────────────────

| Check | Severity | What to Look For |
|-------|----------|------------------|
| Layered architecture | High | No business logic in route handlers, proper separation of concerns |
| Input validation | High | All endpoints validate and sanitize input before processing |
| Error handling | High | All database/IO operations handle failures, return proper HTTP status codes |
| SQL safety | Medium | No raw SQL with string interpolation, use parameterized queries or ORM |
| Test coverage | Medium | New endpoints have integration tests, services have unit tests |
