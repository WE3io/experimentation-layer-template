# Experiment Route

**Purpose**  
This route guides developers who want to understand and work with the experimentation system. The experimentation framework supports both traditional ML projects and conversational AI projects through a unified abstraction.

---

## Route Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ experiments.md  │ ──► │ assignment-     │ ──► │ event-ingestion │
│                 │     │ service         │     │ -service        │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
   Concepts              API Spec              API Spec
   + Config              + Design              + Design
```

---

## Documents in This Route

### 1. Start Here: [../experiments.md](../experiments.md)
**Learn**: Experiment concepts, variants, allocation logic, and unified config format

**After**: You will understand how experiments are configured (for both ML and conversational AI projects) and how users are assigned to variants.

### 2. Next: [../assignment-service.md](../assignment-service.md)
**Learn**: How the Assignment Service works

**After**: You will understand the request/response flow for getting variant assignments.

### 3. Then: [../../services/assignment-service/API_SPEC.md](../../services/assignment-service/API_SPEC.md)
**Learn**: Full API specification for the Assignment Service

**After**: You can implement or call the Assignment Service.

### 4. Then: [../event-ingestion-service.md](../event-ingestion-service.md)
**Learn**: How events are captured with experiment context

**After**: You understand how to log events properly.

### 5. Finally: [../../services/event-ingestion-service/API_SPEC.md](../../services/event-ingestion-service/API_SPEC.md)
**Learn**: Full API specification for the Event Ingestion Service

**After**: You can implement or call the Event Ingestion Service.

---

## Supporting Documents

| Document | Purpose |
|----------|---------|
| [../choosing-project-type.md](../choosing-project-type.md) | Decision guide for ML vs. conversational AI |
| [../data-model.md](../data-model.md) | Schema for experiments, variants, assignments |
| [../../config/experiments.example.yml](../../config/experiments.example.yml) | Example experiment configuration (includes both ML and conversational AI examples) |
| [../../analytics/metabase-models.md](../../analytics/metabase-models.md) | Monitoring experiment results |

---

## Route Outcomes

After completing this route, you will be able to:

1. ✓ Configure new experiments
2. ✓ Define variants with appropriate allocations
3. ✓ Understand how users are assigned to variants
4. ✓ Log events with correct experiment context
5. ✓ Query experiment results

---

## Branching Points

| If you want to... | Go to... |
|-------------------|----------|
| Build conversational AI projects | [conversational-ai-route.md](conversational-ai-route.md) |
| Train models for experiments | [training-route.md](training-route.md) |
| Monitor experiment metrics | [analytics-route.md](analytics-route.md) |
| Understand model promotion | [model-promotion-route.md](model-promotion-route.md) |
| Return to main docs | [../README.md](../README.md) |

