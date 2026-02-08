# Phase 2: Create Database Migration for Prompt Registry

## Outcome

SQL migration files exist that create the prompt registry tables (`exp.prompts` and `exp.prompt_versions`). The migration:
- Creates `exp.prompts` table with appropriate constraints
- Creates `exp.prompt_versions` table with foreign key to `exp.prompts`
- Adds indexes for performance
- Updates `infra/postgres-schema-overview.sql` with new tables
- Includes rollback script

A reviewer can run the migration and verify that:
1. Tables are created successfully
2. Indexes are created
3. Foreign key constraints work
4. Rollback removes tables cleanly

## Constraints & References

- **Schema design:** `docs/data-model.md` or design doc (after phase2-prompt-registry-schema-design.md)
- **Pattern:** Follow existing migration pattern (see `infra/postgres-schema-overview.sql`)
- **Schema location:** `infra/postgres-schema-overview.sql` should be updated
- **Database:** PostgreSQL 12+

## Acceptance Checks

- [ ] Migration file created in `infra/migrations/` (or appropriate location)
- [ ] Migration creates `exp.prompts` table
- [ ] Migration creates `exp.prompt_versions` table
- [ ] Foreign key constraint from `prompt_versions` to `prompts` created
- [ ] Indexes created for common query patterns
- [ ] Rollback script removes tables and indexes
- [ ] `infra/postgres-schema-overview.sql` updated with new table definitions
- [ ] Migration can be applied and rolled back without errors

## Explicit Non-Goals

- Does not populate tables with data (separate work items)
- Does not create `/prompts/` directory (separate work item)
- Does not implement Prompt Service (separate work items)
- Does not create example prompts (separate work item)
