# Phase 6: Create prompts-guide.md

## Outcome

A new documentation file `docs/prompts-guide.md` exists that explains prompt management. The guide:
- Explains the prompt registry system
- Shows how to create and version prompts
- Documents prompt template syntax (Jinja2/Mustache)
- Explains how to use prompts in experiments
- Includes examples and best practices

A reviewer can read the guide and understand how to manage prompts for conversational AI projects.

## Constraints & References

- **Location:** `docs/prompts-guide.md`
- **Proposal reference:** `Repository_Evolution_Proposal.md` section 4 (lines 145)
- **Prompt registry:** Schema and service from Phase 2 work items
- **Documentation style:** Follow existing docs structure

## Acceptance Checks

- [ ] File `docs/prompts-guide.md` created
- [ ] Guide explains prompt registry system
- [ ] Prompt creation and versioning explained
- [ ] Template syntax documented (Jinja2/Mustache)
- [ ] Using prompts in experiments explained
- [ ] Examples and best practices included
- [ ] Links to prompt service API and config examples included
- [ ] Matches existing documentation style
- [ ] Added to `docs/README.md` navigation

## Explicit Non-Goals

- Does not implement prompt registry (separate work items)
- Does not create example prompts (separate work item)
- Does not create conversation flows guide (separate work item)
- Does not write code (documentation only)
