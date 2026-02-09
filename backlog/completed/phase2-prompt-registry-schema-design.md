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

- [x] Schema design document created (location: `docs/data-model.md` Section 4)
- [x] `exp.prompts` table structure documented (id, name, description, created_at)
- [x] `exp.prompt_versions` table structure documented (id, prompt_id, version, file_path, model_provider, model_name, status, config_defaults, created_at)
- [x] Relationships documented (prompts 1:N prompt_versions)
- [x] Indexes documented for common queries (by prompt_id, by status, by provider/model_name)
- [x] Links to `/prompts/` directory files documented (file_path field)
- [x] Status values documented (active, deprecated, archived)
- [x] Design follows pattern of `exp.policies` and `exp.policy_versions`

## Explicit Non-Goals

- Does not create database migration (separate work item)
- Does not create `/prompts/` directory (separate work item)
- Does not implement Prompt Service (separate work items)
- Does not update actual database schema (design only)
