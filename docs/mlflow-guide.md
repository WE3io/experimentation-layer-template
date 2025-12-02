# MLflow Guide

**Purpose**  
This document explains how MLflow is used for model tracking, versioning, and registry in this system.

---

## Start Here If…

- **Full sequential workflow** → Continue from [event-ingestion-service.md](event-ingestion-service.md)
- **Model Promotion Route** → Core document for this route
- **Training workflow** → Read this, then go to [training-workflow.md](training-workflow.md)
- **New to MLflow** → Read section 1 carefully

---

## 1. What is MLflow?

MLflow is an open-source platform for managing the ML lifecycle:

| Component | Purpose |
|-----------|---------|
| **Tracking** | Log parameters, metrics, and artefacts during training |
| **Model Registry** | Version and stage models (candidate, production) |
| **Projects** | Package ML code for reproducible runs |
| **Models** | Deploy models in various formats |

This system uses **Tracking** and **Model Registry** primarily.

---

## 2. MLflow in This System

### 2.1 Role of MLflow

```
Training Script
     │
     ▼
┌─────────────────────────────────────┐
│  MLflow Tracking Server              │
│  - Logs params, metrics              │
│  - Stores artefacts                  │
└─────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────┐
│  MLflow Model Registry               │
│  - Registers model versions          │
│  - Manages stages                    │
└─────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────┐
│  exp.policy_versions                 │
│  - Links policy to MLflow model      │
│  - Used by experiment variants       │
└─────────────────────────────────────┘
```

### 2.2 Key Integration Points

1. **Training** → Logs to MLflow
2. **Policy Versions** → Reference MLflow model versions
3. **Experiment Variants** → Use policy versions
4. **Offline Evaluation** → Loads models from MLflow

---

## 3. Required Logging (Minimum)

Every training run MUST log:

### 3.1 Parameters

```python
# Example: What to log
mlflow.log_params({
    "learning_rate": 1e-4,
    "batch_size": 16,
    "epochs": 3,
    "dataset_version": "2025-01-03",
    "model_base": "llama-3-8b",
    "fine_tuning_method": "lora"
})
```

### 3.2 Metrics

```python
# Example: What to log
mlflow.log_metrics({
    "train_loss": 0.45,
    "val_loss": 0.52,
    "plan_alignment_score": 0.87,
    "constraint_respect_score": 1.0
})
```

### 3.3 Tags

```python
# Example: What to log
mlflow.set_tags({
    "policy_id": "planner_policy",
    "task": "planner",
    "dataset_version": "2025-01-03",
    "stage": "training"
})
```

### 3.4 Artefacts

```python
# Example: What to log
mlflow.log_artifacts("./model_output", artifact_path="model")
mlflow.log_artifact("./tokenizer", artifact_path="tokenizer")
mlflow.log_artifact("./config.json", artifact_path="config")
```

---

## 4. Model Registration

### 4.1 Registering a Model

```pseudo
# After training completes
model_uri = f"runs:/{run_id}/model"

registered_model = mlflow.register_model(
    model_uri=model_uri,
    name="planner_model"
)

# Result:
#   Model name: planner_model
#   Version: 3
```

### 4.2 Model Naming Convention

| Model | Name |
|-------|------|
| Planner model | `planner_model` |
| Meal ranker | `meal_ranker_model` |
| Recipe recommender | `recipe_recommender_model` |

### 4.3 Versioning

MLflow automatically versions models:
- Version 1, 2, 3, etc.
- Each version is immutable
- Reference by name + version

---

## 5. Model Stages

### 5.1 Stage Lifecycle

```
┌─────────┐     ┌───────────┐     ┌────────────┐
│  None   │ ──► │ Candidate │ ──► │ Production │
└─────────┘     └───────────┘     └────────────┘
                      │
                      ▼
               ┌────────────┐
               │  Archived  │
               └────────────┘
```

### 5.2 Stage Meanings

| Stage | Meaning |
|-------|---------|
| `None` | Just registered, not evaluated |
| `candidate` | Passed offline evaluation |
| `production` | Serving live traffic |
| `archived` | No longer in use |

### 5.3 Setting Stages via Tags

```python
# Using tags for stage management
mlflow.set_tag("stage", "candidate")

# Or using MLflow client
client = mlflow.MlflowClient()
client.set_model_version_tag(
    name="planner_model",
    version="3",
    key="stage",
    value="candidate"
)
```

---

## 6. Linking to Policy Versions

### 6.1 Creating Policy Version

After model registration, create a policy version:

```sql
INSERT INTO exp.policy_versions (
    policy_id,
    version,
    mlflow_model_name,
    mlflow_model_version,
    config_defaults
) VALUES (
    'planner_policy_uuid',
    4,
    'planner_model',
    '4',
    '{"temperature": 0.7}'
);
```

### 6.2 Policy → Experiment Link

```
exp.variants.config.policy_version_id
        │
        ▼
exp.policy_versions
        │
        ├─ mlflow_model_name
        └─ mlflow_model_version
              │
              ▼
        MLflow Model Registry
              │
              ▼
        S3/MinIO Artefacts
```

---

## 7. Loading Models

### 7.1 At Inference Time

```pseudo
function load_model(policy_version):
    model_name = policy_version.mlflow_model_name
    model_version = policy_version.mlflow_model_version
    
    model_uri = f"models:/{model_name}/{model_version}"
    model = mlflow.pyfunc.load_model(model_uri)
    
    return model
```

### 7.2 For Offline Evaluation

```pseudo
function evaluate_model(model_version, dataset):
    model_uri = f"models:/planner_model/{model_version}"
    model = mlflow.pyfunc.load_model(model_uri)
    
    for row in dataset:
        prediction = model.predict(row.input)
        # Compare with row.target
```

---

## 8. Environment Setup

### 8.1 Required Environment Variables

```bash
# MLflow tracking server
export MLFLOW_TRACKING_URI="http://mlflow.internal:5000"

# Artefact storage (S3)
export MLFLOW_S3_ENDPOINT_URL="http://minio.internal:9000"
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

### 8.2 Tracking Server Setup

See [../infra/mlflow-setup.md](../infra/mlflow-setup.md) for deployment instructions.

---

## 9. Common Operations

### 9.1 List Model Versions

```pseudo
client = mlflow.MlflowClient()
versions = client.search_model_versions("name='planner_model'")

for v in versions:
    print(f"Version {v.version}: stage={v.tags.get('stage')}")
```

### 9.2 Compare Runs

```pseudo
runs = mlflow.search_runs(
    experiment_ids=["planner_training"],
    filter_string="metrics.val_loss < 0.5",
    order_by=["metrics.plan_alignment_score DESC"]
)
```

### 9.3 Download Artefacts

```pseudo
client = mlflow.MlflowClient()
client.download_artifacts(
    run_id="abc123",
    path="model",
    dst_path="./local_model"
)
```

---

## 10. Related Documentation

| Document | Purpose |
|----------|---------|
| [../infra/mlflow-setup.md](../infra/mlflow-setup.md) | Deployment setup |
| [training-workflow.md](training-workflow.md) | Training process |
| [model-promotion.md](model-promotion.md) | Promotion lifecycle |
| [data-model.md](data-model.md) | Policy versions schema |

---

## After Completing This Document

You will understand:
- MLflow's role in the system
- What to log during training
- How models are registered and versioned
- How stages indicate readiness
- How policy versions link to MLflow

**Next Step**: [training-workflow.md](training-workflow.md)

