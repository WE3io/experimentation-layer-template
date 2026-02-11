# Conversation Flows Guide

**Purpose**  
This guide explains how to create and manage conversation flows for structured dialogues using state machines. Flows orchestrate multi-turn conversations with validation, branching logic, and state management.

---

## Start Here If…

- **Creating conversation flows for conversational AI projects** → Read this guide
- **Understanding flow orchestration** → Read this guide
- **Designing structured dialogues** → Read this guide
- **Already familiar with flows** → Skip to [experiments.md](experiments.md) or [prompts-guide.md](prompts-guide.md)

---

## 1. Overview

Conversation flows are state machines that orchestrate structured dialogues for business process automation. They define how users move through conversation steps based on their responses.

### 1.1 Key Concepts

| Concept | Description |
|---------|-------------|
| **Flow** | A complete conversation flow definition (YAML file) |
| **State** | A single step in the conversation (question, confirmation, data collection) |
| **Transition** | Rule for moving from one state to another based on conditions |
| **Session** | Active conversation instance with current state and collected data |
| **Action** | Side effect executed during state transitions (set fields, API calls, logging) |
| **Validation** | Rules ensuring user input meets requirements |

### 1.2 How It Works

1. **Define flow** in YAML format in `/flows/` directory
2. **Flow Orchestrator** loads flow definition at runtime
3. **Session created** when conversation starts (stored in Redis)
4. **User messages** trigger state transitions based on conditions
5. **Validation** ensures input correctness before transitions
6. **Actions** execute side effects (data storage, API calls, logging)

**Related**: [architecture.md](architecture.md) (section on Flow Orchestrator), [../flows/SCHEMA.md](../flows/SCHEMA.md) for complete schema

---

## 2. Flow Structure

### 2.1 Basic Flow Definition

A flow is defined in YAML format:

```yaml
flow:
  name: user_onboarding
  version: "1.0.0"
  description: "Collect user name and email through a guided onboarding flow"
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
    
    ask_email:
      type: data_collection
      message: "What is your email address?"
      validation:
        required: true
        type: email
    
    complete:
      type: end
      message: "Thank you! Your information has been saved."

  transitions:
    - from: ask_name
      to: ask_email
      condition:
        type: always
    
    - from: ask_email
      to: complete
      condition:
        type: always
```

### 2.2 Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Unique flow identifier |
| `version` | string | Flow version (semantic versioning, e.g., "1.0.0") |
| `initial_state` | string | Name of starting state (must exist in `states`) |
| `states` | object | Map of state definitions |

**Related**: [../flows/SCHEMA.md](../flows/SCHEMA.md) for complete schema reference

---

## 3. State Types

States represent different types of conversation steps:

### 3.1 Question State

Asks user a question and expects a response:

```yaml
ask_name:
  type: question
  message: "What is your name?"
  validation:
    required: true
    type: string
```

### 3.2 Confirmation State

Asks for confirmation (yes/no, proceed/cancel):

```yaml
confirm:
  type: confirmation
  message:
    text: "Is this information correct?"
    buttons:
      - label: "Yes, continue"
        value: "yes"
      - label: "No, go back"
        value: "no"
```

### 3.3 Data Collection State

Collects structured data (form fields):

```yaml
collect_preferences:
  type: data_collection
  message: "What are your dietary preferences?"
  validation:
    required: true
    type: array
    items:
      type: string
      enum: ["vegetarian", "vegan", "gluten-free", "dairy-free"]
```

### 3.4 AI Response State

Uses AI/LLM to generate response based on context:

```yaml
ai_assistant:
  type: ai_response
  message: "Let me help you with that..."
  prompt_config:
    prompt_version_id: "uuid-prompt-v1"
  validation:
    required: false
```

### 3.5 End State

Terminal state indicating flow completion:

```yaml
complete:
  type: end
  message: "Thank you! Your information has been saved."
  actions:
    - type: log_event
      event_type: "flow_completed"
```

---

## 4. Transitions

Transitions define how users move from one state to another based on conditions.

