# Phase 1: Create Unified Experiment Configuration Validator

## Outcome

A specification document exists that defines a unified experiment configuration validator. The validator:
- Validates variant configs for both `mlflow_model` and `prompt_template` execution strategies
- Ensures `execution_strategy` matches the provided config objects
- Validates required fields for each execution strategy
- Provides clear error messages for invalid configurations
- Maintains backward compatibility validation for existing `policy_version_id` format

A reviewer can read the validator specification and understand:
- What configurations are valid
- What error messages are returned for invalid configs
- How backward compatibility is maintained

## Constraints & References

- **Config structure:** `Repository_Evolution_Proposal.md` lines 57-80
- **API spec:** `services/assignment-service/API_SPEC.md` (after updates)
- **Design doc:** `services/assignment-service/DESIGN.md` (after updates)
- **Validation rules:** Must align with database schema and service requirements

## Acceptance Checks

- [ ] Validator specification document created (location TBD: `services/assignment-service/VALIDATOR.md` or similar)
- [ ] Validates `execution_strategy` field presence and valid values
- [ ] Validates `mlflow_model` structure when `execution_strategy` is `"mlflow_model"`
- [ ] Validates `prompt_config` structure when `execution_strategy` is `"prompt_template"`
- [ ] Validates `flow_config` structure when present
- [ ] Validates backward compatibility: accepts existing `policy_version_id` format
- [ ] Error messages are clear and actionable
- [ ] Validation rules documented with examples

## Explicit Non-Goals

- Does not implement the validator (specification only)
- Does not update Assignment Service API/design (separate work items)
- Does not create database constraints (separate work item)
- Does not write validation code (specification only)
