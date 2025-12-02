# Offline Evaluation

**Purpose**  
This document explains the offline replay evaluation process that validates models before live traffic.

---

## Start Here If…

- **Full sequential workflow** → Continue from [training-workflow.md](training-workflow.md)
- **Offline Evaluation Route** → This is your entry point
- **Understanding metrics** → Focus on section 3
- **Acceptance criteria** → Focus on section 4

---

## 1. Why Offline Evaluation?

Before any model receives live traffic, it must pass offline evaluation:

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ Training        │ ──► │ Offline Eval    │ ──► │ Online          │
│ Complete        │     │ (Gate)          │     │ Experiment      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │
                               ▼
                        Pass? ──► Continue
                        Fail? ──► Do not deploy
```

**Benefits**:
- Catches regressions before user impact
- Validates constraint compliance
- Compares against baseline
- Provides confidence metrics

---

## 2. Replay Process

### 2.1 Overview

```
┌─────────────────┐
│ Historical      │
│ Dataset         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Load Candidate  │
│ Model           │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ For each row:   │
│ - Run model     │
│ - Compare output│
│ - Score result  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Aggregate       │
│ Metrics         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Compare vs      │
│ Baseline        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Decision:       │
│ Pass/Fail       │
└─────────────────┘
```

### 2.2 Replay Steps (Pseudo-code)

```pseudo
function run_offline_evaluation(model_name, model_version, dataset_path):
    
    # 1. Load dataset
    dataset = load_parquet(dataset_path)
    
    # 2. Load model from MLflow
    model_uri = f"models:/{model_name}/{model_version}"
    model = mlflow.pyfunc.load_model(model_uri)
    
    # 3. Initialize accumulators
    results = []
    
    # 4. Process each row
    for row in dataset:
        # Run model on historical input
        prediction = model.predict(row.input)
        
        # Compare with historical target
        metrics = compute_metrics(prediction, row.target)
        
        results.append({
            "row_id": row.id,
            "metrics": metrics
        })
    
    # 5. Aggregate results
    aggregate = {
        "plan_alignment_score": mean([r.metrics.alignment for r in results]),
        "constraint_respect_score": mean([r.metrics.constraints for r in results]),
        "edit_distance_score": mean([r.metrics.edit_distance for r in results]),
        "diversity_score": mean([r.metrics.diversity for r in results]),
        "leftovers_score": mean([r.metrics.leftovers for r in results])
    }
    
    # 6. Log to MLflow
    with mlflow.start_run():
        mlflow.log_metrics(aggregate)
        mlflow.set_tags({
            "model_name": model_name,
            "model_version": model_version,
            "dataset_version": dataset_path
        })
    
    # 7. Store results
    db.insert("exp.offline_replay_results", {
        "policy_version_id": get_policy_version(model_name, model_version),
        "dataset_version": dataset_path,
        **aggregate
    })
    
    return aggregate
```

---

## 3. Evaluation Metrics

### 3.1 Core Metrics

| Metric | Description | Target |
|--------|-------------|--------|
| `plan_alignment_score` | How closely prediction matches accepted plan | Higher is better |
| `constraint_respect_score` | Whether all constraints satisfied | Must be 100% |
| `edit_distance_score` | Predicted vs actual user edits | Lower is better |
| `diversity_score` | Variety in meal recommendations | Maintain or improve |
| `leftovers_score` | Efficiency of ingredient usage | Maintain or improve |

### 3.2 Computing Alignment Score

```pseudo
function compute_alignment(prediction, target):
    predicted_meals = set(prediction.meals)
    actual_meals = set(target.accepted_plan.meals)
    
    intersection = predicted_meals.intersect(actual_meals)
    union = predicted_meals.union(actual_meals)
    
    jaccard = len(intersection) / len(union)
    return jaccard
```

### 3.3 Computing Constraint Respect

```pseudo
function compute_constraint_respect(prediction, constraints):
    violations = 0
    
    for meal in prediction.meals:
        recipe = get_recipe(meal.recipe_id)
        
        # Check excluded ingredients
        for ingredient in recipe.ingredients:
            if ingredient in constraints.excluded_ingredients:
                violations += 1
        
        # Check prep time
        if recipe.prep_time > constraints.max_prep_time:
            violations += 1
        
        # Check dietary restrictions
        if not respects_dietary(recipe, constraints.restrictions):
            violations += 1
    
    return 1.0 if violations == 0 else 0.0
```

### 3.4 Computing Edit Distance

```pseudo
function compute_edit_distance(prediction, target):
    predicted_edits = estimate_required_edits(prediction, target.accepted_plan)
    actual_edits = len(target.user_edits)
    
    # Lower is better (prediction needed fewer edits)
    # Normalize: 0 = perfect match, 1 = all different
    max_edits = len(prediction.meals)
    score = 1 - (predicted_edits / max_edits)
    return score