### 4.1 Basic Transition

```yaml
transitions:
  - from: ask_name
    to: ask_email
    condition:
      type: always  # Unconditional transition
```

### 4.2 Conditional Transition

```yaml
transitions:
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

### 4.3 Condition Types

| Condition Type | Description | Example |
|----------------|-------------|---------|
| `always` | Always true (unconditional) | `type: always` |
| `equals` | Field equals value | `type: equals`, `field: "user_response"`, `value: "yes"` |
| `contains` | Field contains value | `type: contains`, `field: "preferences"`, `value: "vegetarian"` |
| `matches` | Field matches regex | `type: matches`, `field: "email"`, `value: "^[a-z]+@example.com$"` |
| `exists` | Field exists and is not null | `type: exists`, `field: "name"` |
| `and` | All conditions true | `type: and`, `conditions: [...]` |
| `or` | Any condition true | `type: or`, `conditions: [...]` |
| `not` | Condition is false | `type: not`, `condition: {...}` |

### 4.4 Complex Conditions

```yaml
transitions:
  - from: collect_info
    to: verify_age
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

**Related**: [../flows/SCHEMA.md](../flows/SCHEMA.md) (section on Condition Schema) for complete condition reference

---

## 5. Validation

Validation rules ensure user input meets requirements before allowing state transitions.

### 5.1 Basic Validation

```yaml
validation:
  required: true
  type: string
  min_length: 2
  max_length: 100
  error_message: "Name must be between 2 and 100 characters"
```

### 5.2 Validation Types

| Type | Description | Additional Rules |
|------|-------------|------------------|
| `string` | Text input | `min_length`, `max_length`, `pattern` |
| `number` | Numeric input | `min`, `max` |
| `email` | Email address | `pattern` (optional, has default) |
| `phone` | Phone number | `pattern` |
| `date` | Date input | `format` |
| `array` | List of items | `items`, `min_items`, `max_items` |

### 5.3 Validation Examples

**Email validation:**
```yaml
validation:
  required: true
  type: email
  pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
  error_message: "Please enter a valid email address"
```

**Number validation:**
```yaml
validation:
  required: true
  type: number
  min: 0
  max: 100
  error_message: "Age must be between 0 and 100"
```

**Array validation:**
```yaml
validation:
  required: true
  type: array
  min_items: 1
  max_items: 5
  items:
    type: string
    enum: ["option1", "option2", "option3"]
```

**Related**: [../flows/SCHEMA.md](../flows/SCHEMA.md) (section on Validation Schema) for complete validation reference

---

## 6. Actions

Actions execute side effects when entering a state or during transitions.

### 6.1 Set Field Action

Store user input in conversation context:

```yaml
actions:
  - type: set_field
    target: name
    value: "{{user_response}}"
```

### 6.2 Call API Action

Make HTTP API call:

```yaml
actions:
  - type: call_api
    target: "https://api.example.com/users"
    method: "POST"
    body:
      email: "{{email}}"
      name: "{{name}}"
    on_error: "continue"  # continue | retry | fail
```

### 6.3 Log Event Action

Log event to Event Ingestion Service:

```yaml
actions:
  - type: log_event
    event_type: "flow_state_entered"
    data:
      state: "{{current_state}}"
      flow: "{{flow_name}}"
      user_id: "{{user_id}}"
```

### 6.4 Redirect Action

Redirect to another flow:

```yaml
actions:
  - type: redirect
    target: "other_flow_name"
```

**Related**: [../flows/SCHEMA.md](../flows/SCHEMA.md) (section on Action Schema) for complete action reference

---

## 7. Flow Patterns

### 7.1 Linear Flow

Step-by-step guided sequence:

```yaml
flow:
  name: linear_onboarding
  initial_state: step1
  
  states:
    step1:
      type: question
      message: "Step 1: What is your name?"
    step2:
      type: question
      message: "Step 2: What is your email?"
    complete:
      type: end
      message: "Done!"
  
  transitions:
    - from: step1
      to: step2
      condition: { type: always }
    - from: step2
      to: complete
      condition: { type: always }
```

