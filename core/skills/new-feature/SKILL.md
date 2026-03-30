---
name: new-feature
description: "Complete feature development workflow from requirements through PR, including spec writing, brainstorming, planning, implementation, testing, and PR creation."
---

# New Feature Workflow

```
/new-feature <name> [--from-jira <ticket>] [--from-figma <url>] [--from-spec <path>] [--skip-brainstorm]
```

**Prerequisites**: `.claude/workflows.yml` exists. Git working tree is clean.

**Config references**: Read `.claude/workflows.yml` for `project.language`, `project.type`, `git.branches.*`, and `workflows.new-feature.*` throughout this workflow.

> **State & Output**: Follow Rules 0-1 in `.claude/skills/_orchestration/RULES.md` — initialize state before starting, write phase output + update state after every phase.

---

## Phase 1: GATHER

**Goal**: Collect all requirements into a unified understanding.

### Input routing

| Flag | Action |
|---|---|
| `--from-jira <ticket>` | Fetch via `mcp__atlassian__getJiraIssue`. Extract title, description, acceptance criteria, subtasks, priority. Fetch subtasks via JQL `parent = <ticket>`. **If MCP unavailable**: print warning, fall back to interactive. |
| `--from-figma <url>` | Fetch via `mcp__figma__get_design_context` + `mcp__figma__get_screenshot`. Extract screens, components, design tokens, interactions. **If MCP unavailable**: ask user to describe UI manually. |
| `--from-spec <path>` | Read and parse the file directly. |
| No flags | Interactive mode (see below). |

### Interactive gathering

Ask sequentially:
1. "What does this feature do? (1-2 sentences)"
2. "What are the acceptance criteria?"
3. "Any UI designs? (Figma URL or description)"
4. "Any API changes needed?"
5. "What existing features does this interact with, and any constraints?"

### Adaptive depth

If `workflows.new-feature.adaptive` is `true` in config, estimate complexity after gathering requirements:

| Signal | Depth | Effect |
|--------|-------|--------|
| 1-2 files, <20 lines estimated | **Trivial** | Skip SPEC, BRAINSTORM. Lightweight plan. |
| 3-10 files, clear scope | **Standard** | Normal workflow (all phases) |
| >10 files, architectural changes | **Complex** | Force deep brainstorm, require spec approval |

Announce: "Estimated complexity: [depth]. Adjusting workflow accordingly." User can override: `--depth full` forces all phases.

### Gate

Do NOT proceed if acceptance criteria are undefined. List missing info and ask user to provide or confirm.

**>> Write output to**: `.workflows/<name>/01-gather.md` — then update `.workflows/current-state.md` (see State Tracking above).

---

## Phase 2: SPEC

**Goal**: Produce a formal specification from gathered requirements.

### Generate spec

If `.claude/templates/spec.md.tmpl` exists, use it as the template. Otherwise use this structure:

Write the spec document with this structure:
- **Metadata**: date, source, status (Draft), author
- **Summary**: 1-3 sentences
- **User Stories**: derived from requirements
- **Acceptance Criteria**: checkable list
- **Scope**: in-scope / out-of-scope
- **Technical Requirements**: API changes, data model, UI/UX
- **Dependencies**
- **Edge Cases**
- **Open Questions**

### Approval gate

Present spec summary. Ask: "Review the spec. Reply with changes or 'approved' to proceed."
- Changes requested: update and re-present.
- Approved: proceed.
- Rejected 3+ times: ask if feature scope needs rethinking.

**>> Write output to**: `.workflows/<name>/02-spec.md` — then update `.workflows/current-state.md`.

---

## Phase 3: BRAINSTORM

**Skip if**: `--skip-brainstorm` flag OR `workflows.new-feature.require_brainstorm` is `false` in config. If skipping, mark as `SKIPPED` in state and proceed to Phase 4.

### Execute (Rule 9 delegation)

Execute brainstorm inline per Rule 9: Read `.claude/skills/brainstorm/SKILL.md` and run its **EXPLORE -> EVALUATE -> RECOMMEND** phases within this workflow context.

Delegation parameters:
- **depth**: `standard` (or override from `workflows.new-feature.brainstorm_depth` in config)
- **topic**: the feature spec produced in Phase 2
- **output**: write to this workflow's `.workflows/<name>/` directory

### Approval gate

User selects an approach. Document choice under "## Chosen Approach" in the spec.

**>> Write output to**: `.workflows/<name>/03-brainstorm.md` — then update `.workflows/current-state.md`.

---

## Phase 4: PLAN

**Goal**: Create a phased implementation plan tailored to the project's architecture.

### Read context

1. Read `.claude/workflows.yml` -> `project.type`, `project.language`, build/test commands.
2. Read `tasks/lessons.md` -- apply relevant lessons.
3. Read chosen approach from brainstorm output.

### Generate plan

Write the implementation plan to `.workflows/<name>/plan.md` using this algorithm:

**Step 1 — Identify layers touched** by the spec. Categorize required changes into:
- **Data/Models**: entities, DTOs, database schemas, types
- **Domain/Business**: use cases, services, business rules, interfaces
- **Data Layer/API**: repositories, API clients, network, data sources
- **Presentation/UI**: views, screens, components, view models, state
- **Configuration**: DI, routing, build config, environment
- **Tests**: unit tests, integration tests for new code

**Step 2 — Order by dependency** (build from foundation up):
- Phase A: Data models and types (if needed)
- Phase B: Domain/business logic (if needed)
- Phase C: Data layer / API integration (if needed)
- Phase D: Presentation / UI (if needed)
- Phase E: Wiring / DI / configuration (if needed)
- Phase F: Tests for new code

