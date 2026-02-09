# Unified Experiment Configuration Validator Specification

**Purpose**  
This document defines the validation rules and error messages for unified variant configurations used in the Experiment Assignment Service.

---

## Start Here If…

- **Implementing config validation** → Read this document
- **Understanding valid config formats** → Read this document
- **Calling the service** → Go to [API_SPEC.md](API_SPEC.md)
- **Service design** → Go to [DESIGN.md](DESIGN.md)

---

## 1. Overview

The unified config validator ensures that variant configurations stored in `exp.variants.config` (JSONB column) conform to the expected structure for both traditional ML projects and conversational AI projects.

**Validation Goals:**

- Ensure config structure matches declared execution strategy
- Validate required fields for each execution strategy
- Provide clear, actionable error messages
- Maintain backward compatibility with legacy `policy_version_id` format

---

## 2. Validation Rules

### 2.1 Execution Strategy Validation

**Rule:** `execution_strategy` must be present and have a valid value, OR config must use legacy format.

**Valid Values:**
- `"mlflow_model"` - Traditional ML projects
- `"prompt_template"` - Conversational AI projects
- `"hybrid"` - Combined approach

**Validation Logic:**

```pseudo
function validate_execution_strategy(config):
    """
    Validate execution_strategy field.
    Returns (is_valid, errors, inferred_strategy)
    """
    errors = []
    
    # Check if legacy format (backward compatibility)
    if "execution_strategy" not in config:
        if "policy_version_id" in config:
            # Legacy format - infer strategy
            return (true, [], "mlflow_model")
        else:
            # Neither unified nor legacy format
            errors.append("Config must have 'execution_strategy' or 'policy_version_id'")
            return (false, errors, null)
    
    # Unified format - validate value
    strategy = config["execution_strategy"]
    
    if not isinstance(strategy, str):
        errors.append("'execution_strategy' must be a string")
        return (false, errors, null)
    
    valid_strategies = ["mlflow_model", "prompt_template", "hybrid"]
    if strategy not in valid_strategies:
        errors.append(
            f"'execution_strategy' must be one of {valid_strategies}, got '{strategy}'"
        )
        return (false, errors, null)
    
    return (true, [], strategy)
```

**Error Messages:**

| Condition | Error Message |
|-----------|--------------|
| Missing execution_strategy and no policy_version_id | `"Config must have 'execution_strategy' or 'policy_version_id'"` |
| execution_strategy is not a string | `"'execution_strategy' must be a string"` |
| Invalid execution_strategy value | `"'execution_strategy' must be one of ['mlflow_model', 'prompt_template', 'hybrid'], got '{value}'"` |

---

### 2.2 ML Model Configuration Validation

**Rule:** When `execution_strategy` is `"mlflow_model"` or `"hybrid"`, `mlflow_model` object must be present with required fields.

**Required Fields:**
- `mlflow_model.policy_version_id` (string, UUID format)

**Optional Fields:**
- `mlflow_model.model_name` (string)

**Validation Logic:**

```pseudo
function validate_mlflow_model(config, strategy):
    """
    Validate mlflow_model structure.
    Returns (is_valid, errors)
    """
    errors = []
    
    # Check if mlflow_model is required for this strategy
    if strategy not in ["mlflow_model", "hybrid"]:
        return (true, [])  # Not required, skip validation
    
    # Check presence
    if "mlflow_model" not in config:
        errors.append(
            f"'mlflow_model' is required when execution_strategy is '{strategy}'"
        )
        return (false, errors)
    
    mlflow = config["mlflow_model"]
    
    # Validate type
    if not isinstance(mlflow, dict):
        errors.append("'mlflow_model' must be an object")
        return (false, errors)
    
    # Validate required fields
    if "policy_version_id" not in mlflow:
        errors.append("'mlflow_model.policy_version_id' is required")
    else:
        policy_version_id = mlflow["policy_version_id"]
        
        # Validate type
        if not isinstance(policy_version_id, str):
            errors.append("'mlflow_model.policy_version_id' must be a string")
        # Validate UUID format
        elif not is_valid_uuid(policy_version_id):
            errors.append(
                f"'mlflow_model.policy_version_id' must be a valid UUID, got '{policy_version_id}'"
            )
    
    # Validate optional fields if present
    if "model_name" in mlflow:
        if not isinstance(mlflow["model_name"], str):
            errors.append("'mlflow_model.model_name' must be a string")
    
    return (len(errors) == 0, errors)
```

