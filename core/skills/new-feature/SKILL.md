---
name: new-feature
description: "End-to-end feature workflow from requirements through PR. Eight phases: GATHER -> SPEC -> BRAINSTORM -> PLAN -> BRANCH -> IMPLEMENT -> TEST -> PR."
---

# New Feature Workflow

```
/new-feature <name> [--from-jira <ticket>] [--from-figma <url>] [--from-spec <path>] [--skip-brainstorm]
```

**Prerequisites**: `.claude/workflows.yml` exists. Git working tree is clean.

**Config references**: Read `.claude/workflows.yml` for `project.language`, `project.type`, `git.branches.*`, and `workflows.new-feature.*` throughout this workflow.

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
2. "Who is this for?"
3. "What are the acceptance criteria?"
4. "Any UI designs? (Figma URL or description)"
5. "Any API changes needed?"
6. "What existing features does this interact with?"
7. "Any performance requirements or constraints?"

### Gate

Do NOT proceed if acceptance criteria are undefined. List missing info and ask user to provide or confirm.

**Output**: `.workflows/<name>/01-gather.md`

---

## Phase 2: SPEC

**Goal**: Produce a formal specification from gathered requirements.

### Generate spec

If `.claude/templates/spec.md.tmpl` exists, use it as the template. Otherwise use this structure:

Write `.workflows/<name>/02-spec.md`:
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

---

## Phase 3: BRAINSTORM

**Skip if**: `--skip-brainstorm` flag OR `workflows.new-feature.require_brainstorm` is `false` in config. Mark `SKIPPED` in phase history.

### Execute

Delegate to brainstorm skill:
- **Input**: spec document from Phase 2
- **Depth**: `standard` (default) or as configured
- **Focus areas**: architecture fit, data flow, component reuse, state management, testing strategy

Use a sub-agent to scan the codebase for similar patterns, reusable components, and existing architecture conventions. Let the brainstorm skill handle technique selection and option generation.

### Approval gate

User selects an approach. Document choice under "## Chosen Approach" in the spec.

**Output**: `.workflows/<name>/03-brainstorm.md`

---

## Phase 4: PLAN

**Goal**: Create a phased implementation plan tailored to the project's architecture.

### Read context

1. Read `.claude/workflows.yml` -> `project.type`, `project.language`, build/test commands.
2. Read `tasks/lessons.md` -- apply relevant lessons.
3. Read chosen approach from brainstorm output.

### Generate plan

Write `.claude/plan-<name>.md`. Generate phases dynamically based on the project's architecture, NOT a hardcoded layer structure. Analyze `project.type` and the existing code structure to determine appropriate phases.

Each phase MUST include:
- **Files to create/modify**: checkable list with paths and descriptions
- **Implementation details**: what to build and how
- **Build check command**: detected from project (e.g., `./gradlew build`, `npm run build`, `cargo build`)
- **Commit message**: conventional commit format `feat(<scope>): <description>`

Also include:
- **Rollback plan**: each phase independently revertable via git
- **Risk assessment**: risks with mitigations

Constraint: if plan exceeds 10 phases, split into multiple features.

### Approval gate

Present plan summary. Ask: "Review the plan. Reply with changes or 'approved' to proceed."

### Update tracking

Add feature to `tasks/todo.md` with a checkable item per phase.

**Output**: `.workflows/<name>/04-plan.md` (summary; detailed plan stays in `.claude/plan-<name>.md`)

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

**Output**: `.workflows/<name>/05-branch.md`

---

## Phase 6: IMPLEMENT

**Goal**: Execute the plan phase by phase with build checks and commits.

### Before starting

1. Read `.claude/rules/` for language-specific coding rules. Follow ALL DO/DON'T directives.
2. Read `tasks/lessons.md` for relevant lessons.

### Per-phase loop

For each phase in the plan:

1. **Read** phase details from `.claude/plan-<name>.md`.
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

### Sub-agent usage

Use sub-agents for: researching existing patterns, running build checks, generating boilerplate, writing test scaffolding.

**Output**: `.workflows/<name>/06-implement.md` (files changed, commits made, issues encountered)

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

**Output**: `.workflows/<name>/07-test.md`

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

**Output**: `.workflows/<name>/08-pr.md`

---

## Error Handling

| Phase | Error | Resolution |
|---|---|---|
| GATHER | Jira MCP unavailable | Fall back to interactive gathering |
| GATHER | Figma MCP unavailable | Ask user to describe UI manually |
| SPEC | User rejects spec 3+ times | Ask if feature scope needs rethinking |
| BRAINSTORM | No similar patterns found | Use generic architecture approach |
| PLAN | Plan too large (>10 phases) | Split into multiple features |
| BRANCH | Merge conflicts | Rebase on dev branch, resolve conflicts |
| IMPLEMENT | Build fails 3+ times | Trigger REPLAN |
| IMPLEMENT | Plan step is impossible | Trigger REPLAN |
| TEST | Tests fail | Fix if feature-related, report if pre-existing |
| PR | `gh` CLI not authenticated | Guide user through `gh auth login` |
| PR | Quality gate violations found | Fix violations before creating PR |
