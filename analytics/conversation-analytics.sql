-- =============================================================================
-- Conversation Analytics SQL Queries
-- =============================================================================
-- Purpose: SQL queries for chatbot/conversation analytics including funnel
--          analysis, drop-off detection, completion rates, and performance metrics
--
-- Start Here If…
--   - Conversation Analytics Route → Use these as templates
--   - Building conversation dashboards → Adapt for Metabase
--   - Analyzing conversation flows → Run directly
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. FUNNEL ANALYSIS QUERIES
-- -----------------------------------------------------------------------------

-- 1.1 Conversation Funnel: Started → Engaged → Completed
-- Purpose: Track user progression through conversation flows
WITH conversation_funnel AS (
    SELECT
        e.context->>'session_id' as session_id,
        e.context->>'flow_id' as flow_id,
        e.experiments->0->>'experiment_id' as experiment_id,
        e.experiments->0->>'variant_id' as variant_id,
        MAX(CASE WHEN e.event_type = 'conversation_started' THEN 1 ELSE 0 END) as started,
        MAX(CASE WHEN e.event_type = 'message_sent' THEN 1 ELSE 0 END) as engaged,
        MAX(CASE WHEN e.event_type = 'flow_completed' THEN 1 ELSE 0 END) as completed,
        MAX(CASE WHEN e.event_type = 'user_dropped_off' THEN 1 ELSE 0 END) as dropped_off
    FROM exp.events e
    WHERE e.event_type IN ('conversation_started', 'message_sent', 'flow_completed', 'user_dropped_off')
      AND e.context->>'session_id' IS NOT NULL
      AND e.timestamp > NOW() - INTERVAL '7 days'
    GROUP BY session_id, flow_id, experiment_id, variant_id
)
SELECT
    flow_id,
    variant_id,
    COUNT(*) FILTER (WHERE started = 1) as started_count,
    COUNT(*) FILTER (WHERE engaged = 1) as engaged_count,
    COUNT(*) FILTER (WHERE completed = 1) as completed_count,
    COUNT(*) FILTER (WHERE dropped_off = 1) as dropped_off_count,
    ROUND(COUNT(*) FILTER (WHERE engaged = 1)::numeric / NULLIF(COUNT(*) FILTER (WHERE started = 1), 0) * 100, 2) as engagement_rate,
    ROUND(COUNT(*) FILTER (WHERE completed = 1)::numeric / NULLIF(COUNT(*) FILTER (WHERE started = 1), 0) * 100, 2) as completion_rate
FROM conversation_funnel
GROUP BY flow_id, variant_id
ORDER BY flow_id, variant_id;

-- 1.2 Funnel by Flow State (Detailed Progression)
-- Purpose: Track progression through specific flow states
WITH state_progression AS (
    SELECT
        e.context->>'session_id' as session_id,
        e.context->>'flow_id' as flow_id,
        e.context->>'current_state' as current_state,
        e.experiments->0->>'variant_id' as variant_id,
        e.timestamp,
        ROW_NUMBER() OVER (PARTITION BY e.context->>'session_id' ORDER BY e.timestamp) as state_order
    FROM exp.events e
    WHERE e.event_type = 'message_sent'
      AND e.context->>'current_state' IS NOT NULL
      AND e.context->>'session_id' IS NOT NULL
      AND e.timestamp > NOW() - INTERVAL '7 days'
)
SELECT
    flow_id,
    variant_id,
    current_state,
    COUNT(DISTINCT session_id) as sessions_reached,
    AVG(state_order) as avg_position_in_flow
FROM state_progression
GROUP BY flow_id, variant_id, current_state
ORDER BY flow_id, variant_id, avg_position_in_flow;

