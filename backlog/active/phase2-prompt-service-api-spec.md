# Phase 2: Create Prompt Service API Specification

## Outcome

A new API specification document exists at `services/prompt-service/API_SPEC.md` that defines the Prompt Service API. The API spec:
- Defines endpoints for retrieving prompt versions by ID
- Defines endpoints for listing prompts and versions
- Documents request/response formats
- Includes examples for common use cases
- Follows the same structure as `services/assignment-service/API_SPEC.md`

A reviewer can read the API spec and understand how to call the Prompt Service to retrieve prompt configurations.

## Constraints & References

- **Location:** `services/prompt-service/API_SPEC.md`
- **Pattern:** Follow structure of `services/assignment-service/API_SPEC.md`
- **Schema:** `exp.prompts` and `exp.prompt_versions` tables (after migration)
- **File storage:** Prompts stored in `/prompts/` directory

## Acceptance Checks

- [ ] File `services/prompt-service/API_SPEC.md` created
- [ ] Base URL and authentication documented
- [ ] Endpoint for retrieving prompt version by ID documented
- [ ] Endpoint for listing prompts documented
- [ ] Endpoint for listing versions of a prompt documented
- [ ] Request/response examples included
- [ ] Error responses documented
- [ ] Follows same structure as Assignment Service API spec

## Explicit Non-Goals

- Does not implement the service (separate work item)
- Does not create service design doc (separate work item)
- Does not create `/prompts/` directory (separate work item)
- Does not populate prompt data (separate work items)
