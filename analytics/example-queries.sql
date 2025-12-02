-- =============================================================================
-- Example SQL Queries for Experimentation Analytics
-- =============================================================================
-- Purpose: Reference queries for common analytics tasks
--
-- Start Here If…
--   - Analytics Route → Use these as templates
--   - Building dashboards → Adapt for Metabase
--   - Debugging experiments → Run directly
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. EXPERIMENT QUERIES
-- -----------------------------------------------------------------------------

-- 1.1 List all active experiments with variant counts
SELECT
    e.id,
    e.name,
    e.status,
    e.unit_type,
    e.start_at,
    COUNT(v.id) as variant_count,
    SUM(v.allocation) as total_allocation
FROM exp.experiments e
LEFT JOIN exp.variants v ON v.experiment_id = e.id
WHERE e.status = 'active'
GROUP BY e.id, e.name, e.status, e.unit_type, e.start_at
ORDER BY e.start_at DESC;

-- 1.2 Get variants for a specific experiment
SELECT
    v.id,
    v.name,
    v.allocation,
    v.config,
    v.config->>'policy_version_id' as policy_version_id
FROM exp.variants v
JOIN exp.experiments e ON e.id = v.experiment_id
WHERE e.name = 'planner_policy_exp'
ORDER BY v.name;

-- 1.3 Assignment distribution per experiment
SELECT
    e.name as experiment,
    v.name as variant,
    v.allocation as expected_allocation,
    COUNT(a.id) as assignment_count,
    ROUND(COUNT(a.id)::numeric / NULLIF(SUM(COUNT(a.id)) OVER (PARTITION BY e.id), 0) * 100, 2) as actual_percentage
FROM exp.experiments e
JOIN exp.variants v ON v.experiment_id = e.id
LEFT JOIN exp.assignments a ON a.variant_id = v.id
WHERE e.status = 'active'
GROUP BY e.id, e.name, v.id, v.name, v.allocation
ORDER BY e.name, v.name;

-- -----------------------------------------------------------------------------
-- 2. EVENT QUERIES
-- -----------------------------------------------------------------------------

-- 2.1 Event counts by type (last 7 days)
SELECT
    event_type,
    COUNT(*) as count,
    DATE(timestamp) as date
FROM exp.events
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY event_type, DATE(timestamp)
ORDER BY date DESC, count DESC;

-- 2.2 Events by experiment and variant
SELECT
    exp_data->>'experiment_id' as experiment_id,
    exp_data->>'variant_id' as variant_id,
    event_type,
    COUNT(*) as count
FROM exp.events,
     LATERAL jsonb_array_elements(experiments) as exp_data
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY experiment_id, variant_id, event_type
ORDER BY count DESC;

-- 2.3 Plan acceptance rate by variant
WITH plan_events AS (
    SELECT
        exp_data->>'variant_id' as variant_id,
        event_type,
        COUNT(*) as count
    FROM exp.events,
         LATERAL jsonb_array_elements(experiments) as exp_data
    WHERE event_type IN ('plan_generated', 'plan_accepted')
    AND timestamp > NOW() - INTERVAL '7 days'
    GROUP BY variant_id, event_type
)
SELECT
    v.name as variant_name,
    COALESCE(gen.count, 0) as generated,
    COALESCE(acc.count, 0) as accepted,
    ROUND(COALESCE(acc.count, 0)::numeric / NULLIF(COALESCE(gen.count, 0), 0) * 100, 2) as acceptance_rate
FROM exp.variants v
LEFT JOIN plan_events gen ON gen.variant_id = v.id::text AND gen.event_type = 'plan_generated'
LEFT JOIN plan_events acc ON acc.variant_id = v.id::text AND acc.event_type = 'plan_accepted';

-- -----------------------------------------------------------------------------
-- 3. METRICS QUERIES
-- -----------------------------------------------------------------------------

-- 3.1 Daily metrics for an experiment
SELECT
    e.name as experiment,
    v.name as variant,
    m.metric_name,
    m.bucket_start::date as date,
    m.mean,
    m.count,
    m.min,
    m.max
FROM exp.metric_aggregates m
JOIN exp.variants v ON v.id = m.variant_id
JOIN exp.experiments e ON e.id = m.experiment_id
WHERE e.name = 'planner_policy_exp'
AND m.bucket_type = 'daily'
AND m.bucket_start > NOW() - INTERVAL '30 days'
ORDER BY m.bucket_start DESC, v.name, m.metric_name;

-- 3.2 Latency percentiles by variant
SELECT
    v.name as variant,
    m.metric_name,
    m.mean as avg_latency,
    m.min as min_latency,
    m.max as max_latency
FROM exp.metric_aggregates m
JOIN exp.variants v ON v.id = m.variant_id
WHERE m.metric_name LIKE 'latency%'
AND m.bucket_type = 'daily'
AND m.bucket_start = DATE(NOW() - INTERVAL '1 day')
ORDER BY v.name;

-- 3.3 Variant comparison (last 7 days)
SELECT
    v.name as variant,
    AVG(CASE WHEN m.metric_name = 'acceptance_rate' THEN m.mean END) as avg_acceptance_rate,
    AVG(CASE WHEN m.metric_name = 'latency_ms' THEN m.mean END) as avg_latency,
    AVG(CASE WHEN m.metric_name = 'edit_count' THEN m.mean END) as avg_edits
