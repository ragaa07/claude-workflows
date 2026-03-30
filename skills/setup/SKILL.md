---
name: setup
description: "Initialize a project for claude-workflows — detects stack, creates .workflows/ directory structure, generates config, and updates .gitignore."
---

# Project Setup

```
/claude-workflows:setup [--with-guards]
```

**Purpose**: One-time project initialization. Replaces the old `npx claude-dev-workflows init` CLI. Run this after installing the plugin to configure your project.

---

## Step 1: Detect Project

Scan the project root for stack markers:

| Marker file | Detected type | Language |
|-------------|--------------|----------|
| `build.gradle`, `build.gradle.kts` | android | kotlin |
| `package.json` with react dependency | react | typescript |
| `package.json` without react | generic | typescript |
| `pyproject.toml`, `setup.py`, `requirements.txt` | python | python |
| `Package.swift`, `*.xcodeproj` | swift | swift |
| `go.mod` | go | go |
| `Cargo.toml` | generic | rust |
| None of the above | generic | — |

Compare detected type with `${user_config.project_type}`. If they differ, inform the user:
> "Detected project type: `<detected>`, but plugin is configured as `${user_config.project_type}`. Using plugin config. Run `claude plugin configure claude-workflows` to change."

## Step 2: Create Directory Structure

```bash
mkdir -p .workflows/specs .workflows/history .workflows/learned
```

## Step 3: Generate Config

Read `${CLAUDE_PLUGIN_ROOT}/config/defaults.yml` as the base template.

Write `.workflows/config.yml` with these substitutions:
- `project.type` → `${user_config.project_type}` (or detected type)
- `project.team` → `${user_config.team}`
- `git.branches.main` → `${user_config.git_main_branch}` (default: `main`)
- `git.branches.development` → `${user_config.git_dev_branch}` (default: `develop`)
- `git.commits.format` → `${user_config.commit_format}` (default: `conventional`)

The user can further customize `.workflows/config.yml` after generation.

## Step 4: Update .gitignore

Add these entries to `.gitignore` if not already present:

```
# claude-workflows state
.workflows/current-state.md
.workflows/paused-*.md
.workflows/history/
.workflows/learned/
.workflows/telemetry.jsonl
.workflows/knowledge.jsonl
```

## Step 5: Safety Guards (Optional)

If `--with-guards` flag is present:
1. Read `${CLAUDE_PLUGIN_ROOT}/templates/guards.yml.tmpl`
2. Write to `.workflows/guards.yml`
3. Inform user: "Safety guards installed at `.workflows/guards.yml`. Edit to customize."

## Step 6: Migration Check

Check for old v2.x installation artifacts:
- If `.claude/workflows.yml` exists → inform user: "Found old v2.x config. Migrating settings to `.workflows/config.yml`." Read old config values and merge into the new config.
- If `.claude/.workflows-version` exists → inform user: "Old v2.x installation detected. The plugin replaces the npm CLI — you can remove `.claude/skills/`, `.claude/rules/`, `.claude/reviews/`, `.claude/templates/`, `.claude/.workflows-version`, and `.claude/.core-skills` if they were installed by claude-workflows."

## Step 7: Report

```
✓ Project setup complete!

  Type:     <project_type>
  Team:     <team>
  Config:   .workflows/config.yml
  State:    .workflows/

  Next: Run /claude-workflows:start to begin a workflow.
```
