# Flow Orchestrator Service Design

**Purpose**  
This document describes the internal design and architecture decisions for the Flow Orchestrator Service, which executes conversation flows as state machines.

---

## Start Here If…

- **Implementing the service** → Read this document
- **Calling the service** → Go to [API_SPEC.md](API_SPEC.md)
- **Understanding flow schema** → Go to [../../flows/SCHEMA.md](../../flows/SCHEMA.md)
- **Understanding conversation flows** → Go to [../../docs/conversation-flows.md](../../docs/conversation-flows.md) (coming in Phase 6)

---

## 1. Service Overview

### 1.1 Responsibilities

| Responsibility | Description |
|----------------|-------------|
| Flow Execution | Execute conversation flows as state machines |
| State Transitions | Evaluate conditions and transition between states |
| Session Management | Maintain conversation state in Redis |
| Message Processing | Process user messages and validate input |
| Action Execution | Execute actions (set fields, API calls, logging) |
| Validation | Validate user input against state validation rules |

### 1.2 Non-Responsibilities

| Not Responsible For | Handled By |
|---------------------|------------|
| Flow definition storage | File system (`/flows/` directory) |
| Event logging | Event Ingestion Service |
| Prompt template retrieval | Prompt Service |
| LLM API calls | Client application or separate LLM service |

---

## 2. Architecture

### 2.1 Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│              Flow Orchestrator Service                       │
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐ │
│  │   API Layer  │ ──►│   Flow       │ ──►│   Session    │ │
│  │              │    │   Engine     │    │   Manager    │ │
│  └──────────────┘    └──────────────┘    └──────────────┘ │
│         │                    │                    │         │
│         │                    ▼                    ▼         │
│         │            ┌──────────────┐    ┌──────────────┐ │
│         │            │   Flow       │    │   Redis      │ │
│         │            │   Loader     │    │   (Sessions) │ │
│         │            └──────────────┘    └──────────────┘ │
│         │                    │                             │
│         ▼                    ▼                             │
│  ┌──────────────┐    ┌──────────────┐                   │
│  │   Validator  │    │   Action      │                   │
│  │              │    │   Executor    │                   │
│  └──────────────┘    └──────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow

```
1. Request arrives at API layer (start conversation or process message)
2. API validates request and extracts session_id
3. Session Manager loads session state from Redis
4. Flow Engine loads flow definition (cached)
5. Flow Engine evaluates current state and user input
6. Validator checks input against state validation rules
7. Flow Engine evaluates transition conditions
8. If valid transition: execute actions, update state
9. Session Manager persists updated state to Redis
10. Return response with new state and message
```

---

## 3. Flow Execution Engine

### 3.1 Flow Loading

Flows are loaded from YAML files in the `/flows/` directory.

```pseudo
function load_flow(flow_id, flow_version=None):
    """
    Load flow definition from file system.
    Returns parsed flow object.
    """
    # Determine file path
    if flow_version:
        file_path = f"flows/{flow_id}_v{flow_version}.yml"
    else:
        # Load latest version (find highest version file)
        file_path = find_latest_flow_file(flow_id)
    
    # Load and parse YAML
    with open(file_path, 'r') as f:
        flow_yaml = yaml.safe_load(f)
    
    # Validate schema
    validate_flow_schema(flow_yaml)
    
    # Parse into internal representation
    flow = parse_flow(flow_yaml)
    
    # Cache flow definition
    cache.set(f"flow:{flow_id}:{flow.version}", flow, ttl=3600)
    
    return flow
```

### 3.2 Flow Caching

```pseudo
# Cache key format
flow:{flow_id}:{flow_version}

# Cache value: Parsed flow object (in-memory structure)
# TTL: 1 hour (flows don't change frequently)

# Cache invalidation: On file system change (watch for file updates)
```

### 3.3 Flow Parsing

```pseudo
function parse_flow(flow_yaml):
    """
    Parse YAML flow definition into internal representation.
    """
    flow = {
        "id": flow_yaml["flow"]["name"],
        "version": flow_yaml["flow"]["version"],
        "initial_state": flow_yaml["flow"]["initial_state"],
        "states": {},
        "transitions": []
    }
    
    # Parse states
    for state_name, state_def in flow_yaml["flow"]["states"].items():
        flow["states"][state_name] = {
            "name": state_name,
            "type": state_def["type"],
            "message": parse_message(state_def["message"]),
            "validation": state_def.get("validation"),
            "actions": state_def.get("actions", []),
            "metadata": state_def.get("metadata", {})
        }
    
    # Parse transitions
    for transition in flow_yaml["flow"].get("transitions", []):
        flow["transitions"].append({
            "from": transition["from"],
            "to": transition["to"],
            "condition": parse_condition(transition["condition"]),
            "actions": transition.get("actions", []),
            "priority": transition.get("priority", 0)
        })
    
    # Validate flow structure
    validate_flow_structure(flow)
    
    return flow
```

---

## 4. State Machine Execution

### 4.1 State Transition Logic

