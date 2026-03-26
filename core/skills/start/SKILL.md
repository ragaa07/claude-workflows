---
name: start
description: Entry point for all workflows. Initializes state tracking, shows available workflows, and launches the selected one with full state management. Every phase produces an output document.
---

# Start a Workflow

> **You are the workflow orchestrator.** You manage state for every workflow. Individual workflow skills contain the phases and steps — you handle everything else: state files, phase transitions, phase output documents, and completion.

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

- If resume: read the state file, load `.claude/skills/<workflow>/SKILL.md`, find the current phase section, continue from there.
- If pause: rename to `.workflows/paused-<feature>.md`, continue to Step 3.
- If abandon: move to `.workflows/history/<feature>-<date>.md`, continue to Step 3.

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

Ask the user for the required input based on their selection:
- **New Feature**: "What's the feature name?" + optional: Jira ticket, Figma URL
- **Extend Feature**: "Which feature?" + "What to add?"
- **Hotfix**: "Describe the issue"
- **Refactor**: "What to refactor?" + "Goal?"
- **Migrate**: "What to migrate?" + "From/to?"
- **Release**: "What version?"
- **Review**: "Which PR or branch?"
- **CI Fix**: "Which CI job?"
- **Brainstorm**: "What topic?"
- **Test**: "What to test?"
- **New Project**: "Project path?"

## Step 5: Create Workflow Directory and State File

Create a directory for this workflow's phase outputs:

```bash
mkdir -p .workflows/<feature>
```

Write `.workflows/current-state.md`:

```markdown
# Workflow State

- **workflow**: <selected-workflow>
- **feature**: <feature>
- **phase**: <first-phase-of-workflow>
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

## Step 6: Load and Execute Workflow

Read `.claude/skills/<selected-workflow>/SKILL.md` and begin executing from Phase 1.

> **Build/Test Command Detection**: Before executing Phase 1, detect the project's build system and store the commands:
> - Gradle: `./gradlew build`, `./gradlew test`
> - npm/yarn: `npm run build`, `npm test`
> - Cargo: `cargo build`, `cargo test`
> - Poetry/pip: `python -m pytest`
>
> These are used wherever `<build-command>` or `<test-command>` appear in workflow phases.

---

## Orchestration Rules — Follow These AT ALL TIMES

### Rule 1: Every Phase Produces an Output Document

At the end of each phase, write a markdown file summarizing what was done and decided:

```
File: .workflows/<feature>/<phase-number>-<phase-name>.md
Example: .workflows/booking-cancellation/01-analyze.md
```

**Output document format:**

```markdown
# <Phase Name> — <Feature>

**Date**: <timestamp>
**Status**: Complete

## Summary
<1-3 sentences of what this phase accomplished>

## Details
<The actual output of the phase — analysis results, brainstorm options, plan, test results, etc.>

## Decisions Made
<Key decisions and rationale>

## Next Phase Input
<What the next phase needs to know from this one>
```

The content of `## Details` depends on the phase:
- **ANALYZE/GATHER/FETCH/DETECT/DIAGNOSE**: Architecture map, file list, current behavior
- **SPEC**: The full feature specification
- **BRAINSTORM**: Options explored, scoring, chosen approach
- **EXPLORE**: Discovery findings, landscape analysis (brainstorm)
- **EVALUATE**: Criteria scoring, comparison matrices (brainstorm)
- **RECOMMEND**: Final recommendation with rationale (brainstorm)
- **PLAN**: The implementation plan with phases and files
- **BRANCH**: Branch name, base branch
- **IMPLEMENT**: Files changed, commits made, issues encountered
- **EXECUTE**: Step-by-step migration execution log, per-step results (migrate)
- **CONTRACT**: Behavioral invariants, public API surface, threading/performance contracts (refactor)
- **DESIGN**: Target state architecture, migration step plan (refactor)
- **MIGRATE**: Per-step execution with compile/test results, rollback points (refactor)
- **TEST/VERIFY-COMPAT/REGRESSION-TEST**: Test results, coverage, pass/fail
- **WRITE**: Test code written, test file paths, framework setup (test)
- **REPORT**: Coverage summary, gap analysis, quality notes (test)
- **PR**: PR URL, summary, reviewers
- **CATEGORIZE**: File classification, review order, scope summary
- **CHECK**: Review findings by category, severity ratings
- **REVIEW**: Findings, severity, recommendations
- **VERIFY** (standalone): Verification results, contract checks, metrics comparison
- **CHERRY-PICK**: Cherry-pick plan, conflict preview, target branch
- **FIX**: Applied fix details, files changed, diff summary
- **PUSH**: Committed files, commit hash, branch pushed (ci-fix)
- **MONITOR**: CI run status, pass/fail result, retry count (ci-fix)
- **CHANGELOG**: Categorized commit history, generated changelog entry (release)
- **VERSION-BUMP**: Version file changes, old/new version values (release)
- **RELEASE-BRANCH**: Release branch name, cherry-picked commits (release)
- **TAG**: Tag name, GitHub release URL (release)