**Use cases:** Onboarding, surveys, step-by-step forms

### 7.2 Decision Tree Flow

Branching logic based on user responses:

```yaml
flow:
  name: support_flow
  initial_state: ask_issue
  
  states:
    ask_issue:
      type: question
      message: "What is your issue?"
    technical_support:
      type: question
      message: "Let me help with technical support..."
    billing_support:
      type: question
      message: "Let me help with billing..."
    complete:
      type: end
  
  transitions:
    - from: ask_issue
      to: technical_support
      condition:
        type: contains
        field: user_response
        value: "technical"
    - from: ask_issue
      to: billing_support
      condition:
        type: contains
        field: user_response
        value: "billing"
    - from: technical_support
      to: complete
      condition: { type: always }
    - from: billing_support
      to: complete
      condition: { type: always }
```

**Use cases:** Support flows, routing, conditional paths

### 7.3 Hybrid Flow

Combining rule-based and AI-driven paths:

```yaml
flow:
  name: hybrid_assistant
  initial_state: collect_info
  
  states:
    collect_info:
      type: data_collection
      message: "What information do you need?"
    rule_based_response:
      type: question
      message: "Based on rules: {{response}}"
    ai_response:
      type: ai_response
      message: "Let me help you with that..."
      prompt_config:
        prompt_version_id: "uuid-prompt-v1"
    complete:
      type: end
  
  transitions:
    - from: collect_info
      to: rule_based_response
      condition:
        type: equals
        field: info_type
        value: "simple"
    - from: collect_info
      to: ai_response
      condition:
        type: equals
        field: info_type
        value: "complex"
```

**Use cases:** Smart routing, fallback to AI, hybrid assistance

**Related**: [../flows/onboarding_flow.yml](../flows/onboarding_flow.yml) and [../flows/data_collection_flow.yml](../flows/data_collection_flow.yml) for complete examples

---

## 8. Session Management

### 8.1 Session Lifecycle

1. **Session created** when conversation starts
2. **Session stored** in Redis with expiry (default: 24 hours)
3. **Session updated** on each state transition
4. **Session expired** after inactivity or explicit timeout

### 8.2 Session Data

Session contains:
- `session_id`: Unique session identifier
- `flow_id`: Flow identifier
- `flow_version`: Flow version
- `current_state`: Current state name
- `previous_state`: Previous state name
- `conversation_data`: Collected data (fields set via actions)
- `user_id`: User identifier
- `created_at`: Session creation timestamp
- `updated_at`: Last update timestamp

### 8.3 Session Storage

Sessions are stored in Redis:
- **Key format:** `flow_session:{session_id}`
- **Expiry:** Configurable (default: 24 hours)
- **Data format:** JSON serialized session object

**Related**: [../services/flow-orchestrator/DESIGN.md](../services/flow-orchestrator/DESIGN.md) for implementation details

---

## 9. Using Flows in Experiments

### 9.1 Variant Configuration

Reference flows in experiment variant configs:

```yaml
experiments:
  - name: onboarding_flow_exp
    variants:
      - name: control
        allocation: 0.5
        config:
          execution_strategy: "prompt_template"
          prompt_config:
            prompt_version_id: "uuid-prompt-v1"
          flow_config:
            flow_id: "user_onboarding"
            initial_state: "ask_name"
```

### 9.2 Flow Orchestrator API

Start a conversation:

```bash
curl -X POST "https://api.example.com/api/v1/conversations" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "flow_id": "user_onboarding",
    "flow_version": "1.0.0",
    "user_id": "user-123",
    "context": {
      "experiment_id": "uuid-exp",
      "variant_id": "uuid-variant"
    }
  }'
```

Process a message:

```bash
curl -X POST "https://api.example.com/api/v1/conversations/{session_id}/messages" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "John Doe"
  }'
```

**Related**: [../services/flow-orchestrator/API_SPEC.md](../services/flow-orchestrator/API_SPEC.md) for complete API reference

