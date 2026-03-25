---
name: workflow-engine
description: Meta-orchestrator that routes /workflow:* commands, manages workflow state, handles session recovery, and enforces the state machine.
---

# Workflow Engine

The workflow engine is the central orchestrator for all `/workflow:*` commands. It manages state, resolves skills, handles session recovery, and enforces phase transitions.

## Command Routing

When the user invokes any `/workflow:*` command:

1. Parse the command: `/workflow:<command> [args...]`
2. Check if `<command>` is a utility command (status, resume, pause, abandon, history)
3. Check if `<command>` is an alias defined in `workflows.yml` under `skills.aliases`
4. Resolve to a workflow skill (e.g., `new-feature`, `hotfix`, `refactor`)
5. Invoke the resolved skill, passing workflow state and args

### Utility Commands

| Command | Action |
|---------|--------|
| `/workflow:status` | Display current workflow state from `.workflows/current-state.md` |
| `/workflow:resume` | Resume a paused workflow from `.workflows/paused-<name>.md` |
| `/workflow:pause` | Pause the active workflow (rename state file to `paused-<name>.md`) |
| `/workflow:abandon` | Archive and discard the active workflow |
| `/workflow:history` | List completed workflows from `.workflows/history/` |

## Reading workflows.yml

The configuration file lives at `.claude/workflows.yml` in the project root. Read and parse it at the start of every workflow operation.

### Resolution Order

1. **Project config**: `.claude/workflows.yml` (user's overrides)
2. **Core defaults**: `core/config/defaults.yml` (shipped defaults)
3. **Hardcoded fallbacks**: Use sensible defaults if neither file exists

For each config key, project config takes precedence over core defaults. Merge deeply -- do not replace entire sections.

### Alias Resolution

Read `skills.aliases` from the config:

```yaml
skills:
  aliases:
    build: "new-feature"
    fix: "hotfix"
```

When the user runs `/workflow:build`, resolve it to `/workflow:new-feature` before routing.

## State Machine

Every workflow follows this state machine. Transitions MUST be sequential -- no skipping phases.

```
IDLE → SPEC → BRAINSTORM → PLAN → BRANCH → IMPLEMENT → TEST → PR → DONE
```

### Phase Definitions

| Phase | Description | Entry Condition |
|-------|-------------|-----------------|
| `IDLE` | No active workflow | Default state |
| `SPEC` | Writing the feature specification | User starts a workflow |
| `BRAINSTORM` | Exploring approaches and trade-offs | Spec document exists (skip if `require_brainstorm: false`) |
| `PLAN` | Creating implementation plan with tasks | Brainstorm complete or skipped |
| `BRANCH` | Creating git branch | Plan exists in `tasks/todo.md` |
| `IMPLEMENT` | Writing code | Branch created |
| `TEST` | Running and writing tests | Implementation complete (skip if `require_tests: false`) |
| `PR` | Creating pull request | Tests pass or skipped |
| `DONE` | Workflow complete | PR created |

### Transition Validation

Before transitioning to the next phase:

1. Verify the current phase's exit criteria are met
2. Check if the next phase should be skipped (based on workflow config)
3. Update the state file with new phase, timestamp, and notes
4. If a phase is skipped, record it as `SKIPPED` in the state file

## State File Management

### Creating State: `.workflows/current-state.md`

When a workflow starts, create this file:

```markdown
# Workflow State

- **workflow**: new-feature
- **feature**: <feature-name>
- **phase**: SPEC
- **started**: <ISO-8601 timestamp>
- **updated**: <ISO-8601 timestamp>
- **branch**: <empty until BRANCH phase>

## Phase History

| Phase | Status | Timestamp | Notes |
|-------|--------|-----------|-------|
| SPEC | ACTIVE | <timestamp> | |

## Context

<Any relevant context, links, or references>
```

### Updating State

At every phase transition:

1. Set the previous phase status to `COMPLETED` or `SKIPPED`
2. Add the new phase row with status `ACTIVE`
3. Update the `phase` and `updated` fields in the header
4. Write a brief note about what was accomplished

### Pausing a Workflow

When `/workflow:pause` is invoked:

1. Read `.workflows/current-state.md`
2. Add a `PAUSED` entry to the phase history with timestamp
3. Rename the file to `.workflows/paused-<feature-name>.md`
4. Confirm to the user with the paused state summary

### Resuming a Workflow

When `/workflow:resume [name]` is invoked:

1. If `name` is provided, look for `.workflows/paused-<name>.md`
2. If `name` is omitted, list all paused workflows and ask the user to pick
3. Rename the paused file back to `.workflows/current-state.md`
4. Add a `RESUMED` entry to the phase history
5. Report the current phase and what to do next

### Abandoning a Workflow

When `/workflow:abandon` is invoked:

1. Confirm with the user (this is destructive)
2. Move `.workflows/current-state.md` to `.workflows/history/<feature-name>-<timestamp>.md`
3. Mark final phase as `ABANDONED` in the history
4. Report what was abandoned

### Archiving on Completion

When a workflow reaches `DONE`:

1. Mark final phase as `COMPLETED`
2. Move to `.workflows/history/<feature-name>-<timestamp>.md`
3. Delete `.workflows/current-state.md`
4. Keep history entries capped at `state.max_history` from config (default 50)

## Session Recovery Protocol

At the START of every session (before any work), check for active workflows:

1. Check if `.workflows/current-state.md` exists
2. If it exists, read it and report to the user:
   ```
   Active workflow detected:
   - Workflow: <workflow-type>
   - Feature: <feature-name>
   - Current phase: <phase>
   - Last updated: <timestamp>

   Options:
   1. Resume (continue from current phase)
   2. Restart (abandon and start fresh)
   3. Abandon (discard workflow)
   ```
3. If no active workflow, check for paused workflows in `.workflows/paused-*.md`
4. If paused workflows exist, mention them:
   ```
   No active workflow. Paused workflows available:
   - <name-1> (paused at <phase>)
   - <name-2> (paused at <phase>)
   Use /workflow:resume <name> to continue.
   ```

## Skill Resolution Order

When routing to a workflow skill:

1. **Project skills**: `.claude/skills/<skill-name>/SKILL.md` (project-specific overrides)
2. **Core skills**: `core/skills/<skill-name>/SKILL.md` (shipped with claude-workflows)
3. **Fallback**: Report that the skill is not found

If a skill is listed in `skills.disabled` in the config, refuse to invoke it and inform the user.

## Directory Structure

Ensure these directories exist before writing files:

```
.workflows/                    # State files
.workflows/history/            # Completed/abandoned workflow archives
.workflows/specs/              # Spec and decision documents
tasks/                         # Todo and lessons files
```

## Error Handling

- If `workflows.yml` is missing, use defaults and warn the user
- If state file is corrupted, offer to reset or abandon
- If a phase transition is invalid (e.g., jumping from SPEC to IMPLEMENT), refuse and explain the required sequence
- If the user tries to start a workflow while one is active, offer to pause the current one first