**UUID Validation:**

```pseudo
function is_valid_uuid(value):
    """
    Validate UUID format (RFC 4122).
    Accepts formats: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    """
    uuid_pattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    return uuid_pattern.test(value)
```

**Error Messages:**

| Condition | Error Message |
|-----------|--------------|
| mlflow_model missing for mlflow_model strategy | `"'mlflow_model' is required when execution_strategy is 'mlflow_model'"` |
| mlflow_model missing for hybrid strategy | `"'mlflow_model' is required when execution_strategy is 'hybrid'"` |
| mlflow_model is not an object | `"'mlflow_model' must be an object"` |
| policy_version_id missing | `"'mlflow_model.policy_version_id' is required"` |
| policy_version_id is not a string | `"'mlflow_model.policy_version_id' must be a string"` |
| policy_version_id invalid UUID | `"'mlflow_model.policy_version_id' must be a valid UUID, got '{value}'"` |
| model_name is not a string | `"'mlflow_model.model_name' must be a string"` |

---

### 2.3 Prompt Configuration Validation

**Rule:** When `execution_strategy` is `"prompt_template"` or `"hybrid"`, `prompt_config` object must be present with required fields.

**Required Fields:**
- `prompt_config.prompt_version_id` (string, UUID format)
- `prompt_config.model_provider` (string)
- `prompt_config.model_name` (string)

**Validation Logic:**

```pseudo
function validate_prompt_config(config, strategy):
    """
    Validate prompt_config structure.
    Returns (is_valid, errors)
    """
    errors = []
    
    # Check if prompt_config is required for this strategy
    if strategy not in ["prompt_template", "hybrid"]:
        return (true, [])  # Not required, skip validation
    
    # Check presence
    if "prompt_config" not in config:
        errors.append(
            f"'prompt_config' is required when execution_strategy is '{strategy}'"
        )
        return (false, errors)
    
    prompt = config["prompt_config"]
    
    # Validate type
    if not isinstance(prompt, dict):
        errors.append("'prompt_config' must be an object")
        return (false, errors)
    
    # Validate required fields
    required_fields = {
        "prompt_version_id": "string",
        "model_provider": "string",
        "model_name": "string"
    }
    
    for field, expected_type in required_fields.items():
        if field not in prompt:
            errors.append(f"'prompt_config.{field}' is required")
        else:
            value = prompt[field]
            if not isinstance(value, expected_type):
                errors.append(
                    f"'prompt_config.{field}' must be a {expected_type}, got {type(value).__name__}"
                )
    
    # Validate UUID format for prompt_version_id
    if "prompt_version_id" in prompt:
        prompt_version_id = prompt["prompt_version_id"]
        if isinstance(prompt_version_id, str) and not is_valid_uuid(prompt_version_id):
            errors.append(
                f"'prompt_config.prompt_version_id' must be a valid UUID, got '{prompt_version_id}'"
            )
    
    return (len(errors) == 0, errors)
```

**Error Messages:**

