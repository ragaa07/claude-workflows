---
name: hotfix
description: Emergency hotfix — diagnose, minimal fix, regression test, PR, cherry-pick plan.
---

# Hotfix Workflow

`/hotfix <description> [--crashlytics <issue-id>] [--log <path>] [--branch <production-branch>]`

Emergency fix for production issues. Optimized for **SPEED**. No brainstorming. No spec. Fix the crash, nothing else.

**Phases**: DIAGNOSE -> FIX -> REGRESSION-TEST -> PR -> CHERRY-PICK

**Prerequisites**: Clean git tree. Production branch identifiable from `.claude/workflows.yml` or `--branch`.

## BEFORE YOU START — Initialize State

Check if `.workflows/current-state.md` exists (it may have been created by `/start`).

**If it does NOT exist**, create it now. Run these commands and create the file:

```bash
mkdir -p .workflows/<description>
```

Then use your **Write tool** to create `.workflows/current-state.md`:

```
# Workflow State

- **workflow**: hotfix
- **feature**: <description>
- **phase**: DIAGNOSE
- **started**: <current ISO-8601 timestamp>
- **updated**: <current ISO-8601 timestamp>
- **branch**:
- **output_dir**: .workflows/<description>/
- **retry_count**: 0

## Phase History

| Phase | Status | Timestamp | Output | Notes |
|-------|--------|-----------|--------|-------|
| DIAGNOSE | ACTIVE | <timestamp> | | Starting workflow |

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

### Phase 1: DIAGNOSE

Identify the exact crash cause in minimum time.

1. **Gather crash data**:
   - Crashlytics (`--crashlytics`): call `mcp__firebase__crashlytics_get_issue` and `mcp__firebase__crashlytics_list_events`. Extract exception type, stack trace, file/line, frequency, version.
   - Log file (`--log`): search for exception lines, stack traces, fatal markers.
   - Description: parse error type, repro steps, affected feature.
2. **Locate crash site**: from the stack trace, find exact file and line. Read the method.
3. **Identify root cause** using this table:

| Crash Type | What to Look For |
|---|---|
| Null/undefined reference | What is null? Unsafe access on nullable/optional? |
| Type error / cast failure | What cast failed? Type mismatch from API change? |
| Index out of bounds | What collection/index? Race condition on size? |
| Invalid state | What state is invalid? Missing initialization? |
| Thread/async issue | Blocking main thread? Wrong execution context? |
| Timeout / hang | What operation is slow? Missing timeout? |

4. **Assess blast radius**: search codebase for the same pattern. Check affected code paths.
5. **Decide**: high confidence — proceed. Low confidence — ask user. Never guess at production fixes.

Document: `"Root cause: <X> is null/invalid when <Y> because <Z>"`

**>> Write output to**: `.workflows/<description>/01-diagnose.md` — then update `.workflows/current-state.md` (see State Tracking above). (Root cause, crash site, blast radius)

---

### Phase 2: FIX

Apply the absolute minimum change.

**Branch**: `git checkout $PROD_BRANCH && git pull && git checkout -b hotfix/<short-description>`

**Rules**:
1. ONE change only — fix the crash, nothing else
2. No refactoring, no features, no dependency updates
3. Match existing style — do not reformat
4. Lines changed: ideally 1-5, **maximum 15**

| Crash Type | Fix Pattern |
|---|---|
| Null/undefined reference | Add null check, safe access, or default value |
| Type error / cast failure | Add type validation or safe conversion |
| Index out of bounds | Add bounds check |
| Invalid state | Add state validation |
| Thread/async issue | Move to correct thread/context |
| Timeout / hang | Add timeout, move to background |

Check `.claude/rules/` for project-specific conventions. Apply them.

**Build check**: run project build command. Fix compilation errors if needed (still minimal). Max 3 attempts.

**Sanity review** (`git diff`): only crash site changed, no unrelated edits, fix is defensive, lines within limit.

**Commit**: `fix: <short description>` with root cause and crash location in body.

**>> Write output to**: `.workflows/<description>/02-fix.md` — then update `.workflows/current-state.md`. (Changes made, diff summary)

---

### Phase 3: REGRESSION-TEST

**MANDATORY — cannot be skipped regardless of `require_tests` config.**

1. **Write regression test** reproducing the exact crash scenario:
   ```
   // Test: should not crash when <crash condition>
   // Given: <state that caused the crash>
   // When: <action that triggered it>
   // Then: <expected safe behavior>
   ```
   Test MUST fail without the fix and pass with it. Use project's test framework. Check `.claude/rules/` for test patterns.

2. **Run tests**: affected module first, then full suite. Related failures — adjust fix. Unrelated — note but don't block.

3. **Commit**: `test: add regression test for <crash description>`

**>> Write output to**: `.workflows/<description>/03-regression-test.md` — then update `.workflows/current-state.md`. (Test results)

---

### Phase 4: PR

Push and create PR to production branch.

```bash
git push -u origin hotfix/<short-description>
gh pr create --base <production-branch> --title "hotfix: <description>" --body "<body>" --label "hotfix"
```

PR body includes: severity, root cause, fix description, files changed, regression test name, plus:

```
- [x] Regression test added and passes
- [x] Full test suite passes
- [x] Lines changed <= 15
- [x] No unrelated changes
- [ ] Manual verification
```

**Quality Gate**: all items (except manual verification) must be checked. If not, STOP and fix first.

Check `.claude/reviews/` for project-specific review criteria. Print PR URL and summary.

**>> Write output to**: `.workflows/<description>/04-pr.md` — then update `.workflows/current-state.md`. (PR URL, summary)

---

### Phase 5: CHERRY-PICK

Do NOT auto-cherry-pick. Present the plan:

```
After hotfix PR merges to <production-branch>:
1. git checkout <dev-branch> && git pull
2. git cherry-pick <fix-hash> && git cherry-pick <test-hash>
3. Resolve conflicts if any (likely in: <diverged files>)
4. git push origin <dev-branch>
Alternative: separate PR to <dev-branch>.
```

Preview conflicts: `git log <prod>..<dev> -- <changed-files>`. Warn if diverged.

Ask: "Cherry-pick now, or handle after merge?"

**>> Write output to**: `.workflows/<description>/05-cherry-pick.md` — then update `.workflows/current-state.md`. (Cherry-pick plan)

**After this final phase**: Move `.workflows/current-state.md` to `.workflows/history/<description>-<YYYY-MM-DD>.md`. Report completion.

---

## Final Summary

```
Hotfix complete.
  Branch:     hotfix/<description>
  PR:         <url> -> <production-branch>
  Root cause: <one line>
  Fix:        <one line>
  Files/Lines: <N>/<N>
  Tests added: <N>
  Cherry-pick: <done|pending>
```

## Error Handling

| Error | Resolution |
|---|---|
| Cannot identify crash | Ask for stack trace or crash report ID |
| Crash in dependency | Document workaround; cannot hotfix third-party code |
| Fix >15 lines | Reassess: hotfix or proper fix? Discuss with user |
| Prod branch unknown | Ask user for branch name |
| Cherry-pick conflicts | Present conflicts, let user resolve |
| Multiple crashes, same cause | Same file: one hotfix. Different files: separate hotfixes |

## Anti-Patterns

- Do NOT refactor while hotfixing
- Do NOT add features while hotfixing
- Do NOT update dependencies while hotfixing
- Do NOT fix code style while hotfixing
- Do NOT branch from development for a hotfix
- Do NOT skip the regression test
