---
name: start
description: Entry point for all workflows. Shows available workflows, lets you pick one, and launches it. Also checks for active or paused workflows to resume.
---

# Start Workflow

## Command

```
/start
```

## Process

### Step 1: Check for Active Workflows

Before offering new workflows, check existing state:

1. **Active workflow**: Read `.workflows/current-state.md`
   - If exists, report it and ask:
     ```
     ⚡ Active workflow detected:
        <workflow> — <feature> (at <phase>, updated <date>)

     Options:
       1. Resume this workflow
       2. Pause it and start something new
       3. Abandon it and start fresh
     ```
   - If user chooses 1: invoke `/resume`
   - If user chooses 2: rename to `.workflows/paused-<feature>.md`, continue to Step 2
   - If user chooses 3: move to `.workflows/history/`, continue to Step 2

2. **Paused workflows**: List `.workflows/paused-*.md`
   - If any exist, mention them:
     ```
     📋 Paused workflows:
       - <name-1> (at <phase>, paused <date>)
       - <name-2> (at <phase>, paused <date>)

     You can resume one with /resume, or start a new workflow below.
     ```

### Step 2: Present Available Workflows

Show the workflow menu:

```
🚀 What would you like to do?

── Build ──────────────────────────────
  1. New Feature      — Full workflow: spec → brainstorm → plan → implement → test → PR
  2. Extend Feature   — Add capabilities to an existing feature
  3. New Project      — Bootstrap a new project with config and scaffolding

── Fix ────────────────────────────────
  4. Hotfix           — Emergency production fix
  5. CI Fix           — Fix failing CI/CD pipeline

── Improve ────────────────────────────
  6. Refactor         — Safely restructure code with contracts and rollback
  7. Migrate          — Migrate dependencies, APIs, or patterns

── Ship ───────────────────────────────
  8. Release          — Version bump, changelog, release branch, tag
  9. Review           — Systematic PR code review

── Think ──────────────────────────────
  10. Brainstorm      — Explore approaches with structured techniques
  11. Test            — Generate tests with coverage analysis

Pick a number (1-11):
```

### Step 3: Launch Selected Workflow

Based on user selection, invoke the corresponding skill:

| Selection | Skill |
|-----------|-------|
| 1 | `/new-feature` |
| 2 | `/extend-feature` |
| 3 | `/new-project` |
| 4 | `/hotfix` |
| 5 | `/ci-fix` |
| 6 | `/refactor` |
| 7 | `/migrate` |
| 8 | `/release` |
| 9 | `/review` |
| 10 | `/brainstorm` |
| 11 | `/test` |

After the user picks, ask for the required arguments (feature name, description, etc.) and then invoke the skill.

### Step 4: Pass Arguments

Each workflow needs different arguments. Ask the user based on their selection:

**New Feature**: "What's the feature name?" + optional: Jira ticket, Figma URL, existing spec
**Extend Feature**: "Which existing feature?" + "What to add?"
**Hotfix**: "Describe the issue" + optional: Crashlytics ID, log path
**Refactor**: "What to refactor?" + "What's the goal?"
**Migrate**: "What to migrate?" + "From what to what?"
**Release**: "What version?" (suggest next based on git tags)
**Review**: "Which PR or branch?"
**CI Fix**: "Which CI job is failing?"
**Brainstorm**: "What topic?"
**Test**: "What to test?"
**New Project**: "Project path?" + optional: preset (android, web, python, etc.)
