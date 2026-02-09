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
| Conversation Analytics | Chatbot metrics and flows | Conversational AI team |

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

### 2.5 Conversation Analytics Dashboard

**Purpose**: Monitor conversation flows, completion rates, and user engagement for chatbot experiments

**Filters**:
- Experiment selector (conversational AI experiments)
- Flow selector
- Date range

**Cards**:

1. **Conversation Metrics Overview**
   - Type: Number cards
   - Metrics: Total Conversations Started, Completion Rate, Avg Turn Count, Avg Duration

2. **Completion Rate by Flow**
   - Type: Bar chart
   - X: Flow ID
   - Y: Completion rate (%)
   - Split by: Variant (optional)

3. **Funnel Analysis**
   - Type: Funnel chart
   - Steps: conversation_started → message_sent (N turns) → flow_completed
   - Shows drop-off at each stage

4. **Turn Count Distribution**
   - Type: Histogram
   - X: Number of turns
   - Y: Count of conversations
   - Split by: Variant

5. **Time to Completion**
   - Type: Line chart
   - X: Date
   - Y: Average time to completion (seconds)
   - Split by: Variant

6. **Drop-off Analysis**
   - Type: Table
   - Columns: Flow ID, Last Active State, Drop-off Count, Drop-off Rate, Avg Progress

7. **Drop-off Heatmap**
   - Type: Heatmap
   - X: Flow states
   - Y: Variants
   - Color: Drop-off rate

8. **Variant Comparison Table**
   - Columns: Variant, Completion Rate, Avg Turns, Avg Duration, Drop-off Rate

9. **Conversation Events Timeline**
   - Type: Line chart
   - X: Time (hour of day)
   - Y: Event count
   - Split by: Event type (conversation_started, message_sent, flow_completed, user_dropped_off)

10. **Satisfaction Scores** (if available)
    - Type: Bar chart
    - X: Variant
    - Y: Average satisfaction score

### 2.6 Latency & Cost Dashboard

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

**Model: Conversation Sessions**
```sql
SELECT
    e.id as event_id,
    e.event_type,
    e.unit_id,
    e.timestamp,
    e.context->>'session_id' as session_id,
    e.context->>'flow_id' as flow_id,
    e.context->>'flow_version' as flow_version,
    e.context->>'current_state' as current_state,
    e.metrics->>'turn_number' as turn_number,
    e.metrics->>'total_turns' as total_turns,
    e.metrics->>'total_duration_seconds' as total_duration_seconds,
    e.metrics->>'completion_rate' as completion_rate,
    e.experiments
FROM exp.events e
WHERE e.event_type IN ('conversation_started', 'message_sent', 'flow_completed', 'user_dropped_off')
```

**Model: Conversation Funnel**
```sql
WITH conversation_events AS (
    SELECT
        e.context->>'session_id' as session_id,
        e.context->>'flow_id' as flow_id,
        e.event_type,
        e.timestamp,
        e.experiments->0->>'experiment_id' as experiment_id,
        e.experiments->0->>'variant_id' as variant_id
    FROM exp.events e
    WHERE e.event_type IN ('conversation_started', 'message_sent', 'flow_completed', 'user_dropped_off')
      AND e.context->>'session_id' IS NOT NULL
)
SELECT
    session_id,
    flow_id,
    experiment_id,
    variant_id,
    MAX(CASE WHEN event_type = 'conversation_started' THEN timestamp END) as started_at,
    MAX(CASE WHEN event_type = 'flow_completed' THEN timestamp END) as completed_at,
    MAX(CASE WHEN event_type = 'user_dropped_off' THEN timestamp END) as dropped_off_at,
    COUNT(CASE WHEN event_type = 'message_sent' THEN 1 END) as message_count,
    CASE 
        WHEN MAX(CASE WHEN event_type = 'flow_completed' THEN 1 END) = 1 THEN 'completed'
        WHEN MAX(CASE WHEN event_type = 'user_dropped_off' THEN 1 END) = 1 THEN 'dropped_off'
        ELSE 'in_progress'
    END as status
FROM conversation_events
GROUP BY session_id, flow_id, experiment_id, variant_id
```

**Model: Flow Drop-off Points**
```sql
SELECT
    e.context->>'flow_id' as flow_id,
    e.context->>'current_state' as last_active_state,
    e.experiments->0->>'variant_id' as variant_id,
    COUNT(*) as drop_off_count,
    AVG((e.payload->>'progress')::float) as avg_progress,
    AVG((e.metrics->>'total_turns')::integer) as avg_turns_before_drop_off
FROM exp.events e
WHERE e.event_type = 'user_dropped_off'
GROUP BY flow_id, last_active_state, variant_id
ORDER BY drop_off_count DESC
```

---

## 4. Conversation Metrics

### 4.1 Core Conversation Metrics

**Completion Rate:**
- Definition: Percentage of conversations that reach `flow_completed` event
- Calculation: `COUNT(flow_completed) / COUNT(conversation_started) * 100`
- Use case: Primary success metric for conversation flows

