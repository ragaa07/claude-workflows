---
name: release
description: Automate versioned releases with changelog, version bump, release branch, PR, and tagging.
---

# Release Workflow

## Command

`/release <version>`

## Phases

### Phase 1: CHANGELOG

Generate changelog from git history since last tag.

1. Find last tag: `git describe --tags --abbrev=0`
2. Collect commits: `git log <last-tag>..HEAD --oneline --no-merges`
3. Categorize by conventional commit type:
   - **Features** (`feat:`), **Bug Fixes** (`fix:`), **Refactoring** (`refactor:`)
   - **Performance** (`perf:`), **Docs** (`docs:`), **Tests** (`test:`), **Chores** (`chore:`)
   - **Breaking Changes**: commits with `BREAKING CHANGE:` or `!:` suffix
4. Generate CHANGELOG.md entry with version header and date
5. Prepend entry to CHANGELOG.md (create if missing)
6. Present to user for review before proceeding

**Phase Output**: `.workflows/<version>/01-changelog.md`

### Phase 2: VERSION-BUMP

Bump version in the project's version file.

1. Detect version file:

   | File | Version Field |
   |------|--------------|
   | `build.gradle.kts` / `build.gradle` | `versionName` + `versionCode` |
   | `package.json` | `"version"` |
   | `Cargo.toml` | `version` under `[package]` |
   | `pyproject.toml` | `version` under `[project]` or `[tool.poetry]` |
   | `version.properties` / `VERSION` | Plain version string |

2. Update version to specified `<version>` value
3. For Android projects, also increment `versionCode` by 1
4. Show diff and confirm with user
5. Commit: `chore(version): bump to {version}`

**Phase Output**: `.workflows/<version>/02-version-bump.md` (old version, new version, files changed)

### Phase 3: RELEASE-BRANCH

Create release branch from development branch.

1. Ensure clean working tree
2. Checkout development branch (from `git.branches.development` in `.claude/workflows.yml`)
3. Pull latest changes
4. Create branch: `release/{version}`
5. Cherry-pick/merge version bump and changelog commits if not present
6. Push release branch to remote

**Phase Output**: `.workflows/<version>/03-release-branch.md`

### Phase 4: PR

Create pull request from release branch to production.

**Quality gate**: Load `.claude/reviews/general-checklist.md` and the language-specific checklist from `.claude/reviews/`. Verify all High/Critical items pass. Run full build and test suite to confirm release readiness.

1. Target: main branch (from `git.branches.main` in `.claude/workflows.yml`)
2. Title: `Release v{version}`
3. Body: include changelog entry from Phase 1
4. Create via `gh pr create`
5. Output PR URL

**Phase Output**: `.workflows/<version>/04-pr.md` (URL, summary)

### Phase 5: TAG

After PR is merged, provide tagging commands.

1. Remind user to merge PR first
2. Provide tag command:
   ```
   git tag -a v{version} -m "Release v{version}"
   git push origin v{version}
   ```
3. Optionally create GitHub release:
   ```
   gh release create v{version} --title "v{version}" --notes "See CHANGELOG.md"
   ```

**Phase Output**: `.workflows/<version>/05-tag.md`

## Configuration

| Config Key | Default | Description |
|------------|---------|-------------|
| `git.branches.development` | `develop` | Branch to create release from |
| `git.branches.main` | `main` | Target branch for release PR |
| `git.branches.release` | `release/v{version}` | Release branch pattern |

## Notes

- Each phase is a checkpoint. User can pause and resume.
- Never force-push or delete branches without explicit user approval.
- If CHANGELOG.md exists, prepend new entry; do not overwrite.
- Version format follows semver: `MAJOR.MINOR.PATCH`.