| Condition | Error Message |
|-----------|--------------|
| prompt_config missing for prompt_template strategy | `"'prompt_config' is required when execution_strategy is 'prompt_template'"` |
| prompt_config missing for hybrid strategy | `"'prompt_config' is required when execution_strategy is 'hybrid'"` |
| prompt_config is not an object | `"'prompt_config' must be an object"` |
| prompt_version_id missing | `"'prompt_config.prompt_version_id' is required"` |
| prompt_version_id is not a string | `"'prompt_config.prompt_version_id' must be a string"` |
| prompt_version_id invalid UUID | `"'prompt_config.prompt_version_id' must be a valid UUID, got '{value}'"` |
| model_provider missing | `"'prompt_config.model_provider' is required"` |
| model_provider is not a string | `"'prompt_config.model_provider' must be a string, got {type}"` |
| model_name missing | `"'prompt_config.model_name' is required"` |
| model_name is not a string | `"'prompt_config.model_name' must be a string, got {type}"` |

---

### 2.4 Flow Configuration Validation

**Rule:** `flow_config` is optional, but if present, must be a valid object with string fields.

**Optional Fields:**
- `flow_config.flow_id` (string)
- `flow_config.initial_state` (string)

**Validation Logic:**

```pseudo
function validate_flow_config(config):
    """
    Validate flow_config structure (optional field).
    Returns (is_valid, errors)
    """
    errors = []
    
    # flow_config is optional, skip if not present
    if "flow_config" not in config:
        return (true, [])
    
    flow = config["flow_config"]
    
    # Validate type
    if not isinstance(flow, dict):
        errors.append("'flow_config' must be an object")
        return (false, errors)
    
    # Validate optional fields if present
    if "flow_id" in flow:
        if not isinstance(flow["flow_id"], str):
            errors.append("'flow_config.flow_id' must be a string")
    
    if "initial_state" in flow:
        if not isinstance(flow["initial_state"], str):
            errors.append("'flow_config.initial_state' must be a string")
    
    return (len(errors) == 0, errors)
```

**Error Messages:**

| Condition | Error Message |
|-----------|--------------|
| flow_config is not an object | `"'flow_config' must be an object"` |
| flow_id is not a string | `"'flow_config.flow_id' must be a string"` |
| initial_state is not a string | `"'flow_config.initial_state' must be a string"` |

---

### 2.5 Parameters Validation

**Rule:** `params` is optional, but if present, must be an object.

**Validation Logic:**

```pseudo
function validate_params(config):
    """
    Validate params structure (optional field).
    Returns (is_valid, errors)
    """
    errors = []
    
    # params is optional, skip if not present
    if "params" not in config:
        return (true, [])
    
    params = config["params"]
    
    # Validate type
    if not isinstance(params, dict):
        errors.append("'params' must be an object")
        return (false, errors)
    
    # No validation of param values - they are execution-strategy agnostic
    # Individual param validation is handled by consuming services
    
    return (true, errors)
```

**Error Messages:**

| Condition | Error Message |
|-----------|--------------|
| params is not an object | `"'params' must be an object"` |

---

### 2.6 Backward Compatibility Validation

**Rule:** Legacy format with `policy_version_id` at root level is accepted and normalized.

**Legacy Format:**

```json
{
  "policy_version_id": "uuid-policy-version",
  "params": {
    "temperature": 0.7
  }
}
```

**Validation Logic:**

```pseudo
function validate_legacy_config(config):
    """
    Validate legacy config format (backward compatibility).
    Returns (is_valid, errors, normalized_config)
    """
    errors = []
    
    # Check if this is legacy format
    if "execution_strategy" in config:
        return (true, [], null)  # Not legacy format
    
    if "policy_version_id" not in config:
        return (false, ["Config must have 'execution_strategy' or 'policy_version_id'"], null)
    
    # Validate policy_version_id
    policy_version_id = config["policy_version_id"]
    
    if not isinstance(policy_version_id, str):
        errors.append("'policy_version_id' must be a string")
    elif not is_valid_uuid(policy_version_id):
        errors.append(
            f"'policy_version_id' must be a valid UUID, got '{policy_version_id}'"
        )
    
    # Validate params if present
    if "params" in config:
        if not isinstance(config["params"], dict):
            errors.append("'params' must be an object")
    
    if len(errors) > 0:
        return (false, errors, null)
    
    # Normalize to unified format
    normalized = {
        "execution_strategy": "mlflow_model",
        "mlflow_model": {
            "policy_version_id": policy_version_id
        },
        "params": config.get("params", {})
    }
    
    # Preserve optional model_name if present
    if "model_name" in config:
        normalized["mlflow_model"]["model_name"] = config["model_name"]
    
    return (true, [], normalized)
```

