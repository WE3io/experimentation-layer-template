-- =============================================================================
-- Migration: Add Unified Variant Config Support
-- =============================================================================
-- Purpose: Ensure exp.variants.config JSONB column supports unified config
--          structure (mlflow_model, prompt_template, hybrid) while maintaining
--          backward compatibility with existing policy_version_id format.
--
-- Created: 2026-02-08
-- Related: docs/data-model.md section 1.2 (exp.variants)
-- =============================================================================

-- =============================================================================
-- Backward Compatibility Note
-- =============================================================================
-- This migration ensures backward compatibility:
-- - Existing configs with policy_version_id at root level continue to work
-- - New unified config format (execution_strategy) can be stored
-- - No data migration required - JSONB is flexible enough to handle both formats
-- - Application layer handles format detection and transformation
--
-- Example existing format (still supported):
--   {"policy_version_id": "uuid", "params": {...}}
--
-- Example new format (supported):
--   {"execution_strategy": "mlflow_model", "mlflow_model": {...}, "params": {...}}
-- =============================================================================

BEGIN;

-- =============================================================================
-- Migration: No schema changes required
-- =============================================================================
-- The exp.variants.config column is already JSONB, which supports both:
-- 1. Legacy format: {"policy_version_id": "uuid", "params": {...}}
-- 2. Unified format: {"execution_strategy": "...", "mlflow_model": {...}, ...}
--
-- JSONB is schema-less, so no ALTER TABLE is needed.
-- Backward compatibility is maintained at the application layer.
-- =============================================================================

-- Verify the column exists and is JSONB (safety check)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'exp'
          AND table_name = 'variants'
          AND column_name = 'config'
          AND data_type = 'jsonb'
    ) THEN
        RAISE EXCEPTION 'Column exp.variants.config does not exist or is not JSONB';
    END IF;
END $$;

-- =============================================================================
-- Optional: Add a comment to the column documenting the unified structure
-- =============================================================================
COMMENT ON COLUMN exp.variants.config IS 
'Unified variant configuration supporting both ML and conversational AI projects.
Supports three execution strategies: mlflow_model, prompt_template, hybrid.
Legacy format (policy_version_id at root) remains supported for backward compatibility.
See docs/data-model.md section 1.2 for complete structure documentation.';

COMMIT;

-- =============================================================================
-- Rollback Script
-- =============================================================================
-- To rollback this migration, remove the comment:
--
-- BEGIN;
-- COMMENT ON COLUMN exp.variants.config IS NULL;
-- COMMIT;
--
-- Note: No data changes are made, so rollback is safe and reversible.
-- =============================================================================
