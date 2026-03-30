---
name: new-project
description: Initialize a new project with Claude Code configuration, detecting build systems, conventions, and generating CLAUDE.md and task scaffolding.
rules: [0, 1, 5, 6, 10, 12, 17]
---

# New Project Initialization

```
/new-project [--path <directory>] [--preset <android|web|rust|go|python>]
```

Four phases: **DETECT -> CONFIGURE -> GENERATE -> SETUP**

**Note**: This skill supersedes `/claude-workflows:setup` — it performs full project detection plus setup. You do NOT need to run `/setup` separately if you use `/new-project`.

## Step 0: Initialize Workflow (DO THIS FIRST)

Create `.workflows/<project-name>/` directory and `.workflows/current-state.md` following the execution protocol — YAML frontmatter with workflow name, feature, first phase ACTIVE, all phases list, timestamps, replan_count=0. Add `## Phase History` table and `## Context` section. **Verify the state file exists before Phase 1.**

**After EVERY phase**: write output file + update `.workflows/current-state.md` (advance phase, mark COMPLETED, add ACTIVE row). Print progress. **NEVER skip phases.**

---

## Phase 1: DETECT

Identify project tech stack, build system, and conventions.

**Steps 1.1, 1.3, 1.4 are independent — execute in parallel.** Step 1.2 depends on 1.1.

### 1.1 — Scan Project Markers

Use `Glob` for each marker. Record ALL matches (projects can be polyglot).

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

### 1.2 — Extract Build Details

From detected markers: build/test/lint commands, build variants (e.g., Android `productFlavors`), package manager via lock files.

### 1.3 — Scan Git Conventions

Run `git log --oneline -20`, `git branch -a | head -20`, check for CI config files. Extract: commit format, branch naming, main/dev branches, CI system.

### 1.4 — Detect Architecture

Search per category: architecture pattern (MVVM, Clean, etc.), DI framework, key directories, module structure.

If fewer than 3 attributes detected, ask user for manual input. Use `--preset` as fallback.

**>> Phase complete** — write output to `.workflows/<project-name>/01-detect.md`

---

## Phase 2: CONFIGURE

### 2.1 — Present & Confirm

Display detection summary (stack, commands, CI, conventions, architecture). Ask: "Does this look correct? Reply with corrections or 'yes' to proceed."

### 2.2 — Generate workflows.yml

Create `.workflows/config.yml` from `<plugin-root>/config/defaults.yml` with: `project` (name, type, language), `git.branches` (main, development, feature/bugfix/hotfix/release patterns), `git.commits` (format, types), `git.pr` (base_branch). Populate from detected values.

**>> Phase complete** — write output to `.workflows/<project-name>/02-configure.md`

---

## Phase 3: GENERATE

### 3.1 — Generate CLAUDE.md

Write `CLAUDE.md` in project root with sections: **Build & Run** (commands), **Architecture** (pattern, DI, modules, key directories), **Code Conventions** (commits, branches, PR base), **Important Notes** (project gotchas). Keep it concise -- one-liners per command, 5-10 key directories.

### 3.2 — Validate

Read back generated file. Verify commands are valid, paths exist, no placeholders remain.

If CLAUDE.md exists, ask: **overwrite**, **merge** (preserve custom, update detected), or **skip**.

**>> Phase complete** — write output to `.workflows/<project-name>/03-generate.md`

---

## Phase 4: SETUP

### 4.1 — Create Scaffolding

```bash
mkdir -p tasks .workflows
```

Create `tasks/todo.md` (with `# Todo`, `## In Progress`, `## Backlog` sections).
Create `tasks/lessons.md` (with `# Lessons Learned` header).

**Do NOT add `tasks/` to `.gitignore`** — task files should be tracked.

### 4.2 — Final Summary

Print created files (CLAUDE.md, .workflows/config.yml, tasks/todo.md, tasks/lessons.md) and next steps: review CLAUDE.md, commit files, run `/claude-workflows:new-feature`.

**>> Phase complete** — write output to `.workflows/<project-name>/04-setup.md`

---

## Error Handling

| Error | Resolution |
|---|---|
| Not a git repository | Offer to run `git init` |
| No build files detected | Fall back to `--preset` |
| Permission denied | Report and suggest fix |
