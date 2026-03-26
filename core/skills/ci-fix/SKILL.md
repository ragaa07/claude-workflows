---
name: ci-fix
description: Diagnose and fix CI/CD pipeline failures automatically.
---

# CI Fix Workflow

## Command

`/ci-fix [--run <run-id>] [--pr <pr-number>]`

## BEFORE YOU START — Initialize State

Check if `.workflows/current-state.md` exists (it may have been created by `/start`).

**If it does NOT exist**, create it now. Run these commands and create the file:

```bash
mkdir -p .workflows/<description>
```

Then use your **Write tool** to create `.workflows/current-state.md`:

```
# Workflow State

- **workflow**: ci-fix
- **feature**: <description>
- **phase**: FETCH
- **started**: <current ISO-8601 timestamp>
- **updated**: <current ISO-8601 timestamp>
- **branch**:
- **output_dir**: .workflows/<description>/
- **retry_count**: 0

## Phase History

| Phase | Status | Timestamp | Output | Notes |
|-------|--------|-----------|--------|-------|
| FETCH | ACTIVE | <timestamp> | | Starting workflow |

## Phase Outputs

_Documents produced by each phase:_

## Context

_Key decisions and resume context:_
```

**If it already exists**, read it and continue from the current active phase.

**Verify**: Read `.workflows/current-state.md` to confirm it exists before proceeding.

---

## AFTER EVERY PHASE — You MUST Create Files

After completing each phase below, do these TWO things using your tools before moving on:

**Action 1 — Create the phase output file.** Use your **Write tool** to create the file at the path shown at the end of each phase (the `>> Write output to` line). Use this format:

```
# <Phase Name> — <Feature>

**Date**: <ISO-8601>
**Status**: Complete

## Summary
<1-3 sentences>

## Details
<Phase-specific content>

## Decisions
<Key decisions>

## Next Phase Input
<What next phase needs>
```

**Action 2 — Rewrite the state file.** Use your **Write tool** to REWRITE the entire `.workflows/current-state.md` file. Read the current content first, then write the full file back with these updates:
- Update `phase` and `updated` in the header
- In Phase History table: change the completed phase status to `COMPLETED`, add output filename, add new row for next phase as `ACTIVE`
- Under `## Phase Outputs`: add a link to the new output file
- Under `## Context`: add key decisions from this phase

**You must REWRITE the whole file — do not try to edit individual lines. Do NOT proceed to the next phase until both files are written.**

---

## Phases

### Phase 1: FETCH

Retrieve CI failure details.

1. If `--run <run-id>`: `gh run view <run-id> --log-failed`
2. If `--pr <pr-number>`: `gh pr checks <pr-number>` then `gh run view <failed-run-id> --log-failed`
3. If neither: `gh run list --status failure --limit 5` and ask user which to investigate
4. Capture full failure output for diagnosis

**>> Write output to**: `.workflows/<description>/01-fetch.md` — then update `.workflows/current-state.md` (see State Tracking above).

### Phase 2: DIAGNOSE

Classify failure by parsing log output. Read `.claude/rules/` for language-specific fix patterns.

| Category | Indicators |
|----------|-----------|
| **Compile Error** | `error:`, `FAILURE: Build failed`, `Cannot find symbol`, `Unresolved reference` |
| **Test Failure** | `FAILED`, `AssertionError`, `expected:`, `Tests run:.*Failures: [1-9]` |
| **Lint Violation** | `warning:`, `Lint found`, `ktlint`, `detekt`, `eslint` |
| **Dependency Issue** | `Could not resolve`, `Module not found`, `version conflict` |
| **Config Error** | `FileNotFoundException`, `missing secret`, `env variable not set`, `permission denied` |
| **Timeout** | `exceeded`, `timed out`, `deadline`, `cancelled` |

1. Parse failure log against indicators
2. Extract error message, file path, line number when available
3. Present diagnosis: category, root cause, affected files

**>> Write output to**: `.workflows/<description>/02-diagnose.md` — then update `.workflows/current-state.md`. (Category, root cause, affected files)

### Phase 3: FIX

Apply targeted fix based on diagnosis.

| Category | Approach |
|----------|----------|
| **Compile Error** | Read failing file at reported line, apply minimal fix (missing import, type mismatch, syntax) |
| **Test Failure** | Read test + source; if ambiguous whether test or source is wrong, ask user; default to fixing source |
| **Lint Violation** | Run auto-fix if available (`ktlint -F`, `eslint --fix`); otherwise manual correction |
| **Dependency Issue** | Check version mismatches in build files, update/add dependencies, verify resolution |
| **Config Error** | Identify missing config/secret/file; inform user (cannot auto-create secrets) |
| **Timeout** | Suggest optimizations (caching, parallelism, test splitting); provide recommendations |

**>> Write output to**: `.workflows/<description>/03-fix.md` — then update `.workflows/current-state.md`. (Changes made, approach)

### Phase 4: PUSH

Commit and push the fix.

1. Stage only changed files (never `git add -A`)
2. Commit: `fix(ci): <description of what was fixed>`
3. Push to current branch
4. Note open PR number if applicable

**>> Write output to**: `.workflows/<description>/04-push.md` — then update `.workflows/current-state.md`. (Commit hash, branch, PR reference)

### Phase 5: MONITOR

Verify the fix resolved the CI failure.

1. Provide watch command: `gh run watch`
2. Or check status: `gh run list --branch <current-branch> --limit 3`
3. **Retry loop**: If run fails again, loop back to Phase 1 with new run ID
   - Maximum 3 retry cycles -- if still failing, STOP and report to user
   - Increment `retry_count` in state file; append retry-suffixed output docs (e.g., `06-fetch-retry-1.md`)
   - Mark failed MONITOR phase as `RETRY` in Phase History

**>> Write output to**: `.workflows/<description>/05-monitor.md` — then update `.workflows/current-state.md`. (CI run status, pass/fail)

**After this final phase**: Move `.workflows/current-state.md` to `.workflows/history/<description>-<YYYY-MM-DD>.md`. Report completion.

## Notes

- Never push directly to main/production branches.
- If fix requires secrets or infrastructure changes, stop and inform user.
- For flaky tests, suggest retry annotation (e.g., `@RerunOnFailure`) but flag for user review.
- Always show diff before pushing.
