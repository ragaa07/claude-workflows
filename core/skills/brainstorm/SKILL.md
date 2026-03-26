---
name: brainstorm
description: Explore implementation approaches using structured techniques (trade-off matrix, six thinking hats, SCAMPER, reverse brainstorm, constraint mapping), then evaluate and recommend the best option.
---

# Brainstorm Workflow

## Command

```
/workflow:brainstorm <--topic "description"> [--depth <quick|standard|deep>]
```

**Options**:
- `--topic`: The problem or feature to brainstorm approaches for (required)
- `--depth`: Analysis depth — `quick`, `standard` (default), or `deep`

## Overview

Generates, evaluates, and recommends implementation approaches using structured brainstorming techniques. Three phases: **EXPLORE -> EVALUATE -> RECOMMEND**.

Can be invoked standalone or delegated from other workflows (e.g., `new-feature` Phase 3, `refactor` Phase 2). When delegated, receives the spec or context document as input.

---

## Depth Levels

| Depth | Options Generated | Techniques Used |
|---|---|---|
| `quick` | 2 | Trade-off Matrix only |
| `standard` | 3 | 1 primary technique + Trade-off Matrix |
| `deep` | 4+ | Multiple techniques + Trade-off Matrix |

Read depth from `--depth` flag, falling back to `workflows.brainstorm.default_depth` in `.claude/workflows.yml` (defaults to `standard`).

---

## Techniques Reference

### 1. Trade-off Matrix
Score each option against weighted criteria. Used in ALL depth levels during Phase 2.

**Criteria** (default weights):
| Criterion | Weight | Description |
|---|---|---|
| Complexity | 3 | How hard is it to understand and implement? |
| Maintainability | 3 | How easy to change and debug over time? |
| Performance | 2 | Runtime efficiency and resource usage |
| Testability | 2 | How easy to write meaningful tests? |
| Time-to-implement | 2 | Development effort required |
| Risk | 3 | Likelihood of unforeseen problems |
| Extensibility | 1 | How well does it support future requirements? |

Score each option 1-5 per criterion (5 = best). Multiply by weight. Highest total wins.

### 2. Six Thinking Hats
Analyze the problem through six perspectives:

- **White Hat (Facts)**: What data and information do we have? What is missing?
- **Red Hat (Intuition)**: What does gut feeling say? First impressions of each option?
- **Black Hat (Risks)**: What could go wrong? Worst-case scenarios?
- **Yellow Hat (Benefits)**: What is the best-case outcome? Key advantages?
- **Green Hat (Creativity)**: Are there unconventional approaches? Can we combine ideas?
- **Blue Hat (Process)**: Which option best fits our workflow and constraints?

### 3. SCAMPER
Generate alternatives by applying each lens to the initial approach:

- **Substitute**: What component/library/pattern could replace part of this?
- **Combine**: Can two approaches be merged into one?
- **Adapt**: What similar solution from another domain applies here?
- **Modify**: What if we change the scale, scope, or interface?
- **Put to other use**: Can existing code serve this purpose with minor changes?
- **Eliminate**: What can we remove to simplify?
- **Rearrange**: What if we reorder the steps or invert the dependency?

### 4. Reverse Brainstorm
List all the ways the implementation could fail, then invert each into a solution:

1. Enumerate failure modes (crashes, performance, maintenance burden, edge cases)
2. For each failure mode, define what the implementation MUST do to prevent it
3. Use the prevention list as requirements for viable options

### 5. Constraint Mapping
Separate hard constraints from soft constraints:

- **Hard (must)**: Non-negotiable requirements (API compatibility, platform support, security)
- **Soft (should)**: Preferred but flexible (code style, library choice, architecture pattern)

Eliminate any option that violates a hard constraint. Rank remaining options by how many soft constraints they satisfy.

---

## Phase 1: EXPLORE

**Goal**: Generate a set of distinct implementation options using the appropriate techniques for the selected depth.

### Step 1.1 — Gather Context

If delegated from another workflow:
- Read the spec document or context passed as input
- Identify the core problem, constraints, and goals

If invoked standalone:
- Parse the `--topic` description
- Scan the codebase for related patterns, existing implementations, and conventions
- Ask clarifying questions if the topic is ambiguous

### Step 1.2 — Apply Constraint Mapping

**Note**: Constraint Mapping is always applied as a pre-analysis step (Step 1.2) regardless of depth level. It is not counted as one of the selected techniques.

Identify constraints before generating options (applies at all depth levels):

```
Hard Constraints (must):
  - <constraint 1>
  - <constraint 2>

Soft Constraints (should):
  - <constraint 1>
  - <constraint 2>
```

### Step 1.3 — Generate Options

Apply techniques based on depth:

**Quick**: Generate 2 options using direct analysis. Focus on the most obvious and one alternative approach.