---

## 10. Best Practices

### 10.1 Flow Design

- **Keep flows focused:** Each flow should have a single, clear purpose
- **Use descriptive state names:** Make state purpose clear from name
- **Progress indicators:** Use `metadata.progress` for UI feedback
- **Error handling:** Provide clear error messages in validation
- **Test transitions:** Ensure all paths are reachable and valid

### 10.2 State Management

- **Minimize state count:** Don't create unnecessary states
- **Reuse common patterns:** Create reusable state templates
- **Clear transitions:** Make transition conditions explicit
- **Handle edge cases:** Consider all possible user responses

### 10.3 Validation

- **Validate early:** Validate input as soon as possible
- **Clear error messages:** Provide helpful error messages
- **Progressive validation:** Validate step-by-step, not all at once
- **Type checking:** Use appropriate validation types

### 10.4 Performance

- **Cache flows:** Flow Orchestrator caches flow definitions
- **Efficient conditions:** Use simple conditions when possible
- **Limit session data:** Don't store unnecessary data in sessions
- **Set appropriate expiry:** Configure session expiry based on use case

---

## 11. Common Patterns

### 11.1 Confirmation Loop

Allow users to go back and correct information:

```yaml
flow:
  name: data_collection_with_confirmation
  version: "1.0.0"
  description: "Collect user info with confirmation step"
  initial_state: collect_info
  
  states:
    collect_info:
      type: data_collection
      message: "Please enter your name and email"
      validation:
        required: true
        type: object
        properties:
          name:
            type: string
            min_length: 2
          email:
            type: email
      metadata:
        progress: 0.5
    
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
        progress: 0.8
      actions:
        - type: set_field
          target: name
          value: "{{user_response.name}}"
        - type: set_field
          target: email
          value: "{{user_response.email}}"
    
    complete:
      type: end
      message: "Thank you! Your information has been saved."
      metadata:
        progress: 1.0

  transitions:
    - from: collect_info
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
      to: collect_info
      condition:
        type: equals
        field: user_response
        value: "no"
      actions:
        - type: set_field
          target: name
          value: ""
        - type: set_field
          target: email
          value: ""
```

**Key features:**
- Validation ensures data quality before confirmation
- Clear confirmation message showing collected data
- Ability to go back and correct information
- Progress indicators for user feedback

### 11.2 Skip Conditions

Skip states based on collected data:

```yaml
flow:
  name: onboarding_with_skip
  version: "1.0.0"
  description: "Onboarding that skips premium questions for premium users"
  initial_state: collect_user_type
  
  states:
    collect_user_type:
      type: question
      message: "What type of user are you? (free/premium)"
      validation:
        required: true
        type: string
        enum: ["free", "premium"]
      actions:
        - type: set_field
          target: user_type
          value: "{{user_response}}"
    
    ask_premium:
      type: question
      message: "Do you want premium features?"
      metadata:
        skip_conditions:
          - type: equals
            field: user_type
            value: "premium"
      # This state will be skipped if user_type is "premium"
    
    complete:
      type: end
      message: "Onboarding complete!"

  transitions:
    - from: collect_user_type
      to: ask_premium
      condition:
        type: always
    
    - from: ask_premium
      to: complete
      condition:
        type: always
```

**Note:** When `skip_conditions` are met, the Flow Orchestrator automatically skips to the next valid state.

### 11.3 Multi-Step Data Collection

Collect multiple fields in sequence:

```yaml
states:
  collect_name:
    type: data_collection
    message: "What is your name?"
  collect_email:
    type: data_collection
    message: "What is your email?"
  collect_phone:
    type: data_collection
    message: "What is your phone number?"
```

---

## 12. Common Mistakes

### 12.1 Flow Design Mistakes

**Mistake: Circular state transitions**

- **Problem:** Creating loops that trap users in states (e.g., A→B→A with no exit)
- **Solution:** Ensure every flow path eventually reaches an `end` state
- **Why:** Prevents users from getting stuck in infinite loops

**Mistake: Missing transition conditions**

