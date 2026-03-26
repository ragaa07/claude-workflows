# Claude Workflows — Complete Guide

## Table of Contents

1. [What Is Claude Workflows](#1-what-is-claude-workflows)
2. [Installation](#2-installation)
3. [Configuration](#3-configuration)
4. [The Workflow Lifecycle](#4-the-workflow-lifecycle)
5. [Quality Gate](#5-quality-gate)
6. [All Commands](#6-all-commands)
7. [Workflows In Depth](#7-workflows-in-depth)
8. [Brainstorming System](#8-brainstorming-system)
9. [Git Flow Management](#9-git-flow-management)
10. [Multi-Session State Management](#10-multi-session-state-management)
11. [Todo & Lessons System](#11-todo--lessons-system)
12. [Sub-Agent Strategy](#12-sub-agent-strategy)
13. [File Reference](#13-file-reference)
14. [Upgrading](#14-upgrading)
15. [Troubleshooting](#15-troubleshooting)

---

## 1. What Is Claude Workflows

A **portable, spec-driven development workflow system** for Claude Code AI agents. Structured, repeatable processes for building features, fixing bugs, refactoring, testing, and shipping releases.

**Core Principles**: Spec before code. Brainstorm before plan. Plan before implement. State persists across sessions. Quality gate before every PR. Language-agnostic (build/test commands auto-detected). Configurable git flow.

**What You Get**: 18 workflow skills, 5 brainstorming techniques, orchestration rules enforced on every execution, review checklists (general + language-specific), coding rules per language, multi-session persistence, and a single YAML config file.

---

## 2. Installation

**Prerequisites**: Git repository, Claude Code, Node.js 18+, `gh` CLI (for PR workflows).

```bash
# Option A: npx (recommended)
cd /path/to/your-project
npx claude-dev-workflows install

# Option B: clone + run directly
git clone https://github.com/<org>/claude-workflows /tmp/claude-workflows
node /tmp/claude-workflows/bin/cli.js install
```

Optional flags: `--type skills|templates`, `--with-guards`, `--team <name>`.

### What the Installer Does

| Action | Path |
|--------|------|
| Core skills (18 dirs) | `.claude/skills/` |
| Orchestration rules | `.claude/skills/_orchestration/RULES.md` |
| Templates (5 files) | `.claude/templates/` |
| Coding rules | `.claude/rules/` |
| Review checklists | `.claude/reviews/` |
| Config (if missing) | `.claude/workflows.yml` |
| State directory | `.workflows/` |
| Claude instructions | `CLAUDE.md` (appended, idempotent) |
| Gitignore entries | `.gitignore` |
| Version marker | `.claude/.workflows-version` |

### Verify & Commit

```bash
cat .claude/.workflows-version
ls .claude/skills/
git add .claude/ CLAUDE.md .workflows/ .gitignore
git commit -m "chore: install claude-workflows v2.0.0"
```

Then open Claude Code and run `/start`.

---

## 3. Configuration

All configuration lives in `.claude/workflows.yml`. See `config/defaults.yml` for the full reference.

```yaml
version: "1.0"

project:
  name: "My Project"
  type: "generic"                    # android | react | python | generic
  language: "kotlin"                 # Drives rule/checklist selection

git:
  branches:
    main: "main"
    development: "develop"
    feature: "feature/{name}"
    hotfix: "hotfix/{name}"
    release: "release/v{version}"
  commits:
    format: "conventional"           # conventional | angular | simple
  pr:
    base_branch: "develop"
  merge:
    strategy: "squash"
  protected: ["main", "develop"]

workflows:
  new-feature:
    require_spec: true
    require_tests: true
    require_brainstorm: true
  hotfix:
    base_branch: "main"
    require_tests: false
  release:
    changelog: true
    tag_format: "v{version}"
  review:
    standards: []
    auto_self_review: false
  brainstorm:
    default_depth: "standard"        # quick | standard | deep

skills:
  aliases:
    build: "new-feature"
    fix: "hotfix"
    ship: "release"

quality:
  self_review: true
  review_checklists: ["general-checklist.md"]
```

**Tips**: Start with `project.name`, `project.language`, and `git.branches`. The `project.language` drives which coding rules and review checklists are loaded automatically.

---

## 4. The Workflow Lifecycle

Every workflow follows a state machine:

```
IDLE → GATHER → SPEC → BRAINSTORM → PLAN → BRANCH → IMPLEMENT → TEST → PR → DONE
                                                          ↓
                                                     REPLAN → back to IMPLEMENT
```

| Phase | What Happens | Output |
|-------|-------------|--------|
| **GATHER** | Collect requirements (Jira, Figma, user, spec file) | Structured requirements |
| **SPEC** | Generate formal specification | `.workflows/<feature>/01-spec.md` |
| **BRAINSTORM** | Explore approaches, evaluate trade-offs | `.workflows/<feature>/02-brainstorm.md` |
| **PLAN** | Phased implementation plan | `.workflows/<feature>/plan<name>.md` |
| **BRANCH** | Create feature branch per git config | Git branch |
| **IMPLEMENT** | Write code phase-by-phase with build checks | Source code + commits |
| **TEST** | Write and run tests | Test files + results |
| **PR** | Push branch, create pull request | GitHub PR |
| **DONE** | Archive state, report summary | History entry |

**Orchestration rules** (`_orchestration/RULES.md`) apply to every execution: phase output documents written to `.workflows/<feature>/`, state updated at every transition, build/test commands auto-detected, quality gate enforced, workflow chaining supported.

**Skippable phases**: Set `require_spec/brainstorm/tests: false` in config or pass `--skip-brainstorm`.

**Decision points**: After SPEC, BRAINSTORM, PLAN, UI implementation, and before PR. The workflow never proceeds without your approval.

**REPLAN**: Triggered when compilation fails 3+ times, plan is wrong, or you request a change. Stops, documents the issue, re-plans, and asks for approval.

---

## 5. Quality Gate

Two mechanisms enforce code standards across all workflows.

### Coding Rules (`.claude/rules/`)

Language-specific DO/DON'T patterns loaded before implementation phases. Available for: Kotlin, TypeScript, Python, Go, Swift, React, Compose. Selected by `project.language` in config.

### Review Checklists (`.claude/reviews/`)

Before creating any PR, the agent self-checks against:
1. `general-checklist.md` (always loaded)
2. Language-specific checklist (auto-detected from `project.language`)
3. Team checklist (if defined)

Critical and High severity violations must be fixed before the PR is created.

```yaml
quality:
  self_review: true
  review_checklists: ["general-checklist.md"]
```

---

## 6. All Commands

| Command | Description |
|---------|-------------|
| `/new-feature <name>` | Build a new feature end-to-end |
| `/extend-feature <name>` | Add to an existing feature |
| `/refactor <target>` | Safely restructure code |
| `/hotfix [--crash <id>]` | Emergency production fix |
| `/test <target>` | Generate tests with coverage |
| `/review <pr-number>` | Review a pull request |
| `/release <version>` | Prepare a versioned release |
| `/ci-fix [--run <id>]` | Fix CI/CD failures |
| `/migrate <type>` | Incremental migration |
| `/new-project` | Bootstrap project setup |
| `/brainstorm <topic>` | Standalone brainstorming |
| `/start` | Start a new workflow or show status |
| `/resume` | Resume a paused/interrupted workflow |

Aliases (configurable): `/build` -> `/new-feature`, `/fix` -> `/hotfix`, `/ship` -> `/release`.

---

## 7. Workflows In Depth

### New Feature

The most comprehensive workflow. Takes a feature from idea to merged PR.

```
/new-feature <name> [--from-jira <ticket>] [--from-figma <url>] [--from-spec <path>] [--skip-brainstorm]
```

**GATHER**: Collects from Jira (MCP), Figma (MCP), spec file, or interactive questions. Multiple sources combinable. **SPEC**: Generates spec with user stories, acceptance criteria, scope, technical requirements, edge cases. **BRAINSTORM**: 2-4 approaches evaluated with structured techniques; produces decision document. **PLAN**: Phased implementation in `.workflows/<feature>/plan<name>.md` with files, details, build checks, commit messages per phase. Also generates `tasks/todo.md`. **BRANCH**: Per git config. **IMPLEMENT**: Phase-by-phase with build checks, commits, and state updates. Coding rules loaded. REPLAN on repeated failures. **TEST**: Targets all new code, reports coverage. **PR**: Quality gate checklists run, then `gh pr create`.

Decision points after SPEC, BRAINSTORM, PLAN, UI implementation, and before PR.

### Extend Feature

```
/extend-feature <name> [--describe "what to add"]
```

**Conservative** workflow: existing behavior must be preserved. Prefers adding new files over modifying existing ones. Uses SCAMPER brainstorming. If existing tests break, the extension is fixed (not the tests).

### Refactor

```
/refactor <target> [--scope files|module|feature] [--goal "description"]
```

Full dependency graph analysis, behavioral contracts documented before changes, incremental migration where **every step compiles and passes tests independently**. Uses Trade-off Matrix + Reverse Brainstorm.

### Hotfix

```
/hotfix [--crash <id>] [--error "description"] [--log <path>]
```

Optimized for **speed**. No brainstorming, no spec. Absolute minimum change, branches from production. Diagnose, Fix, Regression-Test, PR-to-Prod, Cherry-Pick. Should complete in minutes.

### Test

```
/test <target> [--coverage <pct>] [--type unit|integration]
```

Targets: `class:Name`, `file:path`, `module:name`, `feature:name`. Analyzes public API, dependencies, branches, edge cases. Writes tests following project conventions. Default coverage: 90%.

### Review

```
/review <pr-number>
```

Fetches PR via `gh`, categorizes changes by layer, checks architecture/quality/security/performance/coverage/standards. Generates inline comments with severity levels. You choose which to submit.

### Release

```
/release <version>
```

Changelog from commits since last tag, version bump (language-agnostic detection), release branch, PR to production, tag command.

### CI Fix

```
/ci-fix [--run <run-id>] [--pr <pr-number>]
```

Fetches failure details via `gh`, classifies (compile/test/lint/dependency/config/timeout), applies targeted fix, pushes, provides watch command.

### Migrate

```
/migrate <type>
```

Types: `dependency`, `api-version`, `architecture`, `database`. Each step compiles and tests pass independently. Type-specific guidance for version comparison, endpoint mapping, pattern migration, schema migration.

### New Project

```
/new-project [project-path]
```

Detects project type from build files, CI system, and git conventions. Generates `workflows.yml`, `CLAUDE.md`, and directory structure.

---

## 8. Brainstorming System

Runs standalone (`/brainstorm <topic>`) or as part of any workflow.

### 5 Techniques

| Technique | Method |
|-----------|--------|
| **Trade-off Matrix** | Score options against weighted criteria (complexity, maintainability, performance, testability, time) |
| **Six Thinking Hats** | 6 perspectives: Facts, Feelings, Risks, Benefits, Creativity, Process |
| **SCAMPER** | Substitute, Combine, Adapt, Modify, Put to other use, Eliminate, Rearrange |
| **Reverse Brainstorm** | "How could this fail?" — invert failures into mitigations |
| **Constraint Mapping** | Filter by hard/soft constraints before analysis |

### Depth Levels

| Depth | Options | Techniques | When |
|-------|---------|-----------|------|
| `quick` | 2 | Trade-off Matrix only | Simple decisions |
| `standard` | 3 | 1 technique + Trade-off Matrix | Most features |
| `deep` | 4+ | Multiple techniques + Trade-off Matrix | Architecture, high-risk |

**Defaults**: new-feature uses Six Hats, extend-feature uses SCAMPER, refactor/migrate use Reverse Brainstorm. All include Trade-off Matrix.

---

## 9. Git Flow Management

Handled by the `/git-flow` skill, reading from `workflows.yml`.

- **Branches**: Pattern-based (`feature/{name}`, `release/v{version}`)
- **Commits**: Conventional, Angular, or Simple format
- **PRs**: Template with `{summary}`, `{changes}`, `{test_plan}`, `{ticket}` variables
- **Protected branches**: Warns on direct commits, suggests feature branch
- **Hotfix cherry-pick**: Provides command to backport fix to development branch

---

## 10. Multi-Session State Management

Three-layer persistence solves context loss between sessions:

| Layer | File | Purpose |
|-------|------|---------|
| State | `.workflows/current-state.md` | Phase, progress, context notes |
| Spec + Plan | `.workflows/<feature>/`, `.workflows/<feature>/plan<name>.md` | What and how (with `[x]` progress) |
| Git | Branch, log, diff | Committed and uncommitted code |

**Session recovery** (`/resume`): Reads state, spec, plan; verifies branch; reports phase and progress; continues from where it left off.

**Context notes** in the state file capture decisions and discoveries throughout the workflow.

**One active workflow** at a time. Options: resume, pause (preserved as `paused-<name>.md`), or abandon (archived to `history/`).

---

## 11. Todo & Lessons System

**`tasks/todo.md`**: Operational checklist generated from the plan, updated during implementation.

**`tasks/lessons.md`**: Captures mistakes — what went wrong, correct pattern, prevention rule. Written on corrections, REPLAN triggers, failures. Read at session start and before each implementation phase.

| File | What | Updated |
|------|------|---------|
| `tasks/todo.md` | Day-to-day checklist | After each step |
| `.workflows/<feature>/plan*.md` | Architectural plan | Planning and REPLAN |
| `.workflows/current-state.md` | Session metadata | Phase boundaries |

---

## 12. Sub-Agent Strategy

Workflows use sub-agents to parallelize work and protect the main context window.

| Phase | Sub-Agents | Purpose |
|-------|-----------|---------|
| GATHER | 1 Explore | Scan codebase |
| BRAINSTORM | 2 parallel | Analyze + find alternatives |
| PLAN | 1 Plan | Design implementation |
| IMPLEMENT | None | Main thread writes all code |
| TEST | 1 background | Run test suite |
| REVIEW | 1 expert | Analyze PR diff |

Rules: One task per agent. Main thread writes all code. Max 3 concurrent. Results summarized, not dumped raw.

---

## 13. File Reference

### Installed by CLI

| Path | Git-tracked | Purpose |
|------|:-:|-------|
| `.claude/skills/*/SKILL.md` | Yes | 18 workflow skills |
| `.claude/skills/_orchestration/RULES.md` | Yes | Global orchestration rules |
| `.claude/templates/*.tmpl` | Yes | 5 document templates |
| `.claude/rules/*.md` | Yes | Per-language coding rules |
| `.claude/reviews/*.md` | Yes | Review checklists |
| `.claude/workflows.yml` | Yes | Configuration |
| `.claude/.workflows-version` | Yes | Version marker |
| `CLAUDE.md` | Yes | Claude instructions |

### Created During Workflows

| Path | Git-tracked | Created By |
|------|:-:|-----------|
| `.workflows/<feature>/NN-<phase>.md` | Yes | Each phase |
| `.workflows/current-state.md` | No | Phase transitions |
| `.workflows/paused-*.md` | No | Pause command |
| `.workflows/history/` | No | Completion |
| `.workflows/<feature>/plan<name>.md` | Yes | PLAN phase |
| `tasks/todo.md` | Yes | PLAN phase |
| `tasks/lessons.md` | Yes | Corrections |

---

## 14. Upgrading

```bash
npx claude-dev-workflows install        # Re-run in your project
```

The installer is idempotent. Updates skills, templates, rules, and checklists. Preserves `workflows.yml`, project-specific skills, state files, and tasks.

```bash
cat .claude/.workflows-version           # Check current version
```

---

## 15. Troubleshooting

| Problem | Solution |
|---------|----------|
| Skills don't appear | Check `.claude/skills/` has SKILL.md files |
| Git operations fail | Verify branch names in `workflows.yml` |
| PR creation fails | Run `gh auth status` |
| State corrupted | Delete `.workflows/current-state.md`, restart |
| Quality gate not running | Check `quality.self_review: true` in config |
| Wrong rules loaded | Check `project.language` in `workflows.yml` |

### Reset

```bash
rm .workflows/current-state.md .workflows/paused-*.md   # Reset state
npx claude-dev-workflows install                         # Full reinstall
```

### Inspect Skills

```bash
cat .claude/skills/new-feature/SKILL.md
cat .claude/skills/_orchestration/RULES.md
```