```pseudo
function process_message(session_id, user_message):
    """
    Process user message and transition to next state.
    """
    # Load session
    session = session_manager.get(session_id)
    if not session:
        raise SessionNotFound()
    
    # Load flow
    flow = load_flow(session.flow_id, session.flow_version)
    
    # Get current state
    current_state = flow.states[session.current_state]
    
    # Validate input
    validation_result = validate_input(
        user_message,
        current_state.validation,
        session.conversation_data
    )
    
    if not validation_result.valid:
        # Stay in current state, return validation errors
        return {
            "current_state": session.current_state,
            "validation_errors": validation_result.errors,
            "message": current_state.message
        }
    
    # Find valid transitions
    valid_transitions = find_valid_transitions(
        flow.transitions,
        session.current_state,
        user_message,
        session.conversation_data
    )
    
    if not valid_transitions:
        # No valid transition - stay in current state
        return {
            "current_state": session.current_state,
            "validation_errors": [{
                "field": "message",
                "error": "invalid_transition",
                "message": "No valid transition for this input"
            }],
            "message": current_state.message
        }
    
    # Select transition (highest priority, or first match)
    transition = select_transition(valid_transitions)
    
    # Execute transition actions
    updated_data = execute_actions(
        transition.actions,
        user_message,
        session.conversation_data
    )
    
    # Update conversation data
    session.conversation_data.update(updated_data)
    
    # Transition to next state
    next_state = flow.states[transition.to]
    session.previous_state = session.current_state
    session.current_state = transition.to
    
    # Execute state entry actions
    updated_data = execute_actions(
        next_state.actions,
        user_message,
        session.conversation_data
    )
    session.conversation_data.update(updated_data)
    
    # Update state history
    session.state_history.append({
        "state": session.previous_state,
        "entered_at": session.state_history[-1]["exited_at"] if session.state_history else session.created_at,
        "exited_at": now()
    })
    
    # Check if terminal state
    if next_state.type == "end":
        session.flow_completed = True
        session.completed_at = now()
    
    # Persist session
    session_manager.save(session)
    
    # Return response
    return {
        "current_state": session.current_state,
        "previous_state": session.previous_state,
        "state_type": next_state.type,
        "message": render_message(next_state.message, session.conversation_data),
        "progress": next_state.metadata.get("progress", 0.0),
        "conversation_data": session.conversation_data,
        "flow_completed": session.flow_completed
    }
```

### 4.2 Condition Evaluation

```pseudo
function evaluate_condition(condition, user_message, conversation_data):
    """
    Evaluate transition condition.
    Returns True if condition is satisfied.
    """
    condition_type = condition["type"]
    
    if condition_type == "always":
        return True
    
    elif condition_type == "equals":
        field_value = get_field_value(condition["field"], user_message, conversation_data)
        return field_value == condition["value"]
    
    elif condition_type == "contains":
        field_value = get_field_value(condition["field"], user_message, conversation_data)
        if isinstance(field_value, str):
            return condition["value"] in field_value
        elif isinstance(field_value, list):
            return condition["value"] in field_value
        return False
    
    elif condition_type == "matches":
        field_value = get_field_value(condition["field"], user_message, conversation_data)
        pattern = condition["value"]
        return bool(re.match(pattern, str(field_value)))
    
    elif condition_type == "exists":
        field_value = get_field_value(condition["field"], user_message, conversation_data)
        return field_value is not None
    
    elif condition_type == "and":
        return all(
            evaluate_condition(c, user_message, conversation_data)
            for c in condition["conditions"]
        )
    
    elif condition_type == "or":
        return any(
            evaluate_condition(c, user_message, conversation_data)
            for c in condition["conditions"]
        )
    
    elif condition_type == "not":
        return not evaluate_condition(
            condition["conditions"][0],
            user_message,
            conversation_data
        )
    
    elif condition_type == "custom":
        # Custom condition evaluated by flow orchestrator
        return evaluate_custom_condition(
            condition,
            user_message,
            conversation_data
        )
    
    else:
        raise InvalidConditionError(f"Unknown condition type: {condition_type}")
```

### 4.3 Field Value Resolution

```pseudo
function get_field_value(field_name, user_message, conversation_data):
    """
    Resolve field value from user message or conversation data.
    """
    # Check conversation data first
    if field_name in conversation_data:
        return conversation_data[field_name]
    
    # Check user message (for current input)
    if field_name == "user_response":
        return user_message
    
    # Check nested fields (e.g., "context.experiment_id")
    if "." in field_name:
        parts = field_name.split(".")
        obj = conversation_data if parts[0] in conversation_data else None
        for part in parts[1:]:
            if obj and isinstance(obj, dict) and part in obj:
                obj = obj[part]
            else:
                return None
        return obj
    
    return None
```

---

## 5. Validation Hooks

### 5.1 Input Validation

