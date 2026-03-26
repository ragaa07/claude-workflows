---
name: start
description: Entry point — shows available workflows, creates state file, then tells user to invoke the selected workflow skill.
---

# Start a Workflow

## Step 1: Setup

Run this command:

```bash
mkdir -p .workflows/history
```

Read `.claude/workflows.yml` for configuration.

## Step 2: Check for Active Workflows

Read the file `.workflows/current-state.md`. If it exists:

```
Active workflow detected:
   <workflow> — <feature> (at <phase>, updated <date>)

Options:
  1. Resume this workflow (run /resume)
  2. Pause it and start something new
  3. Abandon it and start fresh
```

- Resume → tell user to run `/resume`.
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

## Step 5: Create State File — ACTION REQUIRED

**5a.** Run this command to create the workflow directory:

```bash
mkdir -p .workflows/<feature>
```

**5b.** Use your **Write tool** to create the file `.workflows/current-state.md` with this exact content (fill in the actual values):

```
# Workflow State

- **workflow**: <selected-workflow>
- **feature**: <feature>
- **phase**: <first-phase-of-the-selected-workflow>
- **started**: <current ISO-8601 timestamp>
- **updated**: <current ISO-8601 timestamp>
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

**Verify**: Read back `.workflows/current-state.md` to confirm it was created. Do NOT proceed until this file exists.

## Step 6: Launch the Workflow

Tell the user which skill command to run next. Map the selection:

| Selection | Command |
|-----------|---------|
| 1. New Feature | `/new-feature <name>` |
| 2. Extend Feature | `/extend-feature <feature> <description>` |
| 3. New Project | `/new-project` |
| 4. Hotfix | `/hotfix <description>` |
| 5. CI Fix | `/ci-fix` |
| 6. Refactor | `/refactor <target>` |
| 7. Migrate | `/migrate <type>` |
| 8. Release | `/release <version>` |
| 9. Review | `/review <pr-number>` |
| 10. Brainstorm | `/brainstorm --topic "<topic>"` |
| 11. Test | `/test <target>` |

Tell the user:

```
State file created at .workflows/current-state.md
Workflow directory created at .workflows/<feature>/

To start the workflow, run:
  <command with their arguments>
```

**Do NOT attempt to read and execute the workflow skill yourself.** The user must invoke it as a slash command so Claude Code loads it as the active skill.
