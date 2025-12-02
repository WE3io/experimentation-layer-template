# Event Ingestion Service Overview

**Purpose**  
This document describes the Event Ingestion Service (EIS), which captures and stores event logs with experiment context.

---

## Start Here If…

- **Full sequential workflow** → Continue from [assignment-service.md](assignment-service.md)
- **Event Logging Route** → This is your entry point
- **API details** → Go to [../services/event-ingestion-service/API_SPEC.md](../services/event-ingestion-service/API_SPEC.md)
- **Implementation design** → Go to [../services/event-ingestion-service/DESIGN.md](../services/event-ingestion-service/DESIGN.md)

---

## 1. Service Purpose

The Event Ingestion Service (EIS) is responsible for:

1. **Event Recording** – Capturing in-product actions
2. **Context Attachment** – Including experiment and variant IDs
3. **Validation** – Ensuring event completeness
4. **Storage** – Writing to PostgreSQL and object storage
5. **Metrics Foundation** – Providing data for aggregation pipelines

---

## 2. Core Responsibilities

### 2.1 Event Capture

Records all significant in-product actions:
- Plan generation
- Plan acceptance
- Meal swaps
- User edits
- Validator interventions

### 2.2 Experiment Context

Every event MUST include:
- `experiment_id` – Which experiment the user is in
- `variant_id` – Which variant they received
- `policy_version_id` – Which model version was used

### 2.3 Metrics Logging

Events include measurable quantities:
- `latency_ms` – Response time
- `token_count` – LLM tokens used
- `edit_count` – Number of user edits
- Custom business metrics

---

## 3. API Overview

### 3.1 Request Flow

```
Backend/Client
     │
     ▼
┌─────────────────────────────────────┐
│  POST /events                        │
│  {                                   │
│    event_type: "plan_generated",     │
│    unit_type: "user",                │
│    unit_id: "user-123",              │
│    experiments: [...],               │
│    context: {...},                   │
│    metrics: {...},                   │
│    timestamp: "..."                  │
│  }                                   │
└─────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────┐
│  Validation                          │
│  1. Required fields present          │
│  2. Experiment IDs valid             │
│  3. Timestamp valid                  │
└─────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────┐
│  Storage                             │
│  1. Write to exp.events              │
│  2. Write to object storage (async)  │
└─────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────┐
│  Response                            │
│  { event_id: "uuid", status: "ok" }  │
└─────────────────────────────────────┘
```

### 3.2 Request Schema

```json
{
  "event_type": "plan_generated",
  "unit_type": "user",
  "unit_id": "user-123",
  "experiments": [
    {
      "experiment_id": "uuid-exp",
      "variant_id": "uuid-var"
    }
  ],
  "context": {
    "policy_version_id": "uuid-policy-version",
    "app_version": "1.2.3",
    "platform": "ios"
  },
  "metrics": {
    "latency_ms": 450,
    "token_count": 1200
  },
  "payload": {
    "plan_id": "uuid-plan",
    "meal_count": 7
  },
  "timestamp": "2025-01-01T10:00:00Z"
}
```

### 3.3 Response Schema

```json
{
  "event_id": "uuid-event",
  "status": "accepted"
}
```

---

## 4. Event Types

### 4.1 Standard Event Types

| Event Type | Description | Required Context |
|------------|-------------|------------------|
| `plan_generated` | Plan was created | policy_version_id |
| `plan_accepted` | User accepted plan | plan_id |
| `plan_rejected` | User rejected plan | plan_id, rejection_reason |
| `meal_swapped` | User swapped a meal | meal_id, new_meal_id |
| `edit_applied` | User made an edit | edit_type, edit_details |
| `validator_intervention` | Validator modified output | intervention_type |

### 4.2 Custom Event Types

Define project-specific events as needed:

```json
{
  "event_type": "pantry_updated",
  "payload": {
    "items_added": 5,
    "items_removed": 2
  }
}
```

---

## 5. Validation Rules

### 5.1 Required Fields

```pseudo
required_fields = [
    "event_type",
    "unit_type", 
    "unit_id",
    "timestamp"
]

if any field missing:
    return 400 Bad Request
```

### 5.2 Experiment Context Validation

```pseudo
if experiments is empty:
    log_warning("Event without experiment context")
    # Allow but flag for review

for exp in experiments:
    if not valid_uuid(exp.experiment_id):
        return 400 Bad Request
    if not valid_uuid(exp.variant_id):
        return 400 Bad Request
```

### 5.3 Timestamp Validation

```pseudo
if timestamp > now() + 5 minutes:
    return 400 Bad Request  # Future timestamps not allowed

if timestamp < now() - 7 days:
    log_warning("Old timestamp")
    # Allow but flag
```

---

## 6. Storage Strategy

### 6.1 PostgreSQL (Primary)

All events written to `exp.events`:

```sql
INSERT INTO exp.events (
    event_type,
    unit_type,
    unit_id,
    experiments,
    context,
    metrics,
    payload,
    timestamp
) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
```

### 6.2 Object Storage (Archival)

Async job writes to S3/MinIO:

```
s3://events/{year}/{month}/{day}/{hour}/events_{batch_id}.parquet
```

### 6.3 Retention

| Store | Retention |
|-------|-----------|
| PostgreSQL | 90 days |
| Object Storage | Indefinite |

---

## 7. Integration Points

### 7.1 Upstream (Callers)

- **Backend API** – Logs events after operations
- **Planner** – Logs plan generation events
- **Frontend** – Logs user interactions (via backend)

### 7.2 Downstream (Consumers)

- **Metrics Aggregation Pipeline** – Reads events for summaries
- **Training Pipeline** – Reads events for dataset generation
- **Metabase** – Queries events for dashboards

---

## 8. Batch Ingestion

### 8.1 Batch Request

```json
{
  "events": [
    { "event_type": "...", ... },
    { "event_type": "...", ... }
  ]
}
```

### 8.2 Batch Response

```json
{
  "accepted": 98,
  "rejected": 2,
  "errors": [
    { "index": 5, "error": "missing_timestamp" },
    { "index": 12, "error": "invalid_experiment_id" }
  ]
}
```

---

## 9. Error Handling

### 9.1 Validation Errors (400)

Return immediately; event not stored.

### 9.2 Storage Errors (503)

Retry with exponential backoff; use dead-letter queue for failures.

### 9.3 Partial Failures (207)

In batch mode, return status per event.

---

## 10. Related Documentation

| Document | Purpose |
|----------|---------|
| [../services/event-ingestion-service/DESIGN.md](../services/event-ingestion-service/DESIGN.md) | Implementation design |
| [../services/event-ingestion-service/API_SPEC.md](../services/event-ingestion-service/API_SPEC.md) | Full API specification |
| [data-model.md](data-model.md) | exp.events schema |
| [../pipelines/metrics-aggregation.md](../pipelines/metrics-aggregation.md) | Metrics pipeline |

---

## After Completing This Document

You will understand:
- The role of the Event Ingestion Service
- Event structure and required fields
- Validation rules
- Storage strategy
- Integration with other components

**Next Step**: [mlflow-guide.md](mlflow-guide.md)