```pseudo
function validate_input(user_message, validation_rules, conversation_data):
    """
    Validate user input against state validation rules.
    Returns ValidationResult.
    """
    if not validation_rules:
        return ValidationResult(valid=True, errors=[])
    
    errors = []
    
    # Required field check
    if validation_rules.get("required", False):
        if not user_message or not user_message.strip():
            errors.append({
                "field": "message",
                "error": "required",
                "message": validation_rules.get("error_message", "This field is required")
            })
            return ValidationResult(valid=False, errors=errors)
    
    # Type validation
    if "type" in validation_rules:
        type_error = validate_type(user_message, validation_rules["type"])
        if type_error:
            errors.append(type_error)
    
    # Length validation (for strings)
    if "min_length" in validation_rules:
        if len(user_message) < validation_rules["min_length"]:
            errors.append({
                "field": "message",
                "error": "min_length",
                "message": validation_rules.get("error_message", f"Minimum length is {validation_rules['min_length']}")
            })
    
    if "max_length" in validation_rules:
        if len(user_message) > validation_rules["max_length"]:
            errors.append({
                "field": "message",
                "error": "max_length",
                "message": validation_rules.get("error_message", f"Maximum length is {validation_rules['max_length']}")
            })
    
    # Pattern validation (regex)
    if "pattern" in validation_rules:
        if not re.match(validation_rules["pattern"], user_message):
            errors.append({
                "field": "message",
                "error": "pattern",
                "message": validation_rules.get("error_message", "Invalid format")
            })
    
    # Custom validator
    if "custom_validator" in validation_rules:
        custom_error = call_custom_validator(
            validation_rules["custom_validator"],
            user_message,
            conversation_data
        )
        if custom_error:
            errors.append(custom_error)
    
    return ValidationResult(valid=len(errors) == 0, errors=errors)
```

### 5.2 Type Validation

```pseudo
function validate_type(value, expected_type):
    """
    Validate value matches expected type.
    Returns error dict if invalid, None if valid.
    """
    if expected_type == "string":
        if not isinstance(value, str):
            return {"field": "message", "error": "type", "message": "Expected string"}
    
    elif expected_type == "number":
        try:
            float(value)
        except (ValueError, TypeError):
            return {"field": "message", "error": "type", "message": "Expected number"}
    
    elif expected_type == "email":
        pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
        if not re.match(pattern, value):
            return {"field": "message", "error": "type", "message": "Invalid email format"}
    
    elif expected_type == "phone":
        # Basic phone validation (can be enhanced)
        pattern = r"^\+?[\d\s\-\(\)]+$"
        if not re.match(pattern, value):
            return {"field": "message", "error": "type", "message": "Invalid phone format"}
    
    elif expected_type == "date":
        # Try parsing common date formats
        try:
            parse_date(value)
        except ValueError:
            return {"field": "message", "error": "type", "message": "Invalid date format"}
    
    return None
```

---

## 6. Action Execution

### 6.1 Action Types

```pseudo
function execute_actions(actions, user_message, conversation_data):
    """
    Execute actions and return updated conversation data.
    """
    updated_data = {}
    
    for action in actions:
        action_type = action["type"]
        
        if action_type == "set_field":
            # Set field in conversation data
            target = action["target"]
            value = render_template(action["value"], user_message, conversation_data)
            updated_data[target] = value
        
        elif action_type == "validate":
            # Validate field (already handled in validation step)
            pass
        
        elif action_type == "call_api":
            # Make HTTP API call
            api_result = call_external_api(action, conversation_data)
            if "result_field" in action:
                updated_data[action["result_field"]] = api_result
        
        elif action_type == "log_event":
            # Log event to event ingestion service
            log_to_event_service(action, conversation_data)
        
        elif action_type == "redirect":
            # Redirect to another flow (handled at API level)
            pass
        
        else:
            raise InvalidActionError(f"Unknown action type: {action_type}")
    
    return updated_data
```

### 6.2 Template Rendering

```pseudo
function render_template(template, user_message, conversation_data):
    """
    Render template string with variable substitution.
    Supports {{variable}} syntax.
    """
    # Simple template rendering (can use Jinja2 or similar)
    result = template
    
    # Replace {{variable}} with values
    pattern = r"\{\{(\w+(?:\.\w+)*)\}\}"
    
    def replace_var(match):
        var_path = match.group(1)
        value = get_field_value(var_path, user_message, conversation_data)
        return str(value) if value is not None else ""
    
    result = re.sub(pattern, replace_var, result)
    
    return result
```

### 6.3 Message Rendering

```pseudo
function render_message(message_def, conversation_data):
    """
    Render message definition with variable substitution.
    """
    if isinstance(message_def, str):
        # Simple string message
        return {
            "text": render_template(message_def, None, conversation_data),
            "quick_replies": [],
            "buttons": []
        }
    
    # Structured message
    message = {
        "text": render_template(message_def.get("text", ""), None, conversation_data),
        "quick_replies": message_def.get("quick_replies", []),
        "buttons": []
    }
    
    # Render buttons
    for button in message_def.get("buttons", []):
        message["buttons"].append({
            "label": render_template(button.get("label", ""), None, conversation_data),
            "value": button.get("value", ""),
            "action": button.get("action")
        })
    
    return message
```

---

## 7. Session State Management

### 7.1 Session Data Structure

#### 7.1.1 Session ID Format

Session IDs are opaque, unpredictable identifiers generated using cryptographically secure random generation:

