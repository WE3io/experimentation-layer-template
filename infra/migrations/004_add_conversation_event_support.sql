-- =============================================================================
-- Migration: Add Conversation Event Support
-- =============================================================================
-- Purpose: Extend exp.events table to support conversation-specific event types
--          (conversation_started, message_sent, flow_completed, user_dropped_off).
--          Adds indexes for efficient querying of conversation events by session_id
--          and flow_id stored in the context JSONB field.
--
-- Created: 2026-02-09
-- Related: docs/data-model.md section 2.1 (exp.events)
-- =============================================================================

BEGIN;

-- =============================================================================
-- Schema Note: No Column Changes Required
-- =============================================================================
-- The existing JSONB columns (context, payload, metrics) are sufficient for
-- storing conversation events. Conversation-specific data is stored as:
-- - context.session_id, context.flow_id, context.flow_version, etc.
-- - payload contains event-specific conversation data
-- - metrics contains conversation metrics (turn_number, total_turns, etc.)
--
-- No ALTER TABLE statements needed - JSONB is schema-less and flexible.
-- =============================================================================

-- =============================================================================
-- Add Indexes for Conversation Event Queries
-- =============================================================================
-- Conversation events are frequently queried by:
-- 1. session_id (to get all events for a conversation session)
-- 2. flow_id (to analyze events across all sessions for a flow)
-- 3. event_type (already indexed, but ensure conversation types are covered)
--
-- These indexes use expression indexes on JSONB paths for efficient querying.
-- =============================================================================

-- Index for querying events by session_id (stored in context.session_id)
CREATE INDEX IF NOT EXISTS idx_events_context_session_id 
ON exp.events ((context->>'session_id'))
WHERE context->>'session_id' IS NOT NULL;

-- Index for querying events by flow_id (stored in context.flow_id)
CREATE INDEX IF NOT EXISTS idx_events_context_flow_id 
ON exp.events ((context->>'flow_id'))
WHERE context->>'flow_id' IS NOT NULL;

-- Composite index for common conversation event queries
-- (session_id + timestamp for chronological session event retrieval)
CREATE INDEX IF NOT EXISTS idx_events_session_timestamp 
ON exp.events ((context->>'session_id'), timestamp)
WHERE context->>'session_id' IS NOT NULL;

-- =============================================================================
-- Add Comments Documenting Conversation Event Support
-- =============================================================================

COMMENT ON COLUMN exp.events.event_type IS 
'Event type identifier. Standard ML events: plan_generated, plan_accepted, meal_swapped, etc.
Conversation events: conversation_started, message_sent, flow_completed, user_dropped_off.
See docs/data-model.md section 2.1 for complete event type documentation.';

COMMENT ON COLUMN exp.events.context IS 
'Additional context stored as JSONB. For ML events: policy_version_id, app_version, etc.
For conversation events: session_id, flow_id, flow_version, current_state, prompt_version_id, 
model_provider, model_name. See docs/data-model.md section 2.1 for conversation context fields.';

COMMENT ON COLUMN exp.events.payload IS 
'Event-specific data stored as JSONB. Structure varies by event_type.
For conversation events: entry_point, referral_source (conversation_started);
message_text, sender, state_transition (message_sent); completion_reason, data_collected 
(flow_completed); drop_off_reason, last_active_state, progress (user_dropped_off).
See docs/data-model.md section 2.1 for conversation payload structures.';

COMMENT ON COLUMN exp.events.metrics IS 
'Measurable quantities stored as JSONB. Common ML metrics: latency_ms, token_count.
Conversation metrics: latency_ms, token_count, turn_number, total_turns, 
total_duration_seconds, time_since_last_message_seconds, completion_rate.
See docs/data-model.md section 2.1 for conversation metrics documentation.';

COMMIT;

-- =============================================================================
-- Rollback Script
-- =============================================================================
-- To rollback this migration:
--
-- BEGIN;
-- DROP INDEX IF EXISTS exp.idx_events_session_timestamp;
-- DROP INDEX IF EXISTS exp.idx_events_context_flow_id;
-- DROP INDEX IF EXISTS exp.idx_events_context_session_id;
-- COMMENT ON COLUMN exp.events.event_type IS NULL;
-- COMMENT ON COLUMN exp.events.context IS NULL;
-- COMMENT ON COLUMN exp.events.payload IS NULL;
-- COMMENT ON COLUMN exp.events.metrics IS NULL;
-- COMMIT;
--
-- Note: No data changes are made, so rollback is safe and reversible.
-- =============================================================================
