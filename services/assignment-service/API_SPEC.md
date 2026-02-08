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

**Legacy Format (Backward Compatible):**

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

**Unified Format (ML Model Strategy):**

```json
{
  "assignments": [
    {
      "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
      "experiment_name": "planner_policy_exp",
      "variant_id": "660e8400-e29b-41d4-a716-446655440001",
      "variant_name": "variant_a",
      "config": {
        "execution_strategy": "mlflow_model",
        "mlflow_model": {
          "policy_version_id": "770e8400-e29b-41d4-a716-446655440002",
          "model_name": "planner_model"
        },
        "params": {
          "exploration_rate": 0.15,
          "temperature": 0.7
        }
      }
    }
  ],
  "skipped_experiments": []
}
```

**Unified Format (Prompt Template Strategy):**

```json
{
  "assignments": [
    {
      "experiment_id": "880e8400-e29b-41d4-a716-446655440003",
      "experiment_name": "chatbot_assistant_exp",
      "variant_id": "990e8400-e29b-41d4-a716-446655440004",
      "variant_name": "variant_b",
      "config": {
        "execution_strategy": "prompt_template",
        "prompt_config": {
          "prompt_version_id": "aa0e8400-e29b-41d4-a716-446655440005",
          "model_provider": "anthropic",
          "model_name": "claude-sonnet-4.5"
        },
        "flow_config": {
          "flow_id": "onboarding_v1",
          "initial_state": "welcome"
        },
        "params": {
          "temperature": 0.7,
          "max_tokens": 2048
        }
      }
    }
  ],
  "skipped_experiments": []
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

### 4.1 Single Experiment (ML Model)

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

**Response (Legacy Format):**
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
  "skipped_experiments": []
}
```

**Response (Unified Format):**
```json
{
  "assignments": [
    {
      "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
      "experiment_name": "planner_policy_exp",
      "variant_id": "660e8400-e29b-41d4-a716-446655440001",
      "variant_name": "variant_a",
      "config": {
        "execution_strategy": "mlflow_model",
        "mlflow_model": {
          "policy_version_id": "770e8400-e29b-41d4-a716-446655440002",
          "model_name": "planner_model"
        },
        "params": {
          "exploration_rate": 0.15,
          "temperature": 0.7
        }
      }
    }
  ],
  "skipped_experiments": []
}
```

### 4.2 Single Experiment (Prompt Template)

```bash
curl -X POST https://api.example.com/api/v1/assignments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "unit_type": "user",
    "unit_id": "user-123",
    "requested_experiments": ["chatbot_assistant_exp"]
  }'
```

**Response:**
```json
{
  "assignments": [
    {
      "experiment_id": "880e8400-e29b-41d4-a716-446655440003",
      "experiment_name": "chatbot_assistant_exp",
      "variant_id": "990e8400-e29b-41d4-a716-446655440004",
      "variant_name": "variant_b",
      "config": {
        "execution_strategy": "prompt_template",
        "prompt_config": {
          "prompt_version_id": "aa0e8400-e29b-41d4-a716-446655440005",
          "model_provider": "anthropic",
          "model_name": "claude-sonnet-4.5"
        },
        "flow_config": {
          "flow_id": "onboarding_v1",
          "initial_state": "welcome"
        },
        "params": {
          "temperature": 0.7,
          "max_tokens": 2048
        }
      }
    }
  ],
  "skipped_experiments": []
}
```

### 4.3 Multiple Experiments (Mixed Strategies)

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
      "chatbot_assistant_exp",
      "ui_refresh_exp"
    ]
  }'
```

**Response:**
```json
{
  "assignments": [
    {
      "experiment_id": "550e8400-e29b-41d4-a716-446655440000",
      "experiment_name": "planner_policy_exp",
      "variant_id": "660e8400-e29b-41d4-a716-446655440001",
      "variant_name": "variant_a",
      "config": {
        "execution_strategy": "mlflow_model",
        "mlflow_model": {
          "policy_version_id": "770e8400-e29b-41d4-a716-446655440002",
          "model_name": "planner_model"
        },
        "params": {
          "exploration_rate": 0.15,
          "temperature": 0.7
        }
      }
    },
    {
      "experiment_id": "880e8400-e29b-41d4-a716-446655440003",
      "experiment_name": "chatbot_assistant_exp",
      "variant_id": "990e8400-e29b-41d4-a716-446655440004",
      "variant_name": "variant_b",
      "config": {
        "execution_strategy": "prompt_template",
        "prompt_config": {
          "prompt_version_id": "aa0e8400-e29b-41d4-a716-446655440005",
          "model_provider": "anthropic",
          "model_name": "claude-sonnet-4.5"
        },
        "flow_config": {
          "flow_id": "onboarding_v1",
          "initial_state": "welcome"
        },
        "params": {
          "temperature": 0.7,
          "max_tokens": 2048
        }
      }
    }
  ],
  "skipped_experiments": [
    {
      "experiment_name": "ui_refresh_exp",
      "reason": "not_active"
    }
  ]
}
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