**Error Messages:**

| Condition | Error Message |
|-----------|--------------|
| policy_version_id is not a string | `"'policy_version_id' must be a string"` |
| policy_version_id invalid UUID | `"'policy_version_id' must be a valid UUID, got '{value}'"` |
| params is not an object | `"'params' must be an object"` |

---

## 3. Complete Validation Function

**Main Validation Entry Point:**

```pseudo
function validate_variant_config(config):
    """
    Complete validation function for variant configs.
    Returns (is_valid, errors, normalized_config)
    """
    errors = []
    normalized_config = null
    
    # Step 1: Validate execution strategy (or detect legacy format)
    is_valid_strategy, strategy_errors, strategy = validate_execution_strategy(config)
    errors.extend(strategy_errors)
    
    if not is_valid_strategy:
        return (false, errors, null)
    
    # Step 2: Handle legacy format
    if strategy == "mlflow_model" and "execution_strategy" not in config:
        is_valid_legacy, legacy_errors, normalized = validate_legacy_config(config)
        errors.extend(legacy_errors)
        
        if not is_valid_legacy:
            return (false, errors, null)
        
        # Use normalized config for remaining validation
        config = normalized
        normalized_config = normalized
        strategy = "mlflow_model"
    
    # Step 3: Validate mlflow_model structure
    is_valid_mlflow, mlflow_errors = validate_mlflow_model(config, strategy)
    errors.extend(mlflow_errors)
    
    # Step 4: Validate prompt_config structure
    is_valid_prompt, prompt_errors = validate_prompt_config(config, strategy)
    errors.extend(prompt_errors)
    
    # Step 5: Validate flow_config structure
    is_valid_flow, flow_errors = validate_flow_config(config)
    errors.extend(flow_errors)
    
    # Step 6: Validate params structure
    is_valid_params, params_errors = validate_params(config)
    errors.extend(params_errors)
    
    # Return results
    is_valid = len(errors) == 0
    
    if is_valid and normalized_config is null:
        normalized_config = config  # Use original config if not normalized
    
    return (is_valid, errors, normalized_config)
```

---

## 4. Validation Examples

### 4.1 Valid Configurations

**Valid ML Model Config:**

```json
{
  "execution_strategy": "mlflow_model",
  "mlflow_model": {
    "policy_version_id": "550e8400-e29b-41d4-a716-446655440000",
    "model_name": "planner_model"
  },
  "params": {
    "temperature": 0.7,
    "exploration_rate": 0.15
  }
}
```

**Valid Prompt Template Config:**

```json
{
  "execution_strategy": "prompt_template",
  "prompt_config": {
    "prompt_version_id": "660e8400-e29b-41d4-a716-446655440001",
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
```

**Valid Hybrid Config:**

```json
{
  "execution_strategy": "hybrid",
  "mlflow_model": {
    "policy_version_id": "550e8400-e29b-41d4-a716-446655440000",
    "model_name": "planner_model"
  },
  "prompt_config": {
    "prompt_version_id": "660e8400-e29b-41d4-a716-446655440001",
    "model_provider": "anthropic",
    "model_name": "claude-sonnet-4.5"
  },
  "params": {
    "temperature": 0.7
  }
}
```

**Valid Legacy Config (Backward Compatible):**

```json
{
  "policy_version_id": "550e8400-e29b-41d4-a716-446655440000",
  "params": {
    "temperature": 0.7
  }
}
```

### 4.2 Invalid Configurations

**Missing execution_strategy (and no policy_version_id):**

```json
{
  "params": {
    "temperature": 0.7
  }
}
```

