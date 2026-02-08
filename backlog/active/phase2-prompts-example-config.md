# Phase 2: Add prompts.example.yml Configuration

## Outcome

A new configuration file `config/prompts.example.yml` exists that demonstrates how to configure prompts and prompt versions. The file:
- Shows prompt definitions with versions
- Includes model provider and model name configuration
- Shows status values (active, deprecated, archived)
- Includes parameter examples (temperature, max_tokens)
- Links prompt versions to files in `/prompts/` directory

A reviewer can copy `prompts.example.yml` and understand how to configure prompts for their project.

## Constraints & References

- **Location:** `config/prompts.example.yml`
- **Proposal reference:** `Repository_Evolution_Proposal.md` lines 95-108
- **Pattern:** Follow structure of `config/policies.example.yml`
- **File references:** Link to files in `/prompts/` directory

## Acceptance Checks

- [ ] File `config/prompts.example.yml` created
- [ ] File shows prompt definitions with `name` and `versions` array
- [ ] Each version includes: `version`, `description`, `file`, `model_provider`, `model_name`, `status`, `params`
- [ ] Examples show `active` status prompts
- [ ] Examples show parameter configuration (temperature, max_tokens)
- [ ] File paths reference `/prompts/` directory
- [ ] Comments explain configuration options
- [ ] YAML syntax is valid
- [ ] Matches structure from proposal example

## Explicit Non-Goals

- Does not create actual prompt files (separate work item)
- Does not populate database (example config only)
- Does not implement config loading (example file only)
- Does not validate configs (separate work item)
