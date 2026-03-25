---
name: refactor
description: Safely refactor code with dependency graph mapping, behavioral contracts, incremental migration, and rollback plans at every step.
---

## Workflow State Protocol

> **MANDATORY**: Follow these rules throughout this entire workflow.

### On Workflow Start
1. Create directories: `mkdir -p .workflows/specs .workflows/history`
2. If `.workflows/current-state.md` already exists, ask the user: pause/abandon the existing workflow, or cancel this one.
3. Create `.workflows/current-state.md` with: workflow name, feature name, first phase (ANALYZE) as ACTIVE, started/updated timestamps, empty Phase History table, empty Completed Steps, Artifacts, and Context sections.

### At Every Phase Transition
Update `.workflows/current-state.md`:
1. Mark previous phase as `COMPLETED` with a brief note
2. Add new phase as `ACTIVE`
3. Update `phase` and `updated` header fields
4. Add completed steps from previous phase as checkboxes under `## Completed Steps`

### Save Artifacts
- Specs → `.workflows/specs/<feature>.spec.md`
- Decisions → `.workflows/specs/<feature>.decisions.md`
- Add links under `## Artifacts` in state file

### Brainstorm Skip Check
Before any BRAINSTORM phase: skip if `--skip-brainstorm` was passed OR `.claude/workflows.yml` has `workflows.refactor.require_brainstorm: false`. Mark as `SKIPPED` in Phase History.

### On Workflow Completion
Mark final phase `COMPLETED`. Move state file to `.workflows/history/<feature>-<date>.md`.

# Refactor Workflow

## Command

```
/workflow:refactor <target> [--scope <file|module|feature>] [--goal <description>]
```

**Target formats**: `class:ClassName`, `file:path/File.kt`, `module:moduleName`, `feature:featureName`

## Overview

Restructures existing code while preserving all external behavior. Seven phases: **ANALYZE -> BRAINSTORM -> CONTRACT -> DESIGN -> MIGRATE -> VERIFY -> PR**.

## Core Principle: Behavioral Preservation

The refactored code MUST produce identical outputs for identical inputs. Every step must compile and pass all tests. If any step breaks behavior, roll back and re-approach.

---

## Phase 1: ANALYZE

**Goal**: Build a complete dependency graph and understand the full blast radius.

### Step 1.1 — Identify the Target

Locate the target in the codebase:

```bash
# For a class
grep -r "class <ClassName>" --include="*.kt" -l
grep -r "interface <ClassName>" --include="*.kt" -l

# For a module
find . -name "build.gradle.kts" -exec grep -l "<moduleName>" {} \;

# For a feature
find . -type d -name "*<featureName>*"
```

### Step 1.2 — Map Inbound Dependencies (Who uses this?)

Find all consumers of the target:

```bash
# Class/function references
grep -r "<ClassName>" --include="*.kt" -l
grep -r "import.*<package>.<ClassName>" --include="*.kt" -l

# For modules: check settings.gradle.kts for dependents
grep -r "implementation project.*<module>" --include="*.gradle.kts" -l
```

Categorize consumers:
- **Direct callers**: Code that calls functions on the target
- **Subclasses/Implementors**: Code that extends/implements the target
- **DI consumers**: Code that injects the target
- **Test consumers**: Tests for the target

### Step 1.3 — Map Outbound Dependencies (What does this use?)

Analyze the target's imports and dependencies:
- Libraries and frameworks used
- Other project classes referenced
- System resources (files, network, database)

### Step 1.4 — Map Public API Surface

Document every public member:

```
Public API:
  Functions:
    - fun doSomething(param: Type): ReturnType
    - fun process(input: Input): Output
  Properties:
    - val state: StateFlow<State>
    - val events: Flow<Event>
  Types:
    - sealed class State { ... }
    - data class Model(...)
```

### Step 1.5 — Measure Current State

Record metrics:
- Lines of code
- Number of public members
- Cyclomatic complexity (estimate)
- Number of direct dependents
- Test coverage (if measurable)

**Output**: Dependency graph document with blast radius assessment.

---

## Phase 2: BRAINSTORM

**Goal**: Explore refactoring approaches using Trade-off Matrix and Reverse Brainstorm.

**Skip condition**: Skip if `--skip-brainstorm` passed OR `workflows.refactor.require_brainstorm` is `false` in `.claude/workflows.yml`. Mark as `SKIPPED` in Phase History.

