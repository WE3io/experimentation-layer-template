# Phase 6: Update experiments.md for Unified Abstraction

## Outcome

The experiments documentation (`docs/experiments.md`) is updated to explain the unified abstraction. The documentation:
- Updates variant configuration section to show unified config format
- Explains `execution_strategy` field and its values
- Shows examples for both ML and conversational AI experiments
- Updates config structure examples
- Maintains backward compatibility documentation

A reviewer can read `docs/experiments.md` and understand how to create experiments for both ML and conversational AI projects.

## Constraints & References

- **Current file:** `docs/experiments.md`
- **Proposal reference:** `Repository_Evolution_Proposal.md` section 4 (lines 144)
- **Unified config:** Config structure from Phase 1 work items
- **Format:** Follow existing experiments documentation style

## Acceptance Checks

- [ ] `docs/experiments.md` section 4 (Variant Configuration) updated
- [ ] Unified config format explained with `execution_strategy`
- [ ] Examples show ML experiment configs (`mlflow_model`)
- [ ] Examples show conversational AI experiment configs (`prompt_template`)
- [ ] Backward compatibility section explains old format still works
- [ ] Documentation matches existing experiments style
- [ ] Links to choosing-project-type.md included

## Explicit Non-Goals

- Does not update architecture.md (separate work item)
- Does not create new guides (separate work items)
- Does not update README (separate work item)
- Does not create example projects (separate work item)
