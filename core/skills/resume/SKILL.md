---
name: resume
description: Resume a paused or interrupted workflow with full context from phase outputs.
---

# Resume Workflow

> **You are the workflow orchestrator.** Read and follow `.claude/skills/_orchestration/RULES.md` for all orchestration rules.

## Step 1: Find Workflows

Check for state files:
1. **Active** (interrupted): `.workflows/current-state.md`
2. **Paused**: `.workflows/paused-*.md`

If nothing found: "No active or paused workflows. Use /start to begin."

## Step 2: Select Workflow

- **Only `current-state.md`** → use it directly (interrupted session).
- **Argument provided** (e.g., `/resume booking-cancellation`) → find `.workflows/paused-booking-cancellation.md`, rename to `.workflows/current-state.md`.
- **Multiple paused** → list and ask user to pick.

## Step 3: Load Context

1. Read `.workflows/current-state.md` — extract workflow, feature, phase, output_dir
2. Read ALL phase output documents from `.workflows/<feature>/` in order
3. This gives full context: what was analyzed, decided, planned

## Step 4: Report Status

```
Resuming: <workflow> — <feature>
Phase: <current-phase>
Last updated: <timestamp>

Completed phases:
  <name> — <note> (<output-file>)

Current: <active-phase>
Remaining: <list>

Context:
  <key decisions from state>
```

Ask: "Continue?"

## Step 5: Load and Continue

1. Read `.claude/skills/_orchestration/RULES.md` — follow all rules
2. If branch exists: `git checkout <branch>`
3. Read `.claude/skills/<workflow>/SKILL.md`
4. Find the current active phase section
5. Continue executing from there
6. After each phase: write output (Rule 1), update state (Rule 2), check chains (Rule 6)

## Edge Cases

- **Stale** (>7 days): warn, offer resume/restart/abandon.
- **Missing skill**: report error, offer to abandon.
- **Missing phase outputs**: continue without them, note the gap.
- **Conflict** (active + resuming paused): offer to pause active first.