### Step 2.1 — Trade-off Matrix

For each potential refactoring approach, evaluate:

| Approach | Effort | Risk | Blast Radius | Maintainability Gain | Performance Impact |
|---|---|---|---|---|---|
| A: <desc> | Low/Med/High | Low/Med/High | N files | +/0/- | +/0/- |
| B: <desc> | ... | ... | ... | ... | ... |
| C: <desc> | ... | ... | ... | ... | ... |

### Step 2.2 — Reverse Brainstorm

Ask: "How could this refactoring go wrong?"

List failure modes:
1. **Runtime behavior change**: A subtle behavior difference causes production bugs
2. **Performance regression**: The refactored code is slower
3. **Dependency breakage**: A consumer relies on an implementation detail
4. **Test brittleness**: Tests relied on internal structure, not behavior
5. **Incomplete migration**: Partially refactored state is worse than original

For each failure mode, define a mitigation:
- Behavior change → Behavioral contract (Phase 3)
- Performance → Benchmark before/after
- Dependency breakage → Public API preservation
- Test brittleness → Test migration as part of plan
- Incomplete migration → Each step compiles and tests pass

### Step 2.3 — Recommend Approach

Present recommendation with justification. The approach with the lowest blast radius wins in ties.

Ask: "Which approach? Or suggest an alternative."

---

## Phase 3: CONTRACT

**Goal**: Document the exact behavioral contract BEFORE changing any code.

### Step 3.1 — Write Behavioral Contract

Create `.workflows/contracts/<target>.contract.md`:

```markdown
# Behavioral Contract: <Target>

## Date: <today>
## Status: Pre-Refactor

## Invariants
These MUST be true before AND after the refactor:

1. Given <input>, the output is <output>
2. When <condition>, the behavior is <behavior>
3. <Side effect X> occurs when <trigger>
4. Error <E> is thrown when <invalid input>

## Public API Contract
These signatures MUST NOT change (or must be deprecated with forwarding):

- `fun methodA(param: Type): ReturnType`
- `val propertyB: Type`

## Performance Contract
- Operation X completes in <N>ms (measured)
- Memory usage does not exceed <N>MB for <workload>

## Threading Contract
- Function X is called on <thread>
- Flow Y emits on <dispatcher>

## Test Coverage
- <N> existing tests cover this target
- Tests located at: <paths>
```

### Step 3.2 — Verify Contract Against Tests

Read existing tests for the target. Every test assertion should map to a contract invariant. If tests are missing for a contract invariant:
- Flag it as a gap
- Add a test BEFORE starting the refactor (this is the only time you add tests before implementation in this workflow)

### Decision Point: Contract Approval

Present contract to user. Ask: "Does this contract capture all expected behaviors?"

---

## Phase 4: DESIGN

**Goal**: Create an incremental migration plan where every step compiles and passes tests.

### Step 4.1 — Design the Target State

Describe what the code looks like after the refactor:
- New file/class structure
- New interfaces/abstractions
- New module boundaries (if applicable)

### Step 4.2 — Plan Migration Steps

Write `.claude/plan-refactor-<target>.md`:

Each step MUST satisfy:
- The project compiles after this step
- All tests pass after this step
- The step is independently revertable

```markdown
# Refactor Plan: <Target>

## Contract Reference
- Contract: `.workflows/contracts/<target>.contract.md`

## Current State
<brief description>

## Target State
<brief description>

## Migration Steps

### Step 1: <Description>
- **Action**: <what to do>
- **Files**: <create/modify/delete>
- **Compile check**: <command>
- **Test check**: <command>
- **Rollback**: `git revert <commit>`
- **Commit**: `refactor(<scope>): <message>`

### Step 2: <Description>
...

### Step N: Cleanup
- Remove deprecated code (only after all consumers migrated)
- Remove forwarding functions
- Delete unused files
- Final compile + test

## Migration Safety Rules
1. Never delete old code until new code is proven equivalent
2. Use @Deprecated annotation with ReplaceWith during transition
3. Run full test suite after each step, not just target tests
4. If any step fails tests: revert immediately, do not debug in-place
```

### Step 4.3 — Estimate Blast Radius Per Step

For each step, list:
- Files directly changed
- Files potentially affected (transitive dependents)
- Risk level (low/medium/high)

### Step 4.4 — Get Approval

