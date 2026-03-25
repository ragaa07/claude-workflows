---
name: review
description: Review a GitHub pull request by fetching changes, categorizing by layer, checking against quality standards, and generating inline comments with severity levels.
---

# Code Review Workflow

## Command

```
/workflow:review <pr-number> [--strict] [--focus <area>]
```

**Options**:
- `--strict`: Treat warnings as errors
- `--focus <area>`: Focus review on specific area (security, performance, architecture, tests)

## Overview

Reviews a pull request systematically. Four phases: **FETCH -> CATEGORIZE -> CHECK -> COMMENT**.

---

## Phase 1: FETCH

**Goal**: Gather all PR data needed for review.

### Step 1.1 — Fetch PR Metadata

```bash
gh pr view <pr-number> --json title,body,author,baseRefName,headRefName,additions,deletions,changedFiles,labels,state,reviewDecision
```

Extract:
- **Title**: PR title
- **Description**: PR body
- **Author**: Who wrote it
- **Base branch**: Target branch
- **Head branch**: Source branch
- **Size**: Additions, deletions, changed files count
- **Labels**: Any labels applied
- **Status**: Open, draft, etc.
- **Existing reviews**: Any prior review decisions

### Step 1.2 — Fetch PR Diff

```bash
gh pr diff <pr-number>
```

Store the full diff for analysis.

### Step 1.3 — Fetch Changed Files List

```bash
gh pr view <pr-number> --json files --jq '.files[].path'
```

### Step 1.4 — Fetch PR Checks

```bash
gh pr checks <pr-number>
```

Note any failing checks — these should be flagged in the review.

### Step 1.5 — Fetch PR Comments

```bash
gh api repos/{owner}/{repo}/pulls/<pr-number>/comments
gh api repos/{owner}/{repo}/issues/<pr-number>/comments
```

Check for existing review comments to avoid duplicating feedback.

### Step 1.6 — Read Full Changed Files

For each changed file in the PR, read the FULL file (not just the diff) to understand context:

```bash
gh pr view <pr-number> --json files --jq '.files[].path' | while read f; do
  echo "=== $f ==="
done
```

Use the Read tool to read each changed file in full. This is critical for understanding whether the changes fit the surrounding code.

### Decision Point: PR Size

- **Small** (< 10 files, < 200 lines): Review inline
- **Medium** (10-30 files, 200-500 lines): Review by category
- **Large** (> 30 files, > 500 lines): Use sub-agents per category, warn that PR should be split

---

## Phase 2: CATEGORIZE

**Goal**: Organize changes by architectural layer for structured review.

### Step 2.1 — Classify Each File

Assign each changed file to a category:

| Category | File Patterns | Examples |
|---|---|---|
| **UI** | `*Screen.kt`, `*Composable.kt`, `*Component.kt`, `*View.kt`, `*.xml` (layout) | Composables, XML layouts, themes |
| **ViewModel** | `*ViewModel.kt`, `*State.kt`, `*Event.kt` | State management, UI logic |
| **Domain** | `*UseCase.kt`, `*Interactor.kt`, `*Repository.kt` (interface) | Business logic |
| **Data** | `*RepositoryImpl.kt`, `*DataSource.kt`, `*ApiService.kt`, `*DTO.kt`, `*Mapper.kt` | Data access, API, mapping |
| **DI** | `*Module.kt`, `*Component.kt` (Hilt/Dagger) | Dependency injection setup |
| **Navigation** | `*NavGraph.kt`, `*Route.kt`, `*Navigation.kt` | Screen navigation |
| **Model** | `*Model.kt`, `*Entity.kt`, data classes | Domain/data models |
| **Test** | `*Test.kt`, `*Spec.kt` (in test directories) | Unit/integration tests |
| **Config** | `*.gradle.kts`, `*.yml`, `*.xml` (non-layout), `*.properties` | Build config, resources |
| **Analytics** | `*Analytics*.kt`, `*Tracker*.kt`, `*Event*.kt` (in analytics packages) | Event tracking |
| **Other** | Anything not matching above | Documentation, scripts, etc. |

