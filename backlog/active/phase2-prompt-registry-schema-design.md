# Phase 2: Design Prompt Registry Database Schema

## Outcome

Documentation exists that defines the database schema for the prompt registry system. The schema design:
- Defines `exp.prompts` table structure (prompt names, descriptions)
- Defines `exp.prompt_versions` table structure (versioned prompt configs)
- Documents relationships between prompts and prompt versions
- Includes indexes for common query patterns
- Links prompt versions to prompt files in `/prompts/` directory

A reviewer can read the schema design and understand the complete data model for prompt versioning without seeing SQL.

## Constraints & References

- **Schema location:** Document in `docs/data-model.md` (new section) or separate design doc
- **Proposal reference:** `Repository_Evolution_Proposal.md` section 3.1 (Prompt Registry)
- **Pattern:** Follow existing schema design pattern (see `exp.policies` and `exp.policy_versions`)
- **Database:** PostgreSQL with JSONB support
- **File storage:** Prompts stored in `/prompts/` directory (Git versioned)

## Acceptance Checks

- [ ] Schema design document created (location: `docs/data-model.md` new section or `infra/prompt-registry-schema.md`)
- [ ] `exp.prompts` table structure documented (id, name, description, created_at)
- [ ] `exp.prompt_versions` table structure documented (id, prompt_id, version, file_path, model_provider, model_name, status, params, created_at)
- [ ] Relationships documented (prompts 1:N prompt_versions)
- [ ] Indexes documented for common queries (by prompt name, by version, by status)
- [ ] Links to `/prompts/` directory files documented
- [ ] Status values documented (active, deprecated, archived)
- [ ] Design follows pattern of `exp.policies` and `exp.policy_versions`

## Explicit Non-Goals

- Does not create database migration (separate work item)
- Does not create `/prompts/` directory (separate work item)
- Does not implement Prompt Service (separate work items)
- Does not update actual database schema (design only)
