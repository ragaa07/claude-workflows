---
name: review
description: Review a GitHub pull request by fetching changes, categorizing by architecture, checking against dynamically loaded checklists, and generating inline comments with severity levels.
---

# Code Review Workflow

```
/workflow:review <pr-number> [--strict] [--focus <area>]
```

- `--strict`: Treat warnings as errors
- `--focus <area>`: Prioritize checks matching area (security, performance, architecture, tests)

Four phases: **FETCH -> CATEGORIZE -> CHECK -> COMMENT**

---

## Phase 1: FETCH

**Goal**: Gather all PR data needed for review.

Detect repository: `gh repo view --json owner,name -q '.owner.login + "/" + .name'`

**1.1** Fetch PR metadata:
```bash
gh pr view <pr-number> --json title,body,author,baseRefName,headRefName,additions,deletions,changedFiles,labels,state,reviewDecision
```

**1.2** Fetch diff: `gh pr diff <pr-number>`

**1.3** Fetch changed files: `gh pr view <pr-number> --json files --jq '.files[].path'`

**1.4** Fetch CI checks: `gh pr checks <pr-number>` — flag failures.

**1.5** Fetch existing comments (avoid duplicating feedback):
```bash
gh api repos/{owner}/{repo}/pulls/<pr-number>/comments
gh api repos/{owner}/{repo}/issues/<pr-number>/comments
```

**1.6** Read each changed file in FULL using the Read tool (not just the diff) to understand context.

**Size Decision**:
- **Small** (< 10 files, < 200 lines): Review inline
- **Medium** (10-30 files, 200-500 lines): Review by category
- **Large** (> 30 files, > 500 lines): Sub-agents per category, warn PR should be split

**Phase Output**: `.workflows/<pr-name>/01-fetch.md`

---

## Phase 2: CATEGORIZE

**Goal**: Organize changes by architectural layer.

**2.1 — Classify files** by reading `project.type` from `.claude/workflows.yml`. Common categories:

| Category | Description |
|---|---|
| **UI** | Views, screens, components, templates, styles |
| **Logic/Controllers** | ViewModels, controllers, presenters, state management |
| **Domain/Business** | Use cases, services, business rules, interfaces |
| **Data/API** | Repositories, data sources, API clients, DTOs, mappers |
| **Models** | Domain entities, data classes, types, schemas |
| **Config** | Build files, CI/CD, environment config |
| **Tests** | Unit, integration, e2e tests, test utilities |
| **Other** | Documentation, scripts, assets |

Adapt to the project's actual architecture (e.g., Rails: Models/Views/Controllers; React: Components/Hooks/Store/Utils).

**2.2 — Review order** (foundations first): Models/Data -> Domain -> Logic/Controllers -> UI -> Config -> Tests

**2.3 — Summarize** file counts per category with additions/deletions.

**Phase Output**: `.workflows/<pr-name>/02-categorize.md`

---

## Phase 3: CHECK

**Goal**: Review each file against dynamically loaded quality checklists.

### Step 3.1 — Load Checklists

1. **Always load**: `.claude/reviews/general-checklist.md`
2. **Detect language**: Read `project.language` from `.claude/workflows.yml`
3. **Load language-specific**: `.claude/reviews/<language>-checklist.md` if it exists (e.g., `kotlin-checklist.md`, `typescript-checklist.md`, `python-checklist.md`)
4. **If no checklists found**: Warn user, use fallback checks below

### Step 3.2 — Apply Focus

If `--focus <area>` provided, prioritize matching checklist items. Still run all checks but weight focused violations higher.

### Step 3.3 — Fallback Checks (no checklist files)

- **Architecture**: Layer boundaries respected? Dependencies correct? Code in right location?
- **Code Quality**: Clear naming? Functions < 50 lines? No duplication/dead code/magic values? Errors handled?
- **Security**: No hardcoded secrets? Input validated? Sensitive data safe? HTTPS enforced?
- **Performance**: No blocking on critical paths? No N+1 queries? Caching/pagination where needed?
- **Test Coverage**: New public APIs tested? Happy/error/edge cases? Tests deterministic?
- **Consistency**: Matches codebase patterns? Similar problems solved same way?

### Step 3.4 — Execute

For each changed file, run through ALL loaded checklist items. For each violation record:
- **Severity**: error / warning / suggestion / nitpick
- **File + Line**: exact path and line number
- **Issue**: clear description
- **Suggestion**: actionable fix or code example

**Phase Output**: `.workflows/<pr-name>/03-check.md`

---

## Phase 4: COMMENT

**Goal**: Generate and submit review comments.

### Severity Definitions

| Severity | Meaning | Blocks Merge? |
|---|---|---|
| **error** | Bug, security issue, architecture violation, crash risk | Yes |
| **warning** | Code smell, performance issue, missing best practice | No (but should fix) |
| **suggestion** | Improvement idea, alternative approach | No |
| **nitpick** | Style, naming, minor formatting | No |

### Step 4.1 — Compile Comments

Format each finding as: `[SEVERITY] file:line — Title` followed by description and suggestion.

### Step 4.2 — Generate Summary

Include: verdict, stats (files/errors/warnings/suggestions/nitpicks), key findings, positive observations, action items checklist.

**Verdict logic**:
- Any **error** -> REQUEST_CHANGES
- Only warnings/suggestions/nitpicks -> COMMENT (or APPROVE if minor)
- No findings -> APPROVE
- `--strict`: warnings also trigger REQUEST_CHANGES

### Step 4.3 — User Approval

Present full review and ask: "(1) submit as-is, (2) remove comments, (3) adjust severities, (4) cancel."

### Step 4.4 — Submit

```bash
gh pr review <pr-number> --<approve|request-changes|comment> --body "<summary>"
```

Inline comments via API:
```bash
gh api repos/{owner}/{repo}/pulls/<pr-number>/reviews \
  --method POST \
  --field event="<APPROVE|REQUEST_CHANGES|COMMENT>" \
  --field body="<summary>" \
  --field comments='[{"path": "<file>", "line": <N>, "body": "[<SEVERITY>] <comment>"}]'
```

### Step 4.5 — Report

Print verdict, comment counts by severity, and PR URL.

**Phase Output**: `.workflows/<pr-name>/04-comment.md`

---

## Error Handling

| Error | Resolution |
|---|---|
| PR not found | Verify PR number and repository |
| gh CLI not authenticated | Guide user through `gh auth login` |
| PR already merged | Report status, skip review |
| PR is draft | Review anyway, note draft status |
| Diff too large | Sub-agents per category, warn about PR size |
| Cannot determine file context | Read full file from head branch |
| API rate limit hit | Wait and retry, or batch comments |
| No checklist files found | Warn user, proceed with fallback checks |

## Review Principles

1. **Be constructive**: Every criticism includes a suggestion
2. **Be specific**: Exact lines, code examples
3. **Be proportional**: Don't block PRs for nitpicks
4. **Acknowledge good work**: Call out well-written code
5. **Focus on behavior**: Correctness over style
6. **Consider context**: Hotfix vs. feature PR standards differ
7. **One comment per issue**: Don't combine concerns