Present plan. Ask: "Approve migration plan or request changes?"

---

## Phase 5: MIGRATE

**Goal**: Execute migration step by step with strict verification.

### Per-Step Protocol

For each migration step:

1. **Read**: Re-read the files to be changed (they may have been modified since analysis)
2. **Implement**: Make the changes for this step ONLY
3. **Compile**: Run build command
   - If fails: revert changes for this step, investigate, and retry (max 3 attempts)
   - If fails 3 times: STOP and REPLAN
4. **Test**: Run FULL test suite (not just target tests)
   - If fails: revert changes for this step immediately
   - Investigate: Is it a behavior change or a test that depended on implementation details?
   - If behavior change: the approach is wrong, REPLAN
   - If test depends on internals: update the test (document why)
5. **Contract Check**: Verify contract invariants still hold
6. **Commit**: Atomic commit with descriptive message
7. **Record Rollback**: Note the commit hash for rollback

```bash
# After each step
git add <files>
git commit -m "refactor(<scope>): <step description>"
echo "Rollback point: $(git rev-parse HEAD)"
```

### Parallel Deprecation Pattern

When replacing a class/function:

1. Create the new implementation alongside the old one
2. Add `@Deprecated("Use NewClass instead", ReplaceWith("NewClass"))` to the old one
3. Migrate consumers one by one (each is a separate step)
4. Delete the old implementation only after all consumers are migrated
5. Verify no references remain: `grep -r "OldClass" --include="*.kt"`

### REPLAN Protocol

If a step fails:
1. Revert to last good commit
2. Document what went wrong
3. Re-evaluate the approach
4. Generate a revised plan for remaining steps
5. Get user approval before continuing

---

## Phase 6: VERIFY

**Goal**: Prove the refactoring preserves all behavior.

### Step 6.1 — Full Test Suite

```bash
<full-test-command>
```

Every test must pass. Zero tolerance.

### Step 6.2 — Contract Verification

Go through each invariant in the behavioral contract:
- Manually verify or point to the test that covers it
- Mark each invariant as VERIFIED or FAILED

### Step 6.3 — Metrics Comparison

Compare before/after:

```
Metric              Before    After     Delta
Lines of code       <N>       <N>       <+/->
Public members      <N>       <N>       <+/->
Direct dependents   <N>       <N>       <+/->
Test count          <N>       <N>       <+/->
```

### Step 6.4 — Cleanup Check

Verify:
- No `@Deprecated` annotations remain (all migrations complete)
- No unused imports
- No dead code left behind
- No TODO comments from the refactor

### Decision Point: Verification Failure

If any contract invariant is FAILED:
- Assess severity
- If critical: revert the entire refactor
- If minor: fix and re-verify

---

## Phase 7: PR

**Goal**: Create a PR with full context for reviewers.

### Step 7.1 — Generate PR Body

```markdown
## Summary
Refactors <target> to <goal>.

## Motivation
<why this refactoring was needed>

## Approach
<chosen approach and why>

## Behavioral Contract
All invariants from `.workflows/contracts/<target>.contract.md` verified:
- [x] <invariant 1>
- [x] <invariant 2>

## Changes
### Step 1: <description>
- <files changed>
### Step 2: <description>
- <files changed>

## Metrics
| Metric | Before | After |
|---|---|---|
| Lines of code | N | N |
| Public members | N | N |

## Testing
- [ ] All existing tests pass (unmodified except: <list any modified tests with justification>)
- [ ] Behavioral contract fully verified
- [ ] No deprecated code remaining

## Rollback Plan
Each commit is independently revertable. Full rollback:
`git revert <first-commit>..<last-commit>`
```

### Step 7.2 — Create PR

```bash
git push -u origin <branch>
gh pr create --base <dev_branch> --title "refactor(<scope>): <goal>" --body "$(cat <<'EOF'
<pr-body>
EOF
)"
```

### Step 7.3 — Update State

Update `tasks/todo.md`, report PR URL.

---

## Error Handling

| Error | Resolution |
|---|---|
| Target has 50+ dependents | Suggest splitting into smaller refactors |
| No tests exist for target | Write tests first (contract-based), then refactor |
| Circular dependencies discovered | Document and address as separate prerequisite refactor |
| Performance regression detected | Profile, optimize, or revert to previous approach |
| Migration step breaks unrelated test | Investigate transitive dependency; likely a hidden coupling |
