# Claude Workflows

Structured workflow system for feature development, refactoring, hotfixes, and releases.

## Session Start

1. Read `tasks/lessons.md` -- apply relevant lessons to current work
2. Read `tasks/todo.md` -- check for in-progress items
3. Check `.workflows/current-state.md` -- report any active workflow to the user
4. Check `.workflows/paused-*.md` -- mention any paused workflows

## Configuration

All workflow config lives in `.claude/workflows.yml`. Key sections:

- `git.branches` -- branch naming patterns
- `git.commits.format` -- commit message style (conventional/angular/simple)
- `git.pr` -- PR creation settings (base branch, template, reviewers)
- `git.protected` -- branches that require PRs (warn on direct commit)
- `workflows.<type>` -- per-workflow settings (require_spec, require_tests, require_brainstorm)
- `skills.aliases` -- command shortcuts

## File Locations

| Purpose | Path |
|---------|------|
| Workflow config | `.claude/workflows.yml` |
| Core skills | `.claude/skills/_core/` |
| Team skills | `.claude/skills/_team/` |
| Project skills | `.claude/skills/<name>/` (overrides) |
| Language rules | `.claude/rules/` |
| Review checklists | `.claude/reviews/` |
| Workflow state | `.workflows/current-state.md` |
| Paused workflows | `.workflows/paused-<name>.md` |
| History | `.workflows/history/` |
| Specs & decisions | `.workflows/specs/` |
| Task tracking | `tasks/todo.md` |
| Lessons learned | `tasks/lessons.md` |

## State Machine

Workflows follow: `IDLE -> SPEC -> BRAINSTORM -> PLAN -> BRANCH -> IMPLEMENT -> TEST -> PR -> DONE`

Phases may be skipped based on workflow config (e.g., `require_brainstorm: false`).

### Phase Transition Rules

- Update `.workflows/current-state.md` at EVERY phase transition
- Record phase status (ACTIVE, COMPLETED, SKIPPED) with timestamp
- Never skip phases unless config explicitly allows it
- If something goes wrong, STOP and update state before re-planning

## Lessons & Corrections

After ANY correction from the user or unexpected failure:
1. Append to `tasks/lessons.md` with what went wrong, the correct pattern, and a prevention rule
2. Review lessons at session start to avoid repeating mistakes

## Sub-Agent Guidelines

- Maximum 3 concurrent sub-agents
- One focused task per sub-agent (research, analysis, exploration)
- Main thread writes all implementation code -- sub-agents only read and analyze
- Use sub-agents to keep the main context window clean for implementation work

## Available Commands

| Command | Description |
|---------|-------------|
| `/workflow:new-feature` | Full feature workflow (spec -> brainstorm -> plan -> implement -> test -> PR) |
| `/workflow:extend-feature` | Extend existing feature |
| `/workflow:hotfix` | Quick fix branched from production |
| `/workflow:refactor` | Refactoring workflow |
| `/workflow:release` | Release preparation |
| `/workflow:review` | Code review workflow |
| `/workflow:brainstorm` | Standalone brainstorming session |
| `/workflow:status` | Show active workflow state |
| `/workflow:resume` | Resume a paused workflow |
| `/workflow:pause` | Pause current workflow |
| `/workflow:abandon` | Discard current workflow |
| `/workflow:history` | List completed workflows |

Aliases are defined in `.claude/workflows.yml` under `skills.aliases`.

Team-specific skills (in `.claude/skills/_team/`) are also available via `/workflow:<skill-name>`.
Skill resolution order: project overrides > team skills > core skills.
