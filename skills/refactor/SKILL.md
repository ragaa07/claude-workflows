---
name: refactor
description: Safely refactor code with dependency graph mapping, behavioral contracts, incremental migration, and rollback at every step.
---

# Refactor Workflow

`/refactor <target> [--scope <file|module|feature>] [--goal <description>] [--skip-brainstorm]`

**Targets**: `class:Name`, `file:path/to/file`, `module:name`, `feature:name`

Restructure existing code while preserving all external behavior. **Phases**: ANALYZE -> BRAINSTORM -> CONTRACT -> DESIGN -> MIGRATE -> VERIFY -> PR.

**Core principle**: Identical outputs for identical inputs. Every step must compile and pass tests. Breaks behavior -> roll back.

> Follow orchestration Rules 0-1 for state and output.

---

## Phase 1: ANALYZE

**Goal**: Build complete dependency graph and assess blast radius.

1. **Identify target** — Locate definition and all related files using project-appropriate patterns.
2. **Map inbound deps** — All consumers: direct callers, subclasses/implementors, DI consumers, test consumers.
3. **Map outbound deps** — Imports: libraries, project modules, system resources.
4. **Map public API surface** — Every public member: functions, properties, types.
5. **Measure current state** — LOC, public member count, complexity estimate, dependent count, test coverage.

**>> Write output to**: `.workflows/<target>/01-analyze.md` (Dependency graph and blast radius)

---

## Phase 2: BRAINSTORM

**Goal**: Explore refactoring approaches before committing to a plan.

**Skip condition**: Skip if `--skip-brainstorm` passed OR `workflows.refactor.require_brainstorm` is `false` in `.workflows/config.yml`. If skipping, mark as `SKIPPED` in state and proceed to Phase 3.

### Execute (inline brainstorm — see Rule 9)

Run brainstorm within this workflow context:
1. **Constraint Mapping**: Ask user for constraints. Focus on: structural approach (extract, inline, reshape), migration strategy (parallel run, strangler fig, big bang), dependency management.
2. **Generate Options**: Seed with 1 approach from the analysis. Build alternatives.
3. **Trade-off Matrix**: Score with blast radius as highest-weighted criterion.
4. **Recommend**: Present recommendation. Lowest blast radius wins ties. Ask: "Which approach? Or suggest an alternative."

**>> Write output to**: `.workflows/<target>/02-brainstorm.md`.

---

## Phase 3: CONTRACT

**Goal**: Document exact behavioral contract BEFORE changing any code.

Document: **Invariants** (I/O pairs, side effects, error conditions), **Public API** (signatures that must not change), **Performance** (latency/memory bounds), **Threading** (context/dispatcher requirements), **Test coverage** (count, gaps).

Map every test assertion to an invariant. Missing coverage -> add tests BEFORE refactoring.

**Decision Point**: Present contract. Ask: "Does this capture all expected behaviors?"

**>> Write output to**: `.workflows/<target>/03-contract.md`.

---

## Phase 4: DESIGN

**Goal**: Create incremental migration plan where every step compiles and passes tests.

### 4.1 — Design Target State

Describe post-refactor code: new structure, new abstractions, new module boundaries.

### 4.2 — Plan Migration Steps

Write the migration plan to `.workflows/<target>/plan.md`. Each step must include:
- Action, files affected, compile command, test command, rollback command, commit message

Each step MUST satisfy: project compiles, all tests pass, step is independently revertable.

**Migration safety rules**:
1. Never delete old code until new code is proven equivalent
2. Use language-appropriate deprecation mechanism during transition
3. Run full test suite after each step, not just target tests
4. If any step fails tests: revert immediately, do not debug in-place

### 4.3 — Estimate Blast Radius Per Step

For each step: files directly changed, transitive dependents affected, risk level.

Present plan. Ask: "Approve migration plan or request changes?"

**>> Write output to**: `.workflows/<target>/04-design.md`.

---

## Phase 5: MIGRATE

**Goal**: Execute migration step by step with strict verification.

### Per-Step Protocol

For each step:
1. **Read** — Re-read files (they may have changed since analysis)
2. **Implement** — Make changes for this step ONLY
3. **Compile** — Run build. Fail -> revert, retry (max 3). 3 failures -> REPLAN
4. **Test** — Run FULL test suite. Fail -> revert immediately. Behavior change -> REPLAN. Test depends on internals -> update test (document why)
5. **Contract check** — Verify invariants still hold
6. **Commit** — Atomic commit: `refactor(<scope>): <step description>`
7. **Record rollback** — Note commit hash

### Parallel Deprecation Pattern

Create new alongside old -> mark old deprecated (language-appropriate) -> migrate consumers one-by-one -> delete old after all migrated -> verify no references remain.

### REPLAN Protocol

Revert to last good commit -> document failure -> re-evaluate approach -> revised plan -> user approval.

**>> Write output to**: `.workflows/<target>/05-migrate.md`.

---

## Phase 6: VERIFY

**Goal**: Prove the refactoring preserves all behavior.

1. **Full test suite** — Every test must pass. Zero tolerance.
2. **Contract verification** — Check each invariant: VERIFIED or FAILED. Point to covering test.
3. **Metrics comparison** — Compare before/after: LOC, public members, dependents, test count.
4. **Cleanup check** — No deprecation markers remain, no unused imports, no dead code, no refactor TODOs. Check `${CLAUDE_PLUGIN_ROOT}/rules/` for project-specific style rules.

**Verification failure**: Critical -> revert entire refactor. Minor -> fix and re-verify.

**>> Write output to**: `.workflows/<target>/06-verify.md`.

---

## Phase 7: PR

**Goal**: Create PR with full context for reviewers.

### Quality Gate

Confirm ALL: full tests pass, all contract invariants VERIFIED, no deprecation markers remain, metrics documented. Load `${CLAUDE_PLUGIN_ROOT}/reviews/general-checklist.md` + language-specific checklist. Self-check High/Critical items. Fix violations before creating PR. Gate failure -> return to appropriate phase.

PR body: summary, motivation, approach, contract verification checklist, per-step changes, metrics table, rollback plan (`git revert <first>..<last>`).

```bash
git push -u origin <branch>
gh pr create --base <dev_branch> --title "refactor(<scope>): <goal>" --body "<pr-body>"
```

**>> Write output to**: `.workflows/<target>/07-pr.md`.

**After this final phase**: Move `.workflows/current-state.md` to `.workflows/history/<target>-<YYYY-MM-DD>.md`. Report completion.

---

## Error Handling

| Error | Resolution |
|---|---|
| Target exceeds `workflows.refactor.max_dependents` (default 50) | Warn user; split into smaller refactors or get confirmation to proceed |
| No tests exist for target | Write contract-based tests first, then refactor |
| Circular dependencies discovered | Address as separate prerequisite refactor |
| Performance regression detected | Profile, optimize, or revert to previous approach |
| Migration step breaks unrelated test | Investigate transitive dependency; likely hidden coupling |