```pseudo
function generate_session_id():
    """
    Generate a new session ID.
    Format: session-{random_hex_string}
    Example: session-a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
    """
    random_bytes = os.urandom(24)  # 24 bytes = 48 hex characters
    hex_string = binascii.hexlify(random_bytes).decode('ascii')
    return f"session-{hex_string}"
```

**Properties:**
- **Length**: 56 characters (8 char prefix + 48 char hex)
- **Unpredictability**: Cryptographically secure random generation
- **Uniqueness**: Extremely low collision probability
- **Format**: `session-{48_hex_chars}`

#### 7.1.2 Session Object Structure

```pseudo
Session {
    # Core identifiers
    session_id: string              # Unique session identifier
    flow_id: string                # Flow being executed
    flow_version: string            # Flow version
    
    # State tracking
    current_state: string           # Current state name in flow
    previous_state: string | null    # Previous state (for history)
    state_type: string              # Type of current state
    
    # Context and data
    context: object {               # Immutable context set at creation
        user_id: string
        experiment_id: string | null
        variant_id: string | null
        platform: string | null
        locale: string | null
        [custom_fields]: any
    }
    conversation_data: object {    # Mutable data collected during conversation
        [field_name]: any          # Fields set by actions
    }
    
    # History
    state_history: array [         # History of states visited
        {
            state: string
            entered_at: timestamp
            exited_at: timestamp | null  # null if current state
        }
    ]
    
    # Status
    flow_completed: boolean         # Whether flow reached terminal state
    
    # Timestamps
    created_at: timestamp           # Session creation time
    updated_at: timestamp           # Last update time
    expires_at: timestamp           # Expiration time
}
```

#### 7.1.3 Session Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `session_id` | string | Unique identifier, format: `session-{48hex}` |
| `flow_id` | string | Flow identifier (e.g., `user_onboarding`) |
| `flow_version` | string | Flow version (semantic versioning) |
| `current_state` | string | Current state name in flow state machine |
| `previous_state` | string \| null | Previous state name (null for initial state) |
| `state_type` | string | Type: `question`, `confirmation`, `data_collection`, `ai_response`, `end` |
| `context` | object | Immutable context (set at creation, never changes) |
| `context.user_id` | string | User identifier |
| `context.experiment_id` | string \| null | Experiment ID if part of A/B test |
| `context.variant_id` | string \| null | Variant ID if part of A/B test |
| `conversation_data` | object | Mutable data collected during conversation |
| `state_history` | array | Array of state visit records |
| `flow_completed` | boolean | True if flow reached terminal state |
| `created_at` | timestamp | ISO 8601 timestamp |
| `updated_at` | timestamp | ISO 8601 timestamp |
| `expires_at` | timestamp | ISO 8601 timestamp |

### 7.2 Redis Data Structures

#### 7.2.1 Key Naming Convention

```
session:{session_id}
```

**Examples:**
- `session-a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`
- `session-1234567890abcdef1234567890abcdef1234567890abcdef`

**Properties:**
- **Prefix**: `session:` for namespacing
- **Uniqueness**: Session ID ensures uniqueness
- **Pattern matching**: Supports `session:*` pattern for scanning

#### 7.2.2 Storage Format

**Option A: JSON String (Recommended)**

```pseudo
# Redis key: session:{session_id}
# Redis value: JSON-encoded session object
# Redis type: STRING
# TTL: Set via EXPIRE command

{
  "session_id": "session-a1b2c3...",
  "flow_id": "user_onboarding",
  "flow_version": "1.0.0",
  "current_state": "ask_email",
  "previous_state": "ask_name",
  "state_type": "data_collection",
  "context": {
    "user_id": "user-123",
    "experiment_id": "550e8400-...",
    "variant_id": "660e8400-..."
  },
  "conversation_data": {
    "name": "John Doe"
  },
  "state_history": [
    {
      "state": "ask_name",
      "entered_at": "2025-02-09T10:00:00Z",
      "exited_at": "2025-02-09T10:00:31Z"
    }
  ],
  "flow_completed": false,
  "created_at": "2025-02-09T10:00:00Z",
  "updated_at": "2025-02-09T10:00:31Z",
  "expires_at": "2025-02-09T10:15:00Z"
}
```

**Option B: Redis Hash (Alternative)**

```pseudo
# Redis key: session:{session_id}
# Redis type: HASH
# TTL: Set via EXPIRE command

HSET session:{session_id} session_id "session-a1b2c3..."
HSET session:{session_id} flow_id "user_onboarding"
HSET session:{session_id} current_state "ask_email"
HSET session:{session_id} context '{"user_id":"user-123",...}'
HSET session:{session_id} conversation_data '{"name":"John Doe"}'
# ... other fields
```

**Design Choice: Option A (JSON String)**

**Rationale:**
- Simpler implementation (single SET/GET operation)
- Atomic updates (entire session updated at once)
- Better for complex nested structures
- Easier to migrate to other storage backends
- Slight performance trade-off (JSON parsing) is acceptable

#### 7.2.3 TTL Usage

