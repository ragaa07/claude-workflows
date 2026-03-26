---
name: hotfix
description: Emergency hotfix — diagnose, minimal fix, regression test, PR, cherry-pick plan.
---

# Hotfix Workflow

`/workflow:hotfix <description> [--crashlytics <issue-id>] [--log <path>] [--branch <production-branch>]`

Emergency fix for production issues. Optimized for **SPEED**. No brainstorming. No spec. Fix the crash, nothing else.

**Phases**: DIAGNOSE -> FIX -> REGRESSION-TEST -> PR -> CHERRY-PICK

**Prerequisites**: Clean git tree. Production branch identifiable from `.claude/workflows.yml` or `--branch`.

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

**Phase Output**: `.workflows/<description>/01-diagnose.md` — root cause, crash site, blast radius.

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

**Phase Output**: `.workflows/<description>/02-fix.md` — changes made, diff summary.

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

**Phase Output**: `.workflows/<description>/03-regression-test.md` — test results.

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

**Phase Output**: `.workflows/<description>/04-pr.md` — PR URL, summary.

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

**Phase Output**: `.workflows/<description>/05-cherry-pick.md` — cherry-pick plan.

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

## State Management

When invoked via `/start`, the orchestrator handles state automatically — writes phase outputs to `.workflows/<feature>/` and updates `.workflows/current-state.md`. This skill does not manage state directly.

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
