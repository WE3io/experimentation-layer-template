# Phase 5: Create Database Migration for Event Extensions

## Outcome

SQL migration files exist that extend the event schema if needed for conversation events. The migration:
- Adds any necessary columns or constraints for conversation events (if schema changes needed)
- Updates indexes if conversation event queries require them
- Updates `infra/postgres-schema-overview.sql` with event extensions
- Includes rollback script

Note: If conversation events fit within existing JSONB structure, migration may be minimal or documentation-only.

A reviewer can verify that conversation events can be stored and queried efficiently.

## Constraints & References

- **Current schema:** `infra/postgres-schema-overview.sql` lines 86-110
- **Event docs:** `docs/data-model.md` (after phase5-event-schema-extension-docs.md)
- **Pattern:** Follow existing migration pattern
- **Database:** PostgreSQL 12+ with JSONB support

## Acceptance Checks

- [ ] Migration file created (if schema changes needed) or documentation updated
- [ ] Any new columns or constraints documented
- [ ] Indexes added if needed for conversation event queries
- [ ] `infra/postgres-schema-overview.sql` updated if schema changed
- [ ] Rollback script included (if migration created)
- [ ] Migration can be applied without errors (if migration created)

## Explicit Non-Goals

- Does not update Event Ingestion Service (separate work item)
- Does not create Metabase models (separate work item)
- Does not populate event data (separate work items)
- Does not modify event structure if JSONB is sufficient (may be documentation-only)
