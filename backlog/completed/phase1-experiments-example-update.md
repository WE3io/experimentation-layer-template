# Phase 1: Update experiments.example.yml

## Outcome

The `config/experiments.example.yml` file is updated to include examples showing the unified config format. The file:
- Adds examples demonstrating `execution_strategy: "mlflow_model"` format
- Adds examples demonstrating `execution_strategy: "prompt_template"` format
- Maintains existing examples for backward compatibility reference
- Includes comments explaining when to use each format

A reviewer can copy `experiments.example.yml` and see examples of both ML and conversational AI experiment configurations.

## Constraints & References

- **Current file:** `config/experiments.example.yml`
- **Config structure:** `Repository_Evolution_Proposal.md` lines 57-80
- **Migration guide:** `Repository_Evolution_Proposal.md` lines 236-252
- **Format:** Follow existing YAML style and comment structure

## Acceptance Checks

- [x] File includes example with `execution_strategy: "mlflow_model"`
- [x] File includes example with `execution_strategy: "prompt_template"`
- [x] Examples show complete variant config structure
- [x] Comments explain execution strategies
- [x] Existing examples retained (for backward compatibility reference)
- [x] YAML syntax is valid
- [x] Examples match structure from proposal

## Explicit Non-Goals

- Does not update other config files (separate work items)
- Does not create new config files (separate work items)
- Does not implement config loading (example file only)
- Does not validate configs (separate work item)
