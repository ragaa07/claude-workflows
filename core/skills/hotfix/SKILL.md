---
name: hotfix
description: Emergency hotfix workflow for production crashes — diagnose, fix with minimal change, regression test, PR to production, and cherry-pick to development.
---

# Hotfix Workflow

## Command

```
/workflow:hotfix <description> [--crashlytics <issue-id>] [--log <path>] [--branch <production-branch>]
```

## Overview

Emergency fix for production issues. Optimized for SPEED. Five phases: **DIAGNOSE -> FIX -> REGRESSION-TEST -> PR -> CHERRY-PICK**.

No brainstorming. No spec. Minimal planning. Fix the crash, nothing else.

## Prerequisites

- Git working tree must be clean
- Production branch must be identifiable (from `.claude/workflows.yml` or `--branch`)

---

## Phase 1: DIAGNOSE

**Goal**: Identify the exact cause of the crash in minimum time.

### Step 1.1 — Gather Crash Data

**From Crashlytics (if --crashlytics)**:

```
mcp__firebase__crashlytics_get_issue(issueId: "<issue-id>")
mcp__firebase__crashlytics_list_events(issueId: "<issue-id>")
mcp__firebase__crashlytics_batch_get_events(issueId: "<issue-id>")
```

Extract:
- **Exception type**: NullPointerException, ClassCastException, etc.
- **Stack trace**: Full crash stack trace
- **Affected class/line**: Exact location
- **Device/OS**: Affected devices and OS versions
- **Frequency**: How many users affected
- **App version**: Which build is crashing

**From log file (if --log)**:

Read the provided log file. Search for:
- Exception/Error lines
- Stack traces
- Fatal markers

**From description (always)**:

Parse the user's description for:
- Error type
- Reproduction steps
- Affected feature

### Step 1.2 — Locate the Crash Site

From the stack trace, find the exact file and line:

```bash
# Find the crashing file
grep -r "class <CrashingClass>" --include="*.kt" -l

# Read the file around the crash line
```

Read the file. Focus on the exact method in the stack trace.

### Step 1.3 — Identify Root Cause

Analyze the crash site:

- **NullPointerException**: What is null? Why? Is it a nullable type accessed unsafely?
- **ClassCastException**: What cast failed? Type mismatch from API change?
- **IndexOutOfBoundsException**: What collection? What index? Race condition?
- **IllegalStateException**: What state is invalid? Missing initialization?
- **ANR**: What is blocking the main thread?

Document in one line: "Root cause: <X> is null when <Y> because <Z>"

### Step 1.4 — Assess Blast Radius

Before fixing, check:
- How many places does this code path execute?
- Does the fix affect any other behavior?
- Are there related crash sites with the same root cause?

```bash
# Check for similar patterns
grep -r "<crash-pattern>" --include="*.kt" -l
```

### Decision Point: Diagnosis Confidence

- **High confidence**: Root cause is clear from stack trace. Proceed to FIX.
- **Low confidence**: Ask user for more information. Do NOT guess at production fixes.

**Output**: Root cause statement and crash site location.

---

## Phase 2: FIX

**Goal**: Apply the absolute minimum change to fix the crash.

### Step 2.1 — Branch from Production

```bash
# Identify production branch
PROD_BRANCH=$(grep -A1 "main_branch" .claude/workflows.yml | tail -1 | tr -d ' ' || echo "Production")

git checkout $PROD_BRANCH
git pull origin $PROD_BRANCH
git checkout -b hotfix/<short-description>
```

### Step 2.2 — Apply Minimal Fix

Rules for the fix:
1. **ONE change only**: Fix the crash, nothing else
2. **No refactoring**: Even if the code is ugly
3. **No feature changes**: Even if related and "easy"
4. **No dependency updates**: Even if they might help
5. **Defensive coding**: Prefer null checks, safe casts, bounds checks
6. **Match existing style**: Do not reformat surrounding code

Common fix patterns:

| Crash Type | Fix Pattern |
|---|---|
| NPE on nullable | Add `?.` or `?: default` |
| NPE on non-null assumption | Make type nullable, add null check |
| ClassCastException | Add `as?` safe cast with fallback |
| IndexOutOfBounds | Add bounds check: `getOrNull(index)` |
| IllegalStateException | Add state validation before operation |
| ANR / Main thread block | Move to background dispatcher |
| ConcurrentModification | Use thread-safe collection or copy |

### Step 2.3 — Compile Check

```bash
<build-command>
```

If compile fails: fix compilation error (still minimal). Max 3 attempts.

### Step 2.4 — Sanity Review

Before committing, re-read the diff:

```bash
git diff
```

Verify:
- Only the crash site is changed
- No unrelated modifications
- The fix is defensive, not offensive (handles the bad state rather than preventing it upstream, unless the upstream fix is equally minimal)
- Lines changed: ideally 1-5, maximum 15

