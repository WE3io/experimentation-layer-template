# Migration Guide

**Purpose**  
This guide explains how to migrate existing ML projects to the unified abstraction and how to start new conversational AI projects.

---

## Start Here If…

- **Migrating an existing ML project** → Read section 1 (Migration Path)
- **Starting a new conversational AI project** → Read section 2 (Starting New Projects)
- **Understanding backward compatibility** → Read section 3 (Backward Compatibility)
- **Troubleshooting migration issues** → Read section 4 (Troubleshooting)

---

## 1. Migration Path for Existing ML Projects

### 1.1 Overview

Existing ML projects using the current repository structure will continue to work **without any changes** due to backward compatibility. However, migrating to the unified abstraction provides:

- **Consistency**: Same config structure for all project types
- **Future-proofing**: Ready for new features and capabilities
- **Clarity**: Explicit execution strategy makes intent clear

### 1.2 Migration Steps

**Step 1: Understand the Unified Config Structure**

The unified config supports multiple execution strategies:

```yaml
config:
  execution_strategy: "mlflow_model" | "prompt_template" | "hybrid"
  mlflow_model:          # Required if execution_strategy includes "mlflow_model"
    policy_version_id: "uuid"
    model_name: "optional"
  prompt_config:          # Required if execution_strategy includes "prompt_template"
    prompt_version_id: "uuid"
    model_provider: "anthropic"
    model_name: "claude-sonnet-4.5"
  flow_config:           # Optional, for conversational AI flows
    flow_id: "onboarding_v1"
    initial_state: "welcome"
  params:                # Runtime parameters
    temperature: 0.7
    max_tokens: 2048
```

**Step 2: Transform Your Config**

For ML projects, transform from legacy format to unified format:

**Before (Legacy Format - Still Supported):**

```yaml
variants:
  - name: control
    allocation: 0.5
    config:
      policy_version_id: "550e8400-e29b-41d4-a716-446655440000"
      params:
        temperature: 0.7
        max_tokens: 2048
```

**After (Unified Format - Recommended):**

```yaml
variants:
  - name: control
    allocation: 0.5
    config:
      execution_strategy: "mlflow_model"
      mlflow_model:
        policy_version_id: "550e8400-e29b-41d4-a716-446655440000"
        model_name: "planner_model"  # Optional, for clarity
      params:
        temperature: 0.7
        max_tokens: 2048
```

**Step 3: Update Your Config Files**

1. **Backup your current config:**
   ```bash
   cp config/experiments.yml config/experiments.yml.backup
   ```

2. **Update each variant config:**
   - Add `execution_strategy: "mlflow_model"`
   - Move `policy_version_id` into `mlflow_model` object
   - Keep `params` at root level (unchanged)

3. **Test the migration:**
   ```bash
   # Validate config syntax
   python scripts/validate_config.py config/experiments.yml
   
   # Test assignment service still works
   curl -X POST http://localhost:8000/api/v1/assignments \
     -H "Content-Type: application/json" \
     -d '{"unit_id": "test_user", "requested_experiments": ["your_experiment"]}'
   ```

**Step 4: Deploy Gradually**

1. **Deploy config changes** to staging environment
2. **Verify assignments work** as expected
3. **Monitor for errors** in assignment service logs
4. **Deploy to production** once validated

### 1.3 Complete Example: Before and After

**Before (Legacy Format):**

```yaml
experiments:
  - name: planner_policy_exp
    description: "Test new planner model"
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
            exploration_rate: 0.2
```

**After (Unified Format):**

```yaml
experiments:
  - name: planner_policy_exp
    description: "Test new planner model"
    unit_type: user
    status: active
    
    variants:
      - name: control
        allocation: 0.5
        config:
          execution_strategy: "mlflow_model"
          mlflow_model:
            policy_version_id: "550e8400-e29b-41d4-a716-446655440000"
            model_name: "planner_model"
          params:
            temperature: 0.7
      
      - name: candidate
        allocation: 0.5
        config:
          execution_strategy: "mlflow_model"
          mlflow_model:
            policy_version_id: "660e8400-e29b-41d4-a716-446655440001"
            model_name: "planner_model"
          params:
            temperature: 0.8
            exploration_rate: 0.2
```

### 1.4 Migration Checklist

- [ ] Backup existing config files
- [ ] Understand unified config structure
- [ ] Transform one experiment config as test
- [ ] Validate config syntax
- [ ] Test assignment service with new config
- [ ] Update all experiment configs
- [ ] Deploy to staging
- [ ] Verify assignments work correctly
- [ ] Monitor for errors
- [ ] Deploy to production

