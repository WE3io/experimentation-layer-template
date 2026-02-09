# Event Ingestion Service API Specification

**Purpose**  
This document defines the API contract for the Event Ingestion Service (EIS).

---

## Start Here If…

- **Logging events** → Read this document
- **Implementing the service** → Go to [DESIGN.md](DESIGN.md)
- **Understanding events** → Go to [../../docs/event-ingestion-service.md](../../docs/event-ingestion-service.md)

---

## 1. Base Information

| Property | Value |
|----------|-------|
| Base URL | `/api/v1` |
| Content-Type | `application/json` |
| Authentication | Bearer token (TODO: specify auth scheme) |

---

## 2. Endpoints

### 2.1 Log Single Event

#### Request

```
POST /events
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
  "event_type": "plan_generated",
  "unit_type": "user",
  "unit_id": "user-123",
  "experiments": [
    {
      "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
      "variant_id": "660e8400-e29b-41d4-a716-446655440001"
    }
  ],
  "context": {
    "policy_version_id": "770e8400-e29b-41d4-a716-446655440002",
    "app_version": "1.2.3",
    "platform": "ios"
  },
  "metrics": {
    "latency_ms": 450,
    "token_count": 1200
  },
  "payload": {
    "plan_id": "880e8400-e29b-41d4-a716-446655440003",
    "meal_count": 7
  },
  "timestamp": "2025-01-01T10:00:00Z"
}
```

#### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `event_type` | string | Yes | Type of event |
| `unit_type` | string | Yes | Type of unit: `user`, `household`, `session` |
| `unit_id` | string | Yes | Unique identifier for the unit |
| `experiments` | array | No | Experiment context |
| `experiments[].experiment_id` | string | Yes* | UUID of experiment |
| `experiments[].variant_id` | string | Yes* | UUID of variant |
| `context` | object | No | Additional context |
| `metrics` | object | No | Numeric measurements |
| `payload` | object | No | Event-specific data |
| `timestamp` | string | Yes | ISO 8601 timestamp |

#### Response (200 OK)

```json
{
  "event_id": "990e8400-e29b-41d4-a716-446655440004",
  "status": "accepted"
}
```

---

### 2.2 Log Batch Events

#### Request

```
POST /events/batch
```

#### Request Body

```json
{
  "events": [
    {
      "event_type": "plan_generated",
      "unit_type": "user",
      "unit_id": "user-123",
      "experiments": [...],
      "context": {...},
      "metrics": {...},
      "timestamp": "2025-01-01T10:00:00Z"
    },
    {
      "event_type": "plan_accepted",
      "unit_type": "user",
      "unit_id": "user-123",
      "experiments": [...],
      "timestamp": "2025-01-01T10:01:00Z"
    }
  ]
}
```

#### Response (200 OK)

```json
{
  "accepted": 2,
  "rejected": 0,
  "event_ids": [
    "990e8400-e29b-41d4-a716-446655440004",
    "990e8400-e29b-41d4-a716-446655440005"
  ]
}
```

#### Response (207 Multi-Status)

```json
{
  "accepted": 8,
  "rejected": 2,
  "event_ids": [...],
  "errors": [
    {
      "index": 3,
      "error": "missing_timestamp"
    },
    {
      "index": 7,
      "error": "invalid_experiment_id"
    }
  ]
}
```

---

## 3. Event Types

### 3.1 Standard Event Types

**ML Experiment Events:**

| Event Type | Description |
|------------|-------------|
| `plan_generated` | Plan was created by model |
| `plan_accepted` | User accepted the plan |
| `plan_rejected` | User rejected the plan |
| `meal_swapped` | User swapped a meal |
| `edit_applied` | User made an edit |
| `validator_intervention` | Validator modified output |

**Conversation Events:**

| Event Type | Description |
|------------|-------------|
| `conversation_started` | User initiates a new conversation session |
| `message_sent` | User or bot sends a message in the conversation |
| `flow_completed` | User successfully completes a conversation flow |
| `user_dropped_off` | User abandons conversation without completion |

### 3.2 Custom Event Types

Use `custom.` prefix for custom events:

```json
{
  "event_type": "custom.pantry_updated",
  ...
}
```

---

## 4. Error Responses

### 4.1 Validation Error (400)

```json
{
  "error": "validation_error",
  "message": "Invalid event",
  "details": [
    {
      "field": "timestamp",
      "error": "required"
    }
  ]
}
```

### 4.2 Payload Too Large (413)

```json
{
  "error": "payload_too_large",
  "message": "Event payload exceeds 1MB limit"
}
```

### 4.3 Rate Limited (429)

```json
{
  "error": "rate_limited",
  "message": "Too many events from this unit",
  "retry_after": 60
}
```

### 4.4 Service Unavailable (503)

```json
{
  "error": "service_unavailable",
  "message": "Database temporarily unavailable",
  "retry_after": 5
}
```

---

## 5. Example Requests

### 5.1 Plan Generated Event

