---
name: brainstorm
description: Collaborative brainstorming with the user using structured techniques. Interactive back-and-forth discussion to explore, evaluate, and decide on an approach together.
rules: [0, 1, 2, 5, 6]
---

# Brainstorm Workflow

## Command

```
/brainstorm <--topic "description"> [--depth <quick|standard|deep>]
```

- `--topic` (required): Problem or feature to brainstorm approaches for.
- `--depth`: `quick`, `standard` (default), or `deep`.

## Overview

**This is a collaborative conversation, not a solo analysis.** You are a brainstorming facilitator. Your job is to guide the user through structured thinking using techniques — asking questions, building on their ideas, challenging assumptions, and helping them reach a decision. Never generate a full analysis alone and present it as a fait accompli.

Three phases: **EXPLORE -> EVALUATE -> RECOMMEND**. Can run standalone or delegated from other workflows.

> Follow orchestration Rules 0-1 for state and output.

---

## Depth Levels

| Depth | Options | Techniques | Interaction Level |
|---|---|---|---|
| `quick` | 2 | Constraint Mapping + Trade-off Matrix | 2-3 exchanges |
| `standard` | 3 | 1 technique + Trade-off Matrix | 5-8 exchanges |
| `deep` | 4+ | Multiple techniques + Trade-off Matrix | 10+ exchanges |

Read depth from `--depth` flag, falling back to `workflows.brainstorm.default_depth` in `.workflows/config.yml`.

### Auto-Depth Detection

If no depth is specified (no flag, no config override), auto-detect:

| Signal | Depth |
|--------|-------|
| Naming/styling decision, or 1-2 files affected | `quick` |
| 3-10 files, moderate complexity, no breaking changes | `standard` |
| >10 files, breaking changes, data migration, or multi-service | `deep` |

Announce: "This looks like a [depth] brainstorm based on [signal]. Want to adjust?"

## Techniques Reference

### 1. Trade-off Matrix
Score each option against weighted criteria. Multiply by weight. Highest total wins. Used in ALL depth levels during Phase 2.

| Score | Meaning |
|-------|---------|
| 1 | Unacceptable — fails this criterion or actively harmful |
| 2 | Poor — significant concerns, workaround needed |
| 3 | Adequate — meets minimum bar, nothing special |
| 4 | Good — meaningfully better than minimum, minor gaps |
| 5 | Excellent — best realistic outcome for this criterion |

**Default weights**: Complexity (3), Maintainability (3), Risk (3), Performance (2), Testability (2), Time-to-implement (2), Extensibility (1).

### 2. Six Thinking Hats
Walk through WITH the user, one at a time: **White** (facts/data gaps) -> **Red** (gut feeling) -> **Black** (risks) -> **Yellow** (best-case) -> **Green** (unconventional/combinations) -> **Blue** (process fit).

### 3. SCAMPER
Ask one at a time: **S**ubstitute (swap components?) -> **C**ombine (merge approaches?) -> **A**dapt (patterns from elsewhere?) -> **M**odify (change scope/scale?) -> **P**ut to other use (reuse existing code?) -> **E**liminate (simplify?) -> **R**earrange (reverse order/invert deps?).

### 4. Reverse Brainstorm
"How could this fail?" Collect failure modes, invert each into prevention requirements.

### 5. Constraint Mapping
Separate hard (must) from soft (should) constraints. **Always runs first in Phase 1.**

---

## Phase 1: EXPLORE

**Goal**: Collaboratively generate distinct implementation options through conversation.

### 1.1 — Set the Stage

If delegated from another workflow: read the spec/context document. Summarize the problem in 2-3 sentences. Ask the user: "Does this capture the problem correctly? Anything to add or correct?"

If standalone: parse `--topic`. Scan the codebase for related patterns.

**Knowledge check**: Read `.workflows/knowledge.jsonl` if it exists. Find entries with similar constraints or topic keywords. If matches found, present: "Past decisions on similar topics:" followed by up to 3 relevant entries with their approach and outcome.

Then ask:
- "Here's what I found in the codebase related to this. Before we explore options — what's most important to you? (speed, maintainability, simplicity, performance?)"

**Wait for user response before continuing.**

### 1.2 — Constraint Mapping (always, interactive)

Ask the user: "What MUST this solution do? (hard constraints) What SHOULD it do ideally? (soft constraints) Any technical limitations or compatibility requirements?"

**Wait for response.** Summarize constraints back. Ask: "Did I miss any?"

### 1.3 — Generate Options Together

**Do NOT generate all options silently.** Instead:

