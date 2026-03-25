---
name: extend-feature
description: Extend an existing feature with new capabilities while preserving backward compatibility, using minimal-impact rules and SCAMPER brainstorming.
---

# Extend Feature Workflow

## Phase 0: INIT — Do This First

> **You MUST complete these steps before doing anything else.**

### Step 0.1 — Create State Directories

```bash
mkdir -p .workflows/specs .workflows/history
```

### Step 0.2 — Check for Existing Workflow

Read `.workflows/current-state.md`. If it exists, tell the user:
- "There's an active workflow: `<workflow>` at `<phase>`. Pause it, abandon it, or cancel this new one?"
- Wait for their choice before continuing.

### Step 0.3 — Create State File

Write `.workflows/current-state.md` with this exact content (replace `<feature>` with the user's input):

```markdown
# Workflow State

- **workflow**: extend-feature
- **feature**: <feature>
- **phase**: ANALYZE
- **started**: <current ISO-8601 timestamp>
- **updated**: <current ISO-8601 timestamp>
- **branch**:

## Phase History

| Phase | Status | Timestamp | Notes |
|-------|--------|-----------|-------|
| ANALYZE | ACTIVE | <timestamp> | Starting analysis of existing feature |

## Completed Steps


## Artifacts


## Context

```

### Step 0.4 — Read Configuration

Read `.claude/workflows.yml` and note relevant config for this workflow.
Key config: `workflows.extend-feature.require_brainstorm`, `workflows.extend-feature.require_tests`

---

## Phase Transition Rules

**At the END of every phase** (before starting the next one), you MUST:
1. Update `.workflows/current-state.md`:
   - Change the current phase's row from `ACTIVE` to `COMPLETED` with a note of what was done
   - Add the next phase as `ACTIVE`
   - Update the `phase` and `updated` header fields
   - Add checkboxes for steps completed under `## Completed Steps`
2. Save any artifacts:
   - Specs → `.workflows/specs/<feature>.spec.md`
   - Decisions → `.workflows/specs/<feature>.decisions.md`
   - Add links under `## Artifacts`
3. Add key decisions under `## Context` (for resume)

**When the workflow completes**: Move `.workflows/current-state.md` to `.workflows/history/<feature>-<date>.md`

**Brainstorm skip**: Skip BRAINSTORM if `--skip-brainstorm` was passed OR `workflows.extend-feature.require_brainstorm` is `false`. Mark as `SKIPPED`.

---

## Command

```
/workflow:extend-feature <feature-name> <extension-description> [--skip-brainstorm]
```

## Overview

Adds new capabilities to an existing feature while strictly preserving backward compatibility. Seven phases: **ANALYZE -> BRAINSTORM -> PLAN -> IMPLEMENT -> VERIFY-COMPAT -> TEST -> PR**.

## Core Principle: Minimal Impact

Every decision in this workflow is governed by these rules:

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
# Find feature module or package
find . -type d -name "*<feature-name>*" | head -20

# Find ViewModels
grep -r "class.*<FeatureName>.*ViewModel" --include="*.kt" -l

# Find UI entry points
grep -r "<FeatureName>Screen\|<FeatureName>Route" --include="*.kt" -l
```

### Step 1.2 — Map Feature Architecture

Use a sub-agent to build a feature map:

**Files to identify**:
- ViewModel(s) and their state classes
- UI composables (screens, components)
- Domain layer (use cases, repositories, models)
- Data layer (API services, DTOs, mappers)
- DI modules
- Navigation setup
- Tests

**Document the map**:

```
Feature: <name>
├── UI
│   ├── <Screen>.kt
│   └── <Component>.kt
├── ViewModel
│   ├── <VM>.kt
│   └── <State>.kt
├── Domain
│   ├── <UseCase>.kt
│   └── <Model>.kt
├── Data
│   ├── <Repository>.kt
│   ├── <ApiService>.kt
│   └── <DTO>.kt
├── DI
│   └── <Module>.kt
├── Navigation
│   └── <NavGraph>.kt
└── Tests
    ├── <VMTest>.kt
    └── <UseCaseTest>.kt
```

### Step 1.3 — Identify Extension Points

Analyze the feature for natural extension points:
- **Sealed interfaces/classes**: Can new subtypes be added?
- **State objects**: Can new fields be added without breaking existing consumers?
- **ViewModel**: What public functions exist? What flows are exposed?
- **Navigation**: How are screens added to the nav graph?
- **DI**: What is bound and how?

### Step 1.4 — Document Current Behavior

Record the feature's current behavior:
- What does the user see/do today?
- What data flows exist?
- What events/analytics are tracked?
- What edge cases are handled?

**Output**: Feature analysis document (internal, used in planning).

---

## Phase 2: BRAINSTORM

**Goal**: Explore extension approaches using SCAMPER technique.

**Skip condition**: Skip if `--skip-brainstorm` passed OR `workflows.extend-feature.require_brainstorm` is `false` in `.claude/workflows.yml`. Mark as `SKIPPED` in Phase History.

### Step 2.1 — Apply SCAMPER

Default brainstorm technique for extensions is SCAMPER:

- **S**ubstitute: Can we replace a component to add the capability?
- **C**ombine: Can we combine this with another existing feature?
- **A**dapt: Can we adapt a pattern from elsewhere in the codebase?
- **M**odify: What is the minimal modification to the existing code?
- **P**ut to another use: Can existing code serve double duty?
- **E**liminate: Can we remove something to make room for the extension?
- **R**everse: Can we invert the approach (e.g., push vs pull)?

### Step 2.2 — Evaluate Against Minimal Impact Rules

For each approach from SCAMPER, score:

| Approach | New Files | Modified Files | Changed Signatures | Risk |
|---|---|---|---|---|
| A | 3 | 1 | 0 | Low |
| B | 1 | 4 | 2 | High |

**Always prefer the approach with fewer modified files and zero changed signatures.**

### Step 2.3 — Present Recommendation

Present the top 2 approaches with clear justification for the recommended one.

Ask: "Which approach? (A/B or suggest alternative)"

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
- [ ] `<path>` — <what changes and why it is unavoidable>

## Phases

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

Self-check the plan:

1. Count modified files vs new files. If modified > new, reconsider.
2. Check for any signature changes. If found, find an alternative.
3. Verify each phase compiles independently.

### Step 3.3 — Get Approval

Present plan. Ask: "Approve plan or request changes?"

### Step 3.4 — Update Todo

Add to `tasks/todo.md` under In Progress.

---

## Phase 4: IMPLEMENT

**Goal**: Execute plan phase by phase.

### Implementation Rules (stricter than new-feature)

1. **Before modifying any existing file**: Re-read it to confirm current state matches your analysis
2. **After modifying any existing file**: Run the full test suite, not just compile
3. **If a phase requires changing an existing signature**: STOP and REPLAN
4. **Commit after each phase**: Small, atomic, revertable commits

### Per-Phase Steps

For each phase:

1. Read plan phase details
2. Implement changes (new files first, modifications last)
3. Run compile check
4. Run existing tests for the feature: `<test-command> --tests "<FeatureName>*"`
5. Commit with message from plan
6. Update `tasks/todo.md`

### REPLAN Trigger

If during implementation you discover:
- An existing file needs more changes than planned
- A function signature must change
- A sealed interface needs restructuring

Then:
1. STOP immediately
2. Document the discovery
3. Re-evaluate: Is there a way to avoid the change?
4. If unavoidable: update the plan and get user approval
5. If avoidable: use the alternative approach

---

## Phase 5: VERIFY-COMPAT

**Goal**: Prove that existing functionality is unbroken.

### Step 5.1 — Run Full Test Suite

```bash
<full-test-command>
```

Every existing test MUST pass. No exceptions.

### Step 5.2 — Behavioral Comparison

For each existing feature behavior documented in Phase 1:
- Verify it still works the same way
- If UI changes: note what changed and confirm it is intentional

### Step 5.3 — API Compatibility Check

If the feature exposes a public API (used by other modules):
- Verify all public function signatures are unchanged
- Verify all public data classes have the same fields (new fields must have defaults)
- Verify all sealed interface subtypes still exist

### Decision Point: Compatibility Failure

If any existing test fails:
1. Determine if the failure is a true regression or a test that needs updating
2. If true regression: fix the code, not the test
3. If test needs updating (rare, justified cases only): document why

---

## Phase 6: TEST

**Goal**: Add tests for the new extension.

### Step 6.1 — Write Tests

Create NEW test files (do not modify existing test files):

- Test new functions/use cases
- Test new UI states
- Test integration with existing feature
- Test edge cases specific to the extension

### Step 6.2 — Run All Tests

```bash
<test-command>
```

### Step 6.3 — Coverage Report

Report coverage for new code. Target: 80%+.

---

## Phase 7: PR

**Goal**: Create PR with clear extension documentation.

### Step 7.1 — Generate PR Body

```markdown
## Summary
Extends <feature-name> with <extension-description>.

## Changes

### New Files
- `<path>` — <description>

### Modified Files
- `<path>` — <what changed> (minimal, unavoidable)

## Backward Compatibility
- All existing tests pass (no modifications)
- No public API signature changes
- No sealed interface restructuring
- Existing UI behavior preserved

## Testing
- [ ] Existing tests: all pass (unmodified)
- [ ] New tests added for extension
- [ ] Manual verification of existing behavior

## Test Plan
- [ ] <scenario 1>
- [ ] <scenario 2>
```

### Step 7.2 — Create PR

```bash
git push -u origin <branch>
gh pr create --base <dev_branch> --title "feat(<scope>): extend <feature> with <extension>" --body "$(cat <<'EOF'
<pr-body>
EOF
)"
```

### Step 7.3 — Update State

Update `tasks/todo.md` and report PR URL.

---

## Error Handling

| Error | Resolution |
|---|---|
| Feature not found in codebase | Ask user for correct feature name or path |
| Feature too complex to analyze | Use sub-agent per layer, analyze in parts |
| Extension requires breaking changes | Present alternatives; if none exist, document migration path |
| Existing tests fail after changes | Fix code (not tests) to restore compatibility |
| Plan exceeds minimal impact threshold | Re-brainstorm with stricter constraints |
