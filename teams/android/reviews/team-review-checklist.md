# Team Review Checklist
#
# This file is copied to .claude/reviews/ during install.
# Used by /review for team-specific quality gates.
#
# Format: Markdown table with Check, Severity, and What to Look For.
# ─────────────────────────────────────────────

| Check | Severity | What to Look For |
|-------|----------|------------------|
| Architecture compliance | High | No layer violations (e.g., UI importing data layer directly, business logic in Activities/Fragments) |
| Lifecycle safety | High | Coroutines use appropriate scope (viewModelScope/lifecycleScope), no leaked observers |
| Error handling | High | All network/IO operations handle failures with user feedback |
| Compose best practices | Medium | Composables are stateless where possible, state hoisting is applied correctly |
| Test coverage | Medium | New logic has corresponding unit tests, ViewModels are tested |
