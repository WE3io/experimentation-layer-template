# Fix Stale References in choosing-project-type.md

## Outcome

[docs/choosing-project-type.md](../docs/choosing-project-type.md) no longer contains outdated "coming in Phase X" or "Wait for" text. A reviewer finds no references to future phases that are now complete.

## Constraints & References

- **Files**: [docs/choosing-project-type.md](../docs/choosing-project-type.md)
- **Specific edits**: (1) Line 15: Remove "(coming in Phase 2)" from the Conversational AI link; (2) Lines 321–322: Change "Wait for" to "Read" and remove "(Phase 2)" / "(Phase 3)" from the Conversational AI next steps
- **Principle**: documentation-principles.md (single source of truth, reduce maintenance burden)

## Acceptance Checks

- [x] Line 15: Conversational AI link is `[prompts-guide.md](prompts-guide.md)` with no "(coming in Phase 2)"
- [x] Lines 321–322: "Read" instead of "Wait for"; no phase labels

## Explicit Non-Goals

- Does not modify other docs; does not add new content