-- 1.3 Multi-Step Funnel with Conversion Rates
-- Purpose: Calculate conversion rates between funnel steps
WITH funnel_steps AS (
    SELECT
        e.context->>'session_id' as session_id,
        e.context->>'flow_id' as flow_id,
        e.experiments->0->>'variant_id' as variant_id,
        MAX(CASE WHEN e.event_type = 'conversation_started' THEN e.timestamp END) as step1_started,
        MAX(CASE WHEN e.event_type = 'message_sent' AND (e.metrics->>'turn_number')::int >= 1 THEN e.timestamp END) as step2_first_message,
        MAX(CASE WHEN e.event_type = 'message_sent' AND (e.metrics->>'turn_number')::int >= 3 THEN e.timestamp END) as step3_three_turns,
        MAX(CASE WHEN e.event_type = 'flow_completed' THEN e.timestamp END) as step4_completed
    FROM exp.events e
    WHERE e.context->>'session_id' IS NOT NULL
      AND e.timestamp > NOW() - INTERVAL '7 days'
    GROUP BY session_id, flow_id, variant_id
)
SELECT
    flow_id,
    variant_id,
    COUNT(*) FILTER (WHERE step1_started IS NOT NULL) as step1_count,
    COUNT(*) FILTER (WHERE step2_first_message IS NOT NULL) as step2_count,
    COUNT(*) FILTER (WHERE step3_three_turns IS NOT NULL) as step3_count,
    COUNT(*) FILTER (WHERE step4_completed IS NOT NULL) as step4_count,
    ROUND(COUNT(*) FILTER (WHERE step2_first_message IS NOT NULL)::numeric / 
          NULLIF(COUNT(*) FILTER (WHERE step1_started IS NOT NULL), 0) * 100, 2) as step1_to_step2_rate,
    ROUND(COUNT(*) FILTER (WHERE step3_three_turns IS NOT NULL)::numeric / 
          NULLIF(COUNT(*) FILTER (WHERE step2_first_message IS NOT NULL), 0) * 100, 2) as step2_to_step3_rate,
    ROUND(COUNT(*) FILTER (WHERE step4_completed IS NOT NULL)::numeric / 
          NULLIF(COUNT(*) FILTER (WHERE step3_three_turns IS NOT NULL), 0) * 100, 2) as step3_to_step4_rate
FROM funnel_steps
GROUP BY flow_id, variant_id
ORDER BY flow_id, variant_id;

-- -----------------------------------------------------------------------------
-- 2. DROP-OFF ANALYSIS QUERIES
-- -----------------------------------------------------------------------------

-- 2.1 Drop-off Points by State
-- Purpose: Identify where users most frequently abandon conversations
SELECT
    e.context->>'flow_id' as flow_id,
    e.context->>'current_state' as last_active_state,
    e.experiments->0->>'variant_id' as variant_id,
    COUNT(*) as drop_off_count,
    AVG((e.payload->>'progress')::float) as avg_progress_at_drop_off,
    AVG((e.metrics->>'total_turns')::integer) as avg_turns_before_drop_off,
    AVG((e.metrics->>'total_duration_seconds')::integer) as avg_duration_before_drop_off,
    AVG((e.metrics->>'time_since_last_message_seconds')::integer) as avg_time_since_last_message
FROM exp.events e
WHERE e.event_type = 'user_dropped_off'
  AND e.context->>'current_state' IS NOT NULL
  AND e.timestamp > NOW() - INTERVAL '7 days'
GROUP BY flow_id, last_active_state, variant_id
ORDER BY drop_off_count DESC;

-- 2.2 Drop-off Reasons Distribution
-- Purpose: Understand why users drop off
SELECT
    e.context->>'flow_id' as flow_id,
    e.payload->>'drop_off_reason' as drop_off_reason,
    e.experiments->0->>'variant_id' as variant_id,
    COUNT(*) as count,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER (PARTITION BY e.context->>'flow_id', e.experiments->0->>'variant_id') * 100, 2) as percentage
FROM exp.events e
WHERE e.event_type = 'user_dropped_off'
  AND e.payload->>'drop_off_reason' IS NOT NULL
  AND e.timestamp > NOW() - INTERVAL '7 days'
GROUP BY flow_id, drop_off_reason, variant_id
ORDER BY flow_id, variant_id, count DESC;

-- 2.3 Drop-off Rate by Flow and Variant
-- Purpose: Compare drop-off rates across variants
WITH conversation_outcomes AS (
    SELECT
        e.context->>'session_id' as session_id,
        e.context->>'flow_id' as flow_id,
        e.experiments->0->>'variant_id' as variant_id,
        MAX(CASE WHEN e.event_type = 'conversation_started' THEN 1 ELSE 0 END) as started,
        MAX(CASE WHEN e.event_type = 'flow_completed' THEN 1 ELSE 0 END) as completed,
        MAX(CASE WHEN e.event_type = 'user_dropped_off' THEN 1 ELSE 0 END) as dropped_off
    FROM exp.events e
    WHERE e.context->>'session_id' IS NOT NULL
      AND e.timestamp > NOW() - INTERVAL '7 days'
    GROUP BY session_id, flow_id, variant_id
)
SELECT
    flow_id,
    variant_id,
    COUNT(*) FILTER (WHERE started = 1) as total_started,
    COUNT(*) FILTER (WHERE completed = 1) as total_completed,
    COUNT(*) FILTER (WHERE dropped_off = 1) as total_dropped_off,
    ROUND(COUNT(*) FILTER (WHERE dropped_off = 1)::numeric / 
          NULLIF(COUNT(*) FILTER (WHERE started = 1), 0) * 100, 2) as drop_off_rate
