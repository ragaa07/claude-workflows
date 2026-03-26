---
name: extend-feature
description: Extend an existing feature with new capabilities while preserving backward compatibility, using minimal-impact rules and SCAMPER brainstorming.
---

# Extend Feature Workflow

## Command

```
/extend-feature <feature-name> <extension-description> [--skip-brainstorm]
```

## Overview

Adds new capabilities to an existing feature while strictly preserving backward compatibility. Seven phases: **ANALYZE -> BRAINSTORM -> PLAN -> IMPLEMENT -> VERIFY-COMPAT -> TEST -> PR**.

## Core Principle: Minimal Impact

1. **Prefer new files over modifying existing ones**
2. **Extend sealed interfaces — do not restructure them**
3. **Add ViewModel functions — do not change existing signatures**
4. **Add new composables — do not refactor existing ones**
5. **Add new test files — do not modify existing test assertions**
6. **If you must modify an existing file, change the fewest lines possible**

---

## Phase 1: ANALYZE

**Goal**: Fully understand the existing feature's architecture before touching anything.

### Step 1.1 — Locate the Feature

Search the codebase for the feature:

```bash
find . -type d -name "*<feature-name>*" | head -20
grep -r "class.*<FeatureName>.*ViewModel" --include="*.kt" -l
grep -r "<FeatureName>Screen\|<FeatureName>Route" --include="*.kt" -l
```

### Step 1.2 — Map Feature Architecture

Use a sub-agent to build a feature map. Identify:
- ViewModel(s) and their state classes
- UI composables (screens, components)
- Domain layer (use cases, repositories, models)
- Data layer (API services, DTOs, mappers)
- DI modules
- Navigation setup
- Tests

### Step 1.3 — Identify Extension Points

- **Sealed interfaces/classes**: Can new subtypes be added?
- **State objects**: Can new fields be added without breaking existing consumers?
- **ViewModel**: What public functions exist? What flows are exposed?
- **Navigation**: How are screens added to the nav graph?
- **DI**: What is bound and how?

### Step 1.4 — Document Current Behavior

Record: What does the user see/do today? What data flows exist? What events/analytics are tracked? What edge cases are handled?

**Output**: Feature analysis document saved to `.workflows/<feature>/01-analyze.md`.

---

## Phase 2: BRAINSTORM

**Goal**: Explore extension approaches using SCAMPER technique.

**Skip condition**: Skip if `--skip-brainstorm` was passed OR `workflows.extend-feature.require_brainstorm` is `false`.

### Step 2.1 — Apply SCAMPER

- **S**ubstitute: Can we replace a component to add the capability?
- **C**ombine: Can we combine this with another existing feature?
- **A**dapt: Can we adapt a pattern from elsewhere in the codebase?
- **M**odify: What is the minimal modification to the existing code?
- **P**ut to another use: Can existing code serve double duty?
- **E**liminate: Can we remove something to make room for the extension?
- **R**everse: Can we invert the approach (e.g., push vs pull)?

### Step 2.2 — Evaluate Against Minimal Impact Rules

For each approach, score:

| Approach | New Files | Modified Files | Changed Signatures | Risk |
|---|---|---|---|---|
| A | 3 | 1 | 0 | Low |
| B | 1 | 4 | 2 | High |

**Always prefer fewer modified files and zero changed signatures.**

### Step 2.3 — Present Recommendation

Present top 2 approaches with justification. Ask: "Which approach? (A/B or suggest alternative)"

**Phase Output**: Write brainstorm results to `.workflows/<feature>/02-brainstorm.md`

---

## Phase 3: PLAN

**Goal**: Create implementation plan with explicit compatibility guarantees.

### Step 3.1 — Generate Plan

Write `.claude/plan-<feature-name>-extension.md`:

