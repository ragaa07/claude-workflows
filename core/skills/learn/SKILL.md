---
name: learn
description: Extract patterns from completed workflows and store as learned knowledge for future brainstorming and planning phases.
---

# Auto-Learning

Captures patterns from completed workflows to inform future decisions.

## When Learning Runs

1. **Automatic**: After every workflow reaches DONE phase
2. **Manual**: User invokes `/workflow:learn`

## What Gets Captured

### From Completed Workflows

Read `.workflows/history/` and extract:

1. **Architecture Decisions**
   - Which brainstorm technique was used
   - Which option was chosen and why
   - What trade-offs were accepted

2. **Implementation Patterns**
   - Feature scope (files created/modified count)
   - Which implementation phases took longest (from timestamps)
   - Whether REPLAN was triggered and why
   - Which project skills were invoked

3. **Reuse Patterns**
   - Components reused from existing codebase
   - Patterns that worked (Delegator, single VM, etc.)
   - API patterns (response structure, error handling)

### From Lessons

Read `tasks/lessons.md` and categorize:
- API patterns (nullable fields, response structure)
- Build patterns (variants, commands)
- Architecture patterns (ViewModel init, state management)
- UI patterns (Compose, navigation)

## Storage

Write learned patterns to `.workflows/learned/patterns.json`:

```json
{
  "version": "1.0",
  "last_updated": "2026-03-25",
  "patterns": [
    {
      "id": "p001",
      "type": "architecture",
      "pattern": "Delegator pattern for features with >3 state sources",
      "confidence": 0.8,
      "occurrences": 3,
      "source_workflows": ["booking-cancellation", "search-redesign", "favorites"],
      "context": "When ViewModel manages multiple independent state flows"
    },
    {
      "id": "p002",
      "type": "decision",
      "pattern": "BottomSheet preferred over full screen for secondary flows",
      "confidence": 0.75,
      "occurrences": 3,
      "source_workflows": ["booking-cancellation", "report-ad", "share-listing"]
    }
  ],
  "technique_stats": {
    "trade-off-matrix": {"used": 8, "chosen_winner": 6},
    "six-thinking-hats": {"used": 4, "chosen_winner": 3},
    "scamper": {"used": 2, "chosen_winner": 2}
  },
  "replan_reasons": [
    {"reason": "API contract mismatch", "count": 3},
    {"reason": "Navigation pattern incorrect", "count": 2}
  ]
}
```

## How Patterns Are Used

### During BRAINSTORM Phase

Before generating options, read `.workflows/learned/patterns.json`:
- Surface relevant patterns: "In 3 previous features with similar scope, Delegator pattern was chosen"
- Show technique stats: "Trade-off Matrix has been most effective (75% chosen rate)"
- Warn about common REPLAN reasons: "API contract mismatches caused 3 REPLANs — verify API contract early"

### During PLAN Phase

- Suggest file structure based on similar features
- Warn about patterns that caused REPLANs
- Estimate complexity based on historical data

### Confidence Scoring

| Occurrences | Confidence | Treatment |
|-------------|-----------|-----------|
| 1 | 0.3 | Store but don't surface |
| 2 | 0.5 | Mention if relevant |
| 3+ | 0.75+ | Recommend actively |
| 5+ | 0.9+ | Strong recommendation |

Confidence increases by 0.1 per successful use, decreases by 0.2 per REPLAN caused.

## Manual Learning

`/workflow:learn` without a completed workflow:
1. Ask user: "What pattern did you learn?"
2. Categorize: architecture, decision, implementation, avoid
3. Add to patterns.json with confidence 0.5
4. Confirm: "Learned: {pattern}. Will surface in future brainstorms."
