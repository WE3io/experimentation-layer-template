-- =============================================================================
-- Experimentation & Model Lifecycle - PostgreSQL Schema
-- =============================================================================
-- Purpose: Complete database schema for the experimentation system
-- 
-- Start Here If…
--   - Setting up a new database → Run this file
--   - Understanding the data model → Read docs/data-model.md
--   - Modifying schema → Update this file and create migration
-- =============================================================================

-- Create schema
CREATE SCHEMA IF NOT EXISTS exp;

-- =============================================================================
-- 1. EXPERIMENTS & VARIANTS
-- =============================================================================

-- exp.experiments: Experiment definitions
-- Related: docs/experiments.md
CREATE TABLE IF NOT EXISTS exp.experiments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255) NOT NULL UNIQUE,
    description     TEXT,
    status          VARCHAR(50) NOT NULL DEFAULT 'draft',
                    -- Valid values: draft, active, paused, completed
    unit_type       VARCHAR(50) NOT NULL,
                    -- Valid values: user, household, session
    start_at        TIMESTAMP WITH TIME ZONE,
    end_at          TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_experiments_status CHECK (
        status IN ('draft', 'active', 'paused', 'completed')
    ),
    CONSTRAINT chk_experiments_unit_type CHECK (
        unit_type IN ('user', 'household', 'session')
    )
);

CREATE INDEX IF NOT EXISTS idx_experiments_status ON exp.experiments(status);
CREATE INDEX IF NOT EXISTS idx_experiments_name ON exp.experiments(name);

-- exp.variants: Variants per experiment
-- Related: docs/experiments.md
CREATE TABLE IF NOT EXISTS exp.variants (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experiment_id   UUID NOT NULL REFERENCES exp.experiments(id) ON DELETE CASCADE,
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    allocation      DECIMAL(5,4) NOT NULL,
                    -- 0.0000 to 1.0000 (percentage as decimal)
    config          JSONB NOT NULL DEFAULT '{}',
                    -- Unified config structure supporting both ML and conversational AI
                    -- Supports execution_strategy: mlflow_model | prompt_template | hybrid
                    -- Legacy format (policy_version_id at root) remains supported
                    -- See docs/data-model.md section 1.2 for complete structure documentation
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT uq_variants_experiment_name UNIQUE(experiment_id, name),
    CONSTRAINT chk_variants_allocation CHECK (
        allocation >= 0 AND allocation <= 1
    )
);

CREATE INDEX IF NOT EXISTS idx_variants_experiment ON exp.variants(experiment_id);

-- exp.assignments: Unit → Variant mappings
-- Related: docs/assignment-service.md
CREATE TABLE IF NOT EXISTS exp.assignments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experiment_id   UUID NOT NULL REFERENCES exp.experiments(id) ON DELETE CASCADE,
    unit_type       VARCHAR(50) NOT NULL,
    unit_id         VARCHAR(255) NOT NULL,
    variant_id      UUID NOT NULL REFERENCES exp.variants(id) ON DELETE CASCADE,
    assigned_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT uq_assignments_experiment_unit UNIQUE(experiment_id, unit_id)
);

CREATE INDEX IF NOT EXISTS idx_assignments_unit ON exp.assignments(unit_type, unit_id);
CREATE INDEX IF NOT EXISTS idx_assignments_experiment ON exp.assignments(experiment_id);

-- =============================================================================
-- 2. EVENTS & METRICS
-- =============================================================================

-- exp.events: Atomic logs of in-product actions
-- Related: docs/event-ingestion-service.md
CREATE TABLE IF NOT EXISTS exp.events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type      VARCHAR(100) NOT NULL,
                    -- Examples: plan_generated, plan_accepted, meal_swapped
    unit_type       VARCHAR(50) NOT NULL,
    unit_id         VARCHAR(255) NOT NULL,
    experiments     JSONB NOT NULL DEFAULT '[]',
                    -- Array of {experiment_id, variant_id}
    context         JSONB NOT NULL DEFAULT '{}',
                    -- policy_version_id, app_version, etc.
    metrics         JSONB NOT NULL DEFAULT '{}',
                    -- latency_ms, token_count, etc.
    payload         JSONB,
                    -- Event-specific data
    timestamp       TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_events_type ON exp.events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_unit ON exp.events(unit_type, unit_id);