The `config` object returned in assignments supports a unified structure that works for both traditional ML projects and conversational AI projects. The service maintains full backward compatibility with the legacy format.

### 6.1 Unified Config Format

The unified config format supports three execution strategies:

| Execution Strategy | Use Case | Description |
|-------------------|----------|-------------|
| `mlflow_model` | Traditional ML | Trained models from MLflow Model Registry |
| `prompt_template` | Conversational AI | Prompt templates with LLM providers |
| `hybrid` | Combined | Both ML models and prompts in same variant |

**Unified Config Schema:**

```json
{
  "execution_strategy": "mlflow_model" | "prompt_template" | "hybrid",
  "mlflow_model": {
    "policy_version_id": "uuid",
    "model_name": "string"
  },
  "prompt_config": {
    "prompt_version_id": "uuid",
    "model_provider": "anthropic" | "openai" | "other",
    "model_name": "string"
  },
  "flow_config": {
    "flow_id": "string",
    "initial_state": "string"
  },
  "params": {
    // Runtime parameters (execution-strategy agnostic)
  }
}
```

### 6.2 ML Model Configuration (`mlflow_model` strategy)

For traditional ML projects using trained models:

```json
{
  "execution_strategy": "mlflow_model",
  "mlflow_model": {
    "policy_version_id": "770e8400-e29b-41d4-a716-446655440002",
    "model_name": "planner_model"
  },
  "params": {
    "exploration_rate": 0.15,
    "temperature": 0.7,
    "max_tokens": 2048
  }
}
```

**Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `execution_strategy` | string | Yes | Must be `"mlflow_model"` |
| `mlflow_model.policy_version_id` | string (UUID) | Yes | Reference to `exp.policy_versions.id` |
| `mlflow_model.model_name` | string | No | MLflow model name for reference |
| `params` | object | No | Runtime parameters |

### 6.3 Prompt Template Configuration (`prompt_template` strategy)

For conversational AI projects using prompts and flows:

```json
{
  "execution_strategy": "prompt_template",
  "prompt_config": {
    "prompt_version_id": "aa0e8400-e29b-41d4-a716-446655440005",
    "model_provider": "anthropic",
    "model_name": "claude-sonnet-4.5"
  },
  "flow_config": {
    "flow_id": "onboarding_v1",
    "initial_state": "welcome"
  },
  "params": {
    "temperature": 0.7,
    "max_tokens": 2048,
    "top_p": 0.9
  }
}
```

**Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `execution_strategy` | string | Yes | Must be `"prompt_template"` |
| `prompt_config.prompt_version_id` | string (UUID) | Yes | Reference to `exp.prompt_versions.id` |
| `prompt_config.model_provider` | string | Yes | LLM provider (e.g., `"anthropic"`, `"openai"`) |
| `prompt_config.model_name` | string | Yes | Specific model identifier |
| `flow_config.flow_id` | string | No | Conversation flow identifier |
| `flow_config.initial_state` | string | No | Starting state in flow state machine |
| `params` | object | No | Runtime parameters |

### 6.4 Hybrid Configuration (`hybrid` strategy)

For projects combining both ML models and prompts:

```json
{
  "execution_strategy": "hybrid",
  "mlflow_model": {
    "policy_version_id": "770e8400-e29b-41d4-a716-446655440002",
    "model_name": "planner_model"
  },
  "prompt_config": {
    "prompt_version_id": "aa0e8400-e29b-41d4-a716-446655440005",
    "model_provider": "anthropic",
    "model_name": "claude-sonnet-4.5"
  },
  "params": {
    "temperature": 0.7
  }
}
```

### 6.5 Runtime Parameters (`params`)

The `params` object contains execution-strategy agnostic runtime parameters:

```json
{
  "params": {
    "temperature": 0.7,
    "max_tokens": 2048,
    "top_p": 0.9,
    "exploration_rate": 0.15,
    "feature_enabled": true
  }
}
```

Common parameters:
- `temperature` (number): Controls randomness in model outputs
- `max_tokens` (integer): Maximum tokens in response
- `top_p` (number): Nucleus sampling parameter
- `exploration_rate` (number): For ML models with exploration
- Any custom parameters defined in the variant

### 6.6 Backward Compatibility

**Legacy Format (Still Supported):**

