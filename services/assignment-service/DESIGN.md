# Assignment Service Design

**Purpose**  
This document describes the internal design and architecture decisions for the Experiment Assignment Service (EAS).

---

## Start Here If…

- **Implementing the service** → Read this document
- **Calling the service** → Go to [API_SPEC.md](API_SPEC.md)
- **Understanding experiments** → Go to [../../docs/experiments.md](../../docs/experiments.md)

---

## 1. Service Overview

### 1.1 Responsibilities

| Responsibility | Description |
|----------------|-------------|
| Variant Assignment | Determine which variant a unit receives |
| Config Delivery | Return variant configuration |
| Assignment Persistence | Store assignments for consistency |
| Caching | Reduce database load |

### 1.2 Non-Responsibilities

| Not Responsible For | Handled By |
|---------------------|------------|
| Event logging | Event Ingestion Service |
| Model loading | Planner service |
| Metrics aggregation | Offline pipelines |

---

## 2. Architecture

### 2.1 Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                  Assignment Service                          │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   API Layer  │ ──►│   Business   │ ──►│   Data       │  │
│  │              │    │   Logic      │    │   Access     │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│                              │                    │         │
│                              ▼                    ▼         │
│                       ┌──────────────┐    ┌──────────────┐ │
│                       │   Cache      │    │   Database   │ │
│                       │   (Redis)    │    │   (Postgres) │ │
│                       └──────────────┘    └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow

```
1. Request arrives at API layer
2. API validates request
3. Business logic checks cache for existing assignment
4. If cache miss: query database
5. If no assignment: compute new assignment
6. Persist new assignment to database
7. Update cache
8. Return assignment with config
```

---

## 3. Assignment Algorithm

### 3.1 Hash-Based Bucketing

```pseudo
function compute_bucket(experiment_id, unit_id):
    # Concatenate identifiers
    hash_input = f"{experiment_id}:{unit_id}"
    
    # Use stable hash algorithm (SHA-256 recommended)
    hash_bytes = sha256(hash_input.encode())
    hash_int = int.from_bytes(hash_bytes[:8], 'big')
    
    # Map to bucket (0-9999 for 0.01% granularity)
    bucket = hash_int % 10000
    
    return bucket
```

### 3.2 Variant Selection

```pseudo
function select_variant(bucket, variants):
    # Variants sorted by creation order
    cumulative = 0
    
    for variant in variants:
        cumulative += int(variant.allocation * 10000)
        if bucket < cumulative:
            return variant
    
    # Fallback to last variant (should not happen if allocations sum to 1.0)
    return variants[-1]
```

### 3.3 Algorithm Properties

| Property | Implementation |
|----------|----------------|
| Deterministic | SHA-256 hash of fixed input |
| Uniform | Hash distribution is uniform |
| Stable | Same input always gives same output |
| Collision-resistant | 64-bit hash space |

---

## 4. Caching Strategy

### 4.1 Cache Key Format

```
assignment:{experiment_id}:{unit_id}
```

### 4.2 Cache Value

```json
{
  "variant_id": "uuid",
  "variant_name": "variant_a",
  "config": { ... },
  "cached_at": "2025-01-01T10:00:00Z"
}
```

### 4.3 TTL Strategy

| Scenario | TTL |
|----------|-----|
| Normal | 1 hour |
| High traffic | 15 minutes |
| After experiment change | Invalidate all |

### 4.4 Cache Invalidation

```pseudo
function invalidate_experiment_cache(experiment_id):
    # Pattern-based deletion
    pattern = f"assignment:{experiment_id}:*"
    keys = redis.scan(pattern)
    redis.delete(*keys)
```

---

## 5. Database Schema Usage

### 5.1 Tables Accessed

| Table | Access Pattern |
|-------|----------------|
| `exp.experiments` | Read by name |
| `exp.variants` | Read by experiment_id |
| `exp.assignments` | Read/Write by (experiment_id, unit_id) |

### 5.2 Indexes Required

```sql
-- For experiment lookup
CREATE INDEX idx_experiments_name ON exp.experiments(name);

-- For variant lookup
CREATE INDEX idx_variants_experiment ON exp.variants(experiment_id);

-- For assignment lookup
CREATE UNIQUE INDEX idx_assignments_lookup 
    ON exp.assignments(experiment_id, unit_id);
```

---

## 6. Error Handling

