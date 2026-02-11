# Establish Canonical Schema Source (Reduce Duplication)

## Outcome

[docs/data-model.md](../docs/data-model.md) links to [infra/postgres-schema-overview.sql](../infra/postgres-schema-overview.sql) as the canonical DDL instead of inlining full CREATE TABLE blocks. Schema overview, table list, JSONB config structure, and exp.events payload documentation remain; full SQL is removed.

## Constraints & References

- **Canonical DDL**: [infra/postgres-schema-overview.sql](../infra/postgres-schema-overview.sql)
- **Migrations**: [infra/migrations/README.md](../infra/migrations/README.md)
- **Principle**: Link to canonical sources rather than duplicating

## Acceptance Checks

- [x] data-model.md contains table summaries and relationship diagram, not full CREATE TABLE blocks
- [x] Single link to postgres-schema-overview.sql and migrations README
- [x] JSONB config structure (section 1.2) preserved
- [x] exp.events payload structure preserved
- [x] postgres-schema-overview.sql still references data-model.md for "Understanding the data model"

## Explicit Non-Goals

- Does not modify postgres-schema-overview.sql or migrations; does not change schema itself
