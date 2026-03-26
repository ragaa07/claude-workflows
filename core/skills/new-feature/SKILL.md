---
name: new-feature
description: End-to-end workflow for implementing a new feature from requirements gathering through PR creation, with spec generation, brainstorming, phased implementation, and testing.
---

# New Feature Workflow

## Command

```
/workflow:new-feature <name> [--from-jira <ticket>] [--from-figma <url>] [--from-spec <path>] [--skip-brainstorm]
```

## Overview

The most comprehensive workflow. Takes a feature from idea to merged PR through eight phases: **GATHER -> SPEC -> BRAINSTORM -> PLAN -> BRANCH -> IMPLEMENT -> TEST -> PR**.

## Prerequisites

- `.claude/workflows.yml` must exist (run `/workflow:new-project` first)
- Git working tree must be clean (no uncommitted changes)
- On the development branch or ready to branch from it

---

## Phase 1: GATHER

**Goal**: Collect all requirements from available sources into a unified understanding.

### Step 1.1 — Parse Command Arguments

Determine input sources from flags:
- `--from-jira <ticket>`: Jira ticket ID (e.g., `PROJ-1234`)
- `--from-figma <url>`: Figma design URL
- `--from-spec <path>`: Path to existing spec document
- No flags: Interactive requirements gathering

### Step 1.2 — Fetch from Jira (if --from-jira)

Use Jira MCP tools:

```
mcp__atlassian__getJiraIssue(issueIdOrKey: "<ticket>")
```

Extract:
- **Title**: Issue summary
- **Description**: Full description and acceptance criteria
- **Subtasks**: Child issues (fetch each for details)
- **Linked issues**: Dependencies or related work
- **Priority**: P0-P4
- **Labels/Components**: For categorization
- **Attachments**: Note any attached specs or mockups

If the ticket has sub-tasks, fetch each one:

```
mcp__atlassian__searchJiraIssuesUsingJql(jql: "parent = <ticket>")
```

### Step 1.3 — Fetch from Figma (if --from-figma)

Use Figma MCP tools:

```
mcp__figma__get_design_context(fileKey: "<key>", nodeId: "<id>")
mcp__figma__get_screenshot(fileKey: "<key>", nodeId: "<id>")
```

Extract:
- **Screens**: List of screens/states in the design
- **Components**: UI components used
- **Design tokens**: Colors, spacing, typography
- **Annotations**: Designer notes
- **Interactions**: Prototype flows

### Step 1.4 — Read Spec File (if --from-spec)

Read the provided spec file and parse its structure. Accept markdown, text, or structured formats.

### Step 1.5 — Interactive Gathering (if no flags)

Ask the user a structured set of questions:

1. "What does this feature do? (1-2 sentences)"
2. "Who is this for? (user type/persona)"
3. "What are the acceptance criteria? (list)"
4. "Are there any UI designs? (Figma URL or description)"
5. "Are there any API changes needed? (endpoints, models)"
6. "What existing features does this interact with?"
7. "Any performance requirements or constraints?"

### Decision Point: Sufficient Requirements

Evaluate gathered requirements. If missing critical information:
- List what is missing
- Ask user to provide it or confirm proceeding without it
- Do NOT proceed if acceptance criteria are undefined

**Output**: Write gathered requirements to the phase output document (`.workflows/<name>/01-gather.md`).

---

## Phase 2: SPEC

**Goal**: Generate a formal specification document from gathered requirements.

### Step 2.1 — Generate Spec Document

Write `.workflows/<name>/02-spec.md`:

```markdown
# Feature Spec: <Feature Name>

## Metadata
- **Date**: <today>
- **Source**: <jira-ticket|figma-url|manual>
- **Status**: Draft
- **Author**: Claude Code

## Summary
<1-3 sentence description of the feature>

## User Stories
- As a <persona>, I want to <action>, so that <benefit>
(generate from gathered requirements)

## Acceptance Criteria
- [ ] <criterion 1>
- [ ] <criterion 2>
- [ ] <criterion N>

## Scope

### In Scope
- <item>

### Out of Scope
- <item>

## Technical Requirements

### API Changes
- <endpoint/model changes if any>

### Data Model
- <new entities, fields, relationships>

### UI/UX
- <screens, components, interactions>
- <link to Figma if available>

## Dependencies
- <other features, services, or libraries>

## Edge Cases
- <edge case 1>
- <edge case 2>

## Open Questions
- <question 1>
```