```bash
curl -X POST https://api.example.com/api/v1/events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "event_type": "plan_generated",
    "unit_type": "user",
    "unit_id": "user-123",
    "experiments": [
      {
        "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
        "variant_id": "660e8400-e29b-41d4-a716-446655440001"
      }
    ],
    "context": {
      "policy_version_id": "770e8400-e29b-41d4-a716-446655440002"
    },
    "metrics": {
      "latency_ms": 450,
      "token_count": 1200
    },
    "timestamp": "2025-01-01T10:00:00Z"
  }'
```

### 5.2 User Edit Event

```bash
curl -X POST https://api.example.com/api/v1/events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "event_type": "meal_swapped",
    "unit_type": "user",
    "unit_id": "user-123",
    "experiments": [...],
    "payload": {
      "plan_id": "880e8400-e29b-41d4-a716-446655440003",
      "day": "tuesday",
      "from_meal_id": "aaa-uuid",
      "to_meal_id": "bbb-uuid"
    },
    "timestamp": "2025-01-01T10:05:00Z"
  }'
```

### 5.3 Conversation Started Event

```bash
curl -X POST https://api.example.com/api/v1/events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "event_type": "conversation_started",
    "unit_type": "user",
    "unit_id": "user-123",
    "experiments": [
      {
        "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
        "variant_id": "660e8400-e29b-41d4-a716-446655440001"
      }
    ],
    "context": {
      "session_id": "session-abc123def456",
      "flow_id": "user_onboarding",
      "flow_version": "1.0.0",
      "prompt_version_id": "770e8400-e29b-41d4-a716-446655440002",
      "model_provider": "anthropic",
      "model_name": "claude-sonnet-4.5",
      "app_version": "1.2.3"
    },
    "payload": {
      "entry_point": "web_chat",
      "referral_source": "email_campaign"
    },
    "timestamp": "2025-01-01T10:00:00Z"
  }'
```

### 5.4 Message Sent Event

```bash
curl -X POST https://api.example.com/api/v1/events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "event_type": "message_sent",
    "unit_type": "user",
    "unit_id": "user-123",
    "experiments": [
      {
        "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
        "variant_id": "660e8400-e29b-41d4-a716-446655440001"
      }
    ],
    "context": {
      "session_id": "session-abc123def456",
      "flow_id": "user_onboarding",
      "current_state": "ask_name",
      "prompt_version_id": "770e8400-e29b-41d4-a716-446655440002",
      "model_provider": "anthropic",
      "model_name": "claude-sonnet-4.5"
    },
    "metrics": {
      "latency_ms": 850,
      "token_count": 245,
      "turn_number": 3
    },
    "payload": {
      "sender": "user",
      "message_text": "John Doe",
      "message_length": 8,
      "state_transition": true,
      "next_state": "ask_email"
    },
    "timestamp": "2025-01-01T10:00:15Z"
  }'
```

### 5.5 Flow Completed Event

```bash
curl -X POST https://api.example.com/api/v1/events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "event_type": "flow_completed",
    "unit_type": "user",
    "unit_id": "user-123",
    "experiments": [
      {
        "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
        "variant_id": "660e8400-e29b-41d4-a716-446655440001"
      }
    ],
    "context": {
      "session_id": "session-abc123def456",
      "flow_id": "user_onboarding",
      "flow_version": "1.0.0",
      "current_state": "complete",
      "prompt_version_id": "770e8400-e29b-41d4-a716-446655440002",
      "model_provider": "anthropic",
      "model_name": "claude-sonnet-4.5"
    },
    "metrics": {
      "total_turns": 8,
      "total_duration_seconds": 245,
      "completion_rate": 1.0
    },
    "payload": {
      "completion_reason": "success",
      "final_state": "complete",
      "data_collected": {
        "name": "John Doe",
        "email": "john.doe@example.com"
      }
    },
    "timestamp": "2025-01-01T10:04:05Z"
  }'
```

### 5.6 User Dropped Off Event

```bash
curl -X POST https://api.example.com/api/v1/events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "event_type": "user_dropped_off",
    "unit_type": "user",
    "unit_id": "user-123",
    "experiments": [
      {
        "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
        "variant_id": "660e8400-e29b-41d4-a716-446655440001"
      }
    ],
    "context": {
      "session_id": "session-abc123def456",
      "flow_id": "user_onboarding",
      "current_state": "ask_email",
      "prompt_version_id": "770e8400-e29b-41d4-a716-446655440002",
      "model_provider": "anthropic",
      "model_name": "claude-sonnet-4.5"
    },
    "metrics": {
      "total_turns": 4,
      "total_duration_seconds": 120,
      "time_since_last_message_seconds": 300
    },
    "payload": {
      "drop_off_reason": "session_expired",
      "last_active_state": "ask_email",
      "progress": 0.5,
      "data_collected": {
        "name": "John Doe"
      }
    },
    "timestamp": "2025-01-01T10:05:00Z"
  }'
```

---

## 6. Context Fields

### 6.1 Required Context (Recommended)

**For ML Events:**

| Field | Type | Description |
|-------|------|-------------|
| `policy_version_id` | string | UUID of policy version used |

