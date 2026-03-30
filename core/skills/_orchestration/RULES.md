# Orchestration Rules

> These rules apply to EVERY workflow execution.
>
> **Selective loading**: If the active skill's frontmatter includes a `rules` list (e.g., `rules: [0, 1, 2, 5, 6]`), only follow those numbered rules. Otherwise, follow all rules.

## Rule 0: State Initialization

Before starting any workflow, check if `.workflows/current-state.md` exists.

**If it does NOT exist**, create it:
1. `mkdir -p .workflows/<feature-name>`
2. Use your **Write tool** to create `.workflows/current-state.md` with YAML frontmatter + markdown body:
```
---
workflow: <workflow-name>
feature: <feature-name>
phase: <first-phase>
started: <ISO-8601>
updated: <ISO-8601>
branch:
output_dir: .workflows/<feature-name>/
retry_count: 0
---
## Phase History
| Phase | Status | Output | Notes |
|-------|--------|--------|-------|
| <first-phase> | ACTIVE | | Starting workflow |

## Context
_Key decisions and resume context:_
```

**If it already exists**, read it and continue from the current active phase.
**Verify**: Read `.workflows/current-state.md` to confirm it exists before proceeding.

## Rule 1: Phase Output Protocol

After completing each phase, do TWO things before moving on:

**Action 1 -- Write the phase output file** at the path shown in each phase's `>> Write output to` line:
```
# <Phase Name> -- <Feature>
**Date**: <ISO-8601> | **Status**: Complete
## Summary
<1-3 sentences>
## Details
<Phase-specific content -- the individual skill defines what each phase produces>
## Decisions
<Key decisions>
## Next Phase Input
<What next phase needs>
```

**Action 2 -- Update the state file.** Read `.workflows/current-state.md`, then rewrite:
- **Frontmatter**: set `phase` to next phase, set `updated` to current timestamp
- **Phase History table**: mark completed phase `COMPLETED`, fill Output column, add new `ACTIVE` row
- **Context section**: append key decisions as bullet points
- **branch field**: update if a git branch was created

**Do NOT proceed to the next phase until both files are written.**

**Action 3 — Append context snapshot.** Append to `.workflows/<feature>/CONTEXT.md`:
```
## After <PHASE-NAME>
- <3-5 bullet points: key decisions, constraints, risks from this phase>
```
Before starting a phase, read `CONTEXT.md` to reload prior decisions (critical for long workflows that span context compressions).

## Rule 2: Skipping Phases

Read `.claude/workflows.yml` -> `workflows.<skill>`:
- `require_brainstorm: false` OR `--skip-brainstorm` -> skip BRAINSTORM
- `require_tests: false` -> skip TEST
- `require_spec: false` -> skip SPEC

**Precedence**: Command-line flags override config. When skipping: mark `SKIPPED` in state, no output document, proceed to next phase.

## Rule 3: Quality Gate -- Rules & Reviews

**Before writing code** in any implementation phase:
1. Read `.claude/rules/` files matching `project.language` from `.claude/workflows.yml`
2. Follow every DO/DON'T while implementing

**Before creating a PR** (every workflow that ends with PR):
1. Load `.claude/reviews/general-checklist.md` + language-specific checklist + team checklist (if exists)
2. Self-check all changes against High/Critical items
3. Fix any violations before creating the PR

## Rule 4: Build/Test Command Detection

Before the first implementation phase, detect build system from marker files:

| Marker | System | Marker | System |
|--------|--------|--------|--------|
| `build.gradle(.kts)` | Gradle | `go.mod` | go |
| `package.json` | npm | `pyproject.toml`/`setup.py` | python |
| `Cargo.toml` | cargo | `Package.swift` | swift |
| `CMakeLists.txt` | cmake | | |

Store detected commands for use wherever `<build-command>` or `<test-command>` appear.

## Rule 5: Workflow Completion

1. Write final phase output, mark as `COMPLETED`
2. Move `.workflows/current-state.md` to `.workflows/history/<feature>-<YYYY-MM-DD>.md` (append `-<HHMM>` if exists)
3. Preserve `.workflows/<feature>/` directory as archive
4. Report completion summary to user

## Rule 6: Pausing

If user says "pause" or needs to stop:
1. Write in-progress work to current phase output (partial is fine)
2. Update state with current progress
3. Rename `.workflows/current-state.md` to `.workflows/paused-<feature>.md`

