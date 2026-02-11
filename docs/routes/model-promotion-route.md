# Model Promotion Route

**Purpose**  
This route guides developers through the process of promoting models from candidate to production. This route focuses on **ML projects** using trained models. For conversational AI projects, promotion involves promoting prompt versions rather than model versions—see [conversational-ai-route.md](conversational-ai-route.md) for details.

---

## Prerequisites

- [architecture.md](../architecture.md) - System overview
- [experiments.md](../experiments.md) - Variants and allocations
- [offline-evaluation.md](../offline-evaluation.md) - Candidate qualification
- [data-model.md](../data-model.md) - Schema (sections 1–2, 4)

---

## Route Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ model-          │ ──► │ experiments.md  │ ──► │ metabase-       │
│ promotion.md    │     │ (variants)      │     │ models.md       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│ mlflow-guide    │
│ (stages)        │
└─────────────────┘
```

---

## Documents in This Route

### 1. Start Here: [../model-promotion.md](../model-promotion.md)
**Learn**: Complete promotion lifecycle

**After**: You understand how models move from candidate to production.

### 2. Next: [../mlflow-guide.md](../mlflow-guide.md) (Sections 5-6)
**Learn**: MLflow stage management

**After**: You can update model stages in MLflow.

### 3. Then: [../experiments.md](../experiments.md) (Sections 5-6)
**Learn**: Creating experiment variants for new models

**After**: You can create variants with correct allocations.

### 4. Finally: [../../analytics/metabase-models.md](../../analytics/metabase-models.md)
**Learn**: Monitoring promoted models

**After**: You can track online experiment performance.

---

## Supporting Documents

| Document | Purpose |
|----------|---------|
| [../../config/policies.example.yml](../../config/policies.example.yml) | Policy version configuration |
| [../data-model.md](../data-model.md) | Policy versions schema |
| [../offline-evaluation.md](../offline-evaluation.md) | Prerequisite: passing evaluation |

---

## Route Outcomes

After completing this route, you will be able to:

1. ✓ Create policy versions linking to MLflow models
2. ✓ Create experiment variants for new models
3. ✓ Manage allocation percentages
4. ✓ Monitor online experiment metrics
5. ✓ Promote or rollback based on results

---

## Branching Points

| If you want to... | Go to... |
|-------------------|----------|
| Promote prompt versions (conversational AI) | [conversational-ai-route.md](conversational-ai-route.md) |
| Evaluate models first | [offline-evaluation-route.md](offline-evaluation-route.md) |
| Train new models | [training-route.md](training-route.md) |
| Build monitoring dashboards | [analytics-route.md](analytics-route.md) |
| Return to main docs | [../README.md](../README.md) |