### 6.1 Error Categories

| Category | Response | Action |
|----------|----------|--------|
| Validation error | 400 | Return error details |
| Experiment not found | 200 | Omit from response |
| Database error | 503 | Retry logic |
| Cache error | N/A | Fallback to database |

### 6.2 Retry Strategy

```pseudo
# Database retry
max_retries = 3
backoff_base = 100ms

for attempt in range(max_retries):
    try:
        return execute_query(...)
    except DatabaseError:
        sleep(backoff_base * (2 ** attempt))

raise ServiceUnavailable()
```

---

## 7. Performance Considerations

### 7.1 Expected Latency

| Operation | Target P50 | Target P99 |
|-----------|------------|------------|
| Cache hit | <5ms | <20ms |
| Cache miss | <50ms | <200ms |
| New assignment | <100ms | <500ms |

### 7.2 Throughput

| Metric | Target |
|--------|--------|
| RPS per instance | 1000 |
| Concurrent connections | 100 |

### 7.3 Optimization Strategies

- Connection pooling for database
- Pipeline Redis commands
- Batch experiment lookups

---

## 8. Monitoring

### 8.1 Metrics to Expose

| Metric | Type | Labels |
|--------|------|--------|
| `assignment_requests_total` | Counter | status, experiment |
| `assignment_latency_seconds` | Histogram | experiment |
| `cache_hits_total` | Counter | |
| `cache_misses_total` | Counter | |
| `new_assignments_total` | Counter | experiment |

### 8.2 Alerting Rules

```pseudo
# High error rate
if error_rate > 1%:
    alert("Assignment service error rate high")

# High latency
if p99_latency > 500ms:
    alert("Assignment service latency degraded")
```

---

## 9. Security Considerations

### 9.1 Input Validation

```pseudo
function validate_request(request):
    # Unit ID format
    if not valid_unit_id(request.unit_id):
        raise ValidationError("Invalid unit_id format")
    
    # Experiment names
    for exp_name in request.requested_experiments:
        if not valid_experiment_name(exp_name):
            raise ValidationError("Invalid experiment name")
```

### 9.2 Rate Limiting

```pseudo
# Per-unit rate limit
limit = 100 requests per minute per unit_id

if rate_limiter.exceeded(request.unit_id):
    return 429 Too Many Requests
```

---

## 10. Config Parsing and Validation

### 10.1 Unified Config Structure

The service handles variant configs stored in `exp.variants.config` (JSONB column) that support both traditional ML projects and conversational AI projects. The config structure is flexible and can represent different execution strategies.

**Supported Execution Strategies:**

| Strategy | Description | Use Case |
|----------|-------------|----------|
| `mlflow_model` | Traditional ML with trained models | MLflow Model Registry integration |
| `prompt_template` | Conversational AI with prompts | LLM-powered chatbots and assistants |
| `hybrid` | Combined approach | Projects using both models and prompts |

### 10.2 Config Parsing Logic

```pseudo
function parse_config(raw_config):
    """
    Parse variant config, handling both legacy and unified formats.
    Returns normalized config structure.
    """
    
    # Check for unified format (has execution_strategy)
    if "execution_strategy" in raw_config:
        strategy = raw_config["execution_strategy"]
        
        # Validate execution strategy value
        if strategy not in ["mlflow_model", "prompt_template", "hybrid"]:
            raise InvalidConfigError("Invalid execution_strategy")
        
        # Validate strategy-specific fields
        if strategy == "mlflow_model" or strategy == "hybrid":
            if "mlflow_model" not in raw_config:
                raise InvalidConfigError("mlflow_model required for strategy")
            if "policy_version_id" not in raw_config["mlflow_model"]:
                raise InvalidConfigError("policy_version_id required in mlflow_model")
        
        if strategy == "prompt_template" or strategy == "hybrid":
            if "prompt_config" not in raw_config:
                raise InvalidConfigError("prompt_config required for strategy")
            if "prompt_version_id" not in raw_config["prompt_config"]:
                raise InvalidConfigError("prompt_version_id required in prompt_config")
            if "model_provider" not in raw_config["prompt_config"]:
                raise InvalidConfigError("model_provider required in prompt_config")
            if "model_name" not in raw_config["prompt_config"]:
                raise InvalidConfigError("model_name required in prompt_config")
        
        # Return normalized config (preserve structure)
        return {
            "execution_strategy": strategy,
            "mlflow_model": raw_config.get("mlflow_model"),
            "prompt_config": raw_config.get("prompt_config"),
            "flow_config": raw_config.get("flow_config"),
            "params": raw_config.get("params", {})
        }
    
    # Legacy format handling (backward compatibility)
    if "policy_version_id" in raw_config:
        # Normalize legacy format to unified format
        return {
            "execution_strategy": "mlflow_model",
            "mlflow_model": {
                "policy_version_id": raw_config["policy_version_id"],
                "model_name": raw_config.get("model_name")
            },
            "params": raw_config.get("params", {})
        }
    
    # Invalid config (neither unified nor legacy format)
    raise InvalidConfigError("Config must have execution_strategy or policy_version_id")
```

