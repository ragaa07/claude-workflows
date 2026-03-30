---
name: hotfix
description: Emergency hotfix — diagnose, minimal fix, regression test, PR, cherry-pick plan.
rules: [0, 1, 3, 4, 5, 6, 7, 10, 11, 12, 13, 17]
---

# Hotfix Workflow

`/hotfix <description> [--crashlytics <issue-id>] [--log <path-to-logfile>] [--branch <production-branch>]`

**Directory name**: Auto-generate `<description>` in kebab-case, max 40 chars (e.g., `null-crash-checkout-screen` or `timeout-payment-api`).

Emergency fix for production issues. Optimized for **SPEED**. No brainstorming. No spec. Fix the crash, nothing else.

**Phases**: DIAGNOSE → FIX → REGRESSION-TEST → PR → CHERRY-PICK

**Prerequisites**: Clean git tree. Production branch: `--branch` flag > `workflows.hotfix.base_branch` in config > `git.branches.main`.

> **EXECUTION PROTOCOL — MANDATORY**
> 1. **BEFORE Phase 1**: Create `.workflows/<description>/` dir and `.workflows/current-state.md` with YAML frontmatter (workflow, feature, phase, phases list, started, updated, branch, output_dir, replan_count) + Phase History table + Context section + Constraints section
> 2. **Execute phases IN ORDER** — never skip ahead
> 3. **After EACH phase** — do ALL before moving on:
>    - Write output file (path at end of each phase section)
>    - Update `.workflows/current-state.md`: advance `phase`, mark completed, add new ACTIVE row, append decisions to Context
>    - Print progress: `✓DIAGNOSE ▶FIX ·REGRESSION-TEST ·PR ·CHERRY-PICK`
> 4. Read `.workflows/config.yml` for project settings
> **NEVER skip phases unless explicitly allowed. NEVER proceed without writing output AND updating state.**

---

## Phase 1: DIAGNOSE

Identify the exact crash cause in minimum time.

1. **Gather crash data**: Crashlytics (if MCP available): extract exception, stack trace, file/line, frequency. Log file (`--log`): search for exceptions, fatal markers. Description: parse error type, repro steps.
2. **Locate crash site**: from stack trace, find exact file and line.
3. **Identify root cause**:

| Crash Type | What to Look For |
|---|---|
| Null/undefined reference | What is null? Unsafe access? |
| Type error / cast failure | Type mismatch from API change? |
| Index out of bounds | Race condition on collection size? |
| Invalid state | Missing initialization? |
| Thread/async issue | Wrong execution context? |
| Timeout / hang | Missing timeout? |

4. **Assess blast radius**: search codebase for same pattern.
5. **Decide**: high confidence — proceed. Low confidence — ask user. Never guess at production fixes.

Document: `"Root cause: <X> is null/invalid when <Y> because <Z>"`

**>> Phase complete** — write output to `.workflows/<description>/01-diagnose.md`

---

## Phase 2: FIX

**Preconditions**: `clean-tree`

Apply the absolute minimum change.

**Branch**: `git checkout <production-branch> && git pull && git checkout -b hotfix/<short-description>`

**Rules**: ONE change only. Match existing style. Track lines changed via `git diff --stat`. Warn if lines exceed `workflows.hotfix.max_lines` (default 15).

| Crash Type | Fix Pattern |
|---|---|
| Null/undefined reference | Add null check, safe access, or default value |
| Type error / cast failure | Add type validation or safe conversion |
| Index out of bounds | Add bounds check |
| Invalid state | Add state validation |
| Thread/async issue | Move to correct thread/context |
| Timeout / hang | Add timeout, move to background |

Read `<plugin-root>/rules/` for project-specific conventions. Apply them.

**Build check**: run project build. Fix compilation errors (still minimal). Max 3 attempts.

**Sanity review** (`git diff`): only crash site changed, no unrelated edits, fix is defensive.

**Commit**: `fix: <short description>` with root cause in body.

**>> Phase complete** — write output to `.workflows/<description>/02-fix.md`

---

## Phase 3: REGRESSION-TEST

**MANDATORY — cannot be skipped regardless of config.**

1. **Write regression test** reproducing the exact crash scenario. Test MUST fail without the fix and pass with it. Use project's test framework.
2. **Run tests**: affected module first, then full suite. Related failures → adjust fix. Unrelated → note but don't block.
3. **Commit**: `test: add regression test for <crash description>`

**>> Phase complete** — write output to `.workflows/<description>/03-regression-test.md`

---

## Phase 4: PR

**Preconditions**: `tests-pass`

**Pre-PR quality gate** (Rule 3): proportional to change size.

Push and create PR to production branch with: severity, root cause, fix description, files changed, regression test, checklist.

**>> Phase complete** — write output to `.workflows/<description>/04-pr.md`

---

## Phase 5: CHERRY-PICK

Present the cherry-pick plan. **Do NOT execute until user confirms.**

Preview conflicts: `git log <prod>..<dev> -- <changed-files>`. Warn if diverged.

Ask: "Cherry-pick now, or handle after merge?"

**>> Phase complete** — write output to `.workflows/<description>/05-cherry-pick.md`

---

## Anti-Patterns

While hotfixing, do NOT: refactor, add features, update dependencies, fix code style, branch from development, or skip the regression test.
