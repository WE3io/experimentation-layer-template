# Reduce Config Example Duplication

## Outcome

Full YAML config blocks in docs are replaced with minimal examples plus links to [config/experiments.example.yml](../config/experiments.example.yml) except where the example illustrates a specific concept (e.g., allocation validation, gradual rollout).

## Constraints & References

- **Canonical config**: [config/experiments.example.yml](../config/experiments.example.yml)
- **Target docs**: experiments, choosing-project-type, prompts-guide, conversation-flows, migration-guide, routes, model-promotion
- **Principle**: Link to canonical sources rather than duplicating

## Acceptance Checks

- [x] Redundant full YAML blocks replaced with minimal snippet + link
- [x] Examples kept inline only where they illustrate a concept (allocation validation in experiments.md, gradual rollout in prompts-guide.md)
- [x] config/experiments.example.yml unchanged

## Explicit Non-Goals

- Does not change config format; does not remove all examples
