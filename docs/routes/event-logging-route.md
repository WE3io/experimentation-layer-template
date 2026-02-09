# Event Logging Route

**Purpose**  
This route guides developers who want to understand and work with event logging and metrics aggregation.

---

## Route Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ event-ingestion │ ──► │ data-model.md   │ ──► │ metrics-        │
│ -service.md     │     │ (events)        │     │ aggregation.md  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

## Documents in This Route

### 1. Start Here: [../event-ingestion-service.md](../event-ingestion-service.md)
**Learn**: Event Ingestion Service purpose and API

**After**: You understand how events flow into the system.

### 2. Next: [../../services/event-ingestion-service/DESIGN.md](../../services/event-ingestion-service/DESIGN.md)
**Learn**: Implementation design for the Event Ingestion Service

**After**: You understand internal architecture decisions.

### 3. Then: [../data-model.md](../data-model.md) (Section 2)
**Learn**: exp.events table structure (supports both ML events and conversation events)

**After**: You understand how events are stored.

### 4. Finally: [../../pipelines/metrics-aggregation.md](../../pipelines/metrics-aggregation.md)
**Learn**: How events become aggregated metrics

**After**: You understand the pipeline from raw events to dashboard-ready data.

---

## Supporting Documents

| Document | Purpose |
|----------|---------|
| [../../services/event-ingestion-service/API_SPEC.md](../../services/event-ingestion-service/API_SPEC.md) | Full API specification (supports conversation events) |
| [../../analytics/example-queries.sql](../../analytics/example-queries.sql) | Example event queries |
| [../../analytics/conversation-analytics.sql](../../analytics/conversation-analytics.sql) | Conversation event queries (conversational AI) |
| [../../analytics/metabase-models.md](../../analytics/metabase-models.md) | Visualising event data |

---

## Route Outcomes

After completing this route, you will be able to:

1. ✓ Log events with correct structure
2. ✓ Include experiment context in events
3. ✓ Understand event storage and retention
4. ✓ Query raw and aggregated events
5. ✓ Debug event logging issues

---

## Branching Points

| If you want to... | Go to... |
|-------------------|----------|
| Build conversational AI projects | [conversational-ai-route.md](conversational-ai-route.md) |
| Configure experiments | [experiment-route.md](experiment-route.md) |
| Use events for training | [training-route.md](training-route.md) |
| Build dashboards | [analytics-route.md](analytics-route.md) |
| Return to main docs | [../README.md](../README.md) |

