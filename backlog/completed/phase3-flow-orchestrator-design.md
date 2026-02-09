# Phase 3: Create Flow Orchestrator Service Design

## Outcome

A new design document exists at `services/flow-orchestrator/DESIGN.md` that describes the internal design of the Flow Orchestrator Service. The design:
- Describes state machine execution logic
- Documents flow loading and parsing
- Describes state transition logic (conditions, actions)
- Documents session state management (Redis integration)
- Documents validation hooks and error handling
- Follows the same structure as `services/assignment-service/DESIGN.md`

A reviewer can read the design doc and understand how conversation flows are executed.

## Constraints & References

- **Location:** `services/flow-orchestrator/DESIGN.md`
- **Pattern:** Follow structure of `services/assignment-service/DESIGN.md`
- **API spec:** `services/flow-orchestrator/API_SPEC.md` (after phase3-flow-orchestrator-api-spec.md)
- **Flow schema:** Flow YAML schema design
- **Session management:** Redis session design (separate work item)

## Acceptance Checks

- [ ] File `services/flow-orchestrator/DESIGN.md` created
- [ ] State machine execution logic documented
- [ ] Flow loading and parsing documented
- [ ] State transition logic documented (condition evaluation, action execution)
- [ ] Session state management documented (Redis integration)
- [ ] Validation hooks documented
- [ ] Error handling documented
- [ ] Performance considerations documented
- [ ] Follows same structure as Assignment Service design doc

## Explicit Non-Goals

- Does not implement the service (specification only)
- Does not create API spec (separate work item)
- Does not design Redis sessions (separate work item)
- Does not write code (design specification only)
