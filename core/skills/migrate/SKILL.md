---
name: migrate
description: Plan and execute incremental migrations for dependencies, APIs, architecture, and databases.
---

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

- **workflow**: migrate
- **feature**: <feature>
- **phase**: ANALYZE
- **started**: <current ISO-8601 timestamp>
- **updated**: <current ISO-8601 timestamp>
- **branch**:

## Phase History

| Phase | Status | Timestamp | Notes |
|-------|--------|-----------|-------|
| ANALYZE | ACTIVE | <timestamp> | Starting migration analysis |

## Completed Steps


## Artifacts


## Context

```

### Step 0.4 — Read Configuration

Read `.claude/workflows.yml` and note relevant config for this workflow.
Key config: `workflows.migrate.require_brainstorm`

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

**Brainstorm skip**: Skip BRAINSTORM if `--skip-brainstorm` was passed OR `workflows.migrate.require_brainstorm` is `false`. Mark as `SKIPPED`.

# Migration Workflow

## Command

`/workflow:migrate <type>`

Where `<type>` is one of: `dependency`, `api-version`, `architecture`, `database`

## Phases

### Phase 1: ANALYZE

Document the current state before any changes.

**For all types:**
1. Identify all files and modules affected by the migration
2. Document current versions, patterns, or schemas
3. Create a snapshot summary in the plan file

**Type-specific analysis:**

| Type | What to Document |
|------|-----------------|
| `dependency` | Current version, target version, breaking changes from release notes/changelog, all usage sites |
| `api-version` | Current API version, target version, deprecated endpoints, changed request/response shapes |
| `architecture` | Current pattern (files, classes, data flow), target pattern, boundary identification |
| `database` | Current schema (tables, columns, indices, constraints), target schema, data volume estimates |

### Phase 2: BRAINSTORM

**Skip condition**: Skip if `--skip-brainstorm` passed OR `workflows.migrate.require_brainstorm` is `false` in `.claude/workflows.yml`. Mark as `SKIPPED` in Phase History.

Evaluate migration strategies using structured thinking.

**Trade-off Matrix:**

| Strategy | Effort | Risk | Downtime | Rollback Difficulty |
|----------|--------|------|----------|-------------------|
| Big bang | Low | High | High | Hard |
| Incremental | Medium | Low | None | Easy |
| Parallel run | High | Low | None | Easy |
| Strangler fig | Medium | Low | None | Medium |

**Reverse Brainstorm** — ask "How could this migration fail?" to identify risks:
- Data loss scenarios
- Backward compatibility breaks
- Performance regressions
- Partial migration states that break the system

Present the recommended strategy with rationale to the user.

### Phase 3: PLAN

Create an incremental migration plan where each step is independently safe.

Rules:
1. Every step MUST compile after being applied
2. Every step MUST pass existing tests
3. Each step should be a single, reviewable commit
4. Order steps to minimize risk (non-breaking changes first)
5. Include rollback instructions for each step

**Plan structure:**
```
Step 1: [Description] — Risk: Low/Med/High
  Files: [list]
  Rollback: [how to undo]

Step 2: [Description] — Risk: Low/Med/High
  Files: [list]
  Rollback: [how to undo]
  Depends on: Step 1
```

Write the plan to `.claude/plan-migrate-<type>.md`.

### Phase 4: EXECUTE

Apply the plan step by step.

For each step:
1. Apply the changes
2. Run compile check (e.g., `./gradlew compileDebug`, `npm run build`, `cargo check`)
3. Run relevant tests
4. If compile or tests fail, fix before proceeding
5. Commit with descriptive message: `refactor(migrate): step N — <description>`
6. Report progress to the user

If any step fails unexpectedly:
- STOP execution
- Report what failed and why
- Re-evaluate the plan before continuing

### Phase 5: VERIFY

Full verification after all steps are complete.

1. Run the full test suite
2. Run the full build (all variants if applicable)
3. Generate a manual verification checklist:
   - List all changed behaviors
   - List all UI surfaces affected
   - List all API endpoints affected
4. Check for leftover TODOs, deprecated references, or dead code from the migration
5. Run linters and static analysis

### Phase 6: PR

Create a detailed pull request.

**PR body structure:**

```markdown
## Summary
<what was migrated and why>

## Migration Details

| Aspect | Before | After |
|--------|--------|-------|
| Version/Pattern | {old} | {new} |

## Steps Applied
1. {step 1 description} — {commit hash}
2. {step 2 description} — {commit hash}

## Rollback Plan
{how to revert if issues are found in production}

## Testing
- [ ] Full test suite passes
- [ ] Build succeeds for all variants
- [ ] Manual verification of {critical paths}

## Breaking Changes
{list any breaking changes, or "None"}
```

## Type-Specific Guidance

### dependency

- Always read the library's migration guide or changelog first
- Search codebase for all import statements and API usage of the dependency
- Check for transitive dependency conflicts
- For major version bumps, prefer the adapter/compatibility layer approach when available
- Update lock files (`gradle.lockfile`, `package-lock.json`, `Cargo.lock`)

### api-version

- Implement the new API client alongside the old one (parallel run)
- Add feature flag to toggle between old and new API
- Map old response models to new ones with an adapter layer
- Monitor error rates after switching
- Keep the old client code until the new version is stable in production

### architecture

- Use the Strangler Fig pattern: wrap old code, route new calls through the new pattern
- Never rewrite more than one module at a time
- Maintain the public API contract while changing internals
- Add integration tests at the boundary before starting
- Document the target architecture in the plan file with a diagram or description

### database

- Always create reversible migrations (up + down)
- For schema changes: add new columns/tables first, migrate data, then remove old
- Never drop columns in the same migration that adds the replacement
- Test with realistic data volumes
- For large tables, consider online schema change tools
- Back up before applying destructive migrations

## Notes

- Migrations are high-risk operations. Always get user confirmation before Phase 4.
- If the migration scope is larger than expected, re-plan rather than push through.
- Document lessons learned in `tasks/lessons.md` after completion.
