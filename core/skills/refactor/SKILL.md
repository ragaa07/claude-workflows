---
name: refactor
description: Safely refactor code with dependency graph mapping, behavioral contracts, incremental migration, and rollback at every step.
---

# Refactor Workflow

## Command

```
/refactor <target> [--scope <file|module|feature>] [--goal <description>] [--skip-brainstorm]
```

**Target formats**: `class:Name`, `file:path/to/file`, `module:name`, `feature:name`

## Overview

Restructure existing code while preserving all external behavior. Seven phases: **ANALYZE -> BRAINSTORM -> CONTRACT -> DESIGN -> MIGRATE -> VERIFY -> PR**.

**Core principle**: Refactored code MUST produce identical outputs for identical inputs. Every step must compile and pass tests. If any step breaks behavior, roll back and re-approach.

## BEFORE YOU START — Initialize State

Check if `.workflows/current-state.md` exists (it may have been created by `/start`).

**If it does NOT exist**, create it now. Run these commands and create the file:

```bash
mkdir -p .workflows/<target>
```

Then use your **Write tool** to create `.workflows/current-state.md`:

```
# Workflow State

- **workflow**: refactor
- **feature**: <target>
- **phase**: ANALYZE
- **started**: <current ISO-8601 timestamp>
- **updated**: <current ISO-8601 timestamp>
- **branch**:
- **output_dir**: .workflows/<target>/
- **retry_count**: 0

## Phase History

| Phase | Status | Timestamp | Output | Notes |
|-------|--------|-----------|--------|-------|
| ANALYZE | ACTIVE | <timestamp> | | Starting workflow |

## Phase Outputs

_Documents produced by each phase:_

## Context

_Key decisions and resume context:_
```

**If it already exists**, read it and continue from the current active phase.

**Verify**: Read `.workflows/current-state.md` to confirm it exists before proceeding.

---

## AFTER EVERY PHASE — You MUST Create Files

After completing each phase below, do these TWO things using your tools before moving on:

**Action 1 — Create the phase output file.** Use your **Write tool** to create the file at the path shown at the end of each phase (the `>> Write output to` line). Use this format:

```
# <Phase Name> — <Feature>

**Date**: <ISO-8601>
**Status**: Complete

## Summary
<1-3 sentences>

## Details
<Phase-specific content>

## Decisions
<Key decisions>

## Next Phase Input
<What next phase needs>
```

**Action 2 — Rewrite the state file.** Use your **Write tool** to REWRITE the entire `.workflows/current-state.md` file. Read the current content first, then write the full file back with these updates:
- Update `phase` and `updated` in the header
- In Phase History table: change the completed phase status to `COMPLETED`, add output filename, add new row for next phase as `ACTIVE`
- Under `## Phase Outputs`: add a link to the new output file
- Under `## Context`: add key decisions from this phase

**You must REWRITE the whole file — do not try to edit individual lines. Do NOT proceed to the next phase until both files are written.**

---

## Phase 1: ANALYZE

**Goal**: Build complete dependency graph and assess blast radius.

1. **Identify target** — Search using project-appropriate patterns (language-specific extensions, build system conventions). Locate definition and all related files.
2. **Map inbound dependencies** — Find all consumers. Categorize as: direct callers, subclasses/implementors, DI consumers, test consumers.
3. **Map outbound dependencies** — Analyze imports: libraries, project modules, system resources (files, network, database).
4. **Map public API surface** — Document every public member: functions, properties, types.
5. **Measure current state** — Record: lines of code, public member count, cyclomatic complexity (estimate), direct dependent count, test coverage.

**>> Write output to**: `.workflows/<target>/01-analyze.md` — then update `.workflows/current-state.md` (see State Tracking above). (Dependency graph and blast radius)

---

## Phase 2: BRAINSTORM

**Goal**: Explore refactoring approaches before committing to a plan.

**Skip condition**: Skip if `--skip-brainstorm` passed OR `workflows.refactor.require_brainstorm` is `false` in `.claude/workflows.yml`. If skipping, mark as `SKIPPED` in state and proceed to Phase 3.