**Error:** `"Config must have 'execution_strategy' or 'policy_version_id'"`

**Invalid execution_strategy value:**

```json
{
  "execution_strategy": "invalid_strategy",
  "mlflow_model": {
    "policy_version_id": "550e8400-e29b-41d4-a716-446655440000"
  }
}
```

**Error:** `"'execution_strategy' must be one of ['mlflow_model', 'prompt_template', 'hybrid'], got 'invalid_strategy'"`

**Missing mlflow_model for mlflow_model strategy:**

```json
{
  "execution_strategy": "mlflow_model",
  "params": {
    "temperature": 0.7
  }
}
```

**Error:** `"'mlflow_model' is required when execution_strategy is 'mlflow_model'"`

**Invalid UUID format:**

```json
{
  "execution_strategy": "mlflow_model",
  "mlflow_model": {
    "policy_version_id": "invalid-uuid"
  }
}
```

**Error:** `"'mlflow_model.policy_version_id' must be a valid UUID, got 'invalid-uuid'"`

**Missing prompt_config for prompt_template strategy:**

```json
{
  "execution_strategy": "prompt_template",
  "params": {
    "temperature": 0.7
  }
}
```

**Error:** `"'prompt_config' is required when execution_strategy is 'prompt_template'"`

**Missing required prompt_config fields:**

```json
{
  "execution_strategy": "prompt_template",
  "prompt_config": {
    "prompt_version_id": "660e8400-e29b-41d4-a716-446655440001"
  }
}
```

**Errors:**
- `"'prompt_config.model_provider' is required"`
- `"'prompt_config.model_name' is required"`

**Invalid params type:**

```json
{
  "execution_strategy": "mlflow_model",
  "mlflow_model": {
    "policy_version_id": "550e8400-e29b-41d4-a716-446655440000"
  },
  "params": "not-an-object"
}
```

**Error:** `"'params' must be an object"`

---

## 5. Error Response Format

**Validation Error Response:**

```json
{
  "is_valid": false,
  "errors": [
    "'mlflow_model.policy_version_id' is required",
    "'prompt_config.model_provider' must be a string, got number"
  ],
  "normalized_config": null
}
```

**Success Response:**

```json
{
  "is_valid": true,
  "errors": [],
  "normalized_config": {
    "execution_strategy": "mlflow_model",
    "mlflow_model": {
      "policy_version_id": "550e8400-e29b-41d4-a716-446655440000"
    },
    "params": {}
  }
}
```

---

## 6. Usage Contexts

### 6.1 Assignment Service

**When:** Config is validated when variant is selected and returned to caller.

**Behavior:**
- Invalid configs result in assignment error response
- Service continues to function for other valid assignments
- Errors are logged for monitoring

### 6.2 Experiment Creation Service

**When:** Config is validated when variants are created or updated.

**Behavior:**
- Invalid configs prevent variant creation/update
- Clear error messages guide user to fix config
- Validation happens before database write

### 6.3 Migration Scripts

**When:** Configs are validated during data migration.

**Behavior:**
- Invalid configs are flagged for manual review
- Migration continues for valid configs
- Report generated with validation results

---

## 7. Related Documentation

| Document | Purpose |
|----------|---------|
| [API_SPEC.md](API_SPEC.md) | API specification with config examples |
| [DESIGN.md](DESIGN.md) | Service design including config parsing |
| [../../docs/data-model.md](../../docs/data-model.md) | Database schema and config structure |

---

## 8. Implementation Notes

**TODO:**
- [ ] Implement validator in chosen language (Python/TypeScript/Go)
- [ ] Add unit tests for all validation rules
- [ ] Add integration tests with Assignment Service
- [ ] Add performance benchmarks
- [ ] Create validation library for reuse across services

---

## After Completing This Document

You will understand:
- What configurations are valid
- What error messages are returned for invalid configs
- How backward compatibility is maintained
- How to implement the validator

**Next Step:** Implement validator based on this specification
