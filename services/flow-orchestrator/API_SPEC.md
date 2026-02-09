# Flow Orchestrator Service API Specification

**Purpose**  
This document defines the API contract for the Flow Orchestrator Service, which manages conversation flows and state machines for structured dialogues.

---

## Start Here If…

- **Calling the service** → Read this document
- **Implementing the service** → Go to [DESIGN.md](DESIGN.md)
- **Understanding flow schema** → Go to [../../flows/SCHEMA.md](../../flows/SCHEMA.md)
- **Understanding conversation flows** → Go to [../../docs/conversation-flows.md](../../docs/conversation-flows.md) (coming in Phase 6)

---

## 1. Base Information

| Property | Value |
|----------|-------|
| Base URL | `/api/v1` |
| Content-Type | `application/json` |
| Authentication | Bearer token (TODO: specify auth scheme) |

---

## 2. Endpoints

### 2.1 Start Conversation

Initializes a new conversation session and starts a flow from its initial state.

#### Request

```
POST /conversations
```

#### Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Content-Type` | Yes | `application/json` |
| `Authorization` | Yes | Bearer token |
| `X-Request-ID` | No | Request correlation ID |

#### Request Body

```json
{
  "flow_id": "user_onboarding",
  "flow_version": "1.0.0",
  "user_id": "user-123",
  "context": {
    "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
    "variant_id": "660e8400-e29b-41d4-a716-446655440001",
    "platform": "web",
    "locale": "en-US"
  },
  "initial_data": {
    "referral_source": "email_campaign"
  }
}
```

#### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `flow_id` | string | Yes | Identifier of the flow to start |
| `flow_version` | string | No | Specific flow version (defaults to latest) |
| `user_id` | string | Yes | Unique identifier for the user |
| `context` | object | No | Additional context for the conversation |
| `context.experiment_id` | string (UUID) | No | Experiment ID if part of A/B test |
| `context.variant_id` | string (UUID) | No | Variant ID if part of A/B test |
| `context.platform` | string | No | Platform identifier (e.g., "web", "mobile") |
| `context.locale` | string | No | User locale (e.g., "en-US") |
| `initial_data` | object | No | Initial data to populate conversation context |

#### Response (201 Created)

```json
{
  "session_id": "session-abc123def456",
  "flow_id": "user_onboarding",
  "flow_version": "1.0.0",
  "current_state": "ask_name",
  "state_type": "question",
  "message": {
    "text": "What is your name?",
    "quick_replies": [],
    "buttons": []
  },
  "progress": 0.33,
  "context": {
    "user_id": "user-123",
    "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
    "variant_id": "660e8400-e29b-41d4-a716-446655440001",
    "platform": "web",
    "locale": "en-US"
  },
  "conversation_data": {
    "referral_source": "email_campaign"
  },
  "created_at": "2025-02-09T10:00:00Z",
  "expires_at": "2025-02-09T10:15:00Z"
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `session_id` | string | Unique session identifier (use for subsequent requests) |
| `flow_id` | string | Flow identifier |
| `flow_version` | string | Flow version being executed |
| `current_state` | string | Current state name in the flow |
| `state_type` | string | Type of current state: `question`, `confirmation`, `data_collection`, `ai_response`, `end` |
| `message` | object | Message to display to user (see Message Schema) |
| `progress` | number | Progress indicator (0.0 to 1.0) |
| `context` | object | Conversation context (user_id, experiment info, etc.) |
| `conversation_data` | object | Data collected during conversation |
| `created_at` | string (ISO 8601) | Session creation timestamp |
| `expires_at` | string (ISO 8601) | Session expiration timestamp |

---

### 2.2 Process Message

Processes a user message and transitions the conversation to the next state based on flow logic.

#### Request

```
POST /conversations/{session_id}/messages
```

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `session_id` | string | Yes | Session identifier from start conversation response |

#### Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Content-Type` | Yes | `application/json` |
| `Authorization` | Yes | Bearer token |
| `X-Request-ID` | No | Request correlation ID |

#### Request Body

```json
{
  "message": "John Doe",
  "message_type": "text",
  "metadata": {
    "timestamp": "2025-02-09T10:00:30Z"
  }
}
```

#### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `message` | string | Yes | User's message or response |
| `message_type` | string | No | Type of message: `text`, `button`, `quick_reply` (default: `text`) |
| `metadata` | object | No | Additional metadata about the message |

