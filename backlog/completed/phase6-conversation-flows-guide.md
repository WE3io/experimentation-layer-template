# Phase 6: Create conversation-flows.md

## Outcome

A new documentation file `docs/conversation-flows.md` exists that explains conversation flow orchestration. The guide:
- Explains the flow engine and state machine concepts
- Shows how to define flows in YAML
- Documents flow patterns (linear, decision tree, hybrid)
- Explains session management
- Includes examples and best practices

A reviewer can read the guide and understand how to create conversation flows for structured dialogues.

## Constraints & References

- **Location:** `docs/conversation-flows.md`
- **Proposal reference:** `Repository_Evolution_Proposal.md` section 4 (lines 146)
- **Flow schema:** Flow YAML schema from Phase 3 work items
- **Requirements:** `Structured_Chatbot_Requirements.md` section 1.1
- **Documentation style:** Follow existing docs structure

## Acceptance Checks

- [ ] File `docs/conversation-flows.md` created
- [ ] Guide explains flow engine and state machines
- [ ] Flow definition in YAML explained
- [ ] Flow patterns documented (linear, decision tree, hybrid)
- [ ] Session management explained
- [ ] Examples and best practices included
- [ ] Links to flow orchestrator service and example flows included
- [ ] Matches existing documentation style
- [ ] Added to `docs/README.md` navigation

## Explicit Non-Goals

- Does not implement flow orchestrator (separate work items)
- Does not create example flows (separate work item)
- Does not create prompts guide (separate work item)
- Does not write code (documentation only)
