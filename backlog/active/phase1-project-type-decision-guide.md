# Phase 1: Add Project Type Decision Guide

## Outcome

A new documentation file `docs/choosing-project-type.md` exists that helps developers decide whether to use the ML-focused or conversational AI-focused approach. The guide:
- Explains when to use `execution_strategy: "mlflow_model"` (traditional ML)
- Explains when to use `execution_strategy: "prompt_template"` (conversational AI)
- Provides decision criteria and examples
- Links to relevant documentation for each project type

A reviewer can read the guide and confidently choose the appropriate project type for their use case.

## Constraints & References

- **Location:** `docs/choosing-project-type.md`
- **Proposal reference:** `Repository_Evolution_Proposal.md` section 2 (Unified Abstraction Design)
- **Documentation style:** Follow existing docs structure (see `docs/README.md`)
- **Links:** Reference existing docs like `docs/mlflow-guide.md` and future conversational AI docs

## Acceptance Checks

- [ ] File `docs/choosing-project-type.md` created
- [ ] Guide explains ML project type (model training, fine-tuning)
- [ ] Guide explains conversational AI project type (prompts, flows, foundation models)
- [ ] Decision criteria provided (when to use each)
- [ ] Examples show typical use cases for each type
- [ ] Links to relevant documentation for each project type
- [ ] Matches existing documentation style and structure
- [ ] Added to `docs/README.md` navigation if appropriate

## Explicit Non-Goals

- Does not create the actual project templates (separate work items)
- Does not implement the execution strategies (specification only)
- Does not write conversational AI documentation (separate work items)
- Does not update README.md (separate work item in Phase 6)