#### Response (200 OK)

**Successful Transition:**

```json
{
  "session_id": "session-abc123def456",
  "flow_id": "user_onboarding",
  "flow_version": "1.0.0",
  "current_state": "ask_email",
  "previous_state": "ask_name",
  "state_type": "data_collection",
  "message": {
    "text": "What is your email address?",
    "quick_replies": [],
    "buttons": []
  },
  "progress": 0.67,
  "conversation_data": {
    "referral_source": "email_campaign",
    "name": "John Doe"
  },
  "actions_executed": [
    {
      "type": "set_field",
      "target": "name",
      "value": "John Doe"
    }
  ],
  "updated_at": "2025-02-09T10:00:31Z",
  "expires_at": "2025-02-09T10:15:00Z"
}
```

**Flow Completed:**

```json
{
  "session_id": "session-abc123def456",
  "flow_id": "user_onboarding",
  "flow_version": "1.0.0",
  "current_state": "complete",
  "previous_state": "confirm",
  "state_type": "end",
  "message": {
    "text": "Thank you! Your information has been saved.",
    "quick_replies": [],
    "buttons": []
  },
  "progress": 1.0,
  "conversation_data": {
    "referral_source": "email_campaign",
    "name": "John Doe",
    "email": "john.doe@example.com"
  },
  "actions_executed": [
    {
      "type": "log_event",
      "event_type": "flow_completed",
      "data": {
        "flow": "user_onboarding",
        "name": "John Doe",
        "email": "john.doe@example.com"
      }
    }
  ],
  "flow_completed": true,
  "completed_at": "2025-02-09T10:01:00Z",
  "updated_at": "2025-02-09T10:01:00Z"
}
```

**Validation Error (State Not Changed):**

```json
{
  "session_id": "session-abc123def456",
  "flow_id": "user_onboarding",
  "flow_version": "1.0.0",
  "current_state": "ask_name",
  "state_type": "question",
  "message": {
    "text": "What is your name?",
    "quick_replies": [],
    "buttons": []
  },
  "validation_errors": [
    {
      "field": "message",
      "error": "min_length",
      "message": "Name must be between 2 and 100 characters"
    }
  ],
  "progress": 0.33,
  "conversation_data": {
    "referral_source": "email_campaign"
  },
  "updated_at": "2025-02-09T10:00:31Z",
  "expires_at": "2025-02-09T10:15:00Z"
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `session_id` | string | Session identifier |
| `flow_id` | string | Flow identifier |
| `flow_version` | string | Flow version being executed |
| `current_state` | string | Current state name after processing |
| `previous_state` | string | Previous state name (if transition occurred) |
| `state_type` | string | Type of current state |
| `message` | object | Message to display to user |
| `progress` | number | Progress indicator (0.0 to 1.0) |
| `conversation_data` | object | Data collected during conversation |
| `actions_executed` | array | Actions executed during state transition |
| `validation_errors` | array | Validation errors (if validation failed) |
| `flow_completed` | boolean | Whether flow reached terminal state |
| `completed_at` | string (ISO 8601) | Flow completion timestamp (if completed) |
| `updated_at` | string (ISO 8601) | Last update timestamp |
| `expires_at` | string (ISO 8601) | Session expiration timestamp |

---

### 2.3 Get Conversation State

Retrieves the current state of an active conversation session.

#### Request

```
GET /conversations/{session_id}
```

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `session_id` | string | Yes | Session identifier |

#### Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Authorization` | Yes | Bearer token |
| `X-Request-ID` | No | Request correlation ID |

#### Response (200 OK)

