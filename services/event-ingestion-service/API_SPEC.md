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

| Event Type | Description |
|------------|-------------|
| `plan_generated` | Plan was created by model |
| `plan_accepted` | User accepted the plan |
| `plan_rejected` | User rejected the plan |
| `meal_swapped` | User swapped a meal |
| `edit_applied` | User made an edit |
| `validator_intervention` | Validator modified output |

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

---

## 6. Context Fields

### 6.1 Required Context (Recommended)

| Field | Type | Description |
|-------|------|-------------|
| `policy_version_id` | string | UUID of policy version used |

### 6.2 Optional Context

| Field | Type | Description |
|-------|------|-------------|
| `app_version` | string | Client application version |
| `platform` | string | Client platform (ios, android, web) |
| `session_id` | string | Session identifier |
| `request_id` | string | Original request ID |

---

## 7. Metrics Fields

Common metric fields:

| Field | Type | Unit | Description |
|-------|------|------|-------------|
| `latency_ms` | integer | milliseconds | Response time |
| `token_count` | integer | count | LLM tokens used |
| `input_tokens` | integer | count | Input tokens |
| `output_tokens` | integer | count | Output tokens |
| `cost_usd` | float | USD | Estimated cost |

---

## 8. Best Practices

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

## 9. SDK Examples

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

## 10. Related Documentation

| Document | Purpose |
|----------|---------|
| [DESIGN.md](DESIGN.md) | Implementation design |
| [../../docs/event-ingestion-service.md](../../docs/event-ingestion-service.md) | Service overview |
| [../../docs/data-model.md](../../docs/data-model.md) | Database schema |

