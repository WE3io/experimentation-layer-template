# Event Ingestion Service Design

**Purpose**  
This document describes the internal design and architecture decisions for the Event Ingestion Service (EIS).

---

## Start Here If…

- **Implementing the service** → Read this document
- **Calling the service** → Go to [API_SPEC.md](API_SPEC.md)
- **Understanding events** → Go to [../../docs/event-ingestion-service.md](../../docs/event-ingestion-service.md)

---

## 1. Service Overview

### 1.1 Responsibilities

| Responsibility | Description |
|----------------|-------------|
| Event Ingestion | Accept and validate incoming events |
| Storage | Write to PostgreSQL and object storage |
| Batching | Efficiently handle high-volume writes |
| Validation | Ensure event completeness and correctness |

### 1.2 Non-Responsibilities

| Not Responsible For | Handled By |
|---------------------|------------|
| Variant assignment | Assignment Service |
| Metrics aggregation | Offline pipelines |
| Dashboard rendering | Metabase |

---

## 2. Architecture

### 2.1 Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                 Event Ingestion Service                      │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   API Layer  │ ──►│   Validator  │ ──►│   Writer     │  │
│  │              │    │              │    │              │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│                                                 │           │
│                              ┌──────────────────┼───────┐   │
│                              ▼                  ▼       │   │
│                       ┌──────────────┐  ┌────────────┐ │   │
│                       │  PostgreSQL  │  │   Queue    │ │   │
│                       │  (Primary)   │  │  (Buffer)  │ │   │
│                       └──────────────┘  └────────────┘ │   │
│                                                │       │   │
│                                                ▼       │   │
│                                         ┌────────────┐ │   │
│                                         │ S3/MinIO   │ │   │
│                                         │ (Archive)  │ │   │
│                                         └────────────┘ │   │
│                              └─────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow

```
1. Request arrives at API layer
2. API performs basic validation
3. Validator checks event structure and content
4. Writer persists to PostgreSQL (sync)
5. Writer queues for S3 archival (async)
6. Background worker writes to S3 in batches
7. Response returned to caller
```

---

## 3. Event Validation

### 3.1 Validation Rules

```pseudo
function validate_event(event):
    errors = []
    
    # Required fields
    if not event.event_type:
        errors.append("event_type required")
    if not event.unit_type:
        errors.append("unit_type required")
    if not event.unit_id:
        errors.append("unit_id required")
    if not event.timestamp:
        errors.append("timestamp required")
    
    # Format validation
    if not valid_event_type(event.event_type):
        errors.append("invalid event_type format")
    if not valid_unit_type(event.unit_type):
        errors.append("invalid unit_type")
    if not valid_timestamp(event.timestamp):
        errors.append("invalid timestamp format")
    
    # Experiment context validation
    if event.experiments:
        for exp in event.experiments:
            if not valid_uuid(exp.experiment_id):
                errors.append("invalid experiment_id")
            if not valid_uuid(exp.variant_id):
                errors.append("invalid variant_id")
    
    # Timestamp sanity
    if event.timestamp > now() + 5 minutes:
        errors.append("timestamp in future")
    
    return errors
```

### 3.2 Event Type Registry

```pseudo
VALID_EVENT_TYPES = [
    "plan_generated",
    "plan_accepted",
    "plan_rejected",
    "meal_swapped",
    "edit_applied",
    "validator_intervention",
    # Add custom types here
]

function valid_event_type(event_type):
    # Allow registered types
    if event_type in VALID_EVENT_TYPES:
        return True
    
    # Allow custom types with prefix
    if event_type.startswith("custom."):
        return True
    
    return False
```

---

## 4. Storage Strategy

### 4.1 PostgreSQL (Primary)

Synchronous write for immediate availability:

```pseudo
function write_to_postgres(event):
    db.insert("exp.events", {
        "id": generate_uuid(),
        "event_type": event.event_type,
        "unit_type": event.unit_type,
        "unit_id": event.unit_id,
        "experiments": json.dumps(event.experiments),
        "context": json.dumps(event.context),
        "metrics": json.dumps(event.metrics),
        "payload": json.dumps(event.payload),
        "timestamp": event.timestamp,
        "created_at": now()
    })
```

### 4.2 Object Storage (Archive)

Asynchronous batch write for long-term storage:

```pseudo
# Queue event for archival
function queue_for_archive(event):
    queue.push("events:archive", event)

# Background worker
function archive_worker():
    while True:
        batch = queue.pop_batch("events:archive", size=1000, timeout=60)
        
        if batch:
            # Convert to parquet
            df = to_dataframe(batch)
            parquet_bytes = to_parquet(df)
            
            # Write to S3
            key = f"events/{year}/{month}/{day}/{hour}/batch_{uuid}.parquet"
            s3.put_object(bucket, key, parquet_bytes)
```

### 4.3 Retention Policy

| Store | Retention | Purpose |
|-------|-----------|---------|
| PostgreSQL | 90 days | Hot queries |
| S3/MinIO | Indefinite | Training data, auditing |

---

## 5. Batch Ingestion

### 5.1 Batch Processing

```pseudo
function process_batch(events):
    results = {
        "accepted": 0,
        "rejected": 0,
        "errors": []
    }
    
    # Validate all events first
    valid_events = []
    for i, event in enumerate(events):
        errors = validate_event(event)
        if errors:
            results["rejected"] += 1
            results["errors"].append({
                "index": i,
                "errors": errors
            })
        else:
            valid_events.append(event)
    
    # Batch insert valid events
    if valid_events:
        db.insert_batch("exp.events", valid_events)
        results["accepted"] = len(valid_events)
        
        # Queue all for archival
        for event in valid_events:
            queue_for_archive(event)
    
    return results
```

