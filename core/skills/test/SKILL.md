---
name: test
description: Generate comprehensive tests for a target class, file, module, or feature with coverage analysis, boundary classification, and gap reporting.
---

# Test Workflow

## Command

```
/workflow:test <target> [--coverage <pct>] [--type <unit|integration>]
```

**Target formats**:
- `class:ClassName` — Test a specific class
- `file:path/to/File.kt` — Test a specific file
- `module:moduleName` — Test all public API in a module
- `feature:featureName` — Test a feature end-to-end

**Defaults**:
- Coverage target: 90%
- Type: unit

## Overview

Generates well-structured tests with high coverage. Five phases: **ANALYZE -> PLAN -> WRITE -> VERIFY -> REPORT**.

---

## Phase 1: ANALYZE

**Goal**: Understand what needs testing and identify all test boundaries.

### Step 1.1 — Locate the Target

Based on target format:

**class:ClassName**:
```bash
grep -r "class <ClassName>" --include="*.kt" -l
grep -r "interface <ClassName>" --include="*.kt" -l
```

**file:path/File.kt**:
Read the file directly.

**module:moduleName**:
```bash
find . -path "*/<moduleName>/src/main" -type d
```
List all public classes in the module.

**feature:featureName**:
```bash
find . -type d -name "*<featureName>*"
```
Map all classes in the feature package.

### Step 1.2 — Analyze Public API

For each target class, extract:

- **Public functions**: Name, parameters, return type, nullability
- **Public properties**: Name, type, mutability
- **Constructors**: Parameters, defaults, injected dependencies
- **State flows**: Exposed StateFlow/SharedFlow types
- **Sealed classes/interfaces**: All subtypes
- **Companion object members**: Factory methods, constants

Document as a structured list:

```
Target: <ClassName>
  Constructor:
    - dep1: Dependency1 (injectable)
    - dep2: Dependency2 (injectable)
  Functions:
    - fun doAction(input: String): Result<Output>
    - suspend fun fetchData(id: Int): Data?
  Properties:
    - val state: StateFlow<UiState>
    - val events: SharedFlow<Event>
  Inner Types:
    - sealed class UiState { Loading, Success(data), Error(msg) }
```

### Step 1.3 — Identify Dependencies

Categorize each dependency:

| Dependency | Type | Mock Strategy |
|---|---|---|
| Repository | Interface | Mock (fake implementation) |
| UseCase | Class with interface | Mock |
| Context | Android framework | Robolectric or mock |
| Dispatcher | CoroutineDispatcher | TestDispatcher |
| SharedPreferences | Android framework | Fake or mock |
| Database | Room DAO | In-memory test DB |
| API Service | Retrofit interface | Mock |
| Logger/Analytics | Side-effect only | Mock (verify calls) |

### Step 1.4 — Map Code Branches

For each public function, identify:

- **Happy path**: Normal successful execution
- **Error paths**: Exceptions, error states, null returns
- **Edge cases**: Empty collections, boundary values, null inputs
- **Concurrency paths**: Race conditions, cancellation
- **State-dependent paths**: Behavior that changes based on current state

Document as a branch map:

```
fun doAction(input: String): Result<Output>
  Branches:
    1. input is valid → returns Success(output)
    2. input is empty → returns Failure(ValidationError)
    3. input is blank → returns Failure(ValidationError)
    4. repository throws IOException → returns Failure(NetworkError)
    5. repository returns null → returns Failure(NotFoundError)
    6. concurrent calls → second call waits for first
```

### Step 1.5 — Check Existing Tests

```bash
# Find existing test files
find . -path "*/test*" -name "*<ClassName>*Test*.kt" -o -name "*<ClassName>*Spec*.kt"
```

If tests exist:
- Read them
- Document what is already covered
- Identify gaps (uncovered branches from Step 1.4)

**Output**: Complete analysis with branch map, dependency classification, and existing coverage gaps.

---

## Phase 2: PLAN

**Goal**: Design the test structure and prioritize test cases.