CREATE INDEX IF NOT EXISTS idx_events_timestamp ON exp.events(timestamp);
CREATE INDEX IF NOT EXISTS idx_events_experiments ON exp.events USING GIN(experiments);

-- Partitioning hint (TODO: implement if needed)
-- Consider partitioning by timestamp for large event volumes

-- exp.metric_aggregates: Hourly/daily summaries
-- Related: pipelines/metrics-aggregation.md
CREATE TABLE IF NOT EXISTS exp.metric_aggregates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experiment_id   UUID NOT NULL REFERENCES exp.experiments(id) ON DELETE CASCADE,
    variant_id      UUID NOT NULL REFERENCES exp.variants(id) ON DELETE CASCADE,
    metric_name     VARCHAR(100) NOT NULL,
    bucket_type     VARCHAR(20) NOT NULL,
                    -- hourly, daily
    bucket_start    TIMESTAMP WITH TIME ZONE NOT NULL,
    count           BIGINT NOT NULL DEFAULT 0,
    sum             DECIMAL(20,6),
    mean            DECIMAL(20,6),
    min             DECIMAL(20,6),
    max             DECIMAL(20,6),
    stddev          DECIMAL(20,6),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT uq_aggregates UNIQUE(
        experiment_id, variant_id, metric_name, bucket_type, bucket_start
    ),
    CONSTRAINT chk_aggregates_bucket_type CHECK (
        bucket_type IN ('hourly', 'daily')
    )
);

CREATE INDEX IF NOT EXISTS idx_aggregates_lookup ON exp.metric_aggregates(
    experiment_id, variant_id, metric_name, bucket_start
);

-- =============================================================================
-- 3. POLICIES & MODEL REGISTRY
-- =============================================================================

-- exp.policies: Named policies
-- Related: docs/mlflow-guide.md
CREATE TABLE IF NOT EXISTS exp.policies (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255) NOT NULL UNIQUE,
    description     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- exp.policy_versions: Versioned references to MLflow models
-- Related: docs/model-promotion.md
CREATE TABLE IF NOT EXISTS exp.policy_versions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_id           UUID NOT NULL REFERENCES exp.policies(id) ON DELETE CASCADE,
    version             INTEGER NOT NULL,
    mlflow_model_name   VARCHAR(255) NOT NULL,
    mlflow_model_version VARCHAR(50) NOT NULL,
    config_defaults     JSONB NOT NULL DEFAULT '{}',
    status              VARCHAR(50) NOT NULL DEFAULT 'active',
                        -- active, deprecated, archived
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT uq_policy_versions UNIQUE(policy_id, version),
    CONSTRAINT chk_policy_versions_status CHECK (
        status IN ('active', 'deprecated', 'archived')
    )
);

CREATE INDEX IF NOT EXISTS idx_policy_versions_policy ON exp.policy_versions(policy_id);
CREATE INDEX IF NOT EXISTS idx_policy_versions_mlflow ON exp.policy_versions(
    mlflow_model_name, mlflow_model_version
);

-- =============================================================================
-- 4. PROMPT REGISTRY (CONVERSATIONAL AI)
-- =============================================================================

-- exp.prompts: Named prompts for conversational AI projects
-- Related: docs/data-model.md section 4.1
CREATE TABLE IF NOT EXISTS exp.prompts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255) NOT NULL UNIQUE,
    description     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prompts_name ON exp.prompts(name);

-- exp.prompt_versions: Versioned prompt configurations
-- Related: docs/data-model.md section 4.2
CREATE TABLE IF NOT EXISTS exp.prompt_versions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prompt_id           UUID NOT NULL REFERENCES exp.prompts(id) ON DELETE CASCADE,
    version             INTEGER NOT NULL,
    file_path           VARCHAR(500) NOT NULL,
                        -- Path relative to repo root (e.g., "prompts/meal_planning_v1.txt")
    model_provider      VARCHAR(100) NOT NULL,
                        -- LLM provider: "anthropic", "openai", etc.
    model_name          VARCHAR(255) NOT NULL,
                        -- Model identifier: "claude-sonnet-4.5", "gpt-4", etc.
    config_defaults     JSONB NOT NULL DEFAULT '{}',
                        -- Default parameters (temperature, max_tokens, etc.)
    status              VARCHAR(50) NOT NULL DEFAULT 'active',
                        -- active, deprecated, archived
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT uq_prompt_versions UNIQUE(prompt_id, version),
    CONSTRAINT chk_prompt_versions_status CHECK (
        status IN ('active', 'deprecated', 'archived')
    )
);