```json
{
  "session_id": "session-abc123def456",
  "flow_id": "user_onboarding",
  "flow_version": "1.0.0",
  "current_state": "ask_email",
  "state_type": "data_collection",
  "message": {
    "text": "What is your email address?",
    "quick_replies": [],
    "buttons": []
  },
  "progress": 0.67,
  "context": {
    "user_id": "user-123",
    "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
    "variant_id": "660e8400-e29b-41d4-a716-446655440001",
    "platform": "web",
    "locale": "en-US"
  },
  "conversation_data": {
    "referral_source": "email_campaign",
    "name": "John Doe"
  },
  "state_history": [
    {
      "state": "ask_name",
      "entered_at": "2025-02-09T10:00:00Z",
      "exited_at": "2025-02-09T10:00:31Z"
    }
  ],
  "created_at": "2025-02-09T10:00:00Z",
  "updated_at": "2025-02-09T10:00:31Z",
  "expires_at": "2025-02-09T10:15:00Z"
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `session_id` | string | Session identifier |
| `flow_id` | string | Flow identifier |
| `flow_version` | string | Flow version being executed |
| `current_state` | string | Current state name |
| `state_type` | string | Type of current state |
| `message` | object | Current message to display |
| `progress` | number | Progress indicator (0.0 to 1.0) |
| `context` | object | Conversation context |
| `conversation_data` | object | Data collected during conversation |
| `state_history` | array | History of states visited |
| `state_history[].state` | string | State name |
| `state_history[].entered_at` | string (ISO 8601) | When state was entered |
| `state_history[].exited_at` | string (ISO 8601) | When state was exited (null if current) |
| `created_at` | string (ISO 8601) | Session creation timestamp |
| `updated_at` | string (ISO 8601) | Last update timestamp |
| `expires_at` | string (ISO 8601) | Session expiration timestamp |

---

### 2.4 Reset Conversation

Resets a conversation to its initial state, clearing collected data (optional).

#### Request

```
POST /conversations/{session_id}/reset
```

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `session_id` | string | Yes | Session identifier |

#### Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Content-Type` | Yes | `application/json` |
| `Authorization` | Yes | Bearer token |
| `X-Request-ID` | No | Request correlation ID |

#### Request Body

```json
{
  "clear_data": false
}
```

#### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `clear_data` | boolean | No | Whether to clear collected conversation data (default: false) |

#### Response (200 OK)

```json
{
  "session_id": "session-abc123def456",
  "flow_id": "user_onboarding",
  "flow_version": "1.0.0",
  "current_state": "ask_name",
  "state_type": "question",
  "message": {
    "text": "What is your name?",
    "quick_replies": [],
    "buttons": []
  },
  "progress": 0.33,
  "conversation_data": {
    "referral_source": "email_campaign"
  },
  "reset_at": "2025-02-09T10:02:00Z",
  "updated_at": "2025-02-09T10:02:00Z",
  "expires_at": "2025-02-09T10:17:00Z"
}
```

---

## 3. Message Schema

Messages can be simple text or structured with interactive elements.

### 3.1 Simple Text Message

```json
{
  "text": "What is your name?",
  "quick_replies": [],
  "buttons": []
}
```

### 3.2 Message with Quick Replies

```json
{
  "text": "What type of issue are you experiencing?",
  "quick_replies": [
    "Technical Problem",
    "Billing Question",
    "Feature Request",
    "Other"
  ],
  "buttons": []
}
```

### 3.3 Message with Buttons

```json
{
  "text": "Is this information correct?\nName: John Doe\nEmail: john.doe@example.com",
  "quick_replies": [],
  "buttons": [
    {
      "label": "Yes, continue",
      "value": "yes",
      "action": "confirm"
    },
    {
      "label": "No, go back",
      "value": "no",
      "action": "back"
    }
  ]
}
```

### 3.4 Message Schema Fields

| Field | Type | Description |
|-------|------|-------------|
| `text` | string | Primary message text |
| `quick_replies` | array | Quick reply options (strings) |
| `buttons` | array | Action buttons |
| `buttons[].label` | string | Button label text |
| `buttons[].value` | string | Value returned when button clicked |
| `buttons[].action` | string | Optional action identifier |

---

## 4. Error Responses

### 4.1 Validation Error (400)

```json
{
  "error": "validation_error",
  "message": "Invalid request body",
  "details": [
    {
      "field": "flow_id",
      "error": "required"
    }
  ]
}
```

### 4.2 Session Not Found (404)

```json
{
  "error": "session_not_found",
  "message": "Session not found or expired",
  "session_id": "session-abc123def456"
}
```

### 4.3 Session Expired (410)

```json
{
  "error": "session_expired",
  "message": "Session has expired",
  "session_id": "session-abc123def456",
  "expired_at": "2025-02-09T10:15:00Z"
}
```

### 4.4 Flow Not Found (404)

```json
{
  "error": "flow_not_found",
  "message": "Flow not found",
  "flow_id": "user_onboarding",
  "flow_version": "1.0.0"
}
```

### 4.5 Invalid State Transition (400)

```json
{
  "error": "invalid_transition",
  "message": "No valid transition found for current state and input",
  "session_id": "session-abc123def456",
  "current_state": "ask_name",
  "user_input": "invalid_response"
}
```

