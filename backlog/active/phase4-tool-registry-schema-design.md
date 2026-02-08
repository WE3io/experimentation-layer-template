# Phase 4: Design Tool Registry Database Schema

## Outcome

Documentation exists that defines the database schema for the MCP tool registry. The schema design:
- Defines `exp.mcp_tools` table structure (tool metadata, server info, capabilities)
- Documents relationships between tools and variants (many-to-many if applicable)
- Includes indexes for tool discovery queries
- Documents how tools are linked to MCP servers

A reviewer can read the schema design and understand how MCP tools are tracked in the database.

## Constraints & References

- **Schema location:** Document in `docs/data-model.md` (new section) or separate design doc
- **Proposal reference:** `Repository_Evolution_Proposal.md` section 3.3 (MCP Integration Layer)
- **Pattern:** Follow existing schema design pattern
- **MCP:** Model Context Protocol standard

## Acceptance Checks

- [ ] Schema design document created (location: `docs/data-model.md` new section or `infra/mcp-tool-registry-schema.md`)
- [ ] `exp.mcp_tools` table structure documented (id, name, description, server_name, tool_schema, variant_id, created_at)
- [ ] Relationships documented (tools to variants, tools to MCP servers)
- [ ] Indexes documented for tool discovery queries
- [ ] Tool schema storage documented (JSONB for tool definitions)
- [ ] Design follows pattern of existing tables

## Explicit Non-Goals

- Does not create database migration (separate work item)
- Does not implement MCP client libraries (separate work item)
- Does not create mcp_servers config (separate work item)
- Does not update actual database schema (design only)
