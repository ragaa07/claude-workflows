---
name: start
description: Entry point — shows available workflows, gathers arguments, then executes the selected workflow directly.
rules: [0]
---

# Start a Workflow

## Step 1: Check Active Workflows

Run: `mkdir -p .workflows/history`

Read `.workflows/current-state.md`. If it exists:

```
Active workflow detected:
   <workflow> — <feature> (at <phase>, updated <date>)

Options:
  1. Resume this workflow
  2. Pause it and start something new
  3. Abandon it and start fresh
```

- **Resume** → Read and execute `${CLAUDE_PLUGIN_ROOT}/skills/resume/SKILL.md`. Stop here.
- **Pause** → Rename to `.workflows/paused-<feature>.md`, continue to Step 2.
- **Abandon** → Move to `.workflows/history/<feature>-<date>.md`, continue to Step 2.

Also list any `.workflows/paused-*.md` files as paused workflows the user can resume.

## Step 2: Show Menu

```
What would you like to do?

── Build ──────────────────────────────
  1. New Feature      — spec, plan, implement, test, PR
  2. Extend Feature   — add to an existing feature
  3. New Project      — scaffold a new project

── Fix ────────────────────────────────
  4. Hotfix           — urgent production fix
  5. CI Fix           — fix failing CI/CD

── Improve ────────────────────────────
  6. Refactor         — restructure code safely
  7. Migrate          — upgrade deps, APIs, patterns

── Ship ───────────────────────────────
  8. Release          — version, changelog, tag
  9. Review           — PR code review

── Think ──────────────────────────────
  10. Brainstorm      — explore ideas and approaches
  11. Test            — generate or improve tests

Pick a number (1-11):
```

## Step 3: Gather Arguments

Ask for the required input based on selection:

| Selection | Required input |
|-----------|---------------|
| New Feature | Feature name. Optional: ticket ID, design URL, spec path |
| Extend Feature | Which feature + what to add |
| New Project | Project name/path + stack preferences |
| Hotfix | Description of the issue |
| CI Fix | Which CI job or PR |
| Refactor | Target + goal |
| Migrate | What to migrate + from/to |
| Release | Version number |
| Review | PR number or branch |
| Brainstorm | Topic to explore |
| Test | Target to test |

## Step 4: Execute

Map the selection to a skill directory:

| # | Skill path |
|---|-----------|
| 1 | `${CLAUDE_PLUGIN_ROOT}/skills/new-feature/SKILL.md` |
| 2 | `${CLAUDE_PLUGIN_ROOT}/skills/extend-feature/SKILL.md` |
| 3 | `${CLAUDE_PLUGIN_ROOT}/skills/new-project/SKILL.md` |
| 4 | `${CLAUDE_PLUGIN_ROOT}/skills/hotfix/SKILL.md` |
| 5 | `${CLAUDE_PLUGIN_ROOT}/skills/ci-fix/SKILL.md` |
| 6 | `${CLAUDE_PLUGIN_ROOT}/skills/refactor/SKILL.md` |
| 7 | `${CLAUDE_PLUGIN_ROOT}/skills/migrate/SKILL.md` |
| 8 | `${CLAUDE_PLUGIN_ROOT}/skills/release/SKILL.md` |
| 9 | `${CLAUDE_PLUGIN_ROOT}/skills/review/SKILL.md` |
| 10 | `${CLAUDE_PLUGIN_ROOT}/skills/brainstorm/SKILL.md` |
| 11 | `${CLAUDE_PLUGIN_ROOT}/skills/test/SKILL.md` |

Now read and execute the selected skill's `SKILL.md` starting from Phase 1, passing the gathered arguments as context. State initialization is handled by orchestration Rule 0 — do not create state files here.
