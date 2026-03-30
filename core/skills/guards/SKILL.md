---
name: guards
description: Safety guard enforcement — checks files against block patterns, protected paths, and credential leaks before commits and pushes.
---

# Safety Guards

```
/guards init
/guards check [--staged] [--force]
/guards report
```

Prevents dangerous operations and credential leaks by enforcing rules from `.claude/guards.yml`. Runs as a pre-commit/pre-push check or manually.

---

## `/guards init`

1. If `.claude/guards.yml` exists, print: `Guards config already exists at .claude/guards.yml`
2. Otherwise, copy `.claude/templates/guards.yml.tmpl` to `.claude/guards.yml`.
3. Print config summary (count of block patterns, warn patterns, protected paths, no-commit patterns).

**Error**: If template missing, print: `Template not found at .claude/templates/guards.yml.tmpl`

---

## `/guards check [--staged] [--force]`

**Step 1 -- Load Rules**: Read `.claude/guards.yml` (run `init` if missing). Extract `block_patterns`, `warn_patterns`, `protected_paths`, `no_commit_patterns`.

**Step 2 -- Determine File Set**:
- `--staged`: `git diff --cached --name-only`
- Default: `git diff --name-only HEAD` + `git ls-files --others --exclude-standard`

**Step 3 -- Check Files**: For each file, check:
- Path matches against `protected_paths` and `no_commit_patterns`
- Content matches against `block_patterns` and `warn_patterns`
- Hardcoded tokens (`AKIA`, `sk-`, `ghp_`, `Bearer `, API key formats)

**Step 4 -- Report**: Print `[BLOCK]`, `[WARN]`, `[PASS]` per file with violation details. `BLOCK` stops the operation; `WARN` is advisory (unless `guards.strict: true`).

If `--force` passed, log override to `.workflows/history/guard-overrides.log` and allow the operation.

---

## `/guards report`

Print config summary (block/warn pattern counts, protected paths, no-commit globs) and recent overrides from `.workflows/history/guard-overrides.log`. If no config found, run `init` automatically.
