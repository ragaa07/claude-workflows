---
name: git-flow
description: Direct git operations — branch creation, commits, PRs, and merges using project-configured patterns and policies.
---

# Git Flow Skill

## Commands

```
/workflow:git-flow branch <type> <name>
/workflow:git-flow commit <message>
/workflow:git-flow pr [--base <branch>]
/workflow:git-flow merge <branch>
```

---

## Subcommand: `branch <type> <name>`

Create a branch from the configured pattern in `.claude/workflows.yml`.

1. Read `git.branches` from `.claude/workflows.yml`
2. Validate `<type>` is one of: `feature`, `bugfix`, `hotfix`, `release`
3. Resolve the pattern — replace `{name}` or `{version}` with `<name>`:
   - `feature/{name}`, `bugfix/{name}`, `hotfix/{name}`, `release/v{version}`
4. **Protected branch check**: If the current branch is in `git.protected`, warn before branching from it
5. Ensure working tree is clean, pull latest from the base branch
6. Create and checkout the new branch:
   ```bash
   git checkout -b <resolved-branch-name>
   ```
7. Print the created branch name

**Error**: If `<type>` is not recognized, list valid types from config and abort.

---

## Subcommand: `commit <message>`

Commit staged changes using the configured commit format.

1. Read `git.commits` from `.claude/workflows.yml`
2. **Format validation** — if `format: "conventional"`, enforce:
   - Message must match: `<type>(<scope>): <description>` or `<type>: <description>`
   - `<type>` must be one of the configured `types` list (e.g., `feat`, `fix`, `refactor`, etc.)
   - If the message does not match, reject with an example of the correct format
3. **Protected branch check**: If current branch is in `git.protected`, abort with a warning — never commit directly to protected branches
4. Stage files if none are staged (prompt user to confirm which files)
5. Create the commit:
   ```bash
   git add <specific-files>
   git commit -m "<validated-message>"
   ```
6. Print the commit hash and summary

**Error**: If no changes are staged and no untracked files exist, abort with "nothing to commit".

---

## Subcommand: `pr [--base <branch>]`

Create a pull request with configured settings.

1. Read `git.pr` from `.claude/workflows.yml`
2. Determine base branch:
   - Use `--base <branch>` if provided
   - Otherwise use `git.pr.base_branch` from config (default: `develop`)
3. **Protected branch check**: Warn if PR target is `main`/`master` and source is not a `release/` or `hotfix/` branch
4. Push current branch to remote:
   ```bash
   git push -u origin <current-branch>
   ```
5. Generate PR title from branch name (e.g., `feature/add-login` -> `feat: add login`)
6. Generate PR body from commit log:
   ```bash
   git log <base-branch>..HEAD --oneline --no-merges
   ```
7. Use the PR body template from `git.pr.template` in `.claude/workflows.yml` if configured.
8. Create the PR:
   ```bash
   gh pr create \
     --base <base-branch> \
     --title "<generated-title>" \
     --body "<generated-body>" \
     --draft <git.pr.draft> \
     --reviewer <git.pr.reviewers> \
     --label <git.pr.labels>
   ```
   - Omit `--reviewer` and `--label` flags if their config arrays are empty
8. Print the PR URL

---

## Subcommand: `merge <branch>`

Merge a branch using the configured strategy.

1. Read `git.merge` from `.claude/workflows.yml`
2. **Protected branch check**: If merging INTO a protected branch, require explicit user confirmation
3. Verify the branch exists and has an open PR (if applicable)
4. Apply the configured merge strategy:
   - `squash`: `gh pr merge <branch> --squash`
   - `merge`: `gh pr merge <branch> --merge`
   - `rebase`: `gh pr merge <branch> --rebase`
5. If `git.merge.delete_branch` is `true`:
   ```bash
   gh pr merge <branch> --<strategy> --delete-branch
   ```
6. Pull latest after merge:
   ```bash
   git checkout <base-branch>
   git pull origin <base-branch>
   ```
7. Print merge result and confirm branch deletion status

**Error**: If merge conflicts exist, abort and report the conflicting files.

---

## Configuration Reference

All settings are read from `.claude/workflows.yml` under the `git` key:

| Key | Default | Purpose |
|-----|---------|---------|
| `git.branches.<type>` | See patterns above | Branch naming patterns |
| `git.commits.format` | `conventional` | Commit message format |
| `git.commits.types` | `[feat, fix, ...]` | Allowed commit types |
| `git.pr.base_branch` | `develop` | Default PR target |
| `git.pr.draft` | `false` | Create PRs as draft |
| `git.pr.reviewers` | `[]` | Auto-assign reviewers |
| `git.pr.labels` | `[]` | Auto-apply labels |
| `git.merge.strategy` | `squash` | Merge method |
| `git.merge.delete_branch` | `true` | Delete branch after merge |
| `git.protected` | `[main, master, develop]` | Branches that block direct commits |

## Notes

- Never force-push to protected branches.
- All subcommands read config fresh each invocation — config changes take effect immediately.
- If `.claude/workflows.yml` is missing, use the defaults shown above.