### 10.3 Backward Compatibility Handling

The service maintains full backward compatibility with existing ML projects using the legacy `policy_version_id` format at the root level.

**Legacy Format Detection:**

```pseudo
function is_legacy_format(config):
    """
    Check if config uses legacy format (policy_version_id at root).
    """
    return "execution_strategy" not in config and "policy_version_id" in config
```

**Normalization Strategy:**

When a legacy format config is detected:
1. Automatically infer `execution_strategy: "mlflow_model"`
2. Extract `policy_version_id` from root level
3. Wrap it in `mlflow_model` object structure
4. Preserve `params` object as-is
5. Return normalized config structure

**Example Transformation:**

```pseudo
# Legacy config (from database)
legacy_config = {
    "policy_version_id": "uuid-v1",
    "params": {"temperature": 0.7}
}

# Normalized config (returned to caller)
normalized_config = {
    "execution_strategy": "mlflow_model",
    "mlflow_model": {
        "policy_version_id": "uuid-v1"
    },
    "params": {"temperature": 0.7}
}
```

**Response Format Decision:**

The service can return configs in two ways:
- **Option A (Recommended):** Always return unified format (normalize legacy configs)
- **Option B:** Return configs as stored (preserve legacy format for backward compatibility)

**Current Design Choice:** Option A - Always normalize to unified format. This provides:
- Consistent API response structure
- Easier client-side handling
- Clear migration path
- No breaking changes (clients can handle unified format)

### 10.4 Config Validation

**Validation Rules:**

```pseudo
function validate_config(config):
    """
    Validate config structure and required fields.
    Raises InvalidConfigError if validation fails.
    """
    errors = []
    
    # Execution strategy validation
    if "execution_strategy" not in config:
        errors.append("execution_strategy is required")
    else:
        valid_strategies = ["mlflow_model", "prompt_template", "hybrid"]
        if config["execution_strategy"] not in valid_strategies:
            errors.append(f"execution_strategy must be one of {valid_strategies}")
    
    strategy = config.get("execution_strategy")
    
    # ML model validation
    if strategy in ["mlflow_model", "hybrid"]:
        if "mlflow_model" not in config:
            errors.append("mlflow_model required for mlflow_model/hybrid strategy")
        else:
            mlflow = config["mlflow_model"]
            if "policy_version_id" not in mlflow:
                errors.append("policy_version_id required in mlflow_model")
            elif not is_valid_uuid(mlflow["policy_version_id"]):
                errors.append("policy_version_id must be a valid UUID")
    
    # Prompt config validation
    if strategy in ["prompt_template", "hybrid"]:
        if "prompt_config" not in config:
            errors.append("prompt_config required for prompt_template/hybrid strategy")
        else:
            prompt = config["prompt_config"]
            if "prompt_version_id" not in prompt:
                errors.append("prompt_version_id required in prompt_config")
            elif not is_valid_uuid(prompt["prompt_version_id"]):
                errors.append("prompt_version_id must be a valid UUID")
            if "model_provider" not in prompt:
                errors.append("model_provider required in prompt_config")
            if "model_name" not in prompt:
                errors.append("model_name required in prompt_config")
    
    # Params validation (optional but should be object if present)
    if "params" in config and not isinstance(config["params"], dict):
        errors.append("params must be an object")
    
    if errors:
        raise InvalidConfigError(f"Config validation failed: {', '.join(errors)}")
```

**Validation Timing:**

- **At Assignment Time:** Config is validated when variant is selected and returned
- **At Experiment Creation:** Config validation should occur when variants are created (separate service responsibility)
- **Graceful Degradation:** Invalid configs result in assignment error, not service failure

