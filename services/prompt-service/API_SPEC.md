# Prompt Service API Specification

**Purpose**  
This document defines the API contract for the Prompt Service, which manages versioned prompt templates for conversational AI projects.

---

## Start Here If…

- **Calling the service** → Read this document
- **Implementing the service** → Go to [DESIGN.md](DESIGN.md)
- **Understanding prompts** → Go to [../../docs/prompts-guide.md](../../docs/prompts-guide.md) (coming in Phase 2)
- **Understanding data model** → Go to [../../docs/data-model.md](../../docs/data-model.md) section 4

---

## 1. Base Information

| Property | Value |
|----------|-------|
| Base URL | `/api/v1` |
| Content-Type | `application/json` |
| Authentication | Bearer token (TODO: specify auth scheme) |

---

## 2. Endpoints

### 2.1 Get Prompt Version by ID

Retrieves a specific prompt version configuration and content.

#### Request

```
GET /prompt-versions/{prompt_version_id}
```

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `prompt_version_id` | string (UUID) | Yes | UUID of the prompt version |

#### Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Authorization` | Yes | Bearer token |
| `X-Request-ID` | No | Request correlation ID |

#### Response (200 OK)

```json
{
  "id": "770e8400-e29b-41d4-a716-446655440002",
  "prompt_id": "550e8400-e29b-41d4-a716-446655440000",
  "prompt_name": "meal_planning_assistant",
  "version": 1,
  "file_path": "prompts/meal_planning_v1.txt",
  "content": "You are a helpful meal planning assistant...",
  "model_provider": "anthropic",
  "model_name": "claude-sonnet-4.5",
  "config_defaults": {
    "temperature": 0.7,
    "max_tokens": 2048
  },
  "status": "active",
  "created_at": "2025-01-15T10:00:00Z"
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | UUID of the prompt version |
| `prompt_id` | string (UUID) | UUID of the parent prompt |
| `prompt_name` | string | Name of the prompt |
| `version` | integer | Version number |
| `file_path` | string | Path to prompt file relative to repo root |
| `content` | string | Prompt template content (loaded from file) |
| `model_provider` | string | LLM provider (e.g., "anthropic", "openai") |
| `model_name` | string | Model identifier (e.g., "claude-sonnet-4.5") |
| `config_defaults` | object | Default runtime parameters |
| `status` | string | Version status: `active`, `deprecated`, `archived` |
| `created_at` | string (ISO 8601) | Creation timestamp |

---

### 2.2 List Prompts

Retrieves a list of all prompts.

#### Request

```
GET /prompts
```

#### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `limit` | integer | No | Maximum number of results (default: 50, max: 100) |
| `offset` | integer | No | Number of results to skip (default: 0) |

#### Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Authorization` | Yes | Bearer token |
| `X-Request-ID` | No | Request correlation ID |

#### Response (200 OK)

```json
{
  "prompts": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "meal_planning_assistant",
      "description": "Assistant for helping users plan meals",
      "created_at": "2025-01-01T10:00:00Z"
    },
    {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "name": "customer_support_bot",
      "description": "Customer support chatbot",
      "created_at": "2025-01-10T10:00:00Z"
    }
  ],
  "pagination": {
    "limit": 50,
    "offset": 0,
    "total": 2
  }
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `prompts` | array | List of prompts |
| `prompts[].id` | string (UUID) | UUID of the prompt |
| `prompts[].name` | string | Name of the prompt |
| `prompts[].description` | string | Description of the prompt |
| `prompts[].created_at` | string (ISO 8601) | Creation timestamp |
| `pagination` | object | Pagination metadata |
| `pagination.limit` | integer | Requested limit |
| `pagination.offset` | integer | Requested offset |
| `pagination.total` | integer | Total number of prompts |

---

### 2.3 List Versions of a Prompt

Retrieves all versions of a specific prompt.

#### Request

```
GET /prompts/{prompt_id}/versions
```

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `prompt_id` | string (UUID) | Yes | UUID of the prompt |

#### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `status` | string | No | Filter by status: `active`, `deprecated`, `archived` |
| `limit` | integer | No | Maximum number of results (default: 50, max: 100) |
| `offset` | integer | No | Number of results to skip (default: 0) |

#### Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Authorization` | Yes | Bearer token |
| `X-Request-ID` | No | Request correlation ID |

#### Response (200 OK)

