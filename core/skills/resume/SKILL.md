---
name: resume
description: Resume a paused or interrupted workflow. Reads state from .workflows/current-state.md, loads the correct skill, and continues from the last active phase. Use this after clearing context or starting a new session.
---

# Resume Workflow

## Command

```
/resume [workflow-name]
```

## Process

### Step 1: Detect Active Workflows

Check for workflow state files:

1. **Active workflow**: Read `.workflows/current-state.md`
2. **Paused workflows**: List all `.workflows/paused-*.md` files

If no state files exist:
```
No active or paused workflows found.
Start a new workflow with /new-feature, /refactor, /hotfix, etc.
```

### Step 2: Select Workflow (if multiple)

**If argument provided** (e.g., `/resume booking-cancellation`):
- Look for `.workflows/paused-booking-cancellation.md`
- Rename it to `.workflows/current-state.md`
- Add a `RESUMED` row to Phase History with timestamp

**If no argument and only `current-state.md` exists**:
- This is an interrupted workflow (session recovery) — use it directly

**If no argument and multiple paused workflows exist**:
```
Paused workflows:
  1. <name-1> — paused at <phase> (<date>)
  2. <name-2> — paused at <phase> (<date>)

Which workflow to resume? (1/2/...)
```

### Step 3: Parse State

Read the state file and extract:
- **workflow**: Which skill (e.g., `new-feature`, `refactor`)
- **feature**: The feature/target name
- **phase**: Current active phase (the row with `ACTIVE` status)
- **branch**: Git branch if created
- **Completed Steps**: What has been done (checkboxes)
- **Artifacts**: Links to specs, plans, etc.
- **Context**: Decisions, preferences, and what was happening

### Step 4: Report Status to User

```
Resuming: <workflow> — <feature>
Current phase: <phase>
Last updated: <timestamp>

Progress:
  ✅ <completed-phase-1>: <notes>
  ✅ <completed-phase-2>: <notes>
  🔄 <current-phase> (in progress)
  ⬜ <remaining-phase-1>
  ⬜ <remaining-phase-2>

Completed steps:
  - [x] <step-1>
  - [x] <step-2>
  - [ ] <next-step>

Artifacts:
  - <path-to-spec>
  - <path-to-plan>

Context:
  <key decisions and what was happening>
```

Ask: "Continue from **<phase>**?"

### Step 5: Load and Continue

1. If a branch exists, check it out: `git checkout <branch>`
2. Read the skill file: `.claude/skills/<workflow>/SKILL.md`
3. Navigate to the section for the **current active phase**
4. Read any referenced artifacts (spec, plan, decisions) for full context
5. If Completed Steps show partial progress within the phase, skip those steps
6. **Continue executing from the current position**
7. Resume normal state tracking — update `.workflows/current-state.md` at every subsequent phase transition

### Step 6: Handle Edge Cases

**Stale state** (last updated > 7 days ago):
```
⚠️ This workflow was last updated <N> days ago.
Options:
  1. Resume anyway
  2. Restart from current phase
  3. Abandon workflow
```

**Missing skill file** (skill not installed):
```
❌ Skill '<workflow>' not found in .claude/skills/.
Options:
  1. Abandon this workflow
  2. Install the skill and retry
```

**Corrupted state file** (missing required fields):
```
⚠️ State file appears corrupted (missing: <fields>).
Options:
  1. Attempt recovery from available data
  2. Abandon this workflow
```

**Existing active workflow** when resuming a paused one:
```
⚠️ There is already an active workflow: <name> at <phase>.
Options:
  1. Pause the active workflow first, then resume the selected one
  2. Abandon the active workflow, then resume
  3. Cancel (keep current active workflow)
```
