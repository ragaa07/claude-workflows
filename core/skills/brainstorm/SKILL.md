---
name: brainstorm
description: Collaborative brainstorming with the user using structured techniques. Interactive back-and-forth discussion to explore, evaluate, and decide on an approach together.
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

## BEFORE YOU START — Initialize State

Check if `.workflows/current-state.md` exists (it may have been created by `/start`).

**If it does NOT exist**, create it now. Run these commands and create the file:

```bash
mkdir -p .workflows/<topic>
```

Then use your **Write tool** to create `.workflows/current-state.md`:

```
# Workflow State

- **workflow**: brainstorm
- **feature**: <topic>
- **phase**: EXPLORE
- **started**: <current ISO-8601 timestamp>
- **updated**: <current ISO-8601 timestamp>
- **branch**:
- **output_dir**: .workflows/<topic>/
- **retry_count**: 0

## Phase History

| Phase | Status | Timestamp | Output | Notes |
|-------|--------|-----------|--------|-------|
| EXPLORE | ACTIVE | <timestamp> | | Starting workflow |

## Phase Outputs

_Documents produced by each phase:_

## Context

_Key decisions and resume context:_
```

**If it already exists**, read it and continue from the current active phase.

**Verify**: Read `.workflows/current-state.md` to confirm it exists before proceeding.

---

## AFTER EVERY PHASE — You MUST Create Files

After completing each phase below, do these TWO things using your tools before moving on:

**Action 1 — Create the phase output file.** Use your **Write tool** to create the file at the path shown at the end of each phase (the `>> Write output to` line). Use this format:

```
# <Phase Name> — <Feature>

**Date**: <ISO-8601>
**Status**: Complete

## Summary
<1-3 sentences>

## Details
<Phase-specific content>

## Decisions
<Key decisions>

## Next Phase Input
<What next phase needs>
```

**Action 2 — Rewrite the state file.** Use your **Write tool** to REWRITE the entire `.workflows/current-state.md` file. Read the current content first, then write the full file back with these updates:
- Update `phase` and `updated` in the header
- In Phase History table: change the completed phase status to `COMPLETED`, add output filename, add new row for next phase as `ACTIVE`
- Under `## Phase Outputs`: add a link to the new output file
- Under `## Context`: add key decisions from this phase

**You must REWRITE the whole file — do not try to edit individual lines. Do NOT proceed to the next phase until both files are written.**

---

## Depth Levels

| Depth | Options | Techniques | Interaction Level |
|---|---|---|---|
| `quick` | 2 | Constraint Mapping + Trade-off Matrix | 2-3 exchanges |
| `standard` | 3 | 1 technique + Trade-off Matrix | 5-8 exchanges |
| `deep` | 4+ | Multiple techniques + Trade-off Matrix | 10+ exchanges |

Read depth from `--depth` flag, falling back to `workflows.brainstorm.default_depth` in `.claude/workflows.yml`.

## Techniques Reference

### 1. Trade-off Matrix
Score each option 1-5 against weighted criteria. Multiply by weight. Highest total wins. Used in ALL depth levels during Phase 2.

**Default weights**: Complexity (3), Maintainability (3), Risk (3), Performance (2), Testability (2), Time-to-implement (2), Extensibility (1).

### 2. Six Thinking Hats
Walk through six perspectives one at a time WITH the user:
- **White Hat**: "What facts do we know? What data is missing?"
- **Red Hat**: "What's your gut feeling about each option?"
- **Black Hat**: "What could go wrong? What are the risks?"
- **Yellow Hat**: "What's the best-case outcome? What excites you?"
- **Green Hat**: "Any unconventional ideas? Can we combine approaches?"
- **Blue Hat**: "Which option fits our process and constraints best?"

### 3. SCAMPER
Ask the user each question one at a time:
- **Substitute**: "What component could we swap out for something better?"
- **Combine**: "Can we merge two of these approaches?"
- **Adapt**: "Is there a pattern from elsewhere in the codebase or another domain?"
- **Modify**: "What if we changed the scope or scale?"
- **Put to other use**: "Can existing code serve this purpose with minor changes?"
- **Eliminate**: "What can we remove to simplify?"
- **Rearrange**: "What if we reversed the order or inverted a dependency?"

### 4. Reverse Brainstorm
Ask the user: "How could this implementation fail?" Collect failure modes together, then invert each into a prevention requirement.

### 5. Constraint Mapping
Ask the user to separate hard constraints (must) from soft constraints (should). **Always runs first in Phase 1.**

---

## Phase 1: EXPLORE

**Goal**: Collaboratively generate distinct implementation options through conversation.

### 1.1 — Set the Stage

If delegated from another workflow: read the spec/context document. Summarize the problem in 2-3 sentences. Ask the user: "Does this capture the problem correctly? Anything to add or correct?"

If standalone: parse `--topic`. Scan the codebase for related patterns. Then ask:
- "Here's what I found in the codebase related to this. Before we explore options — what's most important to you? (speed, maintainability, simplicity, performance?)"

**Wait for user response before continuing.**

### 1.2 — Constraint Mapping (always, interactive)

