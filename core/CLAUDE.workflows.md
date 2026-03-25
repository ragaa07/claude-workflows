# Claude Workflows

Structured workflow system for feature development, refactoring, hotfixes, and releases.

## Session Start

1. Check `.workflows/current-state.md` -- if exists, report the active workflow and offer to resume
2. Check `.workflows/paused-*.md` -- mention any paused workflows
3. Read `tasks/todo.md` -- check for in-progress items
4. Read `tasks/lessons.md` -- apply relevant lessons to current work

## Quick Start

| Skill | Description |
|-------|-------------|
| `/start` | **Entry point** — shows all workflows, manages state, launches the selected one |
| `/resume` | Resume a paused or interrupted workflow with full context from phase outputs |

## Available Workflows

All skills are auto-discovered from `.claude/skills/`:

| Skill | Description |
|-------|-------------|
| `/new-feature` | Full feature workflow: spec, brainstorm, plan, implement, test, PR |
| `/extend-feature` | Extend existing feature with backward compatibility |
| `/hotfix` | Emergency production fix |
| `/refactor` | Safely restructure code |
| `/release` | Version bump, changelog, tag |
| `/review` | Systematic PR code review |
| `/brainstorm` | Standalone brainstorming session |
| `/test` | Generate tests with coverage analysis |
| `/ci-fix` | Fix failing CI/CD pipeline |
| `/migrate` | Migrate dependencies, APIs, patterns |
| `/new-project` | Bootstrap a new project |

## File Locations

| Purpose | Path |
|---------|------|
| Workflow config | `.claude/workflows.yml` |
| Skills | `.claude/skills/<name>/SKILL.md` |
| Language rules | `.claude/rules/` |
| Review checklists | `.claude/reviews/` |
| Active workflow state | `.workflows/current-state.md` |
| Paused workflows | `.workflows/paused-<name>.md` |
| Phase output documents | `.workflows/<feature>/01-phase.md, 02-phase.md, ...` |
| Workflow history | `.workflows/history/` |
| Task tracking | `tasks/todo.md` |
| Lessons learned | `tasks/lessons.md` |

## Configuration

All workflow config lives in `.claude/workflows.yml`:

- `git.branches` -- branch naming patterns
- `git.commits.format` -- commit message style
- `git.pr` -- PR creation settings
- `workflows.<type>.require_brainstorm` -- skip brainstorm if false
- `workflows.<type>.require_tests` -- skip tests if false
- `workflows.<type>.require_spec` -- skip spec if false

## Lessons & Corrections

After ANY correction from the user:
1. Append to `tasks/lessons.md` with what went wrong and the correct pattern
2. Review lessons at session start