FROM conversation_outcomes
GROUP BY flow_id, variant_id
ORDER BY flow_id, drop_off_rate DESC;

-- -----------------------------------------------------------------------------
-- 3. COMPLETION RATE QUERIES
-- -----------------------------------------------------------------------------

-- 3.1 Completion Rate by Flow and Variant
-- Purpose: Primary success metric for conversation flows
SELECT
    e.context->>'flow_id' as flow_id,
    e.experiments->0->>'variant_id' as variant_id,
    COUNT(*) FILTER (WHERE e.event_type = 'conversation_started') as started_count,
    COUNT(*) FILTER (WHERE e.event_type = 'flow_completed') as completed_count,
    ROUND(COUNT(*) FILTER (WHERE e.event_type = 'flow_completed')::numeric / 
          NULLIF(COUNT(*) FILTER (WHERE e.event_type = 'conversation_started'), 0) * 100, 2) as completion_rate
FROM exp.events e
WHERE e.event_type IN ('conversation_started', 'flow_completed')
  AND e.context->>'flow_id' IS NOT NULL
  AND e.timestamp > NOW() - INTERVAL '7 days'
GROUP BY flow_id, variant_id
ORDER BY flow_id, completion_rate DESC;

-- 3.2 Completion Rate Over Time
-- Purpose: Track completion rate trends
SELECT
    DATE(e.timestamp) as date,
    e.context->>'flow_id' as flow_id,
    e.experiments->0->>'variant_id' as variant_id,
    COUNT(*) FILTER (WHERE e.event_type = 'conversation_started') as started_count,
    COUNT(*) FILTER (WHERE e.event_type = 'flow_completed') as completed_count,
    ROUND(COUNT(*) FILTER (WHERE e.event_type = 'flow_completed')::numeric / 
          NULLIF(COUNT(*) FILTER (WHERE e.event_type = 'conversation_started'), 0) * 100, 2) as completion_rate
FROM exp.events e
WHERE e.event_type IN ('conversation_started', 'flow_completed')
  AND e.context->>'flow_id' IS NOT NULL
  AND e.timestamp > NOW() - INTERVAL '30 days'
GROUP BY DATE(e.timestamp), flow_id, variant_id
ORDER BY date DESC, flow_id, variant_id;

-- 3.3 Completion Rate by Entry Point
-- Purpose: Understand which entry points lead to better completion
SELECT
    e.context->>'flow_id' as flow_id,
    e.payload->>'entry_point' as entry_point,
    e.experiments->0->>'variant_id' as variant_id,
    COUNT(*) FILTER (WHERE e.event_type = 'conversation_started') as started_count,
    COUNT(*) FILTER (WHERE e.event_type = 'flow_completed') as completed_count,
    ROUND(COUNT(*) FILTER (WHERE e.event_type = 'flow_completed')::numeric / 
          NULLIF(COUNT(*) FILTER (WHERE e.event_type = 'conversation_started'), 0) * 100, 2) as completion_rate
FROM exp.events e
WHERE e.event_type IN ('conversation_started', 'flow_completed')
  AND e.payload->>'entry_point' IS NOT NULL
  AND e.timestamp > NOW() - INTERVAL '7 days'
GROUP BY flow_id, entry_point, variant_id
ORDER BY flow_id, completion_rate DESC;

-- -----------------------------------------------------------------------------
-- 4. TURN COUNT QUERIES
-- -----------------------------------------------------------------------------

-- 4.1 Average Turn Count by Flow and Variant
-- Purpose: Measure conversation efficiency
SELECT
    e.context->>'flow_id' as flow_id,
    e.experiments->0->>'variant_id' as variant_id,
    AVG((e.metrics->>'total_turns')::integer) as avg_turn_count,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (e.metrics->>'total_turns')::integer) as median_turn_count,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY (e.metrics->>'total_turns')::integer) as p95_turn_count,
    MIN((e.metrics->>'total_turns')::integer) as min_turn_count,
    MAX((e.metrics->>'total_turns')::integer) as max_turn_count,
    COUNT(*) as sample_size
FROM exp.events e
WHERE e.event_type IN ('flow_completed', 'user_dropped_off')
  AND e.metrics->>'total_turns' IS NOT NULL
  AND e.timestamp > NOW() - INTERVAL '7 days'
GROUP BY flow_id, variant_id
ORDER BY flow_id, avg_turn_count;