### Step 2.1 — Define Test Boundaries

Classify what to test vs what to mock:

**Test boundary (inside)**: The target class itself and its direct logic.

**Mock boundary (outside)**:
- All injected dependencies (repositories, use cases, services)
- Android framework classes
- System resources (file system, network)
- Time/clock
- Random number generation

**Do NOT mock**:
- Data classes (models, DTOs)
- Pure functions (mappers, validators)
- Sealed class hierarchies (state, events)
- Extension functions used by the target

### Step 2.2 — Generate Test Case List

For each branch identified in Phase 1:

```
Test Cases for <ClassName>:

1. [HAPPY] should return success when input is valid
2. [ERROR] should return validation error when input is empty
3. [ERROR] should return validation error when input is blank
4. [ERROR] should return network error when repository throws IOException
5. [ERROR] should return not found when repository returns null
6. [EDGE]  should handle concurrent calls gracefully
7. [STATE] should emit Loading state before fetching
8. [STATE] should emit Success state after fetch completes
9. [STATE] should emit Error state when fetch fails
```

Tag each: `[HAPPY]`, `[ERROR]`, `[EDGE]`, `[STATE]`, `[INTEGRATION]`

### Step 2.3 — Estimate Coverage

Count total branches from analysis. Count planned test cases. Calculate expected coverage:

```
Total branches: 15
Planned tests:  14
Expected coverage: 93% (target: 90%) ✓
```

If below target: add more test cases for uncovered branches.

### Step 2.4 — Plan Test File Structure

```
Test Files:
  <ClassName>Test.kt
    - Setup: mock dependencies, create SUT
    - Group: "doAction"
      - test cases 1-6
    - Group: "state management"
      - test cases 7-9
    - Group: "edge cases"
      - test cases 10+
```

For `module:` or `feature:` targets, plan multiple test files.

---

## Phase 3: WRITE

**Goal**: Write the actual test code.

### Step 3.1 — Setup Test Infrastructure

Determine the test framework from the project:

```bash
grep -r "testImplementation" --include="*.gradle.kts" | head -10
```

Common setups:
- **JUnit 5 + MockK**: Kotlin projects
- **JUnit 4 + Mockito**: Java/mixed projects
- **Kotest**: Kotlin-first projects
- **Turbine**: Flow testing
- **Robolectric**: Android classes without device

### Step 3.2 — Write Test File

Follow this structure:

```kotlin
class <ClassName>Test {

    // === Dependencies (mocked) ===
    private val mockDep1 = mockk<Dependency1>()
    private val mockDep2 = mockk<Dependency2>()
    private val testDispatcher = StandardTestDispatcher()

    // === System Under Test ===
    private lateinit var sut: ClassName

    @BeforeEach
    fun setup() {
        sut = ClassName(
            dep1 = mockDep1,
            dep2 = mockDep2,
            dispatcher = testDispatcher,
        )
    }

    // === doAction ===

    @Test
    fun `given valid input when doAction called then returns success`() {
        // Given
        val input = "valid"
        coEvery { mockDep1.fetch(input) } returns Result.success(output)

        // When
        val result = sut.doAction(input)

        // Then
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(expectedOutput)
    }

    @Test
    fun `given empty input when doAction called then returns validation error`() {
        // Given
        val input = ""

        // When
        val result = sut.doAction(input)

        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(ValidationError::class.java)
    }

    // ... more tests following Given/When/Then pattern
}
```

### Naming Convention

All test methods MUST use this format:

```
`given <precondition> when <action> then <expected outcome>`
```

Examples:
- `` `given empty list when getFirst called then returns null` ``
- `` `given network error when fetchData called then emits Error state` ``
- `` `given user is logged in when navigate called then opens dashboard` ``

### Step 3.3 — Write Flow/State Tests

For ViewModels or classes with Flow:

