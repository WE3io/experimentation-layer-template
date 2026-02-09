# Assignment Service Testing Strategy

**Purpose**  
This document defines the testing strategy for verifying backward compatibility of the Assignment Service throughout the repository evolution. It ensures that existing ML projects continue to work after changes.

---

## Start Here If…

- **Testing backward compatibility** → Read section 1 (Test Cases)
- **Verifying legacy config format** → Read section 2 (Legacy Format Testing)
- **Setting up regression tests** → Read section 3 (Regression Testing)
- **Understanding test data** → Read section 4 (Test Data Examples)

---

## 1. Test Cases for Existing ML Project Configs

### 1.1 Test Categories

| Category | Description | Priority |
|----------|-------------|----------|
| **Legacy Config Format** | Verify old `policy_version_id` format still works | Critical |
| **Unified Config Format** | Verify new unified format works correctly | High |
| **Config Normalization** | Verify legacy configs are normalized correctly | High |
| **Assignment Consistency** | Verify same unit gets same variant regardless of format | Critical |
| **API Response Format** | Verify API responses are consistent | Medium |
| **Error Handling** | Verify errors are handled gracefully | Medium |

### 1.2 Core Test Cases

#### Test Case 1: Legacy Config Assignment

**Objective:** Verify that variants with legacy `policy_version_id` format at root level continue to work.

**Test Steps:**
1. Create experiment with variant using legacy config format:
   ```json
   {
     "policy_version_id": "550e8400-e29b-41d4-a716-446655440000",
     "params": {"temperature": 0.7}
   }
   ```
2. Request assignment for a unit
3. Verify assignment succeeds
4. Verify variant is assigned correctly
5. Verify config is returned in response

**Expected Result:**
- Assignment succeeds
- Correct variant is assigned
- Config is normalized to unified format in response (or returned as-is, depending on design)

**Acceptance Criteria:**
- HTTP 200 response
- Assignment stored in database
- Variant ID matches expected variant

#### Test Case 2: Unified Config Assignment

**Objective:** Verify that variants with unified config format work correctly.

**Test Steps:**
1. Create experiment with variant using unified config format:
   ```json
   {
     "execution_strategy": "mlflow_model",
     "mlflow_model": {
       "policy_version_id": "550e8400-e29b-41d4-a716-446655440000"
     },
     "params": {"temperature": 0.7}
   }
   ```
2. Request assignment for a unit
3. Verify assignment succeeds
4. Verify variant is assigned correctly

**Expected Result:**
- Assignment succeeds
- Correct variant is assigned
- Config is returned correctly

**Acceptance Criteria:**
- HTTP 200 response
- Assignment stored in database
- Variant ID matches expected variant

#### Test Case 3: Mixed Format Experiment

**Objective:** Verify that experiments can have both legacy and unified format variants.

**Test Steps:**
1. Create experiment with:
   - Variant A: Legacy format
   - Variant B: Unified format
2. Request assignments for multiple units
3. Verify both variants can be assigned
4. Verify assignments are deterministic

**Expected Result:**
- Both variants can be assigned
- Same unit always gets same variant
- No errors occur

**Acceptance Criteria:**
- All assignments succeed
- Deterministic assignment maintained
- No format-related errors

#### Test Case 4: Config Normalization

**Objective:** Verify that legacy configs are normalized correctly.

**Test Steps:**
1. Create variant with legacy config
2. Request assignment
3. Inspect response config structure
4. Verify config is normalized (if design requires normalization)

**Expected Result:**
- Config is normalized to unified format (if design requires)
- Or config is returned as-is (if design preserves format)
- Normalization is consistent

**Acceptance Criteria:**
- Config structure matches expected format
- All required fields present
- No data loss during normalization

---

## 2. Verification Approach for Legacy `policy_version_id` Format

### 2.1 Format Detection Tests

**Test:** Verify legacy format is detected correctly

```pseudo
function test_legacy_format_detection():
    """
    Test that legacy format (policy_version_id at root) is detected.
    """
    legacy_config = {
        "policy_version_id": "550e8400-e29b-41d4-a716-446655440000",
        "params": {"temperature": 0.7}
    }
    
    assert is_legacy_format(legacy_config) == True
    
    unified_config = {
        "execution_strategy": "mlflow_model",
        "mlflow_model": {"policy_version_id": "..."}
    }
    
    assert is_legacy_format(unified_config) == False
```

### 2.2 Legacy Format Assignment Tests

**Test:** Verify legacy format configs work end-to-end