```

---

## 4. Acceptance Criteria

### 4.1 Minimum Requirements

A model may be marked `candidate` if ALL conditions met:

| Criterion | Requirement |
|-----------|-------------|
| Constraint respect | = 100% (zero violations) |
| Plan alignment | ≥ baseline alignment |
| Edit distance | ≤ baseline edit distance |
| Diversity | ≥ 95% of baseline |
| Leftovers efficiency | ≥ 95% of baseline |

### 4.2 Comparison Against Baseline

```pseudo
function passes_evaluation(candidate_metrics, baseline_metrics):
    # Hard requirement: no constraint violations
    if candidate_metrics.constraint_respect_score < 1.0:
        return False
    
    # Must match or exceed baseline alignment
    if candidate_metrics.plan_alignment_score < baseline_metrics.plan_alignment_score:
        return False
    
    # Must not increase predicted edits
    if candidate_metrics.edit_distance_score < baseline_metrics.edit_distance_score:
        return False
    
    # Allow 5% degradation in diversity
    if candidate_metrics.diversity_score < baseline_metrics.diversity_score * 0.95:
        return False
    
    # Allow 5% degradation in leftovers
    if candidate_metrics.leftovers_score < baseline_metrics.leftovers_score * 0.95:
        return False
    
    return True
```

### 4.3 On Pass: Mark Candidate

```pseudo
if passes_evaluation(candidate_metrics, baseline_metrics):
    mlflow.set_tag("stage", "candidate")
    
    db.update("exp.offline_replay_results", {
        "id": eval_id,
        "is_better_than_baseline": True
    })
```

### 4.4 On Fail: Do Not Proceed

```pseudo
if not passes_evaluation(...):
    log_failure_reason(candidate_metrics, baseline_metrics)
    
    # Do NOT create policy version
    # Do NOT create experiment variant
    # Return to training with insights
```

---

## 5. Running Evaluation

### 5.1 Command

```bash
python pipelines/offline_replay.py \
    --model_name=planner_model \
    --model_version=4 \
    --dataset=/datasets/planner/2025-01-03 \
    --baseline_version=3
```

### 5.2 Output

```
Offline Evaluation Results
==========================
Model: planner_model v4
Dataset: /datasets/planner/2025-01-03

Metrics:
  plan_alignment_score:      0.872 (baseline: 0.845) ✓
  constraint_respect_score:  1.000 (baseline: 1.000) ✓
  edit_distance_score:       0.921 (baseline: 0.908) ✓
  diversity_score:           0.834 (baseline: 0.841) ✓
  leftovers_score:           0.756 (baseline: 0.762) ✓

Result: PASS
Action: Model marked as candidate
```

---

## 6. Determinism Requirements

### 6.1 Why Determinism Matters

Offline evaluation must be reproducible:
- Same dataset → same results
- Debugging requires consistency
- Comparison requires stability

### 6.2 Ensuring Determinism

```pseudo
# Pin everything
seed = 42
set_random_seed(seed)

# Use specific versions
model_version = "4"  # Not "latest"
dataset_version = "2025-01-03"  # Not "recent"

# Disable sampling
temperature = 0.0  # Greedy decoding
top_p = 1.0
```

---

## 7. Results Storage

### 7.1 Database Schema

Results stored in `exp.offline_replay_results`:

```sql
INSERT INTO exp.offline_replay_results (
    policy_version_id,
    dataset_version,
    mlflow_run_id,
    plan_alignment_score,
    constraint_respect_score,
    edit_distance_score,
    diversity_score,
    leftovers_score,
    baseline_version_id,
    is_better_than_baseline
) VALUES (...);
```

### 7.2 Querying Results

```sql
SELECT 
    pv.version,
    r.plan_alignment_score,
    r.constraint_respect_score,
    r.is_better_than_baseline
FROM exp.offline_replay_results r
JOIN exp.policy_versions pv ON pv.id = r.policy_version_id
ORDER BY pv.version DESC;
```

---

## 8. Related Documentation

| Document | Purpose |
|----------|---------|
| [training-workflow.md](training-workflow.md) | Training process |
| [model-promotion.md](model-promotion.md) | Next step after passing |
| [mlflow-guide.md](mlflow-guide.md) | MLflow usage |
| [../pipelines/offline-replay.md](../pipelines/offline-replay.md) | Pipeline specification |

---

## After Completing This Document

You will understand:
- Why offline evaluation is required
- The replay process
- How metrics are computed
- Acceptance criteria
- How to run evaluation

**Next Step**: [model-promotion.md](model-promotion.md)

