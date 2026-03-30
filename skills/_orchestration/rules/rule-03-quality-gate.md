# Rule 3: Quality Gate — Rules & Reviews

**Before writing code** in any implementation phase:

1. Determine project type from `.workflows/config.yml` → `project.type`. Fall back to user plugin settings.
2. Read language rules from `<plugin-root>/rules/` based on project type:

   | project_type | Files to read from `<plugin-root>/rules/` |
   |---|---|
   | android | `kotlin.md`, `compose.md` |
   | react | `typescript.md`, `react.md` |
   | python | `python.md` |
   | swift | `swift.md` |
   | go | `go.md` |
   | rust | (skip — no bundled rules; use `generic` conventions) |
   | generic | (skip) |

3. If team is set, also read: `<plugin-root>/teams/<team>/rules/team-conventions.md`
4. Follow every DO/DON'T while implementing.

**Before creating a PR** (every workflow that ends with PR):

1. Run `git diff --name-only <base>..HEAD` to identify changed files.
2. **Proportional review** — scale the gate to the change size:

   | Change Size | Gate Level |
   |---|---|
   | ≤3 files, ≤50 lines | **Light**: Security checks (Critical items only) from general checklist. Skip language-specific checklists. |
   | 4-15 files | **Standard**: General checklist (High + Critical items) + language-specific checklist (High + Critical). |
   | >15 files | **Full**: All checklists, all severity levels. |

3. If team is set, also read: `<plugin-root>/teams/<team>/reviews/team-review-checklist.md`
4. Self-check changes against applicable items. For each Critical/High item, record an explicit verdict:
   - `PASS: <item> — <evidence>` (e.g., "no hardcoded secrets — grep for API key patterns returned 0 results")
   - `FAIL: <item> — <issue> — <fix>`
   - `N/A: <item> — <reason>`

**Minimum evidence**: Every Critical item needs explicit evidence — grep results, test output, or code inspection finding. "Checked" or "no issues found" without specifics is unacceptable.

5. Fix any Critical/High violations before creating the PR. Report Medium/Low as notes in the PR body.