### Step 2.2 — Build Review Order

Review in this order (dependencies flow top-down):
1. **Model/Data** — Data structures and API changes
2. **Domain** — Business logic
3. **ViewModel** — State management
4. **UI** — Presentation
5. **Navigation** — Integration
6. **DI** — Wiring
7. **Analytics** — Tracking
8. **Config** — Build changes
9. **Test** — Test quality

### Step 2.3 — Summarize PR Scope

```
PR Scope Summary:
  UI:         3 files (2 new, 1 modified)
  ViewModel:  1 file (modified)
  Domain:     2 files (new)
  Data:       1 file (modified)
  Tests:      2 files (new)
  Config:     1 file (modified)
  Total:      10 files (+350, -20)
```

---

## Phase 3: CHECK

**Goal**: Review each file against quality standards.

### Check Categories

For each changed file, run through these check categories:

#### 3.1 — Architecture Compliance

- Does the change follow the project's architecture pattern (MVVM, Clean, etc.)?
- Are layer boundaries respected? (UI does not call repository directly)
- Are dependencies flowing in the correct direction?
- Is the DI setup correct? (Scope, bindings, qualifiers)
- Are new classes placed in the correct package/module?

**Severity for violations**: error

#### 3.2 — Code Quality

- **Naming**: Are class/function/variable names clear and consistent with codebase?
- **Complexity**: Are functions too long (>50 lines)? Too many parameters (>5)?
- **Duplication**: Is there duplicated logic that should be extracted?
- **Dead code**: Are there unused imports, variables, or functions?
- **Hardcoded values**: Are there magic numbers, hardcoded strings, or URLs?
- **Nullability**: Are nullable types handled safely? Any `!!` usage?
- **Error handling**: Are exceptions caught appropriately? Any swallowed exceptions?
- **Logging**: Is there appropriate logging for debugging?

**Severity for violations**: warning (minor) or error (major)

#### 3.3 — Security

- Are API keys, tokens, or secrets hardcoded?
- Is user input validated/sanitized?
- Are sensitive data fields (passwords, tokens) properly handled?
- Is data stored securely (encrypted preferences, not plain text)?
- Are network calls using HTTPS?
- SQL injection risks in raw queries?
- Are permissions requested minimally?

**Severity for violations**: error

#### 3.4 — Performance

- Are there operations on the main thread that should be on background?
- N+1 query patterns?
- Unnecessary object allocations in hot paths (loops, draw calls)?
- Missing `remember` in Compose? Unnecessary recompositions?
- Large data loaded without pagination?
- Missing caching where beneficial?
- Flow collection without lifecycle awareness?

**Severity for violations**: warning

#### 3.5 — Test Coverage

- Do new public functions have corresponding tests?
- Do tests cover happy path, error paths, and edge cases?
- Are tests using Given/When/Then pattern?
- Are mocks appropriate (not mocking everything)?
- Are tests deterministic (no flakiness risk)?
- Is test code quality equal to production code quality?

**Severity for violations**: warning

#### 3.6 — Consistency

- Does the code match existing patterns in the codebase?
- Are similar problems solved the same way?
- Is the formatting consistent with surrounding code?
- Are imports organized consistently?

**Severity for violations**: nitpick

### Check Process

For each file, for each check category:

1. Read the full diff for the file
2. Read surrounding code for context
3. Evaluate against each check point
4. If a violation is found:
   - Determine severity (error, warning, suggestion, nitpick)
   - Note the exact file and line number
   - Write a clear, actionable comment
   - Include a code suggestion if applicable

---

## Phase 4: COMMENT

**Goal**: Generate and submit review comments.

### Step 4.1 — Compile Comments

Organize all findings into a structured list:

