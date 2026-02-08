# Phase 5: Update Event Ingestion Service API Specification

## Outcome

The Event Ingestion Service API specification (`services/event-ingestion-service/API_SPEC.md`) is updated to document conversation event types. The API spec:
- Documents new event types in event type reference
- Shows request examples for conversation events
- Documents conversation-specific payload structures
- Updates validation rules if needed

A reviewer can read the API spec and understand how to log conversation events.

## Constraints & References

- **Current API spec:** `services/event-ingestion-service/API_SPEC.md`
- **Event schema:** `docs/data-model.md` (after phase5-event-schema-extension-docs.md)
- **Proposal reference:** `Repository_Evolution_Proposal.md` section 3.4
- **Format:** Follow existing API spec style

## Acceptance Checks

- [ ] API_SPEC.md updated with conversation event types
- [ ] Request examples show conversation events
- [ ] Payload structures documented for conversation events
- [ ] Validation rules updated if needed
- [ ] Examples match existing event patterns
- [ ] Documentation matches existing API spec style

## Explicit Non-Goals

- Does not update Event Ingestion Service design/implementation (separate consideration)
- Does not implement API changes (specification only)
- Does not create Metabase models (separate work item)
- Does not create analytics queries (separate work item)
