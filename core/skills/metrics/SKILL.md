---
name: metrics
description: Tracks and reports workflow execution metrics — completion rates, durations, failure points, and per-workflow stats.
---

# Workflow Metrics

```
/workflow:metrics
/workflow:metrics <workflow-name>
```

Analyzes workflow history files in `.workflows/history/` to produce execution metrics.

---

## `/workflow:metrics` — Summary Dashboard

Read all files in `.workflows/history/`. Extract workflow type, feature, timestamps, phase history, and outcome. Display:

```
Workflow Metrics Dashboard
===================================
  Total workflows:     <N>
  Completion rate:     <N>% (<completed>/<total>)
  Average duration:    <N>h <N>m
  Most used workflow:  <name> (<N> runs)
  Common failure at:   <phase> (<N> times)
  This week: <N>  |  This month: <N>

  By Workflow Type:
  ----------------------------------
  new-feature     ========..  8 runs  (75% success)
  hotfix          ====......  4 runs  (100% success)
  refactor        ==........  2 runs  (50% success)
```

---

## `/workflow:metrics <workflow-name>` — Per-Workflow Detail

Filter history to matching workflow type:

```
Metrics: <workflow-name>
===================================
  Runs: <N>  |  Completed: <N>  |  Failed: <N>  |  Abandoned: <N>
  Avg duration: <N>h <N>m  |  Fastest: <N>h <N>m  |  Slowest: <N>h <N>m

  Phase Breakdown:
  ----------------------------------
  ANALYZE       avg <N>m   <N>/<N> completed
  BRAINSTORM    avg <N>m   <N>/<N> completed  (skipped: <N>)
  PLAN          avg <N>m   <N>/<N> completed
  IMPLEMENT     avg <N>m   <N>/<N> completed  <- most failures
  TEST          avg <N>m   <N>/<N> completed

  Recent Runs:
  ----------------------------------
  <date>  <feature>   COMPLETED  <duration>
  <date>  <feature>   FAILED     <duration>  (failed at IMPLEMENT)
```

If no history files exist, print: `No workflow history found. Complete a workflow to start tracking metrics.` Skip corrupt files with a warning.
