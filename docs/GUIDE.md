# Claude Workflows — Complete Guide

## Table of Contents

1. [What Is Claude Workflows](#1-what-is-claude-workflows)
2. [Installation](#2-installation)
3. [Configuration](#3-configuration)
4. [The Workflow Lifecycle](#4-the-workflow-lifecycle)
5. [All Commands](#5-all-commands)
6. [Workflow: New Feature](#6-workflow-new-feature)
7. [Workflow: Extend Feature](#7-workflow-extend-feature)
8. [Workflow: Refactor](#8-workflow-refactor)
9. [Workflow: Hotfix](#9-workflow-hotfix)
10. [Workflow: Test](#10-workflow-test)
11. [Workflow: Review](#11-workflow-review)
12. [Workflow: Release](#12-workflow-release)
13. [Workflow: CI Fix](#13-workflow-ci-fix)
14. [Workflow: Migrate](#14-workflow-migrate)
15. [Workflow: New Project](#15-workflow-new-project)
16. [Brainstorming System](#16-brainstorming-system)
17. [Git Flow Management](#17-git-flow-management)
18. [Multi-Session Context & State Management](#18-multi-session-context--state-management)
19. [Todo & Lessons System](#19-todo--lessons-system)
20. [Sub-Agent Strategy](#20-sub-agent-strategy)
21. [Project Skills Integration](#21-project-skills-integration)
22. [File Reference](#22-file-reference)
23. [Upgrading](#23-upgrading)
24. [Troubleshooting](#24-troubleshooting)

---

## 1. What Is Claude Workflows

Claude Workflows is a **portable, spec-driven development workflow system** for Claude Code AI agents. It provides structured, repeatable processes for common software development tasks — building features, fixing bugs, refactoring code, writing tests, and shipping releases.

### Core Principles

- **Spec before code** — Every non-trivial change starts with a specification document
- **Brainstorm before plan** — Explore multiple approaches using structured techniques before committing
- **Plan before implement** — Create a phased implementation plan with verification at each step
- **State across sessions** — Workflow progress persists between Claude Code sessions via state files
- **Configurable git flow** — Branch naming, commit format, PR templates, and merge strategy are all configurable
- **Portable** — Install into any project with zero dependencies. Works with Android, React, Python, Go, or any stack

### What You Get

- **10 workflow skills** covering the full development lifecycle
- **3 utility skills** (orchestrator, git operations, brainstorming)
- **5 brainstorming techniques** (Six Thinking Hats, SCAMPER, Trade-off Matrix, Reverse Brainstorm, Constraint Mapping)
- **Multi-session persistence** via state files, specs, plans, and git history
- **Todo + Lessons** tracking integrated into every workflow
- **Configurable everything** via a single YAML file

---

## 2. Installation

### Prerequisites

- A Git repository (the installer detects project root from `.git`)
- Claude Code installed and working
- `gh` CLI installed (for PR workflows)

### Install Steps

```bash
# Step 1: Clone the package
git clone https://github.com/<org>/claude-workflows /tmp/claude-workflows

# Step 2: Navigate to your project
cd /path/to/your-project

# Step 3: Run the installer
bash /tmp/claude-workflows/install.sh
```

### What the Installer Does

| Action | Path | Notes |
|--------|------|-------|
| Copies core skills | `.claude/skills/_core/` | 13 skill directories |
| Copies templates | `.claude/templates/` | spec, plan, state, changelog |
| Creates config | `.claude/workflows.yml` | Only if not exists |
| Creates state dirs | `.workflows/specs/`, `.workflows/history/` | For runtime state |
| Updates CLAUDE.md | `CLAUDE.md` | Appends workflow instructions (idempotent) |
| Updates .gitignore | `.gitignore` | Ignores state file and history |
| Writes version | `.claude/.workflows-version` | Tracks installed version |

### Verify Installation

```bash
# Check version
cat .claude/.workflows-version
# → 1.0.0

# Check skills installed
ls .claude/skills/_core/
# → brainstorm  ci-fix  extend-feature  git-flow  hotfix  migrate
#   new-feature  new-project  refactor  release  review  test  workflow-engine
```

Then open Claude Code and run:

```
/workflow:status
```

### Post-Install: Configure for Your Project

Edit `.claude/workflows.yml` — see [Section 3: Configuration](#3-configuration).

You can start from an example:

```bash
# Android/Kotlin project
cp /tmp/claude-workflows/examples/android/workflows.yml .claude/workflows.yml

# React/TypeScript project
cp /tmp/claude-workflows/examples/react/workflows.yml .claude/workflows.yml

# Python project
cp /tmp/claude-workflows/examples/python/workflows.yml .claude/workflows.yml
```

### Commit the Setup

```bash
git add .claude/ CLAUDE.md .workflows/specs/ .gitignore
git commit -m "chore: install claude-workflows v1.0.0"
```

---

## 3. Configuration

All configuration lives in a single file: `.claude/workflows.yml`

### Full Configuration Reference

```yaml
version: "1.0"

# ─── PROJECT IDENTITY ───────────────────────────────────────
project:
  name: "My Project"                   # Display name
  type: "android"                      # android | react | python | generic
  language: "kotlin"                   # Primary language

# ─── GIT FLOW ────────────────────────────────────────────────
git:
  branches:
    main: "main"                       # Production branch name
    development: "develop"             # Development/integration branch
    feature: "feature/{name}"          # {name} replaced with feature name
    bugfix: "bugfix/{name}"            # {name} replaced with fix name
    hotfix: "hotfix/{name}"            # Branches from main, not develop
    release: "release/v{version}"      # {version} replaced with version string

  commits:
    format: "conventional"             # conventional | angular | simple
    types: [feat, fix, refactor, test, docs, chore, style, perf]
    scopes: true                       # Allow feat(scope): messages
    ticket_reference: false            # Require ticket IDs in commits

  pr:
    base_branch: "develop"             # Default PR target
    draft: false                       # Create as draft PRs
    reviewers: []                      # Auto-assign reviewers (GitHub usernames)
    labels: []                         # Auto-apply labels
    template: |                        # PR body template with variables
      ## Summary
      {summary}
      ## Changes
      {changes}
      ## Test Plan
      {test_plan}

  merge:
    strategy: "squash"                 # squash | merge | rebase
    delete_branch: true                # Delete branch after merge

  protected:                           # Warn on direct commits to these
    - "main"
    - "develop"

# ─── WORKFLOW SETTINGS ────────────────────────────────────────
workflows:
  new-feature:
    require_spec: true                 # Must create spec document
    require_tests: true                # Must write tests before PR
    require_brainstorm: true           # Run brainstorm phase

  extend-feature:
    require_brainstorm: true
    require_tests: true

  refactor:
    require_brainstorm: true
    require_tests: true

  hotfix:
    base_branch: "main"               # Override: branch from main
    require_tests: false               # Skip tests for speed

  release:
    changelog: true                    # Generate changelog entries
    tag_format: "v{version}"           # Git tag format

  review:
    standards:                         # Custom review checklist
      - "Follows project architecture"
      - "Proper error handling"
      - "No hardcoded strings"

  brainstorm:
    default_depth: "standard"          # quick | standard | deep
    techniques:
      - "trade-off-matrix"
      - "six-thinking-hats"
      - "scamper"
      - "reverse-brainstorm"
      - "constraint-mapping"

# ─── STATE MANAGEMENT ─────────────────────────────────────────
state:
  directory: ".workflows"              # Runtime state directory
  history: true                        # Keep completed workflow history
  max_history: 50                      # Max history entries

# ─── SKILLS ───────────────────────────────────────────────────
skills:
  disabled: []                         # Skills to disable by name
  aliases:                             # Command shortcuts
    build: "new-feature"               # /workflow:build → /workflow:new-feature
    fix: "hotfix"                      # /workflow:fix → /workflow:hotfix
    ship: "release"                    # /workflow:ship → /workflow:release
```

### Configuration Tips

- **Start simple**: Copy an example, change `project.name` and `git.branches` — that's enough to start
- **Protected branches**: Add all branches that should never receive direct commits
- **Review standards**: Add project-specific rules that the review workflow checks against
- **Aliases**: Create shortcuts for your most-used workflows
- **Brainstorm depth**: Use `quick` for small changes, `standard` for features, `deep` for architecture decisions

---

## 4. The Workflow Lifecycle

Every workflow follows a state machine. Not all phases apply to every workflow, but the order is always the same:

```
IDLE → GATHER → SPEC → BRAINSTORM → PLAN → BRANCH → IMPLEMENT → TEST → PR → DONE
                                                          ↓
                                                     REPLAN → back to IMPLEMENT
```

### Phase Descriptions

| Phase | What Happens | Output |
|-------|-------------|--------|
| **GATHER** | Collect requirements from Jira, Figma, user, or spec file | Structured requirements |
| **SPEC** | Generate a formal specification document | `.workflows/specs/<name>.spec.md` |
| **BRAINSTORM** | Explore multiple approaches, evaluate trade-offs | `.workflows/specs/<name>.decisions.md` |
| **PLAN** | Create phased implementation plan | `.claude/plan-<name>.md` |
| **BRANCH** | Create feature branch per git config | Git branch |
| **IMPLEMENT** | Write code phase-by-phase with compile checks | Source code + commits |
| **TEST** | Write and run tests | Test files + results |
| **PR** | Push branch, create pull request | GitHub PR |
| **DONE** | Archive state, report summary | History entry |

### Skippable Phases

Controlled by `workflows.yml`:

```yaml
workflows:
  new-feature:
    require_spec: false        # Skips SPEC
    require_brainstorm: false  # Skips BRAINSTORM
    require_tests: false       # Skips TEST
```

Or per-invocation:

```
/workflow:new-feature my-feature --skip-brainstorm
```

### Decision Points

Every workflow pauses at key moments to get user confirmation:

1. **After SPEC** — "Review the spec. Approved?"
2. **After BRAINSTORM** — "Approach A recommended. Agree?"
3. **After PLAN** — "Review the implementation plan. Approved?"
4. **After UI implementation** — "UI complete. Looks correct?"
5. **Before PR** — "Review the PR draft. Create it?"

You're always in control. The workflow never proceeds without your approval at these points.

### REPLAN

If something goes wrong during implementation:

1. Compilation fails 3+ times
2. The plan is wrong (a step is impossible)
3. You request a change

The workflow enters **REPLAN**: stops implementation, documents what went wrong, generates an updated plan, and asks for your approval before continuing.

---

## 5. All Commands

### Workflow Commands

| Command | Description | Phases |
|---------|-------------|--------|
| `/workflow:new-feature <name>` | Build a new feature end-to-end | Gather → Spec → Brainstorm → Plan → Branch → Implement → Test → PR |
| `/workflow:extend-feature <name>` | Add to an existing feature | Analyze → Brainstorm → Plan → Implement → Verify-Compat → Test → PR |
| `/workflow:refactor <target>` | Safely restructure code | Analyze → Brainstorm → Contract → Design → Migrate → Verify → PR |
| `/workflow:hotfix [--crash <id>]` | Emergency production fix | Diagnose → Fix → Regression-Test → PR-to-Prod → Cherry-Pick |
| `/workflow:test <target>` | Generate tests with coverage | Analyze → Plan → Write → Verify → Report |
| `/workflow:review <pr-number>` | Review a pull request | Fetch → Categorize → Check → Comment |
| `/workflow:release <version>` | Prepare a release | Changelog → Version-Bump → Release-Branch → PR → Tag |
| `/workflow:ci-fix [--run <id>]` | Fix CI/CD failures | Fetch → Diagnose → Fix → Push → Monitor |
| `/workflow:migrate <type>` | Incremental migration | Analyze → Brainstorm → Plan → Execute → Verify → PR |
| `/workflow:new-project` | Bootstrap project setup | Detect → Configure → Generate → Setup |
| `/workflow:brainstorm <topic>` | Standalone brainstorming | Context → Generate → Analyze → Decide |

### Utility Commands

| Command | Description |
|---------|-------------|
| `/workflow:status` | Show current workflow state, phase, progress |
| `/workflow:resume` | Resume a paused workflow |
| `/workflow:pause` | Pause the active workflow (state preserved) |
| `/workflow:abandon` | Archive and discard the active workflow |
| `/workflow:history` | List completed workflows |

### Aliases (Configurable)

Default aliases in `workflows.yml`:

```
/workflow:build → /workflow:new-feature
/workflow:fix   → /workflow:hotfix
/workflow:ship  → /workflow:release
```

---

## 6. Workflow: New Feature

The most comprehensive workflow. Takes a feature from idea to merged PR.

### Command

```
/workflow:new-feature <name> [--from-jira <ticket>] [--from-figma <url>] [--from-spec <path>] [--skip-brainstorm]
```

### Phase-by-Phase

#### Phase 1: GATHER

Collects requirements from one or more sources:

| Flag | Source | What Happens |
|------|--------|-------------|
| `--from-jira PROJ-123` | Jira | Fetches ticket via MCP, extracts title, description, acceptance criteria, subtasks |
| `--from-figma <url>` | Figma | Fetches design context via MCP, extracts screens, components, interactions |
| `--from-spec ./spec.md` | File | Reads existing specification document |
| *(no flag)* | Interactive | Asks you 7 structured questions about the feature |

Multiple flags can be combined: `--from-jira PROJ-123 --from-figma <url>`

**Decision Point**: Presents extracted requirements for your confirmation.

#### Phase 2: SPEC

Generates `.workflows/specs/<name>.spec.md` containing:

```
Feature Spec: <Name>
├── Metadata (date, source, status)
├── Summary
├── User Stories
├── Acceptance Criteria (checkable)
├── Scope (in/out)
├── Technical Requirements (API, data model, UI/UX)
├── Dependencies
├── Edge Cases
└── Open Questions
```

**Decision Point**: You review and approve the spec.

#### Phase 3: BRAINSTORM

Explores 2-4 implementation approaches using structured techniques:

1. **Codebase analysis** — sub-agents scan for similar features, existing patterns, reusable components
2. **Generate options** — 2-4 distinct implementation approaches
3. **Evaluate** — Apply selected brainstorming technique(s) and trade-off matrix
4. **Decide** — Produce decision document with chosen approach and rationale

Output: `.workflows/specs/<name>.decisions.md`

**Decision Point**: You approve the chosen approach.

Skip with `--skip-brainstorm` or `require_brainstorm: false` in config.

#### Phase 4: PLAN

Creates `.claude/plan-<name>.md` with phased implementation:

```
Phase A: Data Layer      → Models, service, repository, DI
Phase B: Domain Layer    → Interactors, domain models, DI
Phase C: UI Layer        → UiState, ViewModel, Screen, ScreenContent, components
Phase D: Navigation      → Routes, NavGraph, entry points
Phase E: Analytics       → Events, logger, tracking triggers
Phase F: Testing         → Unit tests for interactors, VMs, repos
```

Each phase includes:
- Specific files to create/modify
- Implementation details
- Compile check command
- Commit message

**Decision Point**: You approve the plan before any code is written.

Also generates `tasks/todo.md` with checkable items.

#### Phase 5: BRANCH

Creates feature branch per config:

```bash
# Reads git.branches.feature from workflows.yml
# Example: "alpha-feature/{name}" → alpha-feature/Booking_cancellation
git fetch origin Development
git checkout -b alpha-feature/Booking_cancellation origin/Development
```

#### Phase 6: IMPLEMENT

Executes the plan phase by phase:

```
For each phase (A → F):
  1. Write the code
  2. Compile check (must pass before continuing)
  3. Commit with conventional message
  4. Update plan file ([x] marks)
  5. Update state file (progress)
  6. Update tasks/todo.md
```

**Decision Point** after Phase C (UI): "UI complete. Looks correct?"

**REPLAN** trigger: If compilation fails 3 times or the plan is wrong → stop, document, re-plan, get approval.

**Lesson integration**: Before each phase, checks `tasks/lessons.md` for relevant rules.

#### Phase 7: TEST

1. Runs test skill (project's `test-ninja` if available, or core `test` skill)
2. Targets all new Interactors, ViewModels, Repositories
3. Runs full test suite
4. Reports coverage and gaps

#### Phase 8: PR

1. Pushes branch to remote
2. Generates PR body from spec + plan + changes
3. Creates PR via `gh pr create --base Development`
4. Adds reviewers/labels if configured

**Decision Point**: You approve the PR draft before creation.

### Complete File Trail

After completion, these files exist:

```
.workflows/specs/<name>.spec.md           # What we built (permanent)
.workflows/specs/<name>.decisions.md      # Why we chose this approach (permanent)
.claude/plan-<name>.md                    # How we built it (permanent)
.workflows/history/<date>-<name>.md       # Archived state (gitignored)
tasks/todo.md                             # Updated with completed items
features/<name>/...                       # Source code
```

---

## 7. Workflow: Extend Feature

Add functionality to an existing feature with minimal impact.

### Command

```
/workflow:extend-feature <existing-feature-name> [--describe "what to add"]
```

### Phases

1. **ANALYZE** — Map the existing feature (files, components, state model, ViewModel actions, tests)
2. **BRAINSTORM** — Use **SCAMPER** technique: what to substitute, combine, adapt, modify, eliminate
3. **PLAN** — Plan additions following minimal impact rules:
   - Prefer adding new files over modifying existing ones
   - Extend sealed interfaces, don't restructure them
   - Add new ViewModel functions, don't change existing signatures
   - New composables as separate files
4. **IMPLEMENT** — Code changes with compile checks per step
5. **VERIFY-COMPAT** — Run existing tests (all must pass without modification)
6. **TEST** — Write new tests for added functionality
7. **PR** — Create PR emphasizing what was *added* (not *changed*)

### Key Difference from New Feature

The extend workflow is **conservative** — existing behavior must be preserved. If existing tests break, the extension code is fixed (not the tests), unless the API intentionally changed.

---

## 8. Workflow: Refactor

Safely restructure code with behavioral contracts and incremental migration.

### Command

```
/workflow:refactor <target> [--scope files|module|feature] [--goal "description"]
```

### Phases

1. **ANALYZE** — Full dependency graph:
   - Inbound dependencies (what calls this code)
   - Outbound dependencies (what this code calls)
   - Public API surface (functions, classes, interfaces used externally)
2. **BRAINSTORM** — **Trade-off Matrix + Reverse Brainstorm**: evaluate new architecture options and identify failure modes
3. **CONTRACT** — Document current behavior as a contract:
   - Every public function: signature, return type, behavior, side effects
   - Capture existing tests as behavioral proof
   - If no tests exist: write behavior-capturing tests FIRST
4. **DESIGN** — Design new architecture, present before/after comparison
5. **MIGRATE** — Incremental steps, each must compile and pass tests independently:
   - Step 1: Add new alongside existing
   - Step 2: Migrate consumers one by one
   - Step 3: Remove old code
   - Step 4: Clean up
6. **VERIFY** — Full test suite comparison: same or more tests, all passing
7. **PR** — Detailed PR with before/after architecture, migration steps, rollback plan

### Key Principle

**Every migration step compiles and passes tests independently.** If any step breaks, revert that step only and re-plan it.

---

## 9. Workflow: Hotfix

Emergency production fix. Optimized for SPEED — no brainstorming, no spec, minimal planning.

### Command

```
/workflow:hotfix [--crash <crashlytics-issue-id>] [--error "description"] [--log <path>]
```

### Phases

1. **DIAGNOSE** — Parse error source:
   - `--crash <id>`: Fetch from Firebase Crashlytics MCP (issue details, events, stack trace)
   - `--error "desc"`: Parse for class names, error types
   - `--log <path>`: Read log file, extract stack trace
   - Output: Exception type, location (file:line), affected users, app version
2. **FIX** — Apply minimal fix:
   - **Absolute minimum change** — fix the crash, nothing else
   - **No refactoring** — even if the code is ugly
   - **No feature additions** — even if related
   - Branch from **Production** (not Development)
3. **REGRESSION-TEST** — Write a test that reproduces the exact crash scenario and verifies the fix
4. **PR** — Expedited PR to Production branch with crash details and user impact
5. **CHERRY-PICK** — Provide cherry-pick command for Development branch

### Timing

A hotfix should complete in **minutes**, not hours. The entire workflow is designed for speed.

---

## 10. Workflow: Test

Generate tests with coverage analysis and gap reporting.

### Command

```
/workflow:test <target> [--coverage <percentage>] [--type unit|integration]
```

Target formats:
- `class:BookingRepository`
- `file:path/to/File.kt`
- `module:core-data`
- `feature:booking`

### Phases

1. **ANALYZE** — Read target code, identify:
   - Public API (functions, properties)
   - Dependencies (injectable, mockable)
   - Branches (if/when/else paths, sealed class variants)
   - Edge cases (null, empty, boundary values)
2. **PLAN** — Generate test plan:
   - Happy path tests
   - Error handling tests
   - Edge case tests
   - State transition tests (for ViewModels)
   - Flow behavior tests (for reactive code)
3. **WRITE** — Generate tests following project conventions:
   - `Given/When/Then` naming
   - MockK for mocking
   - Turbine for Flow testing
   - StandardTestDispatcher for coroutines
4. **VERIFY** — Run tests, fix any failures
5. **REPORT** — Coverage report with gaps highlighted

### Default Coverage Target

90% (configurable via `--coverage`)

---

## 11. Workflow: Review

Structured code review for pull requests.

### Command

```
/workflow:review <pr-number>
```

### Phases

1. **FETCH** — Get PR data via `gh` CLI:
   - Diff, changed files, CI status, description
2. **CATEGORIZE** — Group changes by layer:
   - UI Layer, Domain Layer, Data Layer, Tests, Config
3. **CHECK** — Review against 6 categories:
   - **Architecture compliance**: Correct patterns, proper separation
   - **Code quality**: Null safety, immutability, naming, complexity
   - **Security**: No secrets, input validation, logging of sensitive data
   - **Performance**: Recomposition, caching, unnecessary allocations
   - **Test coverage**: Are new functions tested? Error paths?
   - **Project standards**: Custom rules from `workflows.review.standards`
4. **COMMENT** — Generate inline comments with severity:
   - `error`: Must fix
   - `warning`: Should fix
   - `suggestion`: Consider changing
   - `nitpick`: Minor preference

**Decision Point**: You choose which comments to submit before posting.

---

## 12. Workflow: Release

Prepare and ship a versioned release.

### Command

```
/workflow:release <version>
```

### Phases

1. **CHANGELOG** — Collect commits since last tag, categorize by type:
   - Features (feat:), Bug Fixes (fix:), Refactoring (refactor:), etc.
   - Generate CHANGELOG.md entry
2. **VERSION-BUMP** — Update version in build files:
   - Android: `build.gradle.kts` (versionName, versionCode)
   - React: `package.json` (version)
   - Python: `pyproject.toml` (version)
3. **RELEASE-BRANCH** — Create release branch per config (e.g., `release/v2.1.0`)
4. **PR** — Create PR from release branch to production with changelog as body
5. **TAG** — Provide tag command after merge: `git tag -a v2.1.0 -m "Release v2.1.0"`

---

## 13. Workflow: CI Fix

Diagnose and fix CI/CD failures.

### Command

```
/workflow:ci-fix [--run <run-id>] [--pr <pr-number>]
```

### Phases

1. **FETCH** — Get failure details:
   - `gh run list --status failure` or `gh run view <id> --log-failed`
2. **DIAGNOSE** — Classify failure:
   - Compile error, test failure, lint violation, dependency issue, config error, timeout
3. **FIX** — Apply targeted fix based on diagnosis type
4. **PUSH** — Commit with `fix(ci): <description>`, push to current branch
5. **MONITOR** — Provide `gh run watch` command to track the fix

---

## 14. Workflow: Migrate

Incremental migrations for dependencies, APIs, architecture, or databases.

### Command

```
/workflow:migrate <type>
```

Types: `dependency`, `api-version`, `architecture`, `database`

### Phases

1. **ANALYZE** — Document current state (versions, usage patterns, dependencies)
2. **BRAINSTORM** — Trade-off Matrix + Reverse Brainstorm for migration strategy
3. **PLAN** — Create incremental steps (each compiles and tests pass independently)
4. **EXECUTE** — Apply step by step with verification after each
5. **VERIFY** — Full test suite, build check
6. **PR** — Detailed PR with before/after, steps, rollback plan

### Type-Specific Guidance

- **dependency**: Version comparison, breaking changes, API diff
- **api-version**: Endpoint mapping, model transformation, backward compatibility
- **architecture**: Pattern migration, incremental refactoring
- **database**: Schema migration, data transformation, rollback scripts

---

## 15. Workflow: New Project

Bootstrap a new project for Claude Code workflows.

### Command

```
/workflow:new-project [project-path]
```

### Phases

1. **DETECT** — Scan for project type:
   - Build files: `build.gradle.kts`, `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`
   - CI system: `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`
   - Git conventions: commit history, branch names, PR templates
2. **CONFIGURE** — Present detection results, ask for confirmation, generate `.claude/workflows.yml`
3. **GENERATE** — Create `CLAUDE.md` with build commands, architecture overview, conventions
4. **SETUP** — Create `tasks/` directory, `.workflows/` directory, `.claude/skills/` structure

---

## 16. Brainstorming System

The brainstorm skill can run **standalone** or as part of any workflow.

### Standalone Usage

```
/workflow:brainstorm "authentication redesign" --depth deep --technique six-hats
```

### 5 Techniques

#### Trade-off Matrix

Score options against weighted criteria. Used at ALL depth levels.

```
| Criterion       | Weight | Option A | Option B | Option C |
|-----------------|--------|----------|----------|----------|
| Complexity      | 4      | 4 (16)   | 2 (8)    | 3 (12)   |
| Maintainability | 5      | 3 (15)   | 5 (25)   | 4 (20)   |
| Performance     | 3      | 5 (15)   | 3 (9)    | 4 (12)   |
| Testability     | 4      | 3 (12)   | 4 (16)   | 4 (16)   |
| Time            | 3      | 4 (12)   | 2 (6)    | 3 (9)    |
| **Total**       |        | **70**   | **64**   | **69**   |
```

#### Six Thinking Hats

Analyze from 6 perspectives:

| Hat | Perspective | Question |
|-----|------------|----------|
| White | Facts & Data | What do we know objectively? (LOC, files, performance, coverage) |
| Red | Feelings | How does this feel to maintain? First impressions? |
| Black | Risks | What could go wrong? Breaking changes? Security? Performance? |
| Yellow | Benefits | Code clarity? Reusability? DX improvements? Extensibility? |
| Green | Creativity | Can we combine approaches? Unconventional solutions? Phase it? |
| Blue | Process | Which hat was most revealing? What's the recommendation? |

#### SCAMPER

Generate ideas by asking 7 questions about existing code:

| Prompt | Software Example |
|--------|-----------------|
| **S**ubstitute | Replace inheritance with composition? Swap library for built-in? |
| **C**ombine | Merge two features into one component? Combine API calls? |
| **A**dapt | What patterns exist elsewhere in the codebase? Open-source solutions? |
| **M**odify | Simplify by reducing scope? Make more general-purpose? |
| **P**ut to other use | Repurpose existing utility? Reuse test infrastructure? |
| **E**liminate | Remove unnecessary abstractions? Drop unused dependencies? |
| **R**earrange | Invert control flow? Different processing order? Restructure modules? |

#### Reverse Brainstorm

"How could we make this fail?" → Invert each failure into a mitigation:

```
Failure Mode: Race condition on concurrent booking modification
  Cause: Two users cancel same booking simultaneously
  Impact: High (data corruption)
  Likelihood: Medium
  Mitigation: Use optimistic locking via API ETag
  Detection: Monitoring alert on 409 Conflict responses
```

#### Constraint Mapping

Filter options by hard vs soft constraints before analysis:

```
| Constraint           | Type | Option A | Option B | Option C |
|----------------------|------|----------|----------|----------|
| API 24+ support      | Hard | PASS     | PASS     | FAIL ❌  |
| No new dependencies  | Soft | FULL     | MISS     | --       |
| Under 500ms response | Hard | PASS     | PASS     | --       |
```

Option C eliminated (failed hard constraint). Remaining options proceed to trade-off matrix.

### 3 Depth Levels

| Depth | Options | Techniques | When |
|-------|---------|-----------|------|
| `quick` | 2 | Trade-off Matrix only | Simple decisions, < 5 files |
| `standard` | 3 | 1 technique + Trade-off Matrix | Most features |
| `deep` | 4+ | Multiple techniques + Trade-off Matrix | Architecture changes, high-risk |

### Default Techniques Per Workflow

| Workflow | Default Technique |
|----------|------------------|
| new-feature | Six Thinking Hats + Trade-off Matrix |
| extend-feature | SCAMPER + Trade-off Matrix |
| refactor | Trade-off Matrix + Reverse Brainstorm |
| migrate | Trade-off Matrix + Reverse Brainstorm |

### Output

Decision document saved to `.workflows/specs/<name>.decisions.md` with:
- Problem statement
- Options considered
- Analysis results
- Chosen option with rationale
- Trade-offs accepted
- Action items

---

## 17. Git Flow Management

All git operations are handled by the `git-flow` skill, which reads configuration from `workflows.yml`.

### Branch Operations

```
Create:  Reads git.branches.<type> → replaces {name}/{version} → creates branch
Push:    git push -u origin <branch>
Delete:  After merge (if git.merge.delete_branch is true)
```

### Commit Format

**Conventional** (default):
```
feat: add user profile avatar
feat(auth): add biometric login
fix: prevent crash on empty results
refactor(search): extract search logic to interactor
test: add coverage for BookingRepository
```

**Angular** (with required scope):
```
feat(auth): add biometric login support
fix(search): handle null query parameter
```

**Simple** (free-form):
```
Add user profile avatar upload
```

### PR Creation

```bash
gh pr create \
  --base <git.pr.base_branch> \
  --title "<commit-type>: <description>" \
  --body "<git.pr.template with variables substituted>"
```

Variables: `{summary}`, `{changes}`, `{test_plan}`, `{ticket}`

### Protected Branch Warnings

If you try to commit directly to a protected branch:

```
WARNING: "Production" is a protected branch.
Create a feature branch instead? [Y/n]
```

### Hotfix Cherry-Pick

After a hotfix merges to production, the git-flow skill provides:

```bash
git checkout Development
git pull origin Development
git cherry-pick <merge-commit-hash>
git push origin Development
```

---

## 18. Multi-Session Context & State Management

The biggest challenge with AI agents is **context loss between sessions**. Claude Workflows solves this with three-layer persistence.

### The Three Layers

```
Layer 1: STATE FILE     → Where am I in the workflow?
Layer 2: SPEC + PLAN    → What am I building and how?
Layer 3: GIT STATE      → What code have I already written?
```

### Layer 1: State File (`.workflows/current-state.md`)

The session recovery anchor. Updated at every phase transition:

```markdown
# Active Workflow

| Field | Value |
|-------|-------|
| Workflow | new-feature |
| Feature | booking-cancellation |
| Started | 2026-03-25T10:30:00Z |
| Current Phase | IMPLEMENT |
| Sub-Phase | Phase C: UI Layer |
| Branch | alpha-feature/Booking_cancellation |
| Last Session | 2026-03-25T14:00:00Z |

## Phase History

| Phase | Status | Started | Completed |
|-------|--------|---------|-----------|
| GATHER | done | 10:30 | 10:35 |
| SPEC | done | 10:35 | 10:50 |
| BRAINSTORM | done | 10:50 | 11:10 |
| PLAN | done | 11:10 | 11:30 |
| IMPLEMENT/A: Data | done | 11:30 | 11:45 |
| IMPLEMENT/B: Domain | done | 11:45 | 12:00 |
| IMPLEMENT/C: UI | in-progress | 14:00 | - |

## Completed Items
- [x] Created BookingCancellationResponse
- [x] Created CancelBookingInteractor
- [x] Created BookingCancellationUiState

## Remaining Items
- [ ] Create BookingCancellationViewModel
- [ ] Create CancellationScreen composable
- [ ] Wire navigation
- [ ] Add analytics events
- [ ] Write unit tests

## Context Notes
- API uses POST /bookings/{id}/cancel with reason field
- User confirmed: show confirmation dialog before cancel
- CancellationReason is an enum from API (5 values)

## Files Modified This Workflow
- core/data/models/booking/BookingCancellationResponse.kt (NEW)
- core/domain/booking/CancelBookingInteractor.kt (NEW)
- features/booking/model/BookingCancellationUiState.kt (NEW)
```

### Layer 2: Spec + Plan

- **Spec** (`.workflows/specs/<name>.spec.md`): What we're building — requirements, acceptance criteria
- **Decisions** (`.workflows/specs/<name>.decisions.md`): Why we chose this approach
- **Plan** (`.claude/plan-<name>.md`): How we're building it — with `[x]` checkmarks showing progress

### Layer 3: Git State

- **Branch**: All committed code lives on the feature branch
- **Git log**: Shows committed phases
- **Git diff**: Shows uncommitted work from the last session

### Session Recovery Protocol

When a new session starts:

```
1. Check .workflows/current-state.md
   │
   ├── FOUND (active workflow):
   │   ├── Read state → know phase + progress
   │   ├── Read spec → know what we're building
   │   ├── Read plan → see what's done [x] and remaining [ ]
   │   ├── Check git branch → verify correct branch
   │   ├── Check git diff → find uncommitted work
   │   │
   │   └── Report:
   │       "Resuming: booking-cancellation
   │        Phase: IMPLEMENT (C: UI Layer)
   │        Progress: 7/13 items done
   │        Next: Create BookingCancellationViewModel"
   │
   └── NOT FOUND:
       └── Ready for new workflow
```

### Context Notes: The Decision Journal

The `Context Notes` section captures decisions and discoveries:

```
- User prefers confirmation dialog over swipe-to-cancel
- API team confirmed: helpUrl will be nullable starting v3.2
- Reusing CondorDialog component for confirmation
- Booking list does NOT need refresh after cancel
```

Written whenever:
- User makes a decision at a decision point
- A technical discovery affects the approach
- An assumption is validated or invalidated

### Multi-Workflow Support

Only one workflow active at a time:

```
Active workflow detected: booking-cancellation (Phase: IMPLEMENT)
Options:
1. Resume current workflow
2. Pause (state preserved as paused-booking-cancellation.md)
3. Abandon (archived to history/)
```

---

## 19. Todo & Lessons System

### Todo (`tasks/todo.md`)

The operational checklist. Generated from the plan, updated during implementation:

```markdown
# Todo: Booking Cancellation Feature

## Current Workflow
- Workflow: new-feature
- Branch: alpha-feature/Booking_cancellation

## Data Layer
- [x] Create BookingCancellationResponse
- [x] Create BookingCancellationDataModel
- [x] Add cancelBooking to BookingService

## Domain Layer
- [x] Create CancelBookingInteractor

## UI Layer
- [ ] Create BookingCancellationUiState
- [ ] Create BookingCancellationViewModel
- [ ] Create CancellationScreen

## Testing
- [ ] CancelBookingInteractorTest
- [ ] BookingCancellationViewModelTest

## Post-Implementation
- [ ] Create PR
```

**Lifecycle**: Created at PLAN → Updated during IMPLEMENT → Archived when done

### Lessons (`tasks/lessons.md`)

Captures mistakes to prevent repeating them:

```markdown
# Lessons Learned

## 2026-03-25: Nullable API fields
**What went wrong**: Non-null helpUrl field. API returned null → NPE.
**Correct pattern**: ALL API response fields must be nullable.
**Rule**: When creating API response models, make every field nullable.

## 2026-03-24: Build variant
**What went wrong**: Used `compileDebugKotlin` — ambiguous with multiple flavors.
**Correct pattern**: Use `compileForSaleDebugKotlin`.
**Rule**: Always use ForSale flavor prefix in Gradle commands.
```

**When written**:
- User corrects the agent
- REPLAN triggered (plan was wrong)
- Build/test fails unexpectedly
- Workflow completes (retrospective)

**When read**:
- Session start (highlight 2-3 most relevant)
- Before each implementation phase
- Plan review (cross-check against pitfalls)

### Todo vs Plan vs State

| File | What | When Updated |
|------|------|-------------|
| `tasks/todo.md` | Day-to-day checklist | After each implementation step |
| `.claude/plan-*.md` | Architectural thinking | During planning and REPLAN only |
| `.workflows/current-state.md` | Session handoff metadata | At phase boundaries |

---

## 20. Sub-Agent Strategy

Workflows use Claude Code sub-agents to parallelize work and protect the main context window.

### Usage by Phase

| Phase | Sub-Agents | Purpose |
|-------|-----------|---------|
| GATHER | 1 Explore | Scan codebase for similar features |
| BRAINSTORM | 2 Explore (parallel) | Agent 1: analyze target area; Agent 2: find alternatives |
| PLAN | 1 Plan | Design implementation from brainstorm results |
| IMPLEMENT | None | Main thread writes all code for coherent commits |
| TEST | 1 background | Run test suite while main thread prepares |
| REVIEW | 1 code-review-expert | Analyze PR diff, generate inline comments |
| HOTFIX | 1 Explore | Parse crash logs, trace to source |
| CI-FIX | 1 general-purpose | Fetch and parse CI logs |

### Rules

1. **ONE task per sub-agent** — focused, not sprawling
2. **Main thread writes all code** — sub-agents only read and analyze
3. **Maximum 3 concurrent** at any time
4. **Results are summarized** — not dumped raw into context
5. **Background agents** for long-running tasks (test suites)
6. **No duplicate work** — if delegated to a sub-agent, main thread doesn't also do it

### Why Sub-Agents Matter

Long workflows (3+ sessions, 20+ files) can overwhelm the context window. Sub-agents:
- Offload heavy file reads (large ViewModels, test suites)
- Keep the main thread focused on writing code
- Prevent context overflow on multi-session workflows

---

## 21. Project Skills Integration

Workflows automatically discover and use your project-specific skills.

### How Discovery Works

When a workflow needs a capability (e.g., "analyze code"), it checks:

```
1. .claude/skills/code-analyzer/SKILL.md       ← Project skill (wins)
2. .claude/skills/_core/code-analyzer/SKILL.md  ← Core skill (fallback)
3. Built-in behavior                             ← Default
```

### Integration Map

| Workflow Phase | Looks For | If Found |
|---------------|-----------|----------|
| ANALYZE | `code-analyzer` | Uses project's code analysis patterns |
| IMPLEMENT (UI) | `figma-to-compose` | Uses project's Figma→Compose mapping |
| IMPLEMENT (UI) | `compose-screen` | Uses project's screen assembly patterns |
| IMPLEMENT (API) | `api-integration` | Uses project's API patterns |
| IMPLEMENT (Analytics) | `analytics-integration` | Uses project's analytics patterns |
| TEST | `test-ninja` | Uses project's test conventions |
| REVIEW | `review-pr` | Uses project's review patterns |

### Example: 4Sale Project

The 4Sale project has 9 project skills. During `/workflow:new-feature`:

```
Phase A (Data)      → api-integration (project) → ForSaleDataResult, Service+Repository pattern
Phase B (Domain)    → generic (no project skill)
Phase C (UI)        → figma-to-compose (project) → CondorTheme, DS components
                    → compose-screen (project) → Screen+ScreenContent split, stateIn()
Phase E (Analytics) → analytics-integration (project) → TrackableEvent, EventsKey
Phase F (Testing)   → test-ninja (project) → MockK, Turbine, Given/When/Then
```

### How to Override a Core Workflow

Create a skill with the same name in `.claude/skills/`:

```bash
mkdir .claude/skills/test
# Write your custom test/SKILL.md
```

Your version will be used instead of `_core/test/SKILL.md`.

### Your Orchestrator + Workflows

Your `fawzy` orchestrator can route to workflow commands:

```
/create-feature → /workflow:new-feature
/build-ui       → figma-to-compose (direct, no workflow)
/write-tests    → /workflow:test
```

---

## 22. File Reference

### Files Created by Installation

| Path | Tracked in Git | Purpose |
|------|:-:|-------|
| `.claude/skills/_core/*/SKILL.md` | Yes | Core workflow skills (13 files) |
| `.claude/templates/*.tmpl` | Yes | Document templates (4 files) |
| `.claude/workflows.yml` | Yes | Configuration |
| `.claude/.workflows-version` | Yes | Installed version |
| `.workflows/specs/` | Yes | Feature specs and decisions |
| `.workflows/current-state.md` | No | Active workflow state |
| `.workflows/paused-*.md` | No | Paused workflow states |
| `.workflows/history/` | No | Completed workflow logs |
| `CLAUDE.md` | Yes | Workflow instructions for Claude |

### Files Created During Workflows

| Path | Tracked | Created By |
|------|:-:|-----------|
| `.workflows/specs/<name>.spec.md` | Yes | SPEC phase |
| `.workflows/specs/<name>.decisions.md` | Yes | BRAINSTORM phase |
| `.claude/plan-<name>.md` | Yes | PLAN phase |
| `tasks/todo.md` | Yes | PLAN phase |
| `tasks/lessons.md` | Yes | Corrections/failures |
| `.workflows/history/<date>-<name>.md` | No | Workflow completion |

### Recommended .gitignore

```
# Workflow runtime state (per-developer)
.workflows/current-state.md
.workflows/paused-*.md
.workflows/history/
```

---

## 23. Upgrading

### Upgrade Steps

```bash
# Pull latest version
cd /tmp/claude-workflows && git pull

# Run upgrader from your project
cd /path/to/your-project
bash /tmp/claude-workflows/upgrade.sh
```

### What Gets Updated

| Component | Updated | Preserved |
|-----------|:-------:|:---------:|
| `.claude/skills/_core/` | Yes | - |
| `.claude/templates/` | Yes | - |
| `.claude/.workflows-version` | Yes | - |
| `.claude/workflows.yml` | - | Yes |
| `.claude/skills/<project>/` | - | Yes |
| `.workflows/` | - | Yes |
| `tasks/` | - | Yes |

### Version Check

```bash
# Current version
cat .claude/.workflows-version

# Available version
cat /tmp/claude-workflows/VERSION
```

---

## 24. Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| Skills don't appear in Claude Code | Check `.claude/skills/_core/` exists and has SKILL.md files |
| `/workflow:status` not recognized | Verify CLAUDE.md has the workflow instructions block |
| Git operations fail | Check `workflows.yml` branch names match your actual branches |
| PR creation fails | Run `gh auth status` — may need `gh auth login` |
| State file corrupted | Delete `.workflows/current-state.md` and restart the workflow |
| Paused workflow won't resume | Check `.workflows/paused-<name>.md` exists and is valid |
| Installer fails | Ensure you're in a git repository root (`git rev-parse --show-toplevel`) |
| Upgrade doesn't take effect | Restart Claude Code session after upgrading |

### Reset Everything

If things go wrong, you can reset the workflow state without losing code:

```bash
# Reset workflow state (keeps code, specs, plans)
rm .workflows/current-state.md
rm .workflows/paused-*.md

# Full reinstall (preserves workflows.yml and project skills)
bash /tmp/claude-workflows/install.sh
```

### Getting Help

```
/workflow:status    # See current state
/workflow:history   # See past workflows
```

Check the skill files directly for detailed instructions:

```bash
cat .claude/skills/_core/new-feature/SKILL.md
cat .claude/skills/_core/workflow-engine/SKILL.md
```
