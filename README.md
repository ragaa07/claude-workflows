# claude-workflows

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](VERSION)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**Portable, spec-driven development workflows for Claude Code AI agents.**

claude-workflows provides 10 structured workflows and 3 utility skills that guide AI agents through software development tasks with consistent quality, configurable git flow, and multi-session context persistence.

---

## Quick Start

### Installation

Clone the repository and run the installer from your project root:

```bash
git clone https://github.com/4SaleTech/claude-workflows.git /tmp/claude-workflows
cd /path/to/your/project
bash /tmp/claude-workflows/install.sh
```

This will:
1. Copy core skills to `.claude/skills/_core/`
2. Create `.claude/workflows.yml` from defaults
3. Append workflow commands to your `CLAUDE.md`
4. Set up `.workflows/` state directory
5. Create `tasks/todo.md` and `tasks/lessons.md` scaffolding

### Verify Installation

```bash
cat .claude/.workflows-version
# Should print: 1.0.0
```

Then start a Claude Code session and run:

```
/workflow:status
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
| `/workflow:status` | Show active workflow state |

### Utility Commands

| Command | Description |
|---------|-------------|
| `/workflow:resume` | Resume a paused workflow |
| `/workflow:pause` | Pause the current workflow for later |
| `/workflow:abandon` | Discard the current workflow |
| `/workflow:history` | List completed workflows |

---

## Configuration

All workflow configuration lives in `.claude/workflows.yml`. Edit this file to match your project's conventions.

### Key Sections

```yaml
# Project identity
project:
  name: "My Project"
  type: "android"          # android | react | python | generic
  language: "kotlin"

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
| BRANCH     | COMPLETED | 2025-03-20T11:32:00Z | alpha-feature/Payment_Flow |
| IMPLEMENT  | ACTIVE    | 2025-03-20T11:35:00Z | Phase C in progress      |
```

### 2. Spec and Decision Documents (`.workflows/specs/`)

Feature specifications and brainstorm decision documents persist between sessions, providing full context for any resumed workflow.

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

Captures corrections and patterns discovered during development. After any user correction or unexpected failure, workflows append an entry:

```markdown
## 2025-03-20 — Build variant ambiguity

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

## Project Skills

Projects can define custom skills that coexist with or override core skills.

### Directory Structure

```
.claude/
  skills/
    _core/                    # Core skills (installed by claude-workflows)
      new-feature/SKILL.md
      hotfix/SKILL.md
      ...
    my-custom-skill/          # Project-specific skill
      SKILL.md
```

### Override Pattern

To override a core skill, create a skill with the same name in `.claude/skills/`:

```
.claude/skills/review/SKILL.md      # Your custom review workflow
.claude/skills/_core/review/SKILL.md # Core review (ignored when override exists)
```

### Resolution Priority

1. **Project skills**: `.claude/skills/<name>/SKILL.md`
2. **Core skills**: `.claude/skills/_core/<name>/SKILL.md`
3. **Fallback**: Skill not found error

---

## Upgrading

To upgrade core skills to the latest version:

```bash
cd /path/to/your/project
bash /path/to/claude-workflows/upgrade.sh
```

The upgrade script:
1. Updates core skills in `.claude/skills/_core/`
2. Preserves your `.claude/workflows.yml` configuration
3. Preserves any project-specific skills in `.claude/skills/`
4. Updates the version marker in `.claude/.workflows-version`

---

## Examples

Pre-configured `workflows.yml` files for common project types:

| Project Type | File | Highlights |
|-------------|------|-----------|
| **Android/Kotlin** | [`examples/android/workflows.yml`](examples/android/workflows.yml) | Git-flow branching, Gradle build, design system review standards |
| **React/TypeScript** | [`examples/react/workflows.yml`](examples/react/workflows.yml) | GitHub Flow, Jest testing, ESLint/Prettier, accessibility checks |
| **Python** | [`examples/python/workflows.yml`](examples/python/workflows.yml) | Trunk-based dev, pytest, ruff/black, mypy type checking |

Copy the relevant example to `.claude/workflows.yml` and customize for your project.

---

## Architecture

### Directory Structure

```
claude-workflows/
  config/
    defaults.yml              # Default configuration template
  core/
    CLAUDE.workflows.md       # Main workflow instructions (appended to CLAUDE.md)
    skills/
      workflow-engine/        # Meta-orchestrator: routing, state, session recovery
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
  examples/
    android/workflows.yml     # Android/Kotlin example config
    react/workflows.yml       # React/TypeScript example config
    python/workflows.yml      # Python example config
  install.sh                  # Installer script
  upgrade.sh                  # Upgrade script
  VERSION                     # Current version
```

### State Machine

All workflows follow a phase-based state machine. Phases must proceed sequentially -- no skipping unless the configuration explicitly allows it.

```
IDLE -> SPEC -> BRAINSTORM -> PLAN -> BRANCH -> IMPLEMENT -> TEST -> PR -> DONE
              (skippable)                                  (skippable)
```

Phases can be skipped based on workflow config:
- `require_brainstorm: false` skips BRAINSTORM
- `require_tests: false` skips TEST
- `require_spec: false` skips SPEC

### Skill Resolution Priority

When a `/workflow:<command>` is invoked:

1. Check if it is a **utility command** (status, resume, pause, abandon, history)
2. Check if it is an **alias** defined in `skills.aliases`
3. Resolve to a **project skill** (`.claude/skills/<name>/SKILL.md`)
4. Fall back to a **core skill** (`.claude/skills/_core/<name>/SKILL.md`)
5. Report **skill not found**

---

## Contributing

### Adding a New Workflow

1. Create a directory under `core/skills/<workflow-name>/`
2. Write `SKILL.md` with YAML frontmatter (`name`, `description`) and full phase instructions
3. Follow the existing pattern: phases with numbered steps, decision points, error handling table
4. Add the workflow to `core/CLAUDE.workflows.md` command table
5. Add default config entries to `config/defaults.yml`
6. Create an example entry if the workflow needs project-specific config

### Modifying an Existing Workflow

1. Edit the `SKILL.md` in `core/skills/<workflow-name>/`
2. Update `config/defaults.yml` if new config keys are added
3. Bump the version in `VERSION` if the change is user-facing
4. Test by running the workflow on a sample project

### Adding a Brainstorming Technique

1. Add the technique section to `core/skills/brainstorm/SKILL.md`
2. Add the technique name to `config/defaults.yml` under `workflows.brainstorm.techniques`
3. Document when the technique should be used (which depth levels)

### Pull Request Guidelines

- One workflow or skill change per PR
- Include a test plan describing how you verified the workflow
- Follow conventional commit format: `feat:`, `fix:`, `docs:`
- Target the `Development` branch