```pseudo
# Set TTL when creating/updating session
EXPIRE session:{session_id} {ttl_seconds}

# Check remaining TTL
TTL session:{session_id}  # Returns seconds until expiration, -1 if no TTL, -2 if key doesn't exist

# Remove TTL (make key persistent)
PERSIST session:{session_id}
```

### 7.3 Session Expiry Strategy

#### 7.3.1 TTL Configuration

| Scenario | Default TTL | Configurable |
|----------|-------------|--------------|
| Initial creation | 15 minutes | Yes |
| On message update | 15 minutes (reset) | Yes |
| On state transition | 15 minutes (reset) | Yes |
| Completed flows | 1 hour (extended) | Yes |
| Inactive sessions | 15 minutes | Yes |

#### 7.3.2 Inactivity Timeout

```pseudo
function extend_session_on_activity(session):
    """
    Extend session expiration on any activity.
    """
    # Reset TTL to default inactivity timeout
    inactivity_timeout = config.get("session_inactivity_timeout_minutes", 15)
    session.expires_at = now() + timedelta(minutes=inactivity_timeout)
    session.updated_at = now()
    save_session(session)
```

**Activity Events:**
- Processing a message
- Getting session state
- Resetting conversation

**Inactivity Detection:**
- No activity for `inactivity_timeout` minutes
- Session automatically expires via Redis TTL
- Expired sessions return 410 Gone

#### 7.3.3 Configurable Timeouts

```pseudo
# Configuration options
SESSION_INACTIVITY_TIMEOUT_MINUTES = 15  # Default: 15 minutes
SESSION_COMPLETED_TTL_MINUTES = 60       # Extended TTL for completed flows
SESSION_MAX_TTL_MINUTES = 1440           # Maximum TTL (24 hours)
```

**Configuration Sources:**
1. Environment variables
2. Configuration file
3. Per-flow configuration (in flow metadata)

#### 7.3.4 Expiration Handling

```pseudo
function get_session_with_expiry_check(session_id):
    """
    Get session and check if expired.
    """
    session = get_session(session_id)
    
    if not session:
        return None
    
    # Check expiration
    if now() >= session.expires_at:
        # Session expired, delete it
        delete_session(session_id)
        raise SessionExpired(session_id, session.expires_at)
    
    return session
```

### 7.4 Concurrent Session Handling

#### 7.4.1 Session Isolation

Each session is isolated by unique `session_id`:
- **No shared state**: Sessions never share data
- **Independent execution**: Concurrent requests for same session are serialized
- **User isolation**: Different users have different sessions

#### 7.4.2 Distributed Locks

```pseudo
function process_message_with_lock(session_id, user_message):
    """
    Process message with distributed lock to prevent concurrent modifications.
    """
    lock_key = f"lock:session:{session_id}"
    lock_timeout = 5  # seconds
    
    # Acquire lock
    lock_acquired = redis.set(
        lock_key,
        "locked",
        ex=lock_timeout,
        nx=True  # Only set if not exists
    )
    
    if not lock_acquired:
        # Another request is processing this session
        raise ConcurrentRequestError("Session is being processed by another request")
    
    try:
        # Process message
        result = process_message(session_id, user_message)
        return result
    finally:
        # Release lock
        redis.delete(lock_key)
```

**Lock Properties:**
- **Key format**: `lock:session:{session_id}`
- **Timeout**: 5 seconds (prevents deadlock)
- **Automatic release**: Redis TTL ensures lock is released even if process crashes
- **Retry logic**: Clients can retry after lock timeout

#### 7.4.3 Message Queue (Alternative Approach)

For high-concurrency scenarios, use message queue pattern:

```pseudo
# Push message to queue
LPUSH queue:session:{session_id} {message_json}

# Worker processes messages sequentially
while True:
    message = BRPOP queue:session:{session_id}, timeout=5
    if message:
        process_message(session_id, message)
```

**Use Cases:**
- High message volume per session
- Need for guaranteed ordering
- Background processing acceptable

**Design Choice: Distributed Locks (Default)**

**Rationale:**
- Simpler implementation
- Lower latency (no queue overhead)
- Sufficient for typical conversation flows
- Can upgrade to message queue if needed

### 7.5 Session Recovery and State Restoration

#### 7.5.1 State Restoration After Interruption

```pseudo
function restore_session(session_id):
    """
    Restore session state after interruption (e.g., user reconnects).
    """
    session = get_session(session_id)
    
    if not session:
        # Session not found - may have expired
        raise SessionNotFound(session_id)
    
    if now() >= session.expires_at:
        # Session expired
        raise SessionExpired(session_id, session.expires_at)
    
    # Load flow to get current state details
    flow = load_flow(session.flow_id, session.flow_version)
    current_state = flow.states[session.current_state]
    
    # Return restored state
    return {
        "session_id": session.session_id,
        "current_state": session.current_state,
        "state_type": session.state_type,
        "message": render_message(current_state.message, session.conversation_data),
        "progress": current_state.metadata.get("progress", 0.0),
        "conversation_data": session.conversation_data,
        "state_history": session.state_history,
        "flow_completed": session.flow_completed
    }
```