Ask the user directly:

```
Before we generate options, let's define the boundaries:

Hard constraints (non-negotiable):
  - What MUST this solution do?
  - What technical limitations exist?
  - Any compatibility requirements?

Soft constraints (preferred):
  - What SHOULD it do ideally?
  - Any preferences on patterns or libraries?
```

**Wait for user response.** Summarize the constraints back. Ask: "Did I miss any?"

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

Present all options in a summary table:

```
Options we've identified:
  A: <name> — <1-line summary>
  B: <name> — <1-line summary>
  C: <name> — <1-line summary>

Are these the right options to evaluate? Want to add, remove, or modify any?
```

**Wait for confirmation before moving to Phase 2.**

Discard options violating hard constraints. If fewer than 2 viable, generate more together.

**>> Write output to**: `.workflows/<topic>/01-explore.md` — then update `.workflows/current-state.md` (see State Tracking above).

---

## Phase 2: EVALUATE

**Goal**: Score and compare options collaboratively with the user.

### 2.1 — Review Criteria Together

Present the default weighted criteria:

```
I'll score each option against these criteria (1-5, weighted):
  Complexity (x3) | Maintainability (x3) | Risk (x3)
  Performance (x2) | Testability (x2) | Time-to-implement (x2)
  Extensibility (x1)

Do these criteria make sense for this decision?
Want to adjust weights or add/remove criteria?
```

**Wait for user input.** Adjust criteria if requested.

### 2.2 — Score Together

Present your initial scoring as a table. Then ask:

```
Here's how I'd score these:

                    Weight   Option A   Option B   Option C
Complexity            3       4 (12)     3 (9)      5 (15)
Maintainability       3       3 (9)      4 (12)     4 (12)
...
Total                          56         60         58

Do you agree with these scores? Which ones would you change?
```

**Wait for user response.** Adjust scores based on their input. The user knows their codebase and team better than you.

### 2.3 — Discuss Deal-Breakers

For any score of 1-2, flag it: "Option A scored 2 on Risk — that could be a deal-breaker. Is that acceptable to you, or should we eliminate it?"

**Wait for response.**

### 2.4 — Depth-Specific Discussion

- **Quick**: Matrix discussion is sufficient. Move to Phase 3.
- **Standard**: Ask: "For the leading option, what are the top 3 ways it could fail?" Discuss mitigations together.
- **Deep**: Walk through Six Thinking Hats on the top 2 options WITH the user, one hat at a time.

**>> Write output to**: `.workflows/<topic>/02-evaluate.md` — then update `.workflows/current-state.md`.

---

## Phase 3: RECOMMEND

**Goal**: Reach a decision together.

### 3.1 — Present Where We Are

Summarize the discussion:

```
Based on our conversation:

Recommended: Option B — <name>
Score: 60/80
Why: <top 3 reasons from our discussion>
Trade-offs: <what we're giving up>
Risks: <risks we identified + mitigations>
```

### 3.2 — Ask for Decision

```
What would you like to do?
  1. Go with Option B
  2. Go with a different option
  3. Go deeper — explore more
  4. Combine elements from multiple options
  5. I'm not convinced yet — let's discuss more
```

**Wait for response.** Handle each:
- **Option 1**: Finalize. Document the decision.
- **Option 2**: Ask why. Document the rationale for the switch.
- **Option 3**: Increase depth. Re-run from Phase 1 with more techniques.
- **Option 4**: Discuss which elements to combine. Create a hybrid option, re-evaluate.
- **Option 5**: Ask: "What's your main concern?" Continue the discussion until resolved.

### 3.3 — Document Decision

Once the user confirms, document: chosen approach, rationale (from the conversation), constraints satisfied, risks with mitigations, next steps. When delegated, this feeds into the calling workflow's next phase.

**>> Write output to**: `.workflows/<topic>/03-recommend.md` — then update `.workflows/current-state.md`.

**After this final phase**: Move `.workflows/current-state.md` to `.workflows/history/<topic>-<YYYY-MM-DD>.md`. Report completion.

---

## Facilitation Rules

1. **Never present a wall of analysis.** Break it into conversational pieces.
2. **Always wait for user response** before moving to the next step. Mark wait points with questions.
3. **Build on user's ideas.** If they suggest something, explore it even if you think another option is better.
4. **Challenge gently.** "That's interesting — have you considered X?" not "That won't work because Y."
5. **Summarize frequently.** After each exchange, briefly confirm what was decided before moving on.
6. **The user decides.** Your job is to facilitate, structure, and surface trade-offs — not to choose.

## Error Handling

| Error | Resolution |
|---|---|
| Topic too vague | Ask user for clarification before starting |
| All options violate a hard constraint | Ask user: "Are these constraints truly hard? Can any be relaxed?" |
| Scores are tied | Ask user: "These are very close. What's your tiebreaker — risk, speed, or simplicity?" |
| User rejects all options | Ask: "What's missing? What would the ideal solution look like?" Generate new options from their answer. |
| User wants to skip brainstorming | Respect it. Ask for their preferred approach and document it directly. |
| Delegated without context | Request spec or context from calling workflow |
