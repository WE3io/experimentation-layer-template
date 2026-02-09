-- =============================================================================
-- Migration: Add MCP Tool Registry Tables
-- =============================================================================
-- Purpose: Create exp.mcp_tools and exp.variant_tools tables for MCP (Model
--          Context Protocol) tool management in conversational AI projects.
--          Tools are discovered from configured MCP servers and registered
--          in the database for variant assignment.
--
-- Created: 2026-02-09
-- Related: docs/data-model.md section 5 (MCP Tool Registry)
-- =============================================================================

BEGIN;

-- =============================================================================
-- Create exp.mcp_tools table
-- =============================================================================
-- MCP tools discovered from configured MCP servers. Tools are registered
-- in the database and can be assigned to variants for use in conversational
-- AI projects.
-- =============================================================================

CREATE TABLE IF NOT EXISTS exp.mcp_tools (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(255) NOT NULL,
                        -- Tool name (e.g., "query_database", "send_email")
    description         TEXT,
                        -- Human-readable tool description
    server_name         VARCHAR(255) NOT NULL,
                        -- MCP server name (from config/mcp_servers.json)
                        -- Links to MCP server configuration
    tool_schema         JSONB NOT NULL,
                        -- Tool definition schema (MCP tool schema format)
                        -- Includes input parameters, description, etc.
    capabilities        JSONB NOT NULL DEFAULT '{}',
                        -- Tool capabilities metadata
                        -- e.g., {"requires_auth": true, "rate_limited": true}
    status              VARCHAR(50) NOT NULL DEFAULT 'active',
                        -- active | deprecated | unavailable
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT uq_mcp_tools_server_name UNIQUE(server_name, name),
    CONSTRAINT chk_mcp_tools_status CHECK (
        status IN ('active', 'deprecated', 'unavailable')
    )
);

-- Indexes for tool discovery queries
CREATE INDEX IF NOT EXISTS idx_mcp_tools_server ON exp.mcp_tools(server_name);
CREATE INDEX IF NOT EXISTS idx_mcp_tools_status ON exp.mcp_tools(status);
CREATE INDEX IF NOT EXISTS idx_mcp_tools_name ON exp.mcp_tools(name);
CREATE INDEX IF NOT EXISTS idx_mcp_tools_schema ON exp.mcp_tools USING GIN(tool_schema);

-- Add comments
COMMENT ON TABLE exp.mcp_tools IS 
'MCP (Model Context Protocol) tools discovered from configured MCP servers. Tools are registered in the database and can be assigned to variants for use in conversational AI projects.';

COMMENT ON COLUMN exp.mcp_tools.name IS 
'Tool name (e.g., "query_database", "send_email"). Unique within a server.';

COMMENT ON COLUMN exp.mcp_tools.description IS 
'Human-readable tool description for documentation and UI display.';

COMMENT ON COLUMN exp.mcp_tools.server_name IS 
'MCP server name from config/mcp_servers.json. Links tool to its source server.';

COMMENT ON COLUMN exp.mcp_tools.tool_schema IS 
'Tool definition schema in MCP format (JSONB). Includes input parameters, descriptions, and validation rules.';

COMMENT ON COLUMN exp.mcp_tools.capabilities IS 
'Tool capabilities metadata (JSONB). Examples: requires_auth, rate_limited, timeout_seconds.';

COMMENT ON COLUMN exp.mcp_tools.status IS 
'Tool status: active (available), deprecated (not recommended but supported), unavailable (temporarily unavailable).';

-- =============================================================================
-- Create exp.variant_tools table
-- =============================================================================
-- Many-to-many relationship table linking variants to available MCP tools.
-- Each variant can have multiple tools, and each tool can be available to
-- multiple variants.
-- =============================================================================

CREATE TABLE IF NOT EXISTS exp.variant_tools (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    variant_id          UUID NOT NULL REFERENCES exp.variants(id) ON DELETE CASCADE,
    tool_id             UUID NOT NULL REFERENCES exp.mcp_tools(id) ON DELETE CASCADE,
    enabled             BOOLEAN NOT NULL DEFAULT true,
                        -- Whether tool is enabled for this variant
    priority            INTEGER NOT NULL DEFAULT 0,
                        -- Tool priority (lower = higher priority)
                        -- Used for tool ordering in prompts
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT uq_variant_tools UNIQUE(variant_id, tool_id)
);

-- Indexes for tool discovery queries
CREATE INDEX IF NOT EXISTS idx_variant_tools_variant ON exp.variant_tools(variant_id);
CREATE INDEX IF NOT EXISTS idx_variant_tools_tool ON exp.variant_tools(tool_id);
CREATE INDEX IF NOT EXISTS idx_variant_tools_enabled ON exp.variant_tools(variant_id, enabled) WHERE enabled = true;

-- Add comments
COMMENT ON TABLE exp.variant_tools IS 
'Many-to-many relationship table linking variants to available MCP tools. Each variant can have multiple tools, and each tool can be available to multiple variants.';

COMMENT ON COLUMN exp.variant_tools.enabled IS 
'Whether tool is enabled for this variant. Disabled tools are not included in tool discovery queries.';

COMMENT ON COLUMN exp.variant_tools.priority IS 
'Tool priority (lower = higher priority). Used for tool ordering when including tools in prompts for LLM access.';

COMMIT;

-- =============================================================================
-- Rollback Script
-- =============================================================================
-- To rollback this migration:
--
-- BEGIN;
-- DROP TABLE IF EXISTS exp.variant_tools CASCADE;
-- DROP TABLE IF EXISTS exp.mcp_tools CASCADE;
-- COMMIT;
--
-- Note: CASCADE will drop dependent objects (indexes, constraints).
-- =============================================================================