**Standard**: Select 1 primary technique (Six Thinking Hats, SCAMPER, or Reverse Brainstorm — whichever best fits the problem type). Generate 3 distinct options.

Selection guidance:
- **Six Thinking Hats**: Best for strategic/architectural decisions requiring multiple perspectives
- **SCAMPER**: Best for feature design and creative problem-solving
- **Reverse Brainstorm**: Best for risk-heavy problems or safety-critical features

Only use techniques listed in `workflows.brainstorm.techniques` from `.claude/workflows.yml`.

**Deep**: Apply multiple techniques. Use Reverse Brainstorm to identify failure modes, Six Thinking Hats for multi-perspective analysis, and SCAMPER to generate creative alternatives. Produce 4+ options.

### Step 1.4 — Document Options

For each option, document:

```
Option <letter>: <name>
  Summary: <1-2 sentence description>
  Approach: <technical approach details>
  Key trade-off: <the main thing you give up>
  Effort: <low | medium | high>
```

### Decision Point: Option Viability

Discard any option that violates a hard constraint. If fewer than 2 viable options remain, generate more.

**Phase Output**: Write generated options and analysis to `.workflows/<topic>/01-explore.md`

---

## Phase 2: EVALUATE

**Goal**: Score and compare all viable options using the Trade-off Matrix.

### Step 2.1 — Build Trade-off Matrix

Score each option against all weighted criteria:

```
                    Weight   Option A   Option B   Option C
Complexity            3       4 (12)     3 (9)      5 (15)
Maintainability       3       3 (9)      4 (12)     4 (12)
Performance           2       5 (10)     3 (6)      4 (8)
Testability           2       4 (8)      5 (10)     3 (6)
Time-to-implement     2       2 (4)      4 (8)      3 (6)
Risk                  3       3 (9)      4 (12)     2 (6)
Extensibility         1       4 (4)      3 (3)      5 (5)
                             ------     ------     ------
Total                          56         60         58
```

### Step 2.2 — Analyze Results

For each option:
- Highlight strongest criteria (top 2 scores)
- Highlight weakest criteria (bottom 2 scores)
- Note any criterion scored 1-2 (potential deal-breaker)

### Step 2.3 — Apply Depth-Specific Analysis

**Quick**: Matrix is sufficient. Proceed to Phase 3.

**Standard**: Add a brief Reverse Brainstorm — list the top 3 failure modes for the leading option and confirm mitigations exist.

**Deep**: Apply Six Thinking Hats to the top 2 options. Document findings per hat. Confirm the matrix ranking holds after qualitative analysis.

**Phase Output**: Write trade-off matrix and scoring to `.workflows/<topic>/02-evaluate.md`

---

## Phase 3: RECOMMEND

**Goal**: Present the recommended approach and get user confirmation.

### Step 3.1 — Present Recommendation

```
Recommendation: Option <letter> — <name>

Score: <total> / <max possible>

Why this option:
  - <reason 1 based on highest-weighted criteria>
  - <reason 2>
  - <reason 3>

Trade-offs accepted:
  - <what you give up and why it is acceptable>

Risks and mitigations:
  - <risk>: <mitigation>
```

### Step 3.2 — Show Comparison Summary

Present all options side by side:

```
Option   Score   Effort   Risk    Best For
A        56      High     Medium  Maximum performance
B        60      Low      Low     Fastest delivery      <- recommended
C        58      Medium   High    Best extensibility
```

### Step 3.3 — Get User Decision

Ask: "Proceed with Option <letter>? You can: (1) accept, (2) pick a different option, (3) request deeper analysis, (4) suggest a hybrid approach."

### Decision Point: User Confirmation

- **Accept**: Finalize and output the chosen approach
- **Different option**: Switch recommendation, document rationale
- **Deeper analysis**: Increase depth level and re-run from Phase 1
- **Hybrid**: Combine elements from multiple options, re-evaluate

### Step 3.4 — Output

Return the chosen approach with full rationale:

```
Chosen Approach: <name>
Rationale: <why this was selected>
Constraints satisfied: <list>
Key risks: <list with mitigations>
Next steps: <what the calling workflow should do with this>
```

When delegated from another workflow, this output feeds directly into the next phase (e.g., PLAN in `new-feature`, DESIGN in `refactor`).

**Phase Output**: Write recommendation with justification to `.workflows/<topic>/03-recommend.md`

---

## Error Handling

| Error | Resolution |
|---|---|
| Topic too vague | Ask user for clarification before generating options |
| All options violate a hard constraint | Re-examine constraints with user — are they truly hard? |
| Scores are tied | Use risk as tiebreaker (lower risk wins) |
| User rejects all options | Ask what is missing, generate new options with adjusted constraints |
| Delegated without context | Request spec or context from calling workflow |
