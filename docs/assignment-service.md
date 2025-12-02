# Assignment Service Overview

**Purpose**  
This document describes the Experiment Assignment Service (EAS), which assigns units to experiment variants.

---

## Start Here If…

- **Full sequential workflow** → Continue from [experiments.md](experiments.md)
- **Experiment Route** → Core document for this route
- **API details** → Go to [../services/assignment-service/API_SPEC.md](../services/assignment-service/API_SPEC.md)
- **Implementation design** → Go to [../services/assignment-service/DESIGN.md](../services/assignment-service/DESIGN.md)

---

## 1. Service Purpose

The Experiment Assignment Service (EAS) is responsible for:

1. **Variant Assignment** – Determining which variant a unit receives
2. **Config Delivery** – Returning variant configuration to callers
3. **Assignment Persistence** – Storing assignments for consistency
4. **Experiment Resolution** – Handling multiple concurrent experiments

---

## 2. Core Responsibilities

### 2.1 Deterministic Assignment

- Given the same `(experiment_id, unit_id)`, always return the same variant
- Uses hash-based bucketing (see [experiments.md](experiments.md) section 3)
- Persists assignment after first computation

### 2.2 Config Resolution

- Looks up variant configuration
- Includes `policy_version_id` and any custom `params`
- Returns complete config for backend to use

### 2.3 Multi-Experiment Support

- Can assign same unit to multiple experiments
- Each experiment has independent assignment
- Returns array of assignments

---

## 3. API Overview

### 3.1 Request Flow

```
Client/Backend
     │
     ▼
┌─────────────────────────────────────┐
│  POST /assignments                   │
│  {                                   │
│    unit_type: "user",                │
│    unit_id: "user-123",              │
│    context: { app_version: "1.2.3" },│
│    requested_experiments: [...]      │
│  }                                   │
└─────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────┐
│  Assignment Logic                    │
│  1. Check existing assignments       │
│  2. Compute new assignments          │
│  3. Persist assignments              │
└─────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────┐
│  Response                            │
│  {                                   │
│    assignments: [                    │
│      { experiment_id, variant_id,    │
│        variant_name, config }        │
│    ]                                 │
│  }                                   │
└─────────────────────────────────────┘
```

### 3.2 Request Schema

```json
{
  "unit_type": "user",
  "unit_id": "user-123",
  "context": {
    "app_version": "1.2.3",
    "platform": "ios"
  },
  "requested_experiments": ["planner_policy_exp"]
}
```

### 3.3 Response Schema

```json
{
  "assignments": [
    {
      "experiment_id": "uuid-exp",
      "variant_id": "uuid-var",
      "variant_name": "variant_a",
      "config": {
        "policy_version_id": "uuid-policy-version",
        "params": {
          "exploration_rate": 0.15
        }
      }
    }
  ]
}
```

---

## 4. Assignment Algorithm

### 4.1 Pseudo-code

```pseudo
function get_assignments(request):
    assignments = []
    
    for exp_name in request.requested_experiments:
        experiment = lookup_experiment(exp_name)
        
        if not experiment or experiment.status != 'active':
            continue
        
        # Check existing assignment
        existing = db.query(
            "SELECT * FROM exp.assignments 
             WHERE experiment_id = ? AND unit_id = ?",
            experiment.id, request.unit_id
        )
        
        if existing:
            variant = lookup_variant(existing.variant_id)
        else:
            # Compute new assignment
            variant = compute_variant(experiment, request.unit_id)
            
            # Persist assignment
            db.insert("exp.assignments", {
                experiment_id: experiment.id,
                unit_type: request.unit_type,
                unit_id: request.unit_id,
                variant_id: variant.id
            })
        
        assignments.append({
            experiment_id: experiment.id,
            variant_id: variant.id,
            variant_name: variant.name,
            config: variant.config
        })
    
    return { assignments: assignments }


function compute_variant(experiment, unit_id):
    hash_input = experiment.id + ":" + unit_id
    bucket = hash(hash_input) mod 10000
    
    variants = get_variants(experiment.id)
    cumulative = 0
    
    for variant in variants:
        cumulative += variant.allocation * 10000
        if bucket < cumulative:
            return variant
    
    return variants[-1]
```

---

## 5. Integration Points

### 5.1 Database Tables

- `exp.experiments` – Experiment definitions
- `exp.variants` – Variant configurations
- `exp.assignments` – Persisted assignments

### 5.2 Calling Services

- **Backend API** – Calls EAS on each request needing experiment context
- **Planner** – Uses variant config to select model version

### 5.3 Event Logging

After assignment, caller should log events with experiment context:
- Include `experiment_id` and `variant_id` in all events
- See [event-ingestion-service.md](event-ingestion-service.md)

---

## 6. Performance Considerations

### 6.1 Caching

```pseudo
# Application-level cache
cache_key = f"assignment:{experiment_id}:{unit_id}"

cached = cache.get(cache_key)
if cached:
    return cached

assignment = compute_assignment(...)
cache.set(cache_key, assignment, ttl=3600)
return assignment
```

### 6.2 Batch Lookups

```pseudo
# For multiple experiments
existing_assignments = db.query(
    "SELECT * FROM exp.assignments 
     WHERE experiment_id IN (?) AND unit_id = ?",
    experiment_ids, unit_id
)

# Map for O(1) lookup
assignment_map = {a.experiment_id: a for a in existing_assignments}
```

---

## 7. Error Handling

### 7.1 Invalid Experiment

```json
{
  "error": "experiment_not_found",
  "message": "Experiment 'unknown_exp' does not exist"
}
```

### 7.2 Inactive Experiment

Silently skip inactive experiments (don't error).

### 7.3 Database Failure

Return 503 Service Unavailable; caller should retry with backoff.

---

## 8. Related Documentation

| Document | Purpose |
|----------|---------|
| [../services/assignment-service/DESIGN.md](../services/assignment-service/DESIGN.md) | Implementation design |
| [../services/assignment-service/API_SPEC.md](../services/assignment-service/API_SPEC.md) | Full API specification |
| [experiments.md](experiments.md) | Experiment concepts |
| [event-ingestion-service.md](event-ingestion-service.md) | Event logging |

---

## After Completing This Document

You will understand:
- The role of the Assignment Service
- How assignments are computed and persisted
- The API request/response shapes
- Integration points with other services

**Next Step**: [event-ingestion-service.md](event-ingestion-service.md)

