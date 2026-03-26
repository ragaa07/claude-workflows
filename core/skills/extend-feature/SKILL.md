---
name: extend-feature
description: Extend an existing feature with new capabilities while preserving backward compatibility, using minimal-impact rules and structured brainstorming.
---

# Extend Feature Workflow

## Command

```
/workflow:extend-feature <feature-name> <extension-description> [--skip-brainstorm]
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

## Phase 1: ANALYZE

**Goal**: Fully understand the existing feature before touching anything.

Search for the feature using project-appropriate patterns (classes, modules, components, routes, services). Use a sub-agent to map: entry points, business logic, data layer, configuration/wiring, and existing tests.

Identify extension points where new behavior attaches without modifying existing code: new subtypes/variants on existing abstractions, new fields with defaults on state objects, public functions the extension can call, registration mechanisms for new entry points.

Document current behavior: what the user sees/does, data flows, edge cases.

**Phase Output**: `.workflows/<feature>/01-analyze.md`

---

## Phase 2: BRAINSTORM

**Goal**: Explore extension approaches before committing to a plan.

**Skip condition**: `--skip-brainstorm` passed OR `workflows.extend-feature.require_brainstorm` is `false`.

Delegate to the brainstorm skill:
- **Input**: Feature analysis from Phase 1 + extension description
- **Technique preference**: SCAMPER (best fit for extending existing features)
- **Evaluation focus**: Score approaches on modified-files count and changed-signatures count

Always prefer fewer modified files and zero changed signatures.

Present top 2 approaches. Ask: "Which approach? (A/B or suggest alternative)"

**Phase Output**: `.workflows/<feature>/02-brainstorm.md`

---

## Phase 3: PLAN

**Goal**: Create implementation plan with explicit compatibility guarantees.

Write `.claude/plan-<feature-name>-extension.md` containing: architecture summary, chosen approach, compatibility guarantees (no signatures changed, no variants removed, no test assertions modified, no behavior altered), new files (preferred) and modified files (minimal), implementation phases based on project architecture with build/test commands and commit messages, rollback strategy.

**Verify**: Modified files must not exceed new files. No signature changes allowed. Load `.claude/rules/` and apply project-specific rules.

Present plan. Ask: "Approve plan or request changes?"

**Phase Output**: `.workflows/<feature>/03-plan.md`

---

## Phase 4: IMPLEMENT

**Goal**: Execute plan phase by phase.

### Rules

1. **Before modifying any existing file**: Re-read it to confirm current state
2. **After modifying any existing file**: Run the test suite
3. **If a phase requires changing an existing signature**: STOP and REPLAN
4. **Commit after each phase**: Small, atomic, revertable commits
5. **Load `.claude/rules/`**: Apply project-specific coding rules to all changes

### Per-Phase Loop

For each phase: read plan details, implement (new files first, modifications last), run build check, run feature tests, commit.

### REPLAN Trigger

If an existing file needs more changes than planned, a signature must change, or an abstraction needs restructuring: STOP, document the discovery, re-evaluate with user approval.

**Phase Output**: `.workflows/<feature>/04-implement.md`

---

## Phase 5: VERIFY-COMPAT

**Goal**: Prove existing functionality is unbroken.

1. **Run full test suite** — every existing test MUST pass, no exceptions
2. **Behavioral comparison** — for each behavior documented in Phase 1, verify it works identically
3. **API/interface check** — all public signatures unchanged, all data structures retain existing fields (new fields must have defaults), all type variants still exist

If any test fails: fix the new code (not the existing test) to restore compatibility.

**Phase Output**: `.workflows/<feature>/05-verify-compat.md`

---

## Phase 6: TEST

**Goal**: Add tests for the new extension.

**Skip condition**: `workflows.extend-feature.require_tests` is `false`.

Detect the project's test framework and conventions. Create NEW test files (do not modify existing) covering: new functions/logic, new UI states or endpoints, integration with existing feature, edge cases.

Target: 80%+ coverage for new code.

**Phase Output**: `.workflows/<feature>/06-test.md`

---

## Phase 7: PR

**Goal**: Create PR with clear extension documentation.

**Pre-PR quality gate**: If `.claude/reviews/` exists, load review checklists and verify all items pass.

Push branch and create PR. Body must include: summary, changes (new files vs modified), compatibility verification results, and test results.

```bash
git push -u origin <branch>
gh pr create --base <dev_branch> \
  --title "feat(<scope>): extend <feature> with <extension>" \
  --body "<generated-body>"
```

Report PR URL to user.

**Phase Output**: `.workflows/<feature>/07-pr.md`

---

## Error Handling

| Error | Resolution |
|---|---|
| Feature not found | Ask user for correct name or path |
| Feature too complex | Use sub-agent per layer |
| Extension requires breaking changes | Present alternatives; document migration if unavoidable |
| Existing tests fail | Fix new code, not existing tests |
| Plan exceeds minimal impact | Re-brainstorm with stricter constraints |
| gh CLI not authenticated | Guide user through `gh auth login` |