**For Conversation Events:**

| Field | Type | Description |
|-------|------|-------------|
| `session_id` | string | Unique identifier for the conversation session |
| `flow_id` | string | Identifier of the conversation flow being executed |

### 6.2 Optional Context

**Common Context Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `app_version` | string | Client application version |
| `platform` | string | Client platform (ios, android, web) |
| `request_id` | string | Original request ID |

**Conversation-Specific Context Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `flow_version` | string | Version of the flow definition |
| `current_state` | string | Current state in the flow state machine |
| `prompt_version_id` | string (UUID) | Reference to exp.prompt_versions.id if using prompt templates |
| `model_provider` | string | LLM provider (e.g., "anthropic", "openai") |
| `model_name` | string | Specific model identifier (e.g., "claude-sonnet-4.5", "gpt-4") |

---

## 7. Metrics Fields

### 7.1 Common Metrics (ML and Conversation Events)

| Field | Type | Unit | Description |
|-------|------|------|-------------|
| `latency_ms` | integer | milliseconds | Response time |
| `token_count` | integer | count | LLM tokens used |
| `input_tokens` | integer | count | Input tokens |
| `output_tokens` | integer | count | Output tokens |
| `cost_usd` | float | USD | Estimated cost |

### 7.2 Conversation-Specific Metrics

| Field | Type | Unit | Description |
|-------|------|------|-------------|
| `turn_number` | integer | count | Sequential turn number in the conversation (for message_sent) |
| `total_turns` | integer | count | Total number of turns in the conversation (for completion/drop-off events) |
| `total_duration_seconds` | integer | seconds | Total conversation duration |
| `time_since_last_message_seconds` | integer | seconds | Time since last user message (for drop-off detection) |
| `completion_rate` | float | 0.0-1.0 | Progress indicator (0.0 to 1.0) |

---

## 8. Payload Structures

### 8.1 Conversation Event Payloads

**conversation_started:**

| Field | Type | Description |
|-------|------|-------------|
| `entry_point` | string | How the conversation was initiated (e.g., "web_chat", "mobile_app", "api") |
| `referral_source` | string | Optional referral source (e.g., "email_campaign", "social_media") |

**message_sent:**

| Field | Type | Description |
|-------|------|-------------|
| `sender` | string | Message sender: "user" or "bot" |
| `message_text` | string | Message content |
| `message_length` | integer | Length of message in characters |
| `state_transition` | boolean | Whether this message triggered a state transition |
| `next_state` | string | Next state in flow (if state_transition is true) |

**flow_completed:**

| Field | Type | Description |
|-------|------|-------------|
| `completion_reason` | string | Reason for completion (e.g., "success", "user_cancelled") |
| `final_state` | string | Final state reached in the flow |
| `data_collected` | object | Summary of data collected during conversation |

**user_dropped_off:**

| Field | Type | Description |
|-------|------|-------------|
| `drop_off_reason` | string | Reason for drop-off (e.g., "session_expired", "user_inactive", "error") |
| `last_active_state` | string | Last state the user was in before dropping off |
| `progress` | float | Progress indicator (0.0 to 1.0) at time of drop-off |
| `data_collected` | object | Partial data collected before drop-off |

---

## 9. Best Practices

### 8.1 Always Include Experiment Context

```json
{
  "experiments": [
    {
      "experiment_id": "...",
      "variant_id": "..."
    }
  ]
}
```

### 8.2 Use Consistent Timestamps

```json
{
  "timestamp": "2025-01-01T10:00:00.000Z"
}
```

### 8.3 Batch When Possible

For high-volume logging, use `/events/batch`:
- Reduces HTTP overhead
- Improves throughput
- Atomic processing

---

## 10. SDK Examples

### 9.1 Python (Pseudo-code)

```pseudo
class EventClient:
    def __init__(self, base_url, api_key):
        self.base_url = base_url
        self.api_key = api_key
        self.buffer = []
    
    def log_event(self, event_type, unit_type, unit_id, 
                  experiments=None, context=None, metrics=None, 
                  payload=None, timestamp=None):
        event = {
            "event_type": event_type,
            "unit_type": unit_type,
            "unit_id": unit_id,
            "experiments": experiments or [],
            "context": context or {},
            "metrics": metrics or {},
            "payload": payload,
            "timestamp": timestamp or now_iso()
        }
        
        self.buffer.append(event)
        
        if len(self.buffer) >= 100:
            self.flush()
    
    def flush(self):
        if not self.buffer:
            return
        
        response = http.post(
            f"{self.base_url}/api/v1/events/batch",
            headers={"Authorization": f"Bearer {self.api_key}"},
            json={"events": self.buffer}
        )
        
        self.buffer = []
        return response.json()
```

---

## 11. Related Documentation

| Document | Purpose |
|----------|---------|
| [DESIGN.md](DESIGN.md) | Implementation design |
| [../../docs/event-ingestion-service.md](../../docs/event-ingestion-service.md) | Service overview |
| [../../docs/data-model.md](../../docs/data-model.md) | Database schema |