```pseudo
function test_legacy_format_assignment():
    """
    Test assignment with legacy format config.
    """
    # Setup: Create experiment with legacy format variant
    experiment = create_experiment({
        "name": "legacy_format_test",
        "variants": [{
            "name": "control",
            "allocation": 1.0,
            "config": {
                "policy_version_id": "550e8400-e29b-41d4-a716-446655440000",
                "params": {"temperature": 0.7}
            }
        }]
    })
    
    # Test: Request assignment
    response = assignment_service.get_assignment(
        unit_id="test_user_123",
        requested_experiments=["legacy_format_test"]
    )
    
    # Verify: Assignment succeeds
    assert response.status_code == 200
    assert response.assignments[0].variant_name == "control"
    assert response.assignments[0].config is not None
```

### 2.3 Legacy Format Parsing Tests

**Test:** Verify legacy format is parsed correctly

```pseudo
function test_legacy_format_parsing():
    """
    Test parsing of legacy format configs.
    """
    legacy_config = {
        "policy_version_id": "550e8400-e29b-41d4-a716-446655440000",
        "params": {"temperature": 0.7}
    }
    
    parsed = parse_config(legacy_config)
    
    # Verify parsing results
    assert parsed.execution_strategy == "mlflow_model"
    assert parsed.mlflow_model.policy_version_id == "550e8400-e29b-41d4-a716-446655440000"
    assert parsed.params.temperature == 0.7
```

### 2.4 Legacy Format Validation Tests

**Test:** Verify legacy format validation

```pseudo
function test_legacy_format_validation():
    """
    Test validation of legacy format configs.
    """
    # Valid legacy config
    valid_config = {
        "policy_version_id": "550e8400-e29b-41d4-a716-446655440000",
        "params": {}
    }
    assert validate_config(valid_config) == True
    
    # Invalid: missing policy_version_id
    invalid_config = {
        "params": {}
    }
    assert validate_config(invalid_config) == False
    
    # Invalid: invalid UUID format
    invalid_uuid_config = {
        "policy_version_id": "not-a-uuid",
        "params": {}
    }
    assert validate_config(invalid_uuid_config) == False
```

---

## 3. Assignment Service Backward Compatibility Tests

### 3.1 API Compatibility Tests

**Test:** Verify API endpoints remain compatible

```pseudo
function test_api_backward_compatibility():
    """
    Test that API endpoints maintain backward compatibility.
    """
    # Test: Legacy request format still works
    legacy_request = {
        "unit_id": "test_user_123",
        "requested_experiments": ["test_experiment"]
    }
    
    response = assignment_service.post("/api/v1/assignments", legacy_request)
    assert response.status_code == 200
    
    # Test: Response format hasn't changed
    assert "assignments" in response.json()
    assert isinstance(response.json()["assignments"], list)
```

### 3.2 Response Format Tests

**Test:** Verify response format consistency

```pseudo
function test_response_format_consistency():
    """
    Test that responses are consistent regardless of config format.
    """
    # Create variants with different config formats
    experiment = create_experiment({
        "variants": [
            {"name": "legacy", "config": {"policy_version_id": "..."}},
            {"name": "unified", "config": {"execution_strategy": "mlflow_model", ...}}
        ]
    })
    
    # Get assignments for both
    legacy_assignment = get_assignment("user1", ["test"])
    unified_assignment = get_assignment("user2", ["test"])
    
    # Verify response structures match
    assert legacy_assignment.keys() == unified_assignment.keys()
    assert "variant_id" in legacy_assignment
    assert "variant_name" in legacy_assignment
    assert "config" in legacy_assignment
```

### 3.3 Deterministic Assignment Tests

**Test:** Verify assignments are deterministic regardless of config format

```pseudo
function test_deterministic_assignment():
    """
    Test that same unit gets same variant regardless of config format.
    """
    # Create experiment with legacy format variant
    experiment_legacy = create_experiment({
        "variants": [{"name": "control", "config": {"policy_version_id": "..."}}]
    })
    
    # Create experiment with unified format variant (same allocation)
    experiment_unified = create_experiment({
        "variants": [{"name": "control", "config": {"execution_strategy": "mlflow_model", ...}}]
    })
    
    # Test: Same unit should get same variant (if allocations match)
    unit_id = "test_user_123"
    
    assignment1 = get_assignment(unit_id, [experiment_legacy.name])
    assignment2 = get_assignment(unit_id, [experiment_unified.name])
    
    # Note: Variants may differ if experiments differ, but assignment should be deterministic
    assert assignment1.variant_id is not None
    assert assignment2.variant_id is not None
```

### 3.4 Error Handling Tests