**Step 3 — Skip empty layers.** If no changes needed for a layer, omit it.

**Step 4 — Split large layers.** If a layer touches >5 files, split into sub-phases (e.g., Phase C1: API client, Phase C2: Repository).

**Step 5 — Cap at `workflows.new-feature.max_plan_phases`** (default 10). If over limit, ask user to split feature.

Each phase MUST include:
- **Files to create/modify**: checkable list with paths and descriptions
- **Implementation details**: what to build and how
- **Build check command**: detected from project
- **Commit message**: conventional commit format `feat(<scope>): <description>`

Also include:
- **Rollback plan**: each phase independently revertable via git
- **Risk assessment**: risks with mitigations

### Approval gate

Present plan summary. Ask: "Review the plan. Reply with changes or 'approved' to proceed."

### Update tracking

Add feature to `tasks/todo.md` with a checkable item per phase.

**>> Write output to**: `.workflows/<name>/04-plan.md` — then rewrite `.workflows/current-state.md`. (The detailed plan is in `.workflows/<name>/plan.md`)

---

## Phase 5: BRANCH

**Goal**: Create a properly named feature branch.

### Execute

1. Read `git.branches.development` and `git.branches.feature` pattern from config.
2. Replace `{name}` in pattern with kebab-case feature name.
3. Run:
   ```bash
   git checkout <dev_branch> && git pull origin <dev_branch> && git checkout -b <branch_name>
   ```

### Error handling

- Dirty working tree: tell user to stash or commit first.
- Branch exists: ask to switch or rename.
- Dev branch behind remote: pull first, then branch.

**>> Write output to**: `.workflows/<name>/05-branch.md` — then update `.workflows/current-state.md`.

---

## Phase 6: IMPLEMENT

**Goal**: Execute the plan phase by phase with build checks and commits.

### Before starting

1. Read `.claude/rules/` for language-specific coding rules. Follow ALL DO/DON'T directives.
2. Read `tasks/lessons.md` for relevant lessons.

### Per-phase loop

For each phase in the plan:

1. **Read** phase details from `.workflows/<name>/plan.md`.
2. **Implement** changes. Rules:
   - One concern per phase. Do not mix layers.
   - Match existing codebase conventions exactly.
   - Only create/modify files listed in the plan.
   - No placeholder code. Every line production-ready.
3. **Build check**: run the phase's build command. If it fails:
   - Read error, fix, re-run.
   - After 3 failures: trigger REPLAN.
4. **Commit**: `git add <specific-files> && git commit -m "<message>"`.
5. **Continue**: proceed automatically for straightforward phases. For complex phases, confirm with user.

### REPLAN protocol

Trigger when: build fails 3+ times, plan step is wrong/impossible, or user requests mid-flight change.

1. STOP all implementation.
2. Document what went wrong under "## Replan Notes" in the plan file.
3. Re-analyze remaining phases.
4. Generate updated plan, present for approval.
5. Resume from corrected phase.

**>> Write output to**: `.workflows/<name>/06-implement.md` — then update `.workflows/current-state.md`. (Files changed, commits made, issues encountered)

---

## Phase 7: TEST

**Goal**: Verify correctness and quality.

### Detect test framework

Read `project.language` and `project.type` from config. Detect test runner and coverage tools from the project's build files (e.g., `package.json`, `build.gradle`, `Cargo.toml`, `pyproject.toml`). Do NOT assume any specific test framework.

### Execute

1. **Run all tests**: use the project's test command. All existing tests MUST pass. If failures are caused by the new feature, fix them. If pre-existing, report but do not block.
2. **Run new tests**: if the plan included a testing phase, verify those tests pass.
3. **Coverage check**: if coverage tooling is configured, report coverage for new code. Target: 80%+ for new code.
4. **Present verification checklist**:
   - All existing tests pass
   - New tests pass
   - Build succeeds
   - Feature works as specified
   - No regressions in related features

**>> Write output to**: `.workflows/<name>/07-test.md` — then update `.workflows/current-state.md`.

---

## Phase 8: PR

**Goal**: Create a well-documented pull request after passing quality gates.

### Pre-PR quality gate

1. Load `.claude/reviews/general-checklist.md`.
2. Load language-specific checklist: `.claude/reviews/<language>-checklist.md` (based on `project.language`).
3. If a framework checklist exists (e.g., `.claude/reviews/<framework>-checklist.md`), load that too.
4. Self-check ALL High and Critical severity items from loaded checklists.
5. Fix any violations before proceeding. Document fixes as additional commits.

### Create PR

1. Generate PR body:
   - **Summary**: 2-3 sentences from spec
   - **Changes**: bulleted list organized by phase
   - **Testing**: what was tested, coverage numbers
   - **Checklist**: items from quality gate, all checked
2. Push and create:
   ```bash
   git push -u origin <branch>
   gh pr create --base <dev_branch> --title "feat(<scope>): <title>" --body "<body>"
   ```

### Final summary

Print: branch name, PR URL, commit count, files created/modified, spec path, plan path. Suggest next steps: add screenshots (if UI), request review, address feedback.

**>> Write output to**: `.workflows/<name>/08-pr.md` — then update `.workflows/current-state.md`.

**After this final phase**: Move `.workflows/current-state.md` to `.workflows/history/<name>-<YYYY-MM-DD>.md`. Report completion.

---

## Error Handling

Errors documented inline per phase above. Additional edge cases:

| Phase | Error | Resolution |
|---|---|---|
| BRANCH | Merge conflicts | Rebase on dev branch, resolve conflicts |
| PR | `gh` CLI not authenticated | Guide user through `gh auth login` |