FROM exp.metric_aggregates m
JOIN exp.variants v ON v.id = m.variant_id
WHERE m.bucket_type = 'daily'
AND m.bucket_start > NOW() - INTERVAL '7 days'
GROUP BY v.id, v.name
ORDER BY v.name;

-- -----------------------------------------------------------------------------
-- 4. POLICY & MODEL QUERIES
-- -----------------------------------------------------------------------------

-- 4.1 List policy versions with MLflow info
SELECT
    p.name as policy_name,
    pv.version,
    pv.mlflow_model_name,
    pv.mlflow_model_version,
    pv.status,
    pv.created_at
FROM exp.policy_versions pv
JOIN exp.policies p ON p.id = pv.policy_id
ORDER BY p.name, pv.version DESC;

-- 4.2 Policy versions currently in use
SELECT DISTINCT
    p.name as policy_name,
    pv.version,
    pv.mlflow_model_name,
    pv.mlflow_model_version,
    e.name as experiment_name,
    v.name as variant_name,
    v.allocation
FROM exp.policy_versions pv
JOIN exp.policies p ON p.id = pv.policy_id
JOIN exp.variants v ON v.config->>'policy_version_id' = pv.id::text
JOIN exp.experiments e ON e.id = v.experiment_id
WHERE e.status = 'active'
ORDER BY p.name, pv.version DESC;

-- -----------------------------------------------------------------------------
-- 5. OFFLINE EVALUATION QUERIES
-- -----------------------------------------------------------------------------

-- 5.1 Recent evaluation results
SELECT
    p.name as policy_name,
    pv.version,
    r.dataset_version,
    r.plan_alignment_score,
    r.constraint_respect_score,
    r.edit_distance_score,
    r.is_better_than_baseline,
    r.created_at
FROM exp.offline_replay_results r
JOIN exp.policy_versions pv ON pv.id = r.policy_version_id
JOIN exp.policies p ON p.id = pv.policy_id
ORDER BY r.created_at DESC
LIMIT 20;

-- 5.2 Model improvement over time
SELECT
    pv.version,
    r.plan_alignment_score,
    r.constraint_respect_score,
    LAG(r.plan_alignment_score) OVER (ORDER BY pv.version) as prev_alignment,
    r.plan_alignment_score - LAG(r.plan_alignment_score) OVER (ORDER BY pv.version) as alignment_change
FROM exp.offline_replay_results r
JOIN exp.policy_versions pv ON pv.id = r.policy_version_id
JOIN exp.policies p ON p.id = pv.policy_id
WHERE p.name = 'planner_policy'
ORDER BY pv.version;

-- -----------------------------------------------------------------------------
-- 6. DIAGNOSTIC QUERIES
-- -----------------------------------------------------------------------------

-- 6.1 Events missing experiment context
SELECT
    event_type,
    COUNT(*) as count
FROM exp.events
WHERE experiments = '[]'::jsonb OR experiments IS NULL
AND timestamp > NOW() - INTERVAL '1 day'
GROUP BY event_type
ORDER BY count DESC;

-- 6.2 Latency outliers
SELECT
    event_type,
    (metrics->>'latency_ms')::numeric as latency_ms,
    timestamp,
    unit_id
FROM exp.events
WHERE (metrics->>'latency_ms')::numeric > 5000
AND timestamp > NOW() - INTERVAL '1 day'
ORDER BY latency_ms DESC
LIMIT 100;

-- 6.3 Assignment imbalance check
WITH expected AS (
    SELECT
        experiment_id,
        id as variant_id,
        name as variant_name,
        allocation
    FROM exp.variants
),
actual AS (
    SELECT
        experiment_id,
        variant_id,
        COUNT(*) as assignment_count
    FROM exp.assignments
    GROUP BY experiment_id, variant_id
)
SELECT
    e.variant_name,
    e.allocation as expected_pct,
    ROUND(a.assignment_count::numeric / SUM(a.assignment_count) OVER (PARTITION BY e.experiment_id) * 100, 2) as actual_pct,
    ABS(e.allocation * 100 - ROUND(a.assignment_count::numeric / SUM(a.assignment_count) OVER (PARTITION BY e.experiment_id) * 100, 2)) as drift
FROM expected e
JOIN actual a ON a.variant_id = e.variant_id
ORDER BY drift DESC;

-- -----------------------------------------------------------------------------
-- 7. REPORTING QUERIES
-- -----------------------------------------------------------------------------

-- 7.1 Weekly experiment summary
SELECT
    e.name as experiment,
    COUNT(DISTINCT a.unit_id) as total_users,
    COUNT(DISTINCT ev.id) as total_events,
    DATE(MIN(a.assigned_at)) as first_assignment,
    DATE(MAX(a.assigned_at)) as last_assignment
FROM exp.experiments e
LEFT JOIN exp.assignments a ON a.experiment_id = e.id
LEFT JOIN exp.events ev ON ev.experiments @> jsonb_build_array(jsonb_build_object('experiment_id', e.id::text))
WHERE e.status = 'active'
AND a.assigned_at > NOW() - INTERVAL '7 days'
GROUP BY e.id, e.name
ORDER BY total_users DESC;

-- =============================================================================
-- TODO: Add more queries as needed
-- =============================================================================

