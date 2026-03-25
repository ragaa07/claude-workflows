---
name: metrics
description: Tracks and reports workflow execution metrics including run counts, REPLAN frequency, brainstorm technique usage, and lessons generated.
---

# Workflow Metrics

Tracks and reports metrics across all workflow executions. Invoked with `/workflow:metrics`.

## Command

`/workflow:metrics` — Gather and display workflow execution statistics.

## Process

### Step 1: Gather Data

1. Read `.workflows/history/` directory for all completed workflow records
2. Read `.workflows/current-state.md` for any active workflow in progress
3. Read `.workflows/specs/` for decision documents (brainstorm technique usage)
4. Read `tasks/lessons.md` for lessons generated count and categories

### Step 2: Calculate Statistics

For each workflow type (`new-feature`, `extend-feature`, `refactor`, `hotfix`, `test`, `migrate`, `ci-fix`, `release`):

- **Runs**: Total number of times the workflow was started
- **Completed**: Number of runs that reached the final phase
- **REPLANs**: Number of times a REPLAN was triggered during execution
- **Avg Sessions**: Average number of session resumptions per run

Additional calculations:

- **REPLAN reasons**: Parse REPLAN entries to categorize common reasons (scope change, blocker found, user feedback, test failure, CI failure)
- **Brainstorm technique usage**: Count how many times each technique was used and how often the technique's recommended option was chosen
- **Lessons generated**: Total count and most common category

### Step 3: Write Metrics File

Write or update `.workflows/metrics.md` with the gathered statistics using the template format below.

### Step 4: Present to User

Display the key metrics in a concise summary:

1. Show the summary table
2. Highlight any notable trends (e.g., high REPLAN rate, underused techniques)
3. If REPLAN rate is above 30%, suggest reviewing spec quality
4. If a brainstorm technique is never used, mention it as available

## Metrics File Template

Write to `.workflows/metrics.md`:

```markdown
# Workflow Metrics

Last updated: {date}

## Summary

| Workflow | Runs | Completed | REPLANs | Avg Sessions |
|----------|------|-----------|---------|--------------|
| new-feature | 0 | 0 | 0 | - |
| extend-feature | 0 | 0 | 0 | - |
| refactor | 0 | 0 | 0 | - |
| hotfix | 0 | 0 | 0 | - |
| test | 0 | 0 | 0 | - |
| migrate | 0 | 0 | 0 | - |
| ci-fix | 0 | 0 | 0 | - |
| release | 0 | 0 | 0 | - |

## REPLAN Log

| Date | Workflow | Feature | Reason |
|------|----------|---------|--------|

## Brainstorm Usage

| Technique | Times Used | Chosen Rate |
|-----------|-----------|-------------|
| trade-off-matrix | 0 | - |
| six-thinking-hats | 0 | - |
| scamper | 0 | - |
| reverse-brainstorm | 0 | - |
| constraint-mapping | 0 | - |

## Lessons Generated

Total: 0
Most common category: -
```

## Data Sources

| Data Point | Source File | How to Parse |
|------------|-----------|--------------|
| Workflow runs | `.workflows/history/*.md` | Count files per workflow type |
| Completion status | `.workflows/history/*.md` | Check for final phase marker |
| REPLAN events | `.workflows/history/*.md` | Search for `REPLAN` entries with reason |
| Active workflow | `.workflows/current-state.md` | Read current phase and workflow type |
| Brainstorm usage | `.workflows/specs/*.decisions.md` | Parse `Techniques` field in header |
| Lessons count | `tasks/lessons.md` | Count entries and categorize |

## Edge Cases

- If `.workflows/history/` does not exist or is empty, report all zeros and note that no workflows have been executed yet
- If files are malformed, skip them and note the count of skipped files
- Active workflows count toward "Runs" but not "Completed"
