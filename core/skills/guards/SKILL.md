---
name: guards
description: Safety guard enforcement — checks files against block patterns, protected paths, and credential leaks before commits and pushes.
---

# Safety Guards

## Command

```
/workflow:guards init
/workflow:guards check [--staged] [--force]
/workflow:guards report
```

## Overview

Prevents dangerous operations and credential leaks by enforcing rules from `.claude/guards.yml`. Runs as a pre-commit/pre-push check or manually.

---

## Subcommand: `init`

1. If `.claude/guards.yml` exists, print: `Guards config already exists at .claude/guards.yml`
2. Otherwise, copy `.claude/templates/guards.yml.tmpl` to `.claude/guards.yml`.
3. Print config summary (count of block patterns, warn patterns, protected paths, no-commit patterns).

---

## Subcommand: `check [--staged] [--force]`

### Step 1 — Load Rules

Read `.claude/guards.yml` (run `init` if missing). Extract `block_patterns`, `warn_patterns`, `protected_paths`, and `no_commit_patterns`.

### Step 2 — Determine File Set

- `--staged`: `git diff --cached --name-only`
- Default: `git diff --name-only HEAD` + `git ls-files --others --exclude-standard`

### Step 3 — Check Files

For each file, check:
- Path matches against `protected_paths` and `no_commit_patterns`
- Content matches against `block_patterns` and `warn_patterns`
- Hardcoded tokens (`AKIA`, `sk-`, `ghp_`, `Bearer `, API key formats)

### Step 4 — Report

```
Guards Check Results:
  [BLOCK]   .env.local — protected path, must not be committed
  [BLOCK]   src/api.js:14 — hardcoded token detected (sk-...)
  [WARN]    deploy.sh:8 — matches warn pattern: "rm -rf"
  [PASS]    42 files passed all checks

  Result: BLOCKED (2 blocking violations found)
```

**Severities**: `BLOCK` stops the operation, `WARN` prints but does not block (unless `guards.strict: true`), `PASS` means clean.

If `--force` is passed, log override to `.workflows/history/guard-overrides.log` and allow the operation to proceed.

---

## Subcommand: `report`

```
Guards Status:
  Config:           .claude/guards.yml (loaded)
  Block patterns:   <N> rules
  Warn patterns:    <N> rules
  Protected paths:  <N> paths
  No-commit globs:  <N> patterns

Recent overrides:
  <timestamp> — <file> — <reason>
  (none)
```

---

## Error Handling

| Error | Resolution |
|---|---|
| No guards config found | Run `init` automatically |
| Template file missing | Print: `Template not found at .claude/templates/guards.yml.tmpl` |
| Invalid YAML in config | Print parse error with line number |
