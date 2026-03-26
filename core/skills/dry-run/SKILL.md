---
name: dry-run
description: Preview what a workflow will do without executing any changes. Shows phases, files, branches, and estimated scope.
---

# Dry Run Mode

Preview a workflow's execution plan without making any changes. Append `--dry-run` to any workflow command:

```
/workflow:new-feature booking-cancellation --dry-run
/workflow:hotfix --crashlytics ISSUE-123 --dry-run
/workflow:refactor BookingRepository --dry-run
```

## What Dry Run Does

1. Reads `.claude/workflows.yml` for configuration
2. Determines which phases will execute (based on config flags)
3. Calculates branch name from git config
4. Identifies chainable phases
5. Checks for active/paused workflows
6. Reports everything WITHOUT executing

## Output Format

```
═══ DRY RUN: /workflow:new-feature booking-cancellation ═══

Workflow:    new-feature
Feature:     booking-cancellation

PHASES:
  1. GATHER        — Interactive (no --from-jira or --from-figma)
  2. SPEC          — Will create .workflows/booking-cancellation/02-spec.md
  3. BRAINSTORM    — Depth: standard, Technique: auto-select
  4. PLAN          — Will create .claude/plan-booking-cancellation.md
  5. BRANCH        — alpha-feature/Booking_cancellation (from Development)
  6. IMPLEMENT     — Phases A-F with compile checks
  7. TEST          — Chained: /workflow:test (require_tests: true)
  8. PR            — Target: Development, Format: squash

GIT:
  Branch: alpha-feature/Booking_cancellation  Base: Development
  Commit: feat(booking): ...  PR target: Development

FILES: Spec, Plan, State (.workflows/current-state.md), Todo (tasks/todo.md)

GUARDS: 17 block rules, 11 protected paths
CHAINS: TEST → /workflow:test --coverage 90
CONFLICTS: None (no active workflow)
LEARNED PATTERNS: Relevant patterns from .workflows/learned/ if any

═══ End dry run. No changes made. ═══
```

## What Dry Run Does NOT Do

- Does NOT create any files or branches
- Does NOT run any git commands (except read-only: `git branch`, `git status`)
- Does NOT write to state files or invoke sub-agents
- Does NOT read Jira/Figma (even if flags provided -- just notes the source)

## Integration with Workflow Engine

The workflow engine checks for `--dry-run` flag FIRST:
1. If `--dry-run` present: execute dry-run skill, then STOP
2. If not: proceed with normal workflow execution
