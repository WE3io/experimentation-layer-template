# Cross-Cutting: Update data-model.md with New Tables

## Outcome

The data model documentation (`docs/data-model.md`) is updated to include all new tables from the evolution. The documentation:
- Adds section for `exp.prompts` and `exp.prompt_versions` tables
- Adds section for `exp.mcp_tools` table (if created)
- Updates entity relationships diagram
- Maintains existing table documentation

A reviewer can read `docs/data-model.md` and see the complete data model including all new tables.

## Constraints & References

- **Current file:** `docs/data-model.md`
- **New tables:** Prompt registry (Phase 2), Tool registry (Phase 4)
- **Schema files:** `infra/postgres-schema-overview.sql` (after migrations)
- **Format:** Follow existing data model documentation style

## Acceptance Checks

- [ ] `docs/data-model.md` updated with `exp.prompts` table section
- [ ] `docs/data-model.md` updated with `exp.prompt_versions` table section
- [ ] `docs/data-model.md` updated with `exp.mcp_tools` table section (if created)
- [ ] Entity relationships diagram updated
- [ ] Table structures match schema files
- [ ] Documentation matches existing data model style
- [ ] All new tables properly documented

## Explicit Non-Goals

- Does not create database migrations (separate work items)
- Does not create schema designs (separate work items)
- Does not modify actual database schema (documentation only)
- Does not update other documentation files (this file only)
