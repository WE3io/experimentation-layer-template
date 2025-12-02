# Assignment Service Design

**Purpose**  
This document describes the internal design and architecture decisions for the Experiment Assignment Service (EAS).

---

## Start Here If…

- **Implementing the service** → Read this document
- **Calling the service** → Go to [API_SPEC.md](API_SPEC.md)
- **Understanding experiments** → Go to [../../docs/experiments.md](../../docs/experiments.md)

---

## 1. Service Overview

### 1.1 Responsibilities

| Responsibility | Description |
|----------------|-------------|
| Variant Assignment | Determine which variant a unit receives |
| Config Delivery | Return variant configuration |
| Assignment Persistence | Store assignments for consistency |
| Caching | Reduce database load |

### 1.2 Non-Responsibilities

| Not Responsible For | Handled By |
|---------------------|------------|
| Event logging | Event Ingestion Service |
| Model loading | Planner service |
| Metrics aggregation | Offline pipelines |

---

## 2. Architecture

### 2.1 Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                  Assignment Service                          │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   API Layer  │ ──►│   Business   │ ──►│   Data       │  │
│  │              │    │   Logic      │    │   Access     │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│                              │                    │         │
│                              ▼                    ▼         │
│                       ┌──────────────┐    ┌──────────────┐ │
│                       │   Cache      │    │   Database   │ │
│                       │   (Redis)    │    │   (Postgres) │ │
│                       └──────────────┘    └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow

```
1. Request arrives at API layer
2. API validates request
3. Business logic checks cache for existing assignment
4. If cache miss: query database
5. If no assignment: compute new assignment
6. Persist new assignment to database
7. Update cache
8. Return assignment with config
```

---

## 3. Assignment Algorithm

### 3.1 Hash-Based Bucketing

```pseudo
function compute_bucket(experiment_id, unit_id):
    # Concatenate identifiers
    hash_input = f"{experiment_id}:{unit_id}"
    
    # Use stable hash algorithm (SHA-256 recommended)
    hash_bytes = sha256(hash_input.encode())
    hash_int = int.from_bytes(hash_bytes[:8], 'big')
    
    # Map to bucket (0-9999 for 0.01% granularity)
    bucket = hash_int % 10000
    
    return bucket
```

### 3.2 Variant Selection

```pseudo
function select_variant(bucket, variants):
    # Variants sorted by creation order
    cumulative = 0
    
    for variant in variants:
        cumulative += int(variant.allocation * 10000)
        if bucket < cumulative:
            return variant
    
    # Fallback to last variant (should not happen if allocations sum to 1.0)
    return variants[-1]
```

### 3.3 Algorithm Properties

| Property | Implementation |
|----------|----------------|
| Deterministic | SHA-256 hash of fixed input |
| Uniform | Hash distribution is uniform |
| Stable | Same input always gives same output |
| Collision-resistant | 64-bit hash space |

---

## 4. Caching Strategy

### 4.1 Cache Key Format

```
assignment:{experiment_id}:{unit_id}
```

### 4.2 Cache Value

```json
{
  "variant_id": "uuid",
  "variant_name": "variant_a",
  "config": { ... },
  "cached_at": "2025-01-01T10:00:00Z"
}
```

### 4.3 TTL Strategy

| Scenario | TTL |
|----------|-----|
| Normal | 1 hour |
| High traffic | 15 minutes |
| After experiment change | Invalidate all |

### 4.4 Cache Invalidation

```pseudo
function invalidate_experiment_cache(experiment_id):
    # Pattern-based deletion
    pattern = f"assignment:{experiment_id}:*"
    keys = redis.scan(pattern)
    redis.delete(*keys)
```

---

## 5. Database Schema Usage

### 5.1 Tables Accessed

| Table | Access Pattern |
|-------|----------------|
| `exp.experiments` | Read by name |
| `exp.variants` | Read by experiment_id |
| `exp.assignments` | Read/Write by (experiment_id, unit_id) |

### 5.2 Indexes Required

```sql
-- For experiment lookup
CREATE INDEX idx_experiments_name ON exp.experiments(name);

-- For variant lookup
CREATE INDEX idx_variants_experiment ON exp.variants(experiment_id);

-- For assignment lookup
CREATE UNIQUE INDEX idx_assignments_lookup 
    ON exp.assignments(experiment_id, unit_id);
```

---

## 6. Error Handling

### 6.1 Error Categories

| Category | Response | Action |
|----------|----------|--------|
| Validation error | 400 | Return error details |
| Experiment not found | 200 | Omit from response |
| Database error | 503 | Retry logic |
| Cache error | N/A | Fallback to database |

### 6.2 Retry Strategy

```pseudo
# Database retry
max_retries = 3
backoff_base = 100ms

for attempt in range(max_retries):
    try:
        return execute_query(...)
    except DatabaseError:
        sleep(backoff_base * (2 ** attempt))

raise ServiceUnavailable()
```

---

## 7. Performance Considerations

### 7.1 Expected Latency

| Operation | Target P50 | Target P99 |
|-----------|------------|------------|
| Cache hit | <5ms | <20ms |
| Cache miss | <50ms | <200ms |
| New assignment | <100ms | <500ms |

### 7.2 Throughput

| Metric | Target |
|--------|--------|
| RPS per instance | 1000 |
| Concurrent connections | 100 |

### 7.3 Optimization Strategies

- Connection pooling for database
- Pipeline Redis commands
- Batch experiment lookups

---

## 8. Monitoring

### 8.1 Metrics to Expose

| Metric | Type | Labels |
|--------|------|--------|
| `assignment_requests_total` | Counter | status, experiment |
| `assignment_latency_seconds` | Histogram | experiment |
| `cache_hits_total` | Counter | |
| `cache_misses_total` | Counter | |
| `new_assignments_total` | Counter | experiment |

### 8.2 Alerting Rules

```pseudo
# High error rate
if error_rate > 1%:
    alert("Assignment service error rate high")

# High latency
if p99_latency > 500ms:
    alert("Assignment service latency degraded")
```

---

## 9. Security Considerations

### 9.1 Input Validation

```pseudo
function validate_request(request):
    # Unit ID format
    if not valid_unit_id(request.unit_id):
        raise ValidationError("Invalid unit_id format")
    
    # Experiment names
    for exp_name in request.requested_experiments:
        if not valid_experiment_name(exp_name):
            raise ValidationError("Invalid experiment name")
```

### 9.2 Rate Limiting

```pseudo
# Per-unit rate limit
limit = 100 requests per minute per unit_id

if rate_limiter.exceeded(request.unit_id):
    return 429 Too Many Requests
```

---

## 10. TODO: Implementation Notes

- [ ] Choose web framework (e.g., FastAPI, Express, Go Gin)
- [ ] Implement Redis caching layer
- [ ] Set up connection pooling
- [ ] Add Prometheus metrics
- [ ] Configure rate limiting
- [ ] Write integration tests

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [API_SPEC.md](API_SPEC.md) | API specification |
| [../../docs/experiments.md](../../docs/experiments.md) | Experiment concepts |
| [../../docs/data-model.md](../../docs/data-model.md) | Database schema |