- **Problem:** State has no valid transitions, leaving users stuck
- **Solution:** Always provide at least one transition with `type: always` or proper conditions
- **Why:** Users need a way to progress through the flow

**Mistake: Overly complex flows**

- **Problem:** Too many states and transitions make flows hard to maintain and debug
- **Solution:** Break complex flows into smaller, focused flows
- **Why:** Simpler flows are easier to test, debug, and modify

**Mistake: Not handling all user input possibilities**

- **Problem:** Flow only handles expected inputs, fails on unexpected responses
- **Solution:** Add catch-all transitions or validation with helpful error messages
- **Why:** Users don't always follow expected patterns

### 12.2 State Management Mistakes

**Mistake: Not clearing session data between flows**

- **Problem:** Data from previous flow contaminates new flow
- **Solution:** Clear conversation_data when starting new flow or use flow-specific namespaces
- **Why:** Prevents data leakage between different conversation contexts

**Mistake: Storing sensitive data in session**

- **Problem:** Storing passwords, tokens, or PII in Redis sessions
- **Solution:** Store only necessary conversation state, keep sensitive data encrypted or in secure storage
- **Why:** Redis sessions may be accessible to multiple services

**Mistake: Not setting appropriate session expiry**

- **Problem:** Sessions expire too quickly (frustrating users) or too slowly (wasting resources)
- **Solution:** Set expiry based on flow complexity and expected conversation duration
- **Why:** Balances user experience with resource usage

### 12.3 Validation Mistakes

**Mistake: Overly strict validation**

- **Problem:** Rejecting valid inputs due to overly narrow validation rules
- **Solution:** Use appropriate validation types and provide helpful error messages
- **Why:** Users may format inputs differently than expected

**Mistake: Not validating before state transition**

- **Problem:** Invalid data causes errors in subsequent states
- **Solution:** Always validate input before transitioning to next state
- **Why:** Prevents cascading errors and provides immediate feedback

**Mistake: Generic error messages**

- **Problem:** Error messages don't help users understand what went wrong
- **Solution:** Provide specific, actionable error messages in validation
- **Example:**
  - ❌ Bad: "Invalid input"
  - ✅ Good: "Email must be a valid email address (e.g., user@example.com)"

---

## 13. Troubleshooting

### 13.1 Common Issues

**Issue: Flow not found**

- **Symptom:** Flow Orchestrator returns 404 or flow not found error
- **Solution:** Verify flow file exists in `/flows/` directory
- **Check:** Flow name and version match variant config
- **Debug steps:**
  1. List flow files: `ls flows/`
  2. Verify flow_id in variant config matches filename (without extension)
  3. Check Flow Orchestrator can access `/flows/` directory
  4. Validate YAML syntax: `yamllint flows/my_flow.yml`

**Issue: Invalid transition**

- **Symptom:** User stuck in state, no valid transitions
- **Solution:** Check transition conditions match user input
- **Check:** Verify all required fields are set before transition
- **Debug steps:**
  1. Inspect current session state: Check Redis for session data
  2. List all transitions from current state: Review flow definition
  3. Evaluate conditions manually: Test condition logic with current data
  4. Check for typos in field names or condition values

**Issue: Session expired**

- **Symptom:** Session not found error
- **Solution:** Increase session expiry or handle expiry gracefully
- **Check:** Verify Redis connection and session storage
- **Debug steps:**
  1. Check Redis connection: `redis-cli ping`
  2. Verify session expiry setting: Check Flow Orchestrator configuration
  3. Check session TTL: `redis-cli TTL flow_session:{session_id}`
  4. Review session creation logs: Ensure sessions are being created

**Issue: State transition loops**

- **Symptom:** User keeps returning to same state
- **Solution:** Review transition conditions to find circular references
- **Check:** Trace transition path to identify loop
- **Debug steps:**
  1. Map all transitions: Create visual diagram of state flow
  2. Identify cycles: Look for states that transition back to themselves
  3. Check condition logic: Verify conditions aren't always true when they shouldn't be

