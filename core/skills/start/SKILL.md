---
name: start
description: Entry point for all workflows. Shows available workflows, initializes state, launches the selected one.
---

# Start a Workflow

> **You are the workflow orchestrator.** You manage state, phase transitions, and output documents. Individual workflow skills define the phases — you handle everything else. Read and follow `.claude/skills/_orchestration/RULES.md` for all orchestration rules.

## Step 1: Setup

```bash
mkdir -p .workflows/history
```

Read `.claude/workflows.yml` for configuration.

## Step 2: Check for Active Workflows

Read `.workflows/current-state.md`. If it exists:

```
Active workflow detected:
   <workflow> — <feature> (at <phase>, updated <date>)

Options:
  1. Resume this workflow
  2. Pause it and start something new
  3. Abandon it and start fresh
```

- Resume → load state, load skill, continue from current phase.
- Pause → rename to `.workflows/paused-<feature>.md`, continue to Step 3.
- Abandon → move to `.workflows/history/<feature>-<date>.md`, continue to Step 3.

Also list any `.workflows/paused-*.md` files as paused workflows.

## Step 3: Show Workflow Menu

```
What would you like to do?

── Build ──────────────────────────────
  1. New Feature      — spec, brainstorm, plan, implement, test, PR
  2. Extend Feature   — add capabilities to an existing feature
  3. New Project      — bootstrap a new project

── Fix ────────────────────────────────
  4. Hotfix           — emergency production fix
  5. CI Fix           — fix failing CI/CD pipeline

── Improve ────────────────────────────
  6. Refactor         — restructure code safely
  7. Migrate          — migrate dependencies, APIs, patterns

── Ship ───────────────────────────────
  8. Release          — version bump, changelog, tag
  9. Review           — systematic PR code review

── Think ──────────────────────────────
  10. Brainstorm      — explore approaches
  11. Test            — generate tests

Pick a number (1-11):
```

## Step 4: Gather Arguments

Ask for required input based on selection:
- **New Feature**: feature name + optional: ticket ID, design URL, spec path
- **Extend Feature**: which feature + what to add
- **Hotfix**: describe the issue
- **Refactor**: target + goal
- **Migrate**: what to migrate + from/to
- **Release**: version number
- **Review**: PR number or branch
- **CI Fix**: which CI job or PR
- **Brainstorm**: topic
- **Test**: target to test
- **New Project**: project path

## Step 5: Create State

```bash
mkdir -p .workflows/<feature>
```

Write `.workflows/current-state.md`:

```markdown
# Workflow State

- **workflow**: <selected-workflow>
- **feature**: <feature>
- **phase**: <first-phase>
- **started**: <ISO-8601>
- **updated**: <ISO-8601>
- **branch**:
- **output_dir**: .workflows/<feature>/
- **retry_count**: 0

## Phase History

| Phase | Status | Timestamp | Output | Notes |
|-------|--------|-----------|--------|-------|
| <first-phase> | ACTIVE | <timestamp> | | Starting workflow |

## Phase Outputs

_Documents produced by each phase:_

## Context

_Key decisions and resume context:_
```

## Step 6: Load and Execute

1. Read `.claude/skills/_orchestration/RULES.md` — follow all rules throughout execution
2. Detect build/test commands per Rule 5
3. Read `.claude/skills/<selected-workflow>/SKILL.md`
4. Begin executing from Phase 1
5. After each phase: write output document (Rule 1), update state (Rule 2), check chains (Rule 6)
6. On completion: follow Rule 7