-- 4.2 Turn Count Distribution
-- Purpose: Understand distribution of conversation lengths
SELECT
    e.context->>'flow_id' as flow_id,
    e.experiments->0->>'variant_id' as variant_id,
    (e.metrics->>'total_turns')::integer as turn_count,
    COUNT(*) as frequency
FROM exp.events e
WHERE e.event_type IN ('flow_completed', 'user_dropped_off')
  AND e.metrics->>'total_turns' IS NOT NULL
  AND e.timestamp > NOW() - INTERVAL '7 days'
GROUP BY flow_id, variant_id, turn_count
ORDER BY flow_id, variant_id, turn_count;

-- -----------------------------------------------------------------------------
-- 5. TIME TO COMPLETION QUERIES
-- -----------------------------------------------------------------------------

-- 5.1 Average Time to Completion
-- Purpose: Measure user experience and flow efficiency
SELECT
    e.context->>'flow_id' as flow_id,
    e.experiments->0->>'variant_id' as variant_id,
    AVG((e.metrics->>'total_duration_seconds')::integer) as avg_duration_seconds,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (e.metrics->>'total_duration_seconds')::integer) as median_duration_seconds,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY (e.metrics->>'total_duration_seconds')::integer) as p95_duration_seconds,
    MIN((e.metrics->>'total_duration_seconds')::integer) as min_duration_seconds,
    MAX((e.metrics->>'total_duration_seconds')::integer) as max_duration_seconds,
    COUNT(*) as sample_size
FROM exp.events e
WHERE e.event_type = 'flow_completed'
  AND e.metrics->>'total_duration_seconds' IS NOT NULL
  AND e.timestamp > NOW() - INTERVAL '7 days'
GROUP BY flow_id, variant_id
ORDER BY flow_id, avg_duration_seconds;

-- 5.2 Time to Completion Over Time
-- Purpose: Track duration trends
SELECT
    DATE(e.timestamp) as date,
    e.context->>'flow_id' as flow_id,
    e.experiments->0->>'variant_id' as variant_id,
    AVG((e.metrics->>'total_duration_seconds')::integer) as avg_duration_seconds,
    COUNT(*) as completed_count
FROM exp.events e
WHERE e.event_type = 'flow_completed'
  AND e.metrics->>'total_duration_seconds' IS NOT NULL
  AND e.timestamp > NOW() - INTERVAL '30 days'
GROUP BY DATE(e.timestamp), flow_id, variant_id
ORDER BY date DESC, flow_id, variant_id;

-- -----------------------------------------------------------------------------
-- 6. SATISFACTION SCORE QUERIES
-- -----------------------------------------------------------------------------

-- 6.1 Average Satisfaction Score by Flow and Variant
-- Purpose: Measure user satisfaction (if satisfaction scores are collected)
SELECT
    e.context->>'flow_id' as flow_id,
    e.experiments->0->>'variant_id' as variant_id,
    AVG((e.payload->>'satisfaction_score')::float) as avg_satisfaction_score,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (e.payload->>'satisfaction_score')::float) as median_satisfaction_score,
    COUNT(*) FILTER (WHERE (e.payload->>'satisfaction_score')::float >= 4.0) as satisfied_count,
    COUNT(*) FILTER (WHERE (e.payload->>'satisfaction_score')::float IS NOT NULL) as total_rated,
    ROUND(COUNT(*) FILTER (WHERE (e.payload->>'satisfaction_score')::float >= 4.0)::numeric / 
          NULLIF(COUNT(*) FILTER (WHERE (e.payload->>'satisfaction_score')::float IS NOT NULL), 0) * 100, 2) as satisfaction_rate
FROM exp.events e
WHERE e.event_type = 'flow_completed'
  AND e.payload->>'satisfaction_score' IS NOT NULL
  AND e.timestamp > NOW() - INTERVAL '7 days'
GROUP BY flow_id, variant_id
ORDER BY flow_id, avg_satisfaction_score DESC;

-- 6.2 Satisfaction Score Distribution
-- Purpose: Understand satisfaction score distribution
SELECT
    e.context->>'flow_id' as flow_id,
    e.experiments->0->>'variant_id' as variant_id,
    CASE
        WHEN (e.payload->>'satisfaction_score')::float >= 4.5 THEN 'Very Satisfied (4.5-5.0)'
        WHEN (e.payload->>'satisfaction_score')::float >= 4.0 THEN 'Satisfied (4.0-4.5)'
        WHEN (e.payload->>'satisfaction_score')::float >= 3.0 THEN 'Neutral (3.0-4.0)'
        WHEN (e.payload->>'satisfaction_score')::float >= 2.0 THEN 'Dissatisfied (2.0-3.0)'
        ELSE 'Very Dissatisfied (0-2.0)'
    END as satisfaction_category,
    COUNT(*) as count,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER (PARTITION BY e.context->>'flow_id', e.experiments->0->>'variant_id') * 100, 2) as percentage