1. **Seed with 1 option**: Present ONE approach you see as most obvious. Explain it briefly. Ask: "What do you think? Does this direction make sense, or do you see a different angle?"

2. **Build from user input**: Based on their response, either refine that option or generate an alternative. Ask: "What about approaching it from this angle instead?"

3. **Apply technique interactively** based on depth:
   - **Quick**: After 2 options are on the table, move to evaluation.
   - **Standard**: Select 1 technique (Six Thinking Hats, SCAMPER, or Reverse Brainstorm — pick based on problem type). Walk through it WITH the user, one question at a time. Generate a 3rd option from the discussion. Only use techniques listed in `workflows.brainstorm.techniques` from config.
   - **Deep**: Apply multiple techniques interactively. Let the conversation generate 4+ options naturally.

4. **After each new option**: Ask "Does this option address your concerns? Should we explore another direction?"

### 1.4 — Confirm Options List

Present options: `A: <name> — <summary>`, `B: ...`, `C: ...`. Ask: "Right options to evaluate? Add, remove, or modify any?"

**Wait for confirmation.** Discard hard-constraint violations. If fewer than 2 viable, generate more together.

**>> Write output to**: `.workflows/<topic>/01-explore.md`.

---

## Phase 2: EVALUATE

**Goal**: Score and compare options collaboratively with the user.

### 2.1 — Review Criteria Together

Present default weighted criteria: Complexity (x3), Maintainability (x3), Risk (x3), Performance (x2), Testability (x2), Time-to-implement (x2), Extensibility (x1). Ask: "Adjust weights or add/remove criteria?" **Wait for input.**

### 2.2 — Score Together

Present scoring table (criterion x weight = weighted score per option, with totals). Ask: "Agree with these scores? Which would you change?" **Wait for response.** Adjust based on user input -- they know their codebase better.

### 2.3 — Discuss Deal-Breakers

For any score of 1-2, flag it: "Option A scored 2 on Risk — that could be a deal-breaker. Is that acceptable to you, or should we eliminate it?"

**Wait for response.**

### 2.4 — Depth-Specific Discussion

- **Quick**: Matrix discussion is sufficient. Move to Phase 3.
- **Standard**: Ask: "For the leading option, what are the top 3 ways it could fail?" Discuss mitigations together.
- **Deep**: Walk through Six Thinking Hats on the top 2 options WITH the user, one hat at a time.

**>> Write output to**: `.workflows/<topic>/02-evaluate.md`.

---

## Phase 3: RECOMMEND

**Goal**: Reach a decision together.

### 3.1 — Present Recommendation

Summarize: recommended option, score, top 3 reasons, trade-offs, risks + mitigations.

### 3.2 — Ask for Decision

Options: (1) go with recommendation, (2) different option, (3) go deeper, (4) combine elements, (5) discuss more.

**Wait for response.** Handle: (1) finalize, (2) ask why + document, (3) escalate depth (max once: quick->standard->deep; at deep, make decision or discuss specifics), (4) create hybrid + re-evaluate, (5) ask main concern + continue.

### 3.3 — Document Decision

Once the user confirms, document: chosen approach, rationale (from the conversation), constraints satisfied, risks with mitigations, next steps. When delegated, this feeds into the calling workflow's next phase.

**>> Write output to**: `.workflows/<topic>/03-recommend.md`.

**After this final phase**: Move `.workflows/current-state.md` to `.workflows/history/<topic>-<YYYY-MM-DD>.md`. Report completion.

---

## Facilitation Rules

- Never present a wall of analysis -- break into conversational pieces
- Always wait for user response before proceeding (mark wait points with questions)
- Build on user's ideas, even if you prefer another option
- Challenge gently: "Have you considered X?" not "That won't work"
- Summarize frequently; confirm decisions before moving on
- The user decides -- you facilitate and surface trade-offs
- **Timeout**: After 2 unanswered prompts, offer: continue / go with best option / pause
- **Abort**: On "stop/cancel/abort", end immediately with partial results documented

## Error Handling

| Error | Resolution |
|---|---|
| Topic too vague | Ask user for clarification before starting |
| All options violate a hard constraint | Ask user: "Are these constraints truly hard? Can any be relaxed?" |
| Scores are tied | Ask user: "These are very close. What's your tiebreaker — risk, speed, or simplicity?" |
| User rejects all options | Ask: "What's missing? What would the ideal solution look like?" Generate new options from their answer. |
| User wants to skip brainstorming | Respect it. Ask for their preferred approach and document it directly. |
| Delegated without context | Request spec or context from calling workflow |
