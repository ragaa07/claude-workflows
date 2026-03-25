---
name: new-project
description: Initialize a new project with Claude Code configuration, detecting build systems, conventions, and generating CLAUDE.md and task scaffolding.
---

## Phase 0: INIT — Do This First

> **You MUST complete these steps before doing anything else.**

### Step 0.1 — Create State Directories

```bash
mkdir -p .workflows/specs .workflows/history
```

### Step 0.2 — Check for Existing Workflow

Read `.workflows/current-state.md`. If it exists, tell the user:
- "There's an active workflow: `<workflow>` at `<phase>`. Pause it, abandon it, or cancel this new one?"
- Wait for their choice before continuing.

### Step 0.3 — Create State File

Write `.workflows/current-state.md` with this exact content (replace `<feature>` with the user's input):

```markdown
# Workflow State

- **workflow**: new-project
- **feature**: <feature>
- **phase**: DETECT
- **started**: <current ISO-8601 timestamp>
- **updated**: <current ISO-8601 timestamp>
- **branch**:

## Phase History

| Phase | Status | Timestamp | Notes |
|-------|--------|-----------|-------|
| DETECT | ACTIVE | <timestamp> | Starting project detection |

## Completed Steps


## Artifacts


## Context

```

### Step 0.4 — Read Configuration

Read `.claude/workflows.yml` and note relevant config for this workflow.

---

## Phase Transition Rules

**At the END of every phase** (before starting the next one), you MUST:
1. Update `.workflows/current-state.md`:
   - Change the current phase's row from `ACTIVE` to `COMPLETED` with a note of what was done
   - Add the next phase as `ACTIVE`
   - Update the `phase` and `updated` header fields
   - Add checkboxes for steps completed under `## Completed Steps`
2. Save any artifacts:
   - Specs → `.workflows/specs/<feature>.spec.md`
   - Decisions → `.workflows/specs/<feature>.decisions.md`
   - Add links under `## Artifacts`
3. Add key decisions under `## Context` (for resume)

**When the workflow completes**: Move `.workflows/current-state.md` to `.workflows/history/<feature>-<date>.md`

---

# New Project Initialization

## Command

```
/workflow:new-project [--path <directory>] [--preset <android|web|rust|go|python>]
```

## Overview

Bootstraps a project for Claude Code by detecting its tech stack, conventions, and structure, then generating configuration files. Four phases: **DETECT -> CONFIGURE -> GENERATE -> SETUP**.

---

## Phase 1: DETECT

**Goal**: Automatically identify the project's tech stack, build system, and conventions.

### Step 1.1 — Scan Project Markers

Search the project root for build/config files to identify the stack:

| Marker File | Stack |
|---|---|
| `build.gradle.kts` / `build.gradle` | Android/Kotlin (Gradle) |
| `settings.gradle.kts` | Multi-module Gradle |
| `package.json` | Node.js / JavaScript / TypeScript |
| `Cargo.toml` | Rust |
| `go.mod` | Go |
| `pyproject.toml` / `setup.py` / `requirements.txt` | Python |
| `pom.xml` | Java (Maven) |
| `CMakeLists.txt` | C/C++ (CMake) |
| `Package.swift` | Swift |
| `Podfile` | iOS (CocoaPods) |
| `.csproj` / `.sln` | .NET / C# |

**Action**: Use `Glob` to search for each marker. Record ALL matches (projects can be polyglot).

### Step 1.2 — Detect Build System Details

Based on detected markers, extract:

- **Build command**: Read build files to find the compile/build command
- **Test command**: Find test runner configuration
- **Lint command**: Check for `.eslintrc*`, `ktlint`, `rustfmt.toml`, `ruff.toml`, etc.
- **Build variants/flavors**: For Android, parse `productFlavors` from `build.gradle.kts`
- **Package manager**: npm vs yarn vs pnpm (check lock files), pip vs poetry vs uv

### Step 1.3 — Scan Git History for Conventions

```bash
# Commit message format
git log --oneline -20

# Branch naming
git branch -a | head -20

# Check for CI
ls .github/workflows/ .gitlab-ci.yml Jenkinsfile .circleci/ bitrise.yml 2>/dev/null
```

Extract:
- **Commit format**: conventional commits (`feat:`, `fix:`), Jira references, free-form
- **Branch naming**: `feature/`, `alpha-feature/`, `feat/`, kebab-case, etc.
- **Main branch**: `main` or `master`
- **Development branch**: `develop`, `development`, `dev`, or none
- **CI system**: GitHub Actions, GitLab CI, Jenkins, Bitrise, CircleCI

### Step 1.4 — Detect Architecture Patterns

Use sub-agent to scan source directories for:
- **Architecture**: MVI, MVVM, MVC, Clean Architecture, feature-based modules
- **DI framework**: Hilt, Dagger, Koin, Spring, etc.
- **Key directories**: `src/`, `app/`, `core/`, `features/`, `lib/`
- **Module structure**: mono-module vs multi-module

### Decision Point: Incomplete Detection

If fewer than 3 attributes detected:
- Ask user: "I could not fully detect your project setup. Would you like to specify details manually?"
- If `--preset` was provided, use preset defaults as fallback

**Output of DETECT phase**: Internal detection report (not saved to file yet).

---

## Phase 2: CONFIGURE

**Goal**: Present findings to user and get confirmation before generating files.

### Step 2.1 — Present Detection Results

Display a summary:

```
Project Detection Results:
  Stack:           Android / Kotlin
  Build System:    Gradle 8.x (Kotlin DSL)
  Build Command:   ./gradlew compileForSaleDebugKotlin
  Test Command:    ./gradlew testForSaleDebugUnitTest
  Lint Command:    ./gradlew ktlintCheck
  CI System:       GitHub Actions
  Commit Format:   Conventional (feat:, fix:, chore:)
  Branch Naming:   alpha-feature/<name>
  Main Branch:     master
  Dev Branch:      Development
  Architecture:    MVVM + Clean Architecture
  DI:              Hilt
  Modules:         Multi-module (app, core, features)
```

### Step 2.2 — Ask for Confirmation

Ask: "Does this look correct? Reply with corrections or 'yes' to proceed."

Handle corrections by updating the detection report.

### Step 2.3 — Generate workflows.yml

Create `.claude/workflows.yml`:

```yaml
# Project Workflow Configuration
# Generated by /workflow:new-project on <date>

project:
  name: "<project-name>"
  stack: "<detected-stack>"
  language: "<primary-language>"

git:
  branches:
    main: "<main>"
    development: "<dev>"
    feature: "feature/{name}"
    bugfix: "bugfix/{name}"
    hotfix: "hotfix/{name}"
    release: "release/v{version}"

  commits:
    format: "<conventional|angular|simple>"
    types: [feat, fix, refactor, test, docs, chore, style, perf]

  pr:
    base_branch: "<dev>"
```

---

## Phase 3: GENERATE

**Goal**: Create CLAUDE.md with project-specific instructions.

### Step 3.1 — Generate CLAUDE.md

Write `CLAUDE.md` in the project root with this template:

```markdown
# <Project Name> — Claude Code Instructions

## Build & Run

- Build: `<build-command>`
- Test: `<test-command>`
- Lint: `<lint-command>`
<if variants>
- Build variants: <list variants with explanation>
</if>

## Architecture

- Pattern: <architecture pattern>
- DI: <di framework>
- Module structure: <description>

### Key Directories

- `<path>` — <description>
- `<path>` — <description>
(list 5-10 most important directories)

## Code Conventions

- Commit format: `<format>` (e.g., `feat: add login screen`)
- Branch naming: `<pattern>` (e.g., `alpha-feature/Login_Flow`)
- PR base branch: `<dev-branch>`

## Important Notes

(Add any project-specific gotchas detected during analysis)
```

### Step 3.2 — Validate CLAUDE.md

Read the generated file back and verify:
- Build commands are syntactically valid
- Directory paths exist
- No placeholder text remains

### Error Handling

If CLAUDE.md already exists:
- Ask user: "CLAUDE.md already exists. Overwrite, merge, or skip?"
- **Overwrite**: Replace entirely
- **Merge**: Read existing, preserve custom sections, update detected sections
- **Skip**: Leave as-is

---

## Phase 4: SETUP

**Goal**: Create supporting directory structure and task scaffolding.

### Step 4.1 — Create tasks/ Directory

```bash
mkdir -p tasks
```

Create `tasks/todo.md`:

```markdown
# Todo

## In Progress

## Backlog
```

Create `tasks/lessons.md`:

```markdown
# Lessons Learned

<!-- Corrections and patterns discovered during development -->
```

### Step 4.2 — Create .claude/ Structure

```bash
mkdir -p .claude/skills
```

Ensure `.claude/workflows.yml` exists (created in Phase 2).

### Step 4.3 — Update .gitignore

Check if `.gitignore` exists. If so, ensure these entries are present (add if missing):

```
# Claude Code
tasks/todo.md
tasks/lessons.md
```

Do NOT add `.claude/` or `CLAUDE.md` to gitignore — these should be committed.

### Step 4.4 — Final Summary

Print:

```
Project initialized successfully.

Created:
  - CLAUDE.md (project instructions)
  - .claude/workflows.yml (workflow config)
  - tasks/todo.md (task tracking)
  - tasks/lessons.md (lessons learned)
  - .claude/skills/ (skill directory)

Next steps:
  1. Review CLAUDE.md and add any project-specific notes
  2. Commit the new files
  3. Run /workflow:new-feature <name> to start your first feature
```

---

## Error Handling

| Error | Resolution |
|---|---|
| Not a git repository | Ask user to run `git init` first, or offer to run it |
| No build files detected | Fall back to manual configuration via `--preset` |
| CLAUDE.md already exists | Ask: overwrite, merge, or skip |
| Permission denied on directory creation | Report error, suggest running with appropriate permissions |
| workflows.yml already exists | Ask: overwrite or skip |