```kotlin
@Test
fun `given fetch succeeds when init then state transitions from Loading to Success`() = runTest {
    // Given
    coEvery { repository.getData() } returns testData

    // When
    val sut = createViewModel()

    // Then
    sut.state.test {
        assertThat(awaitItem()).isEqualTo(UiState.Loading)
        assertThat(awaitItem()).isEqualTo(UiState.Success(testData))
        cancelAndIgnoreRemainingEvents()
    }
}
```

### Step 3.4 — Write Edge Case Tests

Always include:
- Null inputs (if parameters are nullable)
- Empty collections
- Boundary values (Int.MAX_VALUE, empty string vs blank string)
- Cancellation (for suspend functions)
- Rapid sequential calls

### Step 3.5 — Compile Tests

```bash
<build-command>
```

Fix any compilation errors in the test code.

---

## Phase 4: VERIFY

**Goal**: Run tests and verify they all pass.

### Step 4.1 — Run New Tests

```bash
<test-command> --tests "*<ClassName>Test*"
```

All tests MUST pass. If any fail:

1. Read the failure output
2. Determine if the test is wrong or the code has a bug
3. If test is wrong: fix the test
4. If code has a bug: report it to the user (do NOT fix production code in the test workflow unless asked)

### Step 4.2 — Run Full Test Suite

```bash
<full-test-command>
```

Verify new tests do not interfere with existing tests.

### Step 4.3 — Verify Test Quality

Self-review each test:

- Does it test ONE thing? (Single assertion focus)
- Does it use the Given/When/Then naming convention?
- Does it mock only what is outside the test boundary?
- Is the test deterministic? (No random, no real time, no real network)
- Would the test fail if the behavior changed? (Not testing implementation details)

### Step 4.4 — Coverage Measurement

If coverage tooling is available:

```bash
<coverage-command>
```

Compare against target (default 90%).

---

## Phase 5: REPORT

**Goal**: Generate a coverage and quality report.

### Step 5.1 — Generate Report

Print:

```
Test Report: <target>

Summary:
  Target:          <ClassName / module / feature>
  Test file(s):    <path(s)>
  Tests written:   <count>
  Tests passing:   <count>
  Coverage:        <pct>% (target: <target-pct>%)

Coverage Breakdown:
  Happy paths:     <count> tests
  Error paths:     <count> tests
  Edge cases:      <count> tests
  State tests:     <count> tests

Branch Coverage:
  Total branches:  <N>
  Covered:         <N>
  Uncovered:       <list uncovered branches>

Gaps (if any):
  - <uncovered scenario 1>: <reason not covered>
  - <uncovered scenario 2>: <reason not covered>

Quality Notes:
  - <any observations about test quality or code quality>
```

### Step 5.2 — Gap Analysis

If coverage is below target, list specific gaps:

```
Coverage Gaps:
  1. <ClassName>.methodX — branch when <condition>
     Reason: Requires integration test (not unit testable)
     Recommendation: Add integration test separately

  2. <ClassName>.methodY — error handling for <exception>
     Reason: Exception is unreachable in current code
     Recommendation: Remove dead code or add test if reachable
```

### Step 5.3 — Commit Tests

```bash
git add <test-files>
git commit -m "test(<scope>): add tests for <target> (<coverage>% coverage)"
```

---

## Error Handling

| Error | Resolution |
|---|---|
| Target class not found | Ask user for correct name or path |
| No test framework configured | Suggest adding testImplementation dependencies |
| Test fails due to missing dependency | Add required test dependency to build.gradle.kts |
| Cannot achieve coverage target | Report gaps with justification; ask user to accept or adjust target |
| Android class without Robolectric | Suggest adding Robolectric or restructuring to extract testable logic |
| Flaky test (passes sometimes) | Identify non-determinism (time, threading, order) and fix it |

## Anti-Patterns (DO NOT)

- Do NOT test private methods directly (test through public API)
- Do NOT mock data classes or value objects
- Do NOT write tests that depend on execution order
- Do NOT use `Thread.sleep()` in tests (use test dispatchers)
- Do NOT assert on implementation details (mock call counts, internal state)
- Do NOT write a test that always passes regardless of behavior