### Rule 2: Update State After Every Phase

Update `.workflows/current-state.md`:

1. Mark completed phase as `COMPLETED` with a note
2. Add the output document path to the `Output` column
3. Add the next phase as `ACTIVE`
4. Update `phase` and `updated` headers
5. Add a link under `## Phase Outputs`
6. Update `## Context` with key decisions
7. If the phase created a git branch, update the `branch` field in the state header

**Example state after 3 phases:**

```markdown
# Workflow State

- **workflow**: extend-feature
- **feature**: booking-cancellation
- **phase**: PLAN
- **started**: 2026-03-25T10:00:00Z
- **updated**: 2026-03-25T11:45:00Z
- **branch**:
- **output_dir**: .workflows/booking-cancellation/

## Phase History

| Phase | Status | Timestamp | Output | Notes |
|-------|--------|-----------|--------|-------|
| ANALYZE | COMPLETED | 2026-03-25T10:00:00Z | 01-analyze.md | Mapped feature architecture |
| BRAINSTORM | COMPLETED | 2026-03-25T11:00:00Z | 02-brainstorm.md | Chose event-driven approach |
| PLAN | ACTIVE | 2026-03-25T11:45:00Z | | Creating implementation plan |

**Phase statuses**: `ACTIVE`, `COMPLETED`, `SKIPPED`, `FAILED`, `RETRY`
- Use `FAILED` when a phase fails and cannot continue
- Use `RETRY` when a phase is being re-attempted (e.g., CI-fix MONITOR loop)

## Phase Outputs

- [01-analyze.md](.workflows/booking-cancellation/01-analyze.md) — Feature architecture analysis
- [02-brainstorm.md](.workflows/booking-cancellation/02-brainstorm.md) — SCAMPER analysis, chose Approach B

## Context

- Feature uses MVVM + Clean Architecture
- Chose event-driven approach (Approach B) over direct API call
- Cancellation requires reason selection (mandatory) + optional comment
```

### Rule 3: Skipping Phases

Read `.claude/workflows.yml`:
- `workflows.<skill>.require_brainstorm: false` OR `--skip-brainstorm` → skip BRAINSTORM
- `workflows.<skill>.require_tests: false` → skip TEST
- `workflows.<skill>.require_spec: false` → skip SPEC

When skipping: mark as `SKIPPED` in state, no output document needed, proceed to next phase.

### Rule 4: When Workflow Completes

1. Write the final phase output document
2. Mark final phase as `COMPLETED` in state
3. Move `.workflows/current-state.md` to `.workflows/history/<feature>-<YYYY-MM-DD>.md` (ISO-8601 date)
4. The `.workflows/<feature>/` directory with all phase outputs is preserved as the workflow archive
5. Report completion to the user

### Rule 5: Pausing

If the user says "pause" or needs to stop mid-workflow:
1. Write any in-progress work to the current phase output document (partial is fine)
2. Update state with current progress
3. Rename `.workflows/current-state.md` to `.workflows/paused-<feature>.md`
