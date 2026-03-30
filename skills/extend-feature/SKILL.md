---
name: extend-feature
description: Extend an existing feature with new capabilities while preserving backward compatibility, using minimal-impact rules and structured brainstorming.
---

# Extend Feature Workflow

## Command

```
/extend-feature <feature-name> <extension-description> [--skip-brainstorm]
```

## Overview

Add new capabilities to an existing feature while strictly preserving backward compatibility. Seven phases: **ANALYZE -> BRAINSTORM -> PLAN -> IMPLEMENT -> VERIFY-COMPAT -> TEST -> PR**.

## Core Principle: Minimal Impact

1. Prefer new files over modifying existing ones
2. Prefer additions over changes to existing code
3. Add new public interfaces — do not change existing signatures
4. Add new test files — do not modify existing test assertions
5. If you must modify an existing file, change the fewest lines possible

---

> Follow orchestration Rules 0-1 for state and output.

---

## Phase 1: ANALYZE

**Goal**: Fully understand the existing feature before touching anything.

Map the feature: entry points, business logic, data layer, configuration/wiring, existing tests.

Identify extension points (attach without modifying existing code): new subtypes/variants, new fields with defaults, callable public functions, registration mechanisms.

Document current behavior: user-facing flows, data flows, edge cases.

**>> Write output to**: `.workflows/<feature>/01-analyze.md`.

---

## Phase 2: BRAINSTORM

**Goal**: Explore extension approaches before committing to a plan.

**Skip condition**: `--skip-brainstorm` passed OR `workflows.extend-feature.require_brainstorm` is `false`. If skipping, mark as `SKIPPED` in state and proceed to Phase 3.

### Execute (inline brainstorm — see Rule 9)

Run brainstorm within this workflow context:
1. **Constraint Mapping**: Ask user for constraints. Add implicit constraint: minimal impact (fewer modified files, zero changed signatures).
2. **Generate Options**: Seed with 1 approach from the analysis. Build alternatives with user. Apply SCAMPER technique (best fit for extensions).
3. **Trade-off Matrix**: Score on modified-files count, changed-signatures count, plus standard criteria.
4. **Recommend**: Present top 2 approaches. Ask: "Which approach? (A/B or suggest alternative)"

**>> Write output to**: `.workflows/<feature>/02-brainstorm.md`.

---

## Phase 3: PLAN

**Goal**: Create implementation plan with explicit compatibility guarantees.

Write plan to `.workflows/<feature-name>/plan.md`: architecture summary, chosen approach, compatibility guarantees (no signatures/variants/assertions/behavior changed), new files (preferred) vs modified files (minimal), implementation phases with build/test commands and commit messages, rollback strategy.

**Verify**: Modified files <= new files. No signature changes. Apply `${CLAUDE_PLUGIN_ROOT}/rules/`.

Present plan. Ask: "Approve plan or request changes?"

**>> Write output to**: `.workflows/<feature>/03-plan.md`.

---

## Phase 4: IMPLEMENT

**Goal**: Execute plan phase by phase.

**Rules**: Re-read before modifying existing files. Run tests after each modification. Signature change -> STOP and REPLAN. Atomic commits per phase. Apply `${CLAUDE_PLUGIN_ROOT}/rules/`.

**Per-phase**: read plan -> implement (new files first, modifications last) -> build -> test -> commit.

**REPLAN trigger**: More changes than planned, signature must change, or abstraction needs restructuring -> STOP, document, get user approval.

**>> Write output to**: `.workflows/<feature>/04-implement.md`.

---

## Phase 5: VERIFY-COMPAT

**Goal**: Prove existing functionality is unbroken.

1. **Run full test suite** — every existing test MUST pass, no exceptions
2. **Behavioral comparison** — for each behavior documented in Phase 1, verify it works identically
3. **API/interface check** — all public signatures unchanged, all data structures retain existing fields (new fields must have defaults), all type variants still exist

If any test fails: fix the new code (not the existing test) to restore compatibility.

**>> Write output to**: `.workflows/<feature>/05-verify-compat.md`.

---

## Phase 6: TEST

**Goal**: Add tests for the new extension.

**Skip condition**: `workflows.extend-feature.require_tests` is `false`. If skipping, mark as `SKIPPED` in state and proceed to Phase 7.

Detect the project's test framework and conventions. Create NEW test files (do not modify existing) covering: new functions/logic, new UI states or endpoints, integration with existing feature, edge cases.

Target: 80%+ coverage for new code.

**>> Write output to**: `.workflows/<feature>/06-test.md`.

---

## Phase 7: PR

**Goal**: Create PR with clear extension documentation.

**Pre-PR quality gate**: Load `${CLAUDE_PLUGIN_ROOT}/reviews/general-checklist.md` + language-specific checklist. Self-check High/Critical items. Fix violations.

Push and create PR with: summary, changes (new vs modified files), compatibility results, test results. Report PR URL.

**>> Write output to**: `.workflows/<feature>/07-pr.md`.

**After this final phase**: Move `.workflows/current-state.md` to `.workflows/history/<feature>-<YYYY-MM-DD>.md`. Report completion.

---

## Error Handling

| Error | Resolution |
|---|---|
| Feature not found | Ask user for correct name or path |
| Feature too complex (>20 files or >5 extension points) | Search per layer; consider splitting into multiple extensions |
| Extension requires breaking changes | Present alternatives; document migration if unavoidable |
| Existing tests fail | Fix new code, not existing tests |
| Plan exceeds minimal impact | Re-brainstorm with stricter constraints |
| gh CLI not authenticated | Guide user through `gh auth login` |