**Issue: Validation always fails**

- **Symptom:** User input never passes validation, can't progress
- **Solution:** Review validation rules for correctness and appropriateness
- **Check:** Test validation with sample inputs
- **Debug steps:**
  1. Test validation independently: Validate input outside flow context
  2. Check validation type: Ensure type matches input (e.g., string vs number)
  3. Review regex patterns: Test patterns with regex tester
  4. Check for required fields: Ensure all required fields are provided

**Issue: Actions not executing**

- **Symptom:** Actions defined in transitions or states don't run
- **Solution:** Verify action syntax and check Flow Orchestrator logs
- **Check:** Ensure actions are defined correctly in YAML
- **Debug steps:**
  1. Validate YAML syntax: Check for indentation errors
  2. Review action types: Ensure action type is supported
  3. Check action parameters: Verify all required parameters are provided
  4. Review service logs: Check for action execution errors

### 13.2 Debugging Tips

- **Check flow definition:** Validate YAML syntax with `yamllint` or online validator
- **Verify state names:** Ensure all referenced states exist in flow definition
- **Test conditions:** Verify condition logic matches expected behavior with sample data
- **Check session data:** Inspect conversation_data in Redis: `redis-cli GET flow_session:{session_id}`
- **Review logs:** Check Flow Orchestrator logs for errors or warnings
- **Trace execution:** Add logging actions to track flow execution path
- **Validate transitions:** Manually test each transition with sample inputs
- **Check Redis connectivity:** Ensure Flow Orchestrator can connect to Redis
- **Review flow version:** Verify correct flow version is loaded
- **Test with curl:** Use Flow Orchestrator API directly to test flows

---

## 14. Further Exploration

- **Flow schema reference** → [../flows/SCHEMA.md](../flows/SCHEMA.md)
- **Example flows** → [../flows/README.md](../flows/README.md)
- **Flow Orchestrator API** → [../services/flow-orchestrator/API_SPEC.md](../services/flow-orchestrator/API_SPEC.md)
- **Flow Orchestrator design** → [../services/flow-orchestrator/DESIGN.md](../services/flow-orchestrator/DESIGN.md)
- **Using flows in experiments** → [experiments.md](experiments.md) (section 4.4)
- **Prompt management** → [prompts-guide.md](prompts-guide.md)
- **Complete example project** → [../examples/conversational-assistant/README.md](../examples/conversational-assistant/README.md)
- **Conversational AI quickstart** → [routes/conversational-ai-route.md](routes/conversational-ai-route.md)

**See Also:**
- [choosing-project-type.md](choosing-project-type.md) - Help deciding if flows are right for your project
- [mcp-integration.md](mcp-integration.md) - Using MCP tools in flows
- [experiments.md](experiments.md) - Configuring experiments with flows

---

## Quick Reference: State Types and Conditions

### State Types
| Type | Purpose | Use Case |
|------|---------|----------|
| `question` | Ask user a question | Simple Q&A |
| `confirmation` | Get yes/no confirmation | Confirm actions |
| `data_collection` | Collect structured data | Forms, multi-field input |
| `ai_response` | Generate AI response | LLM-powered interactions |
| `end` | Terminal state | Flow completion |

### Condition Types
| Type | Description | Example |
|------|-------------|---------|
| `always` | Always true | Unconditional transition |
| `equals` | Field equals value | `field: "user_response"`, `value: "yes"` |
| `contains` | Field contains value | Check if array/string contains item |
| `matches` | Field matches regex | Email validation |
| `exists` | Field exists and not null | Check if data collected |
| `and` | All conditions true | Complex logic |
| `or` | Any condition true | Multiple options |

---

## After Completing This Document

You will understand:
- How conversation flows work as state machines
- How to define flows in YAML format
- Different flow patterns (linear, decision tree, hybrid)
- How sessions are managed
- Best practices for flow design
- Common mistakes and troubleshooting

**Next Step**: [experiments.md](experiments.md) or [prompts-guide.md](prompts-guide.md)
