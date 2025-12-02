# Assignment Service API Specification

**Purpose**  
This document defines the API contract for the Experiment Assignment Service (EAS).

---

## Start Here If…

- **Calling the service** → Read this document
- **Implementing the service** → Go to [DESIGN.md](DESIGN.md)
- **Understanding experiments** → Go to [../../docs/experiments.md](../../docs/experiments.md)

---

## 1. Base Information

| Property | Value |
|----------|-------|
| Base URL | `/api/v1` |
| Content-Type | `application/json` |
| Authentication | Bearer token (TODO: specify auth scheme) |

---

## 2. Endpoints

### 2.1 Get Assignments

Retrieves variant assignments for a unit across one or more experiments.

#### Request

```
POST /assignments
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
  "unit_type": "user",
  "unit_id": "user-123",
  "context": {
    "app_version": "1.2.3",
    "platform": "ios"
  },
  "requested_experiments": ["planner_policy_exp", "feature_flag_exp"]
}
```

#### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `unit_type` | string | Yes | Type of unit: `user`, `household`, `session` |
| `unit_id` | string | Yes | Unique identifier for the unit |
| `context` | object | No | Additional context for targeting |
| `requested_experiments` | array | Yes | List of experiment names |

#### Response (200 OK)

```json
{
  "assignments": [
    {
      "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
      "experiment_name": "planner_policy_exp",
      "variant_id": "660e8400-e29b-41d4-a716-446655440001",
      "variant_name": "variant_a",
      "config": {
        "policy_version_id": "770e8400-e29b-41d4-a716-446655440002",
        "params": {
          "exploration_rate": 0.15,
          "temperature": 0.7
        }
      }
    }
  ],
  "skipped_experiments": [
    {
      "experiment_name": "feature_flag_exp",
      "reason": "not_active"
    }
  ]
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `assignments` | array | List of variant assignments |
| `assignments[].experiment_id` | string | UUID of the experiment |
| `assignments[].experiment_name` | string | Name of the experiment |
| `assignments[].variant_id` | string | UUID of the assigned variant |
| `assignments[].variant_name` | string | Name of the variant |
| `assignments[].config` | object | Variant configuration |
| `skipped_experiments` | array | Experiments not assigned |

---

## 3. Error Responses

### 3.1 Validation Error (400)

```json
{
  "error": "validation_error",
  "message": "Invalid request body",
  "details": [
    {
      "field": "unit_id",
      "error": "required"
    }
  ]
}
```

### 3.2 Unauthorized (401)

```json
{
  "error": "unauthorized",
  "message": "Invalid or missing authentication token"
}
```

### 3.3 Rate Limited (429)

```json
{
  "error": "rate_limited",
  "message": "Too many requests",
  "retry_after": 60
}
```

### 3.4 Service Unavailable (503)

```json
{
  "error": "service_unavailable",
  "message": "Database temporarily unavailable",
  "retry_after": 5
}
```

---

## 4. Example Requests

### 4.1 Single Experiment

```bash
curl -X POST https://api.example.com/api/v1/assignments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "unit_type": "user",
    "unit_id": "user-123",
    "requested_experiments": ["planner_policy_exp"]
  }'
```

### 4.2 Multiple Experiments

```bash
curl -X POST https://api.example.com/api/v1/assignments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "unit_type": "household",
    "unit_id": "household-456",
    "context": {
      "app_version": "2.0.0",
      "platform": "android",
      "region": "us-west"
    },
    "requested_experiments": [
      "planner_policy_exp",
      "meal_ranking_exp",
      "ui_refresh_exp"
    ]
  }'
```

---

## 5. Context Fields

The `context` object can include any fields useful for targeting or logging:

| Field | Type | Example | Purpose |
|-------|------|---------|---------|
| `app_version` | string | `"1.2.3"` | Client version |
| `platform` | string | `"ios"` | Client platform |
| `region` | string | `"us-west"` | Geographic region |
| `locale` | string | `"en-US"` | User locale |
| `device_type` | string | `"mobile"` | Device category |

---

## 6. Config Structure

The `config` object returned in assignments:

```json
{
  "policy_version_id": "uuid",
  "params": {
    // Variant-specific parameters
  }
}
```

### 6.1 Reserved Config Fields

| Field | Type | Description |
|-------|------|-------------|
| `policy_version_id` | string | Reference to exp.policy_versions |

### 6.2 Custom Params

Any additional parameters defined in the variant:

```json
{
  "params": {
    "exploration_rate": 0.15,
    "temperature": 0.7,
    "max_tokens": 2048,
    "feature_enabled": true
  }
}
```

---

## 7. Idempotency

The assignment endpoint is **idempotent**:

- Same `(unit_id, experiment)` always returns same variant
- Safe to retry on network failures
- No side effects on repeated calls

---

## 8. Caching Behavior

### 8.1 Client-Side Caching

Clients MAY cache assignments:

| Header | Value | Meaning |
|--------|-------|---------|
| `Cache-Control` | `max-age=300` | Cache for 5 minutes |

### 8.2 Invalidation

Clients SHOULD refresh when:
- User explicitly requests refresh
- App version changes
- Session changes

---

## 9. Rate Limits

| Limit | Value |
|-------|-------|
| Per unit_id | 100 requests/minute |
| Per API key | 10,000 requests/minute |

---

## 10. SDK Examples

### 10.1 Python (Pseudo-code)

```pseudo
class AssignmentClient:
    def __init__(self, base_url, api_key):
        self.base_url = base_url
        self.api_key = api_key
        self.cache = {}
    
    def get_assignments(self, unit_type, unit_id, experiments, context=None):
        # Check cache
        cache_key = f"{unit_id}:{','.join(experiments)}"
        if cache_key in self.cache:
            if not self.cache[cache_key].expired():
                return self.cache[cache_key].value
        
        # Make request
        response = http.post(
            f"{self.base_url}/api/v1/assignments",
            headers={"Authorization": f"Bearer {self.api_key}"},
            json={
                "unit_type": unit_type,
                "unit_id": unit_id,
                "context": context or {},
                "requested_experiments": experiments
            }
        )
        
        # Cache and return
        self.cache[cache_key] = CacheEntry(response.json(), ttl=300)
        return response.json()
```

### 10.2 Usage

```pseudo
client = AssignmentClient("https://api.example.com", API_KEY)

assignments = client.get_assignments(
    unit_type="user",
    unit_id="user-123",
    experiments=["planner_policy_exp"],
    context={"app_version": "1.2.3"}
)

for assignment in assignments["assignments"]:
    policy_version_id = assignment["config"]["policy_version_id"]
    params = assignment["config"]["params"]
    # Use policy_version_id to load model
    # Apply params to model execution
```

---

## 11. Related Documentation

| Document | Purpose |
|----------|---------|
| [DESIGN.md](DESIGN.md) | Implementation design |
| [../../docs/experiments.md](../../docs/experiments.md) | Experiment concepts |
| [../../docs/assignment-service.md](../../docs/assignment-service.md) | Service overview |

