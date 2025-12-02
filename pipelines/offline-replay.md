# Offline Replay Pipeline

**Purpose**  
This document specifies the pipeline for evaluating models against historical data.

---

## Start Here If…

- **Offline Evaluation Route** → Core document for this route
- **Understanding evaluation** → Go to [../docs/offline-evaluation.md](../docs/offline-evaluation.md)
- **Running evaluations** → Focus on section 4

---

## 1. Pipeline Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Load Dataset   │ ──► │  Load Model     │ ──► │  Run Inference  │
│  (Parquet)      │     │  (MLflow)       │     │  Per Row        │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Store Results  │ ◄── │  Compare vs     │ ◄── │  Compute        │
│  (Postgres)     │     │  Baseline       │     │  Metrics        │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

## 2. Pipeline Steps (Pseudo-code)

### 2.1 Load Dataset

```pseudo
function load_evaluation_dataset(dataset_path, sample_size=None):
    df = read_parquet(dataset_path)
    
    if sample_size and len(df) > sample_size:
        df = df.sample(n=sample_size, random_state=42)
    
    return df
```

### 2.2 Load Model

```pseudo
function load_candidate_model(model_name, model_version):
    model_uri = f"models:/{model_name}/{model_version}"
    model = mlflow.pyfunc.load_model(model_uri)
    return model
```

### 2.3 Run Inference

```pseudo
function run_inference(model, input_context):
    # Ensure determinism
    set_random_seed(42)
    
    # Run model with greedy decoding
    prediction = model.predict(
        input_context,
        temperature=0.0,
        top_p=1.0
    )
    
    return prediction
```

### 2.4 Compute Metrics

```pseudo
function compute_metrics(prediction, target):
    metrics = {}
    
    # Plan alignment (Jaccard similarity)
    pred_meals = set(get_meal_ids(prediction))
    target_meals = set(get_meal_ids(target.accepted_plan))
    
    if len(pred_meals.union(target_meals)) > 0:
        metrics["plan_alignment"] = (
            len(pred_meals.intersection(target_meals)) /
            len(pred_meals.union(target_meals))
        )
    else:
        metrics["plan_alignment"] = 0.0
    
    # Constraint respect
    violations = count_constraint_violations(prediction, target.constraints)
    metrics["constraint_respect"] = 1.0 if violations == 0 else 0.0
    
    # Edit distance
    predicted_edits = estimate_edits_needed(prediction, target.accepted_plan)
    max_edits = len(prediction.meals)
    metrics["edit_distance"] = 1.0 - (predicted_edits / max_edits) if max_edits > 0 else 1.0
    
    # Diversity
    metrics["diversity"] = compute_diversity_score(prediction)
    
    # Leftovers efficiency
    metrics["leftovers"] = compute_leftovers_score(prediction, target.pantry)
    
    return metrics
```

### 2.5 Compare vs Baseline

```pseudo
function compare_with_baseline(candidate_metrics, baseline_metrics):
    comparison = {
        "plan_alignment": {
            "candidate": candidate_metrics.plan_alignment,
            "baseline": baseline_metrics.plan_alignment,
            "diff": candidate_metrics.plan_alignment - baseline_metrics.plan_alignment,
            "passed": candidate_metrics.plan_alignment >= baseline_metrics.plan_alignment
        },
        "constraint_respect": {
            "candidate": candidate_metrics.constraint_respect,
            "baseline": baseline_metrics.constraint_respect,
            "passed": candidate_metrics.constraint_respect >= 1.0
        },
        # ... other metrics
    }
    
    overall_passed = all(m["passed"] for m in comparison.values())
    
    return {
        "comparison": comparison,
        "passed": overall_passed
    }
```

### 2.6 Store Results

```pseudo
function store_results(policy_version_id, dataset_version, metrics, comparison, mlflow_run_id):
    db.insert("exp.offline_replay_results", {
        "policy_version_id": policy_version_id,
        "dataset_version": dataset_version,
        "mlflow_run_id": mlflow_run_id,
        "plan_alignment_score": metrics.plan_alignment,
        "constraint_respect_score": metrics.constraint_respect,
        "edit_distance_score": metrics.edit_distance,
        "diversity_score": metrics.diversity,
        "leftovers_score": metrics.leftovers,
        "baseline_version_id": comparison.baseline_version_id,
        "is_better_than_baseline": comparison.passed,
        "status": "completed"
    })
```

---

## 3. Full Pipeline