```
Review Comments:

1. [ERROR] file.kt:42 — Architecture violation
   UI layer directly accesses repository. Should go through ViewModel.
   Suggestion: Move `repository.fetch()` call to ViewModel, expose via StateFlow.

2. [WARNING] ViewModel.kt:88 — Potential memory leak
   Flow collection without lifecycle scope. Use `viewModelScope.launch` or `repeatOnLifecycle`.

3. [SUGGESTION] Model.kt:15 — Consider sealed interface
   This enum could be a sealed interface for better extensibility.

4. [NITPICK] Screen.kt:33 — Naming
   `doStuff()` is not descriptive. Consider `submitRegistrationForm()`.
```

### Severity Definitions

| Severity | Meaning | Blocks Merge? |
|---|---|---|
| **error** | Bug, security issue, architecture violation, or crash risk | Yes |
| **warning** | Code smell, performance issue, or missing best practice | No (but should fix) |
| **suggestion** | Improvement idea, alternative approach | No |
| **nitpick** | Style, naming, minor formatting | No |

### Step 4.2 — Generate Summary

Write a review summary:

```markdown
## Review Summary

**PR**: #<number> — <title>
**Verdict**: <APPROVE | REQUEST_CHANGES | COMMENT>

### Stats
- Files reviewed: <N>
- Errors: <N>
- Warnings: <N>
- Suggestions: <N>
- Nitpicks: <N>

### Key Findings
1. <most important finding>
2. <second most important finding>

### What's Good
- <positive observation 1>
- <positive observation 2>

### Action Required
- [ ] <fix required 1>
- [ ] <fix required 2>
```

**Verdict logic**:
- Any **error** findings → REQUEST_CHANGES
- Only warnings/suggestions/nitpicks → COMMENT (or APPROVE if minor)
- No findings → APPROVE
- `--strict` flag: warnings also trigger REQUEST_CHANGES

### Step 4.3 — Present to User for Approval

Display the full review (summary + all comments) to the user.

Ask: "Submit this review? You can: (1) submit as-is, (2) remove specific comments, (3) adjust severities, (4) cancel."

### Decision Point: User Approval

- **Submit as-is**: Proceed to Step 4.4
- **Remove comments**: Remove specified comments, re-present
- **Adjust severities**: Update severities, recalculate verdict
- **Cancel**: Do not submit

### Step 4.4 — Submit Review

Submit the review summary as a PR review:

```bash
gh pr review <pr-number> \
  --<approve|request-changes|comment> \
  --body "$(cat <<'EOF'
<review-summary>
EOF
)"
```

Submit inline comments via GitHub API:

```bash
gh api repos/{owner}/{repo}/pulls/<pr-number>/reviews \
  --method POST \
  --field event="<APPROVE|REQUEST_CHANGES|COMMENT>" \
  --field body="<summary>" \
  --field comments='[
    {
      "path": "<file-path>",
      "line": <line-number>,
      "body": "[<SEVERITY>] <comment>"
    }
  ]'
```

### Step 4.5 — Report

Print:

```
Review submitted for PR #<number>.

  Verdict:     <verdict>
  Comments:    <count> submitted
  Errors:      <count>
  Warnings:    <count>
  Suggestions: <count>
  Nitpicks:    <count>

  PR URL: <url>
```

---

## Error Handling

| Error | Resolution |
|---|---|
| PR not found | Verify PR number and repository |
| gh CLI not authenticated | Guide user through `gh auth login` |
| PR is already merged | Report status, skip review |
| PR is draft | Review anyway but note it is a draft |
| Diff too large to analyze | Use sub-agents per category, warn about PR size |
| Cannot determine file context | Read full file from the head branch |
| API rate limit hit | Wait and retry, or submit comments in batches |

## Review Principles

1. **Be constructive**: Every criticism must include a suggestion
2. **Be specific**: Point to exact lines, provide code examples
3. **Be proportional**: Do not block a PR for nitpicks
4. **Acknowledge good work**: Call out well-written code
5. **Focus on behavior**: Prioritize correctness over style
6. **Consider context**: A hotfix has different standards than a feature PR
7. **One comment per issue**: Do not combine multiple concerns in one comment
