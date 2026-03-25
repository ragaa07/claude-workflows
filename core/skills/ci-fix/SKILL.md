---
name: ci-fix
description: Diagnose and fix CI/CD pipeline failures automatically.
---

# CI Fix Workflow

## Command

`/workflow:ci-fix [--run <run-id>] [--pr <pr-number>]`

## Phases

### Phase 1: FETCH

Retrieve CI failure details.

1. If `--run <run-id>` is provided:
   - `gh run view <run-id> --log-failed`
2. If `--pr <pr-number>` is provided:
   - `gh pr checks <pr-number>` to find failed checks
   - `gh run view <failed-run-id> --log-failed` for each failure
3. If neither is provided:
   - `gh run list --status failure --limit 5` to show recent failures
   - Ask the user which run to investigate
4. Capture the full failure output for diagnosis

### Phase 2: DIAGNOSE

Classify the failure type by parsing the log output.

| Category | Indicators |
|----------|-----------|
| **Compile Error** | `error:`, `FAILURE: Build failed`, `Cannot find symbol`, `Unresolved reference` |
| **Test Failure** | `FAILED`, `AssertionError`, `expected:`, `Tests run:.*Failures: [1-9]` |
| **Lint Violation** | `warning:`, `Lint found`, `ktlint`, `detekt`, `eslint` |
| **Dependency Issue** | `Could not resolve`, `Module not found`, `No matching variant`, `version conflict` |
| **Config Error** | `FileNotFoundException`, `missing secret`, `env variable not set`, `permission denied` |
| **Timeout** | `exceeded`, `timed out`, `deadline`, `cancelled` |

1. Parse the failure log against the indicators above
2. Extract the specific error message, file path, and line number when available
3. Present the diagnosis to the user:
   - Failure category
   - Root cause summary
   - Affected file(s) and line(s)

### Phase 3: FIX

Apply a targeted fix based on the diagnosis.

**Compile Error:**
- Read the failing file at the reported line
- Identify the issue (missing import, type mismatch, syntax error)
- Apply the minimal fix

**Test Failure:**
- Read the test file and the source file under test
- Determine if the test expectation is wrong or the source code has a bug
- Ask user which to fix if ambiguous; default to fixing source code

**Lint Violation:**
- Run the linter's auto-fix if available (e.g., `ktlint -F`, `eslint --fix`)
- For violations without auto-fix, apply manual corrections

**Dependency Issue:**
- Check for version mismatches in build files
- Update dependency versions or add missing dependencies
- Run dependency resolution to verify

**Config Error:**
- Identify the missing config, secret, or file
- Suggest the fix (cannot auto-create secrets — inform the user)

**Timeout:**
- Identify slow steps in the CI config
- Suggest optimizations (caching, parallelism, test splitting)
- Cannot auto-fix most timeouts — provide recommendations

### Phase 4: PUSH

Commit and push the fix.

1. Stage only the changed files (never `git add -A`)
2. Commit with message: `fix(ci): <description of what was fixed>`
3. Push to the current branch
4. If the branch has an open PR, note the PR number

### Phase 5: MONITOR

Verify the fix resolved the CI failure.

1. Provide the command to watch the new run:
   ```
   gh run watch
   ```
2. Or check status:
   ```
   gh run list --branch <current-branch> --limit 3
   ```
3. If the run fails again, loop back to Phase 1: FETCH with the new run ID

## Notes

- Never push directly to main/production branches.
- If the fix requires secrets or infrastructure changes, stop and inform the user.
- For flaky tests, suggest adding `@RerunOnFailure` or equivalent, but flag for user review.
- Always show the diff before pushing.
