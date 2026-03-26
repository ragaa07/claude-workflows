---
name: learn
description: Captures successful workflow patterns, stores them with confidence scores, and surfaces relevant patterns in future brainstorming.
---

# Pattern Learning

## Command

```
/workflow:learn capture
/workflow:learn list
/workflow:learn apply <topic>
```

Extracts reusable patterns from completed workflows and stores them as JSON in `.workflows/learned/`. Patterns gain confidence through reuse and are surfaced during future brainstorming.

**Prerequisite**: Check that `learning.enabled` is `true` in `.claude/workflows.yml`. If disabled, inform the user and exit.

**Config**: `learning.enabled`, `learning.min_confidence` (default 0.5), `learning.storage` (default `.workflows/learned`).

---

## `capture` — Extract Patterns from Last Workflow

1. Find the most recent file in `.workflows/history/` and read its phase output documents.
2. Extract patterns: architecture decisions (BRAINSTORM/PLAN), implementation patterns (IMPLEMENT), testing strategies (TEST), problem resolutions (any phase).
3. Store each as JSON in `.workflows/learned/`:

```json
{
  "id": "<uuid>", "name": "<short name>",
  "category": "<architecture|implementation|testing|resolution>",
  "description": "<what and when to use>",
  "context": "<project type, language, framework>",
  "source_workflow": "<history filename>",
  "captured_at": "<ISO-8601>",
  "confidence": 0.5, "times_reused": 0,
  "tags": ["<tag1>", "<tag2>"]
}
```

Print: `Captured <N> patterns from <workflow-name>.`

---

## `list` — Show All Patterns

```
Learned Patterns (<N> total):
  [0.90] * event-driven-state — Use event-driven state for complex forms
         Category: architecture | Reused: 4 times | Tags: state, forms
  [0.50]   snapshot-testing — Compose snapshot tests for UI regression
         Category: testing | Reused: 0 times | Tags: compose, ui
  * = high confidence (>= 0.8)
```

Sort by confidence descending. Patterns below `min_confidence` shown dimmed.

---

## `apply <topic>` — Find Relevant Patterns

1. Load patterns from `.workflows/learned/`. Match by tag, name/description keywords, category.
2. Present top 5 ranked by relevance then confidence:

```
Patterns relevant to "<topic>":
  1. [0.90] event-driven-state — Use event-driven state for complex forms
  2. [0.65] retry-with-backoff — Exponential backoff for flaky API calls
Apply a pattern? (pick a number or skip)
```

3. If selected, increment `times_reused`, update confidence: `min(1.0, base + 0.1 * times_reused)`.