### Step 2.3 — Present Spec for Review

Display the spec summary to the user. Ask: "Review the spec above. Reply with changes or 'approved' to proceed."

### Decision Point: Spec Approval

- If user requests changes: update spec, re-present
- If user approves: proceed to Phase 3
- Save final spec regardless

---

## Phase 3: BRAINSTORM

**Goal**: Explore implementation approaches before committing to a plan.

**Skip condition**: Skip if `--skip-brainstorm` passed OR `workflows.new-feature.require_brainstorm` is `false` in `.claude/workflows.yml`. Mark as `SKIPPED` in Phase History.

### Step 3.1 — Invoke Brainstorm Skill

Delegate to the brainstorm skill with context:

- **Input**: The spec document from Phase 2
- **Technique**: Use "Structured Exploration" by default
- **Focus areas**:
  1. Architecture approach (where does this fit in the codebase?)
  2. Data flow (how does data move through the system?)
  3. UI component strategy (new vs reuse existing)
  4. State management approach
  5. Testing strategy

### Step 3.2 — Codebase Analysis

Use sub-agent to analyze the existing codebase for:

- **Similar features**: Find features with similar patterns to reuse
- **Existing components**: UI components that can be reused
- **Data layer**: Existing repositories, API clients, models that apply
- **Navigation**: How to integrate with existing navigation graph
- **DI setup**: Existing modules and component structure

```bash
# Find similar features
grep -r "class.*ViewModel" --include="*.kt" -l | head -20
grep -r "class.*Repository" --include="*.kt" -l | head -20
grep -r "@Composable" --include="*.kt" -l | head -20
```

### Step 3.3 — Generate Options

Present 2-3 implementation approaches with trade-offs:

```
Approach A: <name>
  Pros: ...
  Cons: ...
  Effort: <low|medium|high>

Approach B: <name>
  Pros: ...
  Cons: ...
  Effort: <low|medium|high>
```

### Decision Point: Approach Selection

Ask user: "Which approach do you prefer? (A/B/C or suggest alternative)"

**Output**: Selected approach documented in spec file under a new "## Chosen Approach" section.

**Phase Output**: Write brainstorm results (options explored, scoring, chosen approach) to `.workflows/<name>/03-brainstorm.md`

---

## Phase 4: PLAN

**Goal**: Create a detailed, phase-by-phase implementation plan.

**Note**: Detect the project build system from the codebase (e.g., `./gradlew` for Android/KMP, `npm` for Node.js, `cargo` for Rust) and use appropriate build/test commands throughout the plan.

### Step 4.1 — Read Project Configuration

```bash
cat .claude/workflows.yml
cat tasks/lessons.md  # Apply past lessons
```

### Step 4.2 — Generate Implementation Plan

Write `.claude/plan-<name>.md`:

```markdown
# Implementation Plan: <Feature Name>

## Spec Reference
- Spec: `.workflows/<name>/02-spec.md`
- Approach: <chosen approach from brainstorm>
- Estimated phases: 6

## Phase A: Data Layer
### Files to create/modify:
- [ ] `<path>` — <description>
### Details:
- <implementation details>
### Compile check: `<build-command>`
### Commit message: `feat(<scope>): add data models for <feature>`

## Phase B: Domain Layer
### Files to create/modify:
- [ ] `<path>` — <description>
### Details:
- <implementation details>
### Compile check: `<build-command>`
### Commit message: `feat(<scope>): add use cases for <feature>`

## Phase C: UI Layer
### Files to create/modify:
- [ ] `<path>` — <description>
### Details:
- <implementation details>
### Compile check: `<build-command>`
### Commit message: `feat(<scope>): add UI components for <feature>`

## Phase D: Navigation & Integration
### Files to create/modify:
- [ ] `<path>` — <description>
### Details:
- <implementation details>
### Compile check: `<build-command>`
### Commit message: `feat(<scope>): integrate <feature> navigation`

## Phase E: Analytics
### Files to create/modify:
- [ ] `<path>` — <description>
### Details:
- <implementation details>
### Compile check: `<build-command>`
### Commit message: `feat(<scope>): add analytics for <feature>`

## Phase F: Testing
### Files to create/modify:
- [ ] `<path>` — <description>
### Details:
- <implementation details>
### Test command: `<test-command>`
### Commit message: `test(<scope>): add tests for <feature>`

## Rollback Plan
- Each phase is independently revertable via git
- No database migrations until Phase D is verified

## Risk Assessment
- <risk 1>: <mitigation>
- <risk 2>: <mitigation>
```

