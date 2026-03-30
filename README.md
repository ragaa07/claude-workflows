# claude-workflows

[![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)](VERSION)
[![npm](https://img.shields.io/npm/v/claude-dev-workflows)](https://www.npmjs.com/package/claude-dev-workflows)
[![GitHub Pages](https://img.shields.io/badge/docs-live-brightgreen)](https://ragaa07.github.io/claude-workflows/)

**Structured development workflows for Claude Code — 20 skills, 16 orchestration rules, quality gates, multi-session state, and team extensibility.**

[Live Docs & Showcase](https://ragaa07.github.io/claude-workflows/)

---

## Installation

### Option 1: Claude Code Plugin (Recommended)

Install directly as a Claude Code plugin:

```
/plugin install ragaa07/claude-workflows
```

This gives you all 20 workflow skills as namespaced commands (e.g., `/claude-workflows:new-feature`), lifecycle hooks, and quality gates — no setup needed.

### Option 2: NPM CLI (Project-Level)

For deeper project integration with language rules, team configs, and workflows.yml:

```bash
# Generic project
npx claude-dev-workflows init

# With language type
npx claude-dev-workflows init --type android
npx claude-dev-workflows init --type react
npx claude-dev-workflows init --type python
npx claude-dev-workflows init --type swift
npx claude-dev-workflows init --type go

# With team skills
npx claude-dev-workflows init --type android --team android
npx claude-dev-workflows init --type react --team frontend
npx claude-dev-workflows init --type python --team backend
npx claude-dev-workflows init --type swift --team ios

# With safety guards
npx claude-dev-workflows init --type android --team android --with-guards
```

### Option 3: Git Clone (Manual)

```bash
git clone https://github.com/ragaa07/claude-workflows.git /tmp/claude-workflows
cd /path/to/your/project
node /tmp/claude-workflows/bin/cli.js init --type android --team android
```

---

## What Gets Installed

| Component | Path | Source |
|-----------|------|--------|
| Core skills (20) | `.claude/skills/` | Always installed |
| Orchestration rules (16) | `.claude/skills/_orchestration/` | Always installed |
| Language rules | `.claude/rules/` | Based on `--type` |
| Review checklists | `.claude/reviews/` | Based on `--type` + `--team` |
| Templates | `.claude/templates/` | Always installed |
| Config | `.claude/workflows.yml` | Created from defaults |
| State directory | `.workflows/` | Always created |
| Safety guards | `.claude/guards.yml` | Only with `--with-guards` |

---

## Workflows

### Build

| Command | What It Does |
|---------|-------------|
| `/new-feature` | Gathers requirements, writes spec, brainstorms approaches, creates phased plan, implements commit-by-commit, tests, quality gate, PR |
| `/extend-feature` | Analyzes existing feature, finds extension points, adds capabilities without modifying signatures or breaking tests |
| `/new-project` | Detects tech stack from build files, generates workflows.yml and CLAUDE.md, scaffolds task tracking |

### Fix

| Command | What It Does |
|---------|-------------|
| `/hotfix` | Diagnoses crash from stack trace/logs, applies minimal fix (1-5 lines), writes mandatory regression test, PRs to production, cherry-pick plan |
| `/ci-fix` | Fetches CI failure logs, classifies error type, applies targeted fix, pushes, monitors retry (up to 3 cycles) |

### Improve

| Command | What It Does |
|---------|-------------|
| `/refactor` | Maps dependency graph, documents behavioral contract, plans incremental migration, every step compiles+tests, parallel deprecation |
| `/migrate` | Supports dependency/API/architecture/database migrations with incremental steps, rollback per step, strategy selection |

### Ship

| Command | What It Does |
|---------|-------------|
| `/release` | Generates changelog from git history, bumps version in build files, creates release branch, PR to production, tag commands |
| `/review` | Fetches PR diff, categorizes by architecture layer, checks against severity-rated checklists, generates inline comments via GitHub API |

### Think

| Command | What It Does |
|---------|-------------|
| `/brainstorm` | Interactive facilitation with 5 techniques (Trade-off Matrix, Six Hats, SCAMPER, Reverse Brainstorm, Constraint Mapping). You decide, Claude facilitates. |
| `/test` | Maps every code branch, plans categorized tests [HAPPY][ERROR][EDGE][STATE], writes with Given/When/Then, coverage reporting |

### Tools

| Command | What It Does |
|---------|-------------|
| `/git-flow` | Branch/commit/PR/merge using your configured patterns and policies |
| `/template` | Save completed specs+plans as reusable templates. Reuse to skip GATHER and SPEC phases. |
| `/compose-skill` | Interactively build custom workflow skills with proper structure and orchestration integration |
| `/metrics` | Telemetry-driven dashboard: completion rates, durations, bottleneck phases, trend analysis |
| `/learn` | Capture and reuse successful patterns. Patterns with 2+ reuses surface in future brainstorms. |
| `/guards` | Scan for hardcoded secrets, protected path violations, and dangerous operations |
| `/start` | Entry point: shows menu, gathers arguments, launches selected workflow directly |
| `/resume` | Resume paused/interrupted workflows with branch validation, checkpoint recovery, staleness detection |

---

## Key Features

### Multi-Session State Persistence

Three-layer context that survives across sessions:

1. **State file** (YAML frontmatter) — current phase, branch, retry count, phase history
2. **Phase outputs + CONTEXT.md** — full details from every phase + compressed decision snapshots
3. **Git + Knowledge graph** — commits, branches, cross-workflow decision learning

### Quality Gates

- 55+ items in general checklist + language-specific + team checklists
- Severity: Critical (blocks merge), High (should fix), Medium, Low
- Focused gate: only checks items relevant to changed files
- Auto-loaded before every PR creation

### Workflow Chaining

Configure automatic workflow succession:
```yaml
chains:
  new-feature: "review --self"     # Auto-review after feature
  hotfix: "ci-fix --pr latest"     # Check CI after hotfix
```

### Adaptive Depth

Auto-detects complexity: trivial changes (1-2 files) skip SPEC and BRAINSTORM. Complex changes (10+ files) force deep analysis. Override with `--depth full`.

### Knowledge Graph

Decisions extracted to `knowledge.jsonl` after workflows. Future brainstorms surface: "Similar past decision: X used Y for Z — succeeded."

### Context Snapshots

CONTEXT.md captures key decisions after every phase. Survives context window compression during long workflows.

---

## Configuration

All config in `.claude/workflows.yml`. See [`config/defaults.yml`](config/defaults.yml) for full reference.

```yaml
project:
  name: "My Project"
  type: "android"           # android | react | python | swift | go | generic
  language: "kotlin"

git:
  branches:
    main: "main"
    development: "develop"
    feature: "feature/{name}"
  commits:
    format: "conventional"  # conventional | angular | simple

workflows:
  new-feature:
    require_spec: true
    require_brainstorm: true
    adaptive: true          # Auto-skip phases for trivial changes

chains:
  new-feature: "review --self"

skills:
  aliases:
    build: "new-feature"
    fix: "hotfix"
    ship: "release"
```

---

## Teams

4 built-in teams + template for custom teams:

| Team | `--team` | `--type` | Stack |
|------|----------|----------|-------|
| Android | `android` | `android` | Kotlin/Compose, MVVM, Hilt |
| iOS | `ios` | `swift` | Swift/SwiftUI |
| Frontend | `frontend` | `react` | React/TypeScript |
| Backend | `backend` | `python` | Python |

Create custom teams:
```bash
cp -r teams/_template teams/my-team
# Edit manifest.yml, skills/, rules/, reviews/
```

---

## Upgrading

```bash
npx claude-dev-workflows@latest upgrade
npx claude-dev-workflows@latest upgrade --type android --team android
```

Preserves: `workflows.yml`, project-specific skills, state files.
Replaces: core skills, templates, rules, checklists.

---

## Plugin Structure

This repo is both an npm package and a Claude Code plugin:

```
claude-workflows/
  .claude-plugin/plugin.json   # Plugin manifest
  skills/ -> core/skills/      # 20 workflow skills (symlink)
  hooks/hooks.json             # Lifecycle hooks
  settings.json                # Default permissions
  bin/cli.js                   # NPM CLI (init, upgrade)
  core/                        # Skills, rules, reviews, templates
  config/defaults.yml          # Configuration template
  teams/                       # Team configurations
  docs/index.html              # Showcase page (GitHub Pages)
```

---

## Contributing

- One workflow or skill change per PR
- Follow conventional commit format
- Test across multiple workflow types
- Target the `main` branch

---

## License

MIT
