# Conversation Flow YAML Schema

**Purpose**  
This document defines the YAML schema for conversation flow definitions. Flows are state machines that orchestrate structured dialogues for business process automation.

---

## Overview

Conversation flows define state machines where:
- **States** represent conversation steps (questions, confirmations, data collection)
- **Transitions** define how users move between states based on conditions
- **Actions** execute side effects (data validation, API calls, state updates)
- **Validation** ensures data integrity and user input correctness

Flows support multiple patterns:
- **Linear flows**: Step-by-step guided sequences
- **Decision trees**: Branching logic based on user responses
- **Hybrid flows**: Combining rule-based and AI-driven paths

---

## Root Schema

```yaml
flow:
  name: string                    # Unique flow identifier
  version: string                 # Flow version (semantic versioning)
  description: string             # Human-readable description
  initial_state: string           # Name of starting state
  states:                         # Map of state definitions
    <state_name>: <StateSchema>
  metadata:                       # Optional metadata
    tags: string[]                # Tags for categorization
    author: string                # Flow author
    created_at: string            # ISO 8601 timestamp
```

**Required fields**: `name`, `version`, `initial_state`, `states`

---

## State Schema

A state represents a single step in the conversation flow.

```yaml
<state_name>:
  type: string                    # State type (see State Types below)
  message: string | MessageSchema # Message to display to user
  actions: ActionSchema[]          # Actions to execute on entry
  validation: ValidationSchema    # Input validation rules
  metadata:                       # Optional state metadata
    progress: number              # Progress indicator (0.0 to 1.0)
    skip_conditions: ConditionSchema[]  # Conditions to skip this state
```

### State Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `string` | Yes | State type: `question`, `confirmation`, `data_collection`, `ai_response`, `end` |
| `message` | `string \| MessageSchema` | Yes | Message or message template to display |
| `actions` | `ActionSchema[]` | No | Actions executed when entering this state |
| `validation` | `ValidationSchema` | No | Validation rules for user input |
| `metadata.progress` | `number` | No | Progress indicator (0.0 to 1.0) for UI |
| `metadata.skip_conditions` | `ConditionSchema[]` | No | Conditions that allow skipping this state |

### State Types

1. **`question`**: Asks user a question, expects a response
2. **`confirmation`**: Asks for confirmation (yes/no, proceed/cancel)
3. **`data_collection`**: Collects structured data (form fields)
4. **`ai_response`**: Uses AI/LLM to generate response based on context
5. **`end`**: Terminal state, flow completion

### Message Schema

Messages can be simple strings or structured objects:

```yaml
# Simple string message
message: "What is your name?"

# Structured message with options
message:
  text: string                    # Primary message text
  quick_replies: string[]         # Quick reply buttons
  buttons:                       # Action buttons
    - label: string
      value: string
      action: string              # Optional action identifier
  template: string               # Template name (for dynamic messages)
  variables: object               # Variables for template substitution
```

---

## Transition Schema

Transitions define how users move from one state to another.

```yaml
transitions:
  - from: string                  # Source state name
    to: string                    # Target state name
    condition: ConditionSchema    # Condition that triggers transition
    actions: ActionSchema[]       # Actions executed during transition
    priority: number              # Optional priority (lower = higher priority)
```

### Transition Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `from` | `string` | Yes | Source state name (must exist in `states`) |
| `to` | `string` | Yes | Target state name (must exist in `states`) |
| `condition` | `ConditionSchema` | Yes | Condition that must be true for transition |
| `actions` | `ActionSchema[]` | No | Actions executed during transition |
| `priority` | `number` | No | Priority when multiple transitions match (default: 0) |

### Condition Schema

Conditions evaluate to true/false to determine if a transition should occur.

```yaml
condition:
  type: string                    # Condition type
  field: string                   # Field to evaluate (for field-based conditions)
  operator: string                # Comparison operator
  value: any                      # Comparison value
  logic: string                   # Logic operator: "and", "or", "not"
  conditions: ConditionSchema[]   # Nested conditions (for complex logic)
```

**Condition Types**:
- `always`: Always true (unconditional transition)
- `equals`: Field equals value
- `contains`: Field contains value (for arrays/strings)
- `matches`: Field matches regex pattern
- `exists`: Field exists and is not null
- `custom`: Custom condition evaluated by flow orchestrator

**Operators** (for comparison conditions):
- `equals`, `not_equals`
- `greater_than`, `less_than`, `greater_than_or_equal`, `less_than_or_equal`
- `contains`, `not_contains`
- `matches`, `not_matches`

**Example conditions**:
```yaml
# Simple equality check
condition:
  type: equals
  field: user_response
  value: "yes"

# Regex pattern match
condition:
  type: matches
  field: email
  value: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"

# Complex logic
condition:
  type: and
  conditions:
    - type: exists
      field: name
    - type: equals
      field: age
      operator: greater_than_or_equal
      value: 18
```

---

## Action Schema

Actions execute side effects when entering a state or during transitions.

