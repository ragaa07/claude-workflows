---
name: ci-fix
description: Diagnose and fix CI/CD pipeline failures automatically.
rules: [0, 1, 3, 4, 5, 6, 7, 10, 11, 12, 17]
---

# CI Fix Workflow

## Command

`/ci-fix [--run <run-id>] [--pr <pr-number>]`

**Description for output paths**: Auto-generate `<description>` from the CI failure (e.g., `fix-compile-error-UserService` or `fix-test-failure-pr-42`). Use kebab-case, max 40 chars.

---

> **Protocol**: Follow the execution protocol injected at session start.
> Create `.workflows/current-state.md` before Phase 1. Write output + update state after EVERY phase. Never skip phases unless config allows.

## Phases

### Phase 1: FETCH

Retrieve CI failure details.

1. If `--run <run-id>`: `gh run view <run-id> --log-failed`
2. If `--pr <pr-number>`: `gh pr checks <pr-number>` then `gh run view <failed-run-id> --log-failed`
3. If neither: `gh run list --status failure --limit 5` and ask user which to investigate
4. Capture full failure output for diagnosis

**>> Write output to**: `.workflows/<description>/01-fetch.md`

### Phase 2: DIAGNOSE

Classify failure by parsing log output. Read `<plugin-root>/rules/` for language-specific fix patterns.

| Category | Indicators |
|----------|-----------|
| **Compile Error** | `error:`, `FAILURE: Build failed`, `Cannot find symbol`, `Unresolved reference` |
| **Test Failure** | `FAILED`, `AssertionError`, `expected:`, `Tests run:.*Failures: [1-9]` |
| **Lint Violation** | `warning:`, `Lint found`, `ktlint`, `detekt`, `eslint` |
| **Dependency Issue** | `Could not resolve`, `Module not found`, `version conflict` |
| **Config Error** | `FileNotFoundException`, `missing secret`, `env variable not set`, `permission denied` |
| **Timeout** | `exceeded`, `timed out`, `deadline`, `cancelled` |
| **Flaky/Intermittent** | Passed locally, `flaky`, sporadic failures, inconsistent results |

1. Parse failure log against indicators
2. Extract error message, file path, line number when available
3. Present diagnosis: category, root cause, affected files

**>> Write output to**: `.workflows/<description>/02-diagnose.md` (category, root cause, affected files)

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

**>> Write output to**: `.workflows/<description>/03-fix.md` (changes made, approach)

### Phase 4: PUSH

Commit and push the fix.

1. Stage only changed files (never `git add -A`)
2. Commit: `fix(ci): <description of what was fixed>`
3. Push to current branch
4. Note open PR number if applicable

**>> Write output to**: `.workflows/<description>/04-push.md` (commit hash, branch, PR)

### Phase 5: MONITOR

Verify the fix resolved the CI failure.

1. Provide watch command: `gh run watch`
2. Or check status: `gh run list --branch <current-branch> --limit 3`
3. **Retry on failure**: If CI fails again, re-read the new failure log and apply a targeted fix. Commit and push. Check status again. Max 3 total fix attempts across the workflow. After 3, STOP and present the failure details to the user.

**>> Write output to**: `.workflows/<description>/05-monitor.md` (CI run status, pass/fail)


