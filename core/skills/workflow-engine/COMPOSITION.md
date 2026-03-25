# Workflow Composition

Workflows can chain other workflows during specific phases. This enables reuse without duplication.

## Chain Definitions

When a workflow reaches a chainable phase, it may invoke another workflow as a sub-workflow.

### Built-in Chains

| Parent Workflow | Phase | Chains To | Condition |
|----------------|-------|-----------|-----------|
| new-feature | TEST | /workflow:test | When require_tests is true |
| new-feature | PRE_PR | /workflow:review --self | When review.auto_self_review is true |
| extend-feature | TEST | /workflow:test | When require_tests is true |
| extend-feature | VERIFY_COMPAT | /workflow:test --existing-only | Always |
| refactor | VERIFY | /workflow:test --full-suite | Always |
| release | PRE_RELEASE | /workflow:review --release | When review.on_release is true |

### Custom Chains (workflows.yml)

Users can define custom chains:

```yaml
workflows:
  new-feature:
    chains:
      POST_IMPLEMENT: "/workflow:review --self"
      TEST: "/workflow:test --coverage 95"

  release:
    chains:
      PRE_RELEASE: "/workflow:review --release"
```

### Chain Execution Rules

1. The parent workflow PAUSES at the chain point
2. The chained workflow runs with its own state (nested state)
3. Chained workflow state is stored as `.workflows/chain-<parent>-<child>.md`
4. When the chained workflow completes, the parent resumes
5. If the chained workflow fails, the parent enters REPLAN
6. Chained workflows do NOT create their own branches or PRs
7. Chained workflows inherit the parent's branch and commit context
8. Maximum chain depth: 2 (no chains within chains within chains)

### How to Invoke a Chain

In a workflow SKILL.md, at the relevant phase:

```
## Phase N: TEST

If workflows.yml has `chains.TEST` defined:
  1. Read the chain command
  2. Parse the target workflow and arguments
  3. Execute the chained workflow
  4. Wait for completion
  5. If chained workflow succeeds: continue to next phase
  6. If chained workflow fails: enter REPLAN with chain failure context
Otherwise:
  Execute the phase's built-in test steps
```