**Test:** Verify error handling for invalid configs

```pseudo
function test_error_handling():
    """
    Test error handling for various invalid config scenarios.
    """
    # Test: Invalid legacy config (missing policy_version_id)
    invalid_variant = {
        "name": "invalid",
        "config": {"params": {}}  # Missing policy_version_id
    }
    
    # Should either:
    # 1. Reject at experiment creation time, OR
    # 2. Handle gracefully at assignment time
    
    # Test: Invalid unified config (missing execution_strategy)
    invalid_unified = {
        "name": "invalid",
        "config": {"mlflow_model": {"policy_version_id": "..."}}
    }
    
    # Should reject or handle gracefully
```

---

## 4. Regression Testing Requirements

### 4.1 Pre-Deployment Regression Tests

**Required Tests Before Any Deployment:**

1. **Legacy Config Assignment Test**
   - Create experiment with legacy format
   - Request assignments for 100 units
   - Verify 100% success rate
   - Verify assignments are deterministic

2. **Unified Config Assignment Test**
   - Create experiment with unified format
   - Request assignments for 100 units
   - Verify 100% success rate
   - Verify assignments are deterministic

3. **Mixed Format Test**
   - Create experiment with both formats
   - Request assignments for 100 units
   - Verify both variants can be assigned
   - Verify no format-related errors

4. **Config Normalization Test**
   - Create variant with legacy format
   - Request assignment
   - Verify config is normalized correctly
   - Verify no data loss

5. **API Response Format Test**
   - Request assignments with legacy configs
   - Request assignments with unified configs
   - Verify response structures match
   - Verify all required fields present

### 4.2 Continuous Regression Tests

**Tests to Run on Every Commit:**

1. **Unit Tests:**
   - Config parsing tests
   - Format detection tests
   - Normalization tests
   - Validation tests

2. **Integration Tests:**
   - Assignment service API tests
   - Database interaction tests
   - Cache interaction tests

3. **End-to-End Tests:**
   - Full assignment flow with legacy configs
   - Full assignment flow with unified configs

### 4.3 Performance Regression Tests

**Tests to Ensure Performance Maintained:**

1. **Latency Tests:**
   - Legacy config assignment latency
   - Unified config assignment latency
   - Verify no performance degradation

2. **Throughput Tests:**
   - Requests per second with legacy configs
   - Requests per second with unified configs
   - Verify throughput maintained

### 4.4 Test Execution Schedule

| Test Type | Frequency | Trigger |
|-----------|----------|---------|
| Unit Tests | Every commit | CI/CD pipeline |
| Integration Tests | Every commit | CI/CD pipeline |
| End-to-End Tests | Before merge | Pull request |
| Performance Tests | Weekly | Scheduled job |
| Full Regression Suite | Before release | Release process |

---

## 5. Test Data Examples

### 5.1 Legacy Config Test Data

**Example 1: Simple Legacy Config**

```json
{
  "policy_version_id": "550e8400-e29b-41d4-a716-446655440000",
  "params": {
    "temperature": 0.7
  }
}
```

**Example 2: Legacy Config with Multiple Params**

```json
{
  "policy_version_id": "550e8400-e29b-41d4-a716-446655440000",
  "params": {
    "temperature": 0.7,
    "max_tokens": 2048,
    "top_p": 0.95
  }
}
```

**Example 3: Legacy Config with Model Name**

```json
{
  "policy_version_id": "550e8400-e29b-41d4-a716-446655440000",
  "model_name": "planner_model",
  "params": {
    "temperature": 0.7
  }
}
```

### 5.2 Unified Config Test Data

**Example 1: Simple Unified Config**

```json
{
  "execution_strategy": "mlflow_model",
  "mlflow_model": {
    "policy_version_id": "550e8400-e29b-41d4-a716-446655440000"
  },
  "params": {
    "temperature": 0.7
  }
}
```

**Example 2: Unified Config with Model Name**

```json
{
  "execution_strategy": "mlflow_model",
  "mlflow_model": {
    "policy_version_id": "550e8400-e29b-41d4-a716-446655440000",
    "model_name": "planner_model"
  },
  "params": {
    "temperature": 0.7,
    "max_tokens": 2048
  }
}
```

### 5.3 Invalid Config Test Data

**Example 1: Missing policy_version_id (Legacy)**

```json
{
  "params": {
    "temperature": 0.7
  }
}
```

**Example 2: Invalid UUID Format**

```json
{
  "policy_version_id": "not-a-valid-uuid",
  "params": {}
}
```

**Example 3: Missing execution_strategy (Unified)**

