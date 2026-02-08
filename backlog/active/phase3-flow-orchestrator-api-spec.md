# Phase 3: Create Flow Orchestrator Service API Specification

## Outcome

A new API specification document exists at `services/flow-orchestrator/API_SPEC.md` that defines the Flow Orchestrator Service API. The API spec:
- Defines endpoints for starting conversations (initializing flow state)
- Defines endpoints for processing user messages (state transitions)
- Defines endpoints for retrieving conversation state
- Documents request/response formats with flow context
- Includes examples for common conversation patterns

A reviewer can read the API spec and understand how to interact with conversation flows.

## Constraints & References

- **Location:** `services/flow-orchestrator/API_SPEC.md`
- **Pattern:** Follow structure of `services/assignment-service/API_SPEC.md`
- **Flow schema:** Flow YAML schema (after phase3-flow-yaml-schema-design.md)
- **Session management:** Redis-backed (design in separate work item)

## Acceptance Checks

- [ ] File `services/flow-orchestrator/API_SPEC.md` created
- [ ] Endpoint for starting conversation documented
- [ ] Endpoint for processing message documented
- [ ] Endpoint for retrieving state documented
- [ ] Request/response examples include flow context
- [ ] Error responses documented
- [ ] Session ID handling documented
- [ ] Follows same structure as Assignment Service API spec

## Explicit Non-Goals

- Does not implement the service (separate work item)
- Does not create service design doc (separate work item)
- Does not implement Redis sessions (separate work item)
- Does not create example flows (separate work item)
