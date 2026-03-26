# Claude Workflows

Structured workflow system for feature development, refactoring, hotfixes, and releases.

## Session Start

1. Check `.workflows/current-state.md` — if exists, report active workflow and offer to resume
2. Check `.workflows/paused-*.md` — mention any paused workflows
3. Read `tasks/todo.md` — check for in-progress items
4. Read `tasks/lessons.md` — apply relevant lessons

## Commands

| Command | Description |
|---------|-------------|
| `/start` | **Entry point** — shows all workflows, manages state, launches selected one |
| `/resume` | Resume a paused or interrupted workflow |

## Available Workflows

| Skill | Description |
|-------|-------------|
| `/new-feature` | Full feature: spec, brainstorm, plan, implement, test, PR |
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
| Orchestration rules | `.claude/skills/_orchestration/RULES.md` |
| Language rules | `.claude/rules/` |
| Review checklists | `.claude/reviews/` |
| Active workflow state | `.workflows/current-state.md` |
| Paused workflows | `.workflows/paused-<name>.md` |
| Phase output documents | `.workflows/<feature>/01-phase.md, 02-phase.md, ...` |
| Workflow history | `.workflows/history/` |

## Orchestration

When executing any workflow, read and follow `.claude/skills/_orchestration/RULES.md`. This covers:
- Phase output documents (Rule 1)
- State updates (Rule 2)
- Phase skipping (Rule 3)
- Quality gate with rules and reviews (Rule 4)
- Build/test command detection (Rule 5)
- Workflow chaining (Rule 6)
- Completion, pausing, error recovery (Rules 7-9)

## Lessons & Corrections

After ANY correction from the user:
1. Append to `tasks/lessons.md` with what went wrong and the correct pattern
2. Review lessons at session start
