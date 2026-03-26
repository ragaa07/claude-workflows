---
name: brainstorm
description: Explore implementation approaches using structured techniques (trade-off matrix, six thinking hats, SCAMPER, reverse brainstorm, constraint mapping), then evaluate and recommend the best option.
---

# Brainstorm Workflow

## Command

```
/workflow:brainstorm <--topic "description"> [--depth <quick|standard|deep>]
```

- `--topic` (required): Problem or feature to brainstorm approaches for.
- `--depth`: `quick`, `standard` (default), or `deep`.

## Overview

Generate, evaluate, and recommend implementation approaches. Three phases: **EXPLORE -> EVALUATE -> RECOMMEND**. Can run standalone or delegated from other workflows (receives spec/context as input).

## Depth Levels

| Depth | Options | Techniques |
|---|---|---|
| `quick` | 2 | Trade-off Matrix only |
| `standard` | 3 | 1 technique + Trade-off Matrix |
| `deep` | 4+ | Multiple techniques + Trade-off Matrix |

Read depth from `--depth` flag, falling back to `workflows.brainstorm.default_depth` in `.claude/workflows.yml`.

## Techniques

### 1. Trade-off Matrix
Score each option 1-5 against weighted criteria. Multiply by weight. Highest total wins. Used in ALL depth levels during Phase 2.

**Default weights**: Complexity (3), Maintainability (3), Risk (3), Performance (2), Testability (2), Time-to-implement (2), Extensibility (1).

### 2. Six Thinking Hats
Analyze through six lenses: White (facts/data gaps), Red (intuition/gut feel), Black (risks/worst-case), Yellow (benefits/best-case), Green (creative/unconventional ideas), Blue (process fit). Best for strategic/architectural decisions.

### 3. SCAMPER
Generate alternatives by applying: Substitute (swap components), Combine (merge approaches), Adapt (borrow from other domains), Modify (change scale/scope), Put to other use (repurpose existing code), Eliminate (simplify), Rearrange (reorder/invert). Best for feature design and creative problem-solving.

### 4. Reverse Brainstorm
Enumerate all failure modes (crashes, performance, maintenance, edge cases). Invert each into a prevention requirement. Use the prevention list as constraints for viable options. Best for risk-heavy or safety-critical features.

### 5. Constraint Mapping
Separate hard constraints (non-negotiable: API compat, security, platform) from soft constraints (preferred: code style, library choice, architecture). Eliminate options violating hard constraints. Rank by soft constraint satisfaction. **Always runs as pre-analysis in Phase 1, regardless of depth.**

---

## Phase 1: EXPLORE

**Goal**: Generate distinct implementation options.

### 1.1 — Gather Context

- **Delegated**: Read the spec/context document. Identify core problem, constraints, goals.
- **Standalone**: Parse `--topic`. Scan codebase for related patterns and conventions. Ask clarifying questions if ambiguous.

### 1.2 — Constraint Mapping (always runs)

Identify hard constraints (must) and soft constraints (should) before generating options.

### 1.3 — Generate Options

- **Quick**: 2 options via direct analysis — most obvious + one alternative.
- **Standard**: Select 1 technique (Six Thinking Hats, SCAMPER, or Reverse Brainstorm) based on problem type. Generate 3 options. Only use techniques listed in `workflows.brainstorm.techniques` from `.claude/workflows.yml`.
- **Deep**: Apply multiple techniques. Generate 4+ options.

### 1.4 — Document Options

For each option: name, 1-2 sentence summary, technical approach, key trade-off, effort level (low/medium/high).

### Decision Point

Discard options violating hard constraints. If fewer than 2 viable options remain, generate more.

**Phase Output**: `.workflows/<topic>/01-explore.md`

---

## Phase 2: EVALUATE

**Goal**: Score and compare all viable options.

### 2.1 — Build Trade-off Matrix

Score each option 1-5 per criterion, multiply by weight, sum totals. Present as table with raw scores and weighted scores.

### 2.2 — Analyze Results

For each option: highlight top 2 and bottom 2 criteria. Flag any score of 1-2 as a potential deal-breaker.

### 2.3 — Depth-Specific Analysis

- **Quick**: Matrix is sufficient.
- **Standard**: Reverse Brainstorm the top 3 failure modes for the leading option. Confirm mitigations exist.
- **Deep**: Apply Six Thinking Hats to the top 2 options. Confirm matrix ranking holds after qualitative analysis.

**Phase Output**: `.workflows/<topic>/02-evaluate.md`

---

## Phase 3: RECOMMEND

**Goal**: Present recommendation and get user confirmation.

### 3.1 — Present Recommendation

Include: recommended option with score, top 3 reasons (tied to highest-weighted criteria), accepted trade-offs, risks with mitigations.

### 3.2 — Comparison Summary

Side-by-side table of all options: score, effort, risk, best-for. Mark the recommended option.

### 3.3 — Get User Decision

Ask: "Proceed with Option X? You can: (1) accept, (2) pick a different option, (3) request deeper analysis, (4) suggest a hybrid approach."

- **Accept**: Finalize and output chosen approach.
- **Different option**: Switch recommendation, document rationale.
- **Deeper analysis**: Increase depth, re-run from Phase 1.
- **Hybrid**: Combine elements from multiple options, re-evaluate.

### 3.4 — Output

Return: chosen approach name, rationale, constraints satisfied, key risks with mitigations, next steps. When delegated, this output feeds directly into the calling workflow's next phase.

**Phase Output**: `.workflows/<topic>/03-recommend.md`

---

## Error Handling

| Error | Resolution |
|---|---|
| Topic too vague | Ask user for clarification before generating options |
| All options violate a hard constraint | Re-examine constraints with user — are they truly hard? |
| Scores are tied | Use risk as tiebreaker (lower risk wins) |
| User rejects all options | Ask what is missing, generate new options with adjusted constraints |
| Delegated without context | Request spec or context from calling workflow |
