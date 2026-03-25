---
name: git-flow
description: Git operations skill for branch creation, commit formatting, PR creation, and protected branch enforcement using project config.
---

# Git Flow

Handles all git operations for workflows. Reads configuration from `.claude/workflows.yml` and enforces project conventions for branches, commits, and pull requests.

## Reading Git Config

Load the `git` section from `.claude/workflows.yml` (fall back to `core/config/defaults.yml`):

```yaml
git:
  branches:
    main: "main"
    development: "develop"
    feature: "feature/{name}"
    bugfix: "bugfix/{name}"
    hotfix: "hotfix/{name}"
    release: "release/v{version}"
  commits:
    format: "conventional"
    types: [feat, fix, refactor, test, docs, chore, style, perf]
    scopes: true
    ticket_reference: false
  pr:
    base_branch: "develop"
    draft: false
    reviewers: []
    labels: []
    template: "..."
  merge:
    strategy: "squash"
    delete_branch: true
  protected:
    - "main"
    - "master"
    - "develop"
```

## Branch Operations

### Creating Branches

1. Read the branch pattern from config for the given type (feature, bugfix, hotfix, release)
2. Replace `{name}` with the kebab-case feature name
3. Replace `{version}` with the version string (for release branches)
4. Validate the resulting branch name against the pattern
5. Create the branch from the appropriate base:
   - **feature/bugfix**: Branch from `git.branches.development`
   - **hotfix**: Branch from `git.branches.main`
   - **release**: Branch from `git.branches.development`

```bash
# Example: feature branch
git checkout <development-branch>
git pull origin <development-branch>
git checkout -b feature/my-feature-name
```

### Branch Name Validation

Branch names must:
- Match the configured pattern for their type
- Use kebab-case for the `{name}` portion
- Not contain spaces, uppercase letters, or special characters (except `/`, `-`, `_`)
- Not duplicate an existing remote branch (check with `git branch -r`)

If validation fails, suggest the corrected name and ask the user to confirm.

## Commit Message Formatting

### Conventional Format (`format: "conventional"`)

```
<type>: <description>

[optional body]

[optional footer]
```

Valid types from config: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`, `perf`

Examples:
```
feat: add user profile avatar upload
fix: prevent crash on empty search results
refactor: extract payment logic into service layer
chore: update gradle wrapper to 8.9
```

### Angular Format (`format: "angular"`)

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

The scope is required and should identify the module or area affected.

Examples:
```
feat(auth): add biometric login support
fix(search): handle null query parameter gracefully
refactor(payments): consolidate payment gateway adapters
```

### Simple Format (`format: "simple"`)

Free-form commit messages. No enforced structure, but recommend:
- Start with a capital letter
- Use imperative mood ("Add feature" not "Added feature")
- Keep the first line under 72 characters

Examples:
```
Add user profile avatar upload
Fix crash on empty search results
```

### Ticket References

When `commits.ticket_reference: true`, append the ticket ID to the commit message:

```
feat: add user profile avatar upload [PROJ-123]
```

If the ticket ID is available in the workflow state, include it automatically. If not, ask the user.

## PR Creation

### Template Variable Substitution

The PR template from config supports these variables:

| Variable | Source |
|----------|--------|
| `{summary}` | Generated from commit messages and spec document |
| `{changes}` | Bulleted list of changes from git diff against base branch |
| `{test_plan}` | From the test phase output or manual input |
| `{ticket}` | Ticket reference from workflow state |
| `{branch}` | Current branch name |
| `{base}` | Target base branch |

### Creating a PR

1. Read PR config: `base_branch`, `draft`, `reviewers`, `labels`, `template`
2. Ensure all changes are committed and pushed
3. Generate the PR body by substituting template variables
4. Create the PR:

```bash
# Push the branch
git push -u origin <branch-name>

# Create the PR
gh pr create \
  --base <base_branch> \
  --title "<pr-title>" \
  --body "<substituted-template>" \
  [--draft] \
  [--reviewer <reviewer1>,<reviewer2>] \
  [--label <label1>,<label2>]
```

5. Report the PR URL to the user

### PR Title

Generate from the feature name and workflow type:
- **new-feature**: `feat: <feature-name-in-sentence-case>`
- **hotfix**: `fix: <description>`
- **refactor**: `refactor: <description>`
- **release**: `release: v<version>`

Keep under 72 characters.

## Protected Branch Detection

Before ANY commit or push operation:

1. Get the current branch: `git rev-parse --abbrev-ref HEAD`
2. Check if it matches any branch in `git.protected`
3. If on a protected branch:
   ```
   WARNING: You are on protected branch '<branch>'.
   Direct commits to this branch are not recommended.

   Options:
   1. Create a feature branch instead
   2. Continue anyway (not recommended)
   ```
4. If the user chooses to continue, proceed but log a warning in the workflow state

## Push Operations

Before pushing:

1. Check for uncommitted changes: `git status --porcelain`
2. If changes exist, warn the user and offer to commit first
3. Push with upstream tracking:
   ```bash
   git push -u origin <branch-name>
   ```
4. If push fails due to remote changes, suggest:
   ```bash
   git pull --rebase origin <branch-name>
   ```

## Hotfix Cherry-Pick Instructions

After a hotfix PR is merged to the main branch, provide cherry-pick instructions for backporting to the development branch:

```
Hotfix merged to <main-branch>.

To backport to <development-branch>:
  git checkout <development-branch>
  git pull origin <development-branch>
  git cherry-pick <commit-sha>
  git push origin <development-branch>

Or create a separate PR to merge <main-branch> back into <development-branch>.
```

## Merge Strategy

When discussing PR merge options, reference the configured strategy:

| Strategy | Description |
|----------|-------------|
| `squash` | Combine all commits into one. Keeps history clean. |
| `merge` | Create a merge commit. Preserves full history. |
| `rebase` | Rebase onto target. Linear history, no merge commits. |

Report the configured strategy to the user when creating PRs.