### Step 2.5 — Commit

```bash
git add <specific-file(s)>
git commit -m "$(cat <<'EOF'
fix: <short description of crash fix>

Root cause: <one line explanation>
Crash: <exception type> in <class>.<method>
EOF
)"
```

---

## Phase 3: REGRESSION-TEST

**Goal**: Prove the fix works and does not break anything else.

### Step 3.1 — Write Regression Test

Create a test that reproduces the exact crash scenario:

```kotlin
@Test
fun `should not crash when <crash condition>`() {
    // Given: <the state that caused the crash>
    // When: <the action that triggered it>
    // Then: <expected behavior instead of crash>
}
```

This test MUST:
- Fail without the fix (verify by mentally tracing the old code path)
- Pass with the fix
- Cover the exact scenario from the crash report

### Step 3.2 — Run Feature Tests

Run tests for the affected feature/module:

```bash
<test-command> --tests "*<AffectedClass>*"
```

### Step 3.3 — Run Full Test Suite

```bash
<full-test-command>
```

All tests must pass. If any fail:
- If related to the fix: the fix needs adjustment
- If unrelated: note it but do not block the hotfix (pre-existing issue)

### Step 3.4 — Commit Test

```bash
git add <test-file>
git commit -m "test: add regression test for <crash description>"
```

---

## Phase 4: PR

**Goal**: Create PR to production branch with urgency context.

### Step 4.1 — Generate PR Body

```markdown
## Hotfix: <crash description>

**Severity**: <Critical/High>
**Users affected**: <count if known>
**Crash rate**: <percentage if known>

## Root Cause
<one paragraph explanation>

## Fix
<description of the minimal change>

## Changes
- `<file>`: <what changed>

## Regression Test
- Added `<test name>` that reproduces the crash scenario

## Testing
- [x] Regression test passes
- [x] Feature tests pass
- [x] Full test suite passes
- [ ] Manual verification on device

## Risk Assessment
- Lines changed: <N>
- Scope: <single file / single function>
- Side effects: None expected
```

### Step 4.2 — Create PR

```bash
git push -u origin hotfix/<short-description>

gh pr create \
  --base <production-branch> \
  --title "hotfix: <crash description>" \
  --body "$(cat <<'EOF'
<pr-body>
EOF
)" \
  --label "hotfix"
```

### Step 4.3 — Report PR

Print the PR URL and summary.

---

## Phase 5: CHERRY-PICK

**Goal**: Plan how to get the fix into the development branch.

### Step 5.1 — Generate Cherry-Pick Plan

Do NOT automatically cherry-pick. Present the plan to the user:

```
Cherry-Pick Plan:

After the hotfix PR is merged to <production-branch>:

1. Checkout development branch:
   git checkout <dev-branch>
   git pull origin <dev-branch>

2. Cherry-pick the fix commits:
   git cherry-pick <fix-commit-hash>
   git cherry-pick <test-commit-hash>

3. Resolve conflicts (if any):
   - Likely conflict in: <files if dev has diverged>

4. Push and verify:
   git push origin <dev-branch>

Alternative: Create a separate PR to <dev-branch> with the same changes.
```

### Step 5.2 — Check for Conflicts

Preview potential conflicts:

```bash
git log <production-branch>..<dev-branch> -- <changed-files>
```

If the changed files have diverged between production and development, warn the user about likely conflicts.

### Decision Point: Auto Cherry-Pick

Ask: "Should I cherry-pick to <dev-branch> now, or will you handle it after the hotfix is merged?"

- If yes: execute the cherry-pick, create PR to dev branch
- If no: save the plan for later

---

## Final Summary

Print:

```
Hotfix complete.

  Branch:     hotfix/<description>
  PR:         <pr-url> (target: <production-branch>)
  Root cause: <one line>
  Fix:        <one line>
  Files:      <count> changed
  Lines:      <count> changed
  Tests:      <count> added

Cherry-pick to <dev-branch>: <done|pending>
```

---

## Error Handling

| Error | Resolution |
|---|---|
| Cannot identify crash from description | Ask for stack trace or Crashlytics issue ID |
| Crash site is in a dependency (not our code) | Document workaround; cannot hotfix third-party code |
| Fix requires >15 lines changed | Reassess: is this truly a hotfix or a proper fix? Discuss with user |
| Production branch not configured | Ask user for the production branch name |
| Cherry-pick has conflicts | Present conflicts, let user resolve manually |
| Multiple crashes with same root cause | Fix all in one hotfix if same file; separate hotfixes if different files |

## Anti-Patterns (DO NOT)

- Do NOT refactor while hotfixing
- Do NOT add features while hotfixing
- Do NOT update dependencies while hotfixing
- Do NOT fix code style while hotfixing
- Do NOT branch from development for a hotfix
- Do NOT skip the regression test