### 4.6 Unauthorized (401)

```json
{
  "error": "unauthorized",
  "message": "Invalid or missing authentication token"
}
```

### 4.7 Rate Limited (429)

```json
{
  "error": "rate_limited",
  "message": "Too many requests",
  "retry_after": 60
}
```

### 4.8 Service Unavailable (503)

```json
{
  "error": "service_unavailable",
  "message": "Flow orchestrator temporarily unavailable",
  "retry_after": 5
}
```

---

## 5. Example Requests

### 5.1 Start Conversation

```bash
curl -X POST https://api.example.com/api/v1/conversations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "flow_id": "user_onboarding",
    "user_id": "user-123",
    "context": {
      "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
      "variant_id": "660e8400-e29b-41d4-a716-446655440001",
      "platform": "web"
    }
  }'
```

**Response:**
```json
{
  "session_id": "session-abc123def456",
  "flow_id": "user_onboarding",
  "flow_version": "1.0.0",
  "current_state": "ask_name",
  "state_type": "question",
  "message": {
    "text": "What is your name?",
    "quick_replies": [],
    "buttons": []
  },
  "progress": 0.33,
  "context": {
    "user_id": "user-123",
    "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
    "variant_id": "660e8400-e29b-41d4-a716-446655440001",
    "platform": "web"
  },
  "conversation_data": {},
  "created_at": "2025-02-09T10:00:00Z",
  "expires_at": "2025-02-09T10:15:00Z"
}
```

### 5.2 Process Message

```bash
curl -X POST https://api.example.com/api/v1/conversations/session-abc123def456/messages \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "message": "John Doe",
    "message_type": "text"
  }'
```

**Response:**
```json
{
  "session_id": "session-abc123def456",
  "flow_id": "user_onboarding",
  "flow_version": "1.0.0",
  "current_state": "ask_email",
  "previous_state": "ask_name",
  "state_type": "data_collection",
  "message": {
    "text": "What is your email address?",
    "quick_replies": [],
    "buttons": []
  },
  "progress": 0.67,
  "conversation_data": {
    "name": "John Doe"
  },
  "actions_executed": [
    {
      "type": "set_field",
      "target": "name",
      "value": "John Doe"
    }
  ],
  "updated_at": "2025-02-09T10:00:31Z",
  "expires_at": "2025-02-09T10:15:00Z"
}
```

### 5.3 Process Button Click

```bash
curl -X POST https://api.example.com/api/v1/conversations/session-abc123def456/messages \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "message": "yes",
    "message_type": "button"
  }'
```

### 5.4 Get Conversation State