#### 7.5.2 Graceful Degradation

```pseudo
function handle_session_recovery_error(session_id, error):
    """
    Handle session recovery errors gracefully.
    """
    if isinstance(error, SessionExpired):
        # Session expired - user needs to restart
        return {
            "error": "session_expired",
            "message": "Your session has expired. Please start a new conversation.",
            "expired_at": error.expires_at
        }
    
    elif isinstance(error, SessionNotFound):
        # Session not found - may have been cleaned up
        return {
            "error": "session_not_found",
            "message": "Session not found. Please start a new conversation."
        }
    
    else:
        # Unexpected error
        log_error("Session recovery failed", session_id=session_id, error=error)
        return {
            "error": "internal_error",
            "message": "Failed to restore session. Please try again."
        }
```

#### 7.5.3 State History for Recovery

State history enables:
- **Debugging**: Track conversation path
- **Analytics**: Analyze drop-off points
- **Recovery**: Understand where user left off
- **Replay**: Reconstruct conversation flow

```pseudo
# State history structure
state_history = [
    {
        "state": "ask_name",
        "entered_at": "2025-02-09T10:00:00Z",
        "exited_at": "2025-02-09T10:00:31Z"
    },
    {
        "state": "ask_email",
        "entered_at": "2025-02-09T10:00:31Z",
        "exited_at": null  # Current state
    }
]
```

### 7.6 Redis Integration Implementation

#### 7.6.1 Save Session

```pseudo
function save_session(session):
    """
    Save session to Redis with TTL.
    """
    key = f"session:{session.session_id}"
    value = json.dumps(session.to_dict())
    
    # Calculate TTL (time until expires_at)
    ttl_seconds = (session.expires_at - now()).total_seconds()
    ttl_seconds = max(int(ttl_seconds), 0)  # Ensure non-negative integer
    
    # Set value and TTL atomically
    redis.setex(key, ttl_seconds, value)
    
    # Log for monitoring
    log_metric("session_saved", session_id=session.session_id, ttl=ttl_seconds)
```

#### 7.6.2 Get Session

```pseudo
function get_session(session_id):
    """
    Load session from Redis.
    """
    key = f"session:{session_id}"
    value = redis.get(key)
    
    if not value:
        log_metric("session_not_found", session_id=session_id)
        return None
    
    try:
        session_dict = json.loads(value)
        session = Session.from_dict(session_dict)
        
        # Check expiration (defensive check)
        if now() >= session.expires_at:
            # Expired - delete and return None
            delete_session(session_id)
            log_metric("session_expired", session_id=session_id)
            return None
        
        return session
    except (json.JSONDecodeError, KeyError) as e:
        log_error("Failed to parse session", session_id=session_id, error=e)
        # Corrupted session - delete it
        delete_session(session_id)
        return None
```

#### 7.6.3 Delete Session

```pseudo
function delete_session(session_id):
    """
    Delete session from Redis.
    """
    key = f"session:{session_id}"
    redis.delete(key)
    log_metric("session_deleted", session_id=session_id)
```

#### 7.6.4 Extend Session

```pseudo
function extend_session(session, additional_minutes=None):
    """
    Extend session expiration time.
    """
    if additional_minutes is None:
        # Use default inactivity timeout
        additional_minutes = config.get("session_inactivity_timeout_minutes", 15)
    
    # Extend expiration
    session.expires_at = now() + timedelta(minutes=additional_minutes)
    session.updated_at = now()
    
    # Save with new TTL
    save_session(session)
```

### 7.7 Session Cleanup

#### 7.7.1 Background Cleanup Task

```pseudo
# Background task: Clean up expired sessions
function cleanup_expired_sessions():
    """
    Remove expired sessions from Redis.
    Runs periodically (e.g., every 5 minutes).
    """
    pattern = "session:*"
    cursor = 0
    deleted_count = 0
    
    while True:
        cursor, keys = redis.scan(cursor, match=pattern, count=100)
        
        for key in keys:
            # Check TTL
            ttl = redis.ttl(key)
            if ttl == -2:  # Key doesn't exist (already deleted)
                continue
            elif ttl == -1:  # No TTL set (shouldn't happen, but handle it)
                # Check if session is actually expired by loading it
                value = redis.get(key)
                if value:
                    try:
                        session_dict = json.loads(value)
                        expires_at = parse_timestamp(session_dict["expires_at"])
                        if now() >= expires_at:
                            redis.delete(key)
                            deleted_count += 1
                    except:
                        # Corrupted - delete it
                        redis.delete(key)
                        deleted_count += 1
            elif ttl < 0:  # Expired (shouldn't happen with TTL, but defensive)
                redis.delete(key)
                deleted_count += 1
        
        if cursor == 0:
            break
    
    log_metric("sessions_cleaned_up", count=deleted_count)
    return deleted_count
```

#### 7.7.2 Cleanup Scheduling

```pseudo
# Schedule cleanup task
schedule_periodic_task(
    function=cleanup_expired_sessions,
    interval_minutes=5,
    name="session_cleanup"
)
```

