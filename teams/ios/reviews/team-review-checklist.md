# Team Review Checklist
#
# This file is copied to .claude/reviews/ during install.
# Used by /workflow:review for team-specific quality gates.
#
# Format: Markdown table with Check, Severity, and What to Look For.
# ─────────────────────────────────────────────

| Check | Severity | What to Look For |
|-------|----------|------------------|
| MVVM compliance | High | No business logic in Views, ViewModels do not import SwiftUI |
| Memory management | High | No retain cycles, proper use of [weak self] in closures |
| Error handling | High | All async operations handle errors with user-facing feedback |
| SwiftUI patterns | Medium | Proper use of @State, @Binding, @ObservedObject; no unnecessary re-renders |
| Test coverage | Medium | New logic has corresponding unit tests, ViewModels are tested |
