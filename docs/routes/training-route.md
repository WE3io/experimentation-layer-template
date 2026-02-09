# Training Route

**Purpose**  
This route guides developers who want to prepare datasets, train models, and register them in MLflow. This route is for **traditional ML projects** using trained models. For conversational AI projects using prompts, see [conversational-ai-route.md](conversational-ai-route.md).

---

## Route Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ training-       │ ──► │ mlflow-guide.md │ ──► │ datasets/       │
│ workflow.md     │     │                 │     │ README.md       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│ training/       │
│ templates       │
└─────────────────┘
```

---

## Documents in This Route

### 1. Start Here: [../training-workflow.md](../training-workflow.md)
**Learn**: Complete training process from dataset to registered model

**After**: You understand how training works end-to-end.

### 2. Next: [../mlflow-guide.md](../mlflow-guide.md)
**Learn**: MLflow usage for tracking and registration

**After**: You know what to log and how to register models.

### 3. Then: [../../datasets/README.md](../../datasets/README.md)
**Learn**: Dataset conventions and structure

**After**: You can create properly formatted datasets.

### 4. Then: [../../pipelines/training-data.md](../../pipelines/training-data.md)
**Learn**: How the training data pipeline works

**After**: You can generate training datasets from events.

### 5. Finally: [../../training/README.md](../../training/README.md)
**Learn**: Training script templates

**After**: You can run training jobs.

---

## Supporting Documents

| Document | Purpose |
|----------|---------|
| [../../infra/mlflow-setup.md](../../infra/mlflow-setup.md) | MLflow deployment |
| [../mlops-concepts.md](../mlops-concepts.md) | MLOps primer |
| [../../config/policies.example.yml](../../config/policies.example.yml) | Policy configuration |

---

## Route Outcomes

After completing this route, you will be able to:

1. ✓ Generate training datasets from events
2. ✓ Understand dataset structure requirements
3. ✓ Run training with proper MLflow logging
4. ✓ Register models in MLflow
5. ✓ Verify registration and artefacts

---

## Branching Points

| If you want to... | Go to... |
|-------------------|----------|
| Build conversational AI projects | [conversational-ai-route.md](conversational-ai-route.md) |
| Evaluate trained models | [offline-evaluation-route.md](offline-evaluation-route.md) |
| Promote models to production | [model-promotion-route.md](model-promotion-route.md) |
| Understand event sources | [event-logging-route.md](event-logging-route.md) |
| Return to main docs | [../README.md](../README.md) |

