# Cross-Cutting: Create Migration Guide Documentation

## Outcome

A migration guide document exists that explains how existing ML projects can adopt the unified abstraction. The guide:
- Documents the migration path for existing ML projects (adding `execution_strategy` field)
- Shows before/after examples of config transformations
- Explains backward compatibility guarantees
- Documents how to start new conversational AI projects
- Includes troubleshooting tips

A reviewer can read the migration guide and successfully migrate their existing ML project or start a new conversational AI project.

## Constraints & References

- **Location:** Document in `docs/migration-guide.md` or `Repository_Evolution_Proposal.md` section 6
- **Proposal reference:** `Repository_Evolution_Proposal.md` section 6 (Migration Guide)
- **Unified config:** Config structure from Phase 1 work items
- **Format:** Follow existing documentation style

## Acceptance Checks

- [ ] Migration guide document created (location: `docs/migration-guide.md` or update proposal)
- [ ] Migration path for existing ML projects documented
- [ ] Before/after config examples included
- [ ] Backward compatibility guarantees explained
- [ ] Starting new conversational AI projects guide included
- [ ] Troubleshooting tips included
- [ ] Examples match actual config structures
- [ ] Documentation matches existing style

## Explicit Non-Goals

- Does not implement migration scripts (documentation only)
- Does not test migrations (separate consideration)
- Does not update existing projects (guide only)
- Does not create new project templates (separate work items)
