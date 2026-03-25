---
name: brainstorm
description: Structured technical brainstorming with Six Thinking Hats, SCAMPER, Trade-off Matrix, Reverse Brainstorm, and Constraint Mapping techniques.
---

# Brainstorm

Structured technical brainstorming skill. Can be invoked standalone (`/workflow:brainstorm <topic>`) or as part of a workflow's BRAINSTORM phase.

## Configuration

Read from `.claude/workflows.yml` under `workflows.brainstorm`:

```yaml
brainstorm:
  default_depth: "standard"    # quick | standard | deep
  techniques:
    - "trade-off-matrix"
    - "six-thinking-hats"
    - "scamper"
    - "reverse-brainstorm"
    - "constraint-mapping"
```

## Depth Levels

| Level | Options Generated | Techniques Used | When to Use |
|-------|------------------|-----------------|-------------|
| `quick` | 2 | Trade-off Matrix only | Small decisions, time-sensitive |
| `standard` | 3 | 1 primary technique + Trade-off Matrix | Most features and refactors |
| `deep` | 4+ | Multiple techniques + Trade-off Matrix | Architecture decisions, high-risk changes |

The user can override depth: `/workflow:brainstorm --depth deep <topic>`

## Process

### Step 1: Context Gathering

Before brainstorming, understand the codebase context:

1. Read the spec document if one exists (`.workflows/specs/<feature-name>.spec.md`)
2. Use sub-agents (Explore tool) to analyze relevant code:
   - Identify existing patterns that relate to the problem
   - Find similar implementations in the codebase
   - Map dependencies and integration points
3. Summarize findings as constraints and context for brainstorming

### Step 2: Generate Options

Based on the depth level, generate the required number of distinct implementation approaches. Each option must include:

- **Name**: Short, descriptive label
- **Description**: 2-3 sentence summary of the approach
- **Key characteristics**: Architecture pattern, complexity, dependencies
- **Estimated effort**: T-shirt size (S/M/L/XL)

### Step 3: Apply Techniques

Apply the configured techniques to analyze the options (see detailed technique instructions below).

### Step 4: Produce Decision Document

Write the decision document to `.workflows/specs/<feature-name>.decisions.md`.

---

## Technique: Six Thinking Hats

Analyze each option through six distinct perspectives. Present the analysis for the TOP options (not all combinations).

### White Hat (Facts & Data)
What do we know objectively?
- Lines of code affected (estimate)
- Number of files changed
- Dependencies introduced or removed
- Performance characteristics (Big-O, memory)
- Existing test coverage of affected areas

### Red Hat (Feelings & Intuition)
Gut reactions without justification:
- How does this feel to maintain?
- First impression on complexity
- Team comfort level with the approach
- "Smell test" -- does this feel right?

### Black Hat (Risks & Caution)
What could go wrong?
- Breaking changes
- Edge cases that are hard to handle
- Maintenance burden over time
- Security implications
- Performance bottlenecks

### Yellow Hat (Benefits & Optimism)
What are the advantages?
- Code clarity improvements
- Reusability gains
- Performance improvements
- Developer experience improvements
- Future extensibility

### Green Hat (Creativity & Alternatives)
Can we combine or modify approaches?
- Hybrid solutions from multiple options
- Unconventional approaches not yet considered
- Phased implementation (start simple, evolve)
- Novel patterns from other domains

### Blue Hat (Process & Summary)
Meta-analysis:
- Which hat revealed the most important insights?
- What is the recommended option and why?
- What additional information would change the recommendation?

---

## Technique: SCAMPER

Apply each SCAMPER prompt to the problem space to generate ideas and variations.

### Substitute
What components, dependencies, or patterns can be substituted?
- Can we use a different data structure?
- Can we swap a library for a built-in solution?
- Can we replace inheritance with composition?

### Combine
What can be merged or integrated?
- Can two features share the same component?
- Can we combine multiple API calls into one?
- Can we merge similar classes or modules?

### Adapt
What existing solutions can be adapted?
- What patterns exist elsewhere in the codebase?
- What open-source solutions solve similar problems?
- What did other teams/projects do for this?

### Modify (Magnify/Minimize)
What can be enlarged, reduced, or changed in scale?
- Can we simplify by reducing scope?
- Can we make it more general-purpose?
- Can we change the granularity (finer/coarser)?

### Put to Another Use
Can existing code serve a different purpose?
- Can an existing utility be repurposed?
- Can test infrastructure be reused?
- Can we leverage existing APIs differently?

### Eliminate
What can be removed entirely?
- Are there unnecessary abstractions?
- Can we remove a dependency?
- Is there dead code or unused functionality?

### Rearrange (Reverse)
What happens if we change the order or structure?
- Can we invert the control flow?
- Can we process data in a different order?
- Can we restructure the module hierarchy?

---

## Technique: Trade-off Matrix

Used in ALL depth levels. This is the primary decision-making tool.

### Setup

1. **Define criteria** relevant to the decision:
   - Complexity (implementation difficulty)
   - Maintainability (long-term code health)
   - Performance (runtime efficiency)
   - Testability (ease of testing)
   - Time to implement (calendar time)
   - Risk (likelihood of issues)
   - Extensibility (future feature support)

