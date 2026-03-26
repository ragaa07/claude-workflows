# claude-workflows

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](VERSION)
[![npm](https://img.shields.io/npm/v/claude-dev-workflows)](https://www.npmjs.com/package/claude-dev-workflows)

**Portable, language-agnostic development workflows for Claude Code AI agents.**

claude-workflows provides 18 structured workflow skills that guide AI agents through software development tasks with consistent quality, configurable git flow, and multi-session context persistence. Skills adapt automatically to your project's language via `workflows.yml`. Teams can inject their own domain-specific skills, rules, and review checklists.

---

## Quick Start

### Installation

From your project root, run:

```bash
npx claude-dev-workflows init
```

### Install with Language Type

```bash
# Android/Kotlin project
npx claude-dev-workflows init --type android

# React/TypeScript project
npx claude-dev-workflows init --type react

# Python project
npx claude-dev-workflows init --type python

# Swift/iOS project
npx claude-dev-workflows init --type swift

# Go project
npx claude-dev-workflows init --type go
```

### Install with Team Skills

```bash
# Android team
npx claude-dev-workflows init --type android --team android

# iOS team
npx claude-dev-workflows init --type swift --team ios

# Frontend team
npx claude-dev-workflows init --type react --team frontend

# Backend team
npx claude-dev-workflows init --type python --team backend

# With safety guards
npx claude-dev-workflows init --type android --team android --with-guards
```

### Alternative: Install via Git Clone

```bash
git clone https://github.com/ragaa07/claude-workflows.git /tmp/claude-workflows
cd /path/to/your/project
node /tmp/claude-workflows/bin/cli.js init --type android --team android
```

### What Gets Installed

| Component | Path | Source |
|-----------|------|--------|
| Core skills (18) | `.claude/skills/` | Always installed |
| Orchestration rules | `.claude/skills/_orchestration/` | Always installed |
| Team skills | `.claude/skills/` | Merged with `--team` |
| Language rules | `.claude/rules/` | Based on `--type` |
| Review checklists | `.claude/reviews/` | Based on `--type` + `--team` |
| Templates | `.claude/templates/` | Always installed |
| Config | `.claude/workflows.yml` | Created from defaults |
| State directory | `.workflows/` | Always created |
| Safety guards | `.claude/guards.yml` | Only with `--with-guards` |

### Verify Installation

```bash
cat .claude/.workflows-version
# Should print: 2.0.0
```

Then start a Claude Code session and run:

```
/workflow:start
```

---

## Workflows

| Command | Description |
|---------|-------------|
| `/workflow:new-feature` | Full feature workflow: spec, brainstorm, plan, implement, test, PR |
| `/workflow:extend-feature` | Add capabilities to an existing feature with backward compatibility |
| `/workflow:hotfix` | Emergency production fix: diagnose, fix, regression test, PR, cherry-pick |
| `/workflow:refactor` | Safely restructure code with behavioral contracts and rollback plans |
| `/workflow:release` | Versioned release: changelog, version bump, release branch, PR, tag |
| `/workflow:review` | Systematic PR review: fetch, categorize, check, comment |
| `/workflow:test` | Generate tests with coverage analysis and gap reporting |
| `/workflow:brainstorm` | Standalone brainstorming with 5 structured techniques |
| `/workflow:new-project` | Bootstrap a project: detect stack, generate config, scaffold files |

### Session Management

| Command | Description |
|---------|-------------|
| `/workflow:start` | Start a new workflow, show active workflow status, or manage sessions |
| `/workflow:resume` | Resume a paused or interrupted workflow |

The `/start` and `/resume` skills handle all session management internally, including pausing, abandoning, and viewing history of workflows.

---

## Configuration

All workflow configuration lives in `.claude/workflows.yml`. Edit this file to match your project's conventions.

### Key Sections

```yaml
# Project identity
project:
  name: "My Project"
  type: "android"          # android | react | python | generic
  language: "kotlin"       # Skills adapt to this automatically

# Git conventions
git:
  branches:
    main: "main"
    development: "develop"
    feature: "feature/{name}"
  commits:
    format: "conventional"  # conventional | angular | simple
  pr:
    base_branch: "develop"
    template: "..."

# Per-workflow settings
workflows:
  new-feature:
    require_spec: true
    require_tests: true
    require_brainstorm: true
  hotfix:
    base_branch: "main"
    require_tests: false

# Quality gate
quality:
  rules_dir: ".claude/rules"
  reviews_dir: ".claude/reviews"

# Brainstorming
brainstorm:
  default_depth: "standard" # quick | standard | deep

# Command aliases
skills:
  aliases:
    build: "new-feature"
    fix: "hotfix"
    ship: "release"
```

See [`config/defaults.yml`](config/defaults.yml) for the full configuration reference with all available options.

---

## Git Flow

### Branch Naming

Branch names are generated from patterns in `git.branches`. The `{name}` placeholder is replaced with the kebab-case feature name, and `{version}` with the version string.

| Type | Default Pattern | Example |
|------|----------------|---------|
| Feature | `feature/{name}` | `feature/user-profile` |
| Bugfix | `bugfix/{name}` | `bugfix/login-crash` |
| Hotfix | `hotfix/{name}` | `hotfix/null-pointer-fix` |
| Release | `release/v{version}` | `release/v2.1.0` |

### Commit Format

Three formats are supported via `git.commits.format`:

**Conventional** (default):
```
feat: add user profile avatar upload
fix: prevent crash on empty search results
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

### PR Templates

The `git.pr.template` field supports variable substitution:

| Variable | Source |
|----------|--------|
| `{summary}` | Generated from commits and spec |
| `{changes}` | Bulleted list from git diff |
| `{test_plan}` | From test phase or manual input |
| `{ticket}` | Ticket reference from workflow state |

### Merge Strategy

Configured via `git.merge.strategy`:

| Strategy | Description |
|----------|-------------|
| `squash` | Combine all commits into one (default) |
| `merge` | Preserve full commit history |
| `rebase` | Linear history, no merge commits |

### Protected Branches

Branches listed in `git.protected` trigger a warning before direct commits. Workflows will always create feature branches instead of committing directly to protected branches.

---

## Quality Gate

Rules and review checklists work together as a quality gate throughout the workflow lifecycle.

### Rules (`.claude/rules/`)

Language-specific rules are loaded during the IMPLEMENT phase. They provide guardrails that the AI agent follows while writing code.

```markdown
## Architecture
- DO use MVVM + Clean Architecture
- DON'T put business logic in ViewModel -- use UseCases

## Error Handling
- DO wrap IO operations in try/catch
- DON'T swallow exceptions silently
```

Rules are sourced from two places:
1. **Language rules** -- installed based on `--type` (e.g., `kotlin.md`, `react.md`)
2. **Team rules** -- installed based on `--team` (e.g., `team-conventions.md`)

### Review Checklists (`.claude/reviews/`)

Review checklists are applied as a pre-PR quality gate. Before creating a pull request, the workflow runs through the applicable checklist to catch issues early.

```markdown
| Check | Severity | What to Look For |
|-------|----------|------------------|
| Architecture compliance | High | No layer violations |
| Error handling | High | All IO operations handle failures |
| Naming conventions | Medium | Follows team standards |
```

Checklists are sourced from:
1. **Language checklists** -- installed based on `--type` (e.g., `kotlin-checklist.md`)
2. **Team checklists** -- installed based on `--team`

### How They Work Together

```
IMPLEMENT phase --> Rules loaded as constraints
    |
TEST phase ------> Tests verify behavior
    |
PR phase --------> Review checklist applied as final gate
```

---

## Brainstorming

The brainstorm skill supports 5 structured techniques and 3 depth levels. It can run standalone (`/workflow:brainstorm <topic>`) or as part of a workflow's BRAINSTORM phase.

### Techniques

| Technique | What It Does |
|-----------|-------------|
| **Trade-off Matrix** | Score options against weighted criteria (complexity, maintainability, performance, testability, time, risk, extensibility). Used at all depth levels. |
| **Six Thinking Hats** | Analyze options through 6 perspectives: facts (white), intuition (red), risks (black), benefits (yellow), creativity (green), process (blue). |
| **SCAMPER** | Generate ideas by asking: Substitute, Combine, Adapt, Modify, Put to other use, Eliminate, Rearrange. |
| **Reverse Brainstorm** | Brainstorm ways to cause failure, then invert each failure into a mitigation strategy. |
| **Constraint Mapping** | Identify hard constraints (must satisfy) and soft constraints (should satisfy) to filter approaches before analysis. |

### Depth Levels

| Level | Options | Techniques | When to Use |
|-------|---------|-----------|-------------|
| `quick` | 2 | Trade-off Matrix only | Small decisions, time-sensitive |
| `standard` | 3 | 1 primary + Trade-off Matrix | Most features and refactors |
| `deep` | 4+ | Multiple + Trade-off Matrix | Architecture decisions, high-risk changes |

Override depth on any invocation:

```
/workflow:brainstorm --depth deep "authentication redesign"
```

---

## Multi-Session Context

Workflows persist state across Claude Code sessions using four mechanisms:

### 1. State File (`.workflows/current-state.md`)

Tracks the active workflow's current phase, timestamps, and history. Updated at every phase transition.

```markdown
# Workflow State
- **workflow**: new-feature
- **feature**: payment-flow
- **phase**: IMPLEMENT
- **started**: 2025-03-20T10:00:00Z
- **updated**: 2025-03-20T14:30:00Z

## Phase History
| Phase      | Status    | Timestamp           | Notes                    |
|------------|-----------|---------------------|--------------------------|
| SPEC       | COMPLETED | 2025-03-20T10:15:00Z | Spec approved            |
| BRAINSTORM | COMPLETED | 2025-03-20T11:00:00Z | Option B selected        |
| PLAN       | COMPLETED | 2025-03-20T11:30:00Z | 6-phase plan approved    |
| BRANCH     | COMPLETED | 2025-03-20T11:32:00Z | feature/payment-flow     |
| IMPLEMENT  | ACTIVE    | 2025-03-20T11:35:00Z | Phase C in progress      |
```

### 2. Phase Output Documents (`.workflows/<feature>/`)

Each completed phase writes a numbered output document:

```
.workflows/payment-flow/01-spec.md
.workflows/payment-flow/02-brainstorm.md
.workflows/payment-flow/03-plan.md
```

These documents persist between sessions, providing full context for any resumed workflow.

### 3. Implementation Plan (`.claude/plan-<name>.md`)

The phased implementation plan with checkable items. Progress is tracked per-phase so a new session knows exactly where to resume.

### 4. Git History

Commits made during implementation serve as a durable record. Even if state files are lost, the branch and commit history provide recovery context.

### Session Recovery Protocol

At the start of every session, the workflow engine checks for active and paused workflows:

1. If `.workflows/current-state.md` exists: report the active workflow and offer to resume, restart, or abandon.
2. If paused workflows exist (`.workflows/paused-*.md`): list them with their paused phase.
3. If nothing exists: ready for a new workflow.

---

## Todo & Lessons

Workflows integrate with two task-tracking files:

### `tasks/todo.md`

Tracks in-progress work with checkable items. Workflows automatically add and update entries:

```markdown
## In Progress
- [ ] Payment Flow (plan: `.claude/plan-payment-flow.md`)
  - [x] Phase A: Data Layer
  - [x] Phase B: Domain Layer
  - [ ] Phase C: UI Layer
  - [ ] Phase D: Navigation
  - [ ] Phase E: Analytics
  - [ ] Phase F: Testing
  - [ ] PR Created
```

### `tasks/lessons.md`

Captures corrections and patterns discovered during development. The `learn` skill writes entries in markdown format:

```markdown
## 2025-03-20 -- Build variant ambiguity

**What went wrong**: Used `compileDebugKotlin` which is ambiguous with multiple flavors.
**Correct pattern**: Use `compileForSaleDebugKotlin` for the ForSale flavor.
**Rule**: Always qualify build tasks with the flavor name in multi-flavor projects.
```

Lessons are reviewed at session start and checked before each implementation phase.

---

## Sub-Agents

Workflows use Claude Code sub-agents to keep the main context window clean and focused on implementation.

### How They Are Used

- **Codebase research**: Find similar patterns, existing components, and integration points before writing new code.
- **Parallel analysis**: Analyze multiple files or modules simultaneously during brainstorming.
- **Compile checks**: Run build commands while the main thread continues planning.
- **Boilerplate generation**: Generate DI modules, navigation setup, and test scaffolding.

### Rules

- Maximum 3 concurrent sub-agents.
- One focused task per sub-agent.
- Sub-agents only read and analyze -- the main thread writes all implementation code.
- Sub-agent results are summarized before being incorporated into the workflow.

---

## Skills & Customization

Skills are language-agnostic and organized in three tiers. Higher tiers override lower ones.

### Directory Structure

```
.claude/
  skills/
    _orchestration/RULES.md      # Shared orchestration rules (all workflows)
    new-feature/SKILL.md         # Core skill (auto-discovered as /new-feature)
    hotfix/SKILL.md              # Core skill
    brainstorm/SKILL.md          # Core skill
    example-skill/SKILL.md       # Team skill (same level)
    my-custom-skill/SKILL.md     # Project-specific skill (same level)
    ...
```

All skills are **auto-discovered** by Claude Code as slash commands. No registration needed.

Skills read `project.language` from `workflows.yml` and adapt their instructions accordingly -- no separate language-specific skill variants are needed.

### Install-Time Priority

The installer copies skills in order -- last write wins:

1. **Core skills** are copied first
2. **Team skills** overwrite core if same name (via `--team`)
3. **Project skills** can be added manually after install to override anything

### Override Pattern

To override a core skill, the team defines a skill with the same name in `teams/<team>/skills/`. Or a developer creates one manually in `.claude/skills/`.

---

## Team Setup

Teams can define their own domain-specific skills, architecture rules, and review checklists. The framework provides templates -- teams write the content.

### Creating a New Team

```bash
# 1. Copy the template
cp -r teams/_template teams/<your-team-name>
# Example: cp -r teams/_template teams/android
```

### Team Directory Structure

```
teams/<your-team-name>/
  manifest.yml                  # Team metadata and skill declarations
  skills/
    example-skill/
      SKILL.md                  # Rename and customize this
    your-skill-name/
      SKILL.md                  # Add as many skills as needed
  rules/
    team-conventions.md         # DO/DON'T rules for your team
  reviews/
    team-review-checklist.md    # Review quality gates
```

### Step-by-Step

**1. Edit `manifest.yml`**

```yaml
team: "android"
description: "Android team conventions and domain skills"
requires_type: android

skills:
  - integrate-analytics
  - scaffold-screen

rules:
  - team-conventions.md

reviews:
  - team-review-checklist.md
```

**2. Create your skills** -- copy the example skeleton and customize:

```bash
cp -r teams/android/skills/example-skill teams/android/skills/integrate-analytics
# Edit teams/android/skills/integrate-analytics/SKILL.md
```

Each skill is a `SKILL.md` file with this structure:

```markdown
---
name: integrate-analytics
description: Add analytics event tracking following team conventions.
---

# Skill Name

## Command
/workflow:integrate-analytics <event-name>

## Overview
What this skill does and when to use it.

## Phase 1: ANALYZE
Steps to understand the current state...

## Phase 2: IMPLEMENT
Steps to make the changes...

## Phase 3: VERIFY
Checklist to confirm correctness...

## Error Handling
What to do when things go wrong...
```

**3. Edit team rules** (`rules/team-conventions.md`):

```markdown
## Architecture
- DO use MVVM + Clean Architecture
- DON'T put business logic in ViewModel -- use UseCases

## Naming
- DO use PascalCase for classes, camelCase for functions
- DON'T use abbreviations in public API names
```

**4. Edit team review checklist** (`reviews/team-review-checklist.md`):

```markdown
| Check | Severity | What to Look For |
|-------|----------|------------------|
| Architecture compliance | High | No layer violations |
| Error handling | High | All IO operations handle failures |
| Naming conventions | Medium | Follows team standards |
```

**5. Commit to the shared repo** -- now every developer on the team gets these skills:

```bash
cd claude-workflows
git add teams/android/
git commit -m "feat: add android team skills and conventions"
```

**6. Developers install with the team flag:**

```bash
npx claude-dev-workflows init --type android --team android
```

### What Each Developer Gets

| Source | `--type` only | `--type` + `--team` |
|--------|---------------|---------------------|
| Core skills (18) | Yes | Yes |
| Orchestration rules | Yes | Yes |
| Language rules | Yes | Yes |
| Language review checklist | Yes | Yes |
| Team skills | No | Yes |
| Team rules | No | Yes |
| Team review checklist | No | Yes |

### Built-in Teams

Four teams ship out of the box, each with a template skeleton ready for customization:

| Team | `--team` | `--type` | Description |
|------|----------|----------|-------------|
| Android | `android` | `android` | Kotlin/Compose, MVVM, Hilt |
| iOS | `ios` | `swift` | Swift/SwiftUI conventions |
| Frontend | `frontend` | `react` | React/TypeScript conventions |
| Backend | `backend` | `python` | Python backend conventions |

```bash
# Android project
npx claude-dev-workflows init --type android --team android

# iOS project
npx claude-dev-workflows init --type swift --team ios

# Frontend project
npx claude-dev-workflows init --type react --team frontend

# Backend project
npx claude-dev-workflows init --type python --team backend
```

### Adding a New Team

```bash
# In the claude-workflows repo
cp -r teams/_template teams/<your-team-name>
# Edit the manifest, add skills, publish a new version
```

---

## Upgrading

To upgrade to the latest version:

```bash
npx claude-dev-workflows@latest upgrade
```

Upgrade with team and language rules:

```bash
# Android team
npx claude-dev-workflows@latest upgrade --type android --team android

# iOS team
npx claude-dev-workflows@latest upgrade --type swift --team ios

# Frontend team
npx claude-dev-workflows@latest upgrade --type react --team frontend

# Backend team
npx claude-dev-workflows@latest upgrade --type python --team backend

# With safety guards
npx claude-dev-workflows@latest upgrade --type android --team android --with-guards
```

Pin to a specific version:

```bash
npx claude-dev-workflows@1.6.0 upgrade
```

The upgrade:
1. Replaces core skills in `.claude/skills/` (tracked via manifest)
2. Copies team skills on top (if `--team` specified)
3. Updates language rules (if `--type` specified)
4. Preserves your `.claude/workflows.yml` configuration
5. Preserves project-specific skills not in the core manifest
6. Updates the version marker in `.claude/.workflows-version`

---

## Architecture

### Directory Structure

```
claude-workflows/
  package.json                # npm package definition
  bin/
    cli.js                    # CLI entry point (init, upgrade, version, list-teams)
  config/
    defaults.yml              # Default configuration template
  core/
    CLAUDE.workflows.md       # Main workflow instructions (appended to CLAUDE.md)
    skills/                   # 18 core workflow skills + orchestration
      _orchestration/         # Shared rules applied to every workflow execution
      start/                  # Start new workflows, manage sessions
      resume/                 # Resume paused or interrupted workflows
      git-flow/               # Branch, commit, PR, and merge operations
      new-project/            # Project bootstrapping and detection
      new-feature/            # Full feature workflow (8 phases)
      extend-feature/         # Extend existing feature (7 phases)
      hotfix/                 # Emergency production fix (5 phases)
      refactor/               # Safe code restructuring (7 phases)
      release/                # Versioned release (5 phases)
      review/                 # PR code review (4 phases)
      test/                   # Test generation with coverage
      brainstorm/             # 5 brainstorming techniques
      ci-fix/                 # CI pipeline fixes
      migrate/                # Project migrations
      learn/                  # Capture patterns in markdown
      dry-run/                # Preview workflows
      metrics/                # Workflow metrics
      guards/                 # Safety guard enforcement
    rules/                    # Language-specific rules (7 files)
    reviews/                  # Language-specific review checklists (8 files)
    templates/                # spec, plan, state, changelog, guards templates
  teams/                      # Team-specific content
    _template/                # Skeleton for creating new teams
      manifest.yml
      skills/example-skill/SKILL.md
      rules/team-conventions.md
      reviews/team-review-checklist.md
  VERSION                     # Current version
```

### State Machine

All workflows follow a phase-based state machine. Phases proceed sequentially unless configuration explicitly allows skipping.

```
INIT -> SPEC -> BRAINSTORM -> PLAN -> BRANCH -> IMPLEMENT -> TEST -> PR -> DONE
               (skippable)                                  (skippable)
```

Phase skipping based on workflow config:
- `require_brainstorm: false` skips BRAINSTORM
- `require_tests: false` skips TEST
- `require_spec: false` skips SPEC

### Orchestration Rules

The `_orchestration/RULES.md` file contains rules that apply to every workflow execution. These include:
- Phase output document format and naming
- State file update protocol
- Sub-agent usage constraints
- Error handling procedures

Previously these rules were duplicated in `start` and `resume` skills. They are now centralized in a single location.

### Skill Resolution Priority

When a `/workflow:<command>` is invoked:

1. Check if it is an **alias** defined in `skills.aliases`
2. Resolve to a **skill** (`.claude/skills/<name>/SKILL.md`)
3. Report **skill not found**

---

## Contributing

### Adding a Team Skill

1. Create a directory under `teams/<your-team>/skills/<skill-name>/`
2. Write `SKILL.md` using the template at `teams/_template/skills/example-skill/SKILL.md`
3. Update your team's `manifest.yml` to list the new skill
4. Test by running `npx claude-dev-workflows init --type <type> --team <your-team>` on a sample project

### Adding a New Core Workflow

1. Create a directory under `core/skills/<workflow-name>/`
2. Write `SKILL.md` with YAML frontmatter (`name`, `description`) and full phase instructions
3. Make the skill language-agnostic -- reference `project.language` from config rather than hardcoding language details
4. Follow the existing pattern: phases with numbered steps, decision points, error handling table
5. Add the workflow to `core/CLAUDE.workflows.md` command table
6. Add default config entries to `config/defaults.yml`

### Modifying an Existing Workflow

1. Edit the `SKILL.md` in `core/skills/<workflow-name>/`
2. Update `config/defaults.yml` if new config keys are added
3. Bump the version in `VERSION` if the change is user-facing
4. Test by running the workflow on a sample project

### Modifying Orchestration Rules

1. Edit `core/skills/_orchestration/RULES.md`
2. Changes apply to all workflows -- test across multiple workflow types
3. Keep rules concise -- every token counts in the context window

### Adding a Brainstorming Technique

1. Add the technique section to `core/skills/brainstorm/SKILL.md`
2. Add the technique name to `config/defaults.yml` under `workflows.brainstorm.techniques`
3. Document when the technique should be used (which depth levels)

### Pull Request Guidelines

- One workflow or skill change per PR
- Include a test plan describing how you verified the workflow
- Follow conventional commit format: `feat:`, `fix:`, `docs:`
- Target the `main` branch