The service maintains full backward compatibility with existing ML projects. The legacy format without `execution_strategy` continues to work:

```json
{
  "policy_version_id": "770e8400-e29b-41d4-a716-446655440002",
  "params": {
    "exploration_rate": 0.15,
    "temperature": 0.7
  }
}
```

When `execution_strategy` is omitted, the service automatically treats the config as `execution_strategy: "mlflow_model"` and extracts `policy_version_id` from the root level. This ensures:

- Existing experiments continue to work without modification
- Gradual migration path to unified format
- No breaking changes for current integrations

**Migration Path:**

Existing projects can migrate to the unified format by wrapping their existing config:

```json
// Before (still works)
{
  "policy_version_id": "uuid-v1",
  "params": { "temperature": 0.7 }
}

// After (recommended)
{
  "execution_strategy": "mlflow_model",
  "mlflow_model": {
    "policy_version_id": "uuid-v1"
  },
  "params": { "temperature": 0.7 }
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

### 10.2 Usage (Legacy Format)

```pseudo
client = AssignmentClient("https://api.example.com", API_KEY)

assignments = client.get_assignments(
    unit_type="user",
    unit_id="user-123",
    experiments=["planner_policy_exp"],
    context={"app_version": "1.2.3"}
)

for assignment in assignments["assignments"]:
    config = assignment["config"]
    
    # Handle legacy format (backward compatible)
    if "policy_version_id" in config:
        policy_version_id = config["policy_version_id"]
        params = config.get("params", {})
        # Use policy_version_id to load model
        # Apply params to model execution
```

### 10.3 Usage (Unified Format)

```pseudo
client = AssignmentClient("https://api.example.com", API_KEY)

assignments = client.get_assignments(
    unit_type="user",
    unit_id="user-123",
    experiments=["planner_policy_exp", "chatbot_assistant_exp"],
    context={"app_version": "1.2.3"}
)

for assignment in assignments["assignments"]:
    config = assignment["config"]
    strategy = config.get("execution_strategy", "mlflow_model")  # Default for backward compat
    params = config.get("params", {})
    
    if strategy == "mlflow_model":
        # Traditional ML project
        policy_version_id = config["mlflow_model"]["policy_version_id"]
        model_name = config["mlflow_model"].get("model_name")
        # Load model from MLflow using policy_version_id
        # Apply params to model execution
        
    elif strategy == "prompt_template":
        # Conversational AI project
        prompt_version_id = config["prompt_config"]["prompt_version_id"]
        model_provider = config["prompt_config"]["model_provider"]
        model_name = config["prompt_config"]["model_name"]
        flow_config = config.get("flow_config", {})
        # Load prompt template using prompt_version_id
        # Initialize conversation flow if flow_config present
        # Call LLM provider with prompt and params
        
    elif strategy == "hybrid":
        # Combined approach
        mlflow_config = config.get("mlflow_model", {})
        prompt_config = config.get("prompt_config", {})
        # Use both ML model and prompt template
        # Orchestrate execution based on business logic
```

### 10.4 Helper Function for Config Parsing

```pseudo
def parse_config(config):
    """Parse variant config, handling both legacy and unified formats."""
    # Check for unified format
    if "execution_strategy" in config:
        strategy = config["execution_strategy"]
        params = config.get("params", {})
        
        if strategy == "mlflow_model":
            return {
                "type": "mlflow_model",
                "policy_version_id": config["mlflow_model"]["policy_version_id"],
                "model_name": config["mlflow_model"].get("model_name"),
                "params": params
            }
        elif strategy == "prompt_template":
            return {
                "type": "prompt_template",
                "prompt_version_id": config["prompt_config"]["prompt_version_id"],
                "model_provider": config["prompt_config"]["model_provider"],
                "model_name": config["prompt_config"]["model_name"],
                "flow_config": config.get("flow_config", {}),
                "params": params
            }
        elif strategy == "hybrid":
            return {
                "type": "hybrid",
                "mlflow_model": config.get("mlflow_model", {}),
                "prompt_config": config.get("prompt_config", {}),
                "params": params
            }
    
    # Legacy format (backward compatibility)
    if "policy_version_id" in config:
        return {
            "type": "mlflow_model",
            "policy_version_id": config["policy_version_id"],
            "params": config.get("params", {})
        }
    
    raise ValueError("Invalid config format")
```

---

## 11. Related Documentation

| Document | Purpose |
|----------|---------|
| [DESIGN.md](DESIGN.md) | Implementation design |
| [../../docs/experiments.md](../../docs/experiments.md) | Experiment concepts |
| [../../docs/assignment-service.md](../../docs/assignment-service.md) | Service overview |