2. **Assign weights** (1-5) to each criterion based on project priorities. Higher weight = more important.

3. **Score each option** (1-5) against each criterion. Higher score = better.

4. **Calculate weighted scores**: `weight x score` for each cell, then sum per option.

### Presentation Format

```
| Criterion       | Weight | Option A | Option B | Option C |
|-----------------|--------|----------|----------|----------|
| Complexity      | 4      | 4 (16)   | 2 (8)    | 3 (12)   |
| Maintainability | 5      | 3 (15)   | 5 (25)   | 4 (20)   |
| Performance     | 3      | 5 (15)   | 3 (9)    | 4 (12)   |
| Testability     | 4      | 3 (12)   | 4 (16)   | 4 (16)   |
| Time            | 3      | 4 (12)   | 2 (6)    | 3 (9)    |
| **Total**       |        | **70**   | **64**   | **69**   |
```

### Interpretation

- Clear winner (>10% gap): Recommend the winner with confidence
- Close race (<10% gap): Highlight the tie-breaking criteria and ask the user
- One option dominates on high-weight criteria: May override total score -- explain why

---

## Technique: Reverse Brainstorm

Instead of solving the problem, brainstorm ways to CAUSE failure. Then invert each failure into a mitigation strategy.

### Process

1. **Frame the reverse question**: "How could we make this feature fail spectacularly?"

2. **Generate failure modes** (aim for 5-8):
   - Data corruption scenarios
   - Race conditions and timing issues
   - Memory leaks or resource exhaustion
   - User experience failures
   - Integration breakages
   - Security vulnerabilities
   - Scale-related failures

3. **For each failure mode, define**:
   - **Cause**: What specifically would trigger this failure?
   - **Impact**: How bad is it? (Low/Medium/High/Critical)
   - **Likelihood**: How likely without mitigation? (Low/Medium/High)
   - **Mitigation**: What design decision prevents this?
   - **Detection**: How would we detect if it happened?

4. **Feed mitigations back** into the option evaluation. Options that naturally prevent more failure modes score higher.

---

## Technique: Constraint Mapping

Identify all constraints and use them to filter approaches before detailed analysis.

### Hard Constraints (Must satisfy -- non-negotiable)

These eliminate options that cannot meet them:
- Platform requirements (API level, OS version)
- Backward compatibility requirements
- Security/compliance requirements
- Performance SLAs or budgets
- Existing API contracts that cannot change
- Team skill set (no time to learn a new paradigm)

### Soft Constraints (Should satisfy -- negotiable)

These influence scoring but do not eliminate options:
- Code style preferences
- Preferred libraries or frameworks
- Desired architecture patterns
- Timeline preferences
- Technical debt reduction goals

### Mapping Process

1. List all constraints with their type (hard/soft)
2. For each option, check against hard constraints:
   - PASS: Option satisfies the constraint
   - FAIL: Option violates the constraint (option is eliminated)
3. For surviving options, score against soft constraints:
   - FULL: Fully satisfies
   - PARTIAL: Partially satisfies
   - MISS: Does not satisfy
4. Present the constraint map:

```
| Constraint              | Type | Option A | Option B | Option C |
|-------------------------|------|----------|----------|----------|
| API 24+ support         | Hard | PASS     | PASS     | FAIL     |
| No new dependencies     | Soft | FULL     | MISS     | --       |
| Under 500ms response    | Hard | PASS     | PASS     | --       |
| Match existing patterns | Soft | FULL     | PARTIAL  | --       |
```

Option C is eliminated (failed a hard constraint). Remaining options proceed to Trade-off Matrix.

---

## Decision Document Template

Write to `.workflows/specs/<feature-name>.decisions.md`:

```markdown
# <Feature Name> -- Technical Decision

**Date**: <ISO-8601 date>
**Depth**: <quick|standard|deep>
**Techniques**: <list of techniques applied>
**Status**: DECIDED | PENDING

## Problem Statement

<1-2 paragraph description of the problem being solved>

## Context

<Key findings from codebase analysis>

## Options Considered

### Option 1: <Name>
<Description, key characteristics, estimated effort>

### Option 2: <Name>
<Description, key characteristics, estimated effort>

[... more options based on depth level ...]

## Analysis

<Results from each technique applied, using the formats defined above>

## Decision

**Selected**: Option <N> -- <Name>

**Rationale**: <Why this option was chosen. Reference specific technique results.>

**Trade-offs accepted**: <What we are giving up by choosing this option>

## Action Items

- [ ] <Specific next step 1>
- [ ] <Specific next step 2>
```

## Standalone Usage

When invoked as `/workflow:brainstorm <topic>`:

1. Ask for depth if not specified (default to config value)
2. Use sub-agents to gather codebase context related to the topic
3. Run the brainstorming process
4. Write the decision document
5. Present the recommendation to the user
6. Do NOT transition workflow state (standalone mode)

## Workflow Integration

When invoked as part of a workflow's BRAINSTORM phase:

1. Read the spec from `.workflows/specs/<feature-name>.spec.md`
2. Use the workflow's configured depth and techniques
3. Run the brainstorming process
4. Write the decision document
5. Present the recommendation and ask the user to confirm or adjust
6. On confirmation, signal the workflow engine to transition to PLAN phase
