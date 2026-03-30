---
name: review
description: Review a GitHub pull request by fetching changes, categorizing by architecture, checking against dynamically loaded checklists, and generating inline comments with severity levels.
---

# Code Review Workflow

```
/review <pr-number> [--strict] [--focus <area>]
```

- `--strict`: Treat warnings as errors
- `--focus <area>`: Prioritize checks matching area (security, performance, architecture, tests)

Four phases: **FETCH -> CATEGORIZE -> CHECK -> COMMENT**

> Follow orchestration Rules 0-1 for state and output.

---

## Phase 1: FETCH

**Goal**: Gather all PR data needed for review.

Detect repository: `gh repo view --json owner,name -q '.owner.login + "/" + .name'`

**Steps 1.1–1.4 are independent — execute in parallel.**

Fetch via `gh`: PR metadata (`gh pr view --json`), diff (`gh pr diff`), changed files, CI checks (flag failures), existing comments (to avoid duplicates). Read each changed file in FULL (not just diff) for context.

**Size Decision** (thresholds configurable via `review.size_thresholds` in `.workflows/config.yml`):
- **Small** (below `small` threshold, default 10 files): Review inline
- **Medium** (up to `medium` threshold, default 30 files): Review by category
- **Large** (above medium threshold): Search per category, warn PR should be split
- **Extra-large** (>50 files or >1000 lines): Recommend user split PR before review

**>> Write output to**: `.workflows/<pr-name>/01-fetch.md`.

---

## Phase 2: CATEGORIZE

**Goal**: Organize changes by architectural layer.

**2.1 — Classify files** by reading `project.type` from `.workflows/config.yml`. Common categories:

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

**>> Write output to**: `.workflows/<pr-name>/02-categorize.md`.

---

## Phase 3: CHECK

**Goal**: Review each file against dynamically loaded quality checklists.

**Load checklists**: Always `${CLAUDE_PLUGIN_ROOT}/reviews/general-checklist.md` + language-specific (from `project.language` config). No checklists found -> warn, use fallback checks.

**Apply focus**: If `--focus` provided, weight matching violations higher. Still run all checks.

**Fallback checks** (no checklist files): Architecture (layer boundaries, deps), Code Quality (naming, function size, duplication, error handling), Security (no secrets, input validation), Performance (no blocking/N+1, caching), Test Coverage (new APIs tested, edge cases), Consistency (matches codebase patterns).

**Execute**: For each changed file, check ALL loaded items. Record violations with: severity (error/warning/suggestion/nitpick), file+line, issue description, actionable suggestion.

**>> Write output to**: `.workflows/<pr-name>/03-check.md`.

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

**4.1 Compile**: Format as `[SEVERITY] file:line — Title` with description and suggestion.

**4.2 Summary**: Verdict, stats, key findings, positive observations, action items.

**Verdict**: error -> REQUEST_CHANGES | warnings only -> COMMENT (or APPROVE if minor) | none -> APPROVE | `--strict`: warnings also REQUEST_CHANGES.

**4.3 User Approval**: "(1) submit as-is, (2) remove comments, (3) adjust severities, (4) cancel."

**4.4 Submit**: `gh pr review` for verdict + `gh api` for inline comments.

**4.5 Report**: Print verdict, counts by severity, PR URL.

**>> Write output to**: `.workflows/<pr-name>/04-comment.md`.

**After this final phase**: Move `.workflows/current-state.md` to `.workflows/history/<pr-name>-<YYYY-MM-DD>.md`. Report completion.

---

## Error Handling

| Error | Resolution |
|---|---|
| PR not found | Verify PR number and repository |
| gh CLI not authenticated | Guide user through `gh auth login` |
| PR already merged | Report status, skip review |
| PR is draft | Review anyway, note draft status |
| Diff too large | Search per category, warn about PR size |
| Cannot determine file context | Read full file from head branch |
| API rate limit hit | Wait and retry, or batch comments |
| No checklist files found | Warn user, proceed with fallback checks |

## Review Principles

Be constructive (include suggestions), specific (exact lines), proportional (don't block for nitpicks). Acknowledge good work. Focus on behavior over style. Consider context (hotfix vs feature). One comment per issue.
