---
name: test
description: Generate comprehensive tests for a target class, file, module, or feature with coverage analysis, boundary classification, and gap reporting.
---

# Test Workflow

```
/workflow:test <target> [--coverage <pct>] [--type <unit|integration>]
```

**Targets**: `class:Name`, `file:path/to/file`, `module:name`, `feature:name` | **Defaults**: coverage=90%, type=unit

**Before starting**: Read `.claude/rules/` for language-specific testing conventions. Scan build files to detect test framework, runner, mocking library, and coverage tooling.

## Phase 1: ANALYZE

### 1.1 Locate Target
- `class:Name` — search source tree for class/interface definition
- `file:path` — read directly
- `module:name` — find module source root, list public types
- `feature:name` — find feature directory, map all classes

### 1.2 Extract Public API
For each target: public functions (name, params, return type, nullability), public properties/fields, constructors and injected dependencies, observable state (streams, emitters, callbacks), type hierarchies (sealed/enum subtypes), static/companion members.

### 1.3 Categorize Dependencies

| Category | Mock Strategy |
|---|---|
| Interface/protocol | Mock or fake implementation |
| Framework class | Test double or test runtime |
| External service (network, DB) | Mock or in-memory substitute |
| Side-effect only (logger, analytics) | Mock, verify calls |
| Pure data (models, DTOs) | Real instances — NEVER mock |

### 1.4 Map Code Branches
Per public function, identify: **happy path** (success), **error paths** (exceptions, error states, null returns), **edge cases** (empty collections, boundary values, null inputs), **concurrency** (races, cancellation, timeouts), **state-dependent** (behavior varies with current state).

Document as branch map:
```
functionName(params)
  1. valid input -> success
  2. empty input -> validation error
  3. dependency throws -> error propagation
  4. concurrent calls -> serialization/dedup
```

### 1.5 Check Existing Tests
Search for existing test files. If found, document covered branches and identify gaps against 1.4.

**Output**: `.workflows/<target>/01-analyze.md`

---

## Phase 2: PLAN

### 2.1 Test Boundaries
**Inside (test directly)**: target class logic. **Outside (mock)**: injected deps, framework classes, system resources (filesystem, network, clock, randomness). **Never mock**: data classes, pure functions, type hierarchies, value objects.

### 2.2 Test Case List
Tag each case from the branch map:
```
1. [HAPPY] should return success when input is valid
2. [ERROR] should return validation error when input is empty
3. [EDGE]  should handle concurrent calls gracefully
4. [STATE] should transition to loading before fetching
```
Tags: `[HAPPY]`, `[ERROR]`, `[EDGE]`, `[STATE]`, `[INTEGRATION]`

### 2.3 Coverage Estimate
Count total branches vs planned tests. If expected coverage < target, add cases.

### 2.4 File Structure
Group tests by function/behavior. For `module:` or `feature:` targets, plan multiple files.

**Output**: `.workflows/<target>/02-plan.md`

---

## Phase 3: WRITE

### 3.1 Test Infrastructure
From build file scan: identify test framework (JUnit, pytest, Jest, Go testing, RSpec, etc.), mocking library, assertion library, async/reactive test utilities, coverage tool.

### 3.2 Write Tests
Structure: (1) declare mocks/fakes, (2) setup SUT with mocked deps, (3) test groups by behavior, (4) Given/When/Then in every test.

**Naming convention** — all tests follow: `given <precondition> when <action> then <expected outcome>`. Use the language's idiomatic format (backtick strings, snake_case, descriptive methods).

### 3.3 Edge Cases
Always include where applicable: null/nil/undefined inputs, empty collections, boundary values (max int, zero, empty vs blank), cancellation/timeout for async, rapid sequential calls.

### 3.4 Compile/Lint
Run build or lint. Fix any compilation errors in test code.

**Output**: `.workflows/<target>/03-write.md`

---

## Phase 4: VERIFY

### 4.1 Run New Tests
All must pass. On failure: if test is wrong, fix it; if code has a bug, report to user (do NOT fix production code unless asked).

### 4.2 Run Full Suite
Verify new tests don't break existing tests.

### 4.3 Quality Check
Each test: tests ONE behavior, uses Given/When/Then naming, mocks only outside boundary, is deterministic, tests behavior not implementation details.

### 4.4 Coverage
Run coverage tool if available. Compare against target.

**Output**: `.workflows/<target>/04-verify.md`

---

## Phase 5: REPORT

### 5.1 Summary
```
Test Report: <target>
  Test file(s):   <path(s)>
  Written/Passing: <N>/<N>
  Coverage:        <pct>% (target: <pct>%)
  Breakdown:       <happy> happy, <error> error, <edge> edge, <state> state
  Uncovered:       <list of uncovered branches>
  Gaps:            <scenario: reason>
  Quality Notes:   <observations>
```

### 5.2 Gap Analysis
If below target: list each gap with reason and recommendation (needs integration test, dead code, requires refactor to test).

### 5.3 Commit
```bash
git add <test-files>
git commit -m "test(<scope>): add tests for <target> (<coverage>% coverage)"
```

**Output**: `.workflows/<target>/05-report.md`

---

## State Management

When invoked via `/start`, the orchestrator handles state updates automatically. This skill does not manage state directly.

## Error Handling

| Error | Resolution |
|---|---|
| Target not found | Ask user for correct name or path |
| No test framework detected | Suggest adding test deps for the language |
| Cannot achieve coverage target | Report gaps; ask user to accept or adjust |
| Flaky test | Identify non-determinism and fix |

## Anti-Patterns

- Do NOT test private methods (test through public API)
- Do NOT mock data classes or value objects
- Do NOT depend on test execution order
- Do NOT use real delays/sleeps (use test timing controls)
- Do NOT assert on implementation details (internal state, exact call counts)
- Do NOT write tests that always pass regardless of behavior
- Do NOT hardcode environment-specific paths or config