FROM exp.events e
WHERE e.event_type = 'flow_completed'
  AND e.payload->>'satisfaction_score' IS NOT NULL
  AND e.timestamp > NOW() - INTERVAL '7 days'
GROUP BY flow_id, variant_id, satisfaction_category
ORDER BY flow_id, variant_id, satisfaction_category;

-- -----------------------------------------------------------------------------
-- 7. VARIANT COMPARISON QUERIES
-- -----------------------------------------------------------------------------

-- 7.1 Comprehensive Variant Comparison
-- Purpose: Compare all key metrics across variants
WITH variant_metrics AS (
    SELECT
        e.context->>'flow_id' as flow_id,
        e.experiments->0->>'variant_id' as variant_id,
        COUNT(*) FILTER (WHERE e.event_type = 'conversation_started') as started_count,
        COUNT(*) FILTER (WHERE e.event_type = 'flow_completed') as completed_count,
        COUNT(*) FILTER (WHERE e.event_type = 'user_dropped_off') as dropped_off_count,
        AVG((e.metrics->>'total_turns')::integer) FILTER (WHERE e.event_type IN ('flow_completed', 'user_dropped_off')) as avg_turns,
        AVG((e.metrics->>'total_duration_seconds')::integer) FILTER (WHERE e.event_type = 'flow_completed') as avg_duration,
        AVG((e.metrics->>'latency_ms')::numeric) FILTER (WHERE e.event_type = 'message_sent') as avg_latency_ms
    FROM exp.events e
    WHERE e.context->>'flow_id' IS NOT NULL
      AND e.timestamp > NOW() - INTERVAL '7 days'
    GROUP BY flow_id, variant_id
)
SELECT
    vm.flow_id,
    v.name as variant_name,
    vm.started_count,
    vm.completed_count,
    vm.dropped_off_count,
    ROUND(vm.completed_count::numeric / NULLIF(vm.started_count, 0) * 100, 2) as completion_rate,
    ROUND(vm.dropped_off_count::numeric / NULLIF(vm.started_count, 0) * 100, 2) as drop_off_rate,
    ROUND(vm.avg_turns, 2) as avg_turn_count,
    ROUND(vm.avg_duration, 2) as avg_duration_seconds,
    ROUND(vm.avg_latency_ms, 2) as avg_latency_ms
FROM variant_metrics vm
JOIN exp.variants v ON v.id::text = vm.variant_id
ORDER BY vm.flow_id, completion_rate DESC;

-- -----------------------------------------------------------------------------
-- 8. PERFORMANCE METRICS QUERIES
-- -----------------------------------------------------------------------------

-- 8.1 Message Latency by Flow and Variant
-- Purpose: Monitor response time performance
SELECT
    e.context->>'flow_id' as flow_id,
    e.experiments->0->>'variant_id' as variant_id,
    AVG((e.metrics->>'latency_ms')::numeric) as avg_latency_ms,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (e.metrics->>'latency_ms')::numeric) as median_latency_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY (e.metrics->>'latency_ms')::numeric) as p95_latency_ms,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY (e.metrics->>'latency_ms')::numeric) as p99_latency_ms,
    COUNT(*) as message_count
FROM exp.events e
WHERE e.event_type = 'message_sent'
  AND e.metrics->>'latency_ms' IS NOT NULL
  AND e.timestamp > NOW() - INTERVAL '7 days'
GROUP BY flow_id, variant_id
ORDER BY flow_id, avg_latency_ms;

-- 8.2 Token Usage by Flow and Variant
-- Purpose: Monitor LLM token consumption
SELECT
    e.context->>'flow_id' as flow_id,
    e.experiments->0->>'variant_id' as variant_id,
    AVG((e.metrics->>'token_count')::integer) as avg_token_count,
    SUM((e.metrics->>'token_count')::integer) as total_tokens,
    COUNT(*) as message_count,
    AVG((e.metrics->>'token_count')::integer) / NULLIF(AVG((e.metrics->>'turn_number')::integer), 0) as avg_tokens_per_turn
FROM exp.events e
WHERE e.event_type = 'message_sent'
  AND e.metrics->>'token_count' IS NOT NULL
  AND e.timestamp > NOW() - INTERVAL '7 days'
GROUP BY flow_id, variant_id
ORDER BY flow_id, avg_token_count DESC;

-- =============================================================================
-- TODO: Add more queries as needed for specific analysis requirements
-- =============================================================================
