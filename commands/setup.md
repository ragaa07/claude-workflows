---
description: Set up claude-workflows for this project — creates workflows.yml, copies language rules and review checklists, configures git flow.
---

# Project Setup

Set up claude-workflows for this project. This creates project-level configuration that the plugin's skills need.

## Step 1: Detect Project

Scan for build system markers:

| Marker | Type | Language |
|--------|------|----------|
| `build.gradle.kts` / `build.gradle` | android | kotlin |
| `package.json` with react | react | typescript |
| `package.json` without react | generic | typescript |
| `pyproject.toml` / `setup.py` | python | python |
| `Package.swift` | swift | swift |
| `go.mod` | go | go |
| `Cargo.toml` | generic | rust |

Present detection results. Ask: "Is this correct? (type/language)"

## Step 2: Create Config

Create `.claude/workflows.yml` with detected values. Use the template from the plugin's `config/defaults.yml` — find it relative to this skill file at `../../config/defaults.yml`. Replace `type`, `language`, and `team` with detected/provided values.

## Step 3: Copy Rules

Based on detected language, copy the appropriate files from the plugin's `core/rules/` to `.claude/rules/`:

| Language | Rule Files |
|----------|-----------|
| kotlin | `kotlin.md`, `compose.md` |
| typescript | `typescript.md`, `react.md` |
| python | `python.md` |
| swift | `swift.md` |
| go | `go.md` |

## Step 4: Copy Review Checklists

Always copy `general-checklist.md` from `core/reviews/`. Then copy language-specific:

| Language | Checklists |
|----------|-----------|
| kotlin | `kotlin-checklist.md`, `compose-checklist.md` |
| typescript | `typescript-checklist.md`, `react-checklist.md` |
| python | `python-checklist.md` |
| swift | `swift-checklist.md` |
| go | `go-checklist.md` |

## Step 5: Create Directories

```bash
mkdir -p .workflows/history .workflows/learned tasks
```

Create `tasks/todo.md` and `tasks/lessons.md` if they don't exist.

## Step 6: Summary

Print what was created and suggest: "Run `/start` to begin your first workflow."
