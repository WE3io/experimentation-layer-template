# Metrics Aggregation Pipeline

**Purpose**  
This document specifies the pipeline for aggregating experiment metrics from raw events.

---

## Start Here If…

- **Event Logging Route** → Understand how events become metrics
- **Analytics Route** → Prerequisite for dashboards
- **Understanding metrics** → Read all sections

---

## 1. Pipeline Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  exp.events     │ ──► │  Aggregate by   │ ──► │ exp.metric_     │
│  (raw logs)     │     │  Experiment +   │     │ aggregates      │
│                 │     │  Variant        │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

## 2. Pipeline Steps (Pseudo-code)

### 2.1 Hourly Aggregation

```pseudo
function aggregate_hourly(window_start, window_end):
    # Query events in window
    events = db.query("""
        SELECT 
            experiments,
            metrics,
            event_type,
            timestamp
        FROM exp.events
        WHERE timestamp >= ?
        AND timestamp < ?
    """, window_start, window_end)
    
    # Group by experiment, variant, metric
    aggregates = {}
    
    for event in events:
        for exp_ctx in event.experiments:
            exp_id = exp_ctx.experiment_id
            var_id = exp_ctx.variant_id
            
            for metric_name, value in event.metrics.items():
                key = (exp_id, var_id, metric_name)
                
                if key not in aggregates:
                    aggregates[key] = {
                        "values": [],
                        "count": 0
                    }
                
                aggregates[key]["values"].append(value)
                aggregates[key]["count"] += 1
    
    # Compute statistics
    for key, data in aggregates.items():
        exp_id, var_id, metric_name = key
        values = data["values"]
        
        db.upsert("exp.metric_aggregates", {
            "experiment_id": exp_id,
            "variant_id": var_id,
            "metric_name": metric_name,
            "bucket_type": "hourly",
            "bucket_start": window_start,
            "count": len(values),
            "sum": sum(values),
            "mean": mean(values),
            "min": min(values),
            "max": max(values),
            "stddev": stddev(values)
        })
```

### 2.2 Daily Rollup

```pseudo
function aggregate_daily(date):
    # Roll up hourly aggregates to daily
    db.execute("""
        INSERT INTO exp.metric_aggregates (
            experiment_id, variant_id, metric_name,
            bucket_type, bucket_start,
            count, sum, mean, min, max, stddev
        )
        SELECT
            experiment_id,
            variant_id,
            metric_name,
            'daily' as bucket_type,
            DATE_TRUNC('day', bucket_start) as bucket_start,
            SUM(count) as count,
            SUM(sum) as sum,
            SUM(sum) / SUM(count) as mean,
            MIN(min) as min,
            MAX(max) as max,
            -- Approximate combined stddev
            SQRT(SUM(count * (stddev * stddev + mean * mean)) / SUM(count) 
                 - POWER(SUM(sum) / SUM(count), 2)) as stddev
        FROM exp.metric_aggregates
        WHERE bucket_type = 'hourly'
        AND bucket_start >= ?
        AND bucket_start < ? + INTERVAL '1 day'
        GROUP BY experiment_id, variant_id, metric_name,
                 DATE_TRUNC('day', bucket_start)
        ON CONFLICT (experiment_id, variant_id, metric_name, bucket_type, bucket_start)
        DO UPDATE SET
            count = EXCLUDED.count,
            sum = EXCLUDED.sum,
            mean = EXCLUDED.mean,
            min = EXCLUDED.min,
            max = EXCLUDED.max,
            stddev = EXCLUDED.stddev
    """, date, date)
```

---

## 3. Metrics Collected

### 3.1 Standard Metrics

| Metric | Source | Description |
|--------|--------|-------------|
| `latency_ms` | plan_generated | Response time |
| `token_count` | plan_generated | LLM tokens used |
| `acceptance_rate` | Computed | plan_accepted / plan_generated |
| `edit_count` | edit_applied | User edits per plan |

### 3.2 Computed Metrics

```pseudo
function compute_derived_metrics(experiment_id, variant_id, date):
    # Acceptance rate
    generated = get_count("plan_generated", experiment_id, variant_id, date)
    accepted = get_count("plan_accepted", experiment_id, variant_id, date)
    
    acceptance_rate = accepted / generated if generated > 0 else 0
    
    store_metric(experiment_id, variant_id, "acceptance_rate", acceptance_rate, date)
    
    # Average edits per plan
    plans = get_count("plan_accepted", experiment_id, variant_id, date)
    edits = get_count("edit_applied", experiment_id, variant_id, date)
    
    avg_edits = edits / plans if plans > 0 else 0
    
    store_metric(experiment_id, variant_id, "avg_edits_per_plan", avg_edits, date)
```

---

## 4. Scheduling

### 4.1 Hourly Job

```pseudo
# Runs every hour at :05
# Processes previous hour's data

schedule: "5 * * * *"

def hourly_aggregation():
    now = get_current_time()
    window_start = now.floor('hour') - timedelta(hours=1)
    window_end = window_start + timedelta(hours=1)
    
    aggregate_hourly(window_start, window_end)
```

### 4.2 Daily Job

```pseudo
# Runs daily at 01:00
# Rolls up previous day's hourly data

schedule: "0 1 * * *"

def daily_aggregation():
    yesterday = get_current_date() - timedelta(days=1)
    aggregate_daily(yesterday)
    compute_derived_metrics_daily(yesterday)
```

---

## 5. Data Retention

### 5.1 Retention Policy

| Bucket Type | Retention |
|-------------|-----------|
| Hourly | 30 days |
| Daily | 1 year |

### 5.2 Cleanup Job

```pseudo
# Runs weekly

def cleanup_old_aggregates():
    # Delete hourly aggregates older than 30 days
    db.execute("""
        DELETE FROM exp.metric_aggregates
        WHERE bucket_type = 'hourly'
        AND bucket_start < NOW() - INTERVAL '30 days'
    """)
```

---

## 6. Querying Aggregates

### 6.1 Example: Daily Comparison

```sql
SELECT
    e.name as experiment,
    v.name as variant,
    m.bucket_start::date as date,
    m.mean as avg_latency
FROM exp.metric_aggregates m
JOIN exp.variants v ON v.id = m.variant_id
JOIN exp.experiments e ON e.id = m.experiment_id
WHERE m.metric_name = 'latency_ms'
AND m.bucket_type = 'daily'
AND m.bucket_start >= NOW() - INTERVAL '7 days'
ORDER BY e.name, v.name, m.bucket_start;
```

---

## 7. TODO: Implementation Notes

- [ ] Implement hourly aggregation job
- [ ] Implement daily rollup job
- [ ] Add derived metrics computation
- [ ] Set up retention cleanup
- [ ] Configure monitoring

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [../docs/event-ingestion-service.md](../docs/event-ingestion-service.md) | Event structure |
| [../analytics/metabase-models.md](../analytics/metabase-models.md) | Dashboards |
| [../analytics/example-queries.sql](../analytics/example-queries.sql) | SQL examples |

