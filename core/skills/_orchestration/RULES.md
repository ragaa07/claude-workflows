# Orchestration Rules

> These rules apply to EVERY workflow execution. Follow them at ALL times.

## Rule 1: Phase Output Documents

After completing each phase, write a markdown file:

```
Path: .workflows/<feature>/<NN>-<phase-name>.md
Example: .workflows/payment-flow/01-analyze.md
```

**Format:**

```markdown
# <Phase Name> — <Feature>

**Date**: <ISO-8601 timestamp>
**Status**: Complete

## Summary
<1-3 sentences>

## Details
<Phase-specific content — see Details Guide below>

## Decisions
<Key decisions and rationale>

## Next Phase Input
<What the next phase needs from this one>
```

**Details Guide** — what to write in `## Details` for each phase type:

| Phase | Details Content |
|-------|----------------|
| GATHER / DETECT | Requirements collected, sources consulted, gaps identified |
| ANALYZE | Architecture map, file inventory, dependency graph, current behavior |
| SPEC | Full feature specification (user stories, acceptance criteria, scope, technical requirements) |
| BRAINSTORM / EXPLORE | Options generated, techniques applied, constraints identified |
| EVALUATE | Trade-off matrix scores, criteria analysis, strengths/weaknesses per option |
| RECOMMEND | Final recommendation with rationale, accepted trade-offs, risks + mitigations |
| CONTRACT | Behavioral invariants, public API surface, performance/threading contracts |
| PLAN / DESIGN | Implementation phases with files, commands, and commit messages |
| BRANCH | Branch name, base branch, git commands used |
| IMPLEMENT / EXECUTE / MIGRATE | Files changed, commits made, issues encountered, compile/test results per step |
| TEST / VERIFY / VERIFY-COMPAT / REGRESSION-TEST | Test results, coverage metrics, pass/fail counts, behavioral verification |
| WRITE | Test code written, file paths, framework setup |
| REPORT | Coverage summary, gap analysis, quality observations |
| FIX | Applied fix details, files changed, diff summary, lines changed count |
| PR | PR URL, title, summary, reviewers assigned |
| CHERRY-PICK | Cherry-pick plan, target branch, potential conflicts |
| PUSH | Commit hash, branch pushed, PR reference |
| MONITOR | CI run status, pass/fail result, retry count |
| DIAGNOSE | Failure category, root cause, affected files/lines |
| CHANGELOG | Categorized commit history, generated changelog entry |
| VERSION-BUMP | Old version, new version, files changed |
| RELEASE-BRANCH | Release branch name, base branch, commits included |
| TAG | Tag name, release URL |
| CONFIGURE | Detection results, user confirmations, config generated |
| CATEGORIZE | File classification, review order, scope summary |
| CHECK | Review findings by category, severity ratings |
| COMMENT | Final review verdict, submitted comments count |

## Rule 2: Update State After Every Phase

Update `.workflows/current-state.md`:

1. Mark completed phase as `COMPLETED` with a note
2. Add output document path to `Output` column
3. Add next phase as `ACTIVE`
4. Update `phase` and `updated` fields
5. Add link under `## Phase Outputs`
6. Update `## Context` with key decisions
7. If a git branch was created, update `branch` field

**Phase statuses**: `ACTIVE`, `COMPLETED`, `SKIPPED`, `FAILED`, `RETRY`
- Use `FAILED` when a phase fails and cannot continue
- Use `RETRY` when a phase is being re-attempted (e.g., CI-fix MONITOR loop)

**Example state after 3 phases:**

```markdown
# Workflow State

- **workflow**: extend-feature
- **feature**: booking-cancellation
- **phase**: PLAN
- **started**: 2026-03-25T10:00:00Z
- **updated**: 2026-03-25T11:45:00Z
- **branch**:
- **output_dir**: .workflows/booking-cancellation/
- **retry_count**: 0

## Phase History

| Phase | Status | Timestamp | Output | Notes |
|-------|--------|-----------|--------|-------|
| ANALYZE | COMPLETED | 2026-03-25T10:00:00Z | 01-analyze.md | Mapped feature architecture |
| BRAINSTORM | COMPLETED | 2026-03-25T11:00:00Z | 02-brainstorm.md | Chose event-driven approach |
| PLAN | ACTIVE | 2026-03-25T11:45:00Z | | Creating implementation plan |

## Phase Outputs

- [01-analyze.md](.workflows/booking-cancellation/01-analyze.md) — Feature architecture analysis
- [02-brainstorm.md](.workflows/booking-cancellation/02-brainstorm.md) — SCAMPER analysis, chose Approach B

## Context

- Feature uses layered architecture
- Chose event-driven approach (Approach B) over direct API call
- Cancellation requires reason selection (mandatory) + optional comment
```

## Rule 3: Skipping Phases

Read `.claude/workflows.yml` → `workflows.<skill>`:
- `require_brainstorm: false` OR `--skip-brainstorm` → skip BRAINSTORM
- `require_tests: false` → skip TEST
- `require_spec: false` → skip SPEC

When skipping: mark as `SKIPPED` in state, no output document, proceed to next phase.

## Rule 4: Quality Gate — Rules & Reviews

**Before writing code** in any implementation phase:
1. Read `.claude/rules/` files matching `project.language` from `.claude/workflows.yml`
2. Follow every DO/DON'T while implementing

**Before creating a PR** (every workflow that ends with PR):
1. Load `.claude/reviews/general-checklist.md`
2. Load the language-specific checklist from `.claude/reviews/` (e.g., `kotlin-checklist.md`)
3. If a team review checklist exists, load it too
4. Self-check all changes against High/Critical items
5. Fix any violations before creating the PR

## Rule 5: Build/Test Command Detection

Before the first implementation phase, detect the project's build system:

| Marker | Build | Test |
|--------|-------|------|
| `build.gradle.kts` / `build.gradle` | `./gradlew build` | `./gradlew test` |
| `package.json` | `npm run build` | `npm test` |
| `Cargo.toml` | `cargo build` | `cargo test` |
| `go.mod` | `go build ./...` | `go test ./...` |
| `pyproject.toml` / `setup.py` | `python -m build` | `python -m pytest` |
| `Package.swift` | `swift build` | `swift test` |
| `CMakeLists.txt` | `cmake --build .` | `ctest` |

Store detected commands. Use them wherever `<build-command>` or `<test-command>` appear.

## Rule 6: Workflow Chaining

Read `chains` from `.claude/workflows.yml`. If a chain is defined for the current workflow + phase, invoke that skill after the phase completes.

Example config: `chains.new-feature.TEST: "/workflow:test"` means after the TEST phase of new-feature, run the test skill.

## Rule 7: Workflow Completion

1. Write the final phase output document
2. Mark final phase as `COMPLETED`
3. Move `.workflows/current-state.md` to `.workflows/history/<feature>-<YYYY-MM-DD>.md`
4. The `.workflows/<feature>/` directory is preserved as archive
5. Report completion summary to user

## Rule 8: Pausing

If user says "pause" or needs to stop:
1. Write in-progress work to current phase output (partial is fine)
2. Update state with current progress
3. Rename `.workflows/current-state.md` to `.workflows/paused-<feature>.md`

## Rule 9: Error Recovery

- Compilation fails 3+ times in a phase → trigger REPLAN
- Plan step is impossible → STOP, document, REPLAN
- User requests change mid-implementation → STOP, REPLAN

**REPLAN**: Stop implementation, document what went wrong, re-analyze remaining phases, generate updated plan, get user approval, resume.
