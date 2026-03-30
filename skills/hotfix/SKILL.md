---
name: hotfix
description: Emergency hotfix — diagnose, minimal fix, regression test, PR, cherry-pick plan.
---

# Hotfix Workflow

`/hotfix <description> [--crashlytics <issue-id>] [--log <path>] [--branch <production-branch>]`

Emergency fix for production issues. Optimized for **SPEED**. No brainstorming. No spec. Fix the crash, nothing else.

**Phases**: DIAGNOSE -> FIX -> REGRESSION-TEST -> PR -> CHERRY-PICK

**Prerequisites**: Clean git tree. Production branch identifiable from `.workflows/config.yml` or `--branch`.

> Follow orchestration Rules 0-1 for state and output.

---

### Phase 1: DIAGNOSE

Identify the exact crash cause in minimum time.

1. **Gather crash data**: Crashlytics (`--crashlytics`): use `mcp__firebase__crashlytics_get_issue` / `_list_events` to extract exception type, stack trace, file/line, frequency. Log file (`--log`): search for exceptions, stack traces, fatal markers. Description: parse error type, repro steps, affected feature.
2. **Locate crash site**: from stack trace, find exact file and line.
3. **Identify root cause**:

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

**>> Write output to**: `.workflows/<description>/01-diagnose.md` (Root cause, crash site, blast radius)

---

### Phase 2: FIX

Apply the absolute minimum change.

**Branch**: `git checkout <production-branch> && git pull && git checkout -b hotfix/<short-description>` (read from `git.branches.main` in config or `--branch`).

**Rules**: ONE change only (no refactoring/features/deps). Match existing style. Lines changed: ideally 1-5, max from `workflows.hotfix.max_lines` (default 15) — warn if exceeded.

| Crash Type | Fix Pattern |
|---|---|
| Null/undefined reference | Add null check, safe access, or default value |
| Type error / cast failure | Add type validation or safe conversion |
| Index out of bounds | Add bounds check |
| Invalid state | Add state validation |
| Thread/async issue | Move to correct thread/context |
| Timeout / hang | Add timeout, move to background |

Check `${CLAUDE_PLUGIN_ROOT}/rules/` for project-specific conventions. Apply them.

**Build check**: run project build command. Fix compilation errors if needed (still minimal). Max 3 attempts.

**Sanity review** (`git diff`): only crash site changed, no unrelated edits, fix is defensive, lines within limit.

**Commit**: `fix: <short description>` with root cause and crash location in body.

**>> Write output to**: `.workflows/<description>/02-fix.md` (Changes made, diff summary)

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
   Test MUST fail without the fix and pass with it. Use project's test framework. Check `${CLAUDE_PLUGIN_ROOT}/rules/` for test patterns.

2. **Run tests**: affected module first, then full suite. Related failures — adjust fix. Unrelated — note but don't block.

3. **Commit**: `test: add regression test for <crash description>`

**>> Write output to**: `.workflows/<description>/03-regression-test.md` (Test results)

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

**Pre-PR quality gate**: Load `${CLAUDE_PLUGIN_ROOT}/reviews/general-checklist.md` + language-specific checklist. Self-check all High/Critical items. Fix violations before creating PR.

Print PR URL and summary.

**>> Write output to**: `.workflows/<description>/04-pr.md` (PR URL, summary)

---

### Phase 5: CHERRY-PICK

Present the cherry-pick plan to the user. **Do NOT execute until user confirms.**

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

**>> Write output to**: `.workflows/<description>/05-cherry-pick.md` (Cherry-pick plan)

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
| Prod branch unknown | Ask user for branch name |
| Cherry-pick conflicts | Present conflicts, let user resolve |
| Multiple crashes, same cause | Same file: one hotfix. Different files: separate hotfixes |

## Anti-Patterns

While hotfixing, do NOT: refactor, add features, update dependencies, fix code style, branch from development, or skip the regression test.