CREATE INDEX IF NOT EXISTS idx_prompt_versions_prompt ON exp.prompt_versions(prompt_id);
CREATE INDEX IF NOT EXISTS idx_prompt_versions_status ON exp.prompt_versions(status);
CREATE INDEX IF NOT EXISTS idx_prompt_versions_provider ON exp.prompt_versions(model_provider, model_name);

-- =============================================================================
-- 5. OFFLINE EVALUATION
-- =============================================================================

-- exp.offline_replay_results: Offline evaluation results
-- Related: docs/offline-evaluation.md
CREATE TABLE IF NOT EXISTS exp.offline_replay_results (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_version_id       UUID NOT NULL REFERENCES exp.policy_versions(id),
    dataset_version         VARCHAR(255) NOT NULL,
    mlflow_run_id           VARCHAR(255),
    
    -- Aggregate metrics
    plan_alignment_score    DECIMAL(10,6),
    constraint_respect_score DECIMAL(10,6),
    edit_distance_score     DECIMAL(10,6),
    diversity_score         DECIMAL(10,6),
    leftovers_score         DECIMAL(10,6),
    
    -- Comparison
    baseline_version_id     UUID REFERENCES exp.policy_versions(id),
    is_better_than_baseline BOOLEAN,
    
    -- Status
    status                  VARCHAR(50) NOT NULL DEFAULT 'completed',
    error_message           TEXT,
    
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_replay_status CHECK (
        status IN ('running', 'completed', 'failed')
    )
);

CREATE INDEX IF NOT EXISTS idx_replay_policy ON exp.offline_replay_results(policy_version_id);
CREATE INDEX IF NOT EXISTS idx_replay_dataset ON exp.offline_replay_results(dataset_version);

-- =============================================================================
-- 6. VIEWS
-- =============================================================================

-- View: Experiment metrics for dashboards
-- Related: analytics/metabase-models.md
CREATE OR REPLACE VIEW exp.v_experiment_metrics AS
SELECT
    e.id AS experiment_id,
    e.name AS experiment_name,
    v.id AS variant_id,
    v.name AS variant_name,
    m.metric_name,
    m.bucket_type,
    m.bucket_start,
    m.count,
    m.mean,
    m.min,
    m.max,
    m.stddev
FROM exp.metric_aggregates m
JOIN exp.variants v ON v.id = m.variant_id
JOIN exp.experiments e ON e.id = m.experiment_id;

-- View: Active experiments with variant counts
CREATE OR REPLACE VIEW exp.v_active_experiments AS
SELECT
    e.*,
    COUNT(v.id) AS variant_count,
    COALESCE(SUM(v.allocation), 0) AS total_allocation
FROM exp.experiments e
LEFT JOIN exp.variants v ON v.experiment_id = e.id
WHERE e.status = 'active'
GROUP BY e.id;

-- View: Policy versions with MLflow info
CREATE OR REPLACE VIEW exp.v_policy_versions AS
SELECT
    pv.*,
    p.name AS policy_name,
    p.description AS policy_description
FROM exp.policy_versions pv
JOIN exp.policies p ON p.id = pv.policy_id;

-- View: Prompt versions with prompt info
CREATE OR REPLACE VIEW exp.v_prompt_versions AS
SELECT
    pv.*,
    p.name AS prompt_name,
    p.description AS prompt_description
FROM exp.prompt_versions pv
JOIN exp.prompts p ON p.id = pv.prompt_id;

-- =============================================================================
-- 7. FUNCTIONS (Optional helpers)
-- =============================================================================

-- Function: Update timestamp on experiments
CREATE OR REPLACE FUNCTION exp.update_experiments_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_experiments_update
    BEFORE UPDATE ON exp.experiments
    FOR EACH ROW
    EXECUTE FUNCTION exp.update_experiments_timestamp();

-- =============================================================================
-- TODO: Implementation Notes
-- =============================================================================
-- [ ] Add table partitioning for exp.events if volume exceeds 100M rows
-- [ ] Add read replicas for analytics queries
-- [ ] Set up automated backups
-- [ ] Configure connection pooling (PgBouncer)
-- [ ] Add monitoring for slow queries
-- =============================================================================

