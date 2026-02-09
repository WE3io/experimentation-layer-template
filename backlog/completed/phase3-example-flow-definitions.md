# Phase 3: Create Example Flow Definitions

## Outcome

Example flow definition files exist in `/flows/` directory demonstrating conversation flow patterns. The directory:
- Contains `onboarding_flow.yml` demonstrating a linear onboarding flow
- Contains `data_collection_flow.yml` demonstrating form-like data collection
- Includes a README.md explaining flow structure
- Shows examples of states, transitions, conditions, and validation

A reviewer can browse `/flows/` and understand how to define conversation flows.

## Constraints & References

- **Location:** `/flows/` directory in repository root
- **Proposal reference:** `Repository_Evolution_Proposal.md` section 4 (lines 167-169)
- **Flow schema:** Flow YAML schema design (after phase3-flow-yaml-schema-design.md)
- **Requirements:** `Structured_Chatbot_Requirements.md` section 1.1 (Conversation Flow Architecture)

## Acceptance Checks

- [ ] Directory `/flows/` created
- [ ] README.md in `/flows/` explains flow structure
- [ ] Example file `onboarding_flow.yml` created with linear flow
- [ ] Example file `data_collection_flow.yml` created with form-like flow
- [ ] Flows demonstrate states, transitions, and conditions
- [ ] Flows demonstrate validation rules
- [ ] Flows demonstrate progress indicators
- [ ] YAML syntax is valid

## Explicit Non-Goals

- Does not implement flow orchestrator (separate work items)
- Does not create all possible flows (examples only)
- Does not implement flow execution (separate work items)
- Does not create flows.example.yml (separate consideration)