### Step 4.3 — Present Plan for Review

Display plan summary. Ask: "Review the plan. Reply with changes or 'approved' to proceed."

### Step 4.4 — Update Todo

Add feature to `tasks/todo.md`:

```markdown
## In Progress
- [ ] <Feature Name> (plan: `.claude/plan-<name>.md`)
  - [ ] Phase A: Data Layer
  - [ ] Phase B: Domain Layer
  - [ ] Phase C: UI Layer
  - [ ] Phase D: Navigation
  - [ ] Phase E: Analytics
  - [ ] Phase F: Testing
  - [ ] PR Created
```

**Phase Output**: Write the plan summary to `.workflows/<name>/04-plan.md` (the detailed plan remains in `.claude/plan-<name>.md`)

---

## Phase 5: BRANCH

**Goal**: Create a properly named feature branch.

### Step 5.1 — Read Git Config

From `.claude/workflows.yml`, get:
- `git.branches.development`: Branch to branch from
- `git.branches.feature`: Branch naming pattern

### Step 5.2 — Create Branch

Replace `{name}` in the branch pattern with a kebab-case version of the feature name (e.g., `add-favorites` -> `feature/add-favorites`).

```bash
git checkout <development_branch>
git pull origin <development_branch>
git checkout -b <feature_pattern_with_name>
```

Example: `git checkout -b feature/add-favorites`

### Error Handling

- If working tree is dirty: "You have uncommitted changes. Stash or commit them first."
- If branch already exists: "Branch `<name>` already exists. Switch to it or choose a different name?"
- If dev branch is behind remote: Pull first, then branch

**Output**: Write branch details to the phase output document (`.workflows/<name>/05-branch.md`).

---

## Phase 6: IMPLEMENT

**Goal**: Execute the plan phase by phase with compile checks and commits.

### Implementation Loop

For each phase (A through F) in the plan:

#### Step 6.X.1 — Read Phase Details

Read the current phase from `.claude/plan-<name>.md`.

#### Step 6.X.2 — Implement Changes

Write the code for this phase. Follow these rules:
- **One concern per phase**: Do not mix data layer changes with UI changes
- **Follow existing patterns**: Match the codebase's conventions exactly
- **Minimal impact**: Only create/modify files listed in the plan
- **No placeholder code**: Every line must be production-ready

#### Step 6.X.3 — Compile Check

Run the build command from the plan:

```bash
<build-command>
```

**If compilation fails**:
1. Read the error output
2. Fix the error
3. Re-run compile check
4. If stuck after 3 attempts: trigger REPLAN (see below)

#### Step 6.X.4 — Commit

```bash
git add <specific-files>
git commit -m "<commit-message-from-plan>"
```

#### Step 6.X.5 — Proceed or Pause

Ask: "Phase <X> complete. Continue to Phase <X+1>?" (Only ask if implementation is complex; for straightforward phases, continue automatically.)

### REPLAN Protocol

Triggered when:
- Compilation fails 3+ times in a phase
- A phase reveals the plan is wrong
- User requests a change mid-implementation

Steps:
1. **STOP** all implementation
2. Document what went wrong in the plan file under "## Replan Notes"
3. Re-analyze the remaining phases
4. Generate updated plan for remaining phases
5. Present to user for approval
6. Resume from the corrected phase

