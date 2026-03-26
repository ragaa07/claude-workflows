---
name: migrate
description: Plan and execute incremental migrations for dependencies, APIs, architecture, and databases.
---

# Migration Workflow

## Command

`/workflow:migrate <type>`

Where `<type>` is one of: `dependency`, `api-version`, `architecture`, `database`

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

**Phase Output**: `.workflows/<type>/01-analyze.md`

### Phase 2: BRAINSTORM

**Skip condition**: Skip if `--skip-brainstorm` passed OR `workflows.migrate.require_brainstorm` is `false`. Mark as `SKIPPED` in Phase History.

Delegate to the **brainstorm skill** for structured strategy evaluation. Provide it:
- Migration context from Phase 1 analysis
- Key strategies to evaluate: big bang, incremental, parallel run, strangler fig
- Risk prompt: "How could this migration fail?" (data loss, backward compat breaks, performance regressions, partial migration states)

Present recommended strategy with rationale to user.

**Phase Output**: `.workflows/<type>/02-brainstorm.md`

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

Write plan to `.claude/plan-migrate-<type>.md`.

**Phase Output**: `.workflows/<type>/03-plan.md`

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

**Phase Output**: `.workflows/<type>/04-execute.md` (steps completed, commits)

### Phase 5: VERIFY

Full verification after all steps complete.

1. Run full test suite
2. Run full build (all variants if applicable)
3. Generate manual verification checklist (changed behaviors, affected UI surfaces, affected endpoints)
4. Check for leftover TODOs, deprecated references, dead code from migration
5. Run linters and static analysis

**Phase Output**: `.workflows/<type>/05-verify.md`

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

**Phase Output**: `.workflows/<type>/06-pr.md`

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