**Cleanup Frequency:**
- **Interval**: 5 minutes (configurable)
- **Purpose**: Remove expired sessions that weren't auto-deleted
- **Impact**: Low (only scans expired keys)

### 7.8 Performance Considerations

#### 7.8.1 Redis Operations

| Operation | Complexity | Expected Latency |
|-----------|------------|------------------|
| GET session | O(1) | <1ms |
| SET session | O(1) | <1ms |
| DELETE session | O(1) | <1ms |
| SETEX (set with TTL) | O(1) | <1ms |
| TTL check | O(1) | <1ms |
| SCAN (cleanup) | O(N) | Depends on key count |

#### 7.8.2 Optimization Strategies

- **Connection pooling**: Reuse Redis connections
- **Pipeline operations**: Batch multiple operations
- **Lazy expiration**: Let Redis TTL handle expiration automatically
- **Minimal cleanup**: Only cleanup task scans keys (not on every request)

### 7.9 Monitoring Session Management

#### 7.9.1 Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `session_created_total` | Counter | Total sessions created |
| `session_loaded_total` | Counter | Total sessions loaded |
| `session_saved_total` | Counter | Total sessions saved |
| `session_expired_total` | Counter | Total sessions expired |
| `session_deleted_total` | Counter | Total sessions deleted |
| `session_operation_duration_seconds` | Histogram | Redis operation latency |
| `concurrent_request_conflicts_total` | Counter | Lock acquisition failures |
| `sessions_active` | Gauge | Current active sessions |

#### 7.9.2 Alerting

```pseudo
# High expiration rate
if session_expired_total / session_created_total > 0.1:
    alert("High session expiration rate (>10%)")

# High concurrent request conflicts
if concurrent_request_conflicts_total / session_loaded_total > 0.05:
    alert("High concurrent request conflicts (>5%)")

# Redis latency degradation
if p99_session_operation_duration > 10ms:
    alert("Redis session operations latency degraded")
```

---

## 8. Error Handling

### 8.1 Error Categories

| Category | Response | Action |
|----------|----------|--------|
| Validation error | 200 (with errors) | Return validation errors, stay in state |
| Session not found | 404 | Return session_not_found error |
| Session expired | 410 | Return session_expired error |
| Flow not found | 404 | Return flow_not_found error |
| Invalid transition | 200 (with errors) | Return invalid_transition error |
| Action execution error | 500 | Log error, continue if possible |
| Redis error | 503 | Retry logic, fallback if possible |

### 8.2 Retry Strategy

```pseudo
# Redis retry
max_retries = 3
backoff_base = 100ms

for attempt in range(max_retries):
    try:
        return redis.get(key)
    except RedisError:
        sleep(backoff_base * (2 ** attempt))

raise ServiceUnavailable()
```

### 8.3 Error Recovery

```pseudo
function handle_action_error(action, error):
    """
    Handle action execution errors based on on_error strategy.
    """
    on_error = action.get("on_error", "fail")
    
    if on_error == "continue":
        # Log error but continue execution
        log_error("Action failed but continuing", action=action, error=error)
        return None
    
    elif on_error == "retry":
        # Retry action (up to max retries)
        return retry_action(action, max_retries=3)
    
    elif on_error == "fail":
        # Fail the request
        raise ActionExecutionError(f"Action failed: {error}")
```

---

## 9. Performance Considerations

### 9.1 Expected Latency

| Operation | Target P50 | Target P99 |
|-----------|------------|------------|
| Start conversation | <50ms | <200ms |
| Process message (cache hit) | <30ms | <100ms |
| Process message (cache miss) | <100ms | <300ms |
| Get state | <20ms | <50ms |

### 9.2 Throughput

| Metric | Target |
|--------|--------|
| RPS per instance | 500 |
| Concurrent sessions | 10,000 |
| Messages per session | 50 (typical flow) |

### 9.3 Optimization Strategies

- **Flow caching**: Cache parsed flows in memory (1 hour TTL)
- **Session caching**: Redis provides fast session access
- **Lazy loading**: Load flows only when needed
- **Batch operations**: Batch Redis operations where possible
- **Connection pooling**: Pool Redis and database connections

### 9.4 Flow Loading Performance

```pseudo
# Flow loading overhead
- File I/O: ~5-10ms (cached after first load)
- YAML parsing: ~1-5ms
- Schema validation: ~1-2ms
- Total: ~10-20ms (first load), <1ms (cached)
```

---

## 10. Monitoring

### 10.1 Metrics to Expose

| Metric | Type | Labels |
|--------|------|--------|
| `conversation_started_total` | Counter | flow_id |
| `message_processed_total` | Counter | flow_id, state_type |
| `state_transition_total` | Counter | flow_id, from_state, to_state |
| `validation_error_total` | Counter | flow_id, error_type |
| `flow_completed_total` | Counter | flow_id |
| `session_expired_total` | Counter | |
| `flow_load_duration_seconds` | Histogram | flow_id |
| `message_processing_duration_seconds` | Histogram | flow_id |
| `session_operations_duration_seconds` | Histogram | operation |

