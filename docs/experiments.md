# Experiments

**Purpose**  
This document explains experiment concepts, variant allocation, configuration, and lifecycle management.

---

## Start Here If…

- **Full sequential workflow** → Continue from [data-model.md](data-model.md)
- **Experiment Route** → This is your entry point; proceed to [assignment-service.md](assignment-service.md) next
- **Understanding allocation logic** → Focus on section 3
- **Creating experiments** → Focus on section 5

---

## 1. Core Concepts

### 1.1 What is an Experiment?

An experiment is a controlled test that assigns users (or other units) to different variants to compare behaviour and outcomes.

**Key Properties**:
- **Name**: Unique identifier (e.g., `planner_policy_exp`)
- **Unit Type**: What gets assigned (`user`, `household`, `session`)
- **Status**: Lifecycle state (`draft`, `active`, `paused`, `completed`)
- **Variants**: Different configurations being tested

### 1.2 What is a Variant?

A variant is a specific configuration within an experiment.

**Key Properties**:
- **Name**: Identifier within experiment (e.g., `control`, `candidate_v2`)
- **Allocation**: Percentage of traffic (0.0 to 1.0)
- **Config**: JSON object containing variant-specific settings

### 1.3 What is an Assignment?

An assignment is a deterministic mapping of a unit to a variant.

**Key Properties**:
- **Deterministic**: Same unit always gets same variant
- **Persistent**: Stored in database
- **Immutable**: Once assigned, never changes

---

## 2. Experiment Lifecycle

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌───────────┐
│  Draft  │ ──► │ Active  │ ──► │ Paused  │ ──► │ Completed │
└─────────┘     └─────────┘     └─────────┘     └───────────┘
     │               │               │
     │               ▼               │
     │          Assignments          │
     │          Created              │
     └───────────────────────────────┘
```

### 2.1 Draft
- Experiment being configured
- No assignments made
- Variants can be modified

### 2.2 Active
- Experiment running
- Assignments being made
- Variants should NOT be modified
- Events being collected

### 2.3 Paused
- Experiment temporarily stopped
- Existing assignments preserved
- No new assignments made

### 2.4 Completed
- Experiment finished
- Analysis complete
- Historical record preserved

---

## 3. Assignment Logic

The system uses deterministic hashing to assign units to variants.

### 3.1 Algorithm (Pseudo-code)

```pseudo
function assign_variant(experiment_id, unit_id, variants):
    
    # 1. Check for existing assignment
    existing = lookup_assignment(experiment_id, unit_id)
    if existing:
        return existing.variant
    
    # 2. Compute deterministic hash
    hash_input = experiment_id + ":" + unit_id
    unit_hash = hash(hash_input)
    bucket = unit_hash mod 10000
    
    # 3. Find variant based on allocation
    cumulative = 0
    for variant in variants:
        cumulative += variant.allocation * 10000
        if bucket < cumulative:
            # 4. Persist assignment
            save_assignment(experiment_id, unit_id, variant.id)
            return variant
    
    # Fallback to last variant
    return variants[-1]
```

### 3.2 Properties

| Property | Guarantee |
|----------|-----------|
| Deterministic | Same input always produces same output |
| Uniform | Even distribution across buckets |
| Persistent | Assignment stored after first computation |
| Stable | Unit never changes variant during experiment |

### 3.3 Example

```
Experiment: planner_policy_exp
Variants:
  - control: 50% (allocation: 0.5)
  - candidate: 50% (allocation: 0.5)

User: user-123
Hash: hash("exp-uuid:user-123") = 12345678
Bucket: 12345678 mod 10000 = 5678

5678 < 5000 (control cumulative)? No
5678 < 10000 (candidate cumulative)? Yes

