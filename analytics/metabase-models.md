# Metabase Models & Dashboards

**Purpose**  
This document specifies the required dashboards and data models for Metabase.

---

## Start Here If…

- **Analytics Route** → This is your entry point
- **Building dashboards** → Follow section 2
- **Writing queries** → Go to [example-queries.sql](example-queries.sql)

---

## 1. Required Dashboards

### 1.1 Dashboard Overview

| Dashboard | Purpose | Audience |
|-----------|---------|----------|
| Experiment Overview | Active experiments status | All |
| Variant Performance | Compare variants | Data/ML team |
| Offline vs Online | Evaluation comparison | ML team |
| Model Quality | Quality over time | ML team |
| Latency & Cost | Performance monitoring | Engineering |

---

## 2. Dashboard Specifications

### 2.1 Experiment Overview Dashboard

**Purpose**: High-level view of all active experiments

**Cards**:

1. **Active Experiments Count**
   - Type: Number
   - Query: Count of experiments where status = 'active'

2. **Experiments Table**
   - Type: Table
   - Columns: Name, Status, Start Date, Variant Count, Total Traffic

3. **Assignments by Experiment**
   - Type: Bar chart
   - X: Experiment name
   - Y: Assignment count

4. **Events by Experiment (7 days)**
   - Type: Line chart
   - X: Date
   - Y: Event count
   - Split by: Experiment

### 2.2 Variant Performance Dashboard

**Purpose**: Compare metrics across variants within an experiment

**Filters**:
- Experiment selector
- Date range

**Cards**:

1. **Variant Comparison Table**
   - Columns: Variant, Allocation, Acceptance Rate, Avg Edits, Latency (p50)

2. **Acceptance Rate Over Time**
   - Type: Line chart
   - X: Date
   - Y: Acceptance rate
   - Split by: Variant

3. **Edit Count Distribution**
   - Type: Box plot or histogram
   - X: Variant
   - Y: Edit count

4. **Latency Distribution**
   - Type: Line chart
   - X: Date
   - Y: Latency (p50, p95, p99)
   - Split by: Variant

5. **Statistical Significance**
   - Type: Table
   - Columns: Metric, Control, Treatment, Diff, P-value, Significant?

### 2.3 Offline vs Online Dashboard

**Purpose**: Compare offline evaluation predictions with online reality

**Cards**:

1. **Model Versions Table**
   - Columns: Version, Offline Score, Online Acceptance, Status

2. **Offline vs Online Correlation**
   - Type: Scatter plot
   - X: Offline alignment score
   - Y: Online acceptance rate

3. **Prediction Accuracy Over Time**
   - Type: Line chart
   - X: Model version
   - Y: Offline-Online delta

### 2.4 Model Quality Dashboard

**Purpose**: Track model quality metrics over time

**Cards**:

1. **Quality Metrics Trend**
   - Type: Line chart
   - Metrics: Alignment, Constraint Respect, Diversity
   - X: Date or Model Version

2. **Constraint Violations**
   - Type: Number (should be 0)
   - Alert if > 0

3. **Version Comparison**
   - Type: Table
   - Compare last 5 model versions

### 2.5 Latency & Cost Dashboard

**Purpose**: Monitor system performance

**Cards**:

1. **Latency Over Time**
   - Type: Line chart
   - Y: p50, p95, p99 latency
   - X: Time

2. **Token Usage**
   - Type: Line chart
   - Y: Tokens per request
   - X: Time

3. **Cost Estimate**
   - Type: Number
   - Daily/weekly cost estimate

4. **Latency by Variant**
   - Type: Box plot
   - Compare variants

---

## 3. Data Models

### 3.1 Required Views

These views should be created in PostgreSQL (see `infra/postgres-schema-overview.sql`):

| View | Purpose |
|------|---------|
| `exp.v_experiment_metrics` | Join metrics with experiment/variant names |
| `exp.v_active_experiments` | Active experiments with stats |
| `exp.v_policy_versions` | Policy versions with model info |

### 3.2 Metabase Models

Create these as Metabase models (saved questions):

**Model: Experiment Performance**
```sql
SELECT
    e.name as experiment,
    v.name as variant,
    v.allocation,
    COUNT(DISTINCT a.unit_id) as users,
    -- Add aggregated metrics
FROM exp.experiments e
JOIN exp.variants v ON v.experiment_id = e.id
LEFT JOIN exp.assignments a ON a.variant_id = v.id
WHERE e.status = 'active'
GROUP BY e.name, v.name, v.allocation
```

**Model: Daily Metrics**
```sql
SELECT
    DATE(bucket_start) as date,
    experiment_id,
    variant_id,
    metric_name,
    mean,
    count
FROM exp.metric_aggregates
WHERE bucket_type = 'daily'
```

---

## 4. Alerting

### 4.1 Required Alerts

| Alert | Condition | Action |
|-------|-----------|--------|
| Constraint Violation | constraint_respect < 1.0 | Immediate notification |
| High Latency | p99_latency > 2000ms | Notify engineering |
| Low Acceptance | acceptance_rate < baseline - 10% | Notify ML team |
| No Events | 0 events in 1 hour | Notify on-call |

### 4.2 Alert Configuration

```yaml
# Pseudo-configuration for alerts

alerts:
  - name: constraint_violations
    query: |
      SELECT COUNT(*) 
      FROM exp.metric_aggregates 
      WHERE metric_name = 'constraint_respect_score' 
      AND mean < 1.0
      AND bucket_start > NOW() - INTERVAL '1 hour'
    condition: result > 0
    channels: [slack, email]
    priority: critical

  - name: high_latency
    query: |
      SELECT mean 
      FROM exp.metric_aggregates 
      WHERE metric_name = 'latency_p99'
      ORDER BY bucket_start DESC LIMIT 1
    condition: result > 2000
    channels: [slack]
    priority: high
```

---

## 5. Access Control

### 5.1 User Groups

| Group | Access |
|-------|--------|
| Admins | Full access, can edit |
| ML Team | All dashboards, can create |
| Engineering | Latency & Cost dashboard |
| Product | Experiment Overview only |

---

## 6. TODO: Implementation Checklist

- [ ] Create PostgreSQL views
- [ ] Set up Metabase connection
- [ ] Create Experiment Overview dashboard
- [ ] Create Variant Performance dashboard
- [ ] Create Offline vs Online dashboard
- [ ] Create Model Quality dashboard
- [ ] Create Latency & Cost dashboard
- [ ] Configure alerts
- [ ] Set up scheduled reports

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [example-queries.sql](example-queries.sql) | SQL examples |
| [../infra/metabase-setup.md](../infra/metabase-setup.md) | Metabase deployment |
| [../pipelines/metrics-aggregation.md](../pipelines/metrics-aggregation.md) | Data source |