### 10.2 Alerting Rules

```pseudo
# High error rate
if validation_error_total / message_processed_total > 0.1:
    alert("High validation error rate (>10%)")

# High latency
if p99_message_processing_duration > 300ms:
    alert("Message processing latency degraded")

# High session expiration rate
if session_expired_total / conversation_started_total > 0.05:
    alert("High session expiration rate (>5%)")
```

---

## 11. Security Considerations

### 11.1 Input Validation

```pseudo
function validate_request(request):
    """
    Validate API request.
    """
    # Session ID format
    if not valid_session_id(request.session_id):
        raise ValidationError("Invalid session_id format")
    
    # Message sanitization
    if request.message:
        # Prevent injection attacks
        request.message = sanitize_input(request.message)
    
    # Flow ID format
    if request.flow_id:
        if not valid_flow_id(request.flow_id):
            raise ValidationError("Invalid flow_id format")
```

### 11.2 Rate Limiting

```pseudo
# Per-session rate limit
limit = 60 requests per minute per session_id

if rate_limiter.exceeded(request.session_id):
    return 429 Too Many Requests
```

### 11.3 Session Security

- **Session ID**: Opaque, unpredictable identifiers
- **Expiration**: Automatic expiration prevents session hijacking
- **Validation**: Validate session ownership (user_id match)
- **HTTPS**: All API calls over HTTPS

---

## 12. Flow Schema Validation

### 12.1 Schema Validation Rules

```pseudo
function validate_flow_schema(flow_yaml):
    """
    Validate flow YAML against schema.
    Raises ValidationError if invalid.
    """
    errors = []
    
    # Required root fields
    if "flow" not in flow_yaml:
        errors.append("Missing 'flow' root key")
        raise ValidationError(errors)
    
    flow = flow_yaml["flow"]
    
    # Required fields
    required_fields = ["name", "version", "initial_state", "states"]
    for field in required_fields:
        if field not in flow:
            errors.append(f"Missing required field: {field}")
    
    # Validate initial_state exists
    if "initial_state" in flow:
        if flow["initial_state"] not in flow.get("states", {}):
            errors.append(f"initial_state '{flow['initial_state']}' not found in states")
    
    # Validate states
    for state_name, state_def in flow.get("states", {}).items():
        state_errors = validate_state(state_name, state_def)
        errors.extend(state_errors)
    
    # Validate transitions
    for i, transition in enumerate(flow.get("transitions", [])):
        trans_errors = validate_transition(transition, flow.get("states", {}))
        errors.extend([f"Transition {i}: {e}" for e in trans_errors])
    
    if errors:
        raise ValidationError(f"Flow validation failed: {', '.join(errors)}")
```

### 12.2 State Validation

```pseudo
function validate_state(state_name, state_def):
    """
    Validate state definition.
    """
    errors = []
    
    # Required fields
    if "type" not in state_def:
        errors.append(f"State '{state_name}': missing 'type'")
    elif state_def["type"] not in ["question", "confirmation", "data_collection", "ai_response", "end"]:
        errors.append(f"State '{state_name}': invalid type '{state_def['type']}'")
    
    if "message" not in state_def:
        errors.append(f"State '{state_name}': missing 'message'")
    
    # Validate progress if present
    if "metadata" in state_def and "progress" in state_def["metadata"]:
        progress = state_def["metadata"]["progress"]
        if not isinstance(progress, (int, float)) or progress < 0.0 or progress > 1.0:
            errors.append(f"State '{state_name}': progress must be between 0.0 and 1.0")
    
    return errors
```

### 12.3 Transition Validation

```pseudo
function validate_transition(transition, states):
    """
    Validate transition definition.
    """
    errors = []
    
    # Required fields
    if "from" not in transition:
        errors.append("Missing 'from' field")
    elif transition["from"] not in states:
        errors.append(f"Transition 'from' state '{transition['from']}' not found")
    
    if "to" not in transition:
        errors.append("Missing 'to' field")
    elif transition["to"] not in states:
        errors.append(f"Transition 'to' state '{transition['to']}' not found")
    
    if "condition" not in transition:
        errors.append("Missing 'condition' field")
    else:
        cond_errors = validate_condition(transition["condition"])
        errors.extend(cond_errors)
    
    return errors
```

---

## 13. TODO: Implementation Notes

- [ ] Choose web framework (e.g., FastAPI, Express, Go Gin)
- [ ] Implement Redis session management
- [ ] Implement flow loader and parser
- [ ] Implement state machine execution engine
- [ ] Implement condition evaluator
- [ ] Implement action executor
- [ ] Implement validation hooks
- [ ] Add Prometheus metrics
- [ ] Configure rate limiting
- [ ] Write integration tests
- [ ] Add flow schema validation
- [ ] Implement session cleanup background task

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [API_SPEC.md](API_SPEC.md) | API specification |
| [../../flows/SCHEMA.md](../../flows/SCHEMA.md) | Flow YAML schema definition |
| [../../docs/conversation-flows.md](../../docs/conversation-flows.md) | Conversation flows guide (coming in Phase 6) |
