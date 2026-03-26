---
name: migrate
description: Plan and execute incremental migrations for dependencies, APIs, architecture, and databases.
---

# Migration Workflow

## Command

`/migrate <type>`

Where `<type>` is one of: `dependency`, `api-version`, `architecture`, `database`

## BEFORE YOU START — Initialize State

Check if `.workflows/current-state.md` exists (it may have been created by `/start`).

**If it does NOT exist**, create it now. Run these commands and create the file:

```bash
mkdir -p .workflows/<type>
```

Then use your **Write tool** to create `.workflows/current-state.md`:

```
# Workflow State

- **workflow**: migrate
- **feature**: <type>
- **phase**: ANALYZE
- **started**: <current ISO-8601 timestamp>
- **updated**: <current ISO-8601 timestamp>
- **branch**:
- **output_dir**: .workflows/<type>/
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

## Phases

### Phase 1: ANALYZE

Document current state before any changes.

1. Identify all files and modules affected by the migration
2. Document current versions, patterns, or schemas
3. Create snapshot summary in plan file

**Type-specific analysis:**

| Type | What to Document |
|------|-----------------|
| `dependency` | Current/target version, breaking changes from changelog, all usage sites |
| `api-version` | Current/target API version, deprecated endpoints, changed request/response shapes |
| `architecture` | Current pattern (files, classes, data flow), target pattern, boundary identification |
| `database` | Current schema (tables, columns, indices, constraints), target schema, data volume estimates |

**>> Write output to**: `.workflows/<type>/01-analyze.md` — then update `.workflows/current-state.md` (see State Tracking above).

### Phase 2: BRAINSTORM

**Skip condition**: Skip if `--skip-brainstorm` passed OR `workflows.migrate.require_brainstorm` is `false`. If skipping, mark as `SKIPPED` in state and proceed to Phase 3.

Delegate to the **brainstorm skill** for structured strategy evaluation. Provide it:
- Migration context from Phase 1 analysis
- Key strategies to evaluate: big bang, incremental, parallel run, strangler fig
- Risk prompt: "How could this migration fail?" (data loss, backward compat breaks, performance regressions, partial migration states)

Present recommended strategy with rationale to user.

**>> Write output to**: `.workflows/<type>/02-brainstorm.md` — then update `.workflows/current-state.md`.

### Phase 3: PLAN

Create incremental migration plan where each step is independently safe.

Rules:
1. Every step MUST compile and pass existing tests after being applied
2. Each step should be a single, reviewable commit
3. Order steps to minimize risk (non-breaking changes first)
4. Include rollback instructions for each step

**Plan structure:**
```
Step N: [Description] — Risk: Low/Med/High
  Files: [list]
  Rollback: [how to undo]
  Depends on: [prior steps]
```

Write the plan to `.workflows/<type>/plan.md`.

**>> Write output to**: `.workflows/<type>/03-plan.md` — then update `.workflows/current-state.md`.

### Phase 4: EXECUTE

Apply plan step by step. Read `.claude/rules/` for language-specific patterns before starting.

For each step:
1. Apply changes
2. Run compile check (e.g., `./gradlew compileDebug`, `npm run build`, `cargo check`)
3. Run relevant tests
4. If compile/tests fail, fix before proceeding (max 3 attempts per step -- if still failing, STOP and re-evaluate plan)
5. Commit: `refactor(migrate): step N — <description>`
6. Report progress to user

If any step fails unexpectedly: STOP, report what failed and why, re-evaluate plan.

**>> Write output to**: `.workflows/<type>/04-execute.md` — then update `.workflows/current-state.md`. (Steps completed, commits)

### Phase 5: VERIFY

Full verification after all steps complete.

1. Run full test suite
2. Run full build (all variants if applicable)
3. Generate manual verification checklist (changed behaviors, affected UI surfaces, affected endpoints)
4. Check for leftover TODOs, deprecated references, dead code from migration
5. Run linters and static analysis

**>> Write output to**: `.workflows/<type>/05-verify.md` — then update `.workflows/current-state.md`.

### Phase 6: PR

Create detailed pull request.

**Quality gate**: Load `.claude/reviews/general-checklist.md` and the language-specific checklist from `.claude/reviews/`. Verify all High/Critical items pass. Confirm full test suite and build are green.

**PR body structure:**
```markdown
## Summary
<what was migrated and why>

## Migration Details
| Aspect | Before | After |
|--------|--------|-------|
| Version/Pattern | {old} | {new} |

## Steps Applied
1. {step description} — {commit hash}

## Rollback Plan
{how to revert if issues found in production}

## Testing
- [ ] Full test suite passes
- [ ] Build succeeds for all variants
- [ ] Manual verification of {critical paths}

## Breaking Changes
{list or "None"}
```

**>> Write output to**: `.workflows/<type>/06-pr.md` — then update `.workflows/current-state.md`.

**After this final phase**: Move `.workflows/current-state.md` to `.workflows/history/<type>-<YYYY-MM-DD>.md`. Report completion.

## Type-Specific Guidance

### dependency
- Read the library's migration guide/changelog first
- Search codebase for all imports and API usage of the dependency
- Check for transitive dependency conflicts
- For major bumps, prefer adapter/compatibility layer when available
- Update lock files (`gradle.lockfile`, `package-lock.json`, `Cargo.lock`)

### api-version
- Implement new API client alongside old one (parallel run)
- Add feature flag to toggle between old and new
- Map old response models to new with adapter layer
- Keep old client until new version is stable in production

### architecture
- Use Strangler Fig pattern: wrap old code, route new calls through new pattern
- Never rewrite more than one module at a time
- Maintain public API contract while changing internals
- Add integration tests at boundary before starting

### database
- Always create reversible migrations (up + down)
- Add new columns/tables first, migrate data, then remove old
- Never drop columns in same migration that adds replacement
- Test with realistic data volumes; consider online schema change tools
- Back up before destructive migrations

## Notes

- Migrations are high-risk. Always get user confirmation before Phase 4.
- If scope is larger than expected, re-plan rather than push through.
- Document lessons learned in `tasks/lessons.md` after completion.
