# Offline Evaluation Route

**Purpose**  
This route guides developers who want to evaluate models before deploying them to live traffic. This route focuses on **ML projects** using trained models. For conversational AI projects, evaluation involves conversation replay—see [conversational-ai-route.md](conversational-ai-route.md) and [../../pipelines/conversation-replay.md](../../pipelines/conversation-replay.md).

---

## Route Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ offline-        │ ──► │ pipelines/      │ ──► │ data-model.md   │
│ evaluation.md   │     │ offline-replay  │     │ (results table) │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

## Documents in This Route

### 1. Start Here: [../offline-evaluation.md](../offline-evaluation.md)
**Learn**: Why and how offline evaluation works

**After**: You understand the evaluation process and acceptance criteria.

### 2. Next: [../../pipelines/offline-replay.md](../../pipelines/offline-replay.md)
**Learn**: The offline replay pipeline specification

**After**: You can run offline evaluation jobs.

### 3. Then: [../data-model.md](../data-model.md) (Section 4)
**Learn**: exp.offline_replay_results schema

**After**: You understand how results are stored.

### 4. Finally: [../mlflow-guide.md](../mlflow-guide.md) (Section 5)
**Learn**: Setting model stages based on evaluation

**After**: You can mark models as candidates.

---

## Supporting Documents

| Document | Purpose |
|----------|---------|
| [../../datasets/README.md](../../datasets/README.md) | Dataset format for evaluation |
| [../../analytics/example-queries.sql](../../analytics/example-queries.sql) | Querying evaluation results |
| [../training-workflow.md](../training-workflow.md) | What happens before evaluation |

---

## Route Outcomes

After completing this route, you will be able to:

1. ✓ Run offline evaluation on trained models
2. ✓ Understand evaluation metrics
3. ✓ Compare against baselines
4. ✓ Interpret pass/fail criteria
5. ✓ Mark passing models as candidates

---

## Branching Points

| If you want to... | Go to... |
|-------------------|----------|
| Evaluate prompts/flows (conversational AI) | [conversational-ai-route.md](conversational-ai-route.md) |
| Train models first | [training-route.md](training-route.md) |
| Promote to production | [model-promotion-route.md](model-promotion-route.md) |
| Build evaluation dashboards | [analytics-route.md](analytics-route.md) |
| Return to main docs | [../README.md](../README.md) |

