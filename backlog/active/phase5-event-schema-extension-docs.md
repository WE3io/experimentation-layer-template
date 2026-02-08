# Phase 5: Extend Event Schema Documentation

## Outcome

Documentation in `docs/data-model.md` is updated to include conversation-specific event types. The documentation:
- Documents new event types: `conversation_started`, `message_sent`, `flow_completed`, `user_dropped_off`
- Explains event structure for conversation events
- Documents conversation context fields in event payload
- Updates event examples to show conversation patterns

A reviewer can read `docs/data-model.md` section 2.1 (exp.events) and understand conversation event types.

## Constraints & References

- **Schema location:** `docs/data-model.md` section 2.1 (exp.events)
- **Current schema:** `infra/postgres-schema-overview.sql` lines 86-110
- **Proposal reference:** `Repository_Evolution_Proposal.md` section 3.4 (Conversation Analytics)
- **Format:** Follow existing documentation style

## Acceptance Checks

- [ ] `docs/data-model.md` section 2.1 updated with conversation event types
- [ ] Event types documented: `conversation_started`, `message_sent`, `flow_completed`, `user_dropped_off`
- [ ] Event structure examples show conversation context
- [ ] Payload structure documented for conversation events
- [ ] Examples show conversation event patterns
- [ ] Documentation matches style of existing event types

## Explicit Non-Goals

- Does not create database migration (separate work item)
- Does not update Event Ingestion Service (separate work item)
- Does not modify actual database schema (documentation only)
- Does not create Metabase models (separate work item)