```markdown
# Extension Plan: <Feature Name> — <Extension>

## Existing Feature Analysis
- Architecture: <map from Phase 1>
- Extension points used: <list>

## Approach
<chosen approach from brainstorm>

## Compatibility Guarantees
- [ ] No existing function signatures changed
- [ ] No existing sealed interface subtypes removed
- [ ] No existing test assertions modified
- [ ] No existing UI behavior altered
- [ ] All existing tests pass after each phase

## Changes

### New Files (preferred)
- [ ] `<path>` — <description>

### Modified Files (minimal)
- [ ] `<path>` — <what changes and why>

## Implementation Phases

### Phase A: <Layer>
- Files: <list>
- Compile check: <command>
- Commit: `feat(<scope>): <message>`

### Phase B: <Layer>
...

## Rollback
- Revert branch; no migrations or irreversible changes
```

### Step 3.2 — Verify Plan Against Rules

1. Count modified files vs new files. If modified > new, reconsider.
2. Check for signature changes. If found, find alternative.
3. Verify each phase compiles independently.

### Step 3.3 — Get Approval

Present plan. Ask: "Approve plan or request changes?"

**Phase Output**: Write plan summary to `.workflows/<feature>/03-plan.md`

---

## Phase 4: IMPLEMENT

**Goal**: Execute plan phase by phase.

### Implementation Rules

1. **Before modifying any existing file**: Re-read it to confirm current state
2. **After modifying any existing file**: Run the full test suite
3. **If a phase requires changing an existing signature**: STOP and REPLAN
4. **Commit after each phase**: Small, atomic, revertable commits

### Per-Phase Steps

For each phase in the plan:
1. Read plan phase details
2. Implement changes (new files first, modifications last)
3. Run compile check
4. Run existing tests for the feature
5. Commit with message from plan

### REPLAN Trigger

If you discover an existing file needs more changes than planned, a function signature must change, or a sealed interface needs restructuring: STOP, document the discovery, re-evaluate, update plan with user approval.

**Phase Output**: Write implementation summary to `.workflows/<feature>/04-implement.md`

---

## Phase 5: VERIFY-COMPAT

**Goal**: Prove that existing functionality is unbroken.

### Step 5.1 — Run Full Test Suite

Every existing test MUST pass. No exceptions.

### Step 5.2 — Behavioral Comparison

For each existing behavior documented in Phase 1, verify it still works.

### Step 5.3 — API Compatibility Check

If the feature exposes a public API:
- All public function signatures unchanged
- All public data classes have same fields (new fields must have defaults)
- All sealed interface subtypes still exist

If any test fails: fix the code (not the test) to restore compatibility.

**Phase Output**: Write compatibility verification results to `.workflows/<feature>/05-verify-compat.md`

---

## Phase 6: TEST

**Goal**: Add tests for the new extension.

**Skip condition**: Skip if `workflows.extend-feature.require_tests` is `false`.

### Step 6.1 — Write Tests

Create NEW test files (do not modify existing):
- Test new functions/use cases
- Test new UI states
- Test integration with existing feature
- Test edge cases specific to the extension

### Step 6.2 — Run All Tests

Target: 80%+ coverage for new code.

**Phase Output**: Write test results to `.workflows/<feature>/06-test.md`

---

## Phase 7: PR

**Goal**: Create PR with clear extension documentation.

### Step 7.1 — Create PR

```bash
git push -u origin <branch>
gh pr create --base <dev_branch> --title "feat(<scope>): extend <feature> with <extension>" --body "<pr-body>"
```

Report PR URL to user.

**Phase Output**: Write PR details to `.workflows/<feature>/07-pr.md`

---

## Error Handling

| Error | Resolution |
|---|---|
| Feature not found | Ask user for correct name or path |
| Feature too complex | Use sub-agent per layer |
| Extension requires breaking changes | Present alternatives; document migration if unavoidable |
| Existing tests fail | Fix code, not tests |
| Plan exceeds minimal impact | Re-brainstorm with stricter constraints |