## Rule 7: Error Recovery & REPLAN

| Trigger | Action |
|---------|--------|
| Compilation fails 3+ times in a phase | REPLAN |
| Plan step is impossible | STOP, document, REPLAN |
| User requests change mid-implementation | STOP, REPLAN |

**REPLAN protocol**: Stop, document failure under "## Replan Notes" in plan file, re-analyze remaining phases, get user approval, resume.

**REPLAN limit**: Max 2 per workflow (tracked via `retry_count`). After 2, STOP and present options: (a) continue with manual guidance, (b) abandon workflow, (c) split into smaller scope. Each REPLAN resets the 3-failure counter.

## Rule 8: Common Error Resolutions

| Error | Resolution |
|-------|------------|
| `gh` CLI not authenticated | Tell user: `gh auth login` |
| Dirty working tree | Tell user: stash or commit first |
| Branch already exists | Ask user: switch, rename, or delete |
| Config file missing | Guide user: `/new-project` or `npx claude-dev-workflows init` |

## Rule 9: Skill Composition

When a workflow phase requires another skill's logic:
1. **Execute inline**: Read the target skill and execute its steps as sub-steps within the current phase
2. **Output routing**: Write to the CURRENT workflow's output directory
3. **State**: Do NOT create a separate state file -- track as part of current phase
4. **Completion**: Continue with parent workflow's next phase

## Rule 10: Phase Statuses

| Status | Meaning |
|--------|---------|
| `ACTIVE` | Currently in progress |
| `COMPLETED` | Finished successfully |
| `SKIPPED` | Skipped per config or flag |
| `FAILED` | Failed, cannot continue |
| `RETRY` | Being re-attempted |

## Rule 11: Mid-Phase Checkpoints

For multi-step phases (IMPLEMENT, MIGRATE, EXECUTE), append after each step:
```
### Checkpoint: Step N complete
- Files changed: [list]
- Commit: [hash]
- Status: pass/fail
```
If resuming mid-phase, read the last checkpoint and continue from the next step.

## Rule 12: Telemetry (Optional)

If `telemetry.enabled` is `true` in `.claude/workflows.yml`, append to `.workflows/telemetry.jsonl` after each phase:
```json
{"ts":"<ISO-8601>","workflow":"<name>","feature":"<feature>","phase":"<phase>","status":"COMPLETED","duration_ms":<ms-since-phase-start>,"files_changed":<count>,"replan":false}
```
Never block workflow execution on telemetry failures.

## Rule 13: Focused Quality Gate

When running the pre-PR quality gate (Rule 3), focus on changed files:
1. `git diff --name-only <base>..HEAD` to identify changed files
2. Categorize and prioritize checklist items by file type:
   - Security (auth, crypto, env) -> all security checks at Critical priority
   - Data (models, DB) -> data integrity, injection checks
   - UI -> XSS, accessibility, performance
   - Test -> test quality checks only
3. **Always run**: architecture, naming, complexity checks. **Skip** categories with zero changed files.

## Rule 14: Dry Run

If `--dry-run` flag is present on any workflow command:
1. Preview the execution plan: phases, branch name, output files, config flags
2. No state files created, no git commands (except read-only), no file writes
3. Display the plan summary, then **STOP**

## Rule 15: Workflow Chaining

After completing a workflow (Rule 5), check `.claude/workflows.yml` → `chains`:
1. If a chain matches the completed workflow, ask: "Chain detected: run `<next-command>` next? (y/n)"
2. On yes: preserve the `.workflows/<feature>/` context directory and launch the chained workflow
3. On no: complete normally
4. Chain config format: `<trigger-workflow>: <next-command>`

## Rule 16: Knowledge Extraction

After completing a workflow (Rule 5), if the workflow included a BRAINSTORM or PLAN phase, extract decisions to `.workflows/knowledge.jsonl`:

```json
{"date":"<ISO-8601>","workflow":"<type>","feature":"<name>","approach":"<chosen-approach>","constraints":["<constraint>"],"outcome":"success","files_touched":0,"duration_phases":0}
```

During future BRAINSTORM phases, read `.workflows/knowledge.jsonl` and surface relevant past decisions:
- Match by similar constraints or approach keywords
- Present as: "Similar past decision: <feature> used <approach> for <constraints> -- succeeded/failed"
- Maximum 3 suggestions to avoid overwhelming the user
