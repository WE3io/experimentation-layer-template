# Cross-Cutting: Update Existing Route Documentation

## Outcome

Existing route documentation files in `docs/routes/` are updated to reflect the unified abstraction. The updates:
- Rename ML-specific routes if needed (e.g., `experiment-route.md` → `ml-route.md` or keep as-is)
- Update route docs to mention unified abstraction where relevant
- Add cross-references to conversational AI route
- Ensure route docs remain accurate after evolution

A reviewer can navigate route documentation and understand both ML and conversational AI paths.

## Constraints & References

- **Location:** `docs/routes/` directory
- **Proposal reference:** `Repository_Evolution_Proposal.md` section 4 (lines 150)
- **Existing routes:** `docs/routes/experiment-route.md`, `docs/routes/training-route.md`, etc.
- **Format:** Follow existing route documentation style

## Acceptance Checks

- [ ] Route documentation reviewed for updates needed
- [ ] ML-specific routes updated to mention unified abstraction
- [ ] Cross-references to conversational AI route added where relevant
- [ ] Route docs remain accurate after evolution
- [ ] Documentation matches existing route style
- [ ] Navigation in `docs/README.md` updated if routes renamed

## Explicit Non-Goals

- Does not create new route docs (separate work items)
- Does not create conversational AI route (separate work item)
- Does not rewrite all route docs (updates only)
- Does not change route structure (updates only)
