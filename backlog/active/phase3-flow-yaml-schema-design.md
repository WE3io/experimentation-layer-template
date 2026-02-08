# Phase 3: Design Flow Definition YAML Schema

## Outcome

Documentation exists that defines the YAML schema for conversation flow definitions. The schema design:
- Defines state machine structure (states, transitions, conditions)
- Documents state properties (name, type, actions, validation)
- Documents transition properties (from, to, condition, actions)
- Includes examples of linear flows and decision trees
- Documents validation rules for flow definitions

A reviewer can read the schema design and understand how to define conversation flows in YAML format.

## Constraints & References

- **Location:** Document in `docs/conversation-flows.md` or separate schema doc
- **Proposal reference:** `Repository_Evolution_Proposal.md` section 3.2 (Conversation Flow Engine)
- **Requirements:** `Structured_Chatbot_Requirements.md` section 1.1 (Conversation Flow Architecture)
- **Format:** YAML-based state machines

## Acceptance Checks

- [ ] Flow schema design document created (location: `docs/conversation-flows.md` or `flows/SCHEMA.md`)
- [ ] State structure documented (name, type, message, actions, validation)
- [ ] Transition structure documented (from, to, condition, actions)
- [ ] Example linear flow documented
- [ ] Example decision tree flow documented
- [ ] Validation rules documented (required fields, valid transitions)
- [ ] Schema supports progress indicators and confirmation steps

## Explicit Non-Goals

- Does not implement flow orchestrator (separate work items)
- Does not create example flows (separate work item)
- Does not implement Redis sessions (separate work item)
- Does not validate YAML files (design only)
