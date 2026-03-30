---
name: metrics
description: Workflow execution metrics from telemetry data — completion rates, durations, bottlenecks, and trends.
rules: []
---

# Workflow Metrics

```
/metrics
/metrics <workflow-name>
/metrics trends
```

**Data source**: `.workflows/telemetry.jsonl` (primary). Falls back to `.workflows/history/` if telemetry is empty.

---

## `/metrics` — Summary Dashboard

Read `.workflows/telemetry.jsonl`. Parse each JSON line. Aggregate:

```
Workflow Metrics
═══════════════════════════════════════
  Total workflows:     <N>
  Completion rate:     <N>% (<completed>/<total>)
  Avg duration:        <N>h <N>m
  Most used:           <name> (<N> runs)
  Bottleneck phase:    <phase> (avg <N>m, <N>% of total time)
  This week: <N>  |  This month: <N>

  By Workflow:
  ──────────────────────────────────────
  new-feature     ████████░░  8 runs  75% success  avg 2.1h
  hotfix          ████░░░░░░  4 runs  100% success avg 0.3h
  refactor        ██░░░░░░░░  2 runs  50% success  avg 3.5h
```

## `/metrics <workflow-name>` — Per-Workflow Detail

Filter telemetry to matching workflow:

```
Metrics: new-feature
═══════════════════════════════════════
  Runs: <N>  |  Completed: <N>  |  Failed: <N>
  Avg: <N>h  |  Fastest: <N>h  |  Slowest: <N>h

  Phase Breakdown:
  ──────────────────────────────────────
  GATHER      avg 5m    ████░░  8/8
  SPEC        avg 12m   ████░░  8/8
  BRAINSTORM  avg 8m    ███░░░  6/8  (skipped: 2)
  PLAN        avg 15m   ████░░  8/8
  IMPLEMENT   avg 45m   ██████  8/8  ← slowest
  TEST        avg 10m   ████░░  7/8
  PR          avg 3m    ██░░░░  7/8
```

## `/metrics trends` — Trend Analysis

Compare last 10 workflows vs previous 10:

```
Trends (last 10 vs previous 10):
  Duration:     ↓ 15% faster (avg 1.8h vs 2.1h)
  Success rate: ↑ 10% (90% vs 80%)
  REPLANs:      ↓ 40% fewer (3 vs 5)
  Skipped phases: BRAINSTORM skipped 60% — consider disabling
```

If fewer than 5 workflows in history: "Not enough data for trends. Complete more workflows."

## Fallback

If `telemetry.jsonl` is empty or missing, read `.workflows/history/*.md` files. Parse frontmatter for workflow type, timestamps, and phase history. Note reduced accuracy in output.

If no data at all: "No workflow history found. Complete a workflow to start tracking."

Cross-project metrics are also written to `${CLAUDE_PLUGIN_DATA}/usage-stats.json` for aggregated insights across all projects using this plugin.