### 5.2 Batch Limits

| Limit | Value | Reason |
|-------|-------|--------|
| Max batch size | 1000 events | Memory constraints |
| Max payload size | 10MB | Network constraints |
| Timeout | 30 seconds | Connection limits |

---

## 6. Error Handling

### 6.1 Error Categories

| Category | Response | Recovery |
|----------|----------|----------|
| Validation error | 400 | Return details |
| Partial failure (batch) | 207 | Return per-event status |
| Database error | 503 | Retry with backoff |
| Queue error | 200 | Log warning, continue |

### 6.2 Dead Letter Queue

```pseudo
function handle_failed_archive(event, error):
    # Write to dead letter queue
    dlq.push("events:dlq", {
        "event": event,
        "error": str(error),
        "timestamp": now(),
        "retries": 0
    })

# DLQ processor
function process_dlq():
    while True:
        item = dlq.pop("events:dlq")
        if item and item.retries < 3:
            try:
                archive_event(item.event)
            except Exception as e:
                item.retries += 1
                dlq.push("events:dlq", item)
```

---

## 7. Performance Considerations

### 7.1 Expected Latency

| Operation | Target P50 | Target P99 |
|-----------|------------|------------|
| Single event | <20ms | <100ms |
| Batch (100 events) | <100ms | <500ms |
| Batch (1000 events) | <500ms | <2s |

### 7.2 Throughput

| Metric | Target |
|--------|--------|
| Events per second | 10,000 |
| Concurrent connections | 200 |

### 7.3 Optimization Strategies

- Connection pooling for database
- Prepared statements
- Batch inserts (multi-row INSERT)
- Async S3 writes

---

## 8. Monitoring

### 8.1 Metrics to Expose

| Metric | Type | Labels |
|--------|------|--------|
| `events_received_total` | Counter | event_type, status |
| `events_ingestion_latency_seconds` | Histogram | event_type |
| `events_batch_size` | Histogram | |
| `events_validation_errors_total` | Counter | error_type |
| `archive_queue_size` | Gauge | |

### 8.2 Alerting Rules

```pseudo
# High error rate
if validation_error_rate > 5%:
    alert("High event validation error rate")

# Queue backup
if archive_queue_size > 100000:
    alert("Event archive queue backing up")

# Database latency
if p99_insert_latency > 500ms:
    alert("Event ingestion latency degraded")
```

---

## 9. Security Considerations

### 9.1 Input Sanitization

```pseudo
function sanitize_event(event):
    # Limit string lengths
    event.event_type = truncate(event.event_type, 100)
    event.unit_id = truncate(event.unit_id, 255)
    
    # Limit payload size
    if sizeof(event.payload) > 1MB:
        raise PayloadTooLarge()
    
    # Remove sensitive fields
    if event.context.get("password"):
        del event.context["password"]
    
    return event
```

### 9.2 Rate Limiting

```pseudo
# Per-unit rate limit
limit = 1000 events per minute per unit_id

if rate_limiter.exceeded(event.unit_id):
    return 429 Too Many Requests
```

---

## 11. Security and PII Handling

The Event Ingestion Service is responsible for ensuring that sensitive Personal Identifiable Information (PII) is not persisted in plain text or leaked into downstream analytics.

### 11.1 PII Identification and Masking

The service maintains a list of sensitive fields that must be masked or hashed before storage.

| Data Type | Handling Strategy | Examples |
|-----------|-------------------|----------|
| User Email | SHA-256 Hash | `user@example.com` -> `5e88...` |
| IP Address | Anonymization (last octet) | `192.168.1.1` -> `192.168.1.0` |
| Geo Location | Rounding (1 decimal place) | `45.1234, -122.5678` -> `45.1, -122.6` |
| Precise Names | Drop from payload | `John Doe` -> (removed) |

### 11.2 Ingestion-Time Filtering

The `Validator` component performs PII filtering before the `Writer` persists data to either PostgreSQL or S3.

```pseudo
function filter_pii(payload):
    sensitive_keys = ["email", "phone", "first_name", "last_name", "full_name"]
    for key in sensitive_keys:
        if key in payload:
            # Option 1: Hash the value (if needed for joining)
            payload[key] = hash_sha256(payload[key])
            # Option 2: Mask the value
            # payload[key] = "[MASKED]"
            # Option 3: Remove the value
            # del payload[key]
    return payload
```

### 11.3 Access Control

- **Ingestion Tokens:** Every client must use a unique Bearer token with appropriate scopes.
- **Internal Access:** Only authorized services (e.g., training pipelines) can access raw events in S3.
- **Analytics:** Metabase access is restricted to aggregated or anonymized views.

---

## 12. TODO: Implementation Notes

- [ ] Choose web framework (e.g., FastAPI, Express, Go Gin)
- [ ] Implement batch insert optimization
- [ ] Set up S3 archival worker
- [ ] Add Prometheus metrics
- [ ] Configure dead letter queue
- [ ] Write integration tests
- [ ] Set up retention policy automation

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [API_SPEC.md](API_SPEC.md) | API specification |
| [../../docs/event-ingestion-service.md](../../docs/event-ingestion-service.md) | Service overview |
| [../../docs/data-model.md](../../docs/data-model.md) | Database schema |