```pseudo
function run_offline_evaluation(
    model_name,
    model_version,
    dataset_path,
    baseline_version=None,
    sample_size=None
):
    # Start MLflow run
    with mlflow.start_run() as run:
        mlflow.set_tags({
            "evaluation_type": "offline_replay",
            "model_name": model_name,
            "model_version": model_version,
            "dataset": dataset_path
        })
        
        # Load dataset
        dataset = load_evaluation_dataset(dataset_path, sample_size)
        mlflow.log_metric("dataset_size", len(dataset))
        
        # Load candidate model
        candidate_model = load_candidate_model(model_name, model_version)
        
        # Load baseline if specified
        baseline_model = None
        if baseline_version:
            baseline_model = load_candidate_model(model_name, baseline_version)
        
        # Process each row
        candidate_results = []
        baseline_results = []
        
        for row in dataset.iterrows():
            # Run candidate
            pred = run_inference(candidate_model, row.input)
            metrics = compute_metrics(pred, row.target)
            candidate_results.append(metrics)
            
            # Run baseline
            if baseline_model:
                baseline_pred = run_inference(baseline_model, row.input)
                baseline_metrics = compute_metrics(baseline_pred, row.target)
                baseline_results.append(baseline_metrics)
        
        # Aggregate results
        candidate_aggregate = aggregate_metrics(candidate_results)
        
        # Log to MLflow
        mlflow.log_metrics({
            "plan_alignment_score": candidate_aggregate.plan_alignment,
            "constraint_respect_score": candidate_aggregate.constraint_respect,
            "edit_distance_score": candidate_aggregate.edit_distance,
            "diversity_score": candidate_aggregate.diversity,
            "leftovers_score": candidate_aggregate.leftovers
        })
        
        # Compare with baseline
        comparison = None
        if baseline_results:
            baseline_aggregate = aggregate_metrics(baseline_results)
            comparison = compare_with_baseline(candidate_aggregate, baseline_aggregate)
        
        # Store results
        policy_version = get_policy_version(model_name, model_version)
        store_results(
            policy_version.id,
            dataset_path,
            candidate_aggregate,
            comparison,
            run.info.run_id
        )
        
        # Mark as candidate if passed
        if comparison and comparison.passed:
            mlflow.set_tag("stage", "candidate")
            print("✓ Evaluation PASSED - model marked as candidate")
        else:
            print("✗ Evaluation FAILED")
        
        return {
            "metrics": candidate_aggregate,
            "comparison": comparison,
            "mlflow_run_id": run.info.run_id
        }
```

---

## 4. Running the Pipeline

### 4.1 Command Line

```bash
python pipelines/offline_replay.py \
    --model_name planner_model \
    --model_version 4 \
    --dataset /datasets/planner/2025-01-03 \
    --baseline_version 3 \
    --sample_size 1000
```

### 4.2 Script Template

```pseudo
# pipelines/offline_replay.py

import argparse

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_name", required=True)
    parser.add_argument("--model_version", required=True)
    parser.add_argument("--dataset", required=True)
    parser.add_argument("--baseline_version")
    parser.add_argument("--sample_size", type=int)
    
    args = parser.parse_args()
    
    result = run_offline_evaluation(
        model_name=args.model_name,
        model_version=args.model_version,
        dataset_path=args.dataset,
        baseline_version=args.baseline_version,
        sample_size=args.sample_size
    )
    
    print(f"\nResults:")
    print(f"  Plan Alignment: {result['metrics'].plan_alignment:.4f}")
    print(f"  Constraint Respect: {result['metrics'].constraint_respect:.4f}")
    print(f"  Edit Distance: {result['metrics'].edit_distance:.4f}")
    
    if result['comparison']:
        print(f"\n  Passed: {result['comparison']['passed']}")

if __name__ == "__main__":
    main()
```

---

## 5. Acceptance Criteria

### 5.1 Hard Requirements

| Criterion | Requirement |
|-----------|-------------|
| Constraint respect | = 100% |

### 5.2 Comparison Requirements

| Criterion | Requirement |
|-----------|-------------|
| Plan alignment | ≥ baseline |
| Edit distance | ≥ baseline |
| Diversity | ≥ 95% of baseline |
| Leftovers | ≥ 95% of baseline |

---

## 6. TODO: Implementation Notes

- [ ] Implement metric computation functions
- [ ] Add constraint checking logic
- [ ] Set up MLflow logging
- [ ] Add CLI interface
- [ ] Configure parallel processing for large datasets

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [../docs/offline-evaluation.md](../docs/offline-evaluation.md) | Evaluation concepts |
| [../docs/mlflow-guide.md](../docs/mlflow-guide.md) | MLflow usage |
| [../docs/model-promotion.md](../docs/model-promotion.md) | Next steps after evaluation |

