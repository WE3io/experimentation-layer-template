# Phase 1: Create Database Migration for Variant Config

## Outcome

A SQL migration file exists that ensures the `exp.variants.config` JSONB column can store the unified config structure. The migration:
- Validates that existing configs continue to work (backward compatibility)
- Adds database-level validation or constraints if needed
- Updates `infra/postgres-schema-overview.sql` with the new config structure documentation
- Includes rollback script

A reviewer can run the migration against a database with existing variant configs and verify that:
1. Migration succeeds without errors
2. Existing configs remain readable
3. New unified config format can be inserted
4. Rollback restores previous state

## Constraints & References

- **Current schema:** `infra/postgres-schema-overview.sql` lines 47-64
- **Target schema:** `docs/data-model.md` (after phase1-variant-config-schema-docs.md completes)
- **Migration pattern:** Follow existing migration conventions (if any) or create new pattern
- **Backward compatibility:** Must not break existing `policy_version_id` configs
- **Database:** PostgreSQL 12+ with JSONB support

## Acceptance Checks

- [ ] Migration file created in `infra/migrations/` (or appropriate location)
- [ ] Migration adds no breaking changes to existing configs
- [ ] Migration can be applied to database with existing variant configs
- [ ] Migration can be rolled back without data loss
- [ ] `infra/postgres-schema-overview.sql` updated with config structure comments
- [ ] Migration includes comments explaining backward compatibility approach
- [ ] Test script or instructions verify existing configs still work after migration

## Explicit Non-Goals

- Does not update Assignment Service to use new config format (separate work item)
- Does not create config validator (separate work item)
- Does not migrate existing configs to new format (migration guide covers this)
- Does not add application-level validation (separate work item)
