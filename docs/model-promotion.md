# Model Promotion

**Purpose**  
This document explains how models move from training through candidate status to production deployment.

---

## Start Here If…

- **Full sequential workflow** → Continue from [offline-evaluation.md](offline-evaluation.md)
- **Model Promotion Route** → This is your entry point
- **Creating policy versions** → Focus on section 2
- **Online experiments** → Focus on section 4

---

## 1. Promotion Lifecycle

### 1.1 Overview

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Trained     │ ──► │ Candidate   │ ──► │ Experiment  │ ──► │ Production  │
│ (None)      │     │             │     │ (≤10%)      │     │ (100%)      │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │                   │
       │                   │                   │                   │
   Registered         Passed Offline      Passed Online       Full Rollout
   in MLflow          Evaluation          Monitoring
```

### 1.2 Stage Transitions

| From | To | Trigger |
|------|-----|---------|
| None | Candidate | Offline evaluation passes |
| Candidate | Experiment | Policy version + variant created |
| Experiment | Production | Online metrics satisfactory |

---

## 2. Creating Policy Versions

After a model passes offline evaluation, create a policy version.

### 2.1 Policy Version Structure

```json
{
  "policy_id": "planner_policy",
  "version": 4,
  "mlflow_model_name": "planner_model",
  "mlflow_model_version": "4",
  "config_defaults": {
    "temperature": 0.7,
    "max_tokens": 2048
  }
}
```

### 2.2 Creating Policy Version (Pseudo-code)

```pseudo
function create_policy_version(policy_name, mlflow_model_name, mlflow_model_version, config_defaults):
    
    # 1. Get policy
    policy = db.query("SELECT * FROM exp.policies WHERE name = ?", policy_name)
    
    # 2. Get next version number
    current_max = db.query(
        "SELECT MAX(version) FROM exp.policy_versions WHERE policy_id = ?",
        policy.id
    )
    next_version = current_max + 1
    
    # 3. Insert policy version
    policy_version = db.insert("exp.policy_versions", {
        "policy_id": policy.id,
        "version": next_version,
        "mlflow_model_name": mlflow_model_name,
        "mlflow_model_version": mlflow_model_version,
        "config_defaults": config_defaults,
        "status": "active"
    })
    
    return policy_version
```

### 2.3 Linking to MLflow

The policy version contains:
- `mlflow_model_name` → Model name in registry
- `mlflow_model_version` → Specific version number

At runtime:
```pseudo
model_uri = f"models:/{policy_version.mlflow_model_name}/{policy_version.mlflow_model_version}"
model = mlflow.pyfunc.load_model(model_uri)
```

---

## 3. Creating Experiment Variants

### 3.1 Variant Structure

```json
{
  "experiment_id": "planner_policy_exp",
  "name": "candidate_model_v4",
  "allocation": 0.1,
  "config": {
    "policy_version_id": "uuid-policy-v4",
    "params": {
      "exploration_rate": 0.15
    }
  }
}
```

### 3.2 Adding Variant (Pseudo-code)

```pseudo
function add_candidate_variant(experiment_name, policy_version_id, initial_allocation):
    
    # 1. Get experiment
    experiment = db.query(
        "SELECT * FROM exp.experiments WHERE name = ?",
        experiment_name
    )
    
    # 2. Reduce existing allocations proportionally
    existing_variants = db.query(
        "SELECT * FROM exp.variants WHERE experiment_id = ?",
        experiment.id
    )
    
    remaining_allocation = 1.0 - initial_allocation
    for variant in existing_variants:
        new_allocation = variant.allocation * remaining_allocation
        db.update("exp.variants", {
            "id": variant.id,
            "allocation": new_allocation
        })
    
    # 3. Create new variant
    new_variant = db.insert("exp.variants", {
        "experiment_id": experiment.id,
        "name": f"candidate_v{policy_version.version}",
        "allocation": initial_allocation,
        "config": {
            "policy_version_id": policy_version_id
        }
    })
    
    return new_variant
```

### 3.3 Allocation Rules

| Phase | New Variant Allocation |
|-------|------------------------|
| Initial | ≤10% |
| Week 1 (if good) | 25% |
| Week 2 (if good) | 50% |
| Full rollout | 100% |

---

## 4. Online Experiment Monitoring

### 4.1 Key Metrics

Monitor these via Metabase:

| Metric | Target | Alert If |
|--------|--------|----------|
| Plan acceptance rate | ≥ baseline | < baseline - 5% |
| Average edits | ≤ baseline | > baseline + 10% |
| Validator interventions | ≤ baseline | > baseline + 5% |
| Latency (p50) | ≤ baseline | > baseline + 20% |
| Latency (p99) | ≤ 2s | > 2s |
| Cost per plan | ≤ baseline | > baseline + 10% |

### 4.2 Monitoring Duration

| Allocation | Minimum Duration |
|------------|------------------|
| 10% | 3 days |
| 25% | 5 days |
| 50% | 7 days |

### 4.3 Decision Criteria

```pseudo
function should_increase_allocation(variant_metrics, baseline_metrics, duration_days):
    
    # Minimum sample size
    if variant_metrics.sample_size < 1000:
        return "wait"  # Need more data
    
    # Minimum duration
    if duration_days < 3:
        return "wait"
    
    # Check key metrics
    if variant_metrics.acceptance_rate < baseline_metrics.acceptance_rate * 0.95:
        return "rollback"
    
    if variant_metrics.avg_edits > baseline_metrics.avg_edits * 1.10:
        return "rollback"
    
    if variant_metrics.validator_rate > baseline_metrics.validator_rate * 1.05:
        return "rollback"
    
    if variant_metrics.p50_latency > baseline_metrics.p50_latency * 1.20:
        return "rollback"
    
    # All checks passed
    return "increase"
