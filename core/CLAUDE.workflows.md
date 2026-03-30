# Claude Workflows

Structured workflow system. On session start, check `.workflows/current-state.md` for active workflows and `.workflows/paused-*.md` for paused ones.

## Commands

| Command | What it does |
|---------|--------------|
| `/start` | Entry point — lists workflows, manages state, launches selection |
| `/resume` | Resume a paused or interrupted workflow |
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
| `/git-flow` | Git branching and merge workflow |
| `/learn` | Learn from codebase or documentation |
| `/dry-run` | Simulate a workflow without making changes |
| `/metrics` | Collect and report workflow metrics |
| `/guards` | Run safety and quality guard checks |

## File Locations

| Purpose | Path |
|---------|------|
| Workflow config | `.claude/workflows.yml` |
| Skills | `.claude/skills/<name>/SKILL.md` |
| Orchestration rules | `.claude/skills/_orchestration/RULES.md` |
| Language rules | `.claude/rules/` |
| Review checklists | `.claude/reviews/` |
| Active state | `.workflows/current-state.md` |
| Paused workflows | `.workflows/paused-<name>.md` |
| Phase outputs | `.workflows/<feature>/01-phase.md, 02-phase.md, ...` |

## Orchestration

Read and follow `.claude/skills/_orchestration/RULES.md` during any workflow:

- **Rule 0** State Initialization | **Rule 1** Phase Output Protocol
- **Rule 2** Skipping Phases | **Rule 3** Quality Gate
- **Rule 4** Build/Test Detection | **Rule 5** Completion
- **Rule 6** Pausing | **Rule 7** Error Recovery & REPLAN
- **Rule 8** Common Errors | **Rule 9** Skill Composition
- **Rule 10** Phase Statuses | **Rule 11** Mid-Phase Checkpoints
- **Rule 12** Telemetry | **Rule 13** Focused Quality Gate | **Rule 14** Dry Run
