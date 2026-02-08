# Phase 1: Extend Variant Config Schema Documentation

## Outcome

Documentation in `docs/data-model.md` is updated to describe the unified variant config schema that supports both `mlflow_model` and `prompt_template` execution strategies. The documentation clearly explains:
- The `execution_strategy` field and its valid values
- The structure of `mlflow_model`, `prompt_config`, and `flow_config` objects
- Backward compatibility with existing `policy_version_id` format
- Example configurations for both ML and conversational AI use cases

A reviewer can read `docs/data-model.md` section 1.2 (exp.variants) and understand the new unified config structure without referring to other documents.

## Constraints & References

- **Schema location:** `docs/data-model.md` section 1.2 (exp.variants)
- **Current schema:** `infra/postgres-schema-overview.sql` lines 47-64
- **Proposed schema:** `Repository_Evolution_Proposal.md` lines 57-80
- **Backward compatibility:** Must document that existing `policy_version_id` format remains supported
- **Format:** Follow existing documentation style in `docs/data-model.md`

## Acceptance Checks

- [x] `docs/data-model.md` section 1.2 includes description of `execution_strategy` field
- [x] Valid values for `execution_strategy` are documented: `"mlflow_model"`, `"prompt_template"`, `"hybrid"`
- [x] Structure of `mlflow_model` object is documented with example
- [x] Structure of `prompt_config` object is documented with example
- [x] Structure of `flow_config` object is documented with example
- [x] Backward compatibility section explains existing `policy_version_id` format still works
- [x] Example configs show both ML and conversational AI patterns
- [x] Documentation matches style and format of existing sections

## Explicit Non-Goals

- Does not create database migration (separate work item)
- Does not update Assignment Service code or specs (separate work items)
- Does not create configuration validator (separate work item)
- Does not modify actual database schema (documentation only)
