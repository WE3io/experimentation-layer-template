# Phase 4: Create Database Migration for Tool Registry

## Outcome

SQL migration files exist that create the MCP tool registry table (`exp.mcp_tools`). The migration:
- Creates `exp.mcp_tools` table with appropriate constraints
- Adds indexes for tool discovery queries
- Updates `infra/postgres-schema-overview.sql` with new table
- Includes rollback script

A reviewer can run the migration and verify that:
1. Table is created successfully
2. Indexes are created
3. Rollback removes table cleanly

## Constraints & References

- **Schema design:** Tool registry schema design (after phase4-tool-registry-schema-design.md)
- **Pattern:** Follow existing migration pattern
- **Schema location:** `infra/postgres-schema-overview.sql` should be updated
- **Database:** PostgreSQL 12+

## Acceptance Checks

- [ ] Migration file created in `infra/migrations/` (or appropriate location)
- [ ] Migration creates `exp.mcp_tools` table
- [ ] Indexes created for tool discovery queries
- [ ] Rollback script removes table and indexes
- [ ] `infra/postgres-schema-overview.sql` updated with new table definition
- [ ] Migration can be applied and rolled back without errors

## Explicit Non-Goals

- Does not populate table with data (separate work items)
- Does not implement MCP client libraries (separate work item)
- Does not create mcp_servers config (separate work item)
- Does not implement tool discovery (separate work items)
