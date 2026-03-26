---
name: learn
description: Captures successful workflow patterns, stores them with confidence scores, and surfaces relevant patterns in future brainstorming.
---

# Pattern Learning

```
/learn capture
/learn list
/learn apply <topic>
```

Extracts reusable patterns from completed workflows, stores as markdown in `.workflows/learned/`. Patterns gain confidence through reuse.

**Prerequisite**: `learning.enabled` must be `true` in `.claude/workflows.yml`. If disabled, inform user and exit.
**Config**: `learning.min_confidence` (default 0.5), `learning.storage` (default `.workflows/learned`).

---

## `/learn capture` — Extract Patterns from Last Workflow

1. Find the most recent file in `.workflows/history/` and read its phase output documents.
2. Extract patterns: architecture decisions (BRAINSTORM/PLAN), implementation patterns (IMPLEMENT), testing strategies (TEST), problem resolutions (any phase).
3. Store each as a markdown file in `.workflows/learned/<pattern-name>.md`:

```markdown
# Pattern: <name>
Category: <architecture|implementation|testing|resolution>
Confidence: 0.5
Reused: 0 times
Tags: <tag1>, <tag2>

## Description
<what and when to use>

## Source
<history filename>
```

Print: `Captured <N> patterns from <workflow-name>.`

---

## `/learn list` — Show All Patterns

Read all `.md` files in `.workflows/learned/`. Sort by confidence descending:

```
Learned Patterns (<N> total):
  [0.90] * event-driven-state — Use event-driven state for complex forms
         Category: architecture | Reused: 4 | Tags: state, forms
  [0.50]   snapshot-testing — Compose snapshot tests for UI regression
  * = high confidence (>= 0.8). Below min_confidence shown dimmed.
```

---

## `/learn apply <topic>` — Find Relevant Patterns

1. Load patterns from `.workflows/learned/`. Match by tag, name/description keywords, category.
2. Present top 5 by relevance then confidence:

```
Patterns relevant to "<topic>":
  1. [0.90] event-driven-state — Use event-driven state for complex forms
  2. [0.65] retry-with-backoff — Exponential backoff for flaky API calls
Apply a pattern? (pick number or skip)
```

3. If selected, increment `Reused` in the file, update confidence: `min(1.0, base + 0.1 * times_reused)`.
