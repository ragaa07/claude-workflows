---
name: release
description: Automate versioned releases with changelog, version bump, release branch, PR, and tagging.
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

- **workflow**: release
- **feature**: <feature>
- **phase**: CHANGELOG
- **started**: <current ISO-8601 timestamp>
- **updated**: <current ISO-8601 timestamp>
- **branch**:

## Phase History

| Phase | Status | Timestamp | Notes |
|-------|--------|-----------|-------|
| CHANGELOG | ACTIVE | <timestamp> | Starting changelog generation |

## Completed Steps


## Artifacts


## Context

```

### Step 0.4 — Read Configuration

Read `.claude/workflows.yml` and note relevant config for this workflow, especially `workflows.release.changelog` and `workflows.release.tag_format`.

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

# Release Workflow

## Command

`/workflow:release <version>`

## Phases

### Phase 1: CHANGELOG

Generate a changelog entry from git history since the last tag.

1. Find the last tag: `git describe --tags --abbrev=0`
2. Collect commits since that tag: `git log <last-tag>..HEAD --oneline --no-merges`
3. Categorize commits by conventional commit type:
   - **Features** (`feat:`): New functionality
   - **Bug Fixes** (`fix:`): Bug corrections
   - **Refactoring** (`refactor:`): Code restructuring without behavior change
   - **Performance** (`perf:`): Performance improvements
   - **Documentation** (`docs:`): Documentation changes
   - **Tests** (`test:`): Test additions or modifications
   - **Chores** (`chore:`): Build, CI, dependency updates
   - **Breaking Changes**: Any commit with `BREAKING CHANGE:` or `!:` suffix
4. Generate a CHANGELOG.md entry with the version header and date
5. Prepend the entry to CHANGELOG.md (create the file if it does not exist)
6. Present the changelog to the user for review before proceeding

### Phase 2: VERSION-BUMP

Bump the version in the project's version file.

1. Detect the version file by checking in order:
   - `build.gradle.kts` or `build.gradle` — look for `versionName` and `versionCode`
   - `package.json` — look for `"version"` field
   - `Cargo.toml` — look for `version` under `[package]`
   - `pyproject.toml` — look for `version` under `[project]` or `[tool.poetry]`
   - `version.properties` or `VERSION` file
2. Update the version to the specified `<version>` value
3. For Android projects, also increment `versionCode` by 1
4. Show the diff to the user and ask for confirmation before committing
5. Commit with message: `chore(version): bump to {version}`

### Phase 3: RELEASE-BRANCH

Create a release branch from the development branch.

1. Ensure working tree is clean
2. Checkout the development branch (default: `Development`, configurable via project config)
3. Pull latest changes
4. Create branch: `release/{version}`
5. Cherry-pick or merge the version bump and changelog commits onto this branch if not already present
6. Push the release branch to remote

### Phase 4: PR

Create a pull request from the release branch to production.

1. Target branch: production branch (default: `Production`, configurable via project config)
2. PR title: `Release v{version}`
3. PR body: Include the changelog entry generated in Phase 1
4. Use `gh pr create` to create the PR
5. Output the PR URL for the user

### Phase 5: TAG

After the PR is merged, provide the tagging command.

1. Remind the user to merge the PR first
2. Provide the tag command:
   ```
   git tag -a v{version} -m "Release v{version}"
   git push origin v{version}
   ```
3. Optionally create a GitHub release: `gh release create v{version} --title "v{version}" --notes-file CHANGELOG_ENTRY.md`

## Configuration

The workflow respects project-level configuration for branch names:

| Config Key | Default | Description |
|------------|---------|-------------|
| `git.branches.development` | `Development` | Branch to create release from |
| `git.branches.production` | `Production` | Branch to merge release into |
| `git.branches.release_prefix` | `release/` | Prefix for release branches |

## Notes

- Each phase is a checkpoint. The user can pause and resume.
- Never force-push or delete branches without explicit user approval.
- If a CHANGELOG.md already exists, prepend the new entry; do not overwrite.
- Version format follows semver: `MAJOR.MINOR.PATCH` (e.g., `1.2.3`).