```json
{
  "prompt": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "meal_planning_assistant",
    "description": "Assistant for helping users plan meals"
  },
  "versions": [
    {
      "id": "770e8400-e29b-41d4-a716-446655440002",
      "version": 1,
      "file_path": "prompts/meal_planning_v1.txt",
      "model_provider": "anthropic",
      "model_name": "claude-sonnet-4.5",
      "config_defaults": {
        "temperature": 0.7,
        "max_tokens": 2048
      },
      "status": "active",
      "created_at": "2025-01-15T10:00:00Z"
    },
    {
      "id": "880e8400-e29b-41d4-a716-446655440003",
      "version": 2,
      "file_path": "prompts/meal_planning_v2.txt",
      "model_provider": "anthropic",
      "model_name": "claude-sonnet-4.5",
      "config_defaults": {
        "temperature": 0.8,
        "max_tokens": 2048
      },
      "status": "active",
      "created_at": "2025-02-01T10:00:00Z"
    }
  ],
  "pagination": {
    "limit": 50,
    "offset": 0,
    "total": 2
  }
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `prompt` | object | Prompt information |
| `prompt.id` | string (UUID) | UUID of the prompt |
| `prompt.name` | string | Name of the prompt |
| `prompt.description` | string | Description of the prompt |
| `versions` | array | List of prompt versions |
| `versions[].id` | string (UUID) | UUID of the prompt version |
| `versions[].version` | integer | Version number |
| `versions[].file_path` | string | Path to prompt file |
| `versions[].model_provider` | string | LLM provider |
| `versions[].model_name` | string | Model identifier |
| `versions[].config_defaults` | object | Default runtime parameters |
| `versions[].status` | string | Version status |
| `versions[].created_at` | string (ISO 8601) | Creation timestamp |
| `pagination` | object | Pagination metadata |

---

## 3. Error Responses

### 3.1 Validation Error (400)

```json
{
  "error": "validation_error",
  "message": "Invalid request parameters",
  "details": [
    {
      "field": "prompt_version_id",
      "error": "invalid_uuid_format"
    }
  ]
}
```

### 3.2 Not Found (404)

```json
{
  "error": "not_found",
  "message": "Prompt version not found",
  "prompt_version_id": "770e8400-e29b-41d4-a716-446655440002"
}
```

### 3.3 Unauthorized (401)

```json
{
  "error": "unauthorized",
  "message": "Invalid or missing authentication token"
}
```

### 3.4 Rate Limited (429)

```json
{
  "error": "rate_limited",
  "message": "Too many requests",
  "retry_after": 60
}
```

### 3.5 Service Unavailable (503)

```json
{
  "error": "service_unavailable",
  "message": "Database temporarily unavailable",
  "retry_after": 5
}
```

---

## 4. Example Requests

### 4.1 Get Prompt Version

```bash
curl -X GET https://api.example.com/api/v1/prompt-versions/770e8400-e29b-41d4-a716-446655440002 \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response:**
```json
{
  "id": "770e8400-e29b-41d4-a716-446655440002",
  "prompt_id": "550e8400-e29b-41d4-a716-446655440000",
  "prompt_name": "meal_planning_assistant",
  "version": 1,
  "file_path": "prompts/meal_planning_v1.txt",
  "content": "You are a helpful meal planning assistant. Help users create meal plans based on their preferences...",
  "model_provider": "anthropic",
  "model_name": "claude-sonnet-4.5",
  "config_defaults": {
    "temperature": 0.7,
    "max_tokens": 2048
  },
  "status": "active",
  "created_at": "2025-01-15T10:00:00Z"
}
```

### 4.2 List All Prompts

```bash
curl -X GET "https://api.example.com/api/v1/prompts?limit=20&offset=0" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response:**
```json
{
  "prompts": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "meal_planning_assistant",
      "description": "Assistant for helping users plan meals",
      "created_at": "2025-01-01T10:00:00Z"
    }
  ],
  "pagination": {
    "limit": 20,
    "offset": 0,
    "total": 1
  }
}
```

### 4.3 List Versions of a Prompt

```bash
curl -X GET "https://api.example.com/api/v1/prompts/550e8400-e29b-41d4-a716-446655440000/versions?status=active" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Response:**
```json
{
  "prompt": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "meal_planning_assistant",
    "description": "Assistant for helping users plan meals"
  },
  "versions": [
    {
      "id": "770e8400-e29b-41d4-a716-446655440002",
      "version": 1,
      "file_path": "prompts/meal_planning_v1.txt",
      "model_provider": "anthropic",
      "model_name": "claude-sonnet-4.5",
      "config_defaults": {
        "temperature": 0.7,
        "max_tokens": 2048
      },
      "status": "active",
      "created_at": "2025-01-15T10:00:00Z"
    }
  ],
  "pagination": {
    "limit": 50,
    "offset": 0,
    "total": 1
  }
}
```