---

## 2. Starting New Conversational AI Projects

### 2.1 Quick Start

1. **Follow the conversational AI route:**
   - See [conversational-ai-route.md](routes/conversational-ai-route.md) for step-by-step guide

2. **Copy example configs:**
   ```bash
   cp config/prompts.example.yml config/prompts.yml
   cp config/flows.example.yml config/flows.yml  # When available
   ```

3. **Create prompt files:**
   - Add prompts to `/prompts/` directory
   - Follow naming convention: `{name}_v{version}.txt`
   - See [prompts/README.md](../prompts/README.md) for details

4. **Configure experiments:**
   - Use `execution_strategy: "prompt_template"` in variant configs
   - Reference prompt versions via `prompt_version_id`

### 2.2 Example: Conversational AI Experiment Config

```yaml
experiments:
  - name: meal_planning_assistant_exp
    description: "Test different prompt versions for meal planning"
    unit_type: user
    status: active
    
    variants:
      - name: control
        allocation: 0.5
        config:
          execution_strategy: "prompt_template"
          prompt_config:
            prompt_version_id: "770e8400-e29b-41d4-a716-446655440002"
            model_provider: "anthropic"
            model_name: "claude-sonnet-4.5"
          params:
            temperature: 0.7
            max_tokens: 2048
      
      - name: improved_prompt
        allocation: 0.5
        config:
          execution_strategy: "prompt_template"
          prompt_config:
            prompt_version_id: "880e8400-e29b-41d4-a716-446655440003"
            model_provider: "anthropic"
            model_name: "claude-sonnet-4.5"
          params:
            temperature: 0.7
            max_tokens: 2048
```

### 2.3 Key Differences from ML Projects

| Aspect | ML Projects | Conversational AI Projects |
|--------|-------------|---------------------------|
| **Execution Strategy** | `mlflow_model` | `prompt_template` |
| **Registry** | MLflow Model Registry | Prompt Registry (PostgreSQL + Git) |
| **Artifacts** | Trained model weights | Prompt templates (text files) |
| **Config Reference** | `policy_version_id` | `prompt_version_id` |
| **Model Info** | In MLflow | In `prompt_config` (provider + name) |

---

## 3. Backward Compatibility Guarantees

### 3.1 What's Guaranteed

The platform maintains **full backward compatibility** with existing ML projects:

1. **Legacy Config Format Still Works:**
   - Configs with `policy_version_id` at root level continue to work
   - No breaking changes to assignment service API
   - Existing experiments continue running without modification

2. **Assignment Service Behavior:**
   - Automatically detects legacy format
   - Normalizes to unified format internally
   - Returns consistent response structure

3. **Database Schema:**
   - No schema changes required for existing tables
   - `exp.variants.config` (JSONB) supports both formats
   - Existing data remains valid

### 3.2 What Changed

1. **New Config Format Available:**
   - Unified format with `execution_strategy` is now supported
   - Recommended for new projects and migrations

2. **New Tables Added:**
   - `exp.prompts` and `exp.prompt_versions` (for conversational AI)
   - Existing ML projects don't use these tables

3. **New Services:**
   - Prompt Service (for conversational AI)
   - Flow Orchestrator (for conversational AI)
   - Existing ML projects don't use these services

### 3.3 Migration Timeline

**No Deadline:** You can migrate at your own pace. Legacy format will continue to be supported indefinitely.

**Recommended Timeline:**
- **Week 1-2:** Understand unified config structure
- **Week 3-4:** Migrate one experiment as proof of concept
- **Week 5-8:** Migrate remaining experiments gradually
- **Ongoing:** Use unified format for all new experiments

---

## 4. Troubleshooting

### 4.1 Common Issues

**Issue: Assignment service returns error after migration**

**Symptoms:**
- HTTP 500 errors
- "Invalid config" errors in logs

**Solution:**
1. Check config syntax (YAML indentation)
2. Verify `execution_strategy` value is correct (`"mlflow_model"`)
3. Ensure `policy_version_id` is inside `mlflow_model` object
4. Check that `policy_version_id` is a valid UUID

**Issue: Config validation fails**

**Symptoms:**
- Config validator reports errors
- Assignment service rejects config

**Solution:**
1. Run config validator: `python scripts/validate_config.py config/experiments.yml`
2. Check error messages for specific field issues
3. Compare with `config/experiments.example.yml` for correct structure
4. Ensure all required fields are present

**Issue: Assignments work but config looks wrong**

**Symptoms:**
- Assignments succeed
- But config structure seems incorrect in responses