### Sub-Agent Usage During Implementation

Use sub-agents for:
- Researching existing code patterns before writing new code
- Running compile checks in background
- Generating boilerplate (DI modules, navigation setup)
- Writing test scaffolding

### Lesson Integration

Before each phase, check `tasks/lessons.md` for relevant lessons:
- If a lesson mentions the current file/pattern, apply it
- After any compilation error, check if a lesson covers it

**Phase Output**: Write implementation summary (files changed, commits made, issues encountered) to `.workflows/<name>/06-implement.md`

---

## Phase 7: TEST

**Goal**: Run tests, verify coverage, and ensure quality.

### Step 7.1 — Run Existing Tests

```bash
<test-command>
```

All existing tests MUST pass. If any fail:
1. Determine if the failure is caused by the new feature
2. If yes: fix it
3. If no: report it but do not block

### Step 7.2 — Run New Tests

If Phase F added tests:

```bash
<test-command-for-new-tests>
```

### Step 7.3 — Coverage Check

If coverage tooling is configured:

```bash
<coverage-command>
```

Report coverage for new code. Target: 80%+ for new code.

### Step 7.4 — Manual Verification Checklist

Present to user:

```
Verification Checklist:
- [ ] All existing tests pass
- [ ] New tests pass
- [ ] Build succeeds
- [ ] Feature works as specified (manual check)
- [ ] No regressions in related features
```

**Phase Output**: Write test results (coverage, pass/fail, gaps) to `.workflows/<name>/07-test.md`

---

## Phase 8: PR

**Goal**: Create a well-documented pull request.

### Step 8.1 — Prepare PR Body

Generate PR body from spec, plan, and changes:

```markdown
## Summary
<2-3 sentences from spec summary>

## Changes
<bulleted list of what was added/modified, organized by phase>

## Spec
<link to spec file or inline key points>

## Screenshots
<if UI changes, note that screenshots should be added>

## Testing
- [ ] Unit tests added for <components>
- [ ] All existing tests pass
- [ ] Manual testing completed for:
  - <test scenario 1>
  - <test scenario 2>

## Checklist
- [ ] Code follows project conventions
- [ ] No hardcoded strings (i18n ready)
- [ ] Analytics events tracked
- [ ] Edge cases handled
- [ ] Documentation updated (if applicable)
```

### Step 8.2 — Push and Create PR

```bash
git push -u origin <branch-name>

gh pr create \
  --base <dev_branch> \
  --title "feat(<scope>): <feature title>" \
  --body "$(cat <<'EOF'
<generated PR body>
EOF
)"
```

### Step 8.3 — Final Summary

Print:

```
Feature implementation complete.

  Branch:  <branch-name>
  PR:      <pr-url>
  Commits: <count>
  Files:   <count> created, <count> modified

  Spec:    .workflows/<name>/02-spec.md
  Plan:    .claude/plan-<name>.md

Next steps:
  1. Add screenshots to PR (if UI changes)
  2. Request review
  3. Address review feedback
```

**Phase Output**: Write PR details (URL, summary, reviewers) to `.workflows/<name>/08-pr.md`

---

## Error Handling Summary

| Phase | Error | Resolution |
|---|---|---|
| GATHER | Jira MCP unavailable | Fall back to interactive gathering |
| GATHER | Figma MCP unavailable | Ask user to describe UI manually |
| SPEC | User rejects spec 3+ times | Ask if feature scope needs rethinking |
| BRAINSTORM | No similar patterns found | Use generic architecture approach |
| PLAN | Plan too large (>10 phases) | Split into multiple features |
| BRANCH | Merge conflicts | Rebase on dev branch, resolve conflicts |
| IMPLEMENT | Compilation fails 3+ times | Trigger REPLAN |
| IMPLEMENT | Plan step is impossible | Trigger REPLAN |
| TEST | Tests fail | Fix if feature-related, report if pre-existing |
| PR | gh CLI not authenticated | Guide user through `gh auth login` |