### 10.5 Error Handling for Invalid Configs

**Error Categories:**

| Error Type | HTTP Status | Response |
|------------|-------------|----------|
| Invalid execution_strategy | 500 | Internal error (data integrity issue) |
| Missing required fields | 500 | Internal error (data integrity issue) |
| Invalid UUID format | 500 | Internal error (data integrity issue) |
| Legacy format parse error | 500 | Internal error (unexpected legacy format issue) |

**Error Response:**

```json
{
  "error": "internal_error",
  "message": "Invalid variant configuration",
  "details": {
    "variant_id": "uuid",
    "experiment_id": "uuid",
    "validation_errors": [
      "policy_version_id must be a valid UUID"
    ]
  }
}
```

**Error Handling Strategy:**

```pseudo
function get_assignment_with_config(experiment_id, unit_id):
    """
    Get assignment and handle config parsing errors gracefully.
    """
    try:
        variant = get_variant_assignment(experiment_id, unit_id)
        config = parse_config(variant.config)
        validate_config(config)
        return {
            "variant_id": variant.id,
            "variant_name": variant.name,
            "config": config
        }
    except InvalidConfigError as e:
        # Log error for monitoring
        log_error("Invalid config", variant_id=variant.id, error=str(e))
        
        # Return error response (don't fail entire request)
        return {
            "variant_id": variant.id,
            "variant_name": variant.name,
            "config": None,
            "config_error": str(e)
        }
    except Exception as e:
        # Unexpected error - log and return generic error
        log_error("Config parsing failed", error=str(e))
        raise InternalError("Failed to parse variant config")
```

### 10.6 Performance Considerations

**Config Parsing Overhead:**

| Operation | Expected Latency | Notes |
|-----------|------------------|-------|
| Parse unified config | <0.1ms | Simple JSON structure access |
| Parse legacy config | <0.2ms | Includes normalization step |
| Validate config | <0.5ms | Field existence and UUID checks |
| Total overhead | <1ms | Negligible compared to DB query |

**Optimization Strategies:**

1. **Parse Once, Cache Result:**
   - Config parsing happens when variant is loaded from database
   - Parsed config is cached with assignment in Redis
   - Subsequent requests use cached parsed config

2. **Lazy Validation:**
   - Validate config only when needed (not on every cache hit)
   - Validation errors cached to avoid repeated parsing attempts

3. **Normalization Caching:**
   - Legacy configs normalized once and cached
   - Normalized format stored in cache to avoid repeated transformation

**Cache Key Impact:**

The config structure does **not** affect cache keys. Cache keys remain:
```
assignment:{experiment_id}:{unit_id}
```

This ensures:
- Same cache key regardless of config format
- Cache invalidation works correctly
- No cache fragmentation by config type

**Database Query Impact:**

Config parsing happens **after** database query, so:
- No impact on SQL query performance
- JSONB column access is efficient
- Parsing overhead is post-query

### 10.7 Monitoring Config Parsing

**Metrics to Track:**

| Metric | Type | Purpose |
|--------|------|---------|
| `config_parse_total` | Counter | Total configs parsed |
| `config_parse_legacy_total` | Counter | Legacy format configs normalized |
| `config_parse_errors_total` | Counter | Config parsing failures |
| `config_validation_errors_total` | Counter | Config validation failures |
| `config_parse_duration_seconds` | Histogram | Parsing latency |

**Alerting:**

```pseudo
# High config error rate
if config_parse_errors_total / config_parse_total > 0.01:
    alert("Config parsing error rate high (>1%)")

# High validation error rate
if config_validation_errors_total / config_parse_total > 0.01:
    alert("Config validation error rate high (>1%)")
```

---

## 11. TODO: Implementation Notes

- [ ] Choose web framework (e.g., FastAPI, Express, Go Gin)
- [ ] Implement Redis caching layer
- [ ] Set up connection pooling
- [ ] Add Prometheus metrics
- [ ] Configure rate limiting
- [ ] Implement unified config parsing logic
- [ ] Add config validation
- [ ] Add config parsing metrics
- [ ] Write integration tests

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [API_SPEC.md](API_SPEC.md) | API specification |
| [../../docs/experiments.md](../../docs/experiments.md) | Experiment concepts |
| [../../docs/data-model.md](../../docs/data-model.md) | Database schema |

