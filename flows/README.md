# Conversation Flows

**Purpose**  
This directory contains conversation flow definitions in YAML format. Flows define state machines that orchestrate structured dialogues for business process automation.

---

## Flow Structure

Each flow file defines a state machine with:

- **States**: Conversation steps (questions, confirmations, data collection)
- **Transitions**: Rules for moving between states based on conditions
- **Actions**: Side effects executed during state transitions
- **Validation**: Input validation rules for user responses

### Basic Flow Structure

```yaml
flow:
  name: flow_identifier
  version: "1.0.0"
  description: "Human-readable description"
  initial_state: starting_state_name
  
  states:
    state_name:
      type: question | confirmation | data_collection | ai_response | end
      message: "Message to display"
      validation: { ... }
      actions: [ ... ]
      metadata:
        progress: 0.5
  
  transitions:
    - from: state_a
      to: state_b
      condition: { ... }
```

---

## Example Flows

### `onboarding_flow.yml`

A linear onboarding flow that collects user information step-by-step:
- Collects name and email
- Includes confirmation step
- Demonstrates progress indicators
- Shows validation rules

### `data_collection_flow.yml`

A form-like data collection flow with branching logic:
- Multiple data fields
- Conditional branching based on responses
- Demonstrates decision tree patterns
- Shows complex validation

---

## Flow Schema

For complete schema documentation, see [SCHEMA.md](SCHEMA.md).

**Key Concepts:**
- **State Types**: `question`, `confirmation`, `data_collection`, `ai_response`, `end`
- **Conditions**: `always`, `equals`, `contains`, `matches`, `exists`, `and`, `or`, `not`
- **Actions**: `set_field`, `validate`, `call_api`, `log_event`, `redirect`
- **Validation**: `required`, `type`, `min_length`, `max_length`, `pattern`

---

## Usage

Flows are loaded by the Flow Orchestrator Service at runtime:

1. Flow files are stored in `/flows/` directory
2. Flow Orchestrator loads flows by `flow_id` and optional `flow_version`
3. Flows are cached in memory for performance
4. Flow definitions are versioned using semantic versioning

---

## Best Practices

1. **Versioning**: Use semantic versioning (e.g., `1.0.0`, `1.1.0`, `2.0.0`)
2. **State Names**: Use descriptive, snake_case names (e.g., `ask_user_name`)
3. **Progress**: Set progress indicators (0.0 to 1.0) for UI feedback
4. **Validation**: Always validate user input with clear error messages
5. **Transitions**: Ensure all states are reachable from `initial_state`
6. **Testing**: Test flows manually before deploying

---

## Related Documentation

- **[SCHEMA.md](SCHEMA.md)**: Complete flow schema definition
- **[../services/flow-orchestrator/API_SPEC.md](../services/flow-orchestrator/API_SPEC.md)**: Flow Orchestrator API
- **[../services/flow-orchestrator/DESIGN.md](../services/flow-orchestrator/DESIGN.md)**: Flow Orchestrator design
- **[../docs/conversation-flows.md](../docs/conversation-flows.md)**: Conversation flows guide (coming in Phase 6)