```

---

## 5. Promoting to Production

### 5.1 Full Promotion Steps

```pseudo
function promote_to_production(policy_version_id, experiment_id):
    
    # 1. Update MLflow stage
    policy_version = db.query(
        "SELECT * FROM exp.policy_versions WHERE id = ?",
        policy_version_id
    )
    
    mlflow.set_model_version_tag(
        name=policy_version.mlflow_model_name,
        version=policy_version.mlflow_model_version,
        key="stage",
        value="production"
    )
    
    # 2. Archive previous production
    previous_production = mlflow.search_model_versions(
        filter_string=f"name='{policy_version.mlflow_model_name}' AND tags.stage='production'"
    )
    for pv in previous_production:
        if pv.version != policy_version.mlflow_model_version:
            mlflow.set_model_version_tag(
                name=pv.name,
                version=pv.version,
                key="stage",
                value="archived"
            )
    
    # 3. Update variant allocation to 100%
    candidate_variant = db.query(
        "SELECT * FROM exp.variants 
         WHERE experiment_id = ? 
         AND config->>'policy_version_id' = ?",
        experiment_id, policy_version_id
    )
    
    # Set candidate to 100%
    db.update("exp.variants", {
        "id": candidate_variant.id,
        "allocation": 1.0
    })
    
    # Set others to 0%
    db.execute(
        "UPDATE exp.variants SET allocation = 0 
         WHERE experiment_id = ? AND id != ?",
        experiment_id, candidate_variant.id
    )
    
    # 4. Log promotion event
    log_event({
        "event_type": "model_promoted",
        "payload": {
            "policy_version_id": policy_version_id,
            "mlflow_model_version": policy_version.mlflow_model_version
        }
    })
```

### 5.2 Retiring Old Variants

After promotion, clean up:

```pseudo
function retire_old_variants(experiment_id, keep_variant_id):
    
    # Option 1: Delete old variants
    db.execute(
        "DELETE FROM exp.variants 
         WHERE experiment_id = ? AND id != ? AND allocation = 0",
        experiment_id, keep_variant_id
    )
    
    # Option 2: Archive old variants (preferred)
    db.execute(
        "UPDATE exp.variants 
         SET name = CONCAT(name, '_archived_', NOW())
         WHERE experiment_id = ? AND id != ?",
        experiment_id, keep_variant_id
    )
```

---

## 6. Rollback Procedure

### 6.1 When to Rollback

- Metrics significantly worse than baseline
- Critical bugs discovered
- Constraint violations in production

### 6.2 Rollback Steps

```pseudo
function rollback_variant(experiment_id, failed_variant_id, baseline_variant_id):
    
    # 1. Set failed variant to 0%
    db.update("exp.variants", {
        "id": failed_variant_id,
        "allocation": 0
    })
    
    # 2. Restore baseline to 100%
    db.update("exp.variants", {
        "id": baseline_variant_id,
        "allocation": 1.0
    })
    
    # 3. Update MLflow stage
    failed_policy = get_policy_version(failed_variant_id)
    mlflow.set_model_version_tag(
        name=failed_policy.mlflow_model_name,
        version=failed_policy.mlflow_model_version,
        key="stage",
        value="archived"
    )
    
    # 4. Log rollback event
    log_event({
        "event_type": "model_rollback",
        "payload": {
            "failed_variant_id": failed_variant_id,
            "reason": "metrics_regression"
        }
    })
```

---

## 7. Promotion Checklist

Use this checklist before promoting:

| Step | Check |
|------|-------|
| Offline evaluation | ✓ Passed all criteria |
| Policy version | ✓ Created and linked to MLflow |
| Experiment variant | ✓ Created with ≤10% allocation |
| Minimum duration | ✓ At least 3 days at each allocation |
| Sample size | ✓ At least 1000 samples |
| Acceptance rate | ✓ Not significantly worse |
| Edit count | ✓ Not significantly worse |
| Validator interventions | ✓ Not significantly worse |
| Latency | ✓ Within acceptable bounds |
| Cost | ✓ Within budget |

---

## 8. Related Documentation

| Document | Purpose |
|----------|---------|
| [offline-evaluation.md](offline-evaluation.md) | Prerequisite |
| [mlflow-guide.md](mlflow-guide.md) | Stage management |
| [experiments.md](experiments.md) | Experiment concepts |
| [../analytics/metabase-models.md](../analytics/metabase-models.md) | Monitoring dashboards |

---

## After Completing This Document

You will understand:
- The full promotion lifecycle
- How to create policy versions
- How to create experiment variants
- How to monitor online experiments
- When and how to promote or rollback

**Next Step**: [../analytics/metabase-models.md](../analytics/metabase-models.md)