Result: user-123 → candidate
```

---

## 4. Variant Configuration

The variant `config` field supports a unified abstraction that works for both traditional ML projects and conversational AI projects. The system maintains full backward compatibility with the legacy format.

**Quick Decision:** Not sure which execution strategy to use? See [choosing-project-type.md](choosing-project-type.md) for guidance.

### 4.1 Unified Config Structure

The unified config format uses an `execution_strategy` field to specify how the variant should be executed:

```json
{
  "execution_strategy": "mlflow_model" | "prompt_template" | "hybrid",
  "mlflow_model": {
    "policy_version_id": "uuid-policy-version",
    "model_name": "planner_model"
  },
  "prompt_config": {
    "prompt_version_id": "uuid-prompt-version",
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

### 4.2 Execution Strategies

| Execution Strategy | Use Case | Description |
|-------------------|----------|-------------|
| `mlflow_model` | Traditional ML projects | Trained models from MLflow Model Registry |
| `prompt_template` | Conversational AI projects | Prompt templates with LLM providers |
| `hybrid` | Combined approaches | Both ML models and prompts in same variant |

**Related**: [choosing-project-type.md](choosing-project-type.md) for guidance on selecting the right strategy

### 4.3 ML Model Configuration (`mlflow_model` strategy)

For traditional ML projects using trained models:

```json
{
  "execution_strategy": "mlflow_model",
  "mlflow_model": {
    "policy_version_id": "550e8400-e29b-41d4-a716-446655440000",
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
- `execution_strategy`: Must be `"mlflow_model"`
- `mlflow_model.policy_version_id`: Reference to `exp.policy_versions.id` (required)
- `mlflow_model.model_name`: MLflow model name for reference (optional)
- `params`: Runtime parameters for the model (optional)

**How it works:**
1. EAS returns variant config to backend
2. Backend extracts `mlflow_model.policy_version_id`
3. Backend looks up MLflow model from policy version
4. Backend loads model and applies `params`

### 4.4 Prompt Template Configuration (`prompt_template` strategy)

For conversational AI projects using prompts and flows:

```json
{
  "execution_strategy": "prompt_template",
  "prompt_config": {
    "prompt_version_id": "770e8400-e29b-41d4-a716-446655440002",
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

**Fields:**
- `execution_strategy`: Must be `"prompt_template"`
- `prompt_config.prompt_version_id`: Reference to `exp.prompt_versions.id` (required)
- `prompt_config.model_provider`: LLM provider (e.g., `"anthropic"`, `"openai"`) (required)
- `prompt_config.model_name`: Model identifier (e.g., `"claude-sonnet-4.5"`) (required)
- `flow_config.flow_id`: Conversation flow identifier (optional)
- `flow_config.initial_state`: Starting state in flow (optional)
- `params`: Runtime parameters for LLM calls (optional)

**How it works:**
1. EAS returns variant config to backend
2. Backend retrieves prompt version from Prompt Service using `prompt_version_id`
3. If `flow_config` is present, Flow Orchestrator manages conversation state
4. Backend calls LLM API with prompt template and conversation context
5. EIS records conversation events with experiment context

**Related**: [prompts-guide.md](prompts-guide.md), [conversation-flows.md](conversation-flows.md)

### 4.5 Backward Compatibility (Legacy Format)

The system maintains full backward compatibility with the legacy format. Existing ML projects can continue using the old format without changes:

**Legacy Format (still supported):**

```json
{
  "policy_version_id": "uuid-policy-version",
  "params": {
    "exploration_rate": 0.15,
    "temperature": 0.7
  }
}
```

When `execution_strategy` is omitted, the system assumes `"mlflow_model"` and treats `policy_version_id` as the legacy format. The Assignment Service automatically converts legacy configs to the unified format internally.

**Migration Recommendation:**
- New experiments should use the unified format with `execution_strategy`
- Existing experiments can continue using legacy format
- Migrate gradually when updating experiment configs

**Related**: [migration-guide.md](migration-guide.md) for detailed migration steps

---

## 5. Creating Experiments

### 5.1 Configuration File

See [../config/experiments.example.yml](../config/experiments.example.yml) for complete examples.

**ML Experiment Example (Unified Format):**

```yaml
experiments:
  - name: planner_policy_exp
    description: "Test new planner model variant"
    unit_type: user
    status: active
    variants:
      - name: control
        allocation: 0.5
        config:
          execution_strategy: "mlflow_model"
          mlflow_model:
            policy_version_id: "uuid-v1"
            model_name: "planner_model"
          params:
            temperature: 0.7
      - name: leftovers_v2
        allocation: 0.5
        config:
          execution_strategy: "mlflow_model"
          mlflow_model:
            policy_version_id: "uuid-v2"
            model_name: "planner_model"
          params:
            exploration_rate: 0.2
            temperature: 0.7
```

**Conversational AI Experiment Example:**

```yaml
experiments:
  - name: chatbot_assistant_exp
    description: "Test different prompt templates for meal planning assistant"
    unit_type: user
    status: active
    variants:
      - name: control
        allocation: 0.5
        config:
          execution_strategy: "prompt_template"
          prompt_config:
            prompt_version_id: "uuid-prompt-v1"
            model_provider: "anthropic"
            model_name: "claude-sonnet-4.5"
          flow_config:
            flow_id: "onboarding_v1"
            initial_state: "welcome"
          params:
            temperature: 0.7
            max_tokens: 2048
      - name: concise_prompt
        allocation: 0.5
        config:
          execution_strategy: "prompt_template"
          prompt_config:
            prompt_version_id: "uuid-prompt-v2"
            model_provider: "anthropic"
            model_name: "claude-sonnet-4.5"
          flow_config:
            flow_id: "onboarding_v1"
            initial_state: "welcome"
          params:
            temperature: 0.5
            max_tokens: 1024
```

**Legacy Format (Still Supported):**

```yaml
experiments:
  - name: planner_policy_exp
    description: "Test new planner model variant"
    unit_type: user
    status: active
    variants:
      - name: control
        allocation: 0.5
        config:
          policy_version_id: "uuid-v1"
      - name: leftovers_v2
        allocation: 0.5
        config:
          policy_version_id: "uuid-v2"
          params:
            exploration_rate: 0.2
```

### 5.2 Allocation Rules

- Total allocation should equal 1.0 (100%)
- Start new variants with ≤10% allocation
- Increase gradually based on results

### 5.3 Naming Conventions

| Entity | Convention | Example |
|--------|------------|---------|
| Experiment | `{feature}_exp` | `planner_policy_exp` |
| Control variant | `control` | `control` |
| Test variant | `{feature}_{version}` | `leftovers_v2` |

---

## 6. Quick Reference: Config Format

### ML Model Strategy
```yaml
config:
  execution_strategy: "mlflow_model"
  mlflow_model:
    policy_version_id: "uuid"  # Required
    model_name: "string"       # Optional
  params:
    temperature: 0.7
```

### Prompt Template Strategy
```yaml
config:
  execution_strategy: "prompt_template"
  prompt_config:
    prompt_version_id: "uuid"  # Required
    model_provider: "anthropic" # Required
    model_name: "claude-sonnet-4.5" # Required
  flow_config:                 # Optional
    flow_id: "string"
    initial_state: "string"
  params:
    temperature: 0.7
```

### Legacy Format (Still Supported)
```yaml
config:
  policy_version_id: "uuid"  # Auto-converted to mlflow_model strategy
  params: {}
```

---

## 7. Common Patterns

### 7.1 A/B Test

Two variants, equal split:

```yaml
variants:
  - name: control
    allocation: 0.5
  - name: treatment
    allocation: 0.5
```

### 7.2 Gradual Rollout

New feature with increasing allocation:

```yaml
# Week 1
variants:
  - name: control
    allocation: 0.9
  - name: new_feature
    allocation: 0.1

# Week 2 (if successful)
variants:
  - name: control
    allocation: 0.5
  - name: new_feature
    allocation: 0.5
```

### 7.3 Multi-Variant Test

Multiple configurations:

```yaml
variants:
  - name: control
    allocation: 0.4
  - name: variant_a
    allocation: 0.2
  - name: variant_b
    allocation: 0.2
  - name: variant_c
    allocation: 0.2
```

---

## 8. Common Mistakes

### 8.1 Configuration Mistakes

**Mistake: Wrong execution strategy for project type**

- **Problem:** Using `mlflow_model` strategy for conversational AI projects or vice versa
- **Solution:** Choose correct execution strategy based on project type:
  - ML projects → `execution_strategy: "mlflow_model"`
  - Conversational AI → `execution_strategy: "prompt_template"`
- **Why:** Wrong strategy causes runtime errors or incorrect behavior
- **Check:** Review [choosing-project-type.md](choosing-project-type.md) if unsure

**Mistake: Missing required config fields**

- **Problem:** Omitting required fields like `prompt_version_id` or `policy_version_id`
- **Solution:** Always include required fields for chosen execution strategy:
  - ML: `mlflow_model.policy_version_id` required
  - Conversational AI: `prompt_config.prompt_version_id` required
- **Why:** Missing fields cause variant assignment failures

**Mistake: Invalid UUID references**

- **Problem:** Using non-existent UUIDs for `prompt_version_id` or `policy_version_id`
- **Solution:** Always verify UUIDs exist in database before using in config
- **Check:** Query `exp.prompt_versions` or `exp.policy_versions` to verify

**Mistake: Mismatched model provider and model name**

- **Problem:** Using OpenAI model name with Anthropic provider (or vice versa)
- **Solution:** Ensure `model_provider` matches the actual provider of `model_name`
- **Example:**
  - ❌ Wrong: `model_provider: "anthropic"`, `model_name: "gpt-4"`
  - ✅ Correct: `model_provider: "openai"`, `model_name: "gpt-4"`

### 8.2 Allocation Mistakes

**Mistake: Allocations don't sum to 1.0**

- **Problem:** Total allocation is less than or greater than 100%
- **Solution:** Always validate allocations sum to exactly 1.0 before activation
- **Why:** Invalid allocations cause assignment failures or unexpected behavior
- **Check:** Sum all variant allocations: `0.5 + 0.3 + 0.2 = 1.0` ✅

**Mistake: Starting with too much traffic on new variant**

- **Problem:** Allocating >10% to untested variant risks user experience
- **Solution:** Always start new variants with ≤10% allocation, increase gradually
- **Why:** Limits impact if variant has issues
- **Best practice:** Start at 1-5%, increase to 10%, then 25%, 50%, etc.

**Mistake: Unequal allocations when not needed**

- **Problem:** Using 50/50 split when one variant is clearly better
- **Solution:** Use appropriate allocations based on confidence level
- **Why:** Optimizes traffic allocation for better variants

### 8.3 Lifecycle Mistakes

**Mistake: Modifying variants after experiment starts**

- **Problem:** Changing variant config breaks experiment validity
- **Solution:** Create new experiment instead of modifying existing one
- **Why:** Modifications invalidate statistical analysis and break determinism
- **Alternative:** Pause experiment, create new one with updated config

**Mistake: Not setting experiment end dates**

- **Problem:** Experiments run indefinitely, consuming resources
- **Solution:** Set `end_at` date when creating experiments
- **Why:** Prevents forgotten experiments from running forever

**Mistake: Activating experiments without testing**

- **Problem:** Activating experiments with invalid configs causes production issues
- **Solution:** Test experiment configs in draft status first
- **Why:** Prevents assignment failures in production

### 8.4 Event Logging Mistakes

**Mistake: Missing experiment context in events**

- **Problem:** Events without experiment/variant IDs can't be analyzed
- **Solution:** Always include experiment context in events:
  ```json
  {
    "event_type": "user_action",
    "experiment_id": "uuid",
    "variant_id": "uuid",
    ...
  }
  ```
- **Why:** Without context, events can't be attributed to variants

**Mistake: Inconsistent event types**

- **Problem:** Using different event type names for same action
- **Solution:** Standardize event type naming across application
- **Why:** Makes analytics and querying easier

**Mistake: Not logging important events**

- **Problem:** Missing key events makes experiment analysis incomplete
- **Solution:** Log all user actions relevant to experiment goals
- **Why:** Incomplete data leads to incorrect conclusions

---

## 9. Common Pitfalls

### 9.1 Experiment Drift
**Problem**: Modifying variants after experiment starts  
**Solution**: Create new experiment instead

### 9.2 Unequal Allocations
**Problem**: Allocations don't sum to 1.0  
**Solution**: Validate allocations before activation

### 9.3 Premature Traffic
**Problem**: Starting with too much traffic on new variant  
**Solution**: Always start ≤10%

### 9.4 Missing Event Context
**Problem**: Events without experiment/variant IDs  
**Solution**: Always include experiment context in events

---

## 10. Further Exploration

- **Choosing your project type** → [choosing-project-type.md](choosing-project-type.md)
- **How assignments work in detail** → [assignment-service.md](assignment-service.md)
- **API specification** → [../services/assignment-service/API_SPEC.md](../services/assignment-service/API_SPEC.md)
- **How events are logged** → [event-ingestion-service.md](event-ingestion-service.md)
- **Prompt management** → [prompts-guide.md](prompts-guide.md)
- **Conversation flows** → [conversation-flows.md](conversation-flows.md)
- **Example configurations** → [../config/experiments.example.yml](../config/experiments.example.yml)
- **Example projects** → [../examples/README.md](../examples/README.md)
- **Migration guide** → [migration-guide.md](migration-guide.md)

---

## After Completing This Document

You will understand:
- Experiment and variant concepts
- The experiment lifecycle
- How assignment logic works
- How to configure experiments (both ML and conversational AI)
- Unified config format with execution strategies
- Common patterns, mistakes, and pitfalls
- How to avoid common configuration errors

**Next Step**: [assignment-service.md](assignment-service.md)

**See Also:**
- [choosing-project-type.md](choosing-project-type.md) - Help choosing execution strategy
- [prompts-guide.md](prompts-guide.md) - For conversational AI projects
- [conversation-flows.md](conversation-flows.md) - For structured dialogues
- [examples/conversational-assistant/](../examples/conversational-assistant/) - Complete example project
