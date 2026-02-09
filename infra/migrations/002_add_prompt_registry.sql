-- =============================================================================
-- Migration: Add Prompt Registry Tables
-- =============================================================================
-- Purpose: Create exp.prompts and exp.prompt_versions tables for conversational
--          AI projects. These tables manage versioned prompt templates similar
--          to how exp.policies and exp.policy_versions manage ML models.
--
-- Created: 2026-02-08
-- Related: docs/data-model.md section 4 (Prompt Registry)
-- =============================================================================

BEGIN;

-- =============================================================================
-- Create exp.prompts table
-- =============================================================================
-- Named prompts for conversational AI projects (e.g., meal planning assistant,
-- customer support bot). Analogous to exp.policies for ML projects.
-- =============================================================================

CREATE TABLE IF NOT EXISTS exp.prompts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255) NOT NULL UNIQUE,
    description     TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for prompt name lookups
CREATE INDEX IF NOT EXISTS idx_prompts_name ON exp.prompts(name);

-- Add comment
COMMENT ON TABLE exp.prompts IS 
'Named prompts for conversational AI projects. Each prompt can have multiple versions stored in exp.prompt_versions.';

-- =============================================================================
-- Create exp.prompt_versions table
-- =============================================================================
-- Versioned prompt configurations linked to prompt files in /prompts/ directory.
-- Analogous to exp.policy_versions for ML projects.
-- =============================================================================

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
                        -- active | deprecated | archived
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT uq_prompt_versions UNIQUE(prompt_id, version),
    CONSTRAINT chk_prompt_versions_status CHECK (
        status IN ('active', 'deprecated', 'archived')
    )
);

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_prompt_versions_prompt ON exp.prompt_versions(prompt_id);
CREATE INDEX IF NOT EXISTS idx_prompt_versions_status ON exp.prompt_versions(status);
CREATE INDEX IF NOT EXISTS idx_prompt_versions_provider ON exp.prompt_versions(model_provider, model_name);

-- Add comments
COMMENT ON TABLE exp.prompt_versions IS 
'Versioned prompt configurations linked to prompt files in /prompts/ directory. Each version references a prompt file and specifies LLM provider/model.';

COMMENT ON COLUMN exp.prompt_versions.file_path IS 
'Path to prompt file relative to repository root (e.g., "prompts/meal_planning_v1.txt"). File is Git versioned.';

COMMENT ON COLUMN exp.prompt_versions.model_provider IS 
'LLM provider identifier (e.g., "anthropic", "openai").';

COMMENT ON COLUMN exp.prompt_versions.model_name IS 
'Specific model identifier (e.g., "claude-sonnet-4.5", "gpt-4").';

COMMENT ON COLUMN exp.prompt_versions.config_defaults IS 
'Default runtime parameters (temperature, max_tokens, etc.) stored as JSONB.';

COMMENT ON COLUMN exp.prompt_versions.status IS 
'Version status: active (in use), deprecated (not recommended but supported), archived (retired).';

COMMIT;

-- =============================================================================
-- Rollback Script
-- =============================================================================
-- To rollback this migration:
--
-- BEGIN;
-- DROP TABLE IF EXISTS exp.prompt_versions CASCADE;
-- DROP TABLE IF EXISTS exp.prompts CASCADE;
-- COMMIT;
--
-- Note: CASCADE will drop dependent objects (indexes, constraints).
-- =============================================================================