**Solution:**
1. Check if Assignment Service is normalizing legacy format
2. Verify response format matches API spec
3. Check service version (should support unified config)

**Issue: Can't find policy_version_id after migration**

**Symptoms:**
- Config doesn't have `policy_version_id` at root
- Code expects root-level `policy_version_id`

**Solution:**
1. Update code to read from `config.mlflow_model.policy_version_id`
2. Or use Assignment Service API which normalizes format
3. Check if you're using legacy format detection logic

### 4.2 Validation Commands

**Validate Config Syntax:**
```bash
python scripts/validate_config.py config/experiments.yml
```

**Test Assignment Service:**
```bash
curl -X POST http://localhost:8000/api/v1/assignments \
  -H "Content-Type: application/json" \
  -d '{
    "unit_id": "test_user_123",
    "requested_experiments": ["your_experiment_name"]
  }'
```

**Check Database Config Format:**
```sql
-- Check variant configs in database
SELECT 
    id,
    name,
    config->>'execution_strategy' as execution_strategy,
    config->'mlflow_model'->>'policy_version_id' as policy_version_id,
    config->>'policy_version_id' as legacy_policy_version_id
FROM exp.variants
WHERE experiment_id = 'your-experiment-id';
```

### 4.3 Getting Help

If you encounter issues not covered here:

1. **Check Documentation:**
   - [experiments.md](experiments.md) - Experiment concepts
   - [assignment-service.md](assignment-service.md) - Assignment service details
   - [data-model.md](data-model.md) - Database schema

2. **Review Examples:**
   - `config/experiments.example.yml` - Example configs
   - `config/prompts.example.yml` - Prompt config examples

3. **Check Logs:**
   - Assignment Service logs for config parsing errors
   - Database logs for query issues

4. **Contact Support:**
   - Open an issue in the repository
   - Contact the platform team

---

## 5. Migration Examples

### 5.1 Simple Migration

**Before:**
```yaml
config:
  policy_version_id: "uuid-123"
  params: {}
```

**After:**
```yaml
config:
  execution_strategy: "mlflow_model"
  mlflow_model:
    policy_version_id: "uuid-123"
  params: {}
```

### 5.2 Migration with Params

**Before:**
```yaml
config:
  policy_version_id: "uuid-123"
  params:
    temperature: 0.7
    max_tokens: 2048
```

**After:**
```yaml
config:
  execution_strategy: "mlflow_model"
  mlflow_model:
    policy_version_id: "uuid-123"
  params:
    temperature: 0.7
    max_tokens: 2048
```

### 5.3 Migration with Model Name

**Before:**
```yaml
config:
  policy_version_id: "uuid-123"
  model_name: "planner_model"
  params: {}
```

**After:**
```yaml
config:
  execution_strategy: "mlflow_model"
  mlflow_model:
    policy_version_id: "uuid-123"
    model_name: "planner_model"
  params: {}
```

---

## 6. Best Practices

### 6.1 Migration Strategy

1. **Start Small:** Migrate one experiment first
2. **Test Thoroughly:** Validate in staging before production
3. **Monitor Closely:** Watch for errors after migration
4. **Document Changes:** Update team documentation
5. **Train Team:** Ensure team understands new format

### 6.2 Config Management

1. **Use Version Control:** Commit config changes to Git
2. **Review Changes:** Use pull requests for config updates
3. **Backup Before Changes:** Always backup before migration
4. **Validate Before Deploy:** Run validation scripts
5. **Document Decisions:** Note why configs are structured certain ways

### 6.3 Testing

1. **Unit Tests:** Test config parsing logic
2. **Integration Tests:** Test assignment service with new configs
3. **End-to-End Tests:** Test full experiment flow
4. **Load Tests:** Ensure performance is maintained

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [experiments.md](experiments.md) | Experiment concepts and lifecycle |
| [assignment-service.md](assignment-service.md) | Assignment service details |
| [data-model.md](data-model.md) | Database schema |
| [conversational-ai-route.md](routes/conversational-ai-route.md) | Starting conversational AI projects |
| [prompts-guide.md](prompts-guide.md) | Prompt management guide |

---

## Summary

- **Existing ML projects:** Continue working without changes (backward compatible)
- **Migration:** Optional but recommended for consistency and future-proofing
- **New projects:** Use unified format from the start
- **Support:** Legacy format supported indefinitely
- **Timeline:** Migrate at your own pace

**Key Takeaway:** The unified abstraction provides a consistent foundation for both ML and conversational AI projects while maintaining full backward compatibility with existing ML projects.