```bash
curl -X GET https://api.example.com/api/v1/conversations/session-abc123def456 \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response:**
```json
{
  "session_id": "session-abc123def456",
  "flow_id": "user_onboarding",
  "flow_version": "1.0.0",
  "current_state": "ask_email",
  "state_type": "data_collection",
  "message": {
    "text": "What is your email address?",
    "quick_replies": [],
    "buttons": []
  },
  "progress": 0.67,
  "context": {
    "user_id": "user-123",
    "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
    "variant_id": "660e8400-e29b-41d4-a716-446655440001",
    "platform": "web"
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
  "created_at": "2025-02-09T10:00:00Z",
  "updated_at": "2025-02-09T10:00:31Z",
  "expires_at": "2025-02-09T10:15:00Z"
}
```

---

## 6. Session Management

### 6.1 Session ID

- **Format**: Opaque string identifier (e.g., `session-abc123def456`)
- **Usage**: Include in all subsequent requests after starting a conversation
- **Storage**: Client should store session_id for conversation continuity
- **Expiration**: Sessions expire after inactivity (default: 15 minutes)

### 6.2 Session Lifecycle

1. **Created**: When `POST /conversations` is called
2. **Active**: While processing messages and maintaining state
3. **Expired**: After `expires_at` timestamp (no longer accepts messages)
4. **Completed**: When flow reaches terminal state (`state_type: end`)

### 6.3 Session Expiration

- **Default TTL**: 15 minutes from last activity
- **Extension**: Each message processing extends expiration time
- **Expired Sessions**: Return 410 Gone with `session_expired` error
- **Cleanup**: Expired sessions are automatically cleaned up

---

## 7. Flow Context

The `context` object persists throughout the conversation and includes:

| Field | Type | Description |
|-------|------|-------------|
| `user_id` | string | User identifier |
| `experiment_id` | string (UUID) | Experiment ID if part of A/B test |
| `variant_id` | string (UUID) | Variant ID if part of A/B test |
| `platform` | string | Platform identifier |
| `locale` | string | User locale |
| Custom fields | any | Additional context fields |

---

## 8. Conversation Data

The `conversation_data` object accumulates data collected during the conversation:

- **Initial Data**: Set via `initial_data` in start conversation request
- **Updates**: Modified by actions (e.g., `set_field`) during state transitions
- **Access**: Available in flow conditions and actions via template variables
- **Reset**: Can be cleared via reset endpoint with `clear_data: true`

---

## 9. Idempotency

- **Start Conversation**: Not idempotent (creates new session each time)
- **Process Message**: Idempotent within same session state (same input = same output)
- **Get State**: Idempotent (read-only operation)
- **Reset**: Idempotent (reset to same initial state)

---

## 10. Rate Limits

| Limit | Value |
|-------|-------|
| Per session_id | 60 requests/minute |
| Per user_id | 300 requests/minute |
| Per API key | 10,000 requests/minute |

---

## 11. SDK Examples

### 11.1 Python (Pseudo-code)

```pseudo
class FlowOrchestratorClient:
    def __init__(self, base_url, api_key):
        self.base_url = base_url
        self.api_key = api_key
    
    def start_conversation(self, flow_id, user_id, context=None, initial_data=None):
        response = http.post(
            f"{self.base_url}/api/v1/conversations",
            headers={"Authorization": f"Bearer {self.api_key}"},
            json={
                "flow_id": flow_id,
                "user_id": user_id,
                "context": context or {},
                "initial_data": initial_data or {}
            }
        )
        return response.json()
    
    def process_message(self, session_id, message, message_type="text"):
        response = http.post(
            f"{self.base_url}/api/v1/conversations/{session_id}/messages",
            headers={"Authorization": f"Bearer {self.api_key}"},
            json={
                "message": message,
                "message_type": message_type
            }
        )
        return response.json()
    
    def get_state(self, session_id):
        response = http.get(
            f"{self.base_url}/api/v1/conversations/{session_id}",
            headers={"Authorization": f"Bearer {self.api_key}"}
        )
        return response.json()
    
    def reset_conversation(self, session_id, clear_data=False):
        response = http.post(
            f"{self.base_url}/api/v1/conversations/{session_id}/reset",
            headers={"Authorization": f"Bearer {self.api_key}"},
            json={"clear_data": clear_data}
        )
        return response.json()
```

### 11.2 Usage Example

```pseudo
client = FlowOrchestratorClient("https://api.example.com", API_KEY)

# Start conversation
response = client.start_conversation(
    flow_id="user_onboarding",
    user_id="user-123",
    context={
        "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
        "variant_id": "660e8400-e29b-41d4-a716-446655440001",
        "platform": "web"
    }
)

session_id = response["session_id"]
current_message = response["message"]["text"]
print(f"Bot: {current_message}")

# Process user response
user_input = input("User: ")
response = client.process_message(session_id, user_input)

# Check for validation errors
if "validation_errors" in response:
    for error in response["validation_errors"]:
        print(f"Error: {error['message']}")
    # Stay in same state, ask again
    current_message = response["message"]["text"]
    print(f"Bot: {current_message}")
else:
    # Transition successful
    current_message = response["message"]["text"]
    print(f"Bot: {current_message}")
    
    # Check if flow completed
    if response.get("flow_completed"):
        print("Flow completed!")
        conversation_data = response["conversation_data"]
        print(f"Collected data: {conversation_data}")
```

---

## 12. Related Documentation

| Document | Purpose |
|----------|---------|
| [DESIGN.md](DESIGN.md) | Implementation design |
| [../../flows/SCHEMA.md](../../flows/SCHEMA.md) | Flow YAML schema definition |
| [../../docs/conversation-flows.md](../../docs/conversation-flows.md) | Conversation flows guide (coming in Phase 6) |
| [../../docs/data-model.md](../../docs/data-model.md) | Database schema |

---

## After Completing This Document

You will understand:
- How to start a conversation session
- How to process user messages and transition states
- How to retrieve conversation state
- How to handle session management and expiration
- How to work with flow context and conversation data

**Next Step**: Review [DESIGN.md](DESIGN.md) for implementation details
