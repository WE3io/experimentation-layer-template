# Data Ops: Schema Migrations & Security

## Outcome

Integration of a database migration tool to manage PostgreSQL schema changes and updated documentation defining the security and PII handling strategy for the event pipeline.

## Constraints & References

- **Migration Tool:** Must be able to execute the existing SQL scripts in `infra/migrations/`. Prefer lightweight tools (e.g., `yoyo-migrations`, `alembic`).
- **Security Principles:** Aligns with `GEMINI.md` and `.agent/rules/security.md`.
- **PII Handling:** Must address data masking or exclusion at the point of ingestion.

## Acceptance Checks

- [ ] A migration tool is configured in the `infra/` directory.
- [ ] The current schema in `infra/postgres-schema-overview.sql` can be reproduced via the migration tool.
- [ ] `services/event-ingestion-service/DESIGN.md` is updated with a "Security and PII" section.
- [ ] The documentation explicitly defines how sensitive user data (PII) is handled during ingestion.
- [ ] A README in `infra/migrations/` explains how to run new migrations.

## Explicit Non-Goals

- Implementation of complex PII masking libraries (e.g., Presidio).
- Database migration to NoSQL or other non-relational stores.
- Setting up database encryption at rest (assumed at infra provider level).
