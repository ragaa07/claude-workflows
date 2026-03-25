---
name: resume
description: Resume a paused or interrupted workflow. Reads state and phase outputs, loads the correct skill, and continues from the last active phase with full state management.
---

# Resume Workflow

> **You are the workflow orchestrator.** You manage state for every workflow. Individual workflow skills contain the phases and steps — you handle everything else: state files, phase transitions, phase output documents, and completion.

## Step 1: Find Workflows to Resume

Check for state files:

1. **Active** (interrupted): `.workflows/current-state.md`
2. **Paused**: `.workflows/paused-*.md`

If nothing found:
```
No active or paused workflows found.
Use /start to begin a new workflow.
```

## Step 2: Select Workflow

**If only `current-state.md` exists** — use it directly (interrupted session).

**If argument provided** (e.g., `/resume booking-cancellation`):
- Find `.workflows/paused-booking-cancellation.md`
- Rename to `.workflows/current-state.md`
- Add `RESUMED` row to Phase History

**If multiple paused workflows**:
```
Paused workflows:
  1. <name-1> — at <phase> (paused <date>)
  2. <name-2> — at <phase> (paused <date>)

Which one? (1/2/...)
```

## Step 3: Load Context from Phase Outputs

1. Read `.workflows/current-state.md` — extract workflow name, feature, current phase, output_dir
2. Read ALL phase output documents from `.workflows/<feature>/` in order
3. This gives you the full context: what was analyzed, what was decided, what was planned

## Step 4: Report Status

```
Resuming: <workflow> — <feature>
Phase: <current-phase>
Last updated: <timestamp>

Completed phases:
  <for each COMPLETED phase, show name + one-line note + output file>

Current: <active-phase> (in progress)

Remaining: <list of remaining phases>

Context:
  <key decisions from state file>
```

Ask: "Continue?"

## Step 5: Load and Continue

1. If branch exists: `git checkout <branch>`
2. Read `.claude/skills/<workflow>/SKILL.md`
3. Find the section for the **current active phase**
4. Continue executing from there

---

## Orchestration Rules — Follow These AT ALL TIMES

### Rule 1: Every Phase Produces an Output Document

At the end of each phase, write a markdown file:

```
File: .workflows/<feature>/<phase-number>-<phase-name>.md
```

**Format:**

```markdown
# <Phase Name> — <Feature>

**Date**: <timestamp>
**Status**: Complete

## Summary
<1-3 sentences>

## Details
<Phase output — analysis, spec, brainstorm, plan, test results, etc.>

## Decisions Made
<Key decisions and rationale>

## Next Phase Input
<What the next phase needs to know>
```

### Rule 2: Update State After Every Phase

Update `.workflows/current-state.md`:
1. Mark completed phase as `COMPLETED` with a note
2. Add output document path to the `Output` column
3. Add next phase as `ACTIVE`
4. Update `phase` and `updated` headers
5. Add link under `## Phase Outputs`
6. Update `## Context` with key decisions

### Rule 3: Skipping Phases

Read `.claude/workflows.yml`:
- `require_brainstorm: false` OR `--skip-brainstorm` → skip BRAINSTORM, mark `SKIPPED`
- `require_tests: false` → skip TEST, mark `SKIPPED`
- `require_spec: false` → skip SPEC, mark `SKIPPED`

### Rule 4: When Workflow Completes

1. Write final phase output document
2. Mark final phase `COMPLETED`
3. Move state to `.workflows/history/<feature>-<date>.md`
4. Phase outputs in `.workflows/<feature>/` preserved as archive
5. Report completion

### Rule 5: Pausing

If user says "pause":
1. Write in-progress work to current phase output (partial is fine)
2. Update state
3. Rename to `.workflows/paused-<feature>.md`

## Edge Cases

**Stale** (>7 days): Warn user, offer resume/restart/abandon.
**Missing skill**: Report error, offer to abandon.
**Missing phase outputs**: Continue without them, note the gap.
**Conflict** (active + resuming paused): Offer to pause active first.
