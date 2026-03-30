---
name: compose-skill
description: Interactively create a custom workflow skill with proper structure, frontmatter, phases, and orchestration integration.
rules: []
---

# Skill Composer

```
/compose-skill <name>
```

Interactively build a new workflow skill for your team.

---

## Step 1: Gather Requirements

Ask sequentially:
1. "What does this skill do? (1-2 sentences)"
2. "What are the phases? List them in order (e.g., ANALYZE, PLAN, EXECUTE, VERIFY)"
3. For each phase: "What should **<phase>** produce? (1 sentence)"
4. "Does this skill need brainstorming? (y/n)"
5. "Does this skill create a PR at the end? (y/n)"
6. "Which orchestration rules apply?" -- suggest based on answers:
   - Always: `[0, 1]` (state + output)
   - If has PR: add `3, 5` (quality gate + completion)
   - If multi-step execution: add `7, 11` (REPLAN + checkpoints)
   - If brainstorm: add `2` (skip support)

## Step 2: Generate Skill

Write `.claude/skills/<name>/SKILL.md` with this structure:

```markdown
---
name: <name>
description: "<user's description>"
rules: [<selected-rules>]
---

# <Name> Workflow

## Command

` ` `
/<name> <target> [flags based on phases]
` ` `

> Follow orchestration Rules <list> for state and output.

---

<For each phase, generate:>

## Phase N: <PHASE-NAME>

**Goal**: <user's description of what this phase produces>

### Execute

<Placeholder instructions -- tell the user to fill in the details>

1. <Step 1 placeholder>
2. <Step 2 placeholder>

**>> Write output to**: `.workflows/<target>/NN-<phase>.md`

---

<If has PR phase, add quality gate boilerplate>

## Error Handling

| Error | Resolution |
|-------|------------|
| Target not found | Ask user for correct name or path |
| Build fails | Fix and retry, REPLAN after 3 failures |
```

## Step 3: Validate

1. Verify the file was written successfully
2. Check that phase output numbering is sequential (01, 02, 03...)
3. Verify frontmatter has required fields (name, description, rules)
4. Print summary:
   ```
   Skill created: .claude/skills/<name>/SKILL.md
     Phases: <list>
     Rules: <list>
     PR phase: yes/no

   Next: Edit the skill to fill in phase-specific instructions.
   Then use /<name> to run it.
   ```

## Step 4: Register (Optional)

Ask: "Add an alias for this skill? (e.g., /build -> /new-feature)"
If yes, suggest adding to `skills.aliases` in `.claude/workflows.yml`.
