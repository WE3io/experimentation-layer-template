# Phase 1: Update Assignment Service API Specification

## Outcome

The Assignment Service API specification (`services/assignment-service/API_SPEC.md`) is updated to document how the service handles unified variant configs. The API spec:
- Documents the new config structure in request/response examples
- Shows examples for both `mlflow_model` and `prompt_template` execution strategies
- Maintains backward compatibility documentation for existing `policy_version_id` format
- Updates config structure documentation in section 6

A reviewer can read the API spec and understand how to call the service with both old and new config formats.

## Constraints & References

- **Current API spec:** `services/assignment-service/API_SPEC.md`
- **Config structure:** `Repository_Evolution_Proposal.md` lines 57-80
- **Backward compatibility:** Must document that old format still works
- **Format:** Follow existing API spec style and structure

## Acceptance Checks

- [x] API_SPEC.md section 6 (Config Structure) updated with unified config format
- [x] Request examples show both old (`policy_version_id`) and new (`execution_strategy`) formats
- [x] Response examples show unified config structure
- [x] Examples include `mlflow_model` execution strategy
- [x] Examples include `prompt_template` execution strategy
- [x] Backward compatibility section explains old format still supported
- [x] SDK examples updated to show new config structure
- [x] Documentation matches existing API spec style

## Explicit Non-Goals

- Does not update Assignment Service design/implementation (separate work item)
- Does not implement the API changes (specification only)
- Does not create config validator (separate work item)
- Does not update client SDKs (specification only)