**Average Turn Count:**
- Definition: Average number of message exchanges per conversation
- Calculation: `AVG(total_turns)` from `flow_completed` or `user_dropped_off` events
- Use case: Measure conversation efficiency

**Time to Completion:**
- Definition: Average duration from `conversation_started` to `flow_completed`
- Calculation: `AVG(total_duration_seconds)` from `flow_completed` events
- Use case: Measure user experience and flow efficiency

**Drop-off Rate:**
- Definition: Percentage of conversations that end with `user_dropped_off`
- Calculation: `COUNT(user_dropped_off) / COUNT(conversation_started) * 100`
- Use case: Identify problematic flows or states

**Drop-off Points:**
- Definition: States where users most frequently drop off
- Calculation: Group `user_dropped_off` events by `last_active_state`
- Use case: Identify bottlenecks in conversation flows

### 4.2 Funnel Analysis Setup

**Purpose**: Track user progression through conversation flows

**Funnel Steps**:
1. **Started**: `conversation_started` events
2. **Engaged**: `message_sent` events (at least 1 turn)
3. **Progressed**: `message_sent` events (at least N turns, where N is flow-specific)
4. **Completed**: `flow_completed` events

**Metabase Funnel Configuration**:
- Use the "Conversation Funnel" model
- Group by: `flow_id`, `variant_id`
- Filter by: `experiment_id`, date range
- Calculate conversion rates between steps

**Example Funnel Query**:
```sql
-- See "Model: Conversation Funnel" in section 3.2
-- This model provides session-level aggregation for funnel analysis
```

### 4.3 Drop-off Analysis Setup

**Purpose**: Identify where and why users abandon conversations

**Key Metrics**:
- **Drop-off Rate by State**: Percentage of users dropping off at each state
- **Average Progress at Drop-off**: How far users got before dropping off
- **Drop-off Reasons**: Distribution of `drop_off_reason` values
- **Time Since Last Message**: How long users were inactive before drop-off

**Metabase Configuration**:
- Use the "Flow Drop-off Points" model
- Create heatmap visualization:
  - X-axis: Flow states
  - Y-axis: Variants
  - Color: Drop-off count or rate
- Create table showing:
  - Last active state
  - Drop-off count
  - Average progress
  - Average turns before drop-off

**Drop-off Reason Categories**:
- `session_expired`: User inactive beyond session timeout
- `user_inactive`: User stopped responding
- `error`: Technical error occurred
- `user_cancelled`: User explicitly cancelled

### 4.4 Conversation Event Types Reference

| Event Type | Description | Key Metrics | Key Context Fields |
|------------|-------------|------------|-------------------|
| `conversation_started` | User initiates conversation | - | session_id, flow_id, flow_version |
| `message_sent` | User or bot sends message | turn_number, latency_ms, token_count | session_id, current_state |
| `flow_completed` | User completes flow | total_turns, total_duration_seconds, completion_rate | session_id, flow_id, final_state |
| `user_dropped_off` | User abandons conversation | total_turns, total_duration_seconds, time_since_last_message_seconds | session_id, flow_id, last_active_state |

### 4.5 Variant Comparison Metrics

For comparing conversation variants in A/B tests:

**Primary Metrics**:
- Completion rate (higher is better)
- Average turn count (lower may be better, depends on flow)
- Average time to completion (lower is better)
- Drop-off rate (lower is better)

**Secondary Metrics**:
- Message latency (p50, p95, p99)
- Token usage per conversation
- User satisfaction scores (if collected)

**Statistical Analysis**:
- Use same statistical significance testing as ML experiments
- Compare completion rates with chi-square test
- Compare turn counts and durations with t-test or Mann-Whitney U test

---

## 5. Alerting

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

## 6. Access Control

### 5.1 User Groups

| Group | Access |
|-------|--------|
| Admins | Full access, can edit |
| ML Team | All dashboards, can create |
| Engineering | Latency & Cost dashboard |
| Product | Experiment Overview only |
| Conversational AI Team | Conversation Analytics dashboard, can create conversation dashboards |

---

## 7. TODO: Implementation Checklist

- [ ] Create PostgreSQL views
- [ ] Set up Metabase connection
- [ ] Create Experiment Overview dashboard
- [ ] Create Variant Performance dashboard
- [ ] Create Offline vs Online dashboard
- [ ] Create Model Quality dashboard
- [ ] Create Latency & Cost dashboard
- [ ] Create Conversation Analytics dashboard
- [ ] Create conversation metrics views/models
- [ ] Set up funnel analysis queries
- [ ] Set up drop-off analysis queries
- [ ] Configure alerts
- [ ] Set up scheduled reports

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [example-queries.sql](example-queries.sql) | SQL examples |
| [../infra/metabase-setup.md](../infra/metabase-setup.md) | Metabase deployment |
| [../pipelines/metrics-aggregation.md](../pipelines/metrics-aggregation.md) | Data source |

