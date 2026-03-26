---
name: release
description: Automate versioned releases with changelog, version bump, release branch, PR, and tagging.
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

**Phase Output**: Write changelog entries to `.workflows/<version>/01-changelog.md`

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

**Phase Output**: Write version bump details (old version, new version, files changed) to `.workflows/<version>/02-version-bump.md`

### Phase 3: RELEASE-BRANCH

Create a release branch from the development branch.

1. Ensure working tree is clean
2. Checkout the development branch (from `git.branches.development` in `.claude/workflows.yml`)
3. Pull latest changes
4. Create branch: `release/{version}`
5. Cherry-pick or merge the version bump and changelog commits onto this branch if not already present
6. Push the release branch to remote

**Phase Output**: Write branch details to `.workflows/<version>/03-release-branch.md`

### Phase 4: PR

Create a pull request from the release branch to production.

1. Target branch: main branch (from `git.branches.main` in `.claude/workflows.yml`)
2. PR title: `Release v{version}`
3. PR body: Include the changelog entry generated in Phase 1
4. Use `gh pr create` to create the PR
5. Output the PR URL for the user

**Phase Output**: Write PR details (URL, summary) to `.workflows/<version>/04-pr.md`

### Phase 5: TAG

After the PR is merged, provide the tagging command.

1. Remind the user to merge the PR first
2. Provide the tag command:
   ```
   git tag -a v{version} -m "Release v{version}"
   git push origin v{version}
   ```
3. Optionally create a GitHub release: `gh release create v{version} --title "v{version}" --notes "Release v{version} — see CHANGELOG.md for details"`

**Phase Output**: Write tag details and release notes to `.workflows/<version>/05-tag.md`

## Configuration

The workflow respects project-level configuration for branch names:

| Config Key | Default | Description |
|------------|---------|-------------|
| `git.branches.development` | `develop` | Branch to create release from |
| `git.branches.main` | `main` | Branch to merge release into (production) |
| `git.branches.release` | `release/v{version}` | Release branch pattern ({version} replaced) |

## Notes

- Each phase is a checkpoint. The user can pause and resume.
- Never force-push or delete branches without explicit user approval.
- If a CHANGELOG.md already exists, prepend the new entry; do not overwrite.
- Version format follows semver: `MAJOR.MINOR.PATCH` (e.g., `1.2.3`).
