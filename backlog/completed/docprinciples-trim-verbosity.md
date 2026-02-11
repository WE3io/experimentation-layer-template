# Trim High-Maintenance Verbosity

## Outcome

Targeted sections in [docs/mcp-integration.md](../docs/mcp-integration.md), [docs/conversation-flows.md](../docs/conversation-flows.md), and [docs/prompts-guide.md](../docs/prompts-guide.md) are shortened or replaced with links where narrative duplicates external specs or adds low maintenance value.

## Constraints & References

- **Targets**: mcp-integration (~1141 lines), conversation-flows (~982), prompts-guide (~715)
- **Keep**: MCP contract, flow schema, template syntax; link to [flows/SCHEMA.md](../flows/SCHEMA.md), [examples/conversational-assistant/](../examples/conversational-assistant/)
- **Principle**: Include detail only when long-term value exceeds maintenance cost

## Acceptance Checks

- [x] For each file: 1–2 sections identified and trimmed or replaced with links
- [x] Durable contracts (contracts, schemas, syntax) preserved

## Explicit Non-Goals

- Does not rewrite entire docs; does not remove all examples