Delegate to the brainstorm skill with Phase 1 context. Focus on:
1. Structural approach (extract, inline, reshape)
2. Migration strategy (parallel run, strangler fig, big bang)
3. Dependency management (how to decouple consumers)

Present recommendation. Lowest blast radius wins ties. Ask: "Which approach? Or suggest an alternative."

**>> Write output to**: `.workflows/<target>/02-brainstorm.md` — then update `.workflows/current-state.md`.

---

## Phase 3: CONTRACT

**Goal**: Document exact behavioral contract BEFORE changing any code.

Create the behavioral contract document covering:
- **Invariants**: Input/output pairs, conditional behaviors, side effects, error conditions
- **Public API contract**: Signatures that must not change (or must be deprecated with forwarding)
- **Performance contract**: Latency bounds, memory limits
- **Threading/concurrency contract**: Thread/context/dispatcher requirements
- **Test coverage**: Count, locations, gaps

Map every test assertion to a contract invariant. If tests are missing for an invariant, add them BEFORE starting the refactor.

**Decision Point**: Present contract. Ask: "Does this contract capture all expected behaviors?"

**>> Write output to**: `.workflows/<target>/03-contract.md` — then update `.workflows/current-state.md`.

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

**>> Write output to**: `.workflows/<target>/04-design.md` — then update `.workflows/current-state.md`.

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

1. Create new implementation alongside old
2. Mark old with language-appropriate deprecation (e.g., `@Deprecated` Java/Kotlin, `warnings.warn` Python, `#[deprecated]` Rust, JSDoc `@deprecated` JS/TS)
3. Migrate consumers one by one (each a separate step)
4. Delete old only after all consumers migrated
5. Verify no references remain using project-appropriate search

### REPLAN Protocol

Revert to last good commit -> document failure -> re-evaluate approach -> revised plan -> user approval.

**>> Write output to**: `.workflows/<target>/05-migrate.md` — then update `.workflows/current-state.md`.

---

## Phase 6: VERIFY

**Goal**: Prove the refactoring preserves all behavior.

1. **Full test suite** — Every test must pass. Zero tolerance.
2. **Contract verification** — Check each invariant: VERIFIED or FAILED. Point to covering test.
3. **Metrics comparison** — Compare before/after: LOC, public members, dependents, test count.
4. **Cleanup check** — No deprecation markers remain, no unused imports, no dead code, no refactor TODOs. Check `.claude/rules/` for project-specific style rules.

**Verification failure**: Critical -> revert entire refactor. Minor -> fix and re-verify.

**>> Write output to**: `.workflows/<target>/06-verify.md` — then update `.workflows/current-state.md`.

---

## Phase 7: PR

**Goal**: Create PR with full context for reviewers.

### Quality Gate

Confirm ALL before creating PR:
- Full test suite passes
- All contract invariants VERIFIED
- No deprecation markers remain
- Metrics comparison documented
- `.claude/reviews/` conventions followed (if they exist)

If any gate fails, return to the appropriate phase.

### PR Body

Include: summary, motivation, approach, behavioral contract verification checklist, per-step changes, metrics table, testing checklist, rollback plan (`git revert <first>..<last>`).

```bash
git push -u origin <branch>
gh pr create --base <dev_branch> --title "refactor(<scope>): <goal>" --body "$(cat <<'EOF'
<pr-body>
EOF
)"
```

**>> Write output to**: `.workflows/<target>/07-pr.md` — then update `.workflows/current-state.md`.

**After this final phase**: Move `.workflows/current-state.md` to `.workflows/history/<target>-<YYYY-MM-DD>.md`. Report completion.

---

## Error Handling

| Error | Resolution |
|---|---|
| Target has 50+ dependents | Split into smaller refactors |
| No tests exist for target | Write contract-based tests first, then refactor |
| Circular dependencies discovered | Address as separate prerequisite refactor |
| Performance regression detected | Profile, optimize, or revert to previous approach |
| Migration step breaks unrelated test | Investigate transitive dependency; likely hidden coupling |
