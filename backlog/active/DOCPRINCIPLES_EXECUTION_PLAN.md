# Documentation Principles – Implementation Execution Plan

**Status**: All 8 items completed.

**Purpose**  
This plan describes how to execute the 8 docprinciples work items using the **implementation-executor** skill. The skill processes exactly one work item per invocation and stops after completion.

---

## Implementation-Executor Constraints

- **One item per invocation**: The skill refuses to work on multiple items at once
- **Completion action**: After acceptance passes, move the item to `backlog/completed/` and update checkboxes to `[x]`
- **Repo convention**: This project uses `backlog/completed/` (not `backlog/done/`) for completed items
- **No sequencing**: The skill does not prioritize or sequence; the human invokes each item separately

---

## Execution Order

Run in this order to minimize dependencies and start with quick wins:

| # | Work Item | Status |
|---|-----------|--------|
| 1 | [docprinciples-fix-stale-refs.md](../completed/docprinciples-fix-stale-refs.md) | Done |
| 2 | [docprinciples-simplify-readme-file-ref.md](../completed/docprinciples-simplify-readme-file-ref.md) | Done |
| 3 | [docprinciples-add-glossary.md](../completed/docprinciples-add-glossary.md) | Done |
| 4 | [docprinciples-archive-meta-docs.md](../completed/docprinciples-archive-meta-docs.md) | Done |
| 5 | [docprinciples-schema-deduplication.md](../completed/docprinciples-schema-deduplication.md) | Done |
| 6 | [docprinciples-config-example-linking.md](../completed/docprinciples-config-example-linking.md) | Done |
| 7 | [docprinciples-trim-verbosity.md](../completed/docprinciples-trim-verbosity.md) | Done |
| 8 | [docprinciples-strengthen-navigation.md](../completed/docprinciples-strengthen-navigation.md) | Done |

---

## Per-Invocation Workflow

For each work item:

1. **Invoke**: Use a trigger phrase with the work item reference, e.g.  
   `"Implement docprinciples-fix-stale-refs"` or  
   `"Execute the task in backlog/active/docprinciples-fix-stale-refs.md"`

2. **Implementation-executor will**:
   - Load the work item and restate Outcome, Constraints, Non-Goals
   - Implement minimal changes to satisfy acceptance checks
   - Verify acceptance (run checks)
   - Perform closure: move to `backlog/completed/`, update checkboxes

3. **Expected output**:
   - Brief summary of changes
   - Verification results
   - Completion action taken

4. **Then**: Invoke the next item in the sequence.

---

## Completion Convention

When an item is completed:

- **Move**: `backlog/active/docprinciples-{name}.md` → `backlog/completed/docprinciples-{name}.md`
- **Update**: Change `[ ]` to `[x]` in Acceptance Checks before or after move
- **Single action**: Only one closure action per item (do not create logs or extra files)

---

## Advisory Checkpoints

- **docprinciples-schema-deduplication**: Touches data-model.md and schema documentation. Consider safety-lens ("check for risks") before or after if concerned about breaking references.
- **docprinciples-trim-verbosity**: Involves judgment on what to trim. If outcome is ambiguous, ask for clarification before implementing.

---

## Batch Execution (Optional)

To run multiple items in sequence without re-invoking, you can say:

> "Implement docprinciples-fix-stale-refs. When done, immediately implement docprinciples-simplify-readme-file-ref. Then docprinciples-add-glossary."

The implementation-executor will still process one at a time per its constraints, but the human can chain requests to reduce round-trips.
