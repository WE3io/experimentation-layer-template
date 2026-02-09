# Phase 2: Create /prompts/ Directory with Example Prompts

## Outcome

A `/prompts/` directory exists with example prompt files demonstrating the prompt versioning system. The directory:
- Contains example prompt files (e.g., `meal_planning_v1.txt`, `customer_support_v1.txt`)
- Includes a README.md explaining the directory structure
- Shows how prompts are versioned (v1, v2 naming convention)
- Demonstrates prompt template syntax (Jinja2/Mustache if applicable)

A reviewer can browse `/prompts/` and understand how prompts are stored and versioned.

## Constraints & References

- **Location:** `/prompts/` directory in repository root
- **Proposal reference:** `Repository_Evolution_Proposal.md` section 4 (lines 163-166)
- **Naming:** Follow versioning pattern (e.g., `{name}_v{version}.txt`)
- **Template syntax:** Support Jinja2/Mustache as mentioned in proposal

## Acceptance Checks

- [ ] Directory `/prompts/` created
- [ ] README.md in `/prompts/` explains directory structure
- [ ] Example prompt file `meal_planning_v1.txt` created
- [ ] Example prompt file `customer_support_v1.txt` created (or similar)
- [ ] Prompt files demonstrate template syntax (variables, conditionals if applicable)
- [ ] README explains versioning convention
- [ ] README explains how prompts link to database records

## Explicit Non-Goals

- Does not create database records (separate work items)
- Does not create prompts.example.yml (separate work item)
- Does not implement prompt loading (separate work items)
- Does not create all possible prompts (examples only)