```json
{
  "mlflow_model": {
    "policy_version_id": "550e8400-e29b-41d4-a716-446655440000"
  },
  "params": {}
}
```

**Example 4: Invalid execution_strategy Value**

```json
{
  "execution_strategy": "invalid_strategy",
  "mlflow_model": {
    "policy_version_id": "550e8400-e29b-41d4-a716-446655440000"
  },
  "params": {}
}
```

### 5.4 Experiment Test Data

**Example: Experiment with Legacy Format Variants**

```yaml
experiments:
  - name: legacy_format_test
    description: "Test experiment with legacy format variants"
    unit_type: user
    status: active
    
    variants:
      - name: control
        allocation: 0.5
        config:
          policy_version_id: "550e8400-e29b-41d4-a716-446655440000"
          params:
            temperature: 0.7
      
      - name: candidate
        allocation: 0.5
        config:
          policy_version_id: "660e8400-e29b-41d4-a716-446655440001"
          params:
            temperature: 0.8
```

**Example: Experiment with Mixed Format Variants**

```yaml
experiments:
  - name: mixed_format_test
    description: "Test experiment with both legacy and unified formats"
    unit_type: user
    status: active
    
    variants:
      - name: legacy_variant
        allocation: 0.5
        config:
          policy_version_id: "550e8400-e29b-41d4-a716-446655440000"
          params:
            temperature: 0.7
      
      - name: unified_variant
        allocation: 0.5
        config:
          execution_strategy: "mlflow_model"
          mlflow_model:
            policy_version_id: "660e8400-e29b-41d4-a716-446655440001"
          params:
            temperature: 0.8
```

---

## 6. Test Execution Strategy

### 6.1 Test Environment Setup

**Requirements:**
- Isolated test database
- Test Assignment Service instance
- Test data fixtures
- Mock MLflow registry (if needed)

**Setup Steps:**
1. Create test database schema
2. Load test data fixtures
3. Start Assignment Service in test mode
4. Verify service is healthy

### 6.2 Test Execution Order

1. **Unit Tests** (fastest, run first)
   - Config parsing tests
   - Format detection tests
   - Validation tests

2. **Integration Tests** (medium speed)
   - API endpoint tests
   - Database interaction tests
   - Cache interaction tests

3. **End-to-End Tests** (slowest, run last)
   - Full assignment flow tests
   - Multi-experiment tests
   - Performance tests

### 6.3 Test Verification Checklist

After running tests, verify:

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] All end-to-end tests pass
- [ ] No performance regressions
- [ ] Legacy config format still works
- [ ] Unified config format works
- [ ] Config normalization works correctly
- [ ] API responses are consistent
- [ ] Error handling works correctly
- [ ] Assignments are deterministic

---

## 7. Monitoring and Alerting

### 7.1 Metrics to Monitor

| Metric | Description | Alert Threshold |
|--------|-------------|----------------|
| Legacy config assignment success rate | % of legacy config assignments that succeed | < 99% |
| Unified config assignment success rate | % of unified config assignments that succeed | < 99% |
| Config parsing errors | Number of config parsing failures | > 10/hour |
| Assignment latency (legacy) | P99 latency for legacy config assignments | > 500ms |
| Assignment latency (unified) | P99 latency for unified config assignments | > 500ms |

### 7.2 Alerting Rules

**Critical Alerts:**
- Legacy config assignment failure rate > 1%
- Unified config assignment failure rate > 1%
- Config parsing error rate > 1%

**Warning Alerts:**
- Assignment latency degradation > 20%
- Config normalization errors detected

---

## 8. Test Maintenance

### 8.1 Test Updates Required When

- New config fields added
- Config structure changes
- API response format changes
- Assignment logic changes

### 8.2 Test Review Schedule

- **Weekly:** Review test results and failures
- **Monthly:** Review test coverage and gaps
- **Quarterly:** Review and update test strategy

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [migration-guide.md](../../docs/migration-guide.md) | Migration guide for existing projects |
| [API_SPEC.md](API_SPEC.md) | Assignment Service API specification |
| [DESIGN.md](DESIGN.md) | Assignment Service design |
| [../../docs/experiments.md](../../docs/experiments.md) | Experiment concepts |

---

## Summary

This testing strategy ensures:

- **Backward Compatibility:** Legacy config format continues to work
- **Forward Compatibility:** Unified config format works correctly
- **Consistency:** Same behavior regardless of config format
- **Reliability:** Regression tests catch breaking changes
- **Performance:** No performance degradation

**Key Principle:** Existing ML projects must continue working without modification. All changes must maintain backward compatibility.
