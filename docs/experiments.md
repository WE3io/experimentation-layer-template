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

### 4.1 Config Structure

Each variant has a `config` JSON field:

```json
{
  "policy_version_id": "uuid-policy-version",
  "params": {
    "exploration_rate": 0.15,
    "temperature": 0.7,
    "max_tokens": 2048
  }
}
```

### 4.2 Key Config Fields

| Field | Purpose |
|-------|---------|
| `policy_version_id` | Links to `exp.policy_versions` |
| `params` | Runtime parameters for the policy/model |

### 4.3 How Config is Used

1. EAS returns variant config to backend
2. Backend extracts `policy_version_id`
3. Backend looks up MLflow model from policy version
4. Backend loads model and applies `params`

---

## 5. Creating Experiments

### 5.1 Configuration File

See [../config/experiments.example.yml](../config/experiments.example.yml):

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

## 6. Common Patterns

### 6.1 A/B Test

Two variants, equal split:

```yaml
variants:
  - name: control
    allocation: 0.5
  - name: treatment
    allocation: 0.5
```

### 6.2 Gradual Rollout

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

### 6.3 Multi-Variant Test

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

## 7. Common Pitfalls

### 7.1 Experiment Drift
**Problem**: Modifying variants after experiment starts  
**Solution**: Create new experiment instead

### 7.2 Unequal Allocations
**Problem**: Allocations don't sum to 1.0  
**Solution**: Validate allocations before activation

### 7.3 Premature Traffic
**Problem**: Starting with too much traffic on new variant  
**Solution**: Always start ≤10%

### 7.4 Missing Event Context
**Problem**: Events without experiment/variant IDs  
**Solution**: Always include experiment context in events

---

## 8. Further Exploration

- **How assignments work in detail** → [assignment-service.md](assignment-service.md)
- **API specification** → [../services/assignment-service/API_SPEC.md](../services/assignment-service/API_SPEC.md)
- **How events are logged** → [event-ingestion-service.md](event-ingestion-service.md)

---

## After Completing This Document

You will understand:
- Experiment and variant concepts
- The experiment lifecycle
- How assignment logic works
- How to configure experiments
- Common patterns and pitfalls

**Next Step**: [assignment-service.md](assignment-service.md)