---

## 5. Status Values

| Status | Description |
|--------|-------------|
| `active` | Currently in use, can be assigned to variants |
| `deprecated` | No longer recommended, but still supported |
| `archived` | Retired, not available for new assignments |

---

## 6. File Storage

Prompt content is stored in the `/prompts/` directory (Git versioned):

- **File Path Format:** `prompts/{prompt_name}_v{version}.txt`
- **Example:** `prompts/meal_planning_v1.txt`
- **Version Control:** Git provides history and versioning for prompt content
- **Content Loading:** Service reads file content from disk when serving prompt versions

---

## 7. Idempotency

All GET endpoints are **idempotent**:

- Same request always returns same response
- Safe to retry on network failures
- No side effects on repeated calls

---

## 8. Caching Behavior

### 8.1 Client-Side Caching

Clients MAY cache prompt versions:

| Header | Value | Meaning |
|--------|-------|---------|
| `Cache-Control` | `max-age=3600` | Cache for 1 hour |

### 8.2 Invalidation

Clients SHOULD refresh when:
- Prompt version status changes
- New version is created
- Explicit cache invalidation requested

---

## 9. Rate Limits

| Limit | Value |
|-------|-------|
| Per API key | 1,000 requests/minute |

---

## 10. SDK Examples

### 10.1 Python (Pseudo-code)

```pseudo
class PromptClient:
    def __init__(self, base_url, api_key):
        self.base_url = base_url
        self.api_key = api_key
        self.cache = {}
    
    def get_prompt_version(self, prompt_version_id):
        # Check cache
        cache_key = f"prompt_version:{prompt_version_id}"
        if cache_key in self.cache:
            if not self.cache[cache_key].expired():
                return self.cache[cache_key].value
        
        # Make request
        response = http.get(
            f"{self.base_url}/api/v1/prompt-versions/{prompt_version_id}",
            headers={"Authorization": f"Bearer {self.api_key}"}
        )
        
        # Cache and return
        self.cache[cache_key] = CacheEntry(response.json(), ttl=3600)
        return response.json()
    
    def list_prompts(self, limit=50, offset=0):
        response = http.get(
            f"{self.base_url}/api/v1/prompts",
            headers={"Authorization": f"Bearer {self.api_key}"},
            params={"limit": limit, "offset": offset}
        )
        return response.json()
    
    def list_prompt_versions(self, prompt_id, status=None, limit=50, offset=0):
        params = {"limit": limit, "offset": offset}
        if status:
            params["status"] = status
        
        response = http.get(
            f"{self.base_url}/api/v1/prompts/{prompt_id}/versions",
            headers={"Authorization": f"Bearer {self.api_key}"},
            params=params
        )
        return response.json()
```

### 10.2 Usage

```pseudo
client = PromptClient("https://api.example.com", API_KEY)

# Get specific prompt version
prompt_version = client.get_prompt_version("770e8400-e29b-41d4-a716-446655440002")
print(f"Prompt: {prompt_version['prompt_name']} v{prompt_version['version']}")
print(f"Content: {prompt_version['content']}")
print(f"Model: {prompt_version['model_provider']}/{prompt_version['model_name']}")

# List all prompts
prompts_response = client.list_prompts(limit=20)
for prompt in prompts_response["prompts"]:
    print(f"Prompt: {prompt['name']} - {prompt['description']}")

# List versions of a prompt
versions_response = client.list_prompt_versions(
    prompt_id="550e8400-e29b-41d4-a716-446655440000",
    status="active"
)
for version in versions_response["versions"]:
    print(f"Version {version['version']}: {version['status']}")
```

---

## 11. Related Documentation

| Document | Purpose |
|----------|---------|
| [DESIGN.md](DESIGN.md) | Implementation design |
| [../../docs/data-model.md](../../docs/data-model.md) | Database schema (section 4) |
| [../../docs/prompts-guide.md](../../docs/prompts-guide.md) | Prompt management guide (coming in Phase 2) |

---

## After Completing This Document

You will understand:
- How to retrieve prompt versions by ID
- How to list prompts and their versions
- The structure of prompt version responses
- How to handle errors and rate limiting

**Next Step**: Review [DESIGN.md](DESIGN.md) for implementation details
