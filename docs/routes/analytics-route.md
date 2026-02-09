# Analytics Route

**Purpose**  
This route guides developers who want to build dashboards and analyse experiment results.

---

## Route Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ metabase-       │ ──► │ example-        │ ──► │ data-model.md   │
│ models.md       │     │ queries.sql     │     │ (views)         │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│ metabase-setup  │
└─────────────────┘
```

---

## Documents in This Route

### 1. Start Here: [../../analytics/metabase-models.md](../../analytics/metabase-models.md)
**Learn**: Required dashboards and data models

**After**: You understand what dashboards to build.

### 2. Next: [../../analytics/example-queries.sql](../../analytics/example-queries.sql)
**Learn**: Example SQL queries for common analyses

**After**: You can write queries for experiment analysis.

### 3. Then: [../data-model.md](../data-model.md) (Section 5)
**Learn**: Available views for analytics

**After**: You understand the data structures.

### 4. Finally: [../../infra/metabase-setup.md](../../infra/metabase-setup.md)
**Learn**: Metabase deployment and configuration

**After**: You can set up Metabase.

---

## Supporting Documents

| Document | Purpose |
|----------|---------|
| [../../pipelines/metrics-aggregation.md](../../pipelines/metrics-aggregation.md) | How metrics are computed |
| [../../analytics/conversation-analytics.sql](../../analytics/conversation-analytics.sql) | SQL queries for conversation metrics (conversational AI) |
| [../experiments.md](../experiments.md) | Understanding experiment structure |
| [../model-promotion.md](../model-promotion.md) | Using analytics for promotion decisions |

---

## Route Outcomes

After completing this route, you will be able to:

1. ✓ Build experiment monitoring dashboards
2. ✓ Write SQL queries for experiment analysis
3. ✓ Compare variant performance
4. ✓ Track model quality over time
5. ✓ Set up alerting for metric degradation

---

## Branching Points

| If you want to... | Go to... |
|-------------------|----------|
| Build conversational AI projects | [conversational-ai-route.md](conversational-ai-route.md) |
| Understand experiments | [experiment-route.md](experiment-route.md) |
| Learn about event data | [event-logging-route.md](event-logging-route.md) |
| Promote models | [model-promotion-route.md](model-promotion-route.md) |
| Return to main docs | [../README.md](../README.md) |

