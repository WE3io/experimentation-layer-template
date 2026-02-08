# Phase 1: Update Assignment Service Design

## Outcome

The Assignment Service design document (`services/assignment-service/DESIGN.md`) is updated to describe how the service handles unified variant configs. The design:
- Explains the logic for parsing and validating unified configs
- Documents backward compatibility handling for existing `policy_version_id` format
- Describes how config is returned to callers (maintains existing format or transforms)
- Updates caching strategy if config structure affects cache keys

A reviewer can read the design doc and understand the implementation approach for unified configs without seeing actual code.

## Constraints & References

- **Current design:** `services/assignment-service/DESIGN.md`
- **API spec:** `services/assignment-service/API_SPEC.md` (after phase1-assignment-service-api-update.md)
- **Config structure:** `Repository_Evolution_Proposal.md` lines 57-80
- **Backward compatibility:** Must handle existing `policy_version_id` configs without breaking

## Acceptance Checks

- [ ] DESIGN.md updated with unified config parsing logic
- [ ] Backward compatibility handling documented (how old configs are processed)
- [ ] Config validation approach described
- [ ] Caching strategy updated if config structure affects cache keys
- [ ] Error handling for invalid config structures documented
- [ ] Performance considerations for config parsing documented
- [ ] Design matches existing document style and structure

## Explicit Non-Goals

- Does not implement the design (specification only)
- Does not update API spec (separate work item)
- Does not create config validator (separate work item)
- Does not write tests (design specification only)