```yaml
actions:
  - type: string                  # Action type
    target: string                # Target (field, API endpoint, etc.)
    value: any                    # Value to set or parameters
    on_error: string              # Error handling: "continue", "retry", "fail"
```

### Action Types

1. **`set_field`**: Set a field in conversation context
   ```yaml
   type: set_field
   target: "user_name"
   value: "{{user_response}}"
   ```

2. **`validate`**: Validate input using validation schema
   ```yaml
   type: validate
   target: "email"
   validation: <ValidationSchema>
   ```

3. **`call_api`**: Make HTTP API call
   ```yaml
   type: call_api
   target: "https://api.example.com/users"
   method: "POST"
   body:
     email: "{{email}}"
     name: "{{name}}"
   ```

4. **`log_event`**: Log event to event ingestion service
   ```yaml
   type: log_event
   event_type: "flow_state_entered"
   data:
     state: "{{current_state}}"
     flow: "{{flow_name}}"
   ```

5. **`redirect`**: Redirect to another flow
   ```yaml
   type: redirect
   target: "other_flow_name"
   ```

---

## Validation Schema

Validation rules ensure user input meets requirements.

```yaml
validation:
  required: boolean               # Field is required
  type: string                    # Expected type: "string", "number", "email", "phone", "date"
  min_length: number              # Minimum length (for strings)
  max_length: number              # Maximum length (for strings)
  min: number                     # Minimum value (for numbers)
  max: number                     # Maximum value (for numbers)
  pattern: string                 # Regex pattern to match
  custom_validator: string        # Custom validator function name
  error_message: string           # Error message to display on failure
```

**Example validation**:
```yaml
validation:
  required: true
  type: email
  pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
  error_message: "Please enter a valid email address"
```

---

## Example: Linear Flow

A simple linear flow for collecting user information step-by-step.

```yaml
flow:
  name: user_onboarding
  version: "1.0.0"
  description: "Collect user name and email"
  initial_state: ask_name
  
  states:
    ask_name:
      type: question
      message: "What is your name?"
      validation:
        required: true
        type: string
        min_length: 2
        max_length: 100
        error_message: "Name must be between 2 and 100 characters"
      metadata:
        progress: 0.33
    
    ask_email:
      type: data_collection
      message:
        text: "What is your email address?"
        quick_replies: []
      validation:
        required: true
        type: email
        pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        error_message: "Please enter a valid email address"
      metadata:
        progress: 0.67
      actions:
        - type: set_field
          target: name
          value: "{{previous_state.user_response}}"
    
    confirm:
      type: confirmation
      message:
        text: "Is this information correct?\nName: {{name}}\nEmail: {{email}}"
        buttons:
          - label: "Yes, continue"
            value: "yes"
          - label: "No, go back"
            value: "no"
      metadata:
        progress: 0.9
    
    complete:
      type: end
      message: "Thank you! Your information has been saved."
      actions:
        - type: log_event
          event_type: "flow_completed"
          data:
            flow: "user_onboarding"
            name: "{{name}}"
            email: "{{email}}"
      metadata:
        progress: 1.0

  transitions:
    - from: ask_name
      to: ask_email
      condition:
        type: always
    
    - from: ask_email
      to: confirm
      condition:
        type: always
    
    - from: confirm
      to: complete
      condition:
        type: equals
        field: user_response
        value: "yes"
    
    - from: confirm
      to: ask_name
      condition:
        type: equals
        field: user_response
        value: "no"
```

---

## Example: Decision Tree Flow

A flow with branching logic based on user responses.

