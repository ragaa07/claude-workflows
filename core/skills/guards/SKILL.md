---
name: guards
description: Safety guard system that reads .claude/guards.yml and enforces block/warn rules on commands and protected file paths before execution.
---

# Safety Guards

Enforces safety rules defined in `.claude/guards.yml` to prevent dangerous operations during workflow execution. Active at all times once loaded.

## Initialization

At the start of every session:

1. Read `.claude/guards.yml` from the project root
2. If the file does not exist, warn the user and suggest running the setup to create one from the template (`core/templates/guards.yml.tmpl`)
3. Parse all four rule sections: `block_patterns`, `warn_patterns`, `protected_paths`, `no_commit_patterns`
4. If `guards.enabled` is `false`, skip enforcement but log that guards are disabled

## Command Enforcement

Before executing ANY bash command, check the full command string against the guard rules:

### Block Patterns

If the command matches any entry in `block_patterns`:

1. **REFUSE** to execute the command
2. Explain which block pattern was matched and why it is dangerous
3. Suggest a safer alternative if one exists
4. Log the blocked command in Context Notes with format: `[GUARD:BLOCKED] <timestamp> — <command> — matched: <pattern>`
5. Do NOT proceed under any circumstance, even if the user insists

### Warn Patterns

If the command matches any entry in `warn_patterns` (and did not match a block pattern):

1. **WARN** the user by clearly stating which warn pattern was matched
2. Explain the potential risk of the command
3. Ask the user for explicit confirmation before proceeding
4. If the user confirms, execute the command and log: `[GUARD:WARNED+APPROVED] <timestamp> — <command> — matched: <pattern>`
5. If the user declines, do not execute and log: `[GUARD:WARNED+DECLINED] <timestamp> — <command> — matched: <pattern>`

### No Match

If the command does not match any pattern, execute normally with no additional output.

## File Path Enforcement

Before reading, writing, or accessing any file:

1. Check the file path against `protected_paths` patterns
2. If matched, **REFUSE** to read, write, or display the file contents
3. Log: `[GUARD:PROTECTED] <timestamp> — attempted access: <path> — matched: <pattern>`
4. Explain that the file is protected by safety guards

## Commit Enforcement

Before staging files with `git add` or creating commits:

1. Check all staged file paths against `no_commit_patterns`
2. If any file matches, **WARN** the user and list the matching files
3. Ask for explicit confirmation before including those files in the commit
4. Log warnings: `[GUARD:COMMIT_WARN] <timestamp> — <file> — matched: <pattern>`

## Pattern Matching Rules

- Patterns are matched as substrings against the full command string (case-sensitive)
- Patterns containing `.*` or other regex metacharacters are treated as regular expressions
- File path patterns support glob syntax (`*.pem`, `credentials*`)
- Block patterns take precedence over warn patterns (a command matching both is blocked)

## Logging

All guard events are accumulated during the session and can be reviewed by the user at any time. When asked about guard activity, present a summary table:

```
| Time | Action | Command/Path | Matched Pattern |
|------|--------|--------------|-----------------|
```

## Customization

Users can modify `.claude/guards.yml` to:
- Add project-specific block or warn patterns
- Add additional protected paths (e.g., production config files)
- Disable guards temporarily by setting `guards.enabled: false`
- Add no-commit patterns for project-specific sensitive files

Changes to the guards file take effect immediately on the next command check.
