# Phase 2: Create Prompt Service Design

## Outcome

A new design document exists at `services/prompt-service/DESIGN.md` that describes the internal design of the Prompt Service. The design:
- Describes responsibilities (prompt retrieval, version management)
- Documents data access patterns
- Describes file system integration (reading from `/prompts/` directory)
- Documents caching strategy if applicable
- Follows the same structure as `services/assignment-service/DESIGN.md`

A reviewer can read the design doc and understand how the Prompt Service will be implemented without seeing code.

## Constraints & References

- **Location:** `services/prompt-service/DESIGN.md`
- **Pattern:** Follow structure of `services/assignment-service/DESIGN.md`
- **API spec:** `services/prompt-service/API_SPEC.md` (after phase2-prompt-service-api-spec.md)
- **Schema:** `exp.prompts` and `exp.prompt_versions` tables
- **File storage:** `/prompts/` directory structure

## Acceptance Checks

- [ ] File `services/prompt-service/DESIGN.md` created
- [ ] Service responsibilities documented
- [ ] Data access patterns documented (database queries)
- [ ] File system integration documented (reading prompt files)
- [ ] Caching strategy documented (if applicable)
- [ ] Error handling documented
- [ ] Performance considerations documented
- [ ] Follows same structure as Assignment Service design doc

## Explicit Non-Goals

- Does not implement the service (specification only)
- Does not create API spec (separate work item)
- Does not create `/prompts/` directory (separate work item)
- Does not write code (design specification only)