```yaml
flow:
  name: support_triage
  version: "1.0.0"
  description: "Triage support requests"
  initial_state: ask_issue_type
  
  states:
    ask_issue_type:
      type: question
      message:
        text: "What type of issue are you experiencing?"
        buttons:
          - label: "Technical Problem"
            value: "technical"
          - label: "Billing Question"
            value: "billing"
          - label: "Feature Request"
            value: "feature"
          - label: "Other"
            value: "other"
      metadata:
        progress: 0.2
    
    collect_technical_details:
      type: data_collection
      message: "Please describe the technical issue you're experiencing."
      validation:
        required: true
        type: string
        min_length: 10
        error_message: "Please provide at least 10 characters"
      metadata:
        progress: 0.5
    
    collect_billing_info:
      type: data_collection
      message: "What is your account number or billing email?"
      validation:
        required: true
        type: string
      metadata:
        progress: 0.5
    
    collect_feature_details:
      type: data_collection
      message: "What feature would you like to see? Please describe it."
      validation:
        required: true
        type: string
        min_length: 20
      metadata:
        progress: 0.5
    
    collect_other_details:
      type: data_collection
      message: "Please describe your issue or question."
      validation:
        required: true
        type: string
        min_length: 5
      metadata:
        progress: 0.5
    
    route_to_support:
      type: end
      message: "Thank you! Your request has been submitted. Our team will respond within 24 hours."
      actions:
        - type: log_event
          event_type: "support_request_submitted"
          data:
            issue_type: "{{issue_type}}"
            details: "{{details}}"
      metadata:
        progress: 1.0

  transitions:
    - from: ask_issue_type
      to: collect_technical_details
      condition:
        type: equals
        field: user_response
        value: "technical"
      actions:
        - type: set_field
          target: issue_type
          value: "technical"
    
    - from: ask_issue_type
      to: collect_billing_info
      condition:
        type: equals
        field: user_response
        value: "billing"
      actions:
        - type: set_field
          target: issue_type
          value: "billing"
    
    - from: ask_issue_type
      to: collect_feature_details
      condition:
        type: equals
        field: user_response
        value: "feature"
      actions:
        - type: set_field
          target: issue_type
          value: "feature"
    
    - from: ask_issue_type
      to: collect_other_details
      condition:
        type: equals
        field: user_response
        value: "other"
      actions:
        - type: set_field
          target: issue_type
          value: "other"
    
    - from: collect_technical_details
      to: route_to_support
      condition:
        type: always
      actions:
        - type: set_field
          target: details
          value: "{{user_response}}"
    
    - from: collect_billing_info
      to: route_to_support
      condition:
        type: always
      actions:
        - type: set_field
          target: details
          value: "{{user_response}}"
    
    - from: collect_feature_details
      to: route_to_support
      condition:
        type: always
      actions:
        - type: set_field
          target: details
          value: "{{user_response}}"
    
    - from: collect_other_details
      to: route_to_support
      condition:
        type: always
      actions:
        - type: set_field
          target: details
          value: "{{user_response}}"
```

---

## Validation Rules

### Required Fields

The following fields are required at the root level:
- `flow.name`: Unique identifier for the flow
- `flow.version`: Semantic version string
- `flow.initial_state`: Must reference a state that exists in `states`
- `flow.states`: Must contain at least one state

Each state must have:
- `type`: Valid state type
- `message`: Non-empty message or message schema

Each transition must have:
- `from`: Must reference an existing state
- `to`: Must reference an existing state
- `condition`: Valid condition schema

### Valid Transitions

1. **State references**: All `from` and `to` values in transitions must reference states defined in `states`
2. **Initial state**: `initial_state` must exist in `states`
3. **Terminal states**: States with `type: end` should not have outgoing transitions
4. **Circular references**: Flows should be designed to avoid infinite loops (validation may warn but not fail)
5. **Reachability**: All states should be reachable from `initial_state` (warning, not error)

### Type Validation

- `version`: Must be valid semantic version string (e.g., "1.0.0")
- `metadata.progress`: Must be between 0.0 and 1.0
- `validation.type`: Must be one of: "string", "number", "email", "phone", "date"
- `condition.type`: Must be valid condition type
- `action.type`: Must be valid action type

### Schema Validation Checklist

When validating a flow definition:

- [ ] Root `flow` object exists
- [ ] Required root fields present (`name`, `version`, `initial_state`, `states`)
- [ ] `initial_state` references a state in `states`
- [ ] All states have required fields (`type`, `message`)
- [ ] All state types are valid
- [ ] All transitions reference valid states (`from` and `to` exist)
- [ ] All transitions have valid conditions
- [ ] No circular dependencies that cause infinite loops
- [ ] Progress indicators are between 0.0 and 1.0
- [ ] Validation schemas are properly formed
- [ ] Action schemas reference valid types

---

## Progress Indicators

Progress indicators help users understand their position in multi-step flows.

**Usage**:
```yaml
metadata:
  progress: 0.5  # 50% complete
```

**Best Practices**:
- Start at 0.0 for initial state
- End at 1.0 for terminal states
- Increment evenly across linear flows
- Update based on actual progress in decision trees

**Example with progress**:
```yaml
states:
  step1:
    metadata:
      progress: 0.25  # 25% complete
  step2:
    metadata:
      progress: 0.50  # 50% complete
  step3:
    metadata:
      progress: 0.75  # 75% complete
  complete:
    metadata:
      progress: 1.0   # 100% complete
```

---

## Confirmation Steps

Confirmation states allow users to review and confirm before proceeding.

**Pattern**:
```yaml
confirm_state:
  type: confirmation
  message:
    text: "Please confirm:\n{{summary}}"
    buttons:
      - label: "Confirm"
        value: "yes"
      - label: "Cancel"
        value: "no"
  transitions:
    - from: confirm_state
      to: next_state
      condition:
        type: equals
        field: user_response
        value: "yes"
    - from: confirm_state
      to: previous_state
      condition:
        type: equals
        field: user_response
        value: "no"
```

**Use Cases**:
- Review collected data before submission
- Confirm destructive actions
- Verify understanding before proceeding
- Final confirmation before flow completion

---

## References

- **Repository Evolution Proposal**: Section 3.2 (Conversation Flow Engine)
- **Structured Chatbot Requirements**: Section 1.1 (Conversation Flow Architecture)
- **Flow Orchestrator Service**: See `services/flow-orchestrator/` for implementation details
- **Example Flows**: See `flows/` directory for complete flow definitions
