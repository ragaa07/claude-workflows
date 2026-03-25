---
name: dry-run
description: Preview what a workflow will do without executing any changes. Shows phases, files, branches, and estimated scope.
---

# Dry Run Mode

Preview a workflow's execution plan without making any changes.

## Command

Append `--dry-run` to any workflow command:

```
/workflow:new-feature booking-cancellation --dry-run
/workflow:hotfix --crash ISSUE-123 --dry-run
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
  2. SPEC          — Will create .workflows/specs/booking-cancellation.spec.md
  3. BRAINSTORM    — Depth: standard, Technique: auto-select
  4. PLAN          — Will create .claude/plan-booking-cancellation.md
  5. BRANCH        — alpha-feature/Booking_cancellation (from Development)
  6. IMPLEMENT     — Phases A-F with compile checks
  7. TEST          — Chained: /workflow:test (require_tests: true)
  8. PR            — Target: Development, Format: squash

GIT:
  Branch:          alpha-feature/Booking_cancellation
  Base:            Development
  Commit format:   feat(booking): ...
  PR target:       Development

FILES (estimated):
  Spec:            .workflows/specs/booking-cancellation.spec.md
  Decisions:       .workflows/specs/booking-cancellation.decisions.md
  Plan:            .claude/plan-booking-cancellation.md
  State:           .workflows/current-state.md
  Todo:            tasks/todo.md (updated)

GUARDS:
  Active:          yes (.claude/guards.yml found)
  Block patterns:  17 rules
  Protected paths: 11 rules

CHAINS:
  TEST → /workflow:test --coverage 90

CONFLICTS:
  None (no active workflow)

LEARNED PATTERNS:
  3 relevant patterns found in .workflows/learned/patterns.json
  "Delegator pattern for features with >3 state sources" (confidence: 0.8)

═══ End dry run. No changes made. ═══
```

## What Dry Run Does NOT Do

- Does NOT create any files
- Does NOT create any branches
- Does NOT run any git commands (except read-only: git branch, git status)
- Does NOT write to state files
- Does NOT invoke sub-agents
- Does NOT read Jira/Figma (even if flags provided — just notes the source)

## Integration with Workflow Engine

The workflow engine checks for `--dry-run` flag FIRST:
1. If `--dry-run` is present: execute dry-run skill, then STOP
2. If not: proceed with normal workflow execution
